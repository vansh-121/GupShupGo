import 'package:flutter/material.dart';
import 'package:video_chat_app/main.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// Version shown to the user. Must match pubspec.yaml version name.
const String kCurrentVersion = '1.1.7';
const String _prefKey = 'pref_whats_new_version';

/// Call this once the home screen is mounted. Shows the dialog only for users
/// who UPDATED from an older version — never for a first-time install.
///
/// A brand-new user has no stored version, so "What's New" would be meaningless
/// (there is no "old" to compare against). On a fresh production launch every
/// user is new, so without this guard the whole user base would see a changelog
/// of internal fixes on their very first open. Instead we silently record the
/// current version and only surface the dialog on a genuine future update.
Future<void> maybeShowWhatsNew(BuildContext context) async {
  final seen = sharedPrefs.getString(_prefKey);

  // Already saw this version's dialog.
  if (seen == kCurrentVersion) return;

  // First install (nothing recorded yet): suppress the dialog, just remember
  // the version so the NEXT update shows correctly.
  if (seen == null) {
    await sharedPrefs.setString(_prefKey, kCurrentVersion);
    return;
  }

  // Existing user who updated from an older version → show what changed.
  if (!context.mounted) return;

  await showWhatsNewDialog(context);

  await sharedPrefs.setString(_prefKey, kCurrentVersion);
}

/// Opens the changelog on demand, with none of [maybeShowWhatsNew]'s gating.
///
/// The automatic dialog fires once per update and is easy to dismiss without
/// reading; this is the way back to it — the overflow menu's "What's New" item.
/// It deliberately does not touch the stored version, so asking to see the
/// changelog never suppresses the next update's automatic showing.
Future<void> showWhatsNewDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _WhatsNewDialog(),
  );
}

class _WhatsNewDialog extends StatelessWidget {
  const _WhatsNewDialog();

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: colors.cardBg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(colors: colors),
              const SizedBox(height: 20),
              ..._features.map((f) => _FeatureRow(feature: f, colors: colors)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Got it!',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.colors});
  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: colors.primaryLt,
            shape: BoxShape.circle,
          ),
          child:
              Icon(Icons.auto_awesome_rounded, color: colors.primary, size: 32),
        ),
        const SizedBox(height: 14),
        Text(
          "What's New",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colors.textHigh,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Version $kCurrentVersion',
          style: TextStyle(fontSize: 13, color: colors.textMid),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature, required this.colors});
  final _Feature feature;
  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.primaryLt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(feature.icon, color: colors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textHigh,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.description,
                  style: TextStyle(
                      fontSize: 13, color: colors.textMid, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature {
  const _Feature(this.icon, this.title, this.description);
  final IconData icon;
  final String title;
  final String description;
}

const List<_Feature> _features = [
  _Feature(
    Icons.palette_rounded,
    'Chat Themes',
    'Give every conversation its own look — backgrounds and bubble colours that follow light and dark mode.',
  ),
  _Feature(
    Icons.picture_as_pdf_rounded,
    'Export Chats as PDF',
    'Save a chat as a beautifully laid out PDF you can print or keep — real bubbles, your photos included, not just a text file.',
  ),
  _Feature(
    Icons.mic_rounded,
    'Longer Voice Messages',
    'Voice notes now run up to 2 minutes, so you have plenty of time to say what you need.',
  ),
  _Feature(
    Icons.hd_rounded,
    'Higher-Quality Media',
    'Send sharper photos and status videos up to 90 seconds, so nothing important gets compressed away.',
  ),
];
