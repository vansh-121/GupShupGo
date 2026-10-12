/// Display metadata for the languages GupShupGo can run in.
///
/// The set of locales the app actually *offers* comes from
/// `AppLocalizations.supportedLocales` (generated from the `app_<code>.arb`
/// files present in `lib/l10n/`). This table only maps a language code to the
/// name shown in the picker — in that language's own script, since a language
/// name should read natively regardless of the current UI language (हिन्दी is
/// always "हिन्दी"). It intentionally covers every *planned* language, so when
/// the translation tool drops in a new ARB the picker labels it correctly with
/// no code change. Unknown codes fall back to the raw code.
library;

/// languageCode → (native name shown in the picker, English name for a11y).
const Map<String, ({String native, String english})> kAppLanguages = {
  'en': (native: 'English', english: 'English'),
  'hi': (native: 'हिन्दी', english: 'Hindi'),
  'es': (native: 'Español', english: 'Spanish'),
  'ar': (native: 'العربية', english: 'Arabic'),
  'fr': (native: 'Français', english: 'French'),
  'pt': (native: 'Português', english: 'Portuguese'),
  'bn': (native: 'বাংলা', english: 'Bengali'),
  'ru': (native: 'Русский', english: 'Russian'),
  'id': (native: 'Bahasa Indonesia', english: 'Indonesian'),
  'de': (native: 'Deutsch', english: 'German'),
  'ja': (native: '日本語', english: 'Japanese'),
  'zh': (native: '中文（简体）', english: 'Chinese (Simplified)'),
  'ur': (native: 'اردو', english: 'Urdu'),
  'tr': (native: 'Türkçe', english: 'Turkish'),
  'ta': (native: 'தமிழ்', english: 'Tamil'),
  'te': (native: 'తెలుగు', english: 'Telugu'),
};

/// The native display name for [languageCode], or the code itself if unknown.
String languageNativeName(String languageCode) =>
    kAppLanguages[languageCode]?.native ?? languageCode;

/// The English display name for [languageCode], or the code itself if unknown.
String languageEnglishName(String languageCode) =>
    kAppLanguages[languageCode]?.english ?? languageCode;
