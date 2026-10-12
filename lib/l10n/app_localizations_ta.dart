// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get commonCancel => 'ரத்து செய்';

  @override
  String get commonOk => 'சரி';

  @override
  String get commonContinue => 'தொடரவும்';

  @override
  String get commonSave => 'சேமி';

  @override
  String get commonRetry => 'மீண்டும் முயற்சி செய்';

  @override
  String get commonClose => 'மூடு';

  @override
  String get commonGotIt => 'புரிந்தது';

  @override
  String get settingsTitle => 'அமைப்புகள்';

  @override
  String get settingsLanguageTitle => 'மொழி';

  @override
  String get settingsLanguageSubtitle =>
      'உங்கள் விருப்ப மொழியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get languagePickerTitle => 'மொழி';

  @override
  String get languageSystemDefault => 'சாதன இயல்புநிலை';

  @override
  String get languageSystemDefaultSubtitle =>
      'உங்கள் சாதனத்தின் மொழியைப் பின்பற்று';

  @override
  String get loginContinueWithPhone => 'தொலைபேசி எண் மூலம் தொடரவும்';

  @override
  String get loginContinueWithGoogle => 'Google மூலம் தொடரவும்';

  @override
  String get loginUseEmailPassword =>
      'மின்னஞ்சல் மற்றும் கடவுச்சொல்லைப் பயன்படுத்தவும்';

  @override
  String get loginSignIn => 'உள்நுழையவும்';

  @override
  String get loginSignUp => 'பதிவு செய்யவும்';

  @override
  String get loginCreateAccount => 'கணக்கை உருவாக்கவும்';

  @override
  String get loginForgotPassword => 'கடவுச்சொல் மறந்துவிட்டதா?';

  @override
  String get loginOfflineChat => 'ஆஃப்லைன் அரட்டை';

  @override
  String get loginHintName => 'உங்கள் பெயர்';

  @override
  String get loginHintEmail => 'மின்னஞ்சல்';

  @override
  String get loginHintPassword => 'கடவுச்சொல்';

  @override
  String get loginPasswordHelper =>
      'குறைந்தது 8 எழுத்துகள், ஒரு எழுத்து மற்றும் எண்ணுடன்';

  @override
  String loginResetEmailSent(String email) {
    return '$email முகவரிக்கு கடவுச்சொல் மீட்டமைப்பு மின்னஞ்சல் அனுப்பப்பட்டது';
  }

  @override
  String get loginErrorEnterEmail => 'உங்கள் மின்னஞ்சலை உள்ளிடவும்';

  @override
  String get loginErrorValidEmail => 'சரியான மின்னஞ்சலை உள்ளிடவும்';

  @override
  String get loginErrorEnterPassword => 'உங்கள் கடவுச்சொல்லை உள்ளிடவும்';

  @override
  String get loginErrorPasswordMin6 =>
      'கடவுச்சொல் குறைந்தது 6 எழுத்துகளாக இருக்க வேண்டும்';

  @override
  String get loginErrorEnterPasswordSignup => 'கடவுச்சொல்லை உள்ளிடவும்';

  @override
  String get loginErrorPasswordMin8 =>
      'கடவுச்சொல் குறைந்தது 8 எழுத்துகளாக இருக்க வேண்டும்';

  @override
  String get loginErrorPasswordLetter =>
      'கடவுச்சொல்லில் ஒரு எழுத்து இருக்க வேண்டும்';

  @override
  String get loginErrorPasswordNumber =>
      'கடவுச்சொல்லில் ஒரு எண் இருக்க வேண்டும்';

  @override
  String get loginErrorEnterName => 'உங்கள் பெயரை உள்ளிடவும்';

  @override
  String get loginErrorGoogleCancelled =>
      'Google உள்நுழைவு ரத்து செய்யப்பட்டது.';

  @override
  String get loginErrorProfileLoad =>
      'சுயவிவரத்தை ஏற்ற முடியவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get loginErrorGoogleFailed =>
      'Google உள்நுழைவு தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get loginErrorSignInFailed =>
      'உள்நுழைய முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get loginErrorSignUpFailed =>
      'பதிவு செய்ய முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get loginErrorGeneric => 'பிழை ஏற்பட்டது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get loginErrorResetFailed =>
      'மீட்டமைப்பு மின்னஞ்சலை அனுப்ப முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get loginErrorUserNotFound =>
      'இந்த மின்னஞ்சலில் கணக்கு எதுவும் இல்லை. பதிவு செய்யவும்.';

  @override
  String get loginErrorWrongPassword =>
      'தவறான கடவுச்சொல். மீண்டும் முயற்சிக்கவும்.';

  @override
  String get loginErrorEmailInUse =>
      'இந்த மின்னஞ்சலில் ஏற்கனவே கணக்கு உள்ளது. உள்நுழையவும்.';

  @override
  String get loginErrorInvalidEmail => 'சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும்.';

  @override
  String get loginErrorWeakPassword =>
      'கடவுச்சொல் மிகவும் எளிதாக உள்ளது. குறைந்தது 6 எழுத்துகளைப் பயன்படுத்தவும்.';

  @override
  String get loginErrorInvalidCredential =>
      'தவறான மின்னஞ்சல் அல்லது கடவுச்சொல். சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get loginErrorTooManyRequests =>
      'அதிக முயற்சிகள் மேற்கொள்ளப்பட்டன. பின்னர் முயற்சிக்கவும்.';
}
