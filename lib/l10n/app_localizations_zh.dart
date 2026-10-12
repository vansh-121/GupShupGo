// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get commonCancel => '取消';

  @override
  String get commonOk => '确定';

  @override
  String get commonContinue => '继续';

  @override
  String get commonSave => '保存';

  @override
  String get commonRetry => '重试';

  @override
  String get commonClose => '关闭';

  @override
  String get commonGotIt => '知道了';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsLanguageTitle => '语言';

  @override
  String get settingsLanguageSubtitle => '选择你的首选语言';

  @override
  String get languagePickerTitle => '语言';

  @override
  String get languageSystemDefault => '系统默认';

  @override
  String get languageSystemDefaultSubtitle => '跟随设备语言';

  @override
  String get loginContinueWithPhone => '使用手机号继续';

  @override
  String get loginContinueWithGoogle => '使用 Google 继续';

  @override
  String get loginUseEmailPassword => '使用邮箱和密码';

  @override
  String get loginSignIn => '登录';

  @override
  String get loginSignUp => '注册';

  @override
  String get loginCreateAccount => '创建账号';

  @override
  String get loginForgotPassword => '忘记密码？';

  @override
  String get loginOfflineChat => '离线聊天';

  @override
  String get loginHintName => '您的姓名';

  @override
  String get loginHintEmail => '邮箱';

  @override
  String get loginHintPassword => '密码';

  @override
  String get loginPasswordHelper => '至少8个字符，包含字母和数字';

  @override
  String loginResetEmailSent(String email) {
    return '密码重置邮件已发送至 $email';
  }

  @override
  String get loginErrorEnterEmail => '请输入您的邮箱';

  @override
  String get loginErrorValidEmail => '请输入有效的邮箱地址';

  @override
  String get loginErrorEnterPassword => '请输入您的密码';

  @override
  String get loginErrorPasswordMin6 => '密码长度至少为 6 个字符';

  @override
  String get loginErrorEnterPasswordSignup => '请输入密码';

  @override
  String get loginErrorPasswordMin8 => '密码长度至少为 8 个字符';

  @override
  String get loginErrorPasswordLetter => '密码必须包含字母';

  @override
  String get loginErrorPasswordNumber => '密码必须包含数字';

  @override
  String get loginErrorEnterName => '请输入您的姓名';

  @override
  String get loginErrorGoogleCancelled => 'Google 登录已取消。';

  @override
  String get loginErrorProfileLoad => '无法加载个人资料。请检查网络后重试。';

  @override
  String get loginErrorGoogleFailed => 'Google 登录失败，请重试。';

  @override
  String get loginErrorSignInFailed => '登录失败，请重试。';

  @override
  String get loginErrorSignUpFailed => '注册失败，请重试。';

  @override
  String get loginErrorGeneric => '发生错误，请重试。';

  @override
  String get loginErrorResetFailed => '发送重置邮件失败，请重试。';

  @override
  String get loginErrorUserNotFound => '未找到此邮箱对应的账号。请先注册。';

  @override
  String get loginErrorWrongPassword => '密码错误，请重试。';

  @override
  String get loginErrorEmailInUse => '此邮箱已注册账号，请直接登录。';

  @override
  String get loginErrorInvalidEmail => '请输入有效的邮箱地址。';

  @override
  String get loginErrorWeakPassword => '密码强度太弱，请使用至少 6 个字符。';

  @override
  String get loginErrorInvalidCredential => '邮箱或密码错误，请检查后重试。';

  @override
  String get loginErrorTooManyRequests => '尝试次数过多，请稍后再试。';
}
