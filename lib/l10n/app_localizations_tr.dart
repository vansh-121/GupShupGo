// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get commonCancel => 'İptal';

  @override
  String get commonOk => 'Tamam';

  @override
  String get commonContinue => 'Devam';

  @override
  String get commonSave => 'Kaydet';

  @override
  String get commonRetry => 'Yeniden dene';

  @override
  String get commonClose => 'Kapat';

  @override
  String get commonGotIt => 'Anladım';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsLanguageTitle => 'Dil';

  @override
  String get settingsLanguageSubtitle => 'Tercih ettiğiniz dili seçin';

  @override
  String get languagePickerTitle => 'Dil';

  @override
  String get languageSystemDefault => 'Sistem varsayılanı';

  @override
  String get languageSystemDefaultSubtitle => 'Cihazınızın dilini kullanın';

  @override
  String get loginContinueWithPhone => 'Telefon ile Devam Et';

  @override
  String get loginContinueWithGoogle => 'Google ile Devam Et';

  @override
  String get loginUseEmailPassword => 'E-posta ve Şifre Kullan';

  @override
  String get loginSignIn => 'Giriş Yap';

  @override
  String get loginSignUp => 'Kayıt Ol';

  @override
  String get loginCreateAccount => 'Hesap Oluştur';

  @override
  String get loginForgotPassword => 'Şifrenizi mi unuttunuz?';

  @override
  String get loginOfflineChat => 'Çevrimdışı Sohbet';

  @override
  String get loginHintName => 'Adınız';

  @override
  String get loginHintEmail => 'E-posta';

  @override
  String get loginHintPassword => 'Şifre';

  @override
  String get loginPasswordHelper =>
      'En az 8 karakter, bir harf ve bir rakam içermelidir';

  @override
  String loginResetEmailSent(String email) {
    return 'Şifre sıfırlama e-postası $email adresine gönderildi';
  }

  @override
  String get loginErrorEnterEmail => 'Lütfen e-posta adresinizi girin';

  @override
  String get loginErrorValidEmail => 'Lütfen geçerli bir e-posta adresi girin';

  @override
  String get loginErrorEnterPassword => 'Lütfen şifrenizi girin';

  @override
  String get loginErrorPasswordMin6 => 'Şifre en az 6 karakter olmalıdır';

  @override
  String get loginErrorEnterPasswordSignup => 'Lütfen bir şifre girin';

  @override
  String get loginErrorPasswordMin8 => 'Şifre en az 8 karakter olmalıdır';

  @override
  String get loginErrorPasswordLetter => 'Şifre en az bir harf içermelidir';

  @override
  String get loginErrorPasswordNumber => 'Şifre en az bir rakam içermelidir';

  @override
  String get loginErrorEnterName => 'Lütfen adınızı girin';

  @override
  String get loginErrorGoogleCancelled => 'Google ile giriş iptal edildi.';

  @override
  String get loginErrorProfileLoad =>
      'Profiliniz yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get loginErrorGoogleFailed =>
      'Google ile giriş başarısız oldu. Lütfen tekrar deneyin.';

  @override
  String get loginErrorSignInFailed =>
      'Giriş yapılamadı. Lütfen tekrar deneyin.';

  @override
  String get loginErrorSignUpFailed =>
      'Kayıt olunamadı. Lütfen tekrar deneyin.';

  @override
  String get loginErrorGeneric => 'Bir hata oluştu. Lütfen tekrar deneyin.';

  @override
  String get loginErrorResetFailed =>
      'Sıfırlama e-postası gönderilemedi. Lütfen tekrar deneyin.';

  @override
  String get loginErrorUserNotFound =>
      'Bu e-posta ile kayıtlı hesap bulunamadı. Lütfen kayıt olun.';

  @override
  String get loginErrorWrongPassword => 'Hatalı şifre. Lütfen tekrar deneyin.';

  @override
  String get loginErrorEmailInUse =>
      'Bu e-posta adresi zaten kullanılıyor. Lütfen giriş yapın.';

  @override
  String get loginErrorInvalidEmail =>
      'Lütfen geçerli bir e-posta adresi girin.';

  @override
  String get loginErrorWeakPassword =>
      'Şifre çok zayıf. En az 6 karakter kullanın.';

  @override
  String get loginErrorInvalidCredential =>
      'Geçersiz e-posta veya şifre. Lütfen kontrol edip tekrar deneyin.';

  @override
  String get loginErrorTooManyRequests =>
      'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
}
