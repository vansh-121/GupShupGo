// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonOk => 'OK';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonSave => 'Salvar';

  @override
  String get commonRetry => 'Tentar novamente';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonGotIt => 'Entendi';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsLanguageSubtitle => 'Escolha seu idioma preferido';

  @override
  String get languagePickerTitle => 'Idioma';

  @override
  String get languageSystemDefault => 'Padrão do sistema';

  @override
  String get languageSystemDefaultSubtitle => 'Usar o idioma do dispositivo';

  @override
  String get loginContinueWithPhone => 'Continuar com telefone';

  @override
  String get loginContinueWithGoogle => 'Continuar com o Google';

  @override
  String get loginUseEmailPassword => 'Usar e-mail e senha';

  @override
  String get loginSignIn => 'Entrar';

  @override
  String get loginSignUp => 'Cadastre-se';

  @override
  String get loginCreateAccount => 'Criar conta';

  @override
  String get loginForgotPassword => 'Esqueceu a senha?';

  @override
  String get loginOfflineChat => 'Chat offline';

  @override
  String get loginHintName => 'Seu nome';

  @override
  String get loginHintEmail => 'E-mail';

  @override
  String get loginHintPassword => 'Senha';

  @override
  String get loginPasswordHelper =>
      'Pelo menos 8 caracteres, com uma letra e um número';

  @override
  String loginResetEmailSent(String email) {
    return 'E-mail de redefinição de senha enviado para $email';
  }

  @override
  String get loginErrorEnterEmail => 'Por favor, insira seu e-mail';

  @override
  String get loginErrorValidEmail => 'Por favor, insira um e-mail válido';

  @override
  String get loginErrorEnterPassword => 'Por favor, insira sua senha';

  @override
  String get loginErrorPasswordMin6 =>
      'A senha deve ter pelo menos 6 caracteres';

  @override
  String get loginErrorEnterPasswordSignup => 'Por favor, insira uma senha';

  @override
  String get loginErrorPasswordMin8 =>
      'A senha deve ter pelo menos 8 caracteres';

  @override
  String get loginErrorPasswordLetter => 'A senha deve incluir uma letra';

  @override
  String get loginErrorPasswordNumber => 'A senha deve incluir um número';

  @override
  String get loginErrorEnterName => 'Por favor, insira seu nome';

  @override
  String get loginErrorGoogleCancelled => 'O login com o Google foi cancelado.';

  @override
  String get loginErrorProfileLoad =>
      'Não foi possível carregar seu perfil. Verifique sua conexão e tente novamente.';

  @override
  String get loginErrorGoogleFailed =>
      'Falha no login com o Google. Tente novamente.';

  @override
  String get loginErrorSignInFailed => 'Falha ao entrar. Tente novamente.';

  @override
  String get loginErrorSignUpFailed => 'Falha ao cadastrar. Tente novamente.';

  @override
  String get loginErrorGeneric => 'Ocorreu um erro. Tente novamente.';

  @override
  String get loginErrorResetFailed =>
      'Falha ao enviar e-mail de redefinição. Tente novamente.';

  @override
  String get loginErrorUserNotFound =>
      'Nenhuma conta encontrada com este e-mail. Cadastre-se.';

  @override
  String get loginErrorWrongPassword => 'Senha incorreta. Tente novamente.';

  @override
  String get loginErrorEmailInUse =>
      'Já existe uma conta com este e-mail. Faça login.';

  @override
  String get loginErrorInvalidEmail =>
      'Por favor, insira um endereço de e-mail válido.';

  @override
  String get loginErrorWeakPassword =>
      'Senha muito fraca. Use pelo menos 6 caracteres.';

  @override
  String get loginErrorInvalidCredential =>
      'E-mail ou senha inválidos. Verifique e tente novamente.';

  @override
  String get loginErrorTooManyRequests =>
      'Muitas tentativas. Tente novamente mais tarde.';
}
