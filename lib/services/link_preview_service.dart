// Sender-side OpenGraph unfurling for chat link previews.
//
// WHY THE SENDER FETCHES
// ----------------------
// Messages are end-to-end encrypted, so no Cloud Function can unfurl a link off
// the message document — the server has no plaintext. That leaves two options,
// and receiver-side fetching is the wrong one: it would hand every link sender a
// way to log the recipient's IP the instant the message is opened, and a
// tracking pixel dressed up as an `og:image` would fire on delivery. So the
// SENDER resolves the metadata and ships title/description/thumbnail *inside*
// the encrypted payload. The receiver renders from bytes it already has, never
// contacts the host, and the card works with the radio off.
//
// Conventions follow the app's one HTTP idiom (see
// lib/services/streak/streak_api.dart): `package:http`, `debugPrint` on
// failure, never an uncaught throw for an expected outcome. The one deliberate
// deviation is the timeout — 8s instead of the house 15s, because this fires
// while the user is still typing and a slow host must lose the race rather than
// hold the composer strip open.
//
// Sender-side fetching moves the exposure rather than removing it: the requests
// leave the sender's network, and only the first of them is a URL the sender
// actually typed. See "Destination filtering" below for what bounds where they
// can be pointed.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show InternetAddress, InternetAddressType;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'image_compressor.dart';

/// Resolved OpenGraph metadata for one URL.
class LinkPreview {
  /// The URL the card opens. This is the *requested* URL, not the redirect
  /// target — tapping the card should go where the sender's text pointed.
  final String url;
  final String? title;
  final String? description;
  final String? siteName;

  /// JPEG micro-thumbnail, base64. Null when the page had no image, the image
  /// was undecodable, or it would not fit under the size ceiling.
  final String? imageBase64;

  const LinkPreview({
    required this.url,
    this.title,
    this.description,
    this.siteName,
    this.imageBase64,
  });

  /// A card with neither a title nor an image is just a second copy of the URL
  /// the bubble already shows, so it is not worth the vertical space.
  bool get isRenderable =>
      (title != null && title!.isNotEmpty) || imageBase64 != null;
}

class LinkPreviewService {
  LinkPreviewService._();
  static final LinkPreviewService instance = LinkPreviewService._();

  static const Duration _timeout = Duration(seconds: 8);

  /// Enough for any real `<head>`. Some pages inline megabytes of JSON after it.
  static const int _maxHtmlBytes = 256 * 1024;
  static const int _maxImageBytes = 2 * 1024 * 1024;

  /// Hard ceiling on the base64 thumbnail.
  ///
  /// `SignalService.encryptForUser` fans the payload out to up to 5 recipient
  /// devices plus the sender's other devices, so whatever goes in here is
  /// duplicated ~9x inside a single Firestore document — against a 1 MiB
  /// per-document limit. 6 KB survives that multiplication with room to spare;
  /// an unbounded thumbnail does not.
  static const int _maxThumbBase64 = 6 * 1024;

  static const int _cacheMax = 50;

  static const String _userAgent =
      'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/119.0.0.0 Mobile Safari/537.36';

  /// Insertion-ordered, so the first key is the oldest — good enough for LRU
  /// eviction at this size. Null values are cached too: a dead link must not be
  /// re-fetched on every debounce tick.
  final Map<String, LinkPreview?> _cache = {};
  final Map<String, Future<LinkPreview?>> _inFlight = {};

  final http.Client _client = http.Client();

  /// Cached result for [url] if we already have one, without touching the
  /// network. The composer uses this to decide whether a preview is ready to
  /// attach at send time.
  LinkPreview? cached(String url) {
    final key = _normalise(url);
    return key == null ? null : _cache[key];
  }

  /// Resolves [url]'s OpenGraph metadata. Returns null when the page has
  /// nothing worth showing, is not HTML, or simply does not answer in time.
  /// Never throws.
  Future<LinkPreview?> fetch(String url) {
    final key = _normalise(url);
    if (key == null) return Future.value(null);

    if (_cache.containsKey(key)) return Future.value(_cache[key]);

    // A debounced composer can ask for the same URL several times before the
    // first answer lands; join the existing request instead of stampeding.
    final existing = _inFlight[key];
    if (existing != null) return existing;

    final future = _fetchUncached(key, url).then((preview) {
      _remember(key, preview);
      return preview;
    }).whenComplete(() => _inFlight.remove(key));

    _inFlight[key] = future;
    return future;
  }

  void _remember(String key, LinkPreview? preview) {
    if (_cache.length >= _cacheMax && !_cache.containsKey(key)) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = preview;
  }

  /// Cache key: scheme + host + path + query, lowercased host, no fragment.
  static String? _normalise(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    if (uri.host.isEmpty) return null;
    return uri.replace(host: uri.host.toLowerCase(), fragment: '').toString();
  }

  Future<LinkPreview?> _fetchUncached(String key, String requestedUrl) async {
    try {
      final uri = Uri.parse(key);
      final response = await _get(uri);
      if (response == null) return null;

      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('[LinkPreview] ${response.statusCode} for $uri');
        }
        return null;
      }

      final contentType =
          (response.headers['content-type'] ?? '').toLowerCase();
      if (!contentType.contains('text/html') &&
          !contentType.contains('application/xhtml')) {
        return null;
      }

      final bytes = await _readCapped(response.stream, _maxHtmlBytes);
      final html = _decodeHtml(bytes, contentType);
      final meta = _parseMetaTags(html);

      final title = _clean(
            meta['og:title'] ?? meta['twitter:title'] ?? _parseTitleTag(html),
            120,
          ) ??
          '';
      final description = _clean(
        meta['og:description'] ??
            meta['twitter:description'] ??
            meta['description'],
        200,
      );
      final siteName =
          _clean(meta['og:site_name'], 60) ?? uri.host.replaceFirst('www.', '');

      final rawImage = meta['og:image'] ??
          meta['og:image:secure_url'] ??
          meta['og:image:url'] ??
          meta['twitter:image'] ??
          meta['twitter:image:src'];

      final thumbnail =
          rawImage == null ? null : await _fetchThumbnail(uri, rawImage);

      final preview = LinkPreview(
        // Deliberately the URL as typed, not the redirect target: tapping the
        // card should land where the sender's text says it lands.
        url: requestedUrl,
        title: title.isEmpty ? null : title,
        description: description,
        siteName: siteName,
        imageBase64: thumbnail,
      );

      return preview.isRenderable ? preview : null;
    } catch (e) {
      if (kDebugMode) debugPrint('[LinkPreview] fetch failed for $key: $e');
      return null;
    }
  }

  Future<http.StreamedResponse?> _get(Uri uri,
      {String accept = 'text/html'}) async {
    var target = uri;
    // `<=`, not `<`: five redirects means six requests, and the sixth has to be
    // the one that answers.
    for (var hop = 0; hop <= _maxRedirects; hop++) {
      if (!await _isPermittedTarget(target)) return null;
      try {
        final request = http.Request('GET', target)
          // Followed by hand below — see _isPermittedTarget. A redirect the
          // client follows for us is a request this code never gets to check.
          ..followRedirects = false
          ..headers.addAll({
            'User-Agent': _userAgent,
            'Accept': accept,
            'Accept-Language': 'en',
          });
        final response = await _client.send(request).timeout(_timeout);
        if (!_redirectCodes.contains(response.statusCode)) return response;

        final location = response.headers['location'];
        // Return the socket to the pool before starting the next hop; a
        // redirect body is a few bytes, so this costs nothing.
        await response.stream.drain();
        if (location == null || location.isEmpty) return null;
        // `resolve` handles a relative Location, which is legal and common.
        target = target.resolve(location);
      } catch (e) {
        if (kDebugMode) debugPrint('[LinkPreview] GET $target failed: $e');
        return null;
      }
    }
    if (kDebugMode) debugPrint('[LinkPreview] too many redirects from $uri');
    return null;
  }

  static const Set<int> _redirectCodes = {301, 302, 303, 307, 308};
  static const int _maxRedirects = 5;

  // ── Destination filtering ─────────────────────────────────────────────────
  //
  // The composer fetches on its own, 600ms after a URL appears in the text —
  // including one the user pasted out of a message somebody else sent them. And
  // two of the three URLs this service requests are not the pasted one at all:
  // redirect hops, and the `og:image` named by whatever page answered. Both are
  // chosen by whoever controls that page.
  //
  // Unchecked, "paste this link" is therefore an attacker-chosen GET from inside
  // the user's network: `http://192.168.1.1/setup.cgi?…` at the router, a
  // loopback port belonging to another app, a link-local metadata address. The
  // response never reaches the attacker — the card only renders og tags and a
  // JPEG — so the request itself is the payload, which is exactly what a
  // state-changing GET on an unauthenticated LAN device needs.
  //
  // Residual, stated plainly: this resolves the host and then `http` resolves it
  // again to open the socket, so a record that changes between the two (DNS
  // rebinding) is not covered. Closing that needs the validated address pinned
  // into the connection via a custom HttpClient — more machinery than a blind
  // GET nobody reads the answer to is worth.

  /// Whether [uri] may be contacted at all. Async because a hostname has to be
  /// resolved before its address can be judged.
  Future<bool> _isPermittedTarget(Uri uri) async {
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    if (uri.host.isEmpty) return false;

    // An IP literal needs no DNS, and must not be sent through it: `lookup`
    // on a literal hands the same address straight back, so a failure to
    // resolve would read as "unknown host" rather than "blocked address".
    final literal = InternetAddress.tryParse(uri.host);
    if (literal != null) {
      if (isBlockedAddress(literal)) {
        if (kDebugMode) debugPrint('[LinkPreview] blocked literal ${uri.host}');
        return false;
      }
      return true;
    }

    try {
      final resolved = await InternetAddress.lookup(uri.host).timeout(_timeout);
      if (resolved.isEmpty) return false;
      // ANY blocked answer disqualifies the name. A record that mixes a public
      // address with 127.0.0.1 is the whole trick — checking only the first
      // answer, or only whether some answer is public, walks right into it.
      if (resolved.any(isBlockedAddress)) {
        if (kDebugMode) debugPrint('[LinkPreview] blocked host ${uri.host}');
        return false;
      }
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[LinkPreview] lookup ${uri.host} failed: $e');
      return false;
    }
  }

  /// True for anything that is not a globally routable unicast address:
  /// loopback, RFC1918 private, link-local (which includes the cloud metadata
  /// address), CGNAT, multicast, broadcast, and the reserved/documentation
  /// ranges. Deny-by-range rather than allow-by-range, because the set of
  /// non-public ranges is the one that is actually enumerable.
  @visibleForTesting
  static bool isBlockedAddress(InternetAddress address) {
    if (address.isLoopback || address.isLinkLocal || address.isMulticast) {
      return true;
    }
    final raw = address.rawAddress;
    return address.type == InternetAddressType.IPv4
        ? _isBlockedV4(raw)
        : _isBlockedV6(raw);
  }

  static bool _isBlockedV4(List<int> b) {
    final a = b[0], second = b[1];
    if (a == 0) return true; // 0.0.0.0/8 "this network"
    if (a == 10) return true; // RFC1918
    if (a == 100 && second >= 64 && second <= 127) return true; // CGNAT
    if (a == 127) return true; // loopback
    if (a == 169 && second == 254) return true; // link-local + metadata
    if (a == 172 && second >= 16 && second <= 31) return true; // RFC1918
    if (a == 192 && second == 0) return true; // protocol assignments, TEST-NET-1
    if (a == 192 && second == 168) return true; // RFC1918
    if (a == 198 && (second == 18 || second == 19)) return true; // benchmarking
    if (a == 198 && second == 51) return true; // TEST-NET-2
    if (a == 203 && second == 0) return true; // TEST-NET-3
    if (a >= 224) return true; // multicast, reserved, 255.255.255.255
    return false;
  }

  static bool _isBlockedV6(List<int> b) {
    if (b.every((byte) => byte == 0)) return true; // ::
    if (b[0] == 0xfe && (b[1] & 0xc0) == 0x80) return true; // fe80::/10
    if ((b[0] & 0xfe) == 0xfc) return true; // fc00::/7 unique-local

    // An embedded IPv4 address has to be judged as IPv4 or `::ffff:127.0.0.1`
    // and `64:ff9b::127.0.0.1` sail past every rule above.
    final firstTenZero = b.take(10).every((byte) => byte == 0);
    if (firstTenZero && b[10] == 0xff && b[11] == 0xff) {
      return _isBlockedV4(b.sublist(12)); // ::ffff:0:0/96 mapped
    }
    if (firstTenZero && b[10] == 0 && b[11] == 0) {
      return _isBlockedV4(b.sublist(12)); // ::/96 compatible (deprecated)
    }
    // 64:ff9b::/96 and 64:ff9b:1::/48 — NAT64.
    if (b[0] == 0x00 && b[1] == 0x64 && b[2] == 0xff && b[3] == 0x9b) {
      return _isBlockedV4(b.sublist(12));
    }
    return false;
  }

  /// Reads at most [cap] bytes and then abandons the rest. Breaking out of the
  /// `await for` cancels the subscription, which closes the socket — a page
  /// that streams 40 MB of markup costs us 256 KB.
  Future<Uint8List> _readCapped(http.ByteStream stream, int cap) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      builder.add(chunk);
      if (builder.length >= cap) break;
    }
    return builder.takeBytes();
  }

  static String _decodeHtml(Uint8List bytes, String contentType) {
    if (contentType.contains('iso-8859-1') || contentType.contains('latin1')) {
      return latin1.decode(bytes, allowInvalid: true);
    }
    // allowMalformed matters: the cap above can slice a multi-byte sequence in
    // half, and a FormatException here would throw away a good preview.
    return utf8.decode(bytes, allowMalformed: true);
  }

  // ── Metadata parsing ────────────────────────────────────────────────────
  // Regex rather than an HTML parser: the repo has no html dependency, and the
  // `<head>` of a page is regular enough for this. Attribute order varies
  // between sites, so each tag's attributes are collected into a map instead of
  // being matched positionally.

  static final RegExp _metaTag = RegExp(r'<meta\s[^>]*>', caseSensitive: false);
  static final RegExp _attribute = RegExp(
    '''([\\w:-]+)\\s*=\\s*(?:"([^"]*)"|'([^']*)'|([^\\s">]+))''',
    caseSensitive: false,
  );
  static final RegExp _titleTag =
      RegExp(r'<title[^>]*>([\s\S]*?)</title>', caseSensitive: false);

  static Map<String, String> _parseMetaTags(String html) {
    // Everything we want lives in the head; stopping there avoids scanning
    // (and regex-backtracking over) the whole body.
    final headEnd = html.toLowerCase().indexOf('</head>');
    final head = headEnd > 0 ? html.substring(0, headEnd) : html;

    final result = <String, String>{};
    for (final tag in _metaTag.allMatches(head)) {
      final attrs = <String, String>{};
      for (final a in _attribute.allMatches(tag.group(0)!)) {
        final value = a.group(2) ?? a.group(3) ?? a.group(4);
        if (value != null) attrs[a.group(1)!.toLowerCase()] = value;
      }
      final key = attrs['property'] ?? attrs['name'];
      final content = attrs['content'];
      // First writer wins — duplicated og tags are usually a CMS artefact and
      // the first is the canonical one.
      if (key != null && content != null && content.isNotEmpty) {
        result.putIfAbsent(key.toLowerCase(), () => content);
      }
    }
    return result;
  }

  static String? _parseTitleTag(String html) =>
      _titleTag.firstMatch(html)?.group(1);

  /// Collapses whitespace, unescapes entities, truncates to [max].
  static String? _clean(String? raw, int max) {
    if (raw == null) return null;
    var s = _unescapeEntities(raw).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (s.isEmpty) return null;
    if (s.length > max) s = '${s.substring(0, max).trimRight()}…';
    return s;
  }

  static final RegExp _numericEntity =
      RegExp(r'&#(x?)([0-9a-fA-F]+);', caseSensitive: false);

  static String _unescapeEntities(String s) {
    var out = s
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&lsquo;', '‘')
        .replaceAll('&rsquo;', '’')
        .replaceAll('&ldquo;', '“')
        .replaceAll('&rdquo;', '”')
        .replaceAll('&ndash;', '–')
        .replaceAll('&mdash;', '—')
        .replaceAll('&hellip;', '…')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
    out = out.replaceAllMapped(_numericEntity, (m) {
      final code =
          int.tryParse(m.group(2)!, radix: m.group(1)!.isEmpty ? 10 : 16);
      if (code == null || code < 0 || code > 0x10FFFF) return m.group(0)!;
      return String.fromCharCode(code);
    });
    // Ampersand last, so `&amp;lt;` does not become `<`.
    return out.replaceAll('&amp;', '&');
  }

  // ── Thumbnail ───────────────────────────────────────────────────────────

  Future<String?> _fetchThumbnail(Uri pageUri, String rawImageUrl) async {
    try {
      // `resolve` handles `/img/x.png` and `//cdn/x.png` relative forms.
      final imageUri = pageUri.resolve(_unescapeEntities(rawImageUrl.trim()));
      if (imageUri.scheme != 'http' && imageUri.scheme != 'https') return null;

      final response = await _get(imageUri, accept: 'image/*');
      if (response == null || response.statusCode != 200) return null;

      final type = (response.headers['content-type'] ?? '').toLowerCase();
      if (!type.startsWith('image/')) return null;

      final bytes = await _readCapped(response.stream, _maxImageBytes);
      if (bytes.isEmpty) return null;

      var encoded = await _encodeThumb(bytes, maxEdge: 200, quality: 55);
      if (encoded != null && encoded.length > _maxThumbBase64) {
        // One retry at a smaller size before giving up — a busy photo at 200px
        // routinely lands just over the ceiling.
        encoded = await _encodeThumb(bytes, maxEdge: 120, quality: 35);
      }
      if (encoded == null || encoded.length > _maxThumbBase64) {
        if (kDebugMode) {
          debugPrint('[LinkPreview] thumbnail over budget for $imageUri — '
              'sending a text-only preview');
        }
        return null;
      }
      return encoded;
    } catch (e) {
      if (kDebugMode) debugPrint('[LinkPreview] thumbnail failed: $e');
      return null;
    }
  }

  static Future<String?> _encodeThumb(
    Uint8List bytes, {
    required int maxEdge,
    required int quality,
  }) async {
    final compressed = await ImageCompressor.compressThumbnailBytes(
      bytes,
      maxEdge: maxEdge,
      quality: quality,
    );
    return compressed == null ? null : base64Encode(compressed);
  }

  @visibleForTesting
  void clearCacheForTest() {
    _cache.clear();
    _inFlight.clear();
  }
}
