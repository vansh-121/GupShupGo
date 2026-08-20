// StarterChecklistCard — the "No chats yet" state, turned into something the
// user can act on.
//
// The old empty state said "Start a conversation by tapping the button below"
// and offered one button. That is accurate but it teaches nothing: a new user
// has no photo, no contacts synced, and no idea the app works without internet.
// A short checklist converts better than a narrative walkthrough because every
// line is a tap that does the thing it describes.
//
// Completion is deliberately mixed-source. "Add a photo" reads real profile
// state, so it cannot be faked and un-completes if the photo is removed. The
// other two only record that the user *visited* the feature — whether they then
// synced contacts or found a nearby peer depends on permissions and on someone
// else being in range, neither of which is a fair bar for a checklist. Marking
// on visit keeps the list honest about what it is tracking: "you have seen
// this", not "you succeeded at this".
//
// Once every step is done the card stops rendering entirely (the caller falls
// back to the plain empty state) so it does not outlive its usefulness.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/main.dart';
import 'package:video_chat_app/theme/app_theme.dart';

const String _kVisitedContactsKey = 'starter_v1_visited_contacts';
const String _kVisitedMeshKey = 'starter_v1_visited_mesh';

/// Records that the user opened the people/contacts screen. Called from the
/// checklist itself and safe to call from any other entry point to that screen.
Future<void> markStarterContactsVisited() =>
    sharedPrefs.setBool(_kVisitedContactsKey, true);

/// Records that the user opened offline/mesh chat.
Future<void> markStarterMeshVisited() =>
    sharedPrefs.setBool(_kVisitedMeshKey, true);

class StarterChecklistCard extends StatefulWidget {
  const StarterChecklistCard({
    super.key,
    required this.hasPhoto,
    required this.onAddPhoto,
    required this.onFindPeople,
    required this.onTryOffline,
  });

  /// Whether the signed-in user already has a profile photo.
  final bool hasPhoto;

  /// Each opens the relevant screen. Awaited so the checkmarks refresh the
  /// moment the user comes back.
  final Future<void> Function() onAddPhoto;
  final Future<void> Function() onFindPeople;
  final Future<void> Function() onTryOffline;

  /// True when there is nothing left to show, so the caller can render the
  /// plain empty state instead.
  static bool isComplete({required bool hasPhoto}) =>
      hasPhoto &&
      (sharedPrefs.getBool(_kVisitedContactsKey) ?? false) &&
      (sharedPrefs.getBool(_kVisitedMeshKey) ?? false);

  @override
  State<StarterChecklistCard> createState() => _StarterChecklistCardState();
}

class _StarterChecklistCardState extends State<StarterChecklistCard> {
  bool get _contactsDone => sharedPrefs.getBool(_kVisitedContactsKey) ?? false;
  bool get _meshDone => sharedPrefs.getBool(_kVisitedMeshKey) ?? false;

  /// Runs [action], records the visit, then refreshes so the tick appears.
  /// The pref is written before awaiting so a step still counts as seen even
  /// if the user backs out of the screen immediately.
  Future<void> _run(
    Future<void> Function() action, {
    Future<void> Function()? mark,
  }) async {
    if (mark != null) await mark();
    if (mounted) setState(() {});
    await action();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);

    final steps = <_Step>[
      _Step(
        icon: Icons.add_a_photo_rounded,
        title: 'Add a profile photo',
        body: 'So friends recognise you when you say hi.',
        done: widget.hasPhoto,
        onTap: () => _run(widget.onAddPhoto),
      ),
      _Step(
        icon: Icons.group_add_rounded,
        title: 'Find people you know',
        body: 'Sync your contacts or search by @username.',
        done: _contactsDone,
        onTap: () =>
            _run(widget.onFindPeople, mark: markStarterContactsVisited),
      ),
      _Step(
        icon: Icons.sensors_rounded,
        title: 'Try offline chat',
        body: 'Message people nearby with no internet at all.',
        done: _meshDone,
        onTap: () => _run(widget.onTryOffline, mark: markStarterMeshVisited),
      ),
    ];

    final doneCount = steps.where((s) => s.done).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header + progress ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  'Get started',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: c.textHigh,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: c.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$doneCount of ${steps.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: c.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: doneCount / steps.length,
              minHeight: 5,
              backgroundColor: c.primary.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(c.primary),
            ),
          ),
          const SizedBox(height: 6),
          ...steps.map((s) => _StepRow(step: s)),
        ],
      ),
    );
  }
}

class _Step {
  const _Step({
    required this.icon,
    required this.title,
    required this.body,
    required this.done,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool done;
  final VoidCallback onTap;
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});
  final _Step step;

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);

    return InkWell(
      onTap: step.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        child: Row(
          children: [
            // Tick when done, feature icon while pending — the icon doubles as
            // a hint about where the step leads.
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: step.done
                    ? c.success.withOpacity(0.14)
                    : c.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                step.done ? Icons.check_rounded : step.icon,
                size: 18,
                color: step.done ? c.success : c.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: step.done ? c.textMid : c.textHigh,
                      decoration: step.done ? TextDecoration.lineThrough : null,
                      decorationColor: c.textLow,
                    ),
                  ),
                  if (!step.done) ...[
                    const SizedBox(height: 2),
                    Text(
                      step.body,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: c.textMid,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!step.done)
              Icon(Icons.chevron_right_rounded, color: c.textLow, size: 20),
          ],
        ),
      ),
    );
  }
}
