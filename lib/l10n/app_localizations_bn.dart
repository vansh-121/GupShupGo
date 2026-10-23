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
  String get homeNavChats => 'বার্তা';

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
  String get homeMenuPrivateVault => 'ব্যক্তিগত ভল্ট';

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
  String get attachmentScreenShare => 'স্ক্রিন শেয়ার করুন';

  @override
  String get attachmentScreenShareSubtitle =>
      'চ্যাটের সময় আপনার স্ক্রিন লাইভ দেখান';

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

  @override
  String get settingsNotificationsTile => 'বিজ্ঞপ্তি';

  @override
  String get settingsNotificationsStatusOn => 'চালু';

  @override
  String get settingsNotificationsStatusOff => 'বন্ধ';

  @override
  String get settingsNotificationsEnabledToast => 'বিজ্ঞপ্তি চালু আছে।';

  @override
  String get settingsEnableNotificationsTitle => 'বিজ্ঞপ্তি চালু করুন';

  @override
  String get settingsEnableNotificationsBody =>
      'বিজ্ঞপ্তি বন্ধ আছে। নতুন বার্তা ও কলের বিষয়ে GupShupGo থেকে বিজ্ঞপ্তি পেতে সিস্টেম সেটিংস খুলুন।';

  @override
  String get settingsOpenSystemSettings => 'সেটিংস খুলুন';

  @override
  String get loginTagline => 'ব্যক্তিগত মেসেজিং যা ইন্টারনেট ছাড়াও কাজ করে।';

  @override
  String get settingsPrivacyPolicy => 'গোপনীয়তা নীতি';

  @override
  String get settingsTerms => 'পরিষেবার শর্তাবলী';

  @override
  String get settingsDeleteAccount => 'অ্যাকাউন্ট মুছুন';

  @override
  String get inviteSheetTitle => 'বন্ধুদের আমন্ত্রণ জানান';

  @override
  String get inviteSheetSubtitle => 'সবাইকে জানান — GupShupGo শেয়ার করুন';

  @override
  String get inviteShareImageBtn => 'ছবি শেয়ার করুন';

  @override
  String get inviteShareLinkBtn => 'লিঙ্ক শেয়ার করুন';

  @override
  String get inviteCopyLinkBtn => 'লিঙ্ক কপি করুন';

  @override
  String get inviteLinkCopied => 'আমন্ত্রণ লিঙ্ক কপি করা হয়েছে';

  @override
  String inviteMessage(String link) {
    return 'GupShupGo-তে আমার সাথে চ্যাট করুন — এটি ইন্টারনেট ছাড়াও কাজ করে 👋 $link';
  }

  @override
  String get inviteCardTagline => 'ব্যক্তিগত চ্যাট যা অফলাইনেও কাজ করে';

  @override
  String get inviteCardScan => 'ডাউনলোড করতে স্ক্যান করুন';

  @override
  String get inviteCardDownload => 'Google Play-তে ডাউনলোড করুন';

  @override
  String get homeMenuInvite => 'বন্ধুদের আমন্ত্রণ জানান';

  @override
  String get invitePromptTitle => 'GupShupGo কেমন লাগছে?';

  @override
  String get invitePromptBody =>
      'বন্ধুদের সাথে এটি আরও ভালো — এবং ইন্টারনেট ছাড়াও কাজ করে। কাউকে আমন্ত্রণ জানাবেন?';

  @override
  String get invitePromptInvite => 'বন্ধুদের আমন্ত্রণ জানান';

  @override
  String get invitePromptLater => 'পরে হতে পারে';

  @override
  String get homeOfflineBannerTitle => 'ইন্টারনেট নেই? সমস্যা নেই';

  @override
  String get homeOfflineBannerSubtitle =>
      'আপনি এখনও ব্লুটুথের মাধ্যমে আশেপাশের লোকদের বার্তা পাঠাতে পারেন।';

  @override
  String homeNearbyBannerTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'কাছে $count জন ব্যক্তি',
      one: 'কাছে ১ জন ব্যক্তি',
    );
    return '$_temp0';
  }

  @override
  String get homeNearbyBannerSubtitle =>
      'ব্লুটুথের মাধ্যমে চ্যাট করুন — ইন্টারনেটের প্রয়োজন নেই।';

  @override
  String get linkBackupTitle => 'একটি ব্যাকআপ সাইন-ইন পদ্ধতি যোগ করুন';

  @override
  String get linkBackupSubtitle =>
      'Google বা ইমেল লিঙ্ক করুন যাতে সিম না থাকলেও আপনি ফিরে আসতে পারেন।';

  @override
  String get linkGoogleTitle => 'Google অ্যাকাউন্ট লিঙ্ক করুন';

  @override
  String get linkGoogleSubtitleLinked => 'সংযুক্ত ✓';

  @override
  String get linkGoogleSubtitleUnlinked => 'সিম ছাড়া ওয়ান-ট্যাপ সাইন-ইন';

  @override
  String get linkGoogleAction => 'লিঙ্ক করুন';

  @override
  String get linkGoogleSuccess => 'Google অ্যাকাউন্ট সফলভাবে লিঙ্ক হয়েছে!';

  @override
  String get linkGoogleAlreadyUsed =>
      'এই Google অ্যাকাউন্টটি ইতিমধ্যে একটি পৃথক অ্যাকাউন্ট হিসাবে নিবন্ধিত।';

  @override
  String get linkGoogleFailed =>
      'Google লিঙ্কিং ব্যর্থ হয়েছে। আবার চেষ্টা করুন।';

  @override
  String get linkSessionExpired =>
      'সেশন শেষ হয়েছে। অনুগ্রহ করে আবার সাইন ইন করুন।';

  @override
  String get linkEmailTitle => 'ইমেল ও পাসওয়ার্ড লিঙ্ক করুন';

  @override
  String get linkEmailSubtitleLinked => 'সংযুক্ত ✓';

  @override
  String get linkEmailSubtitleUnlinked =>
      'সিম বা Google না থাকলে ইমেল দিয়ে সাইন ইন করুন';

  @override
  String get linkEmailActionAdd => 'যোগ করুন';

  @override
  String get linkEmailActionCancel => 'বাতিল';

  @override
  String get linkEmailFieldLabel => 'ইমেল';

  @override
  String get linkPasswordFieldLabel => 'একটি পাসওয়ার্ড তৈরি করুন';

  @override
  String get linkPasswordHelper => 'কমপক্ষে ৬টি অক্ষর';

  @override
  String get linkEmailButton => 'ইমেল লিঙ্ক করুন';

  @override
  String get linkEmailSuccess => 'ইমেল সফলভাবে লিঙ্ক হয়েছে!';

  @override
  String get linkEmailInvalid => 'একটি বৈধ ইমেল ঠিকানা লিখুন।';

  @override
  String get linkPasswordTooShort => 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে।';

  @override
  String get linkEmailAlreadyInUse =>
      'এই ইমেলটি ইতিমধ্যে GupShupGo-তে পৃথকভাবে নিবন্ধিত।';

  @override
  String get linkEmailAlreadyLinked =>
      'আপনার অ্যাকাউন্টে ইতিমধ্যে একটি ইমেল লিঙ্ক করা আছে।';

  @override
  String get linkEmailFailed => 'ইমেল লিঙ্কিং ব্যর্থ হয়েছে।';

  @override
  String get linkContinueToApp => 'অ্যাপে এগিয়ে যান';

  @override
  String get linkSkipForNow => 'এখনকার মতো এড়িয়ে যান';

  @override
  String get linkSkip => 'এড়িয়ে যান';

  @override
  String get phoneAuthTitleEntry => 'আপনার ফোন নম্বর দিয়ে সাইন ইন করুন।';

  @override
  String get phoneAuthTitleOtp => 'আমরা পাঠানো কোডটি লিখুন।';

  @override
  String get phoneAuthNameHint => 'আপনার নাম';

  @override
  String get phoneAuthPhoneHint => 'ফোন নম্বর';

  @override
  String get phoneAuthUseSim => 'সিম ব্যবহার করুন';

  @override
  String get phoneAuthSendOtp => 'ওটিপি পাঠান';

  @override
  String phoneAuthOtpPrompt(String phone) {
    return '$phone নম্বরে পাঠানো ৬-সংখ্যার কোডটি লিখুন';
  }

  @override
  String get phoneAuthOtpPromptGeneric => 'আমাদের পাঠানো ৬-সংখ্যার কোডটি লিখুন';

  @override
  String get phoneAuthOtpHint => 'কোড লিখুন';

  @override
  String get phoneAuthVerify => 'যাচাই করুন';

  @override
  String get phoneAuthGoBack => 'ফিরে যান';

  @override
  String get phoneAuthResendCode => 'কোড পুনরায় পাঠান';

  @override
  String get phoneAuthEnterName => 'অনুগ্রহ করে আপনার নাম লিখুন';

  @override
  String get phoneAuthEnterValidPhone => 'একটি বৈধ ফোন নম্বর লিখুন';

  @override
  String get phoneAuthEnterCode => 'অনুগ্রহ করে কোডটি লিখুন';

  @override
  String get phoneAuthRequestNewCode =>
      'অনুগ্রহ করে একটি নতুন কোডের অনুরোধ করুন।';

  @override
  String get phoneAuthCodeIncorrect => 'সেই কোডটি ভুল। আবার চেষ্টা করুন।';

  @override
  String get phoneAuthErrCodeIncorrect =>
      'কোডটি ভুল। অনুগ্রহ করে দেখে আবার চেষ্টা করুন।';

  @override
  String get phoneAuthErrCodeExpired =>
      'কোডের মেয়াদ শেষ হয়েছে। পুনরায় পাঠান।';

  @override
  String get phoneAuthErrTooManyRequests =>
      'অতিরিক্ত প্রচেষ্টা। অনুগ্রহ করে কিছুক্ষণ অপেক্ষা করুন।';

  @override
  String get phoneAuthErrInvalidPhone => 'ফোন নম্বরটি অবৈধ মনে হচ্ছে।';

  @override
  String get phoneAuthErrQuotaExceeded => 'এসএমএস সীমা পূর্ণ হয়েছে।';

  @override
  String get phoneAuthErrFailed => 'যাচাইকরণ ব্যর্থ হয়েছে।';

  @override
  String get usernameSetupAppBarTitle => 'আপনার হ্যান্ডেল বেছে নিন';

  @override
  String get usernameSetupHeaderTitle => 'আপনার পরিচয় সুরক্ষিত করুন';

  @override
  String get usernameSetupHeaderDesc =>
      'আপনার @handle হল GupShupGo-তে আপনার অনন্য চাবিকাঠি। অন্য ব্যবহারকারীরা ফোন বা ইমেল ছাড়া নিরাপদে আপনাকে খুঁজে পেতে পারেন।';

  @override
  String get usernameSetupInputHint => 'your_handle';

  @override
  String get usernameSetupChecking => 'উপলব্ধতা যাচাই করা হচ্ছে...';

  @override
  String usernameSetupAvailable(String handle) {
    return '@$handle উপলব্ধ!';
  }

  @override
  String usernameSetupTaken(String handle) {
    return '@$handle ইতিমধ্যে অন্য কেউ নিয়েছে।';
  }

  @override
  String get usernameSetupCharRules => '৩–২০টি অক্ষর (a-z, 0-9, _)';

  @override
  String get usernameSetupTooShort => 'হ্যান্ডেল কমপক্ষে ৩ অক্ষরের হতে হবে।';

  @override
  String get usernameSetupTooLong => 'হ্যান্ডেল সর্বাধিক ২০ অক্ষরের হতে পারে।';

  @override
  String get usernameSetupInvalidChars =>
      'শুধুমাত্র বর্ণ, সংখ্যা এবং আন্ডারস্কোর অনুমোদিত।';

  @override
  String get usernameSetupRecommended => 'আপনার জন্য প্রস্তাবিত';

  @override
  String get usernameSetupSaveBtn => 'সংরক্ষণ করুন ও চালিয়ে যান';

  @override
  String get usernameSetupSkipBtn => 'এখনকার মতো এড়িয়ে যান';

  @override
  String usernameSetupFailed(String error) {
    return 'ইউজারনেম সেট করা ব্যর্থ হয়েছে: $error';
  }

  @override
  String get vaultProtectTitle => 'ভল্ট সুরক্ষিত করুন';

  @override
  String get vaultUnlockTitle => 'ভল্ট আনলক করুন';

  @override
  String get vaultSetupDesc =>
      'মেসেজ ইতিহাস এনক্রিপ্ট করতে একটি পিন বেছে নিন। নতুন ফোনে বার্তা পড়তে এটির প্রয়োজন হবে।';

  @override
  String get vaultUnlockDescBio =>
      'ইতিহাস ডিক্রিপ্ট করতে পিন লিখুন বা আঙুলের ছাপ স্পর্শ করুন।';

  @override
  String get vaultUnlockDescPin => 'ইতিহাস ডিক্রিপ্ট করতে আপনার পিন লিখুন।';

  @override
  String get vaultReinstallHint =>
      'ইতিহাস পুনরুদ্ধার করতে আপনার পিন দিন। পরে আবার ফিঙ্গারপ্রিন্ট চালু করতে পারবেন।';

  @override
  String get vaultUnlockWithFingerprint => 'ফিঙ্গারপ্রিন্ট দিয়ে আনলক করুন';

  @override
  String get vaultOrDivider => 'অথবা';

  @override
  String get vaultNewPin => 'নতুন পিন';

  @override
  String get vaultConfirmPin => 'পিন নিশ্চিত করুন';

  @override
  String get vaultEnterPin => 'পিন লিখুন';

  @override
  String get vaultKeyboardUseLetters => 'অক্ষর ব্যবহার করুন';

  @override
  String get vaultKeyboardUseNumbers => 'সংখ্যা ব্যবহার করুন';

  @override
  String get vaultRestoreLater => 'পরে পুনরুদ্ধার করুন';

  @override
  String get vaultForgotPin => 'পিন ভুলে গেছেন?';

  @override
  String get vaultSetPinBtn => 'পিন সেট করুন';

  @override
  String get vaultDecryptBtn => 'ডিক্রিপ্ট করুন';

  @override
  String get vaultPinMinLength => 'পিন কমপক্ষে ৬ অক্ষরের হতে হবে।';

  @override
  String get vaultPinsDoNotMatch => 'পিন মিলছে না।';

  @override
  String get vaultSetupFailed => 'সেটআপ ব্যর্থ হয়েছে।';

  @override
  String get vaultIncorrectPin => 'ভুল পিন। আবার চেষ্টা করুন।';

  @override
  String get vaultFingerprintOutOfDate =>
      'ফিঙ্গারপ্রিন্ট পুরনো হয়ে গেছে। পিন লিখুন।';

  @override
  String get vaultBiometricError => 'বায়োমেট্রিক ত্রুটি। পিন লিখুন।';

  @override
  String get vaultBioReasonUnlock => 'ভল্ট আনলক করতে বায়োমেট্রিক ব্যবহার করুন';

  @override
  String get vaultBioReasonEnrol =>
      'দ্রুত আনলক সক্ষম করতে আঙুলের ছাপ নিশ্চিত করুন';

  @override
  String get vaultAskBioTitle => 'ফিঙ্গারপ্রিন্ট দিয়ে আনলক করবেন?';

  @override
  String get vaultAskBioDesc =>
      'এই ফোনে পিন টাইপ করা এড়িয়ে যান। তবে পিনটি মনে রাখবেন, নতুন ফোনে এটি লাগবে।';

  @override
  String get vaultAskBioNotNow => 'এখন নয়';

  @override
  String get vaultAskBioEnable => 'চালু করুন';

  @override
  String get vaultDeleteMessagesTitle => 'সব বার্তা মুছে ফেলবেন?';

  @override
  String get vaultDeleteMessagesDesc =>
      'পিন ছাড়া আপনার ইতিহাস ডিক্রিপ্ট করা সম্ভব নয়, তাই রিসেট করলে সবকিছু মুছে যাবে। এটি পূর্বাবস্থায় ফেরানো যাবে না।';

  @override
  String get vaultDeleteMessagesCancel => 'বাতিল';

  @override
  String get vaultDeleteMessagesConfirm => 'সব মুছুন';

  @override
  String get vaultCustodyConfirmTitle => 'ভল্ট পিন নিশ্চিত করুন';

  @override
  String get vaultCustodyChooseTitle => 'একটি পিন বেছে নিন';

  @override
  String get vaultCustodyConfirmDesc =>
      'আপনার বার্তা ইতিহাস একটি পিন দিয়ে এনক্রিপ্ট করা হয়েছে। একবার নিশ্চিত করুন।';

  @override
  String get vaultCustodyChooseDesc =>
      'একটি স্মরণীয় পিন বেছে নিন। সব পুরোনো বার্তা নতুন পিনে এনক্রিপ্ট হবে।';

  @override
  String get vaultCustodyDontKnow => 'আমি পিন জানি না';

  @override
  String get vaultCustodyConfirmBtn => 'নিশ্চিত করুন';

  @override
  String get vaultCustodySaveBtn => 'পিন সংরক্ষণ করুন';

  @override
  String get vaultCustodyMismatchError => 'পিন মিলছে না।';

  @override
  String get vaultCustodyAutoUpdateFailed =>
      'স্বয়ংক্রিয়ভাবে পিন আপডেট করা যায়নি।';

  @override
  String vaultCustodyReencrypting(int done, int total) {
    return '$total-এর মধ্যে $doneটি পুনরায় এনক্রিপ্ট হচ্ছে… অ্যাপ খোলা রাখুন।';
  }

  @override
  String get vaultCustodyPreparing => 'প্রস্তুত হচ্ছে… অ্যাপ খোলা রাখুন।';

  @override
  String get vaultSettingsTitle => 'ভল্ট';

  @override
  String get vaultSettingsAboutTitle => 'ভল্ট সম্পর্কে';

  @override
  String get vaultSettingsAboutDesc =>
      'আপনার চ্যাট ইতিহাসের একটি ব্যক্তিগত ব্যাকআপ। শুধুমাত্র আপনার পিন এটি খুলতে পারে — আমরাও নয়।';

  @override
  String get vaultSettingsBulletMessages => 'আপনার বার্তা';

  @override
  String get vaultSettingsBulletStatuses => 'যে স্ট্যাটাসগুলি আপনি দেখতে পারেন';

  @override
  String get vaultSettingsNeverKept =>
      'এখানে রাখা হয় না: কল ইতিহাস, পরিচিতি বা অন্যদের ব্যক্তিগত বার্তা।';

  @override
  String get vaultSettingsSectionPrivacy => 'গোপনীয়তা';

  @override
  String get vaultSettingsAutoDelete => 'পুরোনো বার্তা স্বয়ংক্রিয়ভাবে মুছুন';

  @override
  String get vaultSettingsKeepForever => 'চিরকাল রাখুন';

  @override
  String vaultSettingsDeleteAfter(String label) {
    return '$label পর মুছুন';
  }

  @override
  String get vaultSettingsSectionPin => 'পিন';

  @override
  String get vaultSettingsChangePin => 'পিন পরিবর্তন করুন';

  @override
  String get vaultSettingsChangePinSubtitle =>
      'ভল্টের প্রতিটি এন্ট্রি পুনরায় এনক্রিপ্ট করে';

  @override
  String get vaultSettingsBioTitle => 'ফিঙ্গারপ্রিন্ট দিয়ে আনলক করুন';

  @override
  String get vaultSettingsBioSubOn => 'এই ডিভাইসে চালু';

  @override
  String get vaultSettingsBioSubOff => 'পিন টাইপ করা এড়িয়ে যান';

  @override
  String get vaultSettingsSectionDanger => 'বিপদ অঞ্চল';

  @override
  String get vaultSettingsDeleteData => 'ভল্ট ডেটা মুছুন';

  @override
  String get vaultSettingsDeleteDataSubtitle =>
      'এনক্রিপ্ট করা ইতিহাস মোছে, পিন রাখে';

  @override
  String get vaultSettingsResetVault => 'ভল্ট রিসেট করুন';

  @override
  String get vaultSettingsResetVaultSubtitle =>
      'পিন ভুলে যায় ও সবকিছু মুছে ফেলে';

  @override
  String get vaultSettingsPinChanged => 'পিন পরিবর্তিত হয়েছে।';

  @override
  String get vaultSettingsBioTurnedOff => 'ফিঙ্গারপ্রিন্ট বন্ধ করা হয়েছে।';

  @override
  String get vaultSettingsBioTurnedOn => 'ফিঙ্গারপ্রিন্ট সক্ষম করা হয়েছে।';

  @override
  String get vaultSettingsClearDataTitle => 'ভল্ট ডেটা মুছবেন?';

  @override
  String get vaultSettingsClearDataDesc =>
      'ক্লাউড ভল্ট থেকে সমস্ত এনক্রিপ্ট করা বার্তা মুছে দেয়। পিন অপরিবর্তিত থাকবে।';

  @override
  String get vaultSettingsClearDataCancel => 'বাতিল';

  @override
  String get vaultSettingsClearDataConfirm => 'ডেটা মুছুন';

  @override
  String get vaultSettingsDataDeleted => 'ভল্ট ডেটা মুছে ফেলা হয়েছে।';

  @override
  String get vaultSettingsResetTitle => 'ভল্ট রিসেট করবেন?';

  @override
  String get vaultSettingsResetDesc =>
      'সবকিছু মুছে ফেলে। আপনাকে নতুন পিন সেট করতে হবে।';

  @override
  String get vaultSettingsResetConfirm => 'রিসেট';

  @override
  String get vaultSettingsChangeDialogDesc =>
      'প্রতিটি এন্ট্রি নতুন পিনে এনক্রিপ্ট হবে। অ্যাপটি খোলা রাখুন।';

  @override
  String get vaultSettingsCurrentPin => 'বর্তমান পিন';

  @override
  String get vaultSettingsNewPin => 'নতুন পিন';

  @override
  String get vaultSettingsConfirmNewPin => 'নতুন পিন নিশ্চিত করুন';

  @override
  String get vaultSettingsEnterCurrentPin => 'বর্তমান পিন লিখুন।';

  @override
  String get vaultSettingsNewPinMinLength =>
      'নতুন পিন কমপক্ষে ৬ অক্ষরের হতে হবে।';

  @override
  String get vaultSettingsNewPinMismatch => 'নতুন পিন মিলছে না।';

  @override
  String get vaultSettingsCurrentPinIncorrect => 'বর্তমান পিন ভুল।';

  @override
  String vaultSettingsReencryptingCount(int done, int total) {
    return '$total-এর মধ্যে $doneটি পুনরায় এনক্রিপ্ট হচ্ছে…';
  }

  @override
  String get vaultSettingsChangeBtn => 'পরিবর্তন করুন';

  @override
  String get vaultSettingsBioPinDialogTitle => 'আপনার পিন লিখুন';

  @override
  String get vaultSettingsBioPinDialogDesc =>
      'ফিঙ্গারপ্রিন্ট সক্ষম করতে আপনার বর্তমান পিনটি প্রয়োজন।';

  @override
  String get vaultSettingsContinueBtn => 'চালিয়ে যান';

  @override
  String get premiumTitle => 'GupShupGo প্রো';

  @override
  String get premiumSubtitleMember => 'আপনি একজন প্রো সদস্য! 🎉';

  @override
  String get premiumSubtitleUnlock => 'সম্পূর্ণ অভিজ্ঞতা আনলক করুন';

  @override
  String premiumActiveDaysRemaining(int days) {
    return '$days দিন বাকি';
  }

  @override
  String get premiumFeaturesHeader => 'প্রো-তে যা যা পাচ্ছেন';

  @override
  String get premiumPlansHeader => 'আপনার প্ল্যান বেছে নিন';

  @override
  String get premiumSubscribeBtn => 'এখনই সাবস্ক্রাইব করুন';

  @override
  String get premiumCancelAnytime => 'Google Play থেকে যেকোনো সময় বাতিলযোগ্য।';

  @override
  String get premiumRestoreBtn => 'পূর্বের কেনাকাটা পুনরুদ্ধার করুন';

  @override
  String get premiumRestoring => 'পুনরুদ্ধার করা হচ্ছে…';

  @override
  String get premiumRestoredSuccess =>
      'প্রো সাবস্ক্রিপশন পুনরুদ্ধার হয়েছে! 🎉';

  @override
  String get premiumNoActiveSub => 'কোনো সক্রিয় সাবস্ক্রিপশন পাওয়া যায়নি।';

  @override
  String get premiumProductUnavailable =>
      'পণ্যটি উপলব্ধ নয়। ইন্টারনেট সংযোগ পরীক্ষা করুন।';

  @override
  String get premiumFeatureMediaTitle => 'মিডিয়া মোমেন্টস';

  @override
  String get premiumFeatureMediaDesc =>
      'স্ট্যাটাস আপডেট হিসেবে ছবি ও ভিডিও শেয়ার করুন';

  @override
  String get premiumFeatureMediaFree => 'কেবল টেক্সট';

  @override
  String get premiumFeatureMediaPro => 'ছবি + ভিডিও';

  @override
  String get premiumFeatureScreenShareTitle => 'স্ক্রিন শেয়ারিং';

  @override
  String get premiumFeatureScreenShareDesc =>
      'চ্যাট চলাকালীন লাইভ স্ক্রিন শেয়ার করুন';

  @override
  String get premiumFeatureScreenShareFree => 'লক করা';

  @override
  String get premiumFeatureScreenSharePro => 'সম্পূর্ণ অ্যাক্সেস';

  @override
  String get premiumFeatureThemesTitle => 'চ্যাট থিম';

  @override
  String get premiumFeatureThemesDesc =>
      'প্রতি চ্যাটের জন্য বিশেষ ব্যাকগ্রাউন্ড ও বাবল';

  @override
  String get premiumFeatureThemesFree => '৬টি থিম';

  @override
  String get premiumFeatureThemesPro => 'সব ১২টি + নিজস্ব ছবি';

  @override
  String get premiumFeatureVoiceTitle => 'দীর্ঘ ভয়েস বার্তা';

  @override
  String get premiumFeatureVoiceDesc => 'দীর্ঘ ভয়েস নোট রেকর্ড করুন';

  @override
  String get premiumFeatureVoiceFree => '২ মিনিট';

  @override
  String get premiumFeatureVoicePro => 'সীমাহীন';

  @override
  String get premiumFeatureQualityTitle => 'উচ্চ মানের মিডিয়া';

  @override
  String get premiumFeatureQualityDesc =>
      'তীক্ষ্ণ ছবি এবং ৯০ সেকেন্ডের স্ট্যাটাস ভিডিও';

  @override
  String get premiumFeatureQualityFree => 'সাধারণ মান';

  @override
  String get premiumFeatureQualityPro => 'উচ্চ মান + ৯০সে. ভিডিও';

  @override
  String get premiumFeatureBondTitle => 'বন্ড পুনরুদ্ধার';

  @override
  String get premiumFeatureBondDesc => 'ভাঙা বন্ড বিনামূল্যে পুনরুদ্ধার করুন';

  @override
  String get premiumFeatureBondFree => 'পয়েন্ট বা বিজ্ঞাপন';

  @override
  String get premiumFeatureBondPro => 'সপ্তাহে ১টি ফ্রি পুনরুদ্ধার';

  @override
  String get premiumFeatureBadgeTitle => 'প্রো ব্যাজ';

  @override
  String get premiumFeatureBadgeDesc => 'আপনার প্রো স্ট্যাটাস প্রদর্শন করুন';

  @override
  String get premiumFeatureBadgeFree => 'কোনো ব্যাজ নেই';

  @override
  String get premiumFeatureBadgePro => 'বিশেষ প্রো ব্যাজ';

  @override
  String get premiumFeatureExportTitle => 'চ্যাট এক্সপোর্ট';

  @override
  String get premiumFeatureExportDesc =>
      'পিডিএফ বা টেক্সট হিসেবে চ্যাট সংরক্ষণ করুন';

  @override
  String get premiumFeatureExportFree => 'উপলব্ধ নয়';

  @override
  String get premiumFeatureExportPro => 'পিডিএফ ও টিএক্সটি এক্সপোর্ট';

  @override
  String get premiumFeatureAdFreeTitle => 'বিজ্ঞাপনমুক্ত অভিজ্ঞতা';

  @override
  String get premiumFeatureAdFreeDesc => 'অ্যাপে কোনো ব্যানার বিজ্ঞাপন নেই';

  @override
  String get premiumFeatureAdFreeFree => 'ব্যানার বিজ্ঞাপন থাকে';

  @override
  String get premiumFeatureAdFreePro => 'ব্যানার নেই';

  @override
  String get premiumPlanMonthly => 'মাসিক';

  @override
  String get premiumPlanYearly => 'বার্ষিক';

  @override
  String get premiumPlanSavings => '~৩৩% সাশ্রয়';

  @override
  String get premiumPeriodMonth => '/মাস';

  @override
  String get premiumPeriodYear => '/বছর';

  @override
  String get nearbyOfflineChatTitle => 'অফলাইন চ্যাট';

  @override
  String get nearbySearchingDevices => 'কাছাকাছি ডিভাইস খোঁজা হচ্ছে…';

  @override
  String get nearbyTooltipStop => 'অফলাইন চ্যাট বন্ধ করুন';

  @override
  String get nearbyTooltipStart => 'অফলাইন চ্যাট শুরু করুন';

  @override
  String get nearbyDevicesSection => 'কাছাকাছি ডিভাইস';

  @override
  String get nearbyDiscoveryOn => 'খোঁজ চালু';

  @override
  String get nearbyDiscoveryOff => 'খোঁজ বন্ধ';

  @override
  String get nearbyHeroTitle => 'অফলাইন মোড';

  @override
  String nearbyHeroNearbyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি কাছাকাছি',
      one: '১টি কাছাকাছি',
    );
    return '$_temp0';
  }

  @override
  String get nearbyHeroOff => 'অফলাইন চ্যাট বন্ধ';

  @override
  String get nearbyHeroDesc =>
      '১০০ মিটারের মধ্যে ডিভাইস স্ক্যান করা হচ্ছে। ইন্টারনেট ছাড়াই ব্লুটুথে এনক্রিপ্ট করা চ্যাট।';

  @override
  String get nearbyYourNameHint => 'আপনার নাম';

  @override
  String get nearbyEmptySearching => 'কাছাকাছি ডিভাইস খোঁজা হচ্ছে…';

  @override
  String get nearbyEmptyOff => 'অফলাইন চ্যাট বন্ধ আছে';

  @override
  String get nearbyEmptySearchingDesc =>
      'অন্যান্য ডিভাইসে ব্লুটুথ চালু রেখে GupShupGo খোলা রাখুন।';

  @override
  String get nearbyEmptyOffDesc =>
      'স্ক্যান শুরু করতে স্টার্ট আইকন স্পর্শ করুন।';

  @override
  String get nearbyPeerConnected => 'সংযুক্ত · চ্যাট করতে ট্যাপ করুন';

  @override
  String get nearbyPeerConnecting => 'সংযুক্ত হচ্ছে…';

  @override
  String get nearbyPeerTapToConnect => 'সংযুক্ত হতে ট্যাপ করুন';

  @override
  String get nearbyActionChat => 'চ্যাট';

  @override
  String get nearbyActionConnecting => 'সংযোগ হচ্ছে';

  @override
  String get nearbyActionConnect => 'যুক্ত হন';

  @override
  String get nearbyPermNeededTitle => 'অনুমতি প্রয়োজন';

  @override
  String get nearbyPermNeededDesc =>
      'ইন্টারনেট ছাড়া চ্যাট করতে ব্লুটুথ ও কাছাকাছি ডিভাইসের অনুমতি প্রয়োজন।';

  @override
  String get nearbyTryAgainBtn => 'আবার চেষ্টা করুন';

  @override
  String get nearbySettingsBtn => 'সেটিংস';

  @override
  String get nearbyHelpTip =>
      'বন্ধু দেখতে পাচ্ছেন না? দুজনের ডিভাইসেই ব্লুটুথ চালু আছে কিনা নিশ্চিত করুন।';

  @override
  String get anonLobbyTitle => 'অজ্ঞাতনামা চ্যাট';

  @override
  String get anonLobbyFinding => 'আপনার জন্য কাউকে খোঁজা হচ্ছে…';

  @override
  String get anonLobbyHangTight =>
      'একটু অপেক্ষা করুন — একজন অপরিচিত ব্যক্তির সাথে আপনাকে যুক্ত করা হবে।';

  @override
  String get anonLobbyCancelBtn => 'অনুসন্ধান বাতিল';

  @override
  String get anonLobbyPrivacyNote =>
      'আপনার পরিচয় গোপন থাকে। অপরিচিত হিসেবে চ্যাট করুন।';

  @override
  String get anonLobbyConnecting => 'সংযোগ হচ্ছে…';

  @override
  String get anonLobbyWaitingOthers => 'অন্যদের অনলাইনে আসার অপেক্ষা…';

  @override
  String anonLobbyOnlineCount(int count) {
    return '$count জন এখন অনলাইনে';
  }

  @override
  String get anonChatNotEncrypted =>
      'এই বার্তাগুলি এন্ড-টু-এন্ড এনক্রিপ্ট করা নয়';

  @override
  String get anonChatRequestSentTooltip => 'অনুরোধ পাঠানো হয়েছে';

  @override
  String get anonChatAddFriendTooltip => 'বন্ধু হিসেবে যোগ করুন';

  @override
  String get anonChatNextStrangerTooltip => 'পরবর্তী অপরিচিত';

  @override
  String get anonChatReportTooltip => 'রিপোর্ট করুন';

  @override
  String get anonChatSayHi => 'অপরিচিতকে হ্যালো বলুন! 👋';

  @override
  String get anonChatFriendsTransition =>
      'আপনারা এখন বন্ধু! সুরক্ষিত চ্যাট খুলছে…';

  @override
  String get anonChatStrangerDisconnected =>
      'অপরিচিত সংযোগ বিচ্ছিন্ন করেছেন 👋';

  @override
  String get anonChatFindNextBtn => 'পরবর্তী অপরিচিত খুঁজুন';

  @override
  String get anonChatFriendReqTitle => 'অপরিচিত যুক্ত হতে চান!';

  @override
  String get anonChatFriendReqDesc =>
      'অনুরোধ গ্রহণ করলে পরিচয় প্রকাশ পাবে এবং এনক্রিপ্ট করা চ্যাট শুরু হবে।';

  @override
  String get anonChatDecline => 'প্রত্যাখ্যান';

  @override
  String get anonChatAccept => 'গ্রহণ করুন';

  @override
  String get anonChatWaitingReqTitle => 'বন্ধুত্বের অনুরোধ পাঠানো হয়েছে';

  @override
  String get anonChatWaitingReqDesc => 'অপরিচিত ব্যক্তির উত্তরের অপেক্ষা…';

  @override
  String get anonChatReportTitle => 'অপরিচিতর বিরুদ্ধে রিপোর্ট';

  @override
  String get anonChatReportQuestion =>
      'কেন আপনি এই ব্যবহারকারীর রিপোর্ট করছেন?';

  @override
  String get anonChatReportReasonInappropriate => 'অনুপযুক্ত বিষয়বস্তু';

  @override
  String get anonChatReportReasonHarassment => 'হয়রানি বা অপমান';

  @override
  String get anonChatReportReasonSpam => 'স্প্যাম বা প্রতারণা';

  @override
  String get anonChatReportReasonThreatening => 'হুমকিজনক আচরণ';

  @override
  String get anonChatReportReasonOther => 'অন্যান্য';

  @override
  String get anonChatReportCancel => 'বাতিল';

  @override
  String get anonChatReportSubmit => 'রিপোর্ট ও প্রস্থান';

  @override
  String get anonChatReportSubmitted => 'রিপোর্ট জমা দেওয়া হয়েছে।';

  @override
  String get anonChatViewOnceVideoTitle => 'একবার চালাবেন?';

  @override
  String get anonChatViewOncePhotoTitle => 'একবার খুলবেন?';

  @override
  String get anonChatViewOnceVideoDesc =>
      'এই ভিডিওটি কেবল একবার দেখা যাবে। বন্ধ করলে এটি মুছে যাবে।';

  @override
  String get anonChatViewOncePhotoDesc =>
      'এই ছবিটি কেবল একবার দেখা যাবে। বন্ধ করলে এটি মুছে যাবে।';

  @override
  String get anonChatViewOnceCancel => 'বাতিল';

  @override
  String get anonChatViewOnceOpen => 'খুলুন';

  @override
  String get unsupportedVersionTitle => 'GupShupGo আপডেট করুন';

  @override
  String get unsupportedVersionDesc =>
      'এই সংস্করণটি আর সমর্থিত নয়। নতুন সংস্করণে আপডেট করুন।';

  @override
  String get unsupportedVersionUpdateNow => 'এখনই আপডেট করুন';

  @override
  String get unsupportedVersionOpenPlayStore => 'Play Store খুলুন';

  @override
  String publicProfileNotFound(String username) {
    return '@$username পাওয়া যায়নি';
  }

  @override
  String get publicProfileUserNotFound => 'ব্যবহারকারী পাওয়া যায়নি';

  @override
  String get publicProfileNotFoundDesc => 'এই হ্যান্ডেলটি নেই বা লিঙ্কটি নষ্ট।';

  @override
  String get publicProfileTitle => 'প্রোফাইল';

  @override
  String get publicProfileOnline => 'অনলাইন';

  @override
  String publicProfileLastSeen(String time) {
    return 'সর্বশেষ দেখা গেছে $time';
  }

  @override
  String get publicProfileJustNow => 'এইমাত্র';

  @override
  String publicProfileMinutesAgo(int minutes) {
    return '$minutes মি. আগে';
  }

  @override
  String publicProfileHoursAgo(int hours) {
    return '$hours ঘণ্টা আগে';
  }

  @override
  String publicProfileDaysAgo(int days) {
    return '$days দিন আগে';
  }

  @override
  String publicProfileJoined(String date) {
    return '$date এ যোগ দিয়েছেন';
  }

  @override
  String get publicProfileOwnLink => 'এটি আপনার নিজের প্রোফাইল লিঙ্ক।';

  @override
  String publicProfileGupPoints(int points) {
    return '$points গপ পয়েন্ট';
  }

  @override
  String publicProfileLevel(int level) {
    return 'লেভেল $level';
  }

  @override
  String get publicProfileStatPoints => 'পয়েন্ট';

  @override
  String get publicProfileStatBadges => 'ব্যাজ';

  @override
  String get publicProfileStatBestBond => 'সেরা বন্ড';

  @override
  String get publicProfileBadges => 'ব্যাজসমূহ';

  @override
  String get qrScannerTitle => 'কিউআর কোড স্ক্যান';

  @override
  String get qrScannerFlashOnTooltip => 'ফ্ল্যাশ চালু করুন';

  @override
  String get qrScannerFlashOffTooltip => 'ফ্ল্যাশ বন্ধ করুন';

  @override
  String get qrScannerPrompt => 'ক্যামেরাটি প্রোফাইল কিউআর কোডের দিকে তাক করুন';

  @override
  String get qrScannerNotProfileCode => 'এটি GupShupGo প্রোফাইল কোড নয়।';

  @override
  String get qrScannerCameraErrorTitle => 'ক্যামেরা চালু করা যায়নি।';

  @override
  String get qrScannerCameraErrorRetry => 'আবার চেষ্টা করুন।';

  @override
  String get qrScannerPermissionMsg =>
      'কিউআর স্ক্যান করতে ক্যামেরার অনুমতি প্রয়োজন।';

  @override
  String get qrScannerPermissionAllow => 'ক্যামেরার অনুমতি দিন';

  @override
  String get qrScannerBlockedMsg =>
      'ক্যামেরার অনুমতি ব্লক আছে। সেটিংসে চালু করুন।';

  @override
  String get qrScannerBlockedSettings => 'সেটিংস খুলুন';

  @override
  String get screenShareIncomingTitle => 'ইনকামিং স্ক্রিন শেয়ার';

  @override
  String get screenShareWantsToShare => 'স্ক্রিন শেয়ার করতে চান';

  @override
  String get screenShareReject => 'প্রত্যাখ্যান';

  @override
  String get screenShareAccept => 'গ্রহণ করুন';

  @override
  String get screenShareCantAccept => 'স্ক্রিন শেয়ার গ্রহণ করা যায়নি।';

  @override
  String screenShareDeclined(String name) {
    return '$name আপনার অনুরোধ প্রত্যাখ্যান করেছেন';
  }

  @override
  String get screenShareNoAnswer => 'কোনো উত্তর নেই';

  @override
  String get screenShareStartError => 'স্ক্রিন শেয়ার শুরু করা যায়নি';

  @override
  String get screenShareStatusRequesting => 'অনুমতির অনুরোধ করা হচ্ছে';

  @override
  String get screenShareStatusInitializing => 'সম্প্রচার শুরু হচ্ছে';

  @override
  String get screenShareStatusWaitingParticipant => 'অংশগ্রহণকারীর অপেক্ষা';

  @override
  String get screenShareStatusActive => 'স্ক্রিন শেয়ার সক্রিয়';

  @override
  String screenShareSubWaitingAccept(String name) {
    return '$name গ্রহণ করার অপেক্ষা…';
  }

  @override
  String get screenShareSubEstablishing =>
      'এনক্রিপ্ট করা স্ট্রিম স্থাপন হচ্ছে...';

  @override
  String screenShareSubWaitingJoin(String name) {
    return '$name যোগ দেওয়ার অপেক্ষা...';
  }

  @override
  String get screenShareSubActive => 'আপনার পুরো স্ক্রিন দেখা যাচ্ছে।';

  @override
  String get screenShareBadgeRequesting => 'অনুরোধ চলছে';

  @override
  String get screenShareBadgeConnecting => 'সংযোগ হচ্ছে';

  @override
  String get screenShareSharedWith => 'শেয়ার করা হয়েছে: ';

  @override
  String get screenShareRequestingFrom => 'অনুরোধ করা হয়েছে: ';

  @override
  String get screenShareMinimizeTip =>
      'অ্যাপ ব্যবহার চালিয়ে যেতে এটি ছোট করতে পারেন।';

  @override
  String get screenShareStop => 'শেয়ার বন্ধ করুন';

  @override
  String get screenShareCancelRequest => 'অনুরোধ বাতিল';

  @override
  String screenShareViewerTitle(String name) {
    return '$name শেয়ার করছেন';
  }

  @override
  String get screenShareViewerLive => 'লাইভ স্ট্রিম';

  @override
  String get screenShareViewerMinimize => 'ছোট করুন';

  @override
  String get screenShareViewerLeave => 'প্রস্থান';

  @override
  String screenShareViewerWaitingStream(String name) {
    return '$name-এর স্ক্রিনের জন্য অপেক্ষা…';
  }

  @override
  String get screenShareViewerConnecting => 'স্ট্রিমে সংযোগ হচ্ছে...';

  @override
  String get viewOnceVideoTitle => 'ভিডিও · একবার দেখার জন্য';

  @override
  String get viewOncePhotoTitle => 'ছবি · একবার দেখার জন্য';

  @override
  String get viewOnceCantOpen => 'মিডিয়া খোলা যায়নি।';

  @override
  String get viewOnceUnavailable => 'মিডিয়াটি আর উপলব্ধ নেই।';

  @override
  String get viewOnceBlockedFooter => 'স্ক্রিনশট ব্লক করা হয়েছে।';

  @override
  String get anonRestoreBanner => 'বেনামী ব্যানার';

  @override
  String get contactsInviteFriends => 'বন্ধুদের GupShupGo-তে আমন্ত্রণ জানান';

  @override
  String get inviteImageShareFailed =>
      'ছবি শেয়ার করা যায়নি। আবার চেষ্টা করুন বা লিঙ্ক শেয়ার করুন।';

  @override
  String get viewOnceUnblockedFooter =>
      'এটি আর খোলা যাবে না। iOS-এ স্ক্রিনশট ব্লক করা যায় না।';

  @override
  String get tabMessages => 'বার্তা';
}
