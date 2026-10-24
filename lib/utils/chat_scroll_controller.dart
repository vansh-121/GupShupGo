import 'dart:async';

import 'package:flutter/widgets.dart';

/// Scrolls a reversed chat list to its newest message after layout.
///
/// Focus, taps and incoming messages can request the same scroll together.
/// Coalesce those requests and let an active animation finish instead of
/// restarting it during each frame of the keyboard's resize animation.
class ChatScrollController extends ScrollController {
  ChatScrollController({super.initialScrollOffset, super.debugLabel});

  bool _scheduled = false;
  bool _animating = false;
  bool _disposed = false;

  void scrollToLatest() {
    if (_disposed || _scheduled || _animating) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (_disposed || !hasClients) return;
      final target = position.minScrollExtent;
      if ((position.pixels - target).abs() < 1) return;

      _animating = true;
      unawaited(position
          .animateTo(
            target,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          )
          .whenComplete(() => _animating = false));
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
