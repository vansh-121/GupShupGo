// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonOk => 'ОК';

  @override
  String get commonContinue => 'Продолжить';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get commonGotIt => 'Понятно';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsLanguageTitle => 'Язык';

  @override
  String get settingsLanguageSubtitle => 'Выберите предпочитаемый язык';

  @override
  String get languagePickerTitle => 'Язык';

  @override
  String get languageSystemDefault => 'Системный';

  @override
  String get languageSystemDefaultSubtitle => 'Язык вашего устройства';

  @override
  String get loginContinueWithPhone => 'Продолжить по номеру телефона';

  @override
  String get loginContinueWithGoogle => 'Продолжить через Google';

  @override
  String get loginUseEmailPassword => 'Использовать эл. почту и пароль';

  @override
  String get loginSignIn => 'Войти';

  @override
  String get loginSignUp => 'Регистрация';

  @override
  String get loginCreateAccount => 'Создать аккаунт';

  @override
  String get loginForgotPassword => 'Забыли пароль?';

  @override
  String get loginOfflineChat => 'Офлайн-чат';

  @override
  String get loginHintName => 'Ваше имя';

  @override
  String get loginHintEmail => 'Эл. почта';

  @override
  String get loginHintPassword => 'Пароль';

  @override
  String get loginPasswordHelper =>
      'Не менее 8 символов, включая букву и цифру';

  @override
  String loginResetEmailSent(String email) {
    return 'Письмо для сброса пароля отправлено на $email';
  }

  @override
  String get loginErrorEnterEmail => 'Пожалуйста, введите адрес эл. почты';

  @override
  String get loginErrorValidEmail =>
      'Пожалуйста, введите корректный адрес эл. почты';

  @override
  String get loginErrorEnterPassword => 'Пожалуйста, введите пароль';

  @override
  String get loginErrorPasswordMin6 =>
      'Пароль должен содержать не менее 6 символов';

  @override
  String get loginErrorEnterPasswordSignup => 'Пожалуйста, введите пароль';

  @override
  String get loginErrorPasswordMin8 =>
      'Пароль должен содержать не менее 8 символов';

  @override
  String get loginErrorPasswordLetter =>
      'Пароль должен содержать хотя бы одну букву';

  @override
  String get loginErrorPasswordNumber =>
      'Пароль должен содержать хотя бы одну цифру';

  @override
  String get loginErrorEnterName => 'Пожалуйста, введите ваше имя';

  @override
  String get loginErrorGoogleCancelled => 'Вход через Google был отменен.';

  @override
  String get loginErrorProfileLoad =>
      'Не удалось загрузить профиль. Проверьте соединение и повторите попытку.';

  @override
  String get loginErrorGoogleFailed =>
      'Ошибка входа через Google. Пожалуйста, повторите попытку.';

  @override
  String get loginErrorSignInFailed =>
      'Не удалось войти. Пожалуйста, повторите попытку.';

  @override
  String get loginErrorSignUpFailed =>
      'Не удалось зарегистрироваться. Пожалуйста, повторите попытку.';

  @override
  String get loginErrorGeneric =>
      'Произошла ошибка. Пожалуйста, повторите попытку.';

  @override
  String get loginErrorResetFailed =>
      'Не удалось отправить письмо для сброса. Повторите попытку.';

  @override
  String get loginErrorUserNotFound =>
      'Аккаунт с таким адресом не найден. Пожалуйста, зарегистрируйтесь.';

  @override
  String get loginErrorWrongPassword =>
      'Неверный пароль. Пожалуйста, повторите попытку.';

  @override
  String get loginErrorEmailInUse =>
      'Аккаунт с этим адресом уже существует. Пожалуйста, войдите.';

  @override
  String get loginErrorInvalidEmail =>
      'Пожалуйста, введите действительный адрес эл. почты.';

  @override
  String get loginErrorWeakPassword =>
      'Слишком простой пароль. Используйте не менее 6 символов.';

  @override
  String get loginErrorInvalidCredential =>
      'Неверный адрес эл. почты или пароль. Проверьте данные и повторите попытку.';

  @override
  String get loginErrorTooManyRequests =>
      'Слишком много попыток. Пожалуйста, повторите попытку позже.';
}
