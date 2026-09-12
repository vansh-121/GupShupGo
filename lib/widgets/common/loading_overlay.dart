import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// A themed, blocking loading overlay shown for the span of an async action.
///
/// Replaces the `showDialog(barrierDismissible: false, ...)` +
/// `Center(CircularProgressIndicator())` snippet that was copy-pasted at several
/// call sites (safety-number compute, report-problem submit, account delete).
/// It shows a modal barrier with a spinner and an optional message, runs
/// [action], and **always** removes the barrier in a `finally` — even if
/// [action] throws — so a failure can never leave the UI wedged behind an
/// un-dismissable spinner.
///
/// IMPORTANT: keep navigation OUTSIDE [action]. When [action] finishes this
/// pops the top route to remove its own barrier; if [action] had itself
/// pushed/replaced a route, that pop would remove the wrong one. Do the async
/// work inside, then navigate after `during` returns.
class LoadingOverlay {
  LoadingOverlay._();

  static Future<T> during<T>(
    BuildContext context,
    Future<T> Function() action, {
    String? message,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);

    // Not awaited: the dialog future only completes once we pop it below. Our
    // call sites always await real async work before the `finally`, so the
    // barrier is on screen by the time we pop it.
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      useRootNavigator: true,
      builder: (_) => _OverlayBody(message: message),
    ));

    try {
      return await action();
    } finally {
      if (navigator.canPop()) navigator.pop();
    }
  }
}

class _OverlayBody extends StatelessWidget {
  const _OverlayBody({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return PopScope(
      // Block the hardware back button while the action is in flight.
      canPop: false,
      // `showDialog` does not provide a Material ancestor for a bare Container,
      // so without this the Text renders with Flutter's debug default style
      // (black, double yellow underline). Transparent so the barrier and our
      // own card background show through unchanged.
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            decoration: BoxDecoration(
              color: c.cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(c.primary),
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: c.textHigh,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
