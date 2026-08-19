// URL detection inside chat message text.
//
// Deliberately conservative: only `http://`, `https://` and bare `www.` are
// treated as links. Bare domains (`flutter.dev`) are NOT matched — linkifying
// them means linkifying `file.txt`, `v1.2` and `Mr.Smith` too, and a wrong
// underline in a chat bubble is worse than a missing one. The sender can always
// type the scheme.
//
// No `flutter_linkify` dependency: this is ~60 lines, and every dep in this
// repo carries a "why this version" pin comment because of the FVM-pinned SDK.

/// One matched URL inside a larger string.
///
/// [start] and [end] index into the *original* text (end exclusive) so the
/// caller can slice the surrounding plain runs. [url] is launch-ready — a
/// scheme is always present, even when the user typed a bare `www.` host.
class LinkSpan {
  final int start;
  final int end;
  final String url;

  const LinkSpan({required this.start, required this.end, required this.url});

  @override
  String toString() => 'LinkSpan($start-$end, $url)';

  @override
  bool operator ==(Object other) =>
      other is LinkSpan &&
      other.start == start &&
      other.end == end &&
      other.url == url;

  @override
  int get hashCode => Object.hash(start, end, url);
}

final RegExp _urlPattern = RegExp(
  r'(?:https?://|www\.)[^\s<>"' "'" r'`]+',
  caseSensitive: false,
);

/// Punctuation that terminates a sentence rather than belonging to the URL.
const String _trailingJunk = '.,;:!?*_~’”…';

/// Characters that may not precede a link start. Prevents matching inside a
/// longer token (`xhttps://…`) and inside an e-mail local part
/// (`someone@www.example.com`).
bool _validBoundary(String text, int start) {
  if (start == 0) return true;
  final prev = text.codeUnitAt(start - 1);
  // @ — e-mail. Letters/digits — mid-token. . / - / _ — mid-token too.
  if (prev == 0x40 || prev == 0x2E || prev == 0x2D || prev == 0x5F)
    return false;
  final isLetter =
      (prev >= 0x41 && prev <= 0x5A) || (prev >= 0x61 && prev <= 0x7A);
  final isDigit = prev >= 0x30 && prev <= 0x39;
  return !isLetter && !isDigit;
}

/// Walks back over trailing punctuation and unbalanced closing brackets.
///
/// `(see https://a.com/x)` must not swallow the `)`, but
/// `https://en.wikipedia.org/wiki/Dart_(language)` must keep it — hence the
/// balance count rather than a blanket strip.
int _trimEnd(String text, int start, int end) {
  var e = end;
  while (e > start) {
    final ch = text[e - 1];
    if (_trailingJunk.contains(ch)) {
      e--;
      continue;
    }
    if (ch == ')' || ch == ']' || ch == '}') {
      final open = ch == ')' ? '(' : (ch == ']' ? '[' : '{');
      final slice = text.substring(start, e);
      final opens = slice.split(open).length - 1;
      final closes = slice.split(ch).length - 1;
      if (closes > opens) {
        e--;
        continue;
      }
    }
    break;
  }
  return e;
}

/// Every http(s) link in [text], in order of appearance.
List<LinkSpan> extractLinks(String text) {
  if (text.isEmpty) return const [];
  final spans = <LinkSpan>[];

  for (final m in _urlPattern.allMatches(text)) {
    final start = m.start;
    if (!_validBoundary(text, start)) continue;

    final end = _trimEnd(text, start, m.end);
    final raw = text.substring(start, end);

    // `www.` on its own, or a scheme with nothing after it, is not a link.
    final lower = raw.toLowerCase();
    final bareWww = lower.startsWith('www.');
    if (bareWww && raw.length <= 'www.'.length + 1) continue;
    if (!bareWww) {
      final schemeEnd = lower.indexOf('://') + 3;
      if (raw.length <= schemeEnd) continue;
    }

    final url = bareWww ? 'https://$raw' : raw;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) continue;

    spans.add(LinkSpan(start: start, end: end, url: url));
  }

  return spans;
}

/// The first link in [text], or null. Used by the composer to decide which URL
/// to unfurl — WhatsApp previews the first link only.
String? firstLinkIn(String text) {
  final spans = extractLinks(text);
  return spans.isEmpty ? null : spans.first.url;
}
