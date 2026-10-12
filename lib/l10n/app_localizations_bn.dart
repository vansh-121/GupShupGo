// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get commonCancel => 'বাতিল';

  @override
  String get commonOk => 'ঠিক আছে';

  @override
  String get commonContinue => 'চালিয়ে যান';

  @override
  String get commonSave => 'সংরক্ষণ করুন';

  @override
  String get commonRetry => 'পুনরায় চেষ্টা করুন';

  @override
  String get commonClose => 'বন্ধ করুন';

  @override
  String get commonGotIt => 'বুঝেছি';

  @override
  String get settingsTitle => 'সেটিংস';

  @override
  String get settingsLanguageTitle => 'ভাষা';

  @override
  String get settingsLanguageSubtitle => 'আপনার পছন্দসই ভাষা বেছে নিন';

  @override
  String get languagePickerTitle => 'ভাষা';

  @override
  String get languageSystemDefault => 'সিস্টেম ডিফল্ট';

  @override
  String get languageSystemDefaultSubtitle => 'আপনার ডিভাইসের ভাষা অনুসরণ করুন';

  @override
  String get loginContinueWithPhone => 'ফোন নম্বর দিয়ে চালিয়ে যান';

  @override
  String get loginContinueWithGoogle => 'Google দিয়ে চালিয়ে যান';

  @override
  String get loginUseEmailPassword => 'ইমেইল ও পাসওয়ার্ড ব্যবহার করুন';

  @override
  String get loginSignIn => 'সাইন ইন';

  @override
  String get loginSignUp => 'সাইন আপ';

  @override
  String get loginCreateAccount => 'অ্যাকাউন্ট তৈরি করুন';

  @override
  String get loginForgotPassword => 'পাসওয়ার্ড ভুলে গেছেন?';

  @override
  String get loginOfflineChat => 'অফলাইন চ্যাট';

  @override
  String get loginHintName => 'আপনার নাম';

  @override
  String get loginHintEmail => 'ইমেইল';

  @override
  String get loginHintPassword => 'পাসওয়ার্ড';

  @override
  String get loginPasswordHelper =>
      'কমপক্ষে ৮টি অক্ষর, একটি অক্ষর এবং একটি সংখ্যা সহ';

  @override
  String loginResetEmailSent(String email) {
    return '$email ঠিকানায় পাসওয়ার্ড রিসেট ইমেল পাঠানো হয়েছে';
  }

  @override
  String get loginErrorEnterEmail => 'অনুগ্রহ করে আপনার ইমেল লিখুন';

  @override
  String get loginErrorValidEmail => 'একটি বৈধ ইমেল লিখুন';

  @override
  String get loginErrorEnterPassword => 'অনুগ্রহ করে আপনার পাসওয়ার্ড লিখুন';

  @override
  String get loginErrorPasswordMin6 => 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে';

  @override
  String get loginErrorEnterPasswordSignup =>
      'অনুগ্রহ করে একটি পাসওয়ার্ড লিখুন';

  @override
  String get loginErrorPasswordMin8 => 'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে';

  @override
  String get loginErrorPasswordLetter =>
      'পাসওয়ার্ডে অন্তত একটি অক্ষর থাকতে হবে';

  @override
  String get loginErrorPasswordNumber =>
      'পাসওয়ার্ডে অন্তত একটি সংখ্যা থাকতে হবে';

  @override
  String get loginErrorEnterName => 'অনুগ্রহ করে আপনার নাম লিখুন';

  @override
  String get loginErrorGoogleCancelled => 'Google সাইন-ইন বাতিল করা হয়েছে।';

  @override
  String get loginErrorProfileLoad =>
      'আপনার প্রোফাইল লোড করা যায়নি। সংযোগ পরীক্ষা করে আবার চেষ্টা করুন।';

  @override
  String get loginErrorGoogleFailed =>
      'Google সাইন-ইন ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।';

  @override
  String get loginErrorSignInFailed =>
      'সাইন ইন করতে ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।';

  @override
  String get loginErrorSignUpFailed =>
      'সাইন আপ করতে ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।';

  @override
  String get loginErrorGeneric =>
      'একটি ত্রুটি ঘটেছে। অনুগ্রহ করে আবার চেষ্টা করুন।';

  @override
  String get loginErrorResetFailed =>
      'রিসেট ইমেল পাঠাতে ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।';

  @override
  String get loginErrorUserNotFound =>
      'এই ইমেল দিয়ে কোনো অ্যাকাউন্ট পাওয়া যায়নি। অনুগ্রহ করে সাইন আপ করুন।';

  @override
  String get loginErrorWrongPassword =>
      'ভুল পাসওয়ার্ড। অনুগ্রহ করে আবার চেষ্টা করুন।';

  @override
  String get loginErrorEmailInUse =>
      'এই ইমেল দিয়ে ইতিমধ্যে একটি অ্যাকাউন্ট রয়েছে। অনুগ্রহ করে সাইন ইন করুন।';

  @override
  String get loginErrorInvalidEmail =>
      'অনুগ্রহ করে একটি বৈধ ইমেল ঠিকানা লিখুন।';

  @override
  String get loginErrorWeakPassword =>
      'পাসওয়ার্ড খুব দুর্বল। কমপক্ষে ৬টি অক্ষর ব্যবহার করুন।';

  @override
  String get loginErrorInvalidCredential =>
      'অবৈধ ইমেল বা পাসওয়ার্ড। পরীক্ষা করে আবার চেষ্টা করুন।';

  @override
  String get loginErrorTooManyRequests =>
      'অনেক বেশি চেষ্টা করা হয়েছে। অনুগ্রহ করে পরে আবার চেষ্টা করুন।';
}
