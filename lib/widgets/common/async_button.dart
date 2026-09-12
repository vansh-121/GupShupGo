import 'package:flutter/material.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/utils/haptics.dart';

/// A filled button that runs an async [onPressed], giving the standard
/// "did my tap register?" feedback in one place: a light haptic on tap, then
/// the button disables itself and swaps its label for a spinner until the work
/// finishes.
///
/// This is the reusable form of the `bool _isLoading + setState + onPressed:
/// flag ? null : fn` idiom re-inlined across ~28 screens. Re-entry is guarded,
/// and the busy flag is always cleared in a `finally` (only if still mounted),
/// so a thrown action can't strand the button in a spinning state.
class AsyncButton extends StatefulWidget {
  const AsyncButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  });

  /// The async work to run. A null value renders the button disabled.
  final Future<void> Function()? onPressed;

  final Widget child;
  final ButtonStyle? style;

  @override
  State<AsyncButton> createState() => _AsyncButtonState();
}

class _AsyncButtonState extends State<AsyncButton> {
  bool _busy = false;

  Future<void> _handle() async {
    if (_busy || widget.onPressed == null) return;
    AppHaptics.tap();
    setState(() => _busy = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = !_busy && widget.onPressed != null;
    return ElevatedButton(
      style: widget.style,
      onPressed: enabled ? _handle : null,
      child: _busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                // Contrast against the filled (primary) button surface.
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : widget.child,
    );
  }
}

/// The [IconButton] counterpart of [AsyncButton]: light haptic on tap, then the
/// icon is swapped for a small spinner and the button disabled until the async
/// [onPressed] completes. Guards re-entry (a double-tap can't fire the action
/// twice) and always resets in a `finally`.
class AsyncIconButton extends StatefulWidget {
  const AsyncIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.color,
    this.tooltip,
    this.iconSize = 24,
  });

  final Future<void> Function()? onPressed;
  final Widget icon;

  /// Icon and spinner colour. Defaults to the theme's high-emphasis text colour.
  final Color? color;
  final String? tooltip;
  final double iconSize;

  @override
  State<AsyncIconButton> createState() => _AsyncIconButtonState();
}

class _AsyncIconButtonState extends State<AsyncIconButton> {
  bool _busy = false;

  Future<void> _handle() async {
    if (_busy || widget.onPressed == null) return;
    AppHaptics.tap();
    setState(() => _busy = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final enabled = !_busy && widget.onPressed != null;
    return IconButton(
      tooltip: widget.tooltip,
      iconSize: widget.iconSize,
      color: widget.color,
      onPressed: enabled ? _handle : null,
      icon: _busy
          ? SizedBox(
              width: widget.iconSize * 0.8,
              height: widget.iconSize * 0.8,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor:
                    AlwaysStoppedAnimation<Color>(widget.color ?? c.textHigh),
              ),
            )
          : widget.icon,
    );
  }
}
