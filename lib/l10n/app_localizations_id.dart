// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get commonCancel => 'Batal';

  @override
  String get commonOk => 'OK';

  @override
  String get commonContinue => 'Lanjutkan';

  @override
  String get commonSave => 'Simpan';

  @override
  String get commonRetry => 'Coba lagi';

  @override
  String get commonClose => 'Tutup';

  @override
  String get commonGotIt => 'Mengerti';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get settingsLanguageTitle => 'Bahasa';

  @override
  String get settingsLanguageSubtitle => 'Pilih bahasa pilihan Anda';

  @override
  String get languagePickerTitle => 'Bahasa';

  @override
  String get languageSystemDefault => 'Bawaan sistem';

  @override
  String get languageSystemDefaultSubtitle => 'Ikuti bahasa perangkat Anda';

  @override
  String get loginContinueWithPhone => 'Lanjutkan dengan Telepon';

  @override
  String get loginContinueWithGoogle => 'Lanjutkan dengan Google';

  @override
  String get loginUseEmailPassword => 'Gunakan Email & Kata Sandi';

  @override
  String get loginSignIn => 'Masuk';

  @override
  String get loginSignUp => 'Daftar';

  @override
  String get loginCreateAccount => 'Buat Akun';

  @override
  String get loginForgotPassword => 'Lupa Kata Sandi?';

  @override
  String get loginOfflineChat => 'Obrolan Offline';

  @override
  String get loginHintName => 'Nama Anda';

  @override
  String get loginHintEmail => 'Email';

  @override
  String get loginHintPassword => 'Kata Sandi';

  @override
  String get loginPasswordHelper =>
      'Minimal 8 karakter, mengandung huruf dan angka';

  @override
  String loginResetEmailSent(String email) {
    return 'Email reset kata sandi telah dikirim ke $email';
  }

  @override
  String get loginErrorEnterEmail => 'Silakan masukkan email Anda';

  @override
  String get loginErrorValidEmail => 'Silakan masukkan email yang valid';

  @override
  String get loginErrorEnterPassword => 'Silakan masukkan kata sandi Anda';

  @override
  String get loginErrorPasswordMin6 => 'Kata sandi minimal harus 6 karakter';

  @override
  String get loginErrorEnterPasswordSignup => 'Silakan masukkan kata sandi';

  @override
  String get loginErrorPasswordMin8 => 'Kata sandi minimal harus 8 karakter';

  @override
  String get loginErrorPasswordLetter => 'Kata sandi harus menyertakan huruf';

  @override
  String get loginErrorPasswordNumber => 'Kata sandi harus menyertakan angka';

  @override
  String get loginErrorEnterName => 'Silakan masukkan nama Anda';

  @override
  String get loginErrorGoogleCancelled => 'Masuk dengan Google dibatalkan.';

  @override
  String get loginErrorProfileLoad =>
      'Gagal memuat profil Anda. Periksa koneksi dan coba lagi.';

  @override
  String get loginErrorGoogleFailed =>
      'Gagal masuk dengan Google. Silakan coba lagi.';

  @override
  String get loginErrorSignInFailed => 'Gagal masuk. Silakan coba lagi.';

  @override
  String get loginErrorSignUpFailed => 'Gagal mendaftar. Silakan coba lagi.';

  @override
  String get loginErrorGeneric => 'Terjadi kesalahan. Silakan coba lagi.';

  @override
  String get loginErrorResetFailed =>
      'Gagal mengirim email reset. Silakan coba lagi.';

  @override
  String get loginErrorUserNotFound =>
      'Tidak ada akun dengan email ini. Silakan daftar.';

  @override
  String get loginErrorWrongPassword => 'Kata sandi salah. Silakan coba lagi.';

  @override
  String get loginErrorEmailInUse =>
      'Akun sudah terdaftar dengan email ini. Silakan masuk.';

  @override
  String get loginErrorInvalidEmail =>
      'Silakan masukkan alamat email yang valid.';

  @override
  String get loginErrorWeakPassword =>
      'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.';

  @override
  String get loginErrorInvalidCredential =>
      'Email atau kata sandi tidak valid. Silakan periksa dan coba lagi.';

  @override
  String get loginErrorTooManyRequests =>
      'Terlalu banyak percobaan. Silakan coba lagi nanti.';
}
