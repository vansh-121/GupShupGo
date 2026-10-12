// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonOk => 'موافق';

  @override
  String get commonContinue => 'متابعة';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonGotIt => 'فهمت';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsLanguageTitle => 'اللغة';

  @override
  String get settingsLanguageSubtitle => 'اختر لغتك المفضلة';

  @override
  String get languagePickerTitle => 'اللغة';

  @override
  String get languageSystemDefault => 'افتراضي النظام';

  @override
  String get languageSystemDefaultSubtitle => 'حسب لغة الجهاز';

  @override
  String get loginContinueWithPhone => 'المتابعة باستخدام الهاتف';

  @override
  String get loginContinueWithGoogle => 'المتابعة باستخدام Google';

  @override
  String get loginUseEmailPassword => 'استخدام البريد الإلكتروني وكلمة المرور';

  @override
  String get loginSignIn => 'تسجيل الدخول';

  @override
  String get loginSignUp => 'إنشاء حساب';

  @override
  String get loginCreateAccount => 'إنشاء حساب';

  @override
  String get loginForgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get loginOfflineChat => 'دردشة بلا إنترنت';

  @override
  String get loginHintName => 'اسمك';

  @override
  String get loginHintEmail => 'البريد الإلكتروني';

  @override
  String get loginHintPassword => 'كلمة المرور';

  @override
  String get loginPasswordHelper => '8 أحرف على الأقل، تتضمن حرفًا ورقمًا';

  @override
  String loginResetEmailSent(String email) {
    return 'تم إرسال بريد إعادة تعيين كلمة المرور إلى $email';
  }

  @override
  String get loginErrorEnterEmail => 'يرجى إدخال بريدك الإلكتروني';

  @override
  String get loginErrorValidEmail => 'يرجى إدخال بريد إلكتروني صالح';

  @override
  String get loginErrorEnterPassword => 'يرجى إدخال كلمة المرور';

  @override
  String get loginErrorPasswordMin6 => 'يجب ألا تقل كلمة المرور عن 6 أحرف';

  @override
  String get loginErrorEnterPasswordSignup => 'يرجى إدخال كلمة مرور';

  @override
  String get loginErrorPasswordMin8 => 'يجب ألا تقل كلمة المرور عن 8 أحرف';

  @override
  String get loginErrorPasswordLetter =>
      'يجب أن تحتوي كلمة المرور على حرف واحد على الأقل';

  @override
  String get loginErrorPasswordNumber =>
      'يجب أن تحتوي كلمة المرور على رقم واحد على الأقل';

  @override
  String get loginErrorEnterName => 'يرجى إدخال اسمك';

  @override
  String get loginErrorGoogleCancelled =>
      'تم إلغاء تسجيل الدخول باستخدام Google.';

  @override
  String get loginErrorProfileLoad =>
      'تعذر تحميل ملفك الشخصي. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get loginErrorGoogleFailed =>
      'فشل تسجيل الدخول باستخدام Google. يرجى المحاولة مرة أخرى.';

  @override
  String get loginErrorSignInFailed =>
      'فشل تسجيل الدخول. يرجى المحاولة مرة أخرى.';

  @override
  String get loginErrorSignUpFailed =>
      'فشل إنشاء الحساب. يرجى المحاولة مرة أخرى.';

  @override
  String get loginErrorGeneric => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get loginErrorResetFailed =>
      'فشل إرسال بريد إعادة التعيين. يرجى المحاولة مرة أخرى.';

  @override
  String get loginErrorUserNotFound =>
      'لا يوجد حساب بهذا البريد الإلكتروني. يرجى إنشاء حساب جديد.';

  @override
  String get loginErrorWrongPassword =>
      'كلمة المرور غير صحيحة. يرجى المحاولة مرة أخرى.';

  @override
  String get loginErrorEmailInUse =>
      'يوجد حساب بالفعل بهذا البريد الإلكتروني. يرجى تسجيل الدخول.';

  @override
  String get loginErrorInvalidEmail => 'يرجى إدخال عنوان بريد إلكتروني صالح.';

  @override
  String get loginErrorWeakPassword =>
      'كلمة المرور ضعيفة جدًا. استخدم 6 أحرف على الأقل.';

  @override
  String get loginErrorInvalidCredential =>
      'البريد الإلكتروني أو كلمة المرور غير صالحة. يرجى التحقق والمحاولة مرة أخرى.';

  @override
  String get loginErrorTooManyRequests =>
      'محاولات كثيرة جدًا. يرجى المحاولة مرة أخرى لاحقًا.';
}
