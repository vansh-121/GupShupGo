// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonOk => 'موافق';

  @override
  String get commonContinue => 'متابعة';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonGotIt => 'فهمت';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsLanguageTitle => 'اللغة';

  @override
  String get settingsLanguageSubtitle => 'اختر لغتك المفضلة';

  @override
  String get languagePickerTitle => 'اللغة';

  @override
  String get languageSystemDefault => 'افتراضي النظام';

  @override
  String get languageSystemDefaultSubtitle => 'حسب لغة الجهاز';

  @override
  String get loginContinueWithPhone => 'المتابعة باستخدام الهاتف';

  @override
  String get loginContinueWithGoogle => 'المتابعة باستخدام Google';

  @override
  String get loginUseEmailPassword => 'استخدام البريد الإلكتروني وكلمة المرور';

  @override
  String get loginSignIn => 'تسجيل الدخول';

  @override
  String get loginSignUp => 'إنشاء حساب';

  @override
  String get loginCreateAccount => 'إنشاء حساب';

  @override
  String get loginForgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get loginOfflineChat => 'دردشة بلا إنترنت';

  @override
  String get loginHintName => 'اسمك';

  @override
  String get loginHintEmail => 'البريد الإلكتروني';

  @override
  String get loginHintPassword => 'كلمة المرور';

  @override
  String get loginPasswordHelper => '8 أحرف على الأقل، تتضمن حرفًا ورقمًا';

  @override
  String loginResetEmailSent(String email) {
    return 'تم إرسال بريد إعادة تعيين كلمة المرور إلى $email';
  }

  @override
  String get loginErrorEnterEmail => 'يرجى إدخال بريدك الإلكتروني';

  @override
  String get loginErrorValidEmail => 'يرجى إدخال بريد إلكتروني صالح';

  @override
  String get loginErrorEnterPassword => 'يرجى إدخال كلمة المرور';

  @override
  String get loginErrorPasswordMin6 => 'يجب ألا تقل كلمة المرور عن 6 أحرف';

  @override
  String get loginErrorEnterPasswordSignup => 'يرجى إدخال كلمة مرور';

  @override
  String get loginErrorPasswordMin8 => 'يجب ألا تقل كلمة المرور عن 8 أحرف';

  @override
  String get loginErrorPasswordLetter =>
      'يجب أن تحتوي كلمة المرور على حرف واحد على الأقل';

  @override
  String get loginErrorPasswordNumber =>
      'يجب أن تحتوي كلمة المرور على رقم واحد على الأقل';

  @override
  String get loginErrorEnterName => 'يرجى إدخال اسمك';

  @override
  String get loginErrorGoogleCancelled =>
      'تم إلغاء تسجيل الدخول باستخدام Google.';

  @override
  String get loginErrorProfileLoad =>
      'تعذر تحميل ملفك الشخصي. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get loginErrorGoogleFailed =>
      'فشل تسجيل الدخول باستخدام Google. يرجى المحاولة مرة أخرى.';

  @override
  String get loginErrorSignInFailed =>
      'فشل تسجيل الدخول. يرجى المحاولة مرة أخرى.';

  @override
  String get loginErrorSignUpFailed =>
      'فشل إنشاء الحساب. يرجى المحاولة مرة أخرى.';

  @override
  String get loginErrorGeneric => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get loginErrorResetFailed =>
      'فشل إرسال بريد إعادة التعيين. يرجى المحاولة مرة أخرى.';

  @override
  String get loginErrorUserNotFound =>
      'لا يوجد حساب بهذا البريد الإلكتروني. يرجى إنشاء حساب جديد.';

  @override
  String get loginErrorWrongPassword =>
      'كلمة المرور غير صحيحة. يرجى المحاولة مرة أخرى.';

  @override
  String get loginErrorEmailInUse =>
      'يوجد حساب بالفعل بهذا البريد الإلكتروني. يرجى تسجيل الدخول.';

  @override
  String get loginErrorInvalidEmail => 'يرجى إدخال عنوان بريد إلكتروني صالح.';

  @override
  String get loginErrorWeakPassword =>
      'كلمة المرور ضعيفة جدًا. استخدم 6 أحرف على الأقل.';

  @override
  String get loginErrorInvalidCredential =>
      'البريد الإلكتروني أو كلمة المرور غير صالحة. يرجى التحقق والمحاولة مرة أخرى.';

  @override
  String get loginErrorTooManyRequests =>
      'محاولات كثيرة جدًا. يرجى المحاولة مرة أخرى لاحقًا.';

  @override
  String get homeNavChats => 'الرسائل';

  @override
  String get homeNavMoments => 'لحظات';

  @override
  String get homeNavCalls => 'المكالمات';

  @override
  String get homeNavProfile => 'الملف الشخصي';

  @override
  String get homeTooltipOfflineChat =>
      'دردشة بلا إنترنت — تحدث مع القريبين منك';

  @override
  String get homeTooltipSearch => 'بحث';

  @override
  String get homeMenuProfile => 'الملف الشخصي';

  @override
  String get homeMenuSettings => 'الإعدادات';

  @override
  String get homeMenuRateUs => 'قيّمنا';

  @override
  String get homeMenuReportIssue => 'إبلاغ عن مشكلة';

  @override
  String get homeMenuWhatsNew => 'ما الجديد';

  @override
  String get homeMenuLogOut => 'تسجيل الخروج';

  @override
  String get homeEmptyChatsTitle => 'لا توجد دردشات بعد';

  @override
  String get homeEmptyChatsSubtitle => 'ابدأ محادثة بالضغط على الزر أدناه';

  @override
  String get homeNewChatButton => 'دردشة جديدة';

  @override
  String get homeAiAssistantTitle => 'GupAI';

  @override
  String get homeAiAssistantSubtitle => 'صياغة، ترجمة، تلخيص والمزيد';

  @override
  String get homeStrangerMatchTitle => 'تواصل مع شخص مجهول';

  @override
  String get homeStrangerMatchSubtitle => 'دردشة مجهولة — اضغط للمطابقة!';

  @override
  String get homeMyMoment => 'لحظتي';

  @override
  String get homeRecentMoments => 'لحظات حديثة';

  @override
  String get homeEmptyMomentsTitle => 'لا توجد تحديثات بعد.';

  @override
  String get homeEmptyMomentsSubtitle => 'اضغط على الكاميرا للمشاركة.';

  @override
  String get homeTapToAddMoment => 'اضغط لإضافة تحديث';

  @override
  String get homeEmptyCallsTitle => 'لا يوجد سجل مكالمات';

  @override
  String get homeEmptyCallsSubtitle => 'ستظهر مكالماتك الأخيرة هنا';

  @override
  String get chatInputHint => 'رسالة...';

  @override
  String get chatSearchHint => 'بحث في الرسائل...';

  @override
  String get chatStatusTyping => 'يكتب الآن...';

  @override
  String get chatStatusOnline => 'متصل';

  @override
  String get chatStatusOffline => 'غير متصل';

  @override
  String chatStatusLastSeen(String time) {
    return 'آخر ظهور $time';
  }

  @override
  String get chatEndToEndEncrypted => 'مشفر من طرف إلى طرف';

  @override
  String get chatNoInternetOfflineTitle =>
      'لا يوجد إنترنت؟ تحدث بلا إنترنت مع الأجهزة القريبة';

  @override
  String get chatEnableOfflineButton => 'تفعيل';

  @override
  String get chatSlideToCancel => 'اسحب للإلغاء';

  @override
  String get chatTooltipVoiceCall => 'مكالمة صوتية';

  @override
  String get chatTooltipVideoCall => 'مكالمة فيديو';

  @override
  String get chatMenuContactInfo => 'معلومات جهة الاتصال';

  @override
  String get chatMenuSearch => 'بحث';

  @override
  String get chatMenuChatTheme => 'مظهر الدردشة';

  @override
  String get chatMenuExportChat => 'تصدير الدردشة';

  @override
  String get chatMenuMuteNotifications => 'كتم الإشعارات';

  @override
  String get chatMenuUnmuteNotifications => 'إلغاء كتم الإشعارات';

  @override
  String get chatMenuBlockContact => 'حظر جهة الاتصال';

  @override
  String get chatActionReply => 'رد';

  @override
  String get chatActionCopy => 'نسخ';

  @override
  String get chatActionForward => 'إعادة توجيه';

  @override
  String get chatActionTranslate => 'ترجمة';

  @override
  String get chatActionSummarise => 'تلخيص';

  @override
  String get chatActionAskGupAi => 'اسأل GupAI';

  @override
  String get chatActionEdit => 'تعديل';

  @override
  String get chatActionDelete => 'حذف';

  @override
  String get chatDeleteMessageTitle => 'حذف الرسالة؟';

  @override
  String get chatDeleteMessageForEveryonePrompt =>
      'هل تريد حذفها لنفسك فقط أم للجميع في هذه الدردشة؟';

  @override
  String chatDeleteMessageForMeOnlyPrompt(String name) {
    return 'سيؤدي هذا إلى إزالتها من أجهزتك فقط. سيظل $name يراها.';
  }

  @override
  String get chatDeleteForMe => 'حذف لدي';

  @override
  String get chatDeleteForEveryone => 'حذف لدى الجميع';

  @override
  String chatBlockContactTitle(String name) {
    return 'حظر $name؟';
  }

  @override
  String get chatBlockContactPrompt =>
      'لا يمكن لجهات الاتصال المحظورة مراسلتك أو الاتصال بك. يمكنك إلغاء الحظر من الإعدادات ← الخصوصية.';

  @override
  String get chatBlockButton => 'حظر';

  @override
  String get chatForwardTo => 'إعادة توجيه إلى';

  @override
  String get chatNoForwardChats => 'لا توجد دردشات أخرى لإعادة التوجيه إليها';

  @override
  String get chatCannotSendMediaBlocked =>
      'لا يمكن إرسال الوسائط إلى جهة الاتصال هذه';

  @override
  String get attachmentShareTitle => 'مشاركة';

  @override
  String get attachmentPhoto => 'صورة';

  @override
  String get attachmentPhotoSubtitle => 'اختر صورة من المعرض';

  @override
  String get attachmentVideo => 'فيديو';

  @override
  String get attachmentVideoSubtitle => 'اختر فيديو من المعرض';

  @override
  String get attachmentDocument => 'مستند';

  @override
  String get attachmentDocumentSubtitle =>
      'PDF، ملف أوفيس، أرشيف — يُرسل كما هو';

  @override
  String get attachmentLocation => 'الموقع';

  @override
  String get attachmentLocationSubtitle => 'شارك موقعك الحالي';

  @override
  String get attachmentScreenShare => 'مشاركة الشاشة';

  @override
  String get attachmentScreenShareSubtitle => 'اعرض شاشتك مباشرة أثناء الدردشة';

  @override
  String get attachmentViewOnce => 'عرض لمرة واحدة';

  @override
  String get attachmentViewOnceSubtitle => 'تختفي الصورة أو الفيديو بعد فتحها';

  @override
  String get contactsTitle => 'جهات الاتصال والاستكشاف';

  @override
  String get contactsTabFriends => 'الأصدقاء';

  @override
  String get contactsTabRequests => 'الطلبات';

  @override
  String get contactsTabDiscover => 'استكشاف';

  @override
  String get contactsScanQrTooltip => 'مسح رمز QR';

  @override
  String get contactsMyHandleTooltip => 'اسم المستخدم الخاص بي';

  @override
  String get contactsSetUsernamePrompt =>
      'قم بتعيين @username في ملفك الشخصي أولاً — هذا ما يشاركه رمز QR الخاص بك.';

  @override
  String get contactsMyQrCodeTitle => 'رمز QR لملفي الشخصي';

  @override
  String get contactsMyQrCodeSubtitle =>
      'يمكن للأصدقاء مسح هذا الرمز للاتصال بك فوراً';

  @override
  String get contactsCopyProfileLink => 'نسخ رابط الملف الشخصي';

  @override
  String contactsProfileLinkCopied(String username) {
    return 'تم نسخ رابط الملف الشخصي لـ @$username!';
  }

  @override
  String get contactsScanSomeonesCode => 'مسح رمز شخص آخر';

  @override
  String get contactsPermissionDenied => 'تم رفض إذن الوصول إلى جهات الاتصال.';

  @override
  String get contactsNoUsersFound =>
      'لم يتم العثور على مستخدمي GupShupGo في جهات اتصالك بعد.';

  @override
  String contactsFailedToSync(String error) {
    return 'فشلت مزامنة جهات الاتصال: $error';
  }

  @override
  String contactsMatchedCount(int count) {
    return '$count جهات اتصال على GupShupGo';
  }

  @override
  String get contactsFromDeviceContacts => 'من جهات اتصال جهازك';

  @override
  String get contactsLoadFriendsError => 'تعذر تحميل قائمة الأصدقاء.';

  @override
  String get contactsNoFriendsTitle => 'لم تتم إضافة أصدقاء بعد';

  @override
  String get contactsNoFriendsPrompt =>
      'استخدم تبويب استكشاف للبحث عن المستخدمين بواسطة @username أو الهاتف أو البريد وإرسال طلبات صداقة!';

  @override
  String get contactsDiscoverPeopleButton => 'استكشاف الأشخاص';

  @override
  String get contactsQuickConnectHeader => 'اتصال سريع';

  @override
  String get contactsNoSuggestions => 'لا توجد اقتراحات متاحة حالياً.';

  @override
  String get contactsLoadRequestsError => 'تعذر تحميل الطلبات.';

  @override
  String contactsPendingRequestsHeader(int count) {
    return 'الطلبات المعلقة ($count)';
  }

  @override
  String get contactsNoPendingRequestsTitle => 'لا توجد طلبات معلقة';

  @override
  String get contactsNoPendingRequestsSubtitle =>
      'عندما يرسل لك المستخدمون طلبات اتصال، ستظهر هنا.';

  @override
  String get contactsWantsToConnect => 'يريد الاتصال بك';

  @override
  String get contactsAcceptButton => 'قبول';

  @override
  String get contactsAcceptFailed => 'تعذر قبول الطلب. يرجى المحاولة مرة أخرى.';

  @override
  String contactsConnectedWith(String name) {
    return 'تم الاتصال بـ $name!';
  }

  @override
  String get contactsDeclineFailed => 'تعذر رفض الطلب. يرجى المحاولة مرة أخرى.';

  @override
  String get contactsYouMightKnowHeader => 'قد تعرفهم';

  @override
  String get contactsSeeAll => 'عرض الكل';

  @override
  String get contactsSearchHint =>
      'ابحث بالاسم أو @المعرف أو الهاتف أو البريد...';

  @override
  String get contactsTurnOnDiscoverability =>
      'فعّل إمكانية الاكتشاف لتظهر في البحث والاقتراحات.';

  @override
  String get contactsNoMatchingUsersTitle =>
      'لم يتم العثور على مستخدمين متطابقين';

  @override
  String get contactsNoMatchingUsersSubtitle =>
      'تحقق من @username أو رقم الهاتف أو البريد وحاول مرة أخرى.';

  @override
  String get contactsDiscoverHeroTitle => 'اكتشف أشخاصاً على GupShupGo';

  @override
  String get contactsDiscoverHeroSubtitle =>
      'وسّع دائرتك مع اتصالات عالية الدقة حول العالم.';

  @override
  String get contactsSyncDeviceContacts => 'مزامنة جهات اتصال الجهاز';

  @override
  String get contactsSyncingContacts => 'جارٍ مزامنة جهات الاتصال...';

  @override
  String get contactsSyncDeviceSubtitle =>
      'اعثر على أصدقائك فوراً من جهات اتصال الهاتف';

  @override
  String get contactsSuggestedUsersHeader => 'مستخدمون مقترحون';

  @override
  String get contactsAddFriendButton => 'إضافة صديق';

  @override
  String get contactsRequestedButton => 'تم الطلب';

  @override
  String contactsRequestSent(String name) {
    return 'تم إرسال طلب الصداقة إلى $name!';
  }

  @override
  String get contactsRequestFailed => 'طلب الصداقة معلق بالفعل أو فشل.';

  @override
  String get contactsRequestUnavailable => 'هذا الطلب لم يعد متاحاً.';

  @override
  String get profileEditTitle => 'تعديل الملف الشخصي';

  @override
  String get profileSaveButton => 'حفظ';

  @override
  String get profileTapToChangePhoto => 'اضغط لتغيير الصورة';

  @override
  String get profileUpgradeToPro => 'الترقية إلى برو';

  @override
  String get profileSectionName => 'اسمك';

  @override
  String get profileNameHint => 'أدخل اسمك';

  @override
  String get profileSectionHandle => 'اسم المستخدم الفريد';

  @override
  String get profileHandleNotSet => 'لم يتم التعيين بعد';

  @override
  String get profileChangeHandle => 'تغيير';

  @override
  String get profileSectionAbout => 'نبذة عني';

  @override
  String get profileAboutHint => 'ما الذي يدور في ذهنك؟';

  @override
  String get profileDefaultAbout => 'مرحباً! أنا أستخدم GupShupGo.';

  @override
  String get profileSectionPhone => 'الهاتف';

  @override
  String get profileSectionEmail => 'البريد الإلكتروني';

  @override
  String get profileSectionLinkedMethods => 'طرق تسجيل الدخول المرتبطة';

  @override
  String get profileNotLinked => 'غير مرتبط';

  @override
  String get profileNameEmpty => 'لا يمكن أن يكون الاسم فارغاً.';

  @override
  String get profileUpdatedSuccess => 'تم تحديث الملف الشخصي';

  @override
  String profileUploadPhotoFailed(String error) {
    return 'فشل تحميل الصورة: $error';
  }

  @override
  String profileSaveFailed(String error) {
    return 'فشل حفظ الملف الشخصي: $error';
  }

  @override
  String get profilePoints => 'نقاط';

  @override
  String get profileBadges => 'شارات';

  @override
  String get profileBestBond => 'أفضل سلسلة';

  @override
  String get settingsAccountCard => 'الحساب';

  @override
  String get settingsProfileTile => 'الملف الشخصي';

  @override
  String get settingsLinkedMethodsTile => 'طرق تسجيل الدخول المرتبطة';

  @override
  String get settingsPhoneTile => 'رقم الهاتف';

  @override
  String get settingsEmailTile => 'البريد الإلكتروني';

  @override
  String get settingsPrivacyCard => 'الخصوصية';

  @override
  String get settingsDiscoverability => 'قابلية الاكتشاف';

  @override
  String get settingsLastSeen => 'آخر ظهور';

  @override
  String get settingsReadReceipts => 'مؤشرات قراءة الرسائل';

  @override
  String get settingsAdPreferences => 'تفضيلات الإعلانات';

  @override
  String get settingsManage => 'إدارة';

  @override
  String get settingsAppearanceCard => 'المظهر';

  @override
  String get settingsTheme => 'السمة';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get settingsThemeDark => 'داكن';

  @override
  String get settingsThemeSystem => 'النظام';

  @override
  String get settingsChatTheme => 'سمة الدردشة';

  @override
  String get settingsHelpSecurityCard => 'المساعدة والأمان';

  @override
  String get settingsHelpCenter => 'مركز المساعدة';

  @override
  String get settingsReportProblem => 'الإبلاغ عن مشكلة';

  @override
  String get settingsE2EEShield => 'التشفير التام (الخزنة)';

  @override
  String get settingsVerifySafetyNumber => 'التحقق من رقم الأمان';

  @override
  String get settingsBlockedContacts => 'جهات الاتصال المحظورة';

  @override
  String get settingsClearAllGupHistory => 'مسح سجل الدردشات بالكامل';

  @override
  String get settingsRateUs => 'قيمنا';

  @override
  String get settingsWhatsNew => 'ما الجديد';

  @override
  String get settingsCheckForUpdates => 'التحقق من التحديثات';

  @override
  String get settingsAppInfo => 'معلومات التطبيق';

  @override
  String get settingsLogOut => 'تسجيل الخروج';

  @override
  String get settingsLogOutConfirmTitle => 'تسجيل الخروج';

  @override
  String get settingsLogOutConfirmPrompt =>
      'هل أنت متأكد أنك تريد تسجيل الخروج من GupShupGo؟';

  @override
  String get settingsSigningOut => 'جارٍ تسجيل الخروج…';

  @override
  String get settingsClearChatsConfirmTitle => 'مسح جميع الدردشات';

  @override
  String get settingsClearChatsConfirmPrompt =>
      'سيؤدي هذا إلى حذف سجل رسائلك نهائياً. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get settingsDeleteAll => 'حذف الكل';

  @override
  String get settingsClearingChats => 'جارٍ مسح الدردشات...';

  @override
  String get settingsAllChatsCleared => 'تم مسح جميع الدردشات';

  @override
  String settingsClearChatsFailed(String error) {
    return 'فشل مسح الدردشات: $error';
  }

  @override
  String get settingsChooseThemeTitle => 'اختر السمة';

  @override
  String get settingsUnlockPremiumFeatures => 'افتح الميزات الاحترافية';

  @override
  String settingsProDaysLeft(String planLabel, int daysRemaining) {
    return '$planLabel · متبقي $daysRemaining يوم';
  }

  @override
  String get settingsCheckingForUpdates => 'جارٍ التحقق من التحديثات…';

  @override
  String settingsUpToDate(String version) {
    return 'أنت على أحدث إصدار (v$version).';
  }

  @override
  String get settingsUpdateCheckUnavailable =>
      'تعذر التحقق من التحديثات. تأكد من تثبيت التطبيق من Google Play.';

  @override
  String get settingsNoBlockedContacts => 'لا توجد جهات اتصال محظورة';

  @override
  String get settingsUnblock => 'إلغاء الحظر';

  @override
  String settingsUserUnblocked(String name) {
    return 'تم إلغاء حظر $name';
  }

  @override
  String get settingsVerifyContactTitle => 'التحقق من جهة اتصال';

  @override
  String get settingsVerifyContactSubtitle =>
      'اختر جهة اتصال لعرض رقم الأمان المشترك.';

  @override
  String get settingsComputingSafetyNumber => 'جارٍ حساب رقم الأمان…';

  @override
  String settingsSafetyNumberExplanation(String name) {
    return 'إذا تطابق الرقم أدناه مع جهاز $name، فإن التشفير مؤكد.';
  }

  @override
  String get settingsSafetyNumberNoBundle =>
      'لم تنشر جهة الاتصال هذه حزمة مفاتيح تشفير بعد.';

  @override
  String get settingsSafetyNumberCompareHint =>
      'قارن هذا الرقم شخصياً أو عبر مكالمة موثوقة.';

  @override
  String get callEndToEndEncrypted => 'مشفر من طرف إلى طرف';

  @override
  String get callSecuring => 'تأمين المكالمة…';

  @override
  String get callNotEncrypted => 'غير مشفر';

  @override
  String get callIncomingVoice => 'مكالمة صوتية واردة';

  @override
  String get callIncomingVideo => 'مكالمة فيديو واردة';

  @override
  String get callVoiceCall => 'مكالمة صوتية';

  @override
  String get callVideoCall => 'مكالمة فيديو';

  @override
  String get callDecline => 'رفض';

  @override
  String get callAccept => 'قبول';

  @override
  String get callConnecting => 'جارٍ الاتصال...';

  @override
  String get callSettingUp => 'جارٍ إعداد المكالمة...';

  @override
  String callNotifying(String name) {
    return 'جارٍ إشعار $name...';
  }

  @override
  String get callRinging => 'يرن...';

  @override
  String get callConnected => 'متصل';

  @override
  String get callOnHold => 'قيد الانتظار';

  @override
  String get callCalling => 'جارٍ الاتصال...';

  @override
  String get callWaitingForUser => 'في انتظار الطرف الآخر...';

  @override
  String get callEnded => 'انتهت المكالمة';

  @override
  String get callDeclined => 'تم رفض المكالمة';

  @override
  String get callNoAnswer => 'لا يوجد رد';

  @override
  String get callFailedToConnect => 'فشل الاتصال';

  @override
  String callFailedToStart(String error) {
    return 'فشل بدء المكالمة: $error';
  }

  @override
  String get callTokenExpired =>
      'الرمز غير صالح أو انتهت صلاحيته. يرجى إعادة بدء المكالمة.';

  @override
  String callFailedToInit(String type, String error) {
    return 'فشل بدء مكالمة $type: $error';
  }

  @override
  String get callTurnOffSpeaker => 'إيقاف مكبر الصوت';

  @override
  String get callTurnOnSpeaker => 'تشغيل مكبر الصوت';

  @override
  String get callMuteMic => 'كتم الميكروفون';

  @override
  String get callUnmuteMic => 'إلغاء كتم الميكروفون';

  @override
  String get callEndCall => 'إنهاء المكالمة';

  @override
  String get callSwitchCamera => 'تبديل الكاميرا';

  @override
  String get callTurnOffCamera => 'إيقاف الكاميرا';

  @override
  String get callTurnOnCamera => 'تشغيل الكاميرا';

  @override
  String statusViewedByCount(int count) {
    return 'شوهد بواسطة $count';
  }

  @override
  String get statusNoViewsYet => 'لا توجد مشاهدات بعد';

  @override
  String statusViewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مشاهدات',
      one: 'مشاهدة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get statusDeleteTitle => 'حذف الحالة';

  @override
  String get statusDeleteConfirm => 'هل أنت متأكد من حذف هذه الحالة؟';

  @override
  String get statusDeleteButton => 'حذف';

  @override
  String get statusReplySent => 'تم إرسال الرد';

  @override
  String statusReplyFailed(String error) {
    return 'فشل إرسال الرد: $error';
  }

  @override
  String get statusNoActive => 'لا توجد حالة نشطة';

  @override
  String get statusCouldNotLoad => 'تعذر تحميل هذا التحديث';

  @override
  String get statusTapToRetry => 'انقر لإعادة المحاولة';

  @override
  String get statusFailedToLoadImage => 'فشل تحميل الصورة';

  @override
  String get statusLoadingVideo => 'جارٍ تحميل الفيديو...';

  @override
  String get statusEnterTextPrompt => 'يرجى كتابة نص';

  @override
  String get statusNoContactsNotice =>
      'لا توجد جهات اتصال بعد — ابدأ محادثة أولاً.';

  @override
  String statusPostFailed(String error) {
    return 'فشل نشر الحالة: $error';
  }

  @override
  String get statusTypeHint => 'اكتب حالة...';

  @override
  String get statusCamera => 'الكاميرا';

  @override
  String get statusTakePhoto => 'التقاط صورة';

  @override
  String get statusGalleryPhoto => 'صورة من المعرض';

  @override
  String get statusChooseImageGallery => 'اختر صورة من المعرض';

  @override
  String get statusRecordVideo => 'تسجيل فيديو';

  @override
  String get statusRecordShortVideo => 'تسجيل فيديو قصير';

  @override
  String get statusGalleryVideo => 'فيديو من المعرض';

  @override
  String get statusChooseVideoGallery => 'اختر فيديو من المعرض';

  @override
  String statusFailedPickImage(String error) {
    return 'فشل اختيار الصورة: $error';
  }

  @override
  String statusFailedPickVideo(String error) {
    return 'فشل اختيار الفيديو: $error';
  }

  @override
  String get statusChangeBgColorTooltip => 'تغيير لون الخلفية';

  @override
  String aiMessagesRemaining(int count) {
    return '$count متبقية';
  }

  @override
  String get aiQuotaDialogTitle => 'رسائل GupAI';

  @override
  String aiQuotaRemainingOfTotal(int remaining, int total) {
    return 'متبقي $remaining من $total اليوم';
  }

  @override
  String aiQuotaUsedResetNote(int used) {
    return 'استُخدم $used اليوم · يتجدد غدًا. شاهد إعلانًا أو اشترك في Pro.';
  }

  @override
  String get aiQuotaGotIt => 'حسناً';

  @override
  String get aiTitle => 'GupAI';

  @override
  String get aiSubtitle => 'مساعدك الذكي داخل التطبيق';

  @override
  String get aiEmptyHelpTitle => 'كيف يمكنني مساعدتك؟';

  @override
  String get aiEmptyHelpSubtitle =>
      'قم بصياغة الردود، الترجمة، التلخيص، أو طرح الأسئلة.';

  @override
  String get meshOfflineChatConnected => 'دردشة غير متصلة · متصل';

  @override
  String get meshConnecting => 'جارٍ الاتصال…';

  @override
  String get meshBannerNotice => 'دردشة غير متصلة — دون إنترنت أو خوادم';

  @override
  String meshSayHiTo(String name) {
    return 'قل مرحباً لـ $name';
  }

  @override
  String meshOfflineDescription(String name) {
    return 'أنت في وضع الدردشة غير المتصلة. تبقى الرسائل بينك وبين $name.';
  }

  @override
  String get meshMediaUnavailable => 'هذا الوسائط لم تعد متوفرة.';

  @override
  String get meshViewOnceTitle => 'عرض لمرة واحدة';

  @override
  String meshViewOncePrompt(String type) {
    return 'يمكنك فتح هذا $type مرة واحدة فقط.';
  }

  @override
  String get arcadeTabOverview => 'نظرة عامة';

  @override
  String get arcadeTabChallenges => 'التحديات';

  @override
  String get arcadeTabLeaderboard => 'لوحة الصدارة';

  @override
  String get arcadeFailedLoadStats => 'فشل تحميل الإحصائيات.';

  @override
  String get aiAskHint => 'اسأل GupAI أي شيء…';

  @override
  String get settingsNotificationsTile => 'الإشعارات';

  @override
  String get settingsNotificationsStatusOn => 'مفعّل';

  @override
  String get settingsNotificationsStatusOff => 'متوقف';

  @override
  String get settingsNotificationsEnabledToast => 'الإشعارات مفعّلة.';

  @override
  String get settingsEnableNotificationsTitle => 'تفعيل الإشعارات';

  @override
  String get settingsEnableNotificationsBody =>
      'الإشعارات متوقفة. افتح إعدادات النظام للسماح لـ GupShupGo بإشعارك بالرسائل والمكالمات الجديدة.';

  @override
  String get settingsOpenSystemSettings => 'فتح الإعدادات';

  @override
  String get loginTagline => 'مراسلة خاصة تعمل حتى بدون إنترنت.';

  @override
  String get settingsPrivacyPolicy => 'سياسة الخصوصية';

  @override
  String get settingsTerms => 'شروط الخدمة';

  @override
  String get settingsDeleteAccount => 'حذف الحساب';

  @override
  String get inviteSheetTitle => 'دعوة الأصدقاء';

  @override
  String get inviteSheetSubtitle => 'انشر الخبر — شارك GupShupGo';

  @override
  String get inviteShareImageBtn => 'مشاركة الصورة';

  @override
  String get inviteShareLinkBtn => 'مشاركة الرابط';

  @override
  String get inviteCopyLinkBtn => 'نسخ الرابط';

  @override
  String get inviteLinkCopied => 'تم نسخ رابط الدعوة';

  @override
  String inviteMessage(String link) {
    return 'تحدث معي على GupShupGo — يعمل حتى بدون إنترنت 👋 $link';
  }

  @override
  String get inviteCardTagline => 'محادثة خاصة تعمل حتى في وضع عدم الاتصال';

  @override
  String get inviteCardScan => 'امسح للتنزيل';

  @override
  String get inviteCardDownload => 'تنزيل من Google Play';

  @override
  String get homeMenuInvite => 'دعوة الأصدقاء';

  @override
  String get invitePromptTitle => 'هل تستمتع بـ GupShupGo؟';

  @override
  String get invitePromptBody =>
      'التطبيق أفضل مع الأصدقاء — ويعمل حتى بدون إنترنت. هل تود دعوة شخص ما؟';

  @override
  String get invitePromptInvite => 'دعوة الأصدقاء';

  @override
  String get invitePromptLater => 'ربما لاحقًا';

  @override
  String get homeOfflineBannerTitle => 'لا يوجد إنترنت؟ لا مشكلة';

  @override
  String get homeOfflineBannerSubtitle =>
      'لا يزال بإمكانك مراسلة الأشخاص القريبين منك عبر البلوتوث.';

  @override
  String homeNearbyBannerTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شخص قريب',
      many: '$count شخصًا قريبًا',
      few: '$count أشخاص قريبين',
      one: 'شخص واحد قريب',
    );
    return '$_temp0';
  }

  @override
  String get homeNearbyBannerSubtitle =>
      'دردش عبر البلوتوث — لا حاجة للإنترنت.';

  @override
  String get linkBackupTitle => 'إضافة طريقة تسجيل دخول احتياطية';

  @override
  String get linkBackupSubtitle =>
      'اربط حساب Google أو بريدك الإلكتروني لتسجيل الدخول\nحتى لو كانت بطاقة SIM غير متوفرة.';

  @override
  String get linkGoogleTitle => 'ربط حساب Google';

  @override
  String get linkGoogleSubtitleLinked => 'تم الربط ✓';

  @override
  String get linkGoogleSubtitleUnlinked => 'تسجيل الدخول بلمسة واحدة بدون SIM';

  @override
  String get linkGoogleAction => 'ربط';

  @override
  String get linkGoogleSuccess => 'تم ربط حساب Google بنجاح!';

  @override
  String get linkGoogleAlreadyUsed =>
      'حساب Google هذا مسجل بالفعل كحساب منفصل في GupShupGo. للدمج، سجّل الخروج وسجّل الدخول عبر Google، ثم اربط رقم هاتفك من الإعدادات.';

  @override
  String get linkGoogleFailed => 'فشل ربط Google. حاول مجدداً.';

  @override
  String get linkSessionExpired => 'انتهت الجلسة. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get linkEmailTitle => 'ربط البريد الإلكتروني وكلمة المرور';

  @override
  String get linkEmailSubtitleLinked => 'تم الربط ✓';

  @override
  String get linkEmailSubtitleUnlinked =>
      'سجل الدخول بالبريد الإلكتروني في حال عدم توفر SIM أو Google';

  @override
  String get linkEmailActionAdd => 'إضافة';

  @override
  String get linkEmailActionCancel => 'إلغاء';

  @override
  String get linkEmailFieldLabel => 'البريد الإلكتروني';

  @override
  String get linkPasswordFieldLabel => 'أنشئ كلمة مرور';

  @override
  String get linkPasswordHelper => 'الحد الأدنى 6 أحرف';

  @override
  String get linkEmailButton => 'ربط البريد الإلكتروني';

  @override
  String get linkEmailSuccess => 'تم ربط البريد الإلكتروني بنجاح!';

  @override
  String get linkEmailInvalid => 'أدخل عنوان بريد إلكتروني صالح.';

  @override
  String get linkPasswordTooShort => 'يجب ألا تقل كلمة المرور عن 6 أحرف.';

  @override
  String get linkEmailAlreadyInUse =>
      'هذا البريد مسجل بالفعل في GupShupGo. سجّل الدخول بالبريد أولاً، ثم اربط هاتفك من الإعدادات.';

  @override
  String get linkEmailAlreadyLinked =>
      'يوجد بريد إلكتروني مرتبط بحسابك بالفعل.';

  @override
  String get linkEmailFailed => 'فشل ربط البريد الإلكتروني. حاول مجدداً.';

  @override
  String get linkContinueToApp => 'المتابعة إلى التطبيق';

  @override
  String get linkSkipForNow => 'تخطي الآن';

  @override
  String get linkSkip => 'تخطي';

  @override
  String get phoneAuthTitleEntry => 'تسجيل الدخول برقم هاتفك.';

  @override
  String get phoneAuthTitleOtp => 'أدخل الرمز الذي أرسلناه لك.';

  @override
  String get phoneAuthNameHint => 'اسمك';

  @override
  String get phoneAuthPhoneHint => 'رقم الهاتف';

  @override
  String get phoneAuthUseSim => 'استخدام SIM';

  @override
  String get phoneAuthSendOtp => 'إرسال الرمز';

  @override
  String phoneAuthOtpPrompt(String phone) {
    return 'أدخل الرمز المكون من 6 أرقام المرسل إلى $phone';
  }

  @override
  String get phoneAuthOtpPromptGeneric =>
      'أدخل الرمز المكون من 6 أرقام الذي أرسلناه إليك';

  @override
  String get phoneAuthOtpHint => 'أدخل الرمز';

  @override
  String get phoneAuthVerify => 'تأكيد';

  @override
  String get phoneAuthGoBack => 'رجوع';

  @override
  String get phoneAuthResendCode => 'إعادة إرسال الرمز';

  @override
  String get phoneAuthEnterName => 'يرجى إدخال اسمك';

  @override
  String get phoneAuthEnterValidPhone => 'يرجى إدخال رقم هاتف صالح';

  @override
  String get phoneAuthEnterCode => 'يرجى إدخال الرمز';

  @override
  String get phoneAuthRequestNewCode => 'يرجى طلب رمز جديد.';

  @override
  String get phoneAuthCodeIncorrect =>
      'الرمز غير صحيح. يرجى المحاولة مرة أخرى.';

  @override
  String get phoneAuthErrCodeIncorrect => 'الرمز غير صحيح. حاول مجدداً.';

  @override
  String get phoneAuthErrCodeExpired =>
      'انتهت صلاحية الرمز. اطلب رمزاً جديداً.';

  @override
  String get phoneAuthErrTooManyRequests =>
      'محاولات كثيرة جداً. انتظر دقيقة وحاول مجدداً.';

  @override
  String get phoneAuthErrInvalidPhone => 'رقم الهاتف غير صالح.';

  @override
  String get phoneAuthErrQuotaExceeded =>
      'تم تجاوز حد الرسائل القصيرة SMS. حاول لاحقاً.';

  @override
  String get phoneAuthErrFailed => 'فشل إرسال الرمز. يرجى المحاولة مجدداً.';

  @override
  String get usernameSetupAppBarTitle => 'إعداد اسم المستخدم';

  @override
  String get usernameSetupHeaderTitle => 'اختر اسم المستخدم';

  @override
  String get usernameSetupHeaderDesc =>
      'اختر معرّفاً فريداً ليتمكن الآخرون من العثور عليك في GupShupGo.';

  @override
  String get usernameSetupInputHint => 'اسم_المستخدم';

  @override
  String get usernameSetupChecking => 'جارٍ التحقق…';

  @override
  String usernameSetupAvailable(String handle) {
    return '@$handle متاح!';
  }

  @override
  String usernameSetupTaken(String handle) {
    return '@$handle محجوز بالفعل.';
  }

  @override
  String get usernameSetupCharRules => 'الأحرف المسموحة: a-z و 0-9 و _ و .';

  @override
  String get usernameSetupTooShort => 'يجب ألا يقل اسم المستخدم عن 3 أحرف';

  @override
  String get usernameSetupTooLong => 'يجب ألا يزيد اسم المستخدم عن 20 حرفاً';

  @override
  String get usernameSetupInvalidChars =>
      'يمكن استخدام أحرف صغيرة وأرقام وشرطة سفلية ونقطة فقط';

  @override
  String get usernameSetupRecommended => 'مقترح:';

  @override
  String get usernameSetupSaveBtn => 'حفظ اسم المستخدم';

  @override
  String get usernameSetupSkipBtn => 'تخطي الآن';

  @override
  String usernameSetupFailed(String error) {
    return 'فشل تعيين اسم المستخدم: $error';
  }

  @override
  String get vaultProtectTitle => 'حماية محادثاتك السرية';

  @override
  String get vaultUnlockTitle => 'فتح الخزنة المشفرة';

  @override
  String get vaultSetupDesc =>
      'عيّن رمز PIN أو عبارة مرور لتشفير محادثات الخزنة الخاصة بك.';

  @override
  String get vaultUnlockDescBio =>
      'استخدم المصادقة الحيوية أو أدخل رمز PIN للوصول.';

  @override
  String get vaultUnlockDescPin =>
      'أدخل رمز PIN الخاص بالخزنة لفك تشفير رسائلك.';

  @override
  String get vaultReinstallHint =>
      'إعادة التثبيت؟ استخدم رمز PIN الذي أنشأته سابقاً.';

  @override
  String get vaultUnlockWithFingerprint => 'فتح ببصمة الإصبع';

  @override
  String get vaultOrDivider => 'أو';

  @override
  String get vaultNewPin => 'رمز PIN جديد للخزنة';

  @override
  String get vaultConfirmPin => 'تأكيد رمز PIN الجديد';

  @override
  String get vaultEnterPin => 'أدخل رمز PIN للخزنة';

  @override
  String get vaultKeyboardUseLetters => 'استخدام الأحرف (عبارة مرور)';

  @override
  String get vaultKeyboardUseNumbers => 'استخدام الأرقام (PIN)';

  @override
  String get vaultRestoreLater => 'استعادة لاحقاً';

  @override
  String get vaultForgotPin => 'نسيت رمز PIN؟';

  @override
  String get vaultSetPinBtn => 'تعيين رمز PIN والتشفير';

  @override
  String get vaultDecryptBtn => 'فك التشفير والفتح';

  @override
  String get vaultPinMinLength => 'يجب ألا يقل رمز PIN عن 4 خانات';

  @override
  String get vaultPinsDoNotMatch => 'رمزا PIN غير متطابقين';

  @override
  String get vaultSetupFailed => 'فشل إعداد الخزنة. يرجى المحاولة مرة أخرى.';

  @override
  String get vaultIncorrectPin => 'رمز PIN غير صحيح';

  @override
  String get vaultFingerprintOutOfDate =>
      'تغيرت بصمة الإصبع. يرجى استخدام رمز PIN.';

  @override
  String get vaultBiometricError => 'المصادقة الحيوية غير متوفرة';

  @override
  String get vaultBioReasonUnlock => 'المصادقة لفتح خزنة محادثاتك';

  @override
  String get vaultBioReasonEnrol => 'المصادقة لتمكين الوصول الحيوي للخزنة';

  @override
  String get vaultAskBioTitle => 'تمكين فتح القفل بالمصادقة الحيوية؟';

  @override
  String get vaultAskBioDesc =>
      'استخدم بصمة الإصبع أو معرف الوجه لفتح خزنتك بسرعة وأمان.';

  @override
  String get vaultAskBioNotNow => 'ليس الآن';

  @override
  String get vaultAskBioEnable => 'تمكين';

  @override
  String get vaultDeleteMessagesTitle => 'حذف رسائل الخزنة؟';

  @override
  String get vaultDeleteMessagesDesc =>
      'إذا نسيت رمز PIN، لا يمكن استرداد الرسائل المشفرة. سيتم مسح الرسائل الحالية لتتمكن من إنشاء رمز PIN جديد.';

  @override
  String get vaultDeleteMessagesCancel => 'إلغاء';

  @override
  String get vaultDeleteMessagesConfirm => 'حذف الرسائل وإنشاء PIN جديد';

  @override
  String get vaultCustodyConfirmTitle => 'تأكيد نموذج حراسة الخزنة';

  @override
  String get vaultCustodyChooseTitle => 'نموذج حراسة مفتاح الخزنة';

  @override
  String get vaultCustodyConfirmDesc =>
      'يرجى تأكيد تفضيل تخزين مفتاح التشفير الخاص بك.';

  @override
  String get vaultCustodyChooseDesc =>
      'اختر أين يتم تشفير وحفظ مفاتيح الخزنة الخاصة بك.';

  @override
  String get vaultCustodyDontKnow =>
      'لست متأكداً؟ يمكنك تغيير هذا الخيار لاحقاً في إعدادات الخزنة.';

  @override
  String get vaultCustodyConfirmBtn => 'تأكيد المتابعة';

  @override
  String get vaultCustodySaveBtn => 'حفظ ومتابعة';

  @override
  String get vaultCustodyMismatchError =>
      'عدم تطابق في بيانات التشفير. يرجى إعادة المحاولة.';

  @override
  String get vaultCustodyAutoUpdateFailed =>
      'تعذر تحديث إعدادات الحراسة تلقائياً.';

  @override
  String vaultCustodyReencrypting(int done, int total) {
    return 'جارٍ إعادة التشفير $done من $total… يرجى إبقاء التطبيق مفتوحاً.';
  }

  @override
  String get vaultCustodyPreparing => 'جارٍ تحضير التشفير…';

  @override
  String get vaultSettingsTitle => 'إعدادات الخزنة';

  @override
  String get vaultSettingsAboutTitle => 'حول الخزنة المشفرة';

  @override
  String get vaultSettingsAboutDesc =>
      'الخزنة مساحة فائقة الأمان ومحمية برمز PIN ومصممة لمحادثاتك الخاصة.';

  @override
  String get vaultSettingsBulletMessages =>
      'تشفير شامل لجميع الرسائل والملفات داخل الخزنة.';

  @override
  String get vaultSettingsBulletStatuses =>
      'حالات وحوارات خاصة لا تظهر في سجلات النظام العادية.';

  @override
  String get vaultSettingsNeverKept =>
      'لا يتم حفظ مفاتيح التشفير بشكل غير مشفر نهائياً.';

  @override
  String get vaultSettingsSectionPrivacy => 'الخصوصية والحذف التلقائي';

  @override
  String get vaultSettingsAutoDelete => 'الحذف التلقائي لرسائل الخزنة';

  @override
  String get vaultSettingsKeepForever => 'الاحتفاظ للأبد';

  @override
  String vaultSettingsDeleteAfter(String label) {
    return 'الحذف بعد $label';
  }

  @override
  String get vaultSettingsSectionPin => 'رمز PIN والأمان الحيوي';

  @override
  String get vaultSettingsChangePin => 'تغيير رمز PIN للخزنة';

  @override
  String get vaultSettingsChangePinSubtitle =>
      'قم بتحديث رمز PIN أو عبارة المرور الخاصة بك';

  @override
  String get vaultSettingsBioTitle => 'فتح القفل بالمصادقة الحيوية';

  @override
  String get vaultSettingsBioSubOn => 'استخدم بصمة الإصبع أو الوجه لفتح الخزنة';

  @override
  String get vaultSettingsBioSubOff => 'تم تعطيل الفتح الحيوي';

  @override
  String get vaultSettingsSectionDanger => 'منطقة الخطر';

  @override
  String get vaultSettingsDeleteData => 'مسح بيانات الخزنة';

  @override
  String get vaultSettingsDeleteDataSubtitle =>
      'حذف كافة الرسائل والوسائط المشفرة من هذا الجهاز';

  @override
  String get vaultSettingsResetVault => 'إعادة ضبط الخزنة بالكامل';

  @override
  String get vaultSettingsResetVaultSubtitle =>
      'إزالة الخزنة وإعادة تعيين رمز PIN وحذف جميع محتوياتها';

  @override
  String get vaultSettingsPinChanged => 'تم تغيير رمز PIN للخزنة بنجاح!';

  @override
  String get vaultSettingsBioTurnedOff => 'تم إيقاف الفتح بالمصادقة الحيوية.';

  @override
  String get vaultSettingsBioTurnedOn => 'تم تفعيل الفتح بالمصادقة الحيوية.';

  @override
  String get vaultSettingsClearDataTitle => 'مسح كافة بيانات الخزنة؟';

  @override
  String get vaultSettingsClearDataDesc =>
      'سيتم حذف جميع رسائل ووسائط الخزنة نهائياً من هذا الجهاز ولا يمكن استرجاعها.';

  @override
  String get vaultSettingsClearDataCancel => 'إلغاء';

  @override
  String get vaultSettingsClearDataConfirm => 'مسح البيانات';

  @override
  String get vaultSettingsDataDeleted => 'تم مسح بيانات الخزنة بنجاح.';

  @override
  String get vaultSettingsResetTitle => 'إعادة ضبط الخزنة بالكامل؟';

  @override
  String get vaultSettingsResetDesc =>
      'سيتم حذف جميع المحتويات وإلغاء رمز PIN الحالي. ستحتاج لإعداد الخزنة مجدداً من الصفر.';

  @override
  String get vaultSettingsResetConfirm => 'إعادة ضبط ومسح';

  @override
  String get vaultSettingsChangeDialogDesc =>
      'أدخل رمز PIN الحالي ثم اختر الرمز الجديد.';

  @override
  String get vaultSettingsCurrentPin => 'رمز PIN الحالي';

  @override
  String get vaultSettingsNewPin => 'رمز PIN الجديد';

  @override
  String get vaultSettingsConfirmNewPin => 'تأكيد رمز PIN الجديد';

  @override
  String get vaultSettingsEnterCurrentPin => 'أدخل رمز PIN الحالي';

  @override
  String get vaultSettingsNewPinMinLength =>
      'يجب ألا يقل رمز PIN الجديد عن 4 خانات';

  @override
  String get vaultSettingsNewPinMismatch => 'الرمز الجديد وتأكيده غير متطابقين';

  @override
  String get vaultSettingsCurrentPinIncorrect => 'رمز PIN الحالي غير صحيح';

  @override
  String vaultSettingsReencryptingCount(int done, int total) {
    return 'جارٍ إعادة التشفير $done من $total…';
  }

  @override
  String get vaultSettingsChangeBtn => 'تغيير رمز PIN';

  @override
  String get vaultSettingsBioPinDialogTitle => 'أدخل رمز PIN للتحقق';

  @override
  String get vaultSettingsBioPinDialogDesc =>
      'أدخل رمز PIN للخزنة لتعديل إعدادات المصادقة الحيوية.';

  @override
  String get vaultSettingsContinueBtn => 'متابعة';

  @override
  String get premiumTitle => 'GupShupGo بريميوم';

  @override
  String get premiumSubtitleMember => 'أنت عضو في بريميوم';

  @override
  String get premiumSubtitleUnlock => 'افتح التجربة الكاملة وغير المحدودة';

  @override
  String premiumActiveDaysRemaining(int days) {
    return 'متبقي $days يوم';
  }

  @override
  String get premiumFeaturesHeader => 'كل الميزات المتضمنة';

  @override
  String get premiumPlansHeader => 'اختر خطتك';

  @override
  String get premiumSubscribeBtn => 'الترقية الآن';

  @override
  String get premiumCancelAnytime =>
      'إلغاء الاشتراك في أي وقت من متجر التطبيقات';

  @override
  String get premiumRestoreBtn => 'استعادة المشتريات';

  @override
  String get premiumRestoring => 'جارٍ استعادة المشتريات…';

  @override
  String get premiumRestoredSuccess => 'تمت استعادة مشترياتك بنجاح!';

  @override
  String get premiumNoActiveSub => 'لم يتم العثور على اشتراك نشط.';

  @override
  String get premiumProductUnavailable =>
      'المنتج غير متاح حالياً. يرجى المحاولة لاحقاً.';

  @override
  String get premiumFeatureMediaTitle => 'وسائط فائقة الجودة';

  @override
  String get premiumFeatureMediaDesc =>
      'إرسال صور ومقاطع فيديو بدقة أصلية غير مضغوطة';

  @override
  String get premiumFeatureMediaFree => 'وسائط قياسية مضغوطة';

  @override
  String get premiumFeatureMediaPro => 'جودة أصلية كاملة';

  @override
  String get premiumFeatureScreenShareTitle => 'مشاركة الشاشة بدقة HD';

  @override
  String get premiumFeatureScreenShareDesc =>
      'بث شاشتك بدقة عالية 1080p ومعدل 60 إطار في الثانية';

  @override
  String get premiumFeatureScreenShareFree => 'دقة 720p قياسية';

  @override
  String get premiumFeatureScreenSharePro => 'دقة 1080p عالية النقاء';

  @override
  String get premiumFeatureThemesTitle => 'مظاهر وتخصيص حصري';

  @override
  String get premiumFeatureThemesDesc =>
      'افتح كل المظاهر المظلمة والألوان وشارات الدردشة';

  @override
  String get premiumFeatureThemesFree => 'المظهر الافتراضي فقط';

  @override
  String get premiumFeatureThemesPro => 'جميع المظاهر غير محدودة';

  @override
  String get premiumFeatureVoiceTitle => 'رسائل صوتية طويلة';

  @override
  String get premiumFeatureVoiceDesc =>
      'تسجيل ومشاركة ملاحظات صوتية تصل إلى 30 دقيقة';

  @override
  String get premiumFeatureVoiceFree => 'دقيقتان كحد أقصى';

  @override
  String get premiumFeatureVoicePro => 'حتى 30 دقيقة';

  @override
  String get premiumFeatureQualityTitle => 'أولوية نقل البيانات';

  @override
  String get premiumFeatureQualityDesc =>
      'خوادم مخصصة تضمن أسرع سرعات رفع وتنزيل';

  @override
  String get premiumFeatureQualityFree => 'سرعة عادية';

  @override
  String get premiumFeatureQualityPro => 'أولوية قصوى فائقة';

  @override
  String get premiumFeatureBondTitle => 'مستوى الرابطة المميز';

  @override
  String get premiumFeatureBondDesc =>
      'شارة رابطة خاصة ورسوم متحركة عند الدردشة مع أصدقائك المقربين';

  @override
  String get premiumFeatureBondFree => 'مستوى قياسي';

  @override
  String get premiumFeatureBondPro => 'شارة ورسوم متحركة فريدة';

  @override
  String get premiumFeatureBadgeTitle => 'شارة الملف الشخصي PRO';

  @override
  String get premiumFeatureBadgeDesc =>
      'شارة بريميوم أنيقة بجانب اسمك في كل مكان';

  @override
  String get premiumFeatureBadgeFree => 'بدون شارة';

  @override
  String get premiumFeatureBadgePro => 'شارة PRO ذهبية';

  @override
  String get premiumFeatureExportTitle => 'تصدير المحادثات والوسائط';

  @override
  String get premiumFeatureExportDesc =>
      'تصدير نسخ احتياطية كاملة من محادثاتك بتنسيق PDF أو ZIP';

  @override
  String get premiumFeatureExportFree => 'غير متوفر';

  @override
  String get premiumFeatureExportPro => 'تصدير كامل بنقرة واحدة';

  @override
  String get premiumFeatureAdFreeTitle => 'تجربة نقية تماماً';

  @override
  String get premiumFeatureAdFreeDesc =>
      'استمتع بتطبيق خالٍ تماماً من أي إعلانات أو فواصل';

  @override
  String get premiumFeatureAdFreeFree => 'إعلانات دعم التطبيق';

  @override
  String get premiumFeatureAdFreePro => 'تجربة نقية 100% بدون إعلانات';

  @override
  String get premiumPlanMonthly => 'شهري';

  @override
  String get premiumPlanYearly => 'سنوي';

  @override
  String get premiumPlanSavings => 'وفر 40%';

  @override
  String get premiumPeriodMonth => 'شهرياً';

  @override
  String get premiumPeriodYear => 'سنوياً';

  @override
  String get nearbyOfflineChatTitle => 'دردشة محلية بدون إنترنت';

  @override
  String get nearbySearchingDevices => 'جارٍ البحث عن أجهزة…';

  @override
  String get nearbyTooltipStop => 'إيقاف البحث';

  @override
  String get nearbyTooltipStart => 'بدء البحث';

  @override
  String get nearbyDevicesSection => 'الأجهزة المكتشفة';

  @override
  String get nearbyDiscoveryOn => 'البحث قيد التشغيل';

  @override
  String get nearbyDiscoveryOff => 'البحث متوقف';

  @override
  String get nearbyHeroTitle => 'تواصل في أي مكان';

  @override
  String nearbyHeroNearbyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count على مقربة',
      one: '1 على مقربة',
    );
    return '$_temp0';
  }

  @override
  String get nearbyHeroOff => 'وضع عدم الاتصال متوقف';

  @override
  String get nearbyHeroDesc =>
      'تحدث مع أشخاص قريبين منك عبر Wi-Fi و Bluetooth بدون الحاجة للإنترنت.';

  @override
  String get nearbyYourNameHint => 'اسمك الظاهر للآخرين';

  @override
  String get nearbyEmptySearching => 'جارٍ البحث عن أجهزة مجاورة…';

  @override
  String get nearbyEmptyOff => 'البحث متوقف';

  @override
  String get nearbyEmptySearchingDesc =>
      'تأكد من أن الأجهزة الأخرى فتحت هذه الشاشة أيضاً.';

  @override
  String get nearbyEmptyOffDesc =>
      'انقر على زر التشغيل للبحث عن الأجهزة المجاورة.';

  @override
  String get nearbyPeerConnected => 'متصل';

  @override
  String get nearbyPeerConnecting => 'جارٍ الاتصال…';

  @override
  String get nearbyPeerTapToConnect => 'انقر للاتصال';

  @override
  String get nearbyActionChat => 'دردشة';

  @override
  String get nearbyActionConnecting => 'جارٍ الاتصال…';

  @override
  String get nearbyActionConnect => 'اتصال';

  @override
  String get nearbyPermNeededTitle => 'الأذونات مطلوبة';

  @override
  String get nearbyPermNeededDesc =>
      'يتطلب البحث دون اتصال إذن الموقع والأجهزة المجاورة عبر البلوتوث.';

  @override
  String get nearbyTryAgainBtn => 'إعادة المحاولة';

  @override
  String get nearbySettingsBtn => 'فتح الإعدادات';

  @override
  String get nearbyHelpTip =>
      'ملاحظة: تأكد من تشغيل كل من Wi-Fi و Bluetooth على الجهازين.';

  @override
  String get anonLobbyTitle => 'دردشة عشوائية مجهولة';

  @override
  String get anonLobbyFinding => 'جارٍ البحث عن شخص ما…';

  @override
  String get anonLobbyHangTight => 'انتظر لحظة، نبحث عن شريك محادثة متاح.';

  @override
  String get anonLobbyCancelBtn => 'إلغاء البحث';

  @override
  String get anonLobbyPrivacyNote =>
      'محادثتك مجهولة تماماً. لن يرى الشريك اسمك أو رقم هاتفك أو ملفك الشخصي.';

  @override
  String get anonLobbyConnecting => 'جارٍ الاتصال…';

  @override
  String get anonLobbyWaitingOthers => 'في انتظار انضمام مستخدمين آخرين…';

  @override
  String anonLobbyOnlineCount(int count) {
    return '$count متصل الآن';
  }

  @override
  String get anonChatNotEncrypted =>
      'ملاحظة: الدردشة العشوائية غير مشفرة بخاصية E2EE لتمكين الإبلاغ عن الإساءات.';

  @override
  String get anonChatRequestSentTooltip => 'تم إرسال طلب الصداقة';

  @override
  String get anonChatAddFriendTooltip => 'إضافة صديق';

  @override
  String get anonChatNextStrangerTooltip => 'التالي (شخص جديد)';

  @override
  String get anonChatReportTooltip => 'إبلاغ عن المستخدم';

  @override
  String get anonChatSayHi => 'قل مرحباً! أنت الآن متصل بمستخدم مجهول.';

  @override
  String get anonChatFriendsTransition =>
      'أنتما الآن صديقان! تم نقل المحادثة إلى قائمة الدردشات الرئيسية.';

  @override
  String get anonChatStrangerDisconnected => 'غادر الشريك المحادثة.';

  @override
  String get anonChatFindNextBtn => 'البحث عن شخص جديد';

  @override
  String get anonChatFriendReqTitle => 'طلب صداقة';

  @override
  String get anonChatFriendReqDesc =>
      'يرغب الشريك في إضافتك كصديق ومشاركة الملفات الشخصية.';

  @override
  String get anonChatDecline => 'رفض';

  @override
  String get anonChatAccept => 'قبول';

  @override
  String get anonChatWaitingReqTitle => 'تم إرسال طلب الصداقة';

  @override
  String get anonChatWaitingReqDesc =>
      'في انتظار موافقة الشريك على تبادل الهوية…';

  @override
  String get anonChatReportTitle => 'إبلاغ عن الشريك المجهول';

  @override
  String get anonChatReportQuestion => 'لماذا تبلغ عن هذا المستخدم؟';

  @override
  String get anonChatReportReasonInappropriate => 'محتوى غير لائق أو صريح';

  @override
  String get anonChatReportReasonHarassment => 'تحرش أو سلوك مسيء';

  @override
  String get anonChatReportReasonSpam => 'رسائل غير مرغوب فيها أو احتيال';

  @override
  String get anonChatReportReasonThreatening => 'تهديد أو سلوك خطير';

  @override
  String get anonChatReportReasonOther => 'سبب آخر';

  @override
  String get anonChatReportCancel => 'إلغاء';

  @override
  String get anonChatReportSubmit => 'إرسال البلاغ';

  @override
  String get anonChatReportSubmitted =>
      'تم إرسال البلاغ بنجاح. شكراً لحرصك على أمان المجتمع.';

  @override
  String get anonChatViewOnceVideoTitle => 'فيديو يُعرض لمرة واحدة';

  @override
  String get anonChatViewOncePhotoTitle => 'صورة تُعرض لمرة واحدة';

  @override
  String get anonChatViewOnceVideoDesc =>
      'يمكنك تشغيل هذا الفيديو مرة واحدة فقط. سيتم حذفه بعد المشاهدة.';

  @override
  String get anonChatViewOncePhotoDesc =>
      'يمكنك فتح هذه الصورة مرة واحدة فقط. ستختفي بمجرد إغلاقها.';

  @override
  String get anonChatViewOnceCancel => 'إلغاء';

  @override
  String get anonChatViewOnceOpen => 'فتح وعرض';

  @override
  String get unsupportedVersionTitle => 'تحديث التطبيق مطلوب';

  @override
  String get unsupportedVersionDesc =>
      'هذا الإصدار من GupShupGo لم يعد مدعوماً. يرجى التحديث إلى أحدث إصدار لمواصلة الدردشة والمكالمات بأمان.';

  @override
  String get unsupportedVersionUpdateNow => 'تحديث الآن';

  @override
  String get unsupportedVersionOpenPlayStore => 'فتح متجر التطبيقات';

  @override
  String publicProfileNotFound(String username) {
    return '@$username غير موجود';
  }

  @override
  String get publicProfileUserNotFound => 'المستخدم غير موجود';

  @override
  String get publicProfileNotFoundDesc =>
      'قد يكون تم تغيير اسم المستخدم أو أن الحساب لم يعد نشطاً.';

  @override
  String get publicProfileTitle => 'الملف الشخصي';

  @override
  String get publicProfileOnline => 'متصل الآن';

  @override
  String publicProfileLastSeen(String time) {
    return 'آخر ظهور $time';
  }

  @override
  String get publicProfileJustNow => 'الآن';

  @override
  String publicProfileMinutesAgo(int minutes) {
    return 'منذ $minutes دقيقة';
  }

  @override
  String publicProfileHoursAgo(int hours) {
    return 'منذ $hours ساعة';
  }

  @override
  String publicProfileDaysAgo(int days) {
    return 'منذ $days يوم';
  }

  @override
  String publicProfileJoined(String date) {
    return 'انضم في $date';
  }

  @override
  String get publicProfileOwnLink => 'هذا هو ملفك الشخصي العام';

  @override
  String publicProfileGupPoints(int points) {
    return '$points نقطة Gup';
  }

  @override
  String publicProfileLevel(int level) {
    return 'المستوى $level';
  }

  @override
  String get publicProfileStatPoints => 'نقاط Gup';

  @override
  String get publicProfileStatBadges => 'الشارات';

  @override
  String get publicProfileStatBestBond => 'أفضل رابطة';

  @override
  String get publicProfileBadges => 'الشارات المكتسبة';

  @override
  String get qrScannerTitle => 'مسح رمز QR';

  @override
  String get qrScannerFlashOnTooltip => 'تشغيل الفلاش';

  @override
  String get qrScannerFlashOffTooltip => 'إيقاف الفلاش';

  @override
  String get qrScannerPrompt =>
      'وجّه الكاميرا نحو رمز QR لإضافة صديق أو الاتصال';

  @override
  String get qrScannerNotProfileCode =>
      'هذا الرمز ليس رمز ملف شخصي صالح في GupShupGo.';

  @override
  String get qrScannerCameraErrorTitle => 'خطأ في الكاميرا';

  @override
  String get qrScannerCameraErrorRetry => 'إعادة المحاولة';

  @override
  String get qrScannerPermissionMsg => 'يلزم إذن الكاميرا لمسح رموز QR.';

  @override
  String get qrScannerPermissionAllow => 'السماح بالوصول';

  @override
  String get qrScannerBlockedMsg =>
      'تم حظر إذن الكاميرا. يرجى تفعيله من إعدادات النظام.';

  @override
  String get qrScannerBlockedSettings => 'فتح الإعدادات';

  @override
  String get screenShareIncomingTitle => 'مشاركة شاشة واردة';

  @override
  String get screenShareWantsToShare => 'يريد مشاركة شاشته معك.';

  @override
  String get screenShareReject => 'رفض';

  @override
  String get screenShareAccept => 'قبول';

  @override
  String get screenShareCantAccept =>
      'تعذر قبول مشاركة الشاشة في الوقت الحالي.';

  @override
  String screenShareDeclined(String name) {
    return 'رفض $name مشاركة الشاشة';
  }

  @override
  String get screenShareNoAnswer => 'لم يستجب للمكالمة.';

  @override
  String get screenShareStartError =>
      'تعذر بدء مشاركة الشاشة. يرجى إعادة المحاولة.';

  @override
  String get screenShareStatusRequesting => 'جارٍ إرسال الطلب…';

  @override
  String get screenShareStatusInitializing => 'جارٍ الإعداد…';

  @override
  String get screenShareStatusWaitingParticipant => 'في انتظار انضمام المشارك…';

  @override
  String get screenShareStatusActive => 'أنت تشارك شاشتك الآن';

  @override
  String screenShareSubWaitingAccept(String name) {
    return 'في انتظار قبول $name…';
  }

  @override
  String get screenShareSubEstablishing => 'جارٍ إنشاء اتصال آمن…';

  @override
  String screenShareSubWaitingJoin(String name) {
    return 'في انتظار انضمام $name...';
  }

  @override
  String get screenShareSubActive => 'شاشتك معروضة للمشارك الآخر';

  @override
  String get screenShareBadgeRequesting => 'طلب مشاركة';

  @override
  String get screenShareBadgeConnecting => 'جارٍ الاتصال';

  @override
  String get screenShareSharedWith => 'تتم المشاركة مع:';

  @override
  String get screenShareRequestingFrom => 'مطلوب من:';

  @override
  String get screenShareMinimizeTip => 'يمكنك تصغير هذا الإشعار أثناء المشاركة';

  @override
  String get screenShareStop => 'إيقاف المشاركة';

  @override
  String get screenShareCancelRequest => 'إلغاء الطلب';

  @override
  String screenShareViewerTitle(String name) {
    return '$name يشارك شاشته';
  }

  @override
  String get screenShareViewerLive => 'بث مباشر';

  @override
  String get screenShareViewerMinimize => 'تصغير العارض';

  @override
  String get screenShareViewerLeave => 'مغادرة الجلسة';

  @override
  String screenShareViewerWaitingStream(String name) {
    return 'في انتظار بدء بث شاشة $name...';
  }

  @override
  String get screenShareViewerConnecting => 'جارٍ الاتصال بالبث المباشر…';

  @override
  String get viewOnceVideoTitle => 'فيديو لمرة واحدة';

  @override
  String get viewOncePhotoTitle => 'صورة لمرة واحدة';

  @override
  String get viewOnceCantOpen => 'لا يمكن فتح الوسائط منتهية الصلاحية.';

  @override
  String get viewOnceUnavailable => 'هذه الوسائط غير متاحة أو انتهت مدة عرضها.';

  @override
  String get viewOnceBlockedFooter => 'تم حظر لقطات الشاشة لحماية الخصوصية.';

  @override
  String get viewOnceUnblockedFooter =>
      'ستختفي الوسائط بمجرد إغلاق هذه النافذة.';
}
