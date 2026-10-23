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
  String get homeNavChats => 'پیغامات';

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
  String get attachmentScreenShare => 'اسکرین شیئر کریں';

  @override
  String get attachmentScreenShareSubtitle =>
      'چیٹ کے دوران اپنی اسکرین لائیو دکھائیں';

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

  @override
  String get settingsNotificationsTile => 'اطلاعات';

  @override
  String get settingsNotificationsStatusOn => 'آن';

  @override
  String get settingsNotificationsStatusOff => 'آف';

  @override
  String get settingsNotificationsEnabledToast => 'اطلاعات آن ہیں۔';

  @override
  String get settingsEnableNotificationsTitle => 'اطلاعات فعال کریں';

  @override
  String get settingsEnableNotificationsBody =>
      'اطلاعات بند ہیں۔ نئے پیغامات اور کالز کے بارے میں GupShupGo کو مطلع کرنے کی اجازت دینے کے لیے سسٹم سیٹنگز کھولیں۔';

  @override
  String get settingsOpenSystemSettings => 'سیٹنگز کھولیں';

  @override
  String get loginTagline =>
      'نجی پیغام رسانی جو انٹرنیٹ کے بغیر بھی کام کرتی ہے۔';

  @override
  String get settingsPrivacyPolicy => 'رازداری کی پالیسی';

  @override
  String get settingsTerms => 'سروس کی شرائط';

  @override
  String get settingsDeleteAccount => 'اکاؤنٹ حذف کریں';

  @override
  String get inviteSheetTitle => 'دوستوں کو مدعو کریں';

  @override
  String get inviteSheetSubtitle => 'بات پھیلائیں — GupShupGo شیئر کریں';

  @override
  String get inviteShareImageBtn => 'تصویر شیئر کریں';

  @override
  String get inviteShareLinkBtn => 'لنک شیئر کریں';

  @override
  String get inviteCopyLinkBtn => 'لنک کاپی کریں';

  @override
  String get inviteLinkCopied => 'دعوت نامہ لنک کاپی ہوگیا';

  @override
  String inviteMessage(String link) {
    return 'GupShupGo پر مجھ سے چیٹ کریں — یہ انٹرنیٹ کے بغیر بھی کام کرتا ہے 👋 $link';
  }

  @override
  String get inviteCardTagline => 'نجی چیٹ جو آف لائن بھی کام کرتی ہے';

  @override
  String get inviteCardScan => 'ڈاؤن لوڈ کرنے کے لیے اسکین کریں';

  @override
  String get inviteCardDownload => 'گوگل پلے پر ڈاؤن لوڈ کریں';

  @override
  String get homeMenuInvite => 'دوستوں کو مدعو کریں';

  @override
  String get invitePromptTitle => 'کیا آپ GupShupGo سے لطف اندوز ہو رہے ہیں؟';

  @override
  String get invitePromptBody =>
      'دوستوں کے ساتھ یہ اور بھی بہتر ہے — اور انٹرنیٹ کے بغیر بھی کام کرتا ہے۔ کسی کو مدعو کریں؟';

  @override
  String get invitePromptInvite => 'دوستوں کو مدعو کریں';

  @override
  String get invitePromptLater => 'شاید بعد میں';

  @override
  String get homeOfflineBannerTitle => 'انٹرنیٹ نہیں ہے؟ کوئی مسئلہ نہیں';

  @override
  String get homeOfflineBannerSubtitle =>
      'آپ اب بھی بلوٹوتھ کے ذریعے قریبی لوگوں کو پیغامات بھیج سکتے ہیں۔';

  @override
  String homeNearbyBannerTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قریب $count افراد',
      one: 'قریب 1 شخص',
    );
    return '$_temp0';
  }

  @override
  String get homeNearbyBannerSubtitle =>
      'بلوٹوتھ پر چیٹ کریں — انٹرنیٹ کی ضرورت نہیں۔';

  @override
  String get linkBackupTitle => 'بیک اپ سائن ان کا طریقہ شامل کریں';

  @override
  String get linkBackupSubtitle =>
      'گوگل یا ای میل منسلک کریں تاکہ سم نہ ہونے پر بھی آپ واپس سائن ان کر سکیں۔';

  @override
  String get linkGoogleTitle => 'گوگل اکاؤنٹ لنک کریں';

  @override
  String get linkGoogleSubtitleLinked => 'منسلک ہے ✓';

  @override
  String get linkGoogleSubtitleUnlinked => 'بغیر سم کے ون ٹیپ سائن ان';

  @override
  String get linkGoogleAction => 'لنک کریں';

  @override
  String get linkGoogleSuccess => 'گوگل اکاؤنٹ کامیابی سے منسلک ہو گیا!';

  @override
  String get linkGoogleAlreadyUsed =>
      'یہ گوگل اکاؤنٹ پہلے سے کسی دوسرے اکاؤنٹ کے ساتھ رجسٹرڈ ہے۔';

  @override
  String get linkGoogleFailed => 'گوگل لنک کرنا ناکام رہا۔ دوبارہ کوشش کریں۔';

  @override
  String get linkSessionExpired =>
      'سیشن ختم ہو گیا۔ براہ کرم دوبارہ سائن ان کریں۔';

  @override
  String get linkEmailTitle => 'ای میل اور پاس ورڈ لنک کریں';

  @override
  String get linkEmailSubtitleLinked => 'منسلک ہے ✓';

  @override
  String get linkEmailSubtitleUnlinked =>
      'سم یا گوگل نہ ہونے پر ای میل سے سائن ان کریں';

  @override
  String get linkEmailActionAdd => 'شامل کریں';

  @override
  String get linkEmailActionCancel => 'منسوخ کریں';

  @override
  String get linkEmailFieldLabel => 'ای میل';

  @override
  String get linkPasswordFieldLabel => 'پاس ورڈ بنائیں';

  @override
  String get linkPasswordHelper => 'کم از کم 6 حروف';

  @override
  String get linkEmailButton => 'ای میل لنک کریں';

  @override
  String get linkEmailSuccess => 'ای میل کامیابی سے منسلک ہو گئی!';

  @override
  String get linkEmailInvalid => 'درست ای میل پتہ درج کریں۔';

  @override
  String get linkPasswordTooShort =>
      'پاس ورڈ کم از کم 6 حروف پر مشتمل ہونا چاہیے۔';

  @override
  String get linkEmailAlreadyInUse => 'یہ ای میل پہلے سے رجسٹرڈ ہے۔';

  @override
  String get linkEmailAlreadyLinked =>
      'آپ کے اکاؤنٹ سے پہلے ہی ای میل منسلک ہے۔';

  @override
  String get linkEmailFailed => 'ای میل لنک کرنا ناکام رہا۔';

  @override
  String get linkContinueToApp => 'ایپ پر جاری رکھیں';

  @override
  String get linkSkipForNow => 'ابھی کے لیے چھوڑیں';

  @override
  String get linkSkip => 'چھوڑیں';

  @override
  String get phoneAuthTitleEntry => 'اپنے فون نمبر سے سائن ان کریں۔';

  @override
  String get phoneAuthTitleOtp => 'ہمارا بھیجا گیا کوڈ درج کریں۔';

  @override
  String get phoneAuthNameHint => 'آپ کا نام';

  @override
  String get phoneAuthPhoneHint => 'فون نمبر';

  @override
  String get phoneAuthUseSim => 'سم استعمال کریں';

  @override
  String get phoneAuthSendOtp => 'او ٹی پی بھیجیں';

  @override
  String phoneAuthOtpPrompt(String phone) {
    return '$phone پر بھیجا گیا 6 ہندسوں کا کوڈ درج کریں';
  }

  @override
  String get phoneAuthOtpPromptGeneric =>
      'ہمارا بھیجا گیا 6 ہندسوں کا کوڈ درج کریں';

  @override
  String get phoneAuthOtpHint => 'کوڈ درج کریں';

  @override
  String get phoneAuthVerify => 'تصدیق کریں';

  @override
  String get phoneAuthGoBack => 'واپس جائیں';

  @override
  String get phoneAuthResendCode => 'کوڈ دوبارہ بھیجیں';

  @override
  String get phoneAuthEnterName => 'براہ کرم اپنا نام درج کریں';

  @override
  String get phoneAuthEnterValidPhone => 'براہ کرم درست فون نمبر درج کریں';

  @override
  String get phoneAuthEnterCode => 'براہ کرم کوڈ درج کریں';

  @override
  String get phoneAuthRequestNewCode => 'براہ کرم نئے کوڈ کی درخواست کریں۔';

  @override
  String get phoneAuthCodeIncorrect => 'وہ کوڈ غلط ہے۔ دوبارہ کوشش کریں۔';

  @override
  String get phoneAuthErrCodeIncorrect =>
      'وہ کوڈ غلط ہے۔ براہ کرم چیک کر کے دوبارہ کوشش کریں۔';

  @override
  String get phoneAuthErrCodeExpired =>
      'کوڈ کی میعاد ختم ہو گئی۔ دوبارہ بھیجیں۔';

  @override
  String get phoneAuthErrTooManyRequests =>
      'بہت زیادہ کوششیں کی گئیں۔ کچھ دیر انتظار کریں۔';

  @override
  String get phoneAuthErrInvalidPhone => 'فون نمبر درست نہیں لگتا۔';

  @override
  String get phoneAuthErrQuotaExceeded => 'ایس ایم ایس کی حد ختم ہو گئی۔';

  @override
  String get phoneAuthErrFailed => 'تصدیق ناکام ہو گئی۔';

  @override
  String get usernameSetupAppBarTitle => 'اپنا ہینڈل منتخب کریں';

  @override
  String get usernameSetupHeaderTitle => 'اپنی شناخت محفوظ کریں';

  @override
  String get usernameSetupHeaderDesc =>
      'آپ کا @handle GupShupGo پر آپ کی منفرد شناخت ہے۔ دوسرے لوگ فون یا ای میل شیئر کیے بغیر آپ کو محفوظ طریقے سے تلاش کر سکتے ہیں۔';

  @override
  String get usernameSetupInputHint => 'your_handle';

  @override
  String get usernameSetupChecking => 'دستیابی چیک کی جا رہی ہے...';

  @override
  String usernameSetupAvailable(String handle) {
    return '@$handle دستیاب ہے!';
  }

  @override
  String usernameSetupTaken(String handle) {
    return '@$handle پہلے سے کسی اور نے لے رکھا ہے۔';
  }

  @override
  String get usernameSetupCharRules => '3–20 حروف (a-z, 0-9, _)';

  @override
  String get usernameSetupTooShort => 'کم از کم 3 حروف ہونے چاہئیں۔';

  @override
  String get usernameSetupTooLong => 'زیادہ سے زیادہ 20 حروف ہو سکتے ہیں۔';

  @override
  String get usernameSetupInvalidChars =>
      'صرف حروف، اعداد اور انڈر سکور کی اجازت ہے۔';

  @override
  String get usernameSetupRecommended => 'آپ کے لیے تجویز کردہ';

  @override
  String get usernameSetupSaveBtn => 'محفوظ کریں اور جاری رکھیں';

  @override
  String get usernameSetupSkipBtn => 'ابھی کے لیے چھوڑیں';

  @override
  String usernameSetupFailed(String error) {
    return 'صارف نام سیٹ کرنا ناکام رہا: $error';
  }

  @override
  String get vaultProtectTitle => 'والٹ محفوظ کریں';

  @override
  String get vaultUnlockTitle => 'والٹ ان لاک کریں';

  @override
  String get vaultSetupDesc =>
      'پیغامات کی تاریخ کو انکرپٹ کرنے کے لیے پن منتخب کریں۔ نئے فون پر پیغامات پڑھنے کے لیے اس کی ضرورت ہوگی۔';

  @override
  String get vaultUnlockDescBio =>
      'تاریخ تک رسائی کے لیے پن درج کریں یا فنگر پرنٹ لگائیں۔';

  @override
  String get vaultUnlockDescPin => 'تاریخ تک رسائی کے لیے اپنا پن درج کریں۔';

  @override
  String get vaultReinstallHint =>
      'پیغامات کی تاریخ بحال کرنے کے لیے پن درج کریں۔ فنگر پرنٹ بعد میں آن کیا جا سکتا ہے۔';

  @override
  String get vaultUnlockWithFingerprint => 'فنگر پرنٹ سے ان لاک کریں';

  @override
  String get vaultOrDivider => 'یا';

  @override
  String get vaultNewPin => 'نیا پن';

  @override
  String get vaultConfirmPin => 'پن کی تصدیق کریں';

  @override
  String get vaultEnterPin => 'پن درج کریں';

  @override
  String get vaultKeyboardUseLetters => 'حروف استعمال کریں';

  @override
  String get vaultKeyboardUseNumbers => 'نمبر استعمال کریں';

  @override
  String get vaultRestoreLater => 'بعد میں بحال کریں';

  @override
  String get vaultForgotPin => 'پن بھول گئے؟';

  @override
  String get vaultSetPinBtn => 'پن سیٹ کریں';

  @override
  String get vaultDecryptBtn => 'ان لاک کریں';

  @override
  String get vaultPinMinLength => 'پن کم از کم 6 حروف کا ہونا چاہیے۔';

  @override
  String get vaultPinsDoNotMatch => 'پن مماثل نہیں ہیں۔';

  @override
  String get vaultSetupFailed => 'سیٹ اپ ناکام ہو گیا۔';

  @override
  String get vaultIncorrectPin => 'غلط پن۔ دوبارہ کوشش کریں۔';

  @override
  String get vaultFingerprintOutOfDate =>
      'فنگر پرنٹ پرانا ہو چکا ہے۔ پن درج کریں۔';

  @override
  String get vaultBiometricError => 'بائیو میٹرک خرابی۔ پن درج کریں۔';

  @override
  String get vaultBioReasonUnlock =>
      'والٹ ان لاک کرنے کے لیے بائیو میٹرکس کا استعمال کریں';

  @override
  String get vaultBioReasonEnrol =>
      'فوری ان لاک فعال کرنے کے لیے فنگر پرنٹ کی تصدیق کریں';

  @override
  String get vaultAskBioTitle => 'فنگر پرنٹ سے ان لاک کریں؟';

  @override
  String get vaultAskBioDesc =>
      'اس فون پر پن ٹائپ کرنے سے بچیں۔ لیکن نئے فون کے لیے پن کو یاد رکھیں۔';

  @override
  String get vaultAskBioNotNow => 'ابھی نہیں';

  @override
  String get vaultAskBioEnable => 'فعال کریں';

  @override
  String get vaultDeleteMessagesTitle => 'تمام پیغامات حذف کریں؟';

  @override
  String get vaultDeleteMessagesDesc =>
      'پن کے بغیر پیغامات کو ڈیکرپٹ نہیں کیا جا سکتا، ری سیٹ کرنے سے سب کچھ مٹ جائے گا۔';

  @override
  String get vaultDeleteMessagesCancel => 'منسوخ';

  @override
  String get vaultDeleteMessagesConfirm => 'سب کچھ حذف کریں';

  @override
  String get vaultCustodyConfirmTitle => 'والٹ پن کی تصدیق کریں';

  @override
  String get vaultCustodyChooseTitle => 'پن منتخب کریں';

  @override
  String get vaultCustodyConfirmDesc =>
      'آپ کے پیغامات پن سے محفوظ ہیں۔ ایک بار تصدیق کر لیں۔';

  @override
  String get vaultCustodyChooseDesc =>
      'یاد رہنے والا پن منتخب کریں۔ پرانے پیغامات نئے پن سے انکرپٹ ہوں گے۔';

  @override
  String get vaultCustodyDontKnow => 'مجھے پن معلوم نہیں';

  @override
  String get vaultCustodyConfirmBtn => 'تصدیق کریں';

  @override
  String get vaultCustodySaveBtn => 'پن محفوظ کریں';

  @override
  String get vaultCustodyMismatchError => 'پن مماثل نہیں ہے۔';

  @override
  String get vaultCustodyAutoUpdateFailed =>
      'پن خودکار طور پر اپ ڈیٹ نہیں ہو سکا۔';

  @override
  String vaultCustodyReencrypting(int done, int total) {
    return '$total میں سے $done کو دوبارہ انکرپٹ کیا جا رہا ہے… ایپ کھلی رکھیں۔';
  }

  @override
  String get vaultCustodyPreparing => 'تیاری ہو رہی ہے… ایپ کھلی رکھیں۔';

  @override
  String get vaultSettingsTitle => 'والٹ';

  @override
  String get vaultSettingsAboutTitle => 'والٹ کے بارے میں';

  @override
  String get vaultSettingsAboutDesc =>
      'آپ کی چیٹ ہسٹری کا نجی بیک اپ۔ صرف آپ کا پن اسے کھول سکتا ہے — ہم بھی نہیں۔';

  @override
  String get vaultSettingsBulletMessages => 'آپ کے پیغامات';

  @override
  String get vaultSettingsBulletStatuses => 'وہ اسٹیٹس جو آپ دیکھ سکتے ہیں';

  @override
  String get vaultSettingsNeverKept =>
      'یہاں کبھی نہیں رکھا جاتا: کال ہسٹری، رابطے یا دوسروں کے نجی پیغامات۔';

  @override
  String get vaultSettingsSectionPrivacy => 'رازداری';

  @override
  String get vaultSettingsAutoDelete => 'پرانے پیغامات خودکار حذف کریں';

  @override
  String get vaultSettingsKeepForever => 'ہمیشہ رکھیں';

  @override
  String vaultSettingsDeleteAfter(String label) {
    return '$label کے بعد حذف کریں';
  }

  @override
  String get vaultSettingsSectionPin => 'پن';

  @override
  String get vaultSettingsChangePin => 'پن تبدیل کریں';

  @override
  String get vaultSettingsChangePinSubtitle =>
      'والٹ کے ہر پیغام کو دوبارہ انکرپٹ کرتا ہے';

  @override
  String get vaultSettingsBioTitle => 'فنگر پرنٹ سے ان لاک';

  @override
  String get vaultSettingsBioSubOn => 'اس ڈیوائس پر فعال ہے';

  @override
  String get vaultSettingsBioSubOff => 'پن ٹائپ کرنے سے بچیں';

  @override
  String get vaultSettingsSectionDanger => 'خطرناک زون';

  @override
  String get vaultSettingsDeleteData => 'والٹ کا ڈیٹا حذف کریں';

  @override
  String get vaultSettingsDeleteDataSubtitle =>
      'تاریخ حذف کرتا ہے، پن برقرار رکھتا ہے';

  @override
  String get vaultSettingsResetVault => 'والٹ ری سیٹ کریں';

  @override
  String get vaultSettingsResetVaultSubtitle => 'پن بھول کر سب کچھ مٹا دیتا ہے';

  @override
  String get vaultSettingsPinChanged => 'پن تبدیل کر دیا گیا۔';

  @override
  String get vaultSettingsBioTurnedOff => 'فنگر پرنٹ ان لاک بند کر دیا گیا۔';

  @override
  String get vaultSettingsBioTurnedOn => 'فنگر پرنٹ ان لاک فعال کر دیا گیا۔';

  @override
  String get vaultSettingsClearDataTitle => 'والٹ ڈیٹا حذف کریں؟';

  @override
  String get vaultSettingsClearDataDesc =>
      'کلاؤڈ والٹ سے تمام انکرپٹڈ پیغامات حذف کرتا ہے۔ پن وہی رہے گا۔';

  @override
  String get vaultSettingsClearDataCancel => 'منسوخ';

  @override
  String get vaultSettingsClearDataConfirm => 'ڈیٹا حذف کریں';

  @override
  String get vaultSettingsDataDeleted => 'والٹ ڈیٹا حذف کر دیا گیا۔';

  @override
  String get vaultSettingsResetTitle => 'والٹ ری سیٹ کریں؟';

  @override
  String get vaultSettingsResetDesc =>
      'سب کچھ مٹا دیتا ہے۔ آپ کو نیا پن سیٹ کرنا ہوگا۔';

  @override
  String get vaultSettingsResetConfirm => 'ری سیٹ کریں';

  @override
  String get vaultSettingsChangeDialogDesc =>
      'تمام پیغامات نئے پن سے انکرپٹ ہوں گے۔ ایپ کھلی رکھیں۔';

  @override
  String get vaultSettingsCurrentPin => 'موجودہ پن';

  @override
  String get vaultSettingsNewPin => 'نیا پن';

  @override
  String get vaultSettingsConfirmNewPin => 'نئے پن کی تصدیق کریں';

  @override
  String get vaultSettingsEnterCurrentPin => 'موجودہ پن درج کریں۔';

  @override
  String get vaultSettingsNewPinMinLength => 'کم از کم 6 حروف ہونے چاہئیں۔';

  @override
  String get vaultSettingsNewPinMismatch => 'نئے پن مماثل نہیں ہیں۔';

  @override
  String get vaultSettingsCurrentPinIncorrect => 'موجودہ پن غلط ہے۔';

  @override
  String vaultSettingsReencryptingCount(int done, int total) {
    return '$total میں سے $done دوبارہ انکرپٹ ہو رہے ہیں…';
  }

  @override
  String get vaultSettingsChangeBtn => 'تبدیل کریں';

  @override
  String get vaultSettingsBioPinDialogTitle => 'اپنا پن درج کریں';

  @override
  String get vaultSettingsBioPinDialogDesc =>
      'فنگر پرنٹ کے لیے آپ کا موجودہ پن درکار ہے۔';

  @override
  String get vaultSettingsContinueBtn => 'جاری رکھیں';

  @override
  String get premiumTitle => 'GupShupGo پرو';

  @override
  String get premiumSubtitleMember => 'آپ پرو ممبر ہیں! 🎉';

  @override
  String get premiumSubtitleUnlock => 'مکمل تجربہ ان لاک کریں';

  @override
  String premiumActiveDaysRemaining(int days) {
    return '$days دن باقی ہیں';
  }

  @override
  String get premiumFeaturesHeader => 'پرو کے ساتھ آپ کو کیا ملتا ہے';

  @override
  String get premiumPlansHeader => 'اپنا پلان منتخب کریں';

  @override
  String get premiumSubscribeBtn => 'ابھی سبسکرائب کریں';

  @override
  String get premiumCancelAnytime =>
      'Google Play سے کسی بھی وقت منسوخ کیا جا سکتا ہے۔';

  @override
  String get premiumRestoreBtn => 'پچھلی خریداری بحال کریں';

  @override
  String get premiumRestoring => 'بحال ہو رہا ہے…';

  @override
  String get premiumRestoredSuccess => 'پرو سبسکرپشن بحال ہو گئی! 🎉';

  @override
  String get premiumNoActiveSub => 'کوئی فعال سبسکرپشن نہیں ملی۔';

  @override
  String get premiumProductUnavailable => 'پروڈکٹ دستیاب نہیں ہے۔';

  @override
  String get premiumFeatureMediaTitle => 'میڈیا لمحات';

  @override
  String get premiumFeatureMediaDesc =>
      'تصاویر اور ویڈیوز اسٹیٹس کے طور پر شیئر کریں';

  @override
  String get premiumFeatureMediaFree => 'صرف ٹیکسٹ';

  @override
  String get premiumFeatureMediaPro => 'تصاویر + ویڈیوز';

  @override
  String get premiumFeatureScreenShareTitle => 'اسکرین شیئرنگ';

  @override
  String get premiumFeatureScreenShareDesc =>
      'چیٹ کے دوران اپنی اسکرین لائیو شیئر کریں';

  @override
  String get premiumFeatureScreenShareFree => 'مقفل ہے';

  @override
  String get premiumFeatureScreenSharePro => 'مکمل رسائی';

  @override
  String get premiumFeatureThemesTitle => 'چیٹ تھیمز';

  @override
  String get premiumFeatureThemesDesc => 'منفرد پس منظر اور رنگ برنگے ببلز';

  @override
  String get premiumFeatureThemesFree => '6 تھیمز';

  @override
  String get premiumFeatureThemesPro => 'تمام 12 + آپ کی اپنی تصویر';

  @override
  String get premiumFeatureVoiceTitle => 'طویل وائس پیغامات';

  @override
  String get premiumFeatureVoiceDesc => 'لمبے وائس نوٹس ریکارڈ کریں';

  @override
  String get premiumFeatureVoiceFree => '2 منٹ';

  @override
  String get premiumFeatureVoicePro => 'لامحدود';

  @override
  String get premiumFeatureQualityTitle => 'اعلیٰ معیار کا میڈیا';

  @override
  String get premiumFeatureQualityDesc =>
      'بہترین تصاویر اور 90 سیکنڈ کی ویڈیوز';

  @override
  String get premiumFeatureQualityFree => 'معیاری کوالٹی';

  @override
  String get premiumFeatureQualityPro => 'ہائی کوالٹی + 90s ویڈیوز';

  @override
  String get premiumFeatureBondTitle => 'بانڈ بحالی';

  @override
  String get premiumFeatureBondDesc => 'ٹوٹے ہوئے بانڈز مفت بحال کریں';

  @override
  String get premiumFeatureBondFree => 'پوائنٹس یا اشتہار';

  @override
  String get premiumFeatureBondPro => 'ہفتے میں 1 مفت بحالی';

  @override
  String get premiumFeatureBadgeTitle => 'پرو بیج';

  @override
  String get premiumFeatureBadgeDesc => 'اپنا پرو اسٹیٹس دکھائیں';

  @override
  String get premiumFeatureBadgeFree => 'کوئی بیج نہیں';

  @override
  String get premiumFeatureBadgePro => 'خصوصی پرو بیج';

  @override
  String get premiumFeatureExportTitle => 'چیٹ ایکسپورٹ';

  @override
  String get premiumFeatureExportDesc =>
      'چیٹ کو پی ڈی ایف یا ٹیکسٹ میں محفوظ کریں';

  @override
  String get premiumFeatureExportFree => 'دستیاب نہیں';

  @override
  String get premiumFeatureExportPro => 'PDF اور TXT ایکسپورٹ';

  @override
  String get premiumFeatureAdFreeTitle => 'اشتہارات سے پاک تجربہ';

  @override
  String get premiumFeatureAdFreeDesc => 'ایپ میں کہیں بھی بینر اشتہارات نہیں';

  @override
  String get premiumFeatureAdFreeFree => 'بینر اشتہارات موجود ہیں';

  @override
  String get premiumFeatureAdFreePro => 'کوئی بینر نہیں';

  @override
  String get premiumPlanMonthly => 'ماہانہ';

  @override
  String get premiumPlanYearly => 'سالانہ';

  @override
  String get premiumPlanSavings => '~33% بچت';

  @override
  String get premiumPeriodMonth => '/ماہ';

  @override
  String get premiumPeriodYear => '/سال';

  @override
  String get nearbyOfflineChatTitle => 'آف لائن چیٹ';

  @override
  String get nearbySearchingDevices => 'قریبی ڈیوائسز تلاش کی جا رہی ہیں…';

  @override
  String get nearbyTooltipStop => 'آف لائن چیٹ بند کریں';

  @override
  String get nearbyTooltipStart => 'آف لائن چیٹ شروع کریں';

  @override
  String get nearbyDevicesSection => 'قریبی ڈیوائسز';

  @override
  String get nearbyDiscoveryOn => 'تلاش آن';

  @override
  String get nearbyDiscoveryOff => 'تلاش آف';

  @override
  String get nearbyHeroTitle => 'آف لائن موڈ';

  @override
  String nearbyHeroNearbyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count قریب ہیں',
      one: '1 قریب ہے',
    );
    return '$_temp0';
  }

  @override
  String get nearbyHeroOff => 'آف لائن چیٹ بند ہے';

  @override
  String get nearbyHeroDesc =>
      '100 میٹر کے اندر ڈیوائسز اسکین ہو رہی ہیں۔ انٹرنیٹ کے بغیر براہ راست چیٹ۔';

  @override
  String get nearbyYourNameHint => 'آپ کا نام';

  @override
  String get nearbyEmptySearching => 'قریبی ڈیوائسز تلاش کی جا رہی ہیں…';

  @override
  String get nearbyEmptyOff => 'آف لائن چیٹ بند ہے';

  @override
  String get nearbyEmptySearchingDesc =>
      'بلوٹوتھ آن رکھ کر دوسری ڈیوائسز پر GupShupGo کھولیں۔';

  @override
  String get nearbyEmptyOffDesc =>
      'اسکین شروع کرنے کے لیے اوپر اسٹارٹ آئیکن دبائیں۔';

  @override
  String get nearbyPeerConnected => 'منسلک ہے · چیٹ کے لیے دبائیں';

  @override
  String get nearbyPeerConnecting => 'کنیکٹ ہو رہا ہے…';

  @override
  String get nearbyPeerTapToConnect => 'کنیکٹ کرنے کے لیے دبائیں';

  @override
  String get nearbyActionChat => 'چیٹ';

  @override
  String get nearbyActionConnecting => 'کنیکٹ ہو رہا ہے';

  @override
  String get nearbyActionConnect => 'کنیکٹ کریں';

  @override
  String get nearbyPermNeededTitle => 'اجازت درکار ہے';

  @override
  String get nearbyPermNeededDesc =>
      'انٹرنیٹ کے بغیر تلاش کے لیے بلوٹوتھ کی اجازت درکار ہے۔';

  @override
  String get nearbyTryAgainBtn => 'دوبارہ کوشش کریں';

  @override
  String get nearbySettingsBtn => 'سیٹنگز';

  @override
  String get nearbyHelpTip =>
      'دوست نظر نہیں آ رہے؟ دونوں ڈیوائسز پر بلوٹوتھ چیک کریں۔';

  @override
  String get anonLobbyTitle => 'گمنام چیٹ';

  @override
  String get anonLobbyFinding => 'کسی کی تلاش کی جا رہی ہے…';

  @override
  String get anonLobbyHangTight =>
      'تھوڑا انتظار کریں — آپ کو کسی اجنبی کے ساتھ جوڑا جا رہا ہے۔';

  @override
  String get anonLobbyCancelBtn => 'تلاش منسوخ کریں';

  @override
  String get anonLobbyPrivacyNote => 'آپ کی شناخت خفیہ رہتی ہے۔';

  @override
  String get anonLobbyConnecting => 'کنیکٹ ہو رہا ہے…';

  @override
  String get anonLobbyWaitingOthers => 'دوسروں کے آن لائن آنے کا انتظار ہے…';

  @override
  String anonLobbyOnlineCount(int count) {
    return '$count ابھی آن لائن ہیں';
  }

  @override
  String get anonChatNotEncrypted => 'پیغامات اینڈ ٹو اینڈ انکرپٹڈ نہیں ہیں';

  @override
  String get anonChatRequestSentTooltip => 'درخواست بھیج دی گئی';

  @override
  String get anonChatAddFriendTooltip => 'دوست بنائیں';

  @override
  String get anonChatNextStrangerTooltip => 'اگلا اجنبی';

  @override
  String get anonChatReportTooltip => 'رپورٹ کریں';

  @override
  String get anonChatSayHi => 'اجنبی کو ہیلو کہیں! 👋';

  @override
  String get anonChatFriendsTransition =>
      'اب آپ دوست ہیں! محفوظ چیٹ کھل رہی ہے…';

  @override
  String get anonChatStrangerDisconnected => 'اجنبی منقطع ہو گیا 👋';

  @override
  String get anonChatFindNextBtn => 'اگلا اجنبی تلاش کریں';

  @override
  String get anonChatFriendReqTitle => 'اجنبی رابطہ کرنا چاہتا ہے!';

  @override
  String get anonChatFriendReqDesc =>
      'قبول کرنے پر آپ کا اصلی پروفائل ظاہر ہوگا اور انکرپٹڈ چیٹ شروع ہوگی۔';

  @override
  String get anonChatDecline => 'مسترد کریں';

  @override
  String get anonChatAccept => 'قبول کریں';

  @override
  String get anonChatWaitingReqTitle => 'دوستی کی درخواست بھیج دی گئی';

  @override
  String get anonChatWaitingReqDesc => 'جواب کا انتظار ہے…';

  @override
  String get anonChatReportTitle => 'رپورٹ کریں';

  @override
  String get anonChatReportQuestion => 'آپ کیوں رپورٹ کر رہے ہیں؟';

  @override
  String get anonChatReportReasonInappropriate => 'نامناسب مواد';

  @override
  String get anonChatReportReasonHarassment => 'ہراساں کرنا';

  @override
  String get anonChatReportReasonSpam => 'اسپام یا دھوکہ';

  @override
  String get anonChatReportReasonThreatening => 'دھمکی آمیز رویہ';

  @override
  String get anonChatReportReasonOther => 'دیگر';

  @override
  String get anonChatReportCancel => 'منسوخ';

  @override
  String get anonChatReportSubmit => 'رپورٹ کر کے چھوڑیں';

  @override
  String get anonChatReportSubmitted => 'رپورٹ جمع کر دی گئی۔';

  @override
  String get anonChatViewOnceVideoTitle => 'ایک بار چلائیں؟';

  @override
  String get anonChatViewOncePhotoTitle => 'ایک بار کھولیں؟';

  @override
  String get anonChatViewOnceVideoDesc =>
      'یہ ویڈیو صرف ایک بار دیکھی جا سکتی ہے۔';

  @override
  String get anonChatViewOncePhotoDesc =>
      'یہ تصویر صرف ایک بار دیکھی جا سکتی ہے۔';

  @override
  String get anonChatViewOnceCancel => 'منسوخ';

  @override
  String get anonChatViewOnceOpen => 'کھولیں';

  @override
  String get unsupportedVersionTitle => 'GupShupGo اپ ڈیٹ کریں';

  @override
  String get unsupportedVersionDesc =>
      'یہ ورژن اب سپورٹڈ نہیں ہے۔ چیٹنگ جاری رکھنے کے لیے اپ ڈیٹ کریں۔';

  @override
  String get unsupportedVersionUpdateNow => 'ابھی اپ ڈیٹ کریں';

  @override
  String get unsupportedVersionOpenPlayStore => 'Play Store کھولیں';

  @override
  String publicProfileNotFound(String username) {
    return '@$username نہیں ملا';
  }

  @override
  String get publicProfileUserNotFound => 'صارف نہیں ملا';

  @override
  String get publicProfileNotFoundDesc =>
      'یہ ہینڈل موجود نہیں ہے یا لنک خراب ہے۔';

  @override
  String get publicProfileTitle => 'پروفائل';

  @override
  String get publicProfileOnline => 'آن لائن';

  @override
  String publicProfileLastSeen(String time) {
    return 'آخری بار دیکھا گیا $time';
  }

  @override
  String get publicProfileJustNow => 'ابھی ابھی';

  @override
  String publicProfileMinutesAgo(int minutes) {
    return '$minutes منٹ پہلے';
  }

  @override
  String publicProfileHoursAgo(int hours) {
    return '$hours گھنٹے پہلے';
  }

  @override
  String publicProfileDaysAgo(int days) {
    return '$days دن پہلے';
  }

  @override
  String publicProfileJoined(String date) {
    return '$date کو شامل ہوئے';
  }

  @override
  String get publicProfileOwnLink => 'یہ آپ کا اپنا پروفائل لنک ہے۔';

  @override
  String publicProfileGupPoints(int points) {
    return '$points گپ پوائنٹس';
  }

  @override
  String publicProfileLevel(int level) {
    return 'لیول $level';
  }

  @override
  String get publicProfileStatPoints => 'پوائنٹس';

  @override
  String get publicProfileStatBadges => 'بیجز';

  @override
  String get publicProfileStatBestBond => 'بہترین بانڈ';

  @override
  String get publicProfileBadges => 'بیجز';

  @override
  String get qrScannerTitle => 'کیو آر کوڈ اسکین کریں';

  @override
  String get qrScannerFlashOnTooltip => 'فلیش آن';

  @override
  String get qrScannerFlashOffTooltip => 'فلیش آف';

  @override
  String get qrScannerPrompt => 'کیمرے کو کیو آر کوڈ کے سامنے رکھیں';

  @override
  String get qrScannerNotProfileCode => 'یہ GupShupGo پروفائل کوڈ نہیں ہے۔';

  @override
  String get qrScannerCameraErrorTitle => 'کیمرہ شروع نہیں ہو سکا۔';

  @override
  String get qrScannerCameraErrorRetry => 'دوبارہ کوشش کریں۔';

  @override
  String get qrScannerPermissionMsg =>
      'اسکیننگ کے لیے کیمرے کی اجازت درکار ہے۔';

  @override
  String get qrScannerPermissionAllow => 'کیمرے کی اجازت دیں';

  @override
  String get qrScannerBlockedMsg => 'کیمرہ بلاک ہے۔ سیٹنگز میں آن کریں۔';

  @override
  String get qrScannerBlockedSettings => 'سیٹنگز کھولیں';

  @override
  String get screenShareIncomingTitle => 'اسکرین شیئر کی کال';

  @override
  String get screenShareWantsToShare => 'اسکرین شیئر کرنا چاہتے ہیں';

  @override
  String get screenShareReject => 'مسترد';

  @override
  String get screenShareAccept => 'قبول کریں';

  @override
  String get screenShareCantAccept => 'قبول کرنا ممکن نہیں ہو سکا۔';

  @override
  String screenShareDeclined(String name) {
    return '$name نے مسترد کر دیا';
  }

  @override
  String get screenShareNoAnswer => 'کوئی جواب نہیں';

  @override
  String get screenShareStartError => 'شروع نہیں ہو سکا';

  @override
  String get screenShareStatusRequesting => 'اجازت مانگی جا رہی ہے';

  @override
  String get screenShareStatusInitializing => 'شروع ہو رہا ہے';

  @override
  String get screenShareStatusWaitingParticipant => 'انتظار ہو رہا ہے';

  @override
  String get screenShareStatusActive => 'اسکرین شیئرنگ لائیو ہے';

  @override
  String screenShareSubWaitingAccept(String name) {
    return '$name کے قبول کرنے کا انتظار ہے…';
  }

  @override
  String get screenShareSubEstablishing => 'کنکشن قائم ہو رہا ہے...';

  @override
  String screenShareSubWaitingJoin(String name) {
    return '$name کے شامل ہونے کا انتظار ہے...';
  }

  @override
  String get screenShareSubActive => 'آپ کی اسکرین نظر آ رہی ہے۔';

  @override
  String get screenShareBadgeRequesting => 'درخواست جاری';

  @override
  String get screenShareBadgeConnecting => 'کنیکٹ ہو رہا ہے';

  @override
  String get screenShareSharedWith => 'ان کے ساتھ شیئرڈ: ';

  @override
  String get screenShareRequestingFrom => 'درخواست کنندہ: ';

  @override
  String get screenShareMinimizeTip =>
      'اسے چھوٹا کر کے ایپ استعمال کر سکتے ہیں۔';

  @override
  String get screenShareStop => 'شیئرنگ روکیں';

  @override
  String get screenShareCancelRequest => 'درخواست منسوخ';

  @override
  String screenShareViewerTitle(String name) {
    return '$name شیئر کر رہے ہیں';
  }

  @override
  String get screenShareViewerLive => 'لائیو اسٹریم';

  @override
  String get screenShareViewerMinimize => 'چھوٹا کریں';

  @override
  String get screenShareViewerLeave => 'چھوڑیں';

  @override
  String screenShareViewerWaitingStream(String name) {
    return 'اسٹریم کا انتظار ہے…';
  }

  @override
  String get screenShareViewerConnecting => 'اسٹریم سے کنیکٹ ہو رہا ہے...';

  @override
  String get viewOnceVideoTitle => 'ویڈیو · ایک بار دیکھیں';

  @override
  String get viewOncePhotoTitle => 'تصویر · ایک بار دیکھیں';

  @override
  String get viewOnceCantOpen => 'کھولنا ممکن نہیں ہو سکا۔';

  @override
  String get viewOnceUnavailable => 'اب دستیاب نہیں ہے۔';

  @override
  String get viewOnceBlockedFooter => 'اسکرین شاٹس بلاک ہیں۔';

  @override
  String get anonRestoreBanner => 'گمنام چیٹ بینر دکھائیں';

  @override
  String get contactsInviteFriends => 'دوستوں کو GupShupGo پر مدعو کریں';

  @override
  String get inviteImageShareFailed =>
      'تصویر شیئر نہیں ہو سکی۔ دوبارہ کوشش کریں یا لنک شیئر کریں۔';

  @override
  String get viewOnceUnblockedFooter => 'اسے دوبارہ نہیں کھولا جا سکتا۔';

  @override
  String get tabMessages => 'پیغامات';
}
