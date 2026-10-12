// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonOk => 'OK';

  @override
  String get commonContinue => 'Weiter';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonGotIt => 'Verstanden';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsLanguageTitle => 'Sprache';

  @override
  String get settingsLanguageSubtitle => 'Wähle deine bevorzugte Sprache';

  @override
  String get languagePickerTitle => 'Sprache';

  @override
  String get languageSystemDefault => 'Systemstandard';

  @override
  String get languageSystemDefaultSubtitle => 'Der Gerätesprache folgen';

  @override
  String get loginContinueWithPhone => 'Mit Telefon fortfahren';

  @override
  String get loginContinueWithGoogle => 'Mit Google fortfahren';

  @override
  String get loginUseEmailPassword => 'E-Mail & Passwort verwenden';

  @override
  String get loginSignIn => 'Anmelden';

  @override
  String get loginSignUp => 'Registrieren';

  @override
  String get loginCreateAccount => 'Konto erstellen';

  @override
  String get loginForgotPassword => 'Passwort vergessen?';

  @override
  String get loginOfflineChat => 'Offline-Chat';

  @override
  String get loginHintName => 'Dein Name';

  @override
  String get loginHintEmail => 'E-Mail';

  @override
  String get loginHintPassword => 'Passwort';

  @override
  String get loginPasswordHelper =>
      'Mindestens 8 Zeichen, mit Buchstabe und Zahl';

  @override
  String loginResetEmailSent(String email) {
    return 'E-Mail zum Zurücksetzen des Passworts an $email gesendet';
  }

  @override
  String get loginErrorEnterEmail => 'Bitte gib deine E-Mail-Adresse ein';

  @override
  String get loginErrorValidEmail =>
      'Bitte gib eine gültige E-Mail-Adresse ein';

  @override
  String get loginErrorEnterPassword => 'Bitte gib dein Passwort ein';

  @override
  String get loginErrorPasswordMin6 =>
      'Das Passwort muss mindestens 6 Zeichen lang sein';

  @override
  String get loginErrorEnterPasswordSignup => 'Bitte gib ein Passwort ein';

  @override
  String get loginErrorPasswordMin8 =>
      'Das Passwort muss mindestens 8 Zeichen lang sein';

  @override
  String get loginErrorPasswordLetter =>
      'Das Passwort muss mindestens einen Buchstaben enthalten';

  @override
  String get loginErrorPasswordNumber =>
      'Das Passwort muss mindestens eine Zahl enthalten';

  @override
  String get loginErrorEnterName => 'Bitte gib deinen Namen ein';

  @override
  String get loginErrorGoogleCancelled => 'Google-Anmeldung wurde abgebrochen.';

  @override
  String get loginErrorProfileLoad =>
      'Profil konnte nicht geladen werden. Verbindung prüfen und erneut versuchen.';

  @override
  String get loginErrorGoogleFailed =>
      'Google-Anmeldung fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get loginErrorSignInFailed =>
      'Anmeldung fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get loginErrorSignUpFailed =>
      'Registrierung fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get loginErrorGeneric =>
      'Ein Fehler ist aufgetreten. Bitte erneut versuchen.';

  @override
  String get loginErrorResetFailed =>
      'E-Mail zum Zurücksetzen konnte nicht gesendet werden. Bitte erneut versuchen.';

  @override
  String get loginErrorUserNotFound =>
      'Kein Konto mit dieser E-Mail gefunden. Bitte registrieren.';

  @override
  String get loginErrorWrongPassword =>
      'Falsches Passwort. Bitte erneut versuchen.';

  @override
  String get loginErrorEmailInUse =>
      'Ein Konto mit dieser E-Mail existiert bereits. Bitte anmelden.';

  @override
  String get loginErrorInvalidEmail =>
      'Bitte gib eine gültige E-Mail-Adresse ein.';

  @override
  String get loginErrorWeakPassword =>
      'Passwort ist zu schwach. Mindestens 6 Zeichen verwenden.';

  @override
  String get loginErrorInvalidCredential =>
      'Ungültige E-Mail oder Passwort. Bitte überprüfen und erneut versuchen.';

  @override
  String get loginErrorTooManyRequests =>
      'Zu viele Versuche. Bitte versuche es später noch einmal.';
}
