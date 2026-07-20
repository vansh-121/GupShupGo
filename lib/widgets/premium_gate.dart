/// Reusable premium feature gate widget.
///
/// Wraps any premium feature and shows a beautiful upgrade prompt
/// for free users. Pro users see the child widget as-is.
///
/// Usage:
/// ```dart
/// PremiumGate(
///   featureName: 'Screen Sharing',
///   featureIcon: Icons.screen_share_rounded,
///   child: ScreenShareScreen(),
/// )
/// ```
library premium_gate;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/provider/subscription_provider.dart';
import 'package:video_chat_app/screens/premium_screen.dart';
import 'package:video_chat_app/services/feature_flag_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';

class PremiumGate extends StatelessWidget {
  /// The widget to show when the user has Pro.
  final Widget child;

  /// Feature name shown in the upgrade prompt.
  final String featureName;

  /// Icon shown in the upgrade prompt.
  final IconData featureIcon;

  /// Optional description of why this feature requires Pro.
  final String? description;

  const PremiumGate({
    super.key,
    required this.child,
    required this.featureName,
    this.featureIcon = Icons.workspace_premium_rounded,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    // When Pro feature flag is off, always show the child (no gate)
    if (!FeatureFlagService.instance.isProEnabled) return child;

    final isPro = context.watch<SubscriptionProvider>().isPro;
    if (isPro) return child;

    // Free user — show lock overlay
    return child; // Still show the child but gate the action
  }

  /// Show a bottom sheet upgrade prompt. Call this from onTap handlers
  /// for gated features instead of navigating to the feature.
  ///
  /// Returns `true` if the user just upgraded (bought Pro), `false`
  /// if they dismissed.
  static Future<bool> showUpgradePrompt(
    BuildContext context, {
    required String featureName,
    IconData featureIcon = Icons.workspace_premium_rounded,
    String? description,
  }) async {
    final c = AppThemeColors.of(context);

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UpgradePromptSheet(
        featureName: featureName,
        featureIcon: featureIcon,
        description: description,
        colors: c,
      ),
    );

    return result ?? false;
  }

  /// Check if Pro and either allow or show upgrade prompt.
  /// Returns `true` if the user has Pro (action can proceed).
  /// When the Pro feature flag is off, always returns `true` (no gate).
  static bool checkAndPrompt(
    BuildContext context, {
    required String featureName,
    IconData featureIcon = Icons.workspace_premium_rounded,
    String? description,
  }) {
    // When Pro feature flag is off, let everyone through
    if (!FeatureFlagService.instance.isProEnabled) return true;

    final isPro = context.read<SubscriptionProvider>().isPro;
    if (isPro) return true;

    showUpgradePrompt(
      context,
      featureName: featureName,
      featureIcon: featureIcon,
      description: description,
    );
    return false;
  }
}

class _UpgradePromptSheet extends StatelessWidget {
  final String featureName;
  final IconData featureIcon;
  final String? description;
  final AppThemeColors colors;

  const _UpgradePromptSheet({
    required this.featureName,
    required this.featureIcon,
    this.description,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textLow.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Lock icon with glow
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFD700).withOpacity(0.15),
                      const Color(0xFFFFA500).withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  featureIcon,
                  size: 32,
                  color: const Color(0xFFFFD700),
                ),
              ),
              const SizedBox(height: 16),

              // Feature name
              Text(
                '$featureName is a Pro feature',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textHigh,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                description ??
                    'Upgrade to GupShupGo Pro to unlock $featureName '
                        'and many other premium features.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: colors.textMid,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Upgrade button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PremiumScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.workspace_premium_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Upgrade to Pro',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Not now
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Not now',
                  style: GoogleFonts.poppins(
                    color: colors.textMid,
                    fontSize: 13,
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
