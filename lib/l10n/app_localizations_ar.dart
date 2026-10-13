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
  String get homeNavChats => 'الدردشات';

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
}
