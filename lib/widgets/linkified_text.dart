// Message text with tappable links.
//
// A drop-in replacement for the plain `Text` that chat bubbles used to render.
// The caller supplies the full [style] so each screen keeps its own font size
// and — importantly — its own emoji `fontFamilyFallback` list: dropping that
// fallback turns every emoji in the app into a tofu box on some OEM ROMs.
//
// Stateful because each link span owns a `TapGestureRecognizer`, and those must
// be disposed. Rebuilding them on every `build()` leaks one recognizer per
// frame per bubble, which a scrolling chat list will notice.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../utils/link_extractor.dart';
import '../utils/url_opener.dart';

class LinkifiedText extends StatefulWidget {
  final String text;

  /// Style for the plain runs. Passed through verbatim.
  final TextStyle style;

  /// Colour for the link runs. Links are always underlined on top of this.
  final Color linkColor;

  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  /// Overrides the default "open in browser" behaviour. Used by nothing today;
  /// present so a future in-app browser has a seam.
  final void Function(String url)? onLinkTap;

  const LinkifiedText(
    this.text, {
    super.key,
    required this.style,
    required this.linkColor,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.onLinkTap,
  });

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  final List<TapGestureRecognizer> _recognizers = [];
  List<LinkSpan> _links = const [];

  @override
  void initState() {
    super.initState();
    _rebuild();
  }

  @override
  void didUpdateWidget(LinkifiedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _rebuild();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  void _rebuild() {
    _disposeRecognizers();
    _links = extractLinks(widget.text);
    for (final link in _links) {
      _recognizers.add(TapGestureRecognizer()
        ..onTap = () {
          if (widget.onLinkTap != null) {
            widget.onLinkTap!(link.url);
          } else {
            openExternalUrl(context, link.url);
          }
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fast path: the overwhelming majority of messages contain no link, and a
    // plain Text is cheaper to lay out than a TextSpan tree.
    if (_links.isEmpty) {
      return Text(
        widget.text,
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
        textAlign: widget.textAlign,
      );
    }

    final linkStyle = widget.style.copyWith(
      color: widget.linkColor,
      decoration: TextDecoration.underline,
      decorationColor: widget.linkColor,
    );

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (var i = 0; i < _links.length; i++) {
      final link = _links[i];
      if (link.start > cursor) {
        spans.add(TextSpan(text: widget.text.substring(cursor, link.start)));
      }
      spans.add(TextSpan(
        text: widget.text.substring(link.start, link.end),
        style: linkStyle,
        recognizer: _recognizers[i],
      ));
      cursor = link.end;
    }
    if (cursor < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(cursor)));
    }

    return Text.rich(
      TextSpan(style: widget.style, children: spans),
      maxLines: widget.maxLines,
      overflow: widget.overflow ?? TextOverflow.clip,
      textAlign: widget.textAlign ?? TextAlign.start,
    );
  }
}
