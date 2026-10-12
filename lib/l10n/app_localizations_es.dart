// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonOk => 'Aceptar';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonGotIt => 'Entendido';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsLanguageSubtitle => 'Elige tu idioma preferido';

  @override
  String get languagePickerTitle => 'Idioma';

  @override
  String get languageSystemDefault => 'Predeterminado del sistema';

  @override
  String get languageSystemDefaultSubtitle => 'Usa el idioma de tu dispositivo';

  @override
  String get loginContinueWithPhone => 'Continuar con teléfono';

  @override
  String get loginContinueWithGoogle => 'Continuar con Google';

  @override
  String get loginUseEmailPassword => 'Usar correo y contraseña';

  @override
  String get loginSignIn => 'Iniciar sesión';

  @override
  String get loginSignUp => 'Registrarse';

  @override
  String get loginCreateAccount => 'Crear cuenta';

  @override
  String get loginForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get loginOfflineChat => 'Chat sin conexión';

  @override
  String get loginHintName => 'Tu nombre';

  @override
  String get loginHintEmail => 'Correo electrónico';

  @override
  String get loginHintPassword => 'Contraseña';

  @override
  String get loginPasswordHelper =>
      'Al menos 8 caracteres, con una letra y un número';

  @override
  String loginResetEmailSent(String email) {
    return 'Correo de restablecimiento enviado a $email';
  }

  @override
  String get loginErrorEnterEmail => 'Por favor ingresa tu correo electrónico';

  @override
  String get loginErrorValidEmail => 'Por favor ingresa un correo válido';

  @override
  String get loginErrorEnterPassword => 'Por favor ingresa tu contraseña';

  @override
  String get loginErrorPasswordMin6 =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get loginErrorEnterPasswordSignup =>
      'Por favor ingresa una contraseña';

  @override
  String get loginErrorPasswordMin8 =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get loginErrorPasswordLetter => 'La contraseña debe incluir una letra';

  @override
  String get loginErrorPasswordNumber => 'La contraseña debe incluir un número';

  @override
  String get loginErrorEnterName => 'Por favor ingresa tu nombre';

  @override
  String get loginErrorGoogleCancelled =>
      'Se canceló el inicio de sesión con Google.';

  @override
  String get loginErrorProfileLoad =>
      'No se pudo cargar tu perfil. Revisa tu conexión e intenta de nuevo.';

  @override
  String get loginErrorGoogleFailed =>
      'Error al iniciar sesión con Google. Intenta de nuevo.';

  @override
  String get loginErrorSignInFailed =>
      'Error al iniciar sesión. Intenta de nuevo.';

  @override
  String get loginErrorSignUpFailed =>
      'Error al registrarse. Intenta de nuevo.';

  @override
  String get loginErrorGeneric => 'Ocurrió un error. Intenta de nuevo.';

  @override
  String get loginErrorResetFailed =>
      'Error al enviar el correo de restablecimiento. Intenta de nuevo.';

  @override
  String get loginErrorUserNotFound =>
      'No se encontró ninguna cuenta con este correo. Por favor regístrate.';

  @override
  String get loginErrorWrongPassword =>
      'Contraseña incorrecta. Intenta de nuevo.';

  @override
  String get loginErrorEmailInUse =>
      'Ya existe una cuenta con este correo. Por favor inicia sesión.';

  @override
  String get loginErrorInvalidEmail =>
      'Por favor ingresa una dirección de correo válida.';

  @override
  String get loginErrorWeakPassword =>
      'La contraseña es muy débil. Usa al menos 6 caracteres.';

  @override
  String get loginErrorInvalidCredential =>
      'Correo o contraseña incorrectos. Verifica e intenta de nuevo.';

  @override
  String get loginErrorTooManyRequests =>
      'Demasiados intentos. Intenta de nuevo más tarde.';
}
