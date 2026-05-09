import 'package:flutter/material.dart';
import 'package:video_chat_app/main.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// Version shown to the user. Must match pubspec.yaml version name.
const String kCurrentVersion = '1.0.6';
const String _prefKey = 'pref_whats_new_version';

/// Call this once the home screen is mounted. Shows the dialog only when the
/// stored version differs from [kCurrentVersion] (i.e. first launch after update).
Future<void> maybeShowWhatsNew(BuildContext context) async {
  final seen = sharedPrefs.getString(_prefKey);
  if (seen == kCurrentVersion) return;

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _WhatsNewDialog(),
  );

  await sharedPrefs.setString(_prefKey, kCurrentVersion);
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
    Icons.bug_report_rounded,
    'Crash Reporting',
    'Firebase Crashlytics now automatically captures and reports any app crashes for faster fixes.',
  ),
  _Feature(
    Icons.speed_rounded,
    'Performance Monitoring',
    'Firebase Performance Monitoring tracks call setup time, message speed, and upload performance in real-time.',
  ),
  _Feature(
    Icons.videocam_rounded,
    'Clearer Video Calls',
    'Video quality upgraded to 720p @ 2000 kbps with smooth 30 fps — sharper, lag-free calls.',
  ),
];
