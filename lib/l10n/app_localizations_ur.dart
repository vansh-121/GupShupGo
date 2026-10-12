// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get commonCancel => 'منسوخ کریں';

  @override
  String get commonOk => 'ٹھیک ہے';

  @override
  String get commonContinue => 'جاری رکھیں';

  @override
  String get commonSave => 'محفوظ کریں';

  @override
  String get commonRetry => 'دوبارہ کوشش کریں';

  @override
  String get commonClose => 'بند کریں';

  @override
  String get commonGotIt => 'سمجھ گیا';

  @override
  String get settingsTitle => 'ترتیبات';

  @override
  String get settingsLanguageTitle => 'زبان';

  @override
  String get settingsLanguageSubtitle => 'اپنی پسندیدہ زبان منتخب کریں';

  @override
  String get languagePickerTitle => 'زبان';

  @override
  String get languageSystemDefault => 'سسٹم ڈیفالٹ';

  @override
  String get languageSystemDefaultSubtitle => 'اپنے آلے کی زبان کے مطابق';

  @override
  String get loginContinueWithPhone => 'فون کے ساتھ جاری رکھیں';

  @override
  String get loginContinueWithGoogle => 'Google کے ساتھ جاری رکھیں';

  @override
  String get loginUseEmailPassword => 'ای میل اور پاس ورڈ استعمال کریں';

  @override
  String get loginSignIn => 'سائن ان کریں';

  @override
  String get loginSignUp => 'سائن اپ کریں';

  @override
  String get loginCreateAccount => 'اکاؤنٹ بنائیں';

  @override
  String get loginForgotPassword => 'پاس ورڈ بھول گئے؟';

  @override
  String get loginOfflineChat => 'آف لائن چیٹ';

  @override
  String get loginHintName => 'آپ کا نام';

  @override
  String get loginHintEmail => 'ای میل';

  @override
  String get loginHintPassword => 'پاس ورڈ';

  @override
  String get loginPasswordHelper =>
      'کم از کم 8 حروف، بشمول ایک حرف اور ایک ہندسہ';

  @override
  String loginResetEmailSent(String email) {
    return '$email پر پاس ورڈ ری سیٹ ای میل بھیج دی گئی ہے';
  }

  @override
  String get loginErrorEnterEmail => 'براہ کرم اپنا ای میل درج کریں';

  @override
  String get loginErrorValidEmail => 'براہ کرم ایک درست ای میل درج کریں';

  @override
  String get loginErrorEnterPassword => 'براہ کرم اپنا پاس ورڈ درج کریں';

  @override
  String get loginErrorPasswordMin6 => 'پاس ورڈ کم از کم 6 حروف کا ہونا چاہیے';

  @override
  String get loginErrorEnterPasswordSignup => 'براہ کرم ایک پاس ورڈ درج کریں';

  @override
  String get loginErrorPasswordMin8 => 'پاس ورڈ کم از کم 8 حروف کا ہونا چاہیے';

  @override
  String get loginErrorPasswordLetter => 'پاس ورڈ میں ایک حرف شامل ہونا چاہیے';

  @override
  String get loginErrorPasswordNumber =>
      'پاس ورڈ میں ایک ہندسہ شامل ہونا چاہیے';

  @override
  String get loginErrorEnterName => 'براہ کرم اپنا نام درج کریں';

  @override
  String get loginErrorGoogleCancelled =>
      'Google سائن ان منسوخ کر دیا گیا تھا۔';

  @override
  String get loginErrorProfileLoad =>
      'آپ کا پروفائل لوڈ نہیں ہو سکا۔ اپنا انٹرنیٹ کنکشن چیک کریں اور دوبارہ کوشش کریں۔';

  @override
  String get loginErrorGoogleFailed =>
      'Google سائن ان ناکام ہو گیا۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get loginErrorSignInFailed =>
      'سائن ان کرنے میں ناکامی۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get loginErrorSignUpFailed =>
      'سائن اپ کرنے میں ناکامی۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get loginErrorGeneric =>
      'ایک خرابی پیش آ گئی۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get loginErrorResetFailed =>
      'ری سیٹ ای میل بھیجنے میں ناکامی۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get loginErrorUserNotFound =>
      'اس ای میل سے کوئی اکاؤنٹ نہیں ملا۔ براہ کرم سائن اپ کریں۔';

  @override
  String get loginErrorWrongPassword =>
      'غلط پاس ورڈ۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get loginErrorEmailInUse =>
      'اس ای میل سے پہلے ہی ایک اکاؤنٹ موجود ہے۔ براہ کرم سائن ان کریں۔';

  @override
  String get loginErrorInvalidEmail => 'براہ کرم ایک درست ای میل پتہ درج کریں۔';

  @override
  String get loginErrorWeakPassword =>
      'پاس ورڈ بہت کمزور ہے۔ کم از کم 6 حروف استعمال کریں۔';

  @override
  String get loginErrorInvalidCredential =>
      'غلط ای میل یا پاس ورڈ۔ براہ کرم تصدیق کریں اور دوبارہ کوشش کریں۔';

  @override
  String get loginErrorTooManyRequests =>
      'بہت زیادہ کوششیں۔ براہ کرم بعد میں دوبارہ کوشش کریں۔';
}
