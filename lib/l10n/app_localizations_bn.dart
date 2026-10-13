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

  @override
  String get homeNavChats => 'আলাপ';

  @override
  String get homeNavMoments => 'মুহূর্ত';

  @override
  String get homeNavCalls => 'কল';

  @override
  String get homeNavProfile => 'প্রোফাইল';

  @override
  String get homeTooltipOfflineChat =>
      'অফলাইন চ্যাট — কাছের মানুষের সাথে কথা বলুন';

  @override
  String get homeTooltipSearch => 'অনুসন্ধান';

  @override
  String get homeMenuProfile => 'প্রোফাইল';

  @override
  String get homeMenuSettings => 'সেটিংস';

  @override
  String get homeMenuRateUs => 'রেটিং দিন';

  @override
  String get homeMenuReportIssue => 'সমস্যার অভিযোগ জানান';

  @override
  String get homeMenuWhatsNew => 'নতুন কি আছে';

  @override
  String get homeMenuLogOut => 'লগ আউট';

  @override
  String get homeEmptyChatsTitle => 'এখনও কোনো চ্যাট নেই';

  @override
  String get homeEmptyChatsSubtitle =>
      'নিচের বোতামে ট্যাপ করে কথোপকথন শুরু করুন';

  @override
  String get homeNewChatButton => 'নতুন চ্যাট';

  @override
  String get homeAiAssistantTitle => 'GupAI';

  @override
  String get homeAiAssistantSubtitle =>
      'খসড়া, অনুবাদ, সারসংক্ষেপ এবং আরও অনেক কিছু';

  @override
  String get homeStrangerMatchTitle => 'অপরিচিত কারো সাথে সংযোগ করুন';

  @override
  String get homeStrangerMatchSubtitle => 'বেনামী চ্যাট — মেলাতে ট্যাপ করুন!';

  @override
  String get homeMyMoment => 'আমার মুহূর্ত';

  @override
  String get homeRecentMoments => 'সাম্প্রতিক মুহূর্ত';

  @override
  String get homeEmptyMomentsTitle => 'এখনও কোনো আপডেট নেই।';

  @override
  String get homeEmptyMomentsSubtitle => 'শেয়ার করতে ক্যামেরায় ট্যাপ করুন।';

  @override
  String get homeTapToAddMoment => 'আপডেট যোগ করতে ট্যাপ করুন';

  @override
  String get homeEmptyCallsTitle => 'কোনো কল ইতিহাস নেই';

  @override
  String get homeEmptyCallsSubtitle =>
      'আপনার সাম্প্রতিক কলগুলি এখানে প্রদর্শিত হবে';

  @override
  String get chatInputHint => 'বার্তা লিখুন...';

  @override
  String get chatSearchHint => 'বার্তা অনুসন্ধান...';

  @override
  String get chatStatusTyping => 'টাইপ করছেন...';

  @override
  String get chatStatusOnline => 'অনলাইন';

  @override
  String get chatStatusOffline => 'অফলাইন';

  @override
  String chatStatusLastSeen(String time) {
    return 'শেষ দেখা $time';
  }

  @override
  String get chatEndToEndEncrypted => 'এন্ড-টু-এন্ড এনক্রিপ্ট করা';

  @override
  String get chatNoInternetOfflineTitle =>
      'ইন্টারনেট নেই? কাছের ডিভাইসের সাথে অফলাইনে চ্যাট করুন';

  @override
  String get chatEnableOfflineButton => 'সক্ষম করুন';

  @override
  String get chatSlideToCancel => 'বাতিল করতে স্লাইড করুন';

  @override
  String get chatTooltipVoiceCall => 'ভয়েস কল';

  @override
  String get chatTooltipVideoCall => 'ভিডিও কল';

  @override
  String get chatMenuContactInfo => 'যোগাযোগের তথ্য';

  @override
  String get chatMenuSearch => 'অনুসন্ধান';

  @override
  String get chatMenuChatTheme => 'চ্যাট থিম';

  @override
  String get chatMenuExportChat => 'চ্যাট রপ্তানি করুন';

  @override
  String get chatMenuMuteNotifications => 'বিজ্ঞপ্তি নিঃশব্দ করুন';

  @override
  String get chatMenuUnmuteNotifications => 'বিজ্ঞপ্তি চালু করুন';

  @override
  String get chatMenuBlockContact => 'যোগাযোগ ব্লক করুন';

  @override
  String get chatActionReply => 'উত্তর দিন';

  @override
  String get chatActionCopy => 'কপি করুন';

  @override
  String get chatActionForward => 'ফরওয়ার্ড করুন';

  @override
  String get chatActionTranslate => 'অনুবাদ করুন';

  @override
  String get chatActionSummarise => 'সারসংক্ষেপ করুন';

  @override
  String get chatActionAskGupAi => 'GupAI-কে জিজ্ঞাসা করুন';

  @override
  String get chatActionEdit => 'সম্পাদনা';

  @override
  String get chatActionDelete => 'মুছুন';

  @override
  String get chatDeleteMessageTitle => 'বার্তা মুছে ফেলবেন?';

  @override
  String get chatDeleteMessageForEveryonePrompt =>
      'শুধু আপনার জন্য মুছে ফেলবেন, নাকি সবার জন্য?';

  @override
  String chatDeleteMessageForMeOnlyPrompt(String name) {
    return 'এটি কেবল আপনার ডিভাইস থেকে মুছে যাবে। $name এটি দেখতে পাবেন।';
  }

  @override
  String get chatDeleteForMe => 'আমার জন্য মুছুন';

  @override
  String get chatDeleteForEveryone => 'সবার জন্য মুছুন';

  @override
  String chatBlockContactTitle(String name) {
    return '$name-কে ব্লক করবেন?';
  }

  @override
  String get chatBlockContactPrompt =>
      'ব্লক করা পরিচিতিরা আপনাকে বার্তা পাঠাতে বা কল করতে পারবেন না। সেটিংস → গোপনীয়তা থেকে আনব্লক করতে পারেন।';

  @override
  String get chatBlockButton => 'ব্লক করুন';

  @override
  String get chatForwardTo => 'ফরওয়ার্ড করুন';

  @override
  String get chatNoForwardChats => 'ফরওয়ার্ড করার জন্য অন্য কোনো চ্যাট নেই';

  @override
  String get chatCannotSendMediaBlocked =>
      'এই পরিচিতিতে মিডিয়া পাঠানো যাবে না';

  @override
  String get attachmentShareTitle => 'শেয়ার করুন';

  @override
  String get attachmentPhoto => 'ছবি';

  @override
  String get attachmentPhotoSubtitle => 'গ্যালারি থেকে একটি ছবি বেছে নিন';

  @override
  String get attachmentVideo => 'ভিডিও';

  @override
  String get attachmentVideoSubtitle => 'গ্যালারি থেকে একটি ভিডিও বেছে নিন';

  @override
  String get attachmentDocument => 'নথি';

  @override
  String get attachmentDocumentSubtitle => 'পিডিএফ, অফিস ফাইল, জিপ ফাইল';

  @override
  String get attachmentLocation => 'অবস্থান';

  @override
  String get attachmentLocationSubtitle => 'আপনার বর্তমান অবস্থান শেয়ার করুন';

  @override
  String get attachmentViewOnce => 'একবার দেখার জন্য';

  @override
  String get attachmentViewOnceSubtitle => 'খোলার পর ছবি বা ভিডিও মুছে যায়';

  @override
  String get contactsTitle => 'পরিচিতি ও সন্ধান';

  @override
  String get contactsTabFriends => 'বন্ধু';

  @override
  String get contactsTabRequests => 'অনুরোধ';

  @override
  String get contactsTabDiscover => 'খুঁজুন';

  @override
  String get contactsScanQrTooltip => 'QR কোড স্ক্যান করুন';

  @override
  String get contactsMyHandleTooltip => 'আমার হ্যান্ডেল';

  @override
  String get contactsSetUsernamePrompt =>
      'প্রথমে আপনার প্রোফাইলে @username সেট করুন — আপনার QR কোড এটিই শেয়ার করে।';

  @override
  String get contactsMyQrCodeTitle => 'আমার প্রোফাইল QR কোড';

  @override
  String get contactsMyQrCodeSubtitle =>
      'বন্ধুরা তৎক্ষণাৎ যুক্ত হতে এই QR কোড স্ক্যান করতে পারে';

  @override
  String get contactsCopyProfileLink => 'প্রোফাইল লিংক কপি করুন';

  @override
  String contactsProfileLinkCopied(String username) {
    return '@$username-এর প্রোফাইল লিংক কপি হয়েছে!';
  }

  @override
  String get contactsScanSomeonesCode => 'কারও কোড স্ক্যান করুন';

  @override
  String get contactsPermissionDenied =>
      'পরিচিতি অ্যাক্সেস করার অনুমতি প্রত্যাখ্যান করা হয়েছে।';

  @override
  String get contactsNoUsersFound =>
      'আপনার পরিচিতিতে এখনও কোনো GupShupGo ব্যবহারকারী পাওয়া যায়নি।';

  @override
  String contactsFailedToSync(String error) {
    return 'পরিচিতি সিঙ্ক করতে ব্যর্থ: $error';
  }

  @override
  String contactsMatchedCount(int count) {
    return 'GupShupGo-তে $count জন পরিচিতি';
  }

  @override
  String get contactsFromDeviceContacts => 'আপনার ডিভাইসের পরিচিতি থেকে';

  @override
  String get contactsLoadFriendsError => 'আপনার বন্ধুদের লোড করা যায়নি।';

  @override
  String get contactsNoFriendsTitle => 'এখনও কোনো বন্ধু যোগ করা হয়নি';

  @override
  String get contactsNoFriendsPrompt =>
      '@username, ফোন বা ইমেলের মাধ্যমে অনুসন্ধান করতে খুঁজুন ট্যাব ব্যবহার করুন!';

  @override
  String get contactsDiscoverPeopleButton => 'মানুষ খুঁজুন';

  @override
  String get contactsQuickConnectHeader => 'দ্রুত সংযোগ';

  @override
  String get contactsNoSuggestions => 'বর্তমানে কোনো পরামর্শ উপলব্ধ নেই।';

  @override
  String get contactsLoadRequestsError => 'অনুরোধগুলি লোড করা যায়নি।';

  @override
  String contactsPendingRequestsHeader(int count) {
    return 'অপেক্ষমান অনুরোধ ($count)';
  }

  @override
  String get contactsNoPendingRequestsTitle => 'কোনো অপেক্ষমান অনুরোধ নেই';

  @override
  String get contactsNoPendingRequestsSubtitle =>
      'ব্যবহারকারীরা আপনাকে অনুরোধ পাঠালে সেগুলি এখানে প্রদর্শিত হবে।';

  @override
  String get contactsWantsToConnect => 'যুক্ত হতে চায়';

  @override
  String get contactsAcceptButton => 'গ্রহণ করুন';

  @override
  String get contactsAcceptFailed =>
      'অনুরোধ গ্রহণ করা যায়নি। পুনরায় চেষ্টা করুন।';

  @override
  String contactsConnectedWith(String name) {
    return '$name-এর সাথে যুক্ত হয়েছেন!';
  }

  @override
  String get contactsDeclineFailed =>
      'অনুরোধ প্রত্যাখ্যান করা যায়নি। পুনরায় চেষ্টা করুন।';

  @override
  String get contactsYouMightKnowHeader => 'পরিচিত হতে পারে';

  @override
  String get contactsSeeAll => 'সব দেখুন';

  @override
  String get contactsSearchHint => 'নাম, @হ্যান্ডেল, ফোন বা ইমেল খুঁজুন...';

  @override
  String get contactsTurnOnDiscoverability =>
      'অনুসন্ধান এবং পরামর্শে উপস্থিত হতে সন্ধানযোগ্যতা চালু করুন।';

  @override
  String get contactsNoMatchingUsersTitle => 'কোনো ব্যবহারকারী পাওয়া যায়নি';

  @override
  String get contactsNoMatchingUsersSubtitle =>
      '@username, ফোন বা ইমেল যাচাই করে পুনরায় চেষ্টা করুন।';

  @override
  String get contactsDiscoverHeroTitle => 'GupShupGo-তে মানুষ খুঁজুন';

  @override
  String get contactsDiscoverHeroSubtitle =>
      'সারা বিশ্ব জুড়ে আপনার পরিচিতির পরিধি বাড়ান।';

  @override
  String get contactsSyncDeviceContacts => 'ডিভাইস পরিচিতি সিঙ্ক করুন';

  @override
  String get contactsSyncingContacts => 'পরিচিতি সিঙ্ক হচ্ছে...';

  @override
  String get contactsSyncDeviceSubtitle =>
      'ফোন পরিচিতি থেকে বন্ধুদের তৎক্ষণাৎ খুঁজুন';

  @override
  String get contactsSuggestedUsersHeader => 'প্রস্তাবিত ব্যবহারকারী';

  @override
  String get contactsAddFriendButton => 'বন্ধু যোগ করুন';

  @override
  String get contactsRequestedButton => 'অনুরোধ পাঠানো হয়েছে';

  @override
  String contactsRequestSent(String name) {
    return '$name-কে বন্ধুত্বের অনুরোধ পাঠানো হয়েছে!';
  }

  @override
  String get contactsRequestFailed =>
      'অনুরোধটি ইতিমধ্যে অপেক্ষমাণ বা ব্যর্থ হয়েছে।';

  @override
  String get contactsRequestUnavailable => 'অনুরোধটি আর উপলব্ধ নেই।';

  @override
  String get profileEditTitle => 'প্রোফাইল সম্পাদনা';

  @override
  String get profileSaveButton => 'সংরক্ষণ';

  @override
  String get profileTapToChangePhoto => 'ছবি পরিবর্তন করতে স্পর্শ করুন';

  @override
  String get profileUpgradeToPro => 'প্রো-তে আপগ্রেড করুন';

  @override
  String get profileSectionName => 'আপনার নাম';

  @override
  String get profileNameHint => 'আপনার নাম লিখুন';

  @override
  String get profileSectionHandle => 'অনন্য হ্যান্ডেল';

  @override
  String get profileHandleNotSet => 'এখনও সেট করা হয়নি';

  @override
  String get profileChangeHandle => 'পরিবর্তন';

  @override
  String get profileSectionAbout => 'সম্পর্কে';

  @override
  String get profileAboutHint => 'আপনার মনে কি চলছে?';

  @override
  String get profileDefaultAbout => 'আরে! আমি GupShupGo ব্যবহার করছি।';

  @override
  String get profileSectionPhone => 'ফোন';

  @override
  String get profileSectionEmail => 'ইমেল';

  @override
  String get profileSectionLinkedMethods => 'সংযুক্ত সাইন-ইন মাধ্যম';

  @override
  String get profileNotLinked => 'সংযুক্ত নয়';

  @override
  String get profileNameEmpty => 'নাম খালি হতে পারে না।';

  @override
  String get profileUpdatedSuccess => 'প্রোফাইল আপডেট হয়েছে';

  @override
  String profileUploadPhotoFailed(String error) {
    return 'ছবি আপলোড করতে ব্যর্থ: $error';
  }

  @override
  String profileSaveFailed(String error) {
    return 'প্রোফাইল সংরক্ষণ করতে ব্যর্থ: $error';
  }

  @override
  String get profilePoints => 'পয়েন্ট';

  @override
  String get profileBadges => 'ব্যাজ';

  @override
  String get profileBestBond => 'সেরা বন্ধন';

  @override
  String get settingsAccountCard => 'অ্যাকাউন্ট';

  @override
  String get settingsProfileTile => 'প্রোফাইল';

  @override
  String get settingsLinkedMethodsTile => 'সংযুক্ত সাইন-ইন মাধ্যম';

  @override
  String get settingsPhoneTile => 'ফোন নম্বর';

  @override
  String get settingsEmailTile => 'ইমেল';

  @override
  String get settingsPrivacyCard => 'গোপনীয়তা';

  @override
  String get settingsDiscoverability => 'সন্ধানযোগ্যতা';

  @override
  String get settingsLastSeen => 'সর্বশেষ দেখা';

  @override
  String get settingsReadReceipts => 'পড়ার স্বীকৃতি';

  @override
  String get settingsAdPreferences => 'বিজ্ঞাপন পছন্দ';

  @override
  String get settingsManage => 'ব্যবস্থাপনা';

  @override
  String get settingsAppearanceCard => 'চেহারা';

  @override
  String get settingsTheme => 'থিম';

  @override
  String get settingsThemeLight => 'হালকা';

  @override
  String get settingsThemeDark => 'গাঢ়';

  @override
  String get settingsThemeSystem => 'সিস্টেম';

  @override
  String get settingsChatTheme => 'চ্যাট থিম';

  @override
  String get settingsHelpSecurityCard => 'সহায়তা ও নিরাপত্তা';

  @override
  String get settingsHelpCenter => 'সহায়তা কেন্দ্র';

  @override
  String get settingsReportProblem => 'সমস্যার কথা জানান';

  @override
  String get settingsE2EEShield => 'এন্ড-টু-এন্ড এনক্রিপশন (ভল্ট)';

  @override
  String get settingsVerifySafetyNumber => 'নিরাপত্তা নম্বর যাচাই করুন';

  @override
  String get settingsBlockedContacts => 'অবরুদ্ধ পরিচিতি';

  @override
  String get settingsClearAllGupHistory => 'সব চ্যাট ইতিহাস মুছুন';

  @override
  String get settingsRateUs => 'রেটিং দিন';

  @override
  String get settingsWhatsNew => 'নতুন কি আছে';

  @override
  String get settingsCheckForUpdates => 'আপডেট পরীক্ষা করুন';

  @override
  String get settingsAppInfo => 'অ্যাপ তথ্য';

  @override
  String get settingsLogOut => 'লগ আউট';

  @override
  String get settingsLogOutConfirmTitle => 'লগ আউট';

  @override
  String get settingsLogOutConfirmPrompt =>
      'আপনি কি নিশ্চিতভাবে GupShupGo থেকে লগ আউট করতে চান?';

  @override
  String get settingsSigningOut => 'লগ আউট হচ্ছে…';

  @override
  String get settingsClearChatsConfirmTitle => 'সমস্ত চ্যাট মুছুন';

  @override
  String get settingsClearChatsConfirmPrompt =>
      'এটি স্থায়ীভাবে আপনার বার্তার ইতিহাস মুছে ফেলবে। এটি ফিরিয়ে আনা যাবে না।';

  @override
  String get settingsDeleteAll => 'সব মুছুন';

  @override
  String get settingsClearingChats => 'চ্যাট মোছা হচ্ছে...';

  @override
  String get settingsAllChatsCleared => 'সব চ্যাট মুছে ফেলা হয়েছে';

  @override
  String settingsClearChatsFailed(String error) {
    return 'চ্যাট মুছতে ব্যর্থ: $error';
  }

  @override
  String get settingsChooseThemeTitle => 'থিম নির্বাচন করুন';

  @override
  String get settingsUnlockPremiumFeatures => 'প্রিমিয়াম ফিচার আনলক করুন';

  @override
  String settingsProDaysLeft(String planLabel, int daysRemaining) {
    return '$planLabel · $daysRemaining দিন বাকি';
  }

  @override
  String get settingsCheckingForUpdates => 'আপডেট পরীক্ষা করা হচ্ছে…';

  @override
  String settingsUpToDate(String version) {
    return 'আপনি সর্বশেষ সংস্করণে আছেন (v$version)।';
  }

  @override
  String get settingsUpdateCheckUnavailable =>
      'আপডেট চেক করা যায়নি। Google Play Store থেকে ইনস্টল করা নিশ্চিত করুন।';

  @override
  String get settingsNoBlockedContacts => 'কোনো অবরুদ্ধ পরিচিতি নেই';

  @override
  String get settingsUnblock => 'আনব্লক করুন';

  @override
  String settingsUserUnblocked(String name) {
    return '$name আনব্লক করা হয়েছে';
  }

  @override
  String get settingsVerifyContactTitle => 'পরিচিতি যাচাই করুন';

  @override
  String get settingsVerifyContactSubtitle =>
      'শেয়ার করা নিরাপত্তা নম্বর দেখতে একটি পরিচিতি বেছে নিন।';

  @override
  String get settingsComputingSafetyNumber => 'নিরাপত্তা নম্বর গণনা করা হচ্ছে…';

  @override
  String settingsSafetyNumberExplanation(String name) {
    return 'নিচের নম্বরটি $name-এর ডিভাইসের সাথে মিললে এনক্রিপশন যাচাইকৃত হয়।';
  }

  @override
  String get settingsSafetyNumberNoBundle =>
      'এই পরিচিতি এখনও কোনো এনক্রিপশন কী প্রকাশ করেনি।';

  @override
  String get settingsSafetyNumberCompareHint =>
      'ব্যক্তিগতভাবে বা বিশ্বস্ত কলে এই নম্বরটি মিলিয়ে নিন।';

  @override
  String get callEndToEndEncrypted => 'এন্ড-টু-এন্ড এনক্রিপ্ট করা';

  @override
  String get callSecuring => 'কল সুরক্ষিত করা হচ্ছে…';

  @override
  String get callNotEncrypted => 'এনক্রিপ্ট করা নয়';

  @override
  String get callIncomingVoice => 'ইনকামিং ভয়েস কল';

  @override
  String get callIncomingVideo => 'ইনকামিং ভিডিও কল';

  @override
  String get callVoiceCall => 'ভয়েস কল';

  @override
  String get callVideoCall => 'ভিডিও কল';

  @override
  String get callDecline => 'প্রত্যাখ্যান';

  @override
  String get callAccept => 'গ্রহণ করুন';

  @override
  String get callConnecting => 'সংযোগ করা হচ্ছে...';

  @override
  String get callSettingUp => 'কল সেটআপ করা হচ্ছে...';

  @override
  String callNotifying(String name) {
    return '$name-কে জানানো হচ্ছে...';
  }

  @override
  String get callRinging => 'বাজছে...';

  @override
  String get callConnected => 'সংযুক্ত';

  @override
  String get callOnHold => 'হোল্ডে আছে';

  @override
  String get callCalling => 'কল করা হচ্ছে...';

  @override
  String get callWaitingForUser => 'ব্যবহারকারীর জন্য অপেক্ষা করা হচ্ছে...';

  @override
  String get callEnded => 'কল সমাপ্ত';

  @override
  String get callDeclined => 'কল প্রত্যাখ্যান করা হয়েছে';

  @override
  String get callNoAnswer => 'কোনো উত্তর নেই';

  @override
  String get callFailedToConnect => 'সংযোগ করতে ব্যর্থ';

  @override
  String callFailedToStart(String error) {
    return 'কল শুরু করতে ব্যর্থ: $error';
  }

  @override
  String get callTokenExpired =>
      'টোকেন মেয়াদোত্তীর্ণ বা অবৈধ। কল পুনরায় চালু করুন।';

  @override
  String callFailedToInit(String type, String error) {
    return '$type কল আরম্ভ করতে ব্যর্থ: $error';
  }

  @override
  String get callTurnOffSpeaker => 'স্পিকার বন্ধ করুন';

  @override
  String get callTurnOnSpeaker => 'স্পিকার চালু করুন';

  @override
  String get callMuteMic => 'মাইক নিঃশব্দ করুন';

  @override
  String get callUnmuteMic => 'মাইক চালু করুন';

  @override
  String get callEndCall => 'কল শেষ করুন';

  @override
  String get callSwitchCamera => 'ক্যামেরা পরিবর্তন করুন';

  @override
  String get callTurnOffCamera => 'ক্যামেরা বন্ধ করুন';

  @override
  String get callTurnOnCamera => 'ক্যামেরা চালু করুন';

  @override
  String statusViewedByCount(int count) {
    return '$count জন দেখেছেন';
  }

  @override
  String get statusNoViewsYet => 'এখনো কোনো ভিউ নেই';

  @override
  String statusViewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count বার দেখা হয়েছে',
      one: '১ বার দেখা হয়েছে',
    );
    return '$_temp0';
  }

  @override
  String get statusDeleteTitle => 'স্ট্যাটাস মুছুন';

  @override
  String get statusDeleteConfirm =>
      'আপনি কি নিশ্চিতভাবে এই স্ট্যাটাস মুছতে চান?';

  @override
  String get statusDeleteButton => 'মুছুন';

  @override
  String get statusReplySent => 'উত্তর পাঠানো হয়েছে';

  @override
  String statusReplyFailed(String error) {
    return 'উত্তর পাঠাতে ব্যর্থ: $error';
  }

  @override
  String get statusNoActive => 'কোনো সক্রিয় স্ট্যাটাস নেই';

  @override
  String get statusCouldNotLoad => 'এই আপডেটটি লোড করা যায়নি';

  @override
  String get statusTapToRetry => 'আবার চেষ্টা করতে ট্যাপ করুন';

  @override
  String get statusFailedToLoadImage => 'ছবি লোড করতে ব্যর্থ';

  @override
  String get statusLoadingVideo => 'ভিডিও লোড হচ্ছে...';

  @override
  String get statusEnterTextPrompt => 'অনুগ্রহ করে কিছু লিখুন';

  @override
  String get statusNoContactsNotice =>
      'এখনো কোনো পরিচিতি নেই — স্ট্যাটাস দেওয়ার আগে চ্যাট শুরু করুন।';

  @override
  String statusPostFailed(String error) {
    return 'স্ট্যাটাস পোস্ট করতে ব্যর্থ: $error';
  }

  @override
  String get statusTypeHint => 'স্ট্যাটাস লিখুন...';

  @override
  String get statusCamera => 'ক্যামেরা';

  @override
  String get statusTakePhoto => 'ছবি তুলুন';

  @override
  String get statusGalleryPhoto => 'গ্যালারি ছবি';

  @override
  String get statusChooseImageGallery => 'গ্যালারি থেকে ছবি বেছে নিন';

  @override
  String get statusRecordVideo => 'ভিডিও রেকর্ড করুন';

  @override
  String get statusRecordShortVideo => 'ছোট ভিডিও রেকর্ড করুন';

  @override
  String get statusGalleryVideo => 'গ্যালারি ভিডিও';

  @override
  String get statusChooseVideoGallery => 'গ্যালারি থেকে ভিডিও বেছে নিন';

  @override
  String statusFailedPickImage(String error) {
    return 'ছবি নির্বাচনে ব্যর্থ: $error';
  }

  @override
  String statusFailedPickVideo(String error) {
    return 'ভিডিও নির্বাচনে ব্যর্থ: $error';
  }

  @override
  String get statusChangeBgColorTooltip => 'পটভূমির রঙ পরিবর্তন করুন';

  @override
  String aiMessagesRemaining(int count) {
    return '$countটি বাকি';
  }

  @override
  String get aiQuotaDialogTitle => 'GupAI বার্তা';

  @override
  String aiQuotaRemainingOfTotal(int remaining, int total) {
    return 'আজ $total-এর মধ্যে $remainingটি বাকি';
  }

  @override
  String aiQuotaUsedResetNote(int used) {
    return 'আজ $usedটি ব্যবহৃত · আগামীকাল রিসেট হবে। আরও পেতে বিজ্ঞাপন দেখুন বা প্রো নিন।';
  }

  @override
  String get aiQuotaGotIt => 'বুঝেছি';

  @override
  String get aiTitle => 'GupAI';

  @override
  String get aiSubtitle => 'আপনার অ্যাপ সহকারী';

  @override
  String get aiEmptyHelpTitle => 'আমি কীভাবে সাহায্য করতে পারি?';

  @override
  String get aiEmptyHelpSubtitle =>
      'খসড়া তৈরি করুন, অনুবাদ করুন, সারসংক্ষেপ করুন বা প্রশ্ন জিজ্ঞাসা করুন।';

  @override
  String get meshOfflineChatConnected => 'অফলাইন চ্যাট · সংযুক্ত';

  @override
  String get meshConnecting => 'সংযোগ করা হচ্ছে…';

  @override
  String get meshBannerNotice =>
      'অফলাইন চ্যাট — কোনো ইন্টারনেট নেই, কোনো সার্ভার নেই';

  @override
  String meshSayHiTo(String name) {
    return '$name-কে হাই বলুন';
  }

  @override
  String meshOfflineDescription(String name) {
    return 'আপনি অফলাইন চ্যাটে আছেন। বার্তাগুলো আপনার এবং $name-এর মধ্যেই থাকে।';
  }

  @override
  String get meshMediaUnavailable => 'এই মিডিয়া আর উপলব্ধ নেই।';

  @override
  String get meshViewOnceTitle => 'একবার দেখার মতো';

  @override
  String meshViewOncePrompt(String type) {
    return 'আপনি এই $type শুধুমাত্র একবার খুলতে পারবেন।';
  }

  @override
  String get arcadeTabOverview => 'ওভারভিউ';

  @override
  String get arcadeTabChallenges => 'চ্যালেঞ্জসমূহ';

  @override
  String get arcadeTabLeaderboard => 'লিডারবোর্ড';

  @override
  String get arcadeFailedLoadStats => 'পরিসংখ্যান লোড করতে ব্যর্থ।';

  @override
  String get aiAskHint => 'GupAI-কে যা খুশি জিজ্ঞেস করুন…';
}
