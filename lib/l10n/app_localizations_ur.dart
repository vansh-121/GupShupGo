// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get commonCancel => 'منسوخ کریں';

  @override
  String get commonOk => 'ٹھیک ہے';

  @override
  String get commonContinue => 'جاری رکھیں';

  @override
  String get commonSave => 'محفوظ کریں';

  @override
  String get commonRetry => 'دوبارہ کوشش کریں';

  @override
  String get commonClose => 'بند کریں';

  @override
  String get commonGotIt => 'سمجھ گیا';

  @override
  String get settingsTitle => 'سیٹنگز';

  @override
  String get settingsLanguageTitle => 'زبان';

  @override
  String get settingsLanguageSubtitle => 'اپنی پسندیدہ زبان منتخب کریں';

  @override
  String get languagePickerTitle => 'زبان';

  @override
  String get languageSystemDefault => 'سسٹم ڈیفالٹ';

  @override
  String get languageSystemDefaultSubtitle => 'اپنے آلے کی زبان کے مطابق';

  @override
  String get loginContinueWithPhone => 'فون کے ساتھ جاری رکھیں';

  @override
  String get loginContinueWithGoogle => 'Google کے ساتھ جاری رکھیں';

  @override
  String get loginUseEmailPassword => 'ای میل اور پاس ورڈ استعمال کریں';

  @override
  String get loginSignIn => 'سائن ان کریں';

  @override
  String get loginSignUp => 'سائن اپ کریں';

  @override
  String get loginCreateAccount => 'اکاؤنٹ بنائیں';

  @override
  String get loginForgotPassword => 'پاس ورڈ بھول گئے؟';

  @override
  String get loginOfflineChat => 'آف لائن چیٹ';

  @override
  String get loginHintName => 'آپ کا نام';

  @override
  String get loginHintEmail => 'ای میل';

  @override
  String get loginHintPassword => 'پاس ورڈ';

  @override
  String get loginPasswordHelper =>
      'کم از کم 8 حروف، بشمول ایک حرف اور ایک ہندسہ';

  @override
  String loginResetEmailSent(String email) {
    return '$email پر پاس ورڈ ری سیٹ ای میل بھیج دی گئی ہے';
  }

  @override
  String get loginErrorEnterEmail => 'براہ کرم اپنا ای میل درج کریں';

  @override
  String get loginErrorValidEmail => 'براہ کرم ایک درست ای میل درج کریں';

  @override
  String get loginErrorEnterPassword => 'براہ کرم اپنا پاس ورڈ درج کریں';

  @override
  String get loginErrorPasswordMin6 => 'پاس ورڈ کم از کم 6 حروف کا ہونا چاہیے';

  @override
  String get loginErrorEnterPasswordSignup => 'براہ کرم ایک پاس ورڈ درج کریں';

  @override
  String get loginErrorPasswordMin8 => 'پاس ورڈ کم از کم 8 حروف کا ہونا چاہیے';

  @override
  String get loginErrorPasswordLetter => 'پاس ورڈ میں ایک حرف شامل ہونا چاہیے';

  @override
  String get loginErrorPasswordNumber =>
      'پاس ورڈ میں ایک ہندسہ شامل ہونا چاہیے';

  @override
  String get loginErrorEnterName => 'براہ کرم اپنا نام درج کریں';

  @override
  String get loginErrorGoogleCancelled =>
      'Google سائن ان منسوخ کر دیا گیا تھا۔';

  @override
  String get loginErrorProfileLoad =>
      'آپ کا پروفائل لوڈ نہیں ہو سکا۔ اپنا انٹرنیٹ کنکشن چیک کریں اور دوبارہ کوشش کریں۔';

  @override
  String get loginErrorGoogleFailed =>
      'Google سائن ان ناکام ہو گیا۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get loginErrorSignInFailed =>
      'سائن ان کرنے میں ناکامی۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get loginErrorSignUpFailed =>
      'سائن اپ کرنے میں ناکامی۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get loginErrorGeneric =>
      'ایک خرابی پیش آ گئی۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get loginErrorResetFailed =>
      'ری سیٹ ای میل بھیجنے میں ناکامی۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get loginErrorUserNotFound =>
      'اس ای میل سے کوئی اکاؤنٹ نہیں ملا۔ براہ کرم سائن اپ کریں۔';

  @override
  String get loginErrorWrongPassword =>
      'غلط پاس ورڈ۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get loginErrorEmailInUse =>
      'اس ای میل سے پہلے ہی ایک اکاؤنٹ موجود ہے۔ براہ کرم سائن ان کریں۔';

  @override
  String get loginErrorInvalidEmail => 'براہ کرم ایک درست ای میل پتہ درج کریں۔';

  @override
  String get loginErrorWeakPassword =>
      'پاس ورڈ بہت کمزور ہے۔ کم از کم 6 حروف استعمال کریں۔';

  @override
  String get loginErrorInvalidCredential =>
      'غلط ای میل یا پاس ورڈ۔ براہ کرم تصدیق کریں اور دوبارہ کوشش کریں۔';

  @override
  String get loginErrorTooManyRequests =>
      'بہت زیادہ کوششیں۔ براہ کرم بعد میں دوبارہ کوشش کریں۔';

  @override
  String get homeNavChats => 'چیٹس';

  @override
  String get homeNavMoments => 'لمحات';

  @override
  String get homeNavCalls => 'کالز';

  @override
  String get homeNavProfile => 'پروفائل';

  @override
  String get homeTooltipOfflineChat => 'آف لائن چیٹ — قریبی لوگوں سے بات کریں';

  @override
  String get homeTooltipSearch => 'تلاش کریں';

  @override
  String get homeMenuProfile => 'پروفائل';

  @override
  String get homeMenuSettings => 'ترتیبات';

  @override
  String get homeMenuRateUs => 'ہمیں ریٹ کریں';

  @override
  String get homeMenuReportIssue => 'مسئلہ رپورٹ کریں';

  @override
  String get homeMenuWhatsNew => 'نیا کیا ہے';

  @override
  String get homeMenuLogOut => 'لاگ آؤٹ';

  @override
  String get homeEmptyChatsTitle => 'ابھی کوئی چیٹ نہیں';

  @override
  String get homeEmptyChatsSubtitle =>
      'نیچے دیے گئے بٹن پر ٹیپ کر کے گفتگو شروع کریں';

  @override
  String get homeNewChatButton => 'نئی چیٹ';

  @override
  String get homeAiAssistantTitle => 'GupAI';

  @override
  String get homeAiAssistantSubtitle =>
      'ڈرافٹ لکھیں، ترجمہ کریں، خلاصہ بنائیں اور بہت کچھ';

  @override
  String get homeStrangerMatchTitle => 'کسی اجنبی سے رابطہ کریں';

  @override
  String get homeStrangerMatchSubtitle => 'گمنام چیٹ — میچ کے لیے ٹیپ کریں!';

  @override
  String get homeMyMoment => 'میرا لمحہ';

  @override
  String get homeRecentMoments => 'حالیہ لمحات';

  @override
  String get homeEmptyMomentsTitle => 'ابھی کوئی اپ ڈیٹ نہیں۔';

  @override
  String get homeEmptyMomentsSubtitle => 'شیئر کرنے کے لیے کیمرے پر ٹیپ کریں۔';

  @override
  String get homeTapToAddMoment => 'اپ ڈیٹ شامل کرنے کے لیے ٹیپ کریں';

  @override
  String get homeEmptyCallsTitle => 'کوئی کال ہسٹری نہیں';

  @override
  String get homeEmptyCallsSubtitle => 'آپ کی حالیہ کالز یہاں ظاہر ہوں گی';

  @override
  String get chatInputHint => 'پیغام لکھیں...';

  @override
  String get chatSearchHint => 'پیغامات تلاش کریں...';

  @override
  String get chatStatusTyping => 'ٹائپ کر رہے ہیں...';

  @override
  String get chatStatusOnline => 'آن لائن';

  @override
  String get chatStatusOffline => 'آف لائن';

  @override
  String chatStatusLastSeen(String time) {
    return 'آخری بار دیکھا گیا $time';
  }

  @override
  String get chatEndToEndEncrypted => 'اینڈ ٹو اینڈ انکرپٹڈ';

  @override
  String get chatNoInternetOfflineTitle =>
      'انٹرنیٹ نہیں ہے؟ قریبی آلات کے ساتھ آف لائن چیٹ کریں';

  @override
  String get chatEnableOfflineButton => 'فعال کریں';

  @override
  String get chatSlideToCancel => 'منسوخ کرنے کے لیے سلائیڈ کریں';

  @override
  String get chatTooltipVoiceCall => 'وائس کال';

  @override
  String get chatTooltipVideoCall => 'ویڈیو کال';

  @override
  String get chatMenuContactInfo => 'رابطے کی معلومات';

  @override
  String get chatMenuSearch => 'تلاش کریں';

  @override
  String get chatMenuChatTheme => 'چیٹ تھیم';

  @override
  String get chatMenuExportChat => 'چیٹ ایکسپورٹ کریں';

  @override
  String get chatMenuMuteNotifications => 'اطلاعات خاموش کریں';

  @override
  String get chatMenuUnmuteNotifications => 'اطلاعات بحال کریں';

  @override
  String get chatMenuBlockContact => 'رابطہ بلاک کریں';

  @override
  String get chatActionReply => 'جواب دیں';

  @override
  String get chatActionCopy => 'کاپی کریں';

  @override
  String get chatActionForward => 'آگے بھیجیں';

  @override
  String get chatActionTranslate => 'ترجمہ کریں';

  @override
  String get chatActionSummarise => 'خلاصہ کریں';

  @override
  String get chatActionAskGupAi => 'GupAI سے پوچھیں';

  @override
  String get chatActionEdit => 'ترمیم کریں';

  @override
  String get chatActionDelete => 'حذف کریں';

  @override
  String get chatDeleteMessageTitle => 'پیغام حذف کریں؟';

  @override
  String get chatDeleteMessageForEveryonePrompt =>
      'صرف اپنے لیے حذف کریں، یا سب کے لیے؟';

  @override
  String chatDeleteMessageForMeOnlyPrompt(String name) {
    return 'یہ صرف آپ کے آلات سے ہٹے گا۔ $name اب بھی اسے دیکھ سکیں گے۔';
  }

  @override
  String get chatDeleteForMe => 'میرے لیے حذف کریں';

  @override
  String get chatDeleteForEveryone => 'سب کے لیے حذف کریں';

  @override
  String chatBlockContactTitle(String name) {
    return '$name کو بلاک کریں؟';
  }

  @override
  String get chatBlockContactPrompt =>
      'بلاک شدہ رابطے آپ کو پیغامات یا کال نہیں کر سکتے۔ آپ ترتیبات ← رازداری سے ان بلاک کر سکتے ہیں۔';

  @override
  String get chatBlockButton => 'بلاک کریں';

  @override
  String get chatForwardTo => 'آگے بھیجیں';

  @override
  String get chatNoForwardChats => 'آگے بھیجنے کے لیے کوئی دوسری چیٹ نہیں ہے';

  @override
  String get chatCannotSendMediaBlocked =>
      'اس رابطے کو میڈیا نہیں بھیجا جا سکتا';

  @override
  String get attachmentShareTitle => 'شیئر کریں';

  @override
  String get attachmentPhoto => 'تصویر';

  @override
  String get attachmentPhotoSubtitle => 'گیلری سے تصویر منتخب کریں';

  @override
  String get attachmentVideo => 'ویڈیو';

  @override
  String get attachmentVideoSubtitle => 'گیلری سے ویڈیو منتخب کریں';

  @override
  String get attachmentDocument => 'دستاویز';

  @override
  String get attachmentDocumentSubtitle => 'پی ڈی ایف، آفس فائل، زپ فائل';

  @override
  String get attachmentLocation => 'مقام';

  @override
  String get attachmentLocationSubtitle => 'اپنا موجودہ مقام شیئر کریں';

  @override
  String get attachmentViewOnce => 'ایک بار دیکھنے کے لیے';

  @override
  String get attachmentViewOnceSubtitle =>
      'کھولنے کے بعد تصویر یا ویڈیو غائب ہو جاتی ہے';

  @override
  String get contactsTitle => 'رابطے اور دریافت';

  @override
  String get contactsTabFriends => 'دوست';

  @override
  String get contactsTabRequests => 'درخواستیں';

  @override
  String get contactsTabDiscover => 'دریافت';

  @override
  String get contactsScanQrTooltip => 'کیو آر کوڈ اسکین کریں';

  @override
  String get contactsMyHandleTooltip => 'میرا ہینڈل';

  @override
  String get contactsSetUsernamePrompt =>
      'پہلے اپنی پروفائل میں @username سیٹ کریں — آپ کا QR کوڈ یہی شیئر کرتا ہے۔';

  @override
  String get contactsMyQrCodeTitle => 'میری پروفائل کا QR کوڈ';

  @override
  String get contactsMyQrCodeSubtitle =>
      'دوست فوری طور پر جڑنے کے لیے یہ کوڈ اسکین کر سکتے ہیں';

  @override
  String get contactsCopyProfileLink => 'پروفائل لنک کاپی کریں';

  @override
  String contactsProfileLinkCopied(String username) {
    return '@$username کا پروفائل لنک کاپی ہو گیا!';
  }

  @override
  String get contactsScanSomeonesCode => 'کسی کا کوڈ اسکین کریں';

  @override
  String get contactsPermissionDenied =>
      'رابطوں تک رسائی کی اجازت مسترد کر دی گئی۔';

  @override
  String get contactsNoUsersFound =>
      'آپ کے رابطوں میں ابھی تک کوئی GupShupGo صارف نہیں ملا۔';

  @override
  String contactsFailedToSync(String error) {
    return 'رابطے ہم آہنگ کرنے میں ناکامی: $error';
  }

  @override
  String contactsMatchedCount(int count) {
    return 'GupShupGo پر $count رابطے';
  }

  @override
  String get contactsFromDeviceContacts => 'آپ کے آلے کے رابطوں سے';

  @override
  String get contactsLoadFriendsError => 'آپ کے دوست لوڈ نہیں ہو سکے۔';

  @override
  String get contactsNoFriendsTitle => 'ابھی تک کوئی دوست شامل نہیں کیا گیا';

  @override
  String get contactsNoFriendsPrompt =>
      '@username، فون یا ای میل کے ذریعے تلاش کرنے کے لیے دریافت ٹیب کا استعمال کریں!';

  @override
  String get contactsDiscoverPeopleButton => 'لوگوں کو دریافت کریں';

  @override
  String get contactsQuickConnectHeader => 'فوری رابطہ';

  @override
  String get contactsNoSuggestions => 'فی الحال کوئی تجاویز دستیاب نہیں ہیں۔';

  @override
  String get contactsLoadRequestsError => 'آپ کی درخواستیں لوڈ نہیں ہو سکیں۔';

  @override
  String contactsPendingRequestsHeader(int count) {
    return 'زیر التواء درخواستیں ($count)';
  }

  @override
  String get contactsNoPendingRequestsTitle => 'کوئی زیر التواء درخواست نہیں';

  @override
  String get contactsNoPendingRequestsSubtitle =>
      'جب صارفین آپ کو درخواستیں بھیجیں گے تو وہ یہاں نظر آئیں گی۔';

  @override
  String get contactsWantsToConnect => 'رابطہ قائم کرنا چاہتے ہیں';

  @override
  String get contactsAcceptButton => 'قبول کریں';

  @override
  String get contactsAcceptFailed =>
      'درخواست قبول نہیں کی جا سکی۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String contactsConnectedWith(String name) {
    return '$name سے رابطہ قائم ہو گیا!';
  }

  @override
  String get contactsDeclineFailed =>
      'درخواست مسترد نہیں کی جا سکی۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get contactsYouMightKnowHeader => 'آپ شاید جانتے ہوں';

  @override
  String get contactsSeeAll => 'سب دیکھیں';

  @override
  String get contactsSearchHint => 'نام، @ہینڈل، فون یا ای میل تلاش کریں...';

  @override
  String get contactsTurnOnDiscoverability =>
      'تلاش اور تجاویز میں ظاہر ہونے کے لیے مرئیت آن کریں۔';

  @override
  String get contactsNoMatchingUsersTitle => 'کوئی مماثل صارف نہیں ملا';

  @override
  String get contactsNoMatchingUsersSubtitle =>
      '@username، فون نمبر یا ای میل چیک کریں اور دوبارہ کوشش کریں۔';

  @override
  String get contactsDiscoverHeroTitle => 'GupShupGo پر لوگوں کو تلاش کریں';

  @override
  String get contactsDiscoverHeroSubtitle =>
      'دنیا بھر میں اعلیٰ معیار کے روابط کے ساتھ اپنے دائرے کو بڑھائیں۔';

  @override
  String get contactsSyncDeviceContacts => 'آلے کے رابطے ہم آہنگ کریں';

  @override
  String get contactsSyncingContacts => 'رابطے ہم آہنگ ہو رہے ہیں...';

  @override
  String get contactsSyncDeviceSubtitle =>
      'فون کی کتاب سے اپنے دوستوں کو فوری تلاش کریں';

  @override
  String get contactsSuggestedUsersHeader => 'تجویز کردہ صارفین';

  @override
  String get contactsAddFriendButton => 'دوست بنائیں';

  @override
  String get contactsRequestedButton => 'درخواست بھیجی گئی';

  @override
  String contactsRequestSent(String name) {
    return '$name کو دوستی کی درخواست بھیج دی گئی!';
  }

  @override
  String get contactsRequestFailed =>
      'درخواست پہلے سے زیر التوا ہے یا ناکام ہو گئی۔';

  @override
  String get contactsRequestUnavailable => 'یہ درخواست اب دستیاب نہیں ہے۔';

  @override
  String get profileEditTitle => 'پروفائل میں ترمیم کریں';

  @override
  String get profileSaveButton => 'محفوظ کریں';

  @override
  String get profileTapToChangePhoto => 'تصویر تبدیل کرنے کے لیے تھپتھپائیں';

  @override
  String get profileUpgradeToPro => 'پرو پر اپ گریڈ کریں';

  @override
  String get profileSectionName => 'آپ کا نام';

  @override
  String get profileNameHint => 'اپنا نام درج کریں';

  @override
  String get profileSectionHandle => 'منفرد ہینڈل';

  @override
  String get profileHandleNotSet => 'ابھی سیٹ نہیں ہوا';

  @override
  String get profileChangeHandle => 'تبدیل کریں';

  @override
  String get profileSectionAbout => 'کے بارے میں';

  @override
  String get profileAboutHint => 'آپ کیا سوچ رہے ہیں؟';

  @override
  String get profileDefaultAbout => 'ارے! میں GupShupGo استعمال کر رہا ہوں۔';

  @override
  String get profileSectionPhone => 'فون';

  @override
  String get profileSectionEmail => 'ای میل';

  @override
  String get profileSectionLinkedMethods => 'منسلک سائن ان طریقے';

  @override
  String get profileNotLinked => 'منسلک نہیں';

  @override
  String get profileNameEmpty => 'نام خالی نہیں ہو سکتا۔';

  @override
  String get profileUpdatedSuccess => 'پروفائل اپ ڈیٹ ہو گئی';

  @override
  String profileUploadPhotoFailed(String error) {
    return 'تصویر اپ لوڈ کرنے میں ناکامی: $error';
  }

  @override
  String profileSaveFailed(String error) {
    return 'پروفائل محفوظ کرنے میں ناکامی: $error';
  }

  @override
  String get profilePoints => 'پوائنٹس';

  @override
  String get profileBadges => 'بیجز';

  @override
  String get profileBestBond => 'بہترین بانڈ';

  @override
  String get settingsAccountCard => 'اکاؤنٹ';

  @override
  String get settingsProfileTile => 'پروفائل';

  @override
  String get settingsLinkedMethodsTile => 'منسلک سائن ان طریقے';

  @override
  String get settingsPhoneTile => 'فون نمبر';

  @override
  String get settingsEmailTile => 'ای میل';

  @override
  String get settingsPrivacyCard => 'رازداری';

  @override
  String get settingsDiscoverability => 'قابل دریافت حیثیت';

  @override
  String get settingsLastSeen => 'آخری بار دیکھا گیا';

  @override
  String get settingsReadReceipts => 'پڑھنے کی رسیدیں';

  @override
  String get settingsAdPreferences => 'اشتہارات کی ترجیحات';

  @override
  String get settingsManage => 'انتظام کریں';

  @override
  String get settingsAppearanceCard => 'ظاہری شکل';

  @override
  String get settingsTheme => 'تھیم';

  @override
  String get settingsThemeLight => 'روشن';

  @override
  String get settingsThemeDark => 'تاریک';

  @override
  String get settingsThemeSystem => 'سسٹم';

  @override
  String get settingsChatTheme => 'چیٹ تھیم';

  @override
  String get settingsHelpSecurityCard => 'مدد اور سیکیورٹی';

  @override
  String get settingsHelpCenter => 'امدادی مرکز';

  @override
  String get settingsReportProblem => 'مسئلہ رپورٹ کریں';

  @override
  String get settingsE2EEShield => 'اینڈ ٹو اینڈ انکرپشن (والٹ)';

  @override
  String get settingsVerifySafetyNumber => 'حفاظتی نمبر کی تصدیق کریں';

  @override
  String get settingsBlockedContacts => 'بلاک شدہ رابطے';

  @override
  String get settingsClearAllGupHistory => 'تمام چیٹ ہسٹری صاف کریں';

  @override
  String get settingsRateUs => 'ہمیں ریٹ کریں';

  @override
  String get settingsWhatsNew => 'نیا کیا ہے';

  @override
  String get settingsCheckForUpdates => 'اپ ڈیٹس چیک کریں';

  @override
  String get settingsAppInfo => 'ایپ کی معلومات';

  @override
  String get settingsLogOut => 'لاگ آؤٹ';

  @override
  String get settingsLogOutConfirmTitle => 'لاگ آؤٹ';

  @override
  String get settingsLogOutConfirmPrompt =>
      'کیا آپ واقعی GupShupGo سے لاگ آؤٹ کرنا چاہتے ہیں؟';

  @override
  String get settingsSigningOut => 'لاگ آؤٹ ہو رہا ہے…';

  @override
  String get settingsClearChatsConfirmTitle => 'تمام چیٹس صاف کریں';

  @override
  String get settingsClearChatsConfirmPrompt =>
      'یہ آپ کی تمام پیغامات کی تاریخ مستقل طور پر حذف کر دے گا۔ اس عمل کو واپس نہیں لایا جا سکتا۔';

  @override
  String get settingsDeleteAll => 'سب حذف کریں';

  @override
  String get settingsClearingChats => 'چیٹس صاف ہو رہی ہیں...';

  @override
  String get settingsAllChatsCleared => 'تمام چیٹس صاف ہو گئیں';

  @override
  String settingsClearChatsFailed(String error) {
    return 'چیٹس صاف کرنے میں ناکامی: $error';
  }

  @override
  String get settingsChooseThemeTitle => 'تھیم منتخب کریں';

  @override
  String get settingsUnlockPremiumFeatures => 'پریمیم خصوصیات کھولیں';

  @override
  String settingsProDaysLeft(String planLabel, int daysRemaining) {
    return '$planLabel · $daysRemaining دن باقی ہیں';
  }

  @override
  String get settingsCheckingForUpdates => 'اپ ڈیٹس چیک کی جا رہی ہیں…';

  @override
  String settingsUpToDate(String version) {
    return 'آپ تازہ ترین ورژن پر ہیں (v$version)۔';
  }

  @override
  String get settingsUpdateCheckUnavailable =>
      'اپ ڈیٹس چیک نہیں ہو سکیں۔ یقینی بنائیں کہ ایپ گوگل پلے اسٹور سے انسٹال کی گئی ہے۔';

  @override
  String get settingsNoBlockedContacts => 'کوئی بلاک شدہ رابطہ نہیں ہے';

  @override
  String get settingsUnblock => 'ان بلاک کریں';

  @override
  String settingsUserUnblocked(String name) {
    return '$name کو ان بلاک کر دیا گیا';
  }

  @override
  String get settingsVerifyContactTitle => 'رابطے کی تصدیق کریں';

  @override
  String get settingsVerifyContactSubtitle =>
      'مشترکہ حفاظتی نمبر دیکھنے کے لیے ایک رابطہ منتخب کریں۔';

  @override
  String get settingsComputingSafetyNumber =>
      'حفاظتی نمبر کا حساب لگایا جا رہا ہے…';

  @override
  String settingsSafetyNumberExplanation(String name) {
    return 'اگر نیچے دیا گیا نمبر $name کے آلے سے ملتا ہے تو انکرپشن کی تصدیق ہو جاتی ہے۔';
  }

  @override
  String get settingsSafetyNumberNoBundle =>
      'اس رابطے نے ابھی تک کوئی انکرپشن بنڈل شائع نہیں کیا ہے۔';

  @override
  String get settingsSafetyNumberCompareHint =>
      'اس نمبر کا بالمشافہ یا قابل اعتماد کال پر موازنہ کریں۔';

  @override
  String get callEndToEndEncrypted => 'شروع سے آخر تک محفوظ (انکرپٹڈ)';

  @override
  String get callSecuring => 'کال محفوظ کی جا رہی ہے…';

  @override
  String get callNotEncrypted => 'انکرپٹڈ نہیں ہے';

  @override
  String get callIncomingVoice => 'ان کمنگ وائس کال';

  @override
  String get callIncomingVideo => 'ان کمنگ ویڈیو کال';

  @override
  String get callVoiceCall => 'وائس کال';

  @override
  String get callVideoCall => 'ویڈیو کال';

  @override
  String get callDecline => 'مسترد کریں';

  @override
  String get callAccept => 'قبول کریں';

  @override
  String get callConnecting => 'رابطہ ہو رہا ہے...';

  @override
  String get callSettingUp => 'کال سیٹ اپ ہو رہی ہے...';

  @override
  String callNotifying(String name) {
    return '$name کو مطلع کیا جا رہا ہے...';
  }

  @override
  String get callRinging => 'گھنٹی بج رہی ہے...';

  @override
  String get callConnected => 'منسلک';

  @override
  String get callOnHold => 'ہولڈ پر';

  @override
  String get callCalling => 'کال کی جا رہی ہے...';

  @override
  String get callWaitingForUser => 'صارف کا انتظار ہے...';

  @override
  String get callEnded => 'کال ختم ہوگئی';

  @override
  String get callDeclined => 'کال مسترد کردی گئی';

  @override
  String get callNoAnswer => 'کوئی جواب نہیں';

  @override
  String get callFailedToConnect => 'رابطہ قائم نہیں ہو سکا';

  @override
  String callFailedToStart(String error) {
    return 'کال شروع کرنے میں ناکامی: $error';
  }

  @override
  String get callTokenExpired =>
      'ٹوکن ختم یا غلط ہے۔ براہ کرم دوبارہ کال شروع کریں۔';

  @override
  String callFailedToInit(String type, String error) {
    return '$type کال شروع کرنے میں ناکامی: $error';
  }

  @override
  String get callTurnOffSpeaker => 'اسپیکر بند کریں';

  @override
  String get callTurnOnSpeaker => 'اسپیکر آن کریں';

  @override
  String get callMuteMic => 'مائیک میوٹ کریں';

  @override
  String get callUnmuteMic => 'مائیک ان میوٹ کریں';

  @override
  String get callEndCall => 'کال ختم کریں';

  @override
  String get callSwitchCamera => 'کیمرا تبدیل کریں';

  @override
  String get callTurnOffCamera => 'کیمرا بند کریں';

  @override
  String get callTurnOnCamera => 'کیمرا آن کریں';

  @override
  String statusViewedByCount(int count) {
    return '$count افراد نے دیکھا';
  }

  @override
  String get statusNoViewsYet => 'ابھی تک کوئی ویوز نہیں';

  @override
  String statusViewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ویوز',
    );
    return '$_temp0';
  }

  @override
  String get statusDeleteTitle => 'اسٹیٹس حذف کریں';

  @override
  String get statusDeleteConfirm =>
      'کیا آپ واقعی یہ اسٹیٹس حذف کرنا چاہتے ہیں؟';

  @override
  String get statusDeleteButton => 'حذف کریں';

  @override
  String get statusReplySent => 'جواب بھیج دیا گیا';

  @override
  String statusReplyFailed(String error) {
    return 'جواب بھیجنے میں ناکامی: $error';
  }

  @override
  String get statusNoActive => 'کوئی فعال اسٹیٹس نہیں';

  @override
  String get statusCouldNotLoad => 'یہ اپ ڈیٹ لوڈ نہیں ہو سکی';

  @override
  String get statusTapToRetry => 'دوبارہ کوشش کے لیے ٹیپ کریں';

  @override
  String get statusFailedToLoadImage => 'تصویر لوڈ کرنے میں ناکامی';

  @override
  String get statusLoadingVideo => 'ویڈیو لوڈ ہو رہی ہے...';

  @override
  String get statusEnterTextPrompt => 'براہ کرم کچھ متن درج کریں';

  @override
  String get statusNoContactsNotice =>
      'ابھی کوئی رابطے نہیں — اسٹیٹس لگانے سے پہلے چیٹ شروع کریں۔';

  @override
  String statusPostFailed(String error) {
    return 'اسٹیٹس پوسٹ کرنے میں ناکامی: $error';
  }

  @override
  String get statusTypeHint => 'اسٹیٹس لکھیں...';

  @override
  String get statusCamera => 'کیمرا';

  @override
  String get statusTakePhoto => 'تصویر لیں';

  @override
  String get statusGalleryPhoto => 'گیلری تصویر';

  @override
  String get statusChooseImageGallery => 'گیلری سے تصویر منتخب کریں';

  @override
  String get statusRecordVideo => 'ویڈیو ریکارڈ کریں';

  @override
  String get statusRecordShortVideo => 'مختصر ویڈیو ریکارڈ کریں';

  @override
  String get statusGalleryVideo => 'گیلری ویڈیو';

  @override
  String get statusChooseVideoGallery => 'گیلری سے ویڈیو منتخب کریں';

  @override
  String statusFailedPickImage(String error) {
    return 'تصویر منتخب کرنے میں ناکامی: $error';
  }

  @override
  String statusFailedPickVideo(String error) {
    return 'ویڈیو منتخب کرنے میں ناکامی: $error';
  }

  @override
  String get statusChangeBgColorTooltip => 'پس منظر کا رنگ تبدیل کریں';

  @override
  String aiMessagesRemaining(int count) {
    return '$count باقی';
  }

  @override
  String get aiQuotaDialogTitle => 'GupAI پیغامات';

  @override
  String aiQuotaRemainingOfTotal(int remaining, int total) {
    return 'آج $total میں سے $remaining باقی';
  }

  @override
  String aiQuotaUsedResetNote(int used) {
    return 'آج $used استعمال ہوئے · کل ری سیٹ ہوگا۔ اشتہار دیکھیں یا پرو لیں۔';
  }

  @override
  String get aiQuotaGotIt => 'سمجھ گیا';

  @override
  String get aiTitle => 'GupAI';

  @override
  String get aiSubtitle => 'آپ کا ایپ اسسٹنٹ';

  @override
  String get aiEmptyHelpTitle => 'میں کیا مدد کر سکتا ہوں؟';

  @override
  String get aiEmptyHelpSubtitle =>
      'جوابات تیار کریں، ترجمہ کریں، خلاصہ بنائیں یا سوال پوچھیں۔';

  @override
  String get meshOfflineChatConnected => 'آف لائن چیٹ · منسلک';

  @override
  String get meshConnecting => 'رابطہ ہو رہا ہے…';

  @override
  String get meshBannerNotice => 'آف لائن چیٹ — انٹرنیٹ یا سرور کے بغیر';

  @override
  String meshSayHiTo(String name) {
    return '$name کو ہیلو کہیں';
  }

  @override
  String meshOfflineDescription(String name) {
    return 'آپ آف لائن چیٹ میں ہیں۔ پیغامات صرف آپ اور $name کے درمیان رہتے ہیں۔';
  }

  @override
  String get meshMediaUnavailable => 'یہ میڈیا اب دستیاب نہیں ہے۔';

  @override
  String get meshViewOnceTitle => 'ایک بار دیکھیں';

  @override
  String meshViewOncePrompt(String type) {
    return 'آپ اس $type کو صرف ایک بار کھول سکتے ہیں۔';
  }

  @override
  String get arcadeTabOverview => 'جائزہ';

  @override
  String get arcadeTabChallenges => 'چیلنجز';

  @override
  String get arcadeTabLeaderboard => 'لیڈر بورڈ';

  @override
  String get arcadeFailedLoadStats => 'اعداد و شمار لوڈ کرنے میں ناکامی۔';

  @override
  String get aiAskHint => 'GupAI سے کچھ بھی پوچھیں…';
}
