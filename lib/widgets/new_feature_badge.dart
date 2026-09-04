// The two shapes a "this is new" marker takes.
//
// [NewFeatureDot] goes on containers — an app-bar ⋮, a card title — and means
// "something unseen is behind here". [NewFeatureChip] goes on the destination
// itself and names it outright. Together they form the trail a user follows:
// dot on the ⋮ → dot on the row → pill on the item → tap → all of it gone.
//
// Both listen to [WhatsNewService] directly, so marking a feature seen anywhere
// in the app clears every badge for it without a single `setState` at the call
// sites. That matters because the dot on the home app bar and the pill inside
// Settings are several screens apart.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/services/whats_new_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';

// Re-exported so a screen placing a badge needs one import rather than two —
// naming the anchor is inseparable from placing the dot.
export 'package:video_chat_app/services/whats_new_service.dart'
    show NewFeature, NewFeatureAnchor, WhatsNewService;

/// A small dot overlaid on [child] while any unseen feature sits behind
/// [anchor].
///
/// Renders [child] completely untouched once there is nothing to advertise — no
/// `Stack`, no padding shift — so call sites can leave it wrapped permanently
/// instead of writing a conditional around it.
class NewFeatureDot extends StatelessWidget {
  const NewFeatureDot({
    super.key,
    required this.anchor,
    required this.child,
    this.offset = const Offset(0, 0),
  });

  /// Which entry point this dot speaks for — a [NewFeatureAnchor] constant.
  final String anchor;

  final Widget child;

  /// Nudge for hosts whose glyph does not fill its box. Positive x moves the
  /// dot right, positive y moves it down; negative values push it outside the
  /// child, which is what the two constants below rely on.
  final Offset offset;

  /// For a narrow glyph centred in a wide box — `Icons.more_vert` above all.
  ///
  /// The default corner placement lands squarely on that icon's topmost dot and
  /// hides it, leaving a `⋮` that reads as two dots and a blob. This pushes the
  /// badge up and out into the empty corner instead, so all three dots survive.
  /// Both hosts sit inside a `PopupMenuButton`'s 48 px touch target, which has
  /// room to spare for the overflow.
  static const Offset narrowGlyph = Offset(-4, -3);

  /// For a text host — a card heading with the dot floating beside the word.
  ///
  /// Text fills its box, so anything less than the badge's own width overlaps
  /// the last letter and reads as a stray accent rather than a badge. This
  /// clears the word entirely and leaves a 3 px gap.
  static const Offset besideText = Offset(-15, 0);

  /// Diameter of the coloured dot, before its ring.
  static const double _size = 9;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WhatsNewService.instance,
      builder: (context, _) {
        if (!WhatsNewService.instance.hasUnseenAt(anchor)) return child;

        final c = AppThemeColors.of(context);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              right: offset.dx,
              top: offset.dy,
              child: IgnorePointer(
                child: Container(
                  width: _size + 3,
                  height: _size + 3,
                  decoration: BoxDecoration(
                    color: c.primary,
                    shape: BoxShape.circle,
                    // The ring is the app-bar colour, not white: it is what
                    // separates the dot from the icon glyph underneath, and on
                    // a dark app bar a white ring would read as a second dot.
                    border: Border.all(color: c.surface, width: 1.5),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A "NEW" pill for the destination itself — a menu row or a settings tile.
///
/// Shrinks to nothing once [featureId] has been visited or has aged out, so it
/// can sit unconditionally in a `Row`.
class NewFeatureChip extends StatelessWidget {
  const NewFeatureChip({super.key, required this.featureId});

  /// A [NewFeature] constant.
  final String featureId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WhatsNewService.instance,
      builder: (context, _) {
        if (!WhatsNewService.instance.isNew(featureId)) {
          return const SizedBox.shrink();
        }

        final c = AppThemeColors.of(context);

        return Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: c.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'NEW',
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        );
      },
    );
  }
}
