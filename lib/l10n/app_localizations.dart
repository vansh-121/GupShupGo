import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bn'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('id'),
    Locale('ja'),
    Locale('pt'),
    Locale('ru'),
    Locale('ta'),
    Locale('te'),
    Locale('tr'),
    Locale('ur'),
    Locale('zh')
  ];

  /// Generic Cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Generic OK/confirm button.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// Generic Continue button.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// Generic Save button.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Generic Retry button after a failure.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// Generic Close button.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Dismiss button acknowledging a notice.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get commonGotIt;

  /// Title of the Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings row that opens the app language picker.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// Subtitle under the Language settings row.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get settingsLanguageSubtitle;

  /// Title of the language picker screen.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languagePickerTitle;

  /// Option that follows the device's language instead of a fixed app language.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystemDefault;

  /// Subtitle for the System default language option.
  ///
  /// In en, this message translates to:
  /// **'Follow your device language'**
  String get languageSystemDefaultSubtitle;

  /// Primary login button: start phone-number auth.
  ///
  /// In en, this message translates to:
  /// **'Continue with Phone'**
  String get loginContinueWithPhone;

  /// Login button: sign in with a Google account.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginContinueWithGoogle;

  /// Login button: reveal the email/password form.
  ///
  /// In en, this message translates to:
  /// **'Use Email & Password'**
  String get loginUseEmailPassword;

  /// Sign In mode chip and submit button.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginSignIn;

  /// Sign Up mode chip.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get loginSignUp;

  /// Submit button in sign-up mode.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get loginCreateAccount;

  /// Link that triggers a password-reset email.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get loginForgotPassword;

  /// Bottom link to the offline/nearby mesh chat.
  ///
  /// In en, this message translates to:
  /// **'Offline Chat'**
  String get loginOfflineChat;

  /// Name field placeholder on sign-up.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get loginHintName;

  /// Email field placeholder.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginHintEmail;

  /// Password field placeholder.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginHintPassword;

  /// Helper text under the password field on sign-up.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters, with a letter and a number'**
  String get loginPasswordHelper;

  /// Confirmation snackbar after a password-reset email is sent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent to {email}'**
  String loginResetEmailSent(String email);

  /// Validation: email field empty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get loginErrorEnterEmail;

  /// Validation: email format invalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get loginErrorValidEmail;

  /// Validation: password field empty (sign-in).
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get loginErrorEnterPassword;

  /// Validation: sign-in password too short.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get loginErrorPasswordMin6;

  /// Validation: password field empty (sign-up).
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get loginErrorEnterPasswordSignup;

  /// Validation: sign-up password too short.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get loginErrorPasswordMin8;

  /// Validation: sign-up password needs a letter.
  ///
  /// In en, this message translates to:
  /// **'Password must include a letter'**
  String get loginErrorPasswordLetter;

  /// Validation: sign-up password needs a number.
  ///
  /// In en, this message translates to:
  /// **'Password must include a number'**
  String get loginErrorPasswordNumber;

  /// Validation: name field empty on sign-up.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get loginErrorEnterName;

  /// Google sign-in dismissed by the user.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was cancelled.'**
  String get loginErrorGoogleCancelled;

  /// Profile read failed during sign-in.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your profile. Check your connection and try again.'**
  String get loginErrorProfileLoad;

  /// Generic Google sign-in failure.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get loginErrorGoogleFailed;

  /// Email sign-in returned no user.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign in. Please try again.'**
  String get loginErrorSignInFailed;

  /// Email sign-up returned no user.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign up. Please try again.'**
  String get loginErrorSignUpFailed;

  /// Fallback error for an unexpected failure.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get loginErrorGeneric;

  /// Password-reset email could not be sent.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email. Please try again.'**
  String get loginErrorResetFailed;

  /// Firebase auth: user-not-found.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email. Please sign up.'**
  String get loginErrorUserNotFound;

  /// Firebase auth: wrong-password.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Please try again.'**
  String get loginErrorWrongPassword;

  /// Firebase auth: email-already-in-use.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email. Please sign in.'**
  String get loginErrorEmailInUse;

  /// Firebase auth: invalid-email.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get loginErrorInvalidEmail;

  /// Firebase auth: weak-password.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Use at least 6 characters.'**
  String get loginErrorWeakPassword;

  /// Firebase auth: invalid-credential.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password. Please check and try again.'**
  String get loginErrorInvalidCredential;

  /// Firebase auth: too-many-requests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get loginErrorTooManyRequests;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'bn',
        'de',
        'en',
        'es',
        'fr',
        'hi',
        'id',
        'ja',
        'pt',
        'ru',
        'ta',
        'te',
        'tr',
        'ur',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'ja':
      return AppLocalizationsJa();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'tr':
      return AppLocalizationsTr();
    case 'ur':
      return AppLocalizationsUr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
