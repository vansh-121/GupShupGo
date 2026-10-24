import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/l10n/app_localizations.dart';
import 'package:video_chat_app/l10n/app_locales.dart';
import 'package:video_chat_app/provider/locale_provider.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// Lets the user pick the app language (or follow the device). The list is
/// driven by [AppLocalizations.supportedLocales], so every language that has an
/// `app_<code>.arb` appears automatically; names render natively via
/// [languageNativeName]. The choice is persisted by [LocaleProvider] and applied
/// live (MaterialApp rebuilds on notify).
class LanguagePickerScreen extends StatelessWidget {
  const LanguagePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final t = AppLocalizations.of(context);
    final localeProvider = context.watch<LocaleProvider>();

    // Stable ordering: English first, then by English name so the list doesn't
    // reshuffle as ARBs are discovered in filesystem order.
    final locales = AppLocalizations.supportedLocales.toList()
      ..sort((a, b) {
        if (a.languageCode == 'en') return -1;
        if (b.languageCode == 'en') return 1;
        return languageEnglishName(a.languageCode)
            .compareTo(languageEnglishName(b.languageCode));
      });

    final current = localeProvider.locale?.languageCode;

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        title: Text(
          t.languagePickerTitle,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: c.textHigh,
          ),
        ),
      ),
      body: ListView(
        children: [
          _LanguageTile(
            title: t.languageSystemDefault,
            subtitle: t.languageSystemDefaultSubtitle,
            selected: localeProvider.isSystem,
            onTap: () {
              context.read<LocaleProvider>().setLocale(null);
              Navigator.of(context).pop();
            },
            colors: c,
          ),
          Divider(height: 1, color: c.divider),
          for (final locale in locales)
            _LanguageTile(
              title: languageNativeName(locale.languageCode),
              // English name as a secondary line so a user who can't read the
              // script can still identify the language. Hidden for English
              // itself (native == English name).
              subtitle: locale.languageCode == 'en'
                  ? null
                  : languageEnglishName(locale.languageCode),
              selected: current == locale.languageCode,
              onTap: () {
                context.read<LocaleProvider>().setLocale(locale);
                Navigator.of(context).pop();
              },
              colors: c,
            ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.colors,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15.5,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: c.textHigh,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: GoogleFonts.poppins(fontSize: 12.5, color: c.textMid),
            ),
      trailing: selected
          ? Icon(Icons.check_rounded, color: c.primary, size: 22)
          : null,
    );
  }
}
