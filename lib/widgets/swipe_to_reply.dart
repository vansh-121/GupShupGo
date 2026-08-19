// WhatsApp-style swipe-right-to-reply.
//
// Wraps a chat bubble. Dragging right translates the bubble and reveals a reply
// arrow underneath it; past the threshold, releasing fires [onReply] and the
// bubble springs back.
//
// No new package for this. The bubble sits inside a vertical `ListView`, and
// Flutter's gesture arena already resolves a horizontal drag against a vertical
// scroll on its own — `onHorizontalDragUpdate` only ever wins once the pointer
// has actually committed to a horizontal direction, so the list keeps scrolling
// normally.
//
// The wrapper must sit *outside* the bubble's existing long-press
// `GestureDetector`: long-press (reactions) and horizontal drag (reply) are
// different recognizers and coexist in the arena, but nesting them the other way
// around puts the drag inside a detector that has already claimed the pointer.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class SwipeToReply extends StatefulWidget {
  final Widget child;

  /// Fired once per gesture, at the moment the drag is released past the
  /// threshold. Never fired mid-drag — that would compose a reply the user is
  /// still in the middle of cancelling.
  final VoidCallback onReply;

  /// Set false for bubbles that cannot be replied to (reactions, and
  /// undecryptable placeholders whose text we do not have to quote).
  final bool enabled;

  const SwipeToReply({
    super.key,
    required this.child,
    required this.onReply,
    this.enabled = true,
  });

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply>
    with SingleTickerProviderStateMixin {
  /// Where the bubble stops travelling, no matter how far the finger goes.
  static const double _maxDrag = 76;

  /// Release past this and the reply fires. Deliberately below [_maxDrag] so the
  /// gesture completes before the bubble hits the wall — the haptic lands while
  /// the finger is still moving, which is what makes it feel responsive.
  static const double _threshold = 64;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  double _offset = 0;

  /// Where the finger let go. The spring-back interpolates from here to 0.
  double _releaseFrom = 0;
  bool _hapticFired = false;

  @override
  void initState() {
    super.initState();
    // One listener for the lifetime of the widget. Attaching a fresh one per
    // gesture and awaiting the TickerFuture would throw TickerCanceled the
    // moment a new drag interrupts a spring-back.
    _controller.addListener(() {
      final t = Curves.easeOutCubic.transform(_controller.value);
      setState(() => _offset = _releaseFrom * (1 - t));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onStart(DragStartDetails details) {
    // Grabbing a bubble mid-spring-back should hand control straight back to
    // the finger rather than fight the animation.
    if (_controller.isAnimating) _controller.stop();
  }

  void _onUpdate(DragUpdateDetails details) {
    final next = (_offset + (details.primaryDelta ?? 0)).clamp(0.0, _maxDrag);
    if (next == _offset) return;

    // One haptic per gesture, on the way out only. Firing it again on the way
    // back in turns a single reply into a stutter of taps.
    if (!_hapticFired && next >= _threshold) {
      _hapticFired = true;
      HapticFeedback.selectionClick();
    }
    setState(() => _offset = next);
  }

  void _onEnd(DragEndDetails details) {
    final fired = _offset >= _threshold;
    _springBack();
    if (fired) widget.onReply();
  }

  void _springBack() {
    _hapticFired = false;
    if (_offset == 0) return;
    _releaseFrom = _offset;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final c = AppThemeColors.of(context);

    return GestureDetector(
      // Drag-right only. `onHorizontalDragUpdate` still sees left deltas, but
      // the clamp in _onUpdate floors them at 0, so a left swipe is inert.
      onHorizontalDragStart: _onStart,
      onHorizontalDragUpdate: _onUpdate,
      onHorizontalDragEnd: _onEnd,
      onHorizontalDragCancel: _springBack,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Behind the bubble, so it appears to be uncovered by the drag rather
          // than flying in. Opacity tracks progress toward the threshold and
          // then holds, which reads as "armed".
          if (_offset > 0)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Opacity(
                opacity: (_offset / _threshold).clamp(0.0, 1.0),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: c.surfaceAlt.withOpacity(0.94),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.reply_rounded, size: 17, color: c.textMid),
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(_offset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
