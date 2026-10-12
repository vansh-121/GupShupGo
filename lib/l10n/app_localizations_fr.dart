// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonOk => 'OK';

  @override
  String get commonContinue => 'Continuer';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonGotIt => 'J\'ai compris';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsLanguageTitle => 'Langue';

  @override
  String get settingsLanguageSubtitle => 'Choisissez votre langue préférée';

  @override
  String get languagePickerTitle => 'Langue';

  @override
  String get languageSystemDefault => 'Par défaut du système';

  @override
  String get languageSystemDefaultSubtitle =>
      'Utilise la langue de votre appareil';

  @override
  String get loginContinueWithPhone => 'Continuer avec le téléphone';

  @override
  String get loginContinueWithGoogle => 'Continuer avec Google';

  @override
  String get loginUseEmailPassword => 'Utiliser l\'e-mail et le mot de passe';

  @override
  String get loginSignIn => 'Se connecter';

  @override
  String get loginSignUp => 'S\'inscrire';

  @override
  String get loginCreateAccount => 'Créer un compte';

  @override
  String get loginForgotPassword => 'Mot de passe oublié ?';

  @override
  String get loginOfflineChat => 'Chat hors ligne';

  @override
  String get loginHintName => 'Votre nom';

  @override
  String get loginHintEmail => 'E-mail';

  @override
  String get loginHintPassword => 'Mot de passe';

  @override
  String get loginPasswordHelper =>
      'Au moins 8 caractères, avec une lettre et un chiffre';

  @override
  String loginResetEmailSent(String email) {
    return 'E-mail de réinitialisation envoyé à $email';
  }

  @override
  String get loginErrorEnterEmail => 'Veuillez entrer votre e-mail';

  @override
  String get loginErrorValidEmail => 'Veuillez entrer un e-mail valide';

  @override
  String get loginErrorEnterPassword => 'Veuillez entrer votre mot de passe';

  @override
  String get loginErrorPasswordMin6 =>
      'Le mot de passe doit comporter au moins 6 caractères';

  @override
  String get loginErrorEnterPasswordSignup => 'Veuillez entrer un mot de passe';

  @override
  String get loginErrorPasswordMin8 =>
      'Le mot de passe doit comporter au moins 8 caractères';

  @override
  String get loginErrorPasswordLetter =>
      'Le mot de passe doit inclure une lettre';

  @override
  String get loginErrorPasswordNumber =>
      'Le mot de passe doit inclure un chiffre';

  @override
  String get loginErrorEnterName => 'Veuillez entrer votre nom';

  @override
  String get loginErrorGoogleCancelled => 'La connexion Google a été annulée.';

  @override
  String get loginErrorProfileLoad =>
      'Impossible de charger votre profil. Vérifiez votre connexion et réessayez.';

  @override
  String get loginErrorGoogleFailed =>
      'Échec de la connexion Google. Veuillez réessayer.';

  @override
  String get loginErrorSignInFailed =>
      'Échec de la connexion. Veuillez réessayer.';

  @override
  String get loginErrorSignUpFailed =>
      'Échec de l\'inscription. Veuillez réessayer.';

  @override
  String get loginErrorGeneric =>
      'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get loginErrorResetFailed =>
      'Échec de l\'envoi de l\'e-mail de réinitialisation. Veuillez réessayer.';

  @override
  String get loginErrorUserNotFound =>
      'Aucun compte trouvé avec cet e-mail. Veuillez vous inscrire.';

  @override
  String get loginErrorWrongPassword =>
      'Mot de passe incorrect. Veuillez réessayer.';

  @override
  String get loginErrorEmailInUse =>
      'Un compte existe déjà avec cet e-mail. Veuillez vous connecter.';

  @override
  String get loginErrorInvalidEmail =>
      'Veuillez entrer une adresse e-mail valide.';

  @override
  String get loginErrorWeakPassword =>
      'Mot de passe trop faible. Utilisez au moins 6 caractères.';

  @override
  String get loginErrorInvalidCredential =>
      'E-mail ou mot de passe invalide. Veuillez vérifier et réessayer.';

  @override
  String get loginErrorTooManyRequests =>
      'Trop de tentatives. Veuillez réessayer plus tard.';
}
