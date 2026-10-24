import 'dart:async';

import 'package:flutter/widgets.dart';

/// Waits for the input's route and its first layout to finish before opening
/// the IME. A route that was dismissed or covered must never reclaim focus.
Future<bool> waitForInputRoute(BuildContext context) async {
  await WidgetsBinding.instance.endOfFrame;
  if (!context.mounted) return false;

  final route = ModalRoute.of(context);
  if (route != null && (!route.isCurrent || !route.isActive)) return false;
  final animation = route?.animation;
  if (route != null && animation != null && !animation.isCompleted) {
    if (animation.status == AnimationStatus.reverse) return false;
    final ready = Completer<void>();
    void onStatus(AnimationStatus status) {
      if (!ready.isCompleted &&
          (status == AnimationStatus.completed ||
              status == AnimationStatus.reverse ||
              status == AnimationStatus.dismissed)) {
        ready.complete();
      }
    }

    animation.addStatusListener(onStatus);
    try {
      await Future.any<void>([
        ready.future,
        route.popped.then<void>((_) {}),
      ]);
    } finally {
      animation.removeStatusListener(onStatus);
    }
    await WidgetsBinding.instance.endOfFrame;
  }

  return context.mounted &&
      (route == null ||
          (route.isCurrent &&
              route.isActive &&
              (animation == null || animation.isCompleted)));
}

/// Opens an entry field once it can accept input, keeping any field the user
/// has already selected. The predicate cancels stale requests after a step
/// change, a submit, or a system authentication prompt.
Future<void> focusInputWhenReady(
  BuildContext context,
  FocusNode node, {
  bool Function()? shouldFocus,
  bool preserveUserFocus = true,
}) async {
  if (shouldFocus?.call() == false || !await waitForInputRoute(context)) return;
  if (shouldFocus?.call() == false) return;
  final inputContext = node.context;
  if (inputContext == null || !inputContext.mounted || !node.canRequestFocus) {
    return;
  }

  final primary = FocusManager.instance.primaryFocus;
  if (preserveUserFocus &&
      primary != node &&
      primary?.context?.findAncestorStateOfType<EditableTextState>() != null) {
    return;
  }

  final input = inputContext.findAncestorStateOfType<EditableTextState>();
  if (input != null) {
    // requestKeyboard also works when Android's Back button hid the keyboard
    // while the field kept focus. It preserves the existing input connection.
    input.requestKeyboard();
  } else {
    node.requestFocus();
  }
}
