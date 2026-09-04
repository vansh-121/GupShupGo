import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// What an export should be written as.
enum ExportFormat {
  /// A laid-out document with bubbles, day dividers and embedded photos.
  pdf,

  /// One line per message, plain text.
  text,
}

/// Asks which format to export a conversation as.
///
/// This exists because the two formats are not better and worse versions of each
/// other, they are different objects: the PDF is the one you keep or print, the
/// transcript is the one you search, grep, or paste into something else. Picking
/// silently would take that choice away, and adding a second menu item would put
/// the word "export" in the overflow menu twice.
///
/// Returns null if the sheet is dismissed, which the caller must treat as "do
/// nothing" rather than as a default.
class ExportFormatSheet extends StatelessWidget {
  const ExportFormatSheet({super.key});

  static Future<ExportFormat?> show(BuildContext context) {
    return showModalBottomSheet<ExportFormat>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const ExportFormatSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.textLow.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.ios_share_rounded,
                      size: 19,
                      color: c.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export chat',
                          style: GoogleFonts.poppins(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: c.textHigh,
                          ),
                        ),
                        Text(
                          'Choose a format',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: c.textMid,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _FormatOption(
              colors: c,
              icon: Icons.picture_as_pdf_rounded,
              title: 'PDF document',
              subtitle:
                  'Looks like your chat — bubbles, dates and photos. Best for '
                  'keeping or printing.',
              highlighted: true,
              onTap: () => Navigator.of(context).pop(ExportFormat.pdf),
            ),
            _FormatOption(
              colors: c,
              icon: Icons.description_outlined,
              title: 'Plain text',
              subtitle: 'One line per message. Small, and searchable anywhere.',
              onTap: () => Navigator.of(context).pop(ExportFormat.text),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Text(
                'Only messages saved on this device are included.',
                style: GoogleFonts.poppins(fontSize: 11, color: c.textLow),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatOption extends StatelessWidget {
  const _FormatOption({
    required this.colors,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  final AppThemeColors colors;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Draws the tinted, bordered treatment. Used for the PDF option: it is the
  /// answer for most people, and a first option that looks the same as the second
  /// makes the reader compare two paragraphs before they can act.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: highlighted ? colors.primary.withOpacity(0.08) : colors.chatBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: highlighted
                    ? colors.primary.withOpacity(0.35)
                    : colors.divider,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: highlighted
                        ? colors.primary
                        : colors.textLow.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 21,
                    color: highlighted ? Colors.white : colors.textMid,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textHigh,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          height: 1.35,
                          color: colors.textMid,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: colors.textLow,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
