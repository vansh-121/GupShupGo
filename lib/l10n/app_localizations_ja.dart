// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonOk => 'OK';

  @override
  String get commonContinue => '続行';

  @override
  String get commonSave => '保存';

  @override
  String get commonRetry => '再試行';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonGotIt => '了解';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsLanguageTitle => '言語';

  @override
  String get settingsLanguageSubtitle => '言語を選択してください';

  @override
  String get languagePickerTitle => '言語';

  @override
  String get languageSystemDefault => 'システムのデフォルト';

  @override
  String get languageSystemDefaultSubtitle => '端末の言語設定に従います';

  @override
  String get loginContinueWithPhone => '電話番号で続行';

  @override
  String get loginContinueWithGoogle => 'Googleで続行';

  @override
  String get loginUseEmailPassword => 'メールとパスワードを使用';

  @override
  String get loginSignIn => 'ログイン';

  @override
  String get loginSignUp => '登録';

  @override
  String get loginCreateAccount => 'アカウント作成';

  @override
  String get loginForgotPassword => 'パスワードをお忘れですか？';

  @override
  String get loginOfflineChat => 'オフラインチャット';

  @override
  String get loginHintName => 'お名前';

  @override
  String get loginHintEmail => 'メールアドレス';

  @override
  String get loginHintPassword => 'パスワード';

  @override
  String get loginPasswordHelper => '英字と数字を含む8文字以上';

  @override
  String loginResetEmailSent(String email) {
    return '$email にパスワード再設定メールを送信しました';
  }

  @override
  String get loginErrorEnterEmail => 'メールアドレスを入力してください';

  @override
  String get loginErrorValidEmail => '有効なメールアドレスを入力してください';

  @override
  String get loginErrorEnterPassword => 'パスワードを入力してください';

  @override
  String get loginErrorPasswordMin6 => 'パスワードは6文字以上にする必要があります';

  @override
  String get loginErrorEnterPasswordSignup => 'パスワードを入力してください';

  @override
  String get loginErrorPasswordMin8 => 'パスワードは8文字以上にする必要があります';

  @override
  String get loginErrorPasswordLetter => 'パスワードには英字を含める必要があります';

  @override
  String get loginErrorPasswordNumber => 'パスワードには数字を含める必要があります';

  @override
  String get loginErrorEnterName => '名前を入力してください';

  @override
  String get loginErrorGoogleCancelled => 'Googleログインがキャンセルされました。';

  @override
  String get loginErrorProfileLoad => 'プロフィールを読み込めませんでした。接続を確認して再試行してください。';

  @override
  String get loginErrorGoogleFailed => 'Googleログインに失敗しました。もう一度お試しください。';

  @override
  String get loginErrorSignInFailed => 'ログインに失敗しました。もう一度お試しください。';

  @override
  String get loginErrorSignUpFailed => 'アカウント登録に失敗しました。もう一度お試しください。';

  @override
  String get loginErrorGeneric => 'エラーが発生しました。もう一度お試しください。';

  @override
  String get loginErrorResetFailed => '再設定メールの送信に失敗しました。もう一度お試しください。';

  @override
  String get loginErrorUserNotFound => 'このメールアドレスのアカウントは見つかりませんでした。新規登録してください。';

  @override
  String get loginErrorWrongPassword => 'パスワードが正しくありません。もう一度お試しください。';

  @override
  String get loginErrorEmailInUse => 'このメールアドレスのアカウントは既に存在します。ログインしてください。';

  @override
  String get loginErrorInvalidEmail => '有効なメールアドレスを入力してください。';

  @override
  String get loginErrorWeakPassword => 'パスワードが短すぎます。6文字以上使用してください。';

  @override
  String get loginErrorInvalidCredential =>
      'メールアドレスまたはパスワードが無効です。確認して再試行してください。';

  @override
  String get loginErrorTooManyRequests => '試行回数が多すぎます。しばらくしてから再試行してください。';
}
