// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonOk => 'OK';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonClose => 'Close';

  @override
  String get commonGotIt => 'Got it';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Choose your preferred language';

  @override
  String get languagePickerTitle => 'Language';

  @override
  String get languageSystemDefault => 'System default';

  @override
  String get languageSystemDefaultSubtitle => 'Follow your device language';

  @override
  String get loginContinueWithPhone => 'Continue with Phone';

  @override
  String get loginContinueWithGoogle => 'Continue with Google';

  @override
  String get loginUseEmailPassword => 'Use Email & Password';

  @override
  String get loginSignIn => 'Sign In';

  @override
  String get loginSignUp => 'Sign Up';

  @override
  String get loginCreateAccount => 'Create Account';

  @override
  String get loginForgotPassword => 'Forgot Password?';

  @override
  String get loginOfflineChat => 'Offline Chat';

  @override
  String get loginHintName => 'Your Name';

  @override
  String get loginHintEmail => 'Email';

  @override
  String get loginHintPassword => 'Password';

  @override
  String get loginPasswordHelper =>
      'At least 8 characters, with a letter and a number';

  @override
  String loginResetEmailSent(String email) {
    return 'Password reset email sent to $email';
  }

  @override
  String get loginErrorEnterEmail => 'Please enter your email';

  @override
  String get loginErrorValidEmail => 'Please enter a valid email';

  @override
  String get loginErrorEnterPassword => 'Please enter your password';

  @override
  String get loginErrorPasswordMin6 => 'Password must be at least 6 characters';

  @override
  String get loginErrorEnterPasswordSignup => 'Please enter a password';

  @override
  String get loginErrorPasswordMin8 => 'Password must be at least 8 characters';

  @override
  String get loginErrorPasswordLetter => 'Password must include a letter';

  @override
  String get loginErrorPasswordNumber => 'Password must include a number';

  @override
  String get loginErrorEnterName => 'Please enter your name';

  @override
  String get loginErrorGoogleCancelled => 'Google sign-in was cancelled.';

  @override
  String get loginErrorProfileLoad =>
      'Couldn\'t load your profile. Check your connection and try again.';

  @override
  String get loginErrorGoogleFailed =>
      'Google sign-in failed. Please try again.';

  @override
  String get loginErrorSignInFailed => 'Failed to sign in. Please try again.';

  @override
  String get loginErrorSignUpFailed => 'Failed to sign up. Please try again.';

  @override
  String get loginErrorGeneric => 'An error occurred. Please try again.';

  @override
  String get loginErrorResetFailed =>
      'Failed to send reset email. Please try again.';

  @override
  String get loginErrorUserNotFound =>
      'No account found with this email. Please sign up.';

  @override
  String get loginErrorWrongPassword => 'Incorrect password. Please try again.';

  @override
  String get loginErrorEmailInUse =>
      'An account already exists with this email. Please sign in.';

  @override
  String get loginErrorInvalidEmail => 'Please enter a valid email address.';

  @override
  String get loginErrorWeakPassword =>
      'Password is too weak. Use at least 6 characters.';

  @override
  String get loginErrorInvalidCredential =>
      'Invalid email or password. Please check and try again.';

  @override
  String get loginErrorTooManyRequests =>
      'Too many attempts. Please try again later.';
}
