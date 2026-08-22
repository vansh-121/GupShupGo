// Boundary behaviour of chat-message URL detection.
//
// Every case here is a bubble a user can actually produce by typing. The
// detector is deliberately conservative — a wrong underline in a chat bubble is
// worse than a missing one — so roughly half these tests assert that something
// is NOT a link. Those are the ones that matter: an over-eager matcher turns
// `file.txt`, `v1.2.3` and every e-mail address into a tappable link that opens
// a browser on a URL that was never a URL.

import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/utils/link_extractor.dart';

/// Convenience: the URLs only, in order.
List<String> _urls(String text) =>
    extractLinks(text).map((s) => s.url).toList();

void main() {
  group('matches real links', () {
    test('a bare https URL', () {
      expect(_urls('https://flutter.dev'), ['https://flutter.dev']);
    });

    test('a URL mid-sentence', () {
      expect(_urls('check out https://flutter.dev today'),
          ['https://flutter.dev']);
    });

    test('http as well as https', () {
      expect(_urls('http://example.com/x'), ['http://example.com/x']);
    });

    test('a path, query and fragment survive intact', () {
      const url = 'https://a.com/search?q=dart&page=2#results';
      expect(_urls('see $url'), [url]);
    });

    test('multiple URLs in one message, in order', () {
      expect(
        _urls('https://a.com and then https://b.com'),
        ['https://a.com', 'https://b.com'],
      );
    });

    test('an uppercase scheme still matches', () {
      // Uri lowercases the scheme when parsing, so launchUrl is happy; we keep
      // the string as typed so the bubble shows what the user wrote.
      expect(_urls('HTTPS://FLUTTER.DEV'), ['HTTPS://FLUTTER.DEV']);
    });
  });

  group('bare www hosts', () {
    test('get an https:// scheme prepended so they are launch-ready', () {
      expect(_urls('see www.flutter.dev now'), ['https://www.flutter.dev']);
    });

    test('the span still covers only what the user typed', () {
      // LinkifiedText slices the plain runs around [start, end), so the span
      // must NOT grow to cover the synthesised scheme.
      final spans = extractLinks('see www.flutter.dev now');
      expect(spans, hasLength(1));
      expect(
          'see www.flutter.dev now'
              .substring(spans.first.start, spans.first.end),
          'www.flutter.dev');
    });

    test('"www." on its own is not a link', () {
      expect(extractLinks('www.'), isEmpty);
      expect(extractLinks('brb www. later'), isEmpty);
    });
  });

  group('trailing punctuation is not part of the URL', () {
    test('a sentence-ending period', () {
      expect(_urls('go to https://flutter.dev.'), ['https://flutter.dev']);
    });

    test('a question mark', () {
      expect(_urls('seen https://a.com/x?'), ['https://a.com/x']);
    });

    test('comma, semicolon, colon, bang, ellipsis', () {
      for (final tail in [',', ';', ':', '!', '…', '?!']) {
        expect(_urls('https://a.com$tail'), ['https://a.com'],
            reason: 'trailing "$tail" should not be part of the URL');
      }
    });

    test('but punctuation inside a path is kept', () {
      expect(_urls('https://a.com/a,b'), ['https://a.com/a,b']);
      expect(_urls('https://a.com/a!b'), ['https://a.com/a!b']);
    });
  });

  group('brackets are balanced, not blanket-stripped', () {
    test('a URL wrapped in parentheses drops the closing paren', () {
      expect(_urls('(see https://a.com/x)'), ['https://a.com/x']);
    });

    test('a URL whose own path contains balanced parens keeps them', () {
      const url = 'https://en.wikipedia.org/wiki/Dart_(programming_language)';
      expect(_urls(url), [url]);
    });

    test('square brackets and braces behave the same way', () {
      expect(_urls('[https://a.com/x]'), ['https://a.com/x']);
      expect(_urls('{https://a.com/x}'), ['https://a.com/x']);
    });
  });

  group('does NOT match', () {
    test('an e-mail address', () {
      // The @ boundary check is the only thing standing between this and a
      // tappable "https://www.example.com" inside someone's address.
      expect(extractLinks('mail me at someone@www.example.com'), isEmpty);
      expect(extractLinks('someone@example.com'), isEmpty);
    });

    test('a filename that merely contains a dot', () {
      expect(extractLinks('open file.txt please'), isEmpty);
      expect(extractLinks('report.pdf'), isEmpty);
    });

    test('a bare domain with no scheme and no www', () {
      // Intentional: matching this means matching every version number and
      // abbreviation too. The sender can type the scheme.
      expect(extractLinks('flutter.dev is great'), isEmpty);
    });

    test('a version number or an initialled name', () {
      expect(extractLinks('upgrade to v1.2.3'), isEmpty);
      expect(extractLinks('ask Mr.Smith'), isEmpty);
    });

    test('a scheme with no host after it', () {
      expect(extractLinks('https://'), isEmpty);
      expect(extractLinks('http:// nothing'), isEmpty);
    });

    test('a scheme glued to the end of another word', () {
      expect(extractLinks('xhttps://a.com'), isEmpty);
    });

    test('empty and whitespace-only text', () {
      expect(extractLinks(''), isEmpty);
      expect(extractLinks('   \n  '), isEmpty);
    });
  });

  group('span offsets', () {
    test('index into the original string, not a normalised copy', () {
      const text = 'check out https://flutter.dev today';
      final spans = extractLinks(text);
      expect(spans, hasLength(1));
      expect(text.substring(spans.first.start, spans.first.end),
          'https://flutter.dev');
    });

    test('are correct with unicode text before the link', () {
      // Offsets are UTF-16 code units — the same units String.substring uses —
      // so a slice by those offsets must round-trip even past an emoji
      // surrogate pair or a Devanagari run.
      for (final prefix in ['🎉 ', 'देखो ', 'ñÿ — ']) {
        final text = '${prefix}https://flutter.dev ok';
        final spans = extractLinks(text);
        expect(spans, hasLength(1), reason: 'prefix "$prefix"');
        expect(text.substring(spans.first.start, spans.first.end),
            'https://flutter.dev',
            reason: 'prefix "$prefix"');
      }
    });

    test('do not overlap for adjacent links', () {
      const text = 'https://a.com https://b.com';
      final spans = extractLinks(text);
      expect(spans, hasLength(2));
      expect(spans[0].end, lessThanOrEqualTo(spans[1].start));
    });
  });

  group('firstLinkIn', () {
    test('returns the first link only — WhatsApp previews one card', () {
      expect(firstLinkIn('https://a.com then https://b.com'), 'https://a.com');
    });

    test('normalises a bare www host', () {
      expect(firstLinkIn('www.flutter.dev'), 'https://www.flutter.dev');
    });

    test('returns null when there is nothing to unfurl', () {
      expect(firstLinkIn('no links here at all'), isNull);
      expect(firstLinkIn(''), isNull);
    });
  });

  test('LinkSpan equality is by value so widget diffing works', () {
    const a = LinkSpan(start: 0, end: 5, url: 'https://a.com');
    const b = LinkSpan(start: 0, end: 5, url: 'https://a.com');
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });
}
