// The composer paperclip's chooser — one sheet for photo, video, document and
// location, shared by every chat surface (online, mesh, anonymous).
//
// It used to be copy-pasted three times: [ChatScreen], [MeshChatScreen] and
// [AnonymousChatScreen] each grew their own `_showAttachSheet`, and the chrome
// drifted apart tile by tile — colored icons in one, plain glyphs in the
// others; a "Share" title and drag handle in one, bare rows in the rest. The
// *actions* were always meant to differ (each transport sends through its own
// backend, and anonymous deliberately drops Document and Location), but the
// *look* was never meant to. This widget owns the look; the call sites pass
// only which tiles to show and what each one does.
//
// The split that survives, because it is real:
//   • which tiles appear — anonymous omits Document and Location (an archive or
//     APK from a stranger is a different risk class, and a pin identifies you);
//   • what each tile does — the `onTap` callbacks route to each screen's own
//     picker/send path;
//   • the view-once toggle's *copy* — the guarantee differs by transport
//     (E2EE key destruction online vs a plaintext one-time viewer elsewhere),
//     so each screen supplies its own wording while sharing the control.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/utils/haptics.dart';
// Brings in NewFeatureChip, plus the re-exported WhatsNewService/NewFeature.
import 'package:video_chat_app/widgets/new_feature_badge.dart';

/// The kinds of attachment a chat can offer. The icon, accent colour, title and
/// subtitles for each live here — not at the call sites — so the four tiles
/// look and read identically wherever they appear.
enum AttachmentKind { photo, video, document, location }

/// Whether view-once even makes sense for a kind. Document and location have no
/// media key to destroy (and a pin carries no media at all), so they are
/// disabled — greyed, not hidden, so the sheet doesn't reshuffle under a thumb —
/// while the toggle is armed.
bool _supportsViewOnce(AttachmentKind kind) =>
    kind == AttachmentKind.photo || kind == AttachmentKind.video;

/// One row the caller chose to show, bound to that screen's send path.
class AttachmentAction {
  const AttachmentAction({
    required this.kind,
    required this.onTap,
    this.newFeatureId,
  });

  final AttachmentKind kind;

  /// Runs after the sheet is dismissed. Receives the armed view-once state;
  /// kinds that ignore it (document, location) simply drop the argument.
  final void Function(bool viewOnce) onTap;

  /// A [NewFeature] id. When set, the row wears a `NEW` pill and is marked seen
  /// on tap. Only the online chat is a discovery anchor today, so mesh and
  /// anonymous leave this null.
  final String? newFeatureId;
}

/// The view-once toggle's configuration. Absent → no toggle, and nothing is
/// ever disabled.
///
/// The subtitle is supplied by the caller because the promise it makes is
/// transport-specific and must stay honest: the online chat really does destroy
/// an encryption key; the plaintext surfaces only block screenshots on Android.
class AttachmentViewOnce {
  const AttachmentViewOnce({
    required this.subtitleOff,
    required this.subtitleOn,
    this.newFeatureId,
  });

  /// Shown on the toggle while view-once is off / on respectively.
  final String subtitleOff;
  final String subtitleOn;

  /// A [NewFeature] id marked seen the first time the switch is armed (turning
  /// it back off is not "discovering" it). The switch also wears a pill for it.
  final String? newFeatureId;
}

/// Show the attachment chooser. Returns when the sheet closes.
///
/// [actions] are rendered top-to-bottom in the order given. [viewOnce], when
/// provided, adds the toggle below a divider and lets it disable the
/// non-media tiles. [footer] is small print under everything (the anonymous
/// "not end-to-end encrypted" note).
Future<void> showAttachmentSheet({
  required BuildContext context,
  required List<AttachmentAction> actions,
  AttachmentViewOnce? viewOnce,
  String? footer,
  String title = 'Share',
}) {
  AppHaptics.tap();
  final c = AppThemeColors.of(context);

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      // Local to the sheet, so it resets on every open: a mode this destructive
      // must never be sticky across sends.
      bool armed = false;
      return StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.textLow.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: c.textHigh,
                  ),
                ),
                const SizedBox(height: 16),
                for (final action in actions)
                  _AttachmentTile(
                    action: action,
                    colors: c,
                    // A tile is disabled only when view-once is armed *and* the
                    // kind can't honour it.
                    disabled: viewOnce != null &&
                        armed &&
                        !_supportsViewOnce(action.kind),
                    armed: armed,
                    hasViewOnce: viewOnce != null,
                    onSelected: () {
                      final id = action.newFeatureId;
                      Navigator.pop(sheetContext);
                      if (id != null) WhatsNewService.instance.markSeen(id);
                      action.onTap(armed);
                    },
                  ),
                if (viewOnce != null) ...[
                  const Divider(height: 20, indent: 16, endIndent: 16),
                  SwitchListTile(
                    value: armed,
                    activeColor: c.primary,
                    onChanged: (v) {
                      AppHaptics.tap();
                      // Turning it *on* is visiting it; turning it back off is
                      // not, and would clear the badge for a user who only
                      // brushed the switch.
                      if (v && viewOnce.newFeatureId != null) {
                        WhatsNewService.instance.markSeen(viewOnce.newFeatureId!);
                      }
                      setSheetState(() => armed = v);
                    },
                    secondary: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: c.primary.withValues(alpha: armed ? 0.16 : 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        armed ? Icons.lock_clock_rounded : Icons.timer_outlined,
                        color: c.primary,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text('View once',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: c.textHigh,
                            )),
                        if (viewOnce.newFeatureId != null)
                          NewFeatureChip(featureId: viewOnce.newFeatureId!),
                      ],
                    ),
                    subtitle: Text(
                      armed ? viewOnce.subtitleOn : viewOnce.subtitleOff,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: c.textLow),
                    ),
                  ),
                ],
                if (footer != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      footer,
                      style:
                          GoogleFonts.poppins(fontSize: 11, color: c.textLow),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// A single attachment row. Pulls its icon, colour and copy from the kind so
/// the four tiles can never drift apart again.
class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.action,
    required this.colors,
    required this.disabled,
    required this.armed,
    required this.hasViewOnce,
    required this.onSelected,
  });

  final AttachmentAction action;
  final AppThemeColors colors;
  final bool disabled;

  /// Whether view-once is currently armed — flips the photo/video subtitle to
  /// its "opens once" wording.
  final bool armed;

  /// Whether a view-once toggle exists at all in this sheet, which decides
  /// whether the disappearing-subtitle wording is ever relevant.
  final bool hasViewOnce;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final accent = _accent(action.kind, colors);
    final showOnce = hasViewOnce && armed && _supportsViewOnce(action.kind);

    return ListTile(
      enabled: !disabled,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: disabled ? 0.04 : 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _icon(action.kind),
          color: accent.withValues(alpha: disabled ? 0.4 : 1),
        ),
      ),
      title: Row(
        children: [
          Text(
            _title(action.kind),
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: colors.textHigh,
            ),
          ),
          if (action.newFeatureId != null)
            NewFeatureChip(featureId: action.newFeatureId!),
        ],
      ),
      subtitle: Text(
        disabled
            ? 'Not available for view once'
            : (showOnce ? _subtitleOnce(action.kind) : _subtitle(action.kind)),
        style: GoogleFonts.poppins(fontSize: 12, color: colors.textLow),
      ),
      onTap: disabled ? null : onSelected,
    );
  }

  static IconData _icon(AttachmentKind kind) {
    switch (kind) {
      case AttachmentKind.photo:
        return Icons.photo_library_rounded;
      case AttachmentKind.video:
        return Icons.video_library_rounded;
      case AttachmentKind.document:
        return Icons.insert_drive_file_rounded;
      case AttachmentKind.location:
        return Icons.location_on_rounded;
    }
  }

  static Color _accent(AttachmentKind kind, AppThemeColors c) {
    switch (kind) {
      case AttachmentKind.photo:
        return c.online;
      case AttachmentKind.video:
        return Colors.orange;
      case AttachmentKind.document:
        return Colors.indigo;
      case AttachmentKind.location:
        return Colors.redAccent;
    }
  }

  static String _title(AttachmentKind kind) {
    switch (kind) {
      case AttachmentKind.photo:
        return 'Photo';
      case AttachmentKind.video:
        return 'Video';
      case AttachmentKind.document:
        return 'Document';
      case AttachmentKind.location:
        return 'Location';
    }
  }

  static String _subtitle(AttachmentKind kind) {
    switch (kind) {
      case AttachmentKind.photo:
        return 'Choose an image from your gallery';
      case AttachmentKind.video:
        return 'Choose a video from your gallery';
      case AttachmentKind.document:
        return 'PDF, Office file, archive — sent as-is';
      case AttachmentKind.location:
        return 'Share your current location';
    }
  }

  static String _subtitleOnce(AttachmentKind kind) {
    switch (kind) {
      case AttachmentKind.photo:
        return 'Opens once, then it\'s gone';
      case AttachmentKind.video:
        return 'Plays once, then it\'s gone';
      case AttachmentKind.document:
      case AttachmentKind.location:
        return 'Not available for view once';
    }
  }
}
