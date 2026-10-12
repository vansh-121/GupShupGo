// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get commonCancel => 'रद्द करें';

  @override
  String get commonOk => 'ठीक है';

  @override
  String get commonContinue => 'जारी रखें';

  @override
  String get commonSave => 'सहेजें';

  @override
  String get commonRetry => 'पुनः प्रयास करें';

  @override
  String get commonClose => 'बंद करें';

  @override
  String get commonGotIt => 'समझ गए';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsLanguageTitle => 'भाषा';

  @override
  String get settingsLanguageSubtitle => 'अपनी पसंदीदा भाषा चुनें';

  @override
  String get languagePickerTitle => 'भाषा';

  @override
  String get languageSystemDefault => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get languageSystemDefaultSubtitle => 'अपने डिवाइस की भाषा के अनुसार';

  @override
  String get loginContinueWithPhone => 'फ़ोन के साथ जारी रखें';

  @override
  String get loginContinueWithGoogle => 'Google के साथ जारी रखें';

  @override
  String get loginUseEmailPassword => 'ईमेल और पासवर्ड का उपयोग करें';

  @override
  String get loginSignIn => 'साइन इन करें';

  @override
  String get loginSignUp => 'साइन अप करें';

  @override
  String get loginCreateAccount => 'खाता बनाएं';

  @override
  String get loginForgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get loginOfflineChat => 'ऑफ़लाइन चैट';

  @override
  String get loginHintName => 'आपका नाम';

  @override
  String get loginHintEmail => 'ईमेल';

  @override
  String get loginHintPassword => 'पासवर्ड';

  @override
  String get loginPasswordHelper =>
      'कम से कम 8 अक्षर, जिसमें एक अक्षर और एक संख्या हो';

  @override
  String loginResetEmailSent(String email) {
    return '$email पर पासवर्ड रीसेट ईमेल भेजा गया';
  }

  @override
  String get loginErrorEnterEmail => 'कृपया अपना ईमेल दर्ज करें';

  @override
  String get loginErrorValidEmail => 'कृपया एक मान्य ईमेल दर्ज करें';

  @override
  String get loginErrorEnterPassword => 'कृपया अपना पासवर्ड दर्ज करें';

  @override
  String get loginErrorPasswordMin6 =>
      'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए';

  @override
  String get loginErrorEnterPasswordSignup => 'कृपया एक पासवर्ड दर्ज करें';

  @override
  String get loginErrorPasswordMin8 =>
      'पासवर्ड कम से कम 8 अक्षरों का होना चाहिए';

  @override
  String get loginErrorPasswordLetter =>
      'पासवर्ड में कम से कम एक अक्षर होना चाहिए';

  @override
  String get loginErrorPasswordNumber =>
      'पासवर्ड में कम से कम एक संख्या होनी चाहिए';

  @override
  String get loginErrorEnterName => 'कृपया अपना नाम दर्ज करें';

  @override
  String get loginErrorGoogleCancelled => 'Google साइन-इन रद्द कर दिया गया था।';

  @override
  String get loginErrorProfileLoad =>
      'आपकी प्रोफ़ाइल लोड नहीं हो सकी। अपना कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String get loginErrorGoogleFailed =>
      'Google साइन-इन विफल रहा। कृपया पुनः प्रयास करें।';

  @override
  String get loginErrorSignInFailed =>
      'साइन इन करने में विफल। कृपया पुनः प्रयास करें।';

  @override
  String get loginErrorSignUpFailed =>
      'साइन अप करने में विफल। कृपया पुनः प्रयास करें।';

  @override
  String get loginErrorGeneric => 'कोई त्रुटि हुई। कृपया पुनः प्रयास करें।';

  @override
  String get loginErrorResetFailed =>
      'रीसेट ईमेल भेजने में विफल। कृपया पुनः प्रयास करें।';

  @override
  String get loginErrorUserNotFound =>
      'इस ईमेल से कोई खाता नहीं मिला। कृपया साइन अप करें।';

  @override
  String get loginErrorWrongPassword => 'गलत पासवर्ड। कृपया पुनः प्रयास करें।';

  @override
  String get loginErrorEmailInUse =>
      'इस ईमेल से पहले से ही एक खाता मौजूद है। कृपया साइन इन करें।';

  @override
  String get loginErrorInvalidEmail => 'कृपया एक मान्य ईमेल पता दर्ज करें।';

  @override
  String get loginErrorWeakPassword =>
      'पासवर्ड बहुत कमज़ोर है। कम से कम 6 अक्षरों का उपयोग करें।';

  @override
  String get loginErrorInvalidCredential =>
      'अमान्य ईमेल या पासवर्ड। कृपया जांचें और पुनः प्रयास करें।';

  @override
  String get loginErrorTooManyRequests =>
      'बहुत सारे प्रयास। कृपया बाद में पुनः प्रयास करें。';
}
