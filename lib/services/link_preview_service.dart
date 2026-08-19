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

import 'dart:async';
import 'dart:convert';
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
    try {
      final request = http.Request('GET', uri)
        ..followRedirects = true
        ..maxRedirects = 5
        ..headers.addAll({
          'User-Agent': _userAgent,
          'Accept': accept,
          'Accept-Language': 'en',
        });
      return await _client.send(request).timeout(_timeout);
    } catch (e) {
      if (kDebugMode) debugPrint('[LinkPreview] GET $uri failed: $e');
      return null;
    }
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
