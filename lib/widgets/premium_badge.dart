/// Small "PRO" badge widget.
///
/// Displays a compact gradient badge next to Pro users' names in chats,
/// contacts, profiles, and the app bar.
library premium_badge;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/services/feature_flag_service.dart';

class PremiumBadge extends StatelessWidget {
  /// Size variant: `small` for inline text, `medium` for profile cards.
  final PremiumBadgeSize size;

  const PremiumBadge({super.key, this.size = PremiumBadgeSize.small});

  @override
  Widget build(BuildContext context) {
    // Hide badge entirely when Pro feature flag is off
    if (!FeatureFlagService.instance.isProEnabled) {
      return const SizedBox.shrink();
    }

    final isSmall = size == PremiumBadgeSize.small;
    final fontSize = isSmall ? 8.0 : 10.0;
    final hPad = isSmall ? 5.0 : 7.0;
    final vPad = isSmall ? 1.5 : 2.5;
    final iconSize = isSmall ? 8.0 : 11.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            size: iconSize,
            color: Colors.white,
          ),
          SizedBox(width: isSmall ? 2 : 3),
          Text(
            'PRO',
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.8,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

enum PremiumBadgeSize { small, medium }
