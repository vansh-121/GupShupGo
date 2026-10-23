// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get commonCancel => 'ரத்து செய்';

  @override
  String get commonOk => 'சரி';

  @override
  String get commonContinue => 'தொடரவும்';

  @override
  String get commonSave => 'சேமி';

  @override
  String get commonRetry => 'மீண்டும் முயற்சி செய்';

  @override
  String get commonClose => 'மூடு';

  @override
  String get commonGotIt => 'புரிந்தது';

  @override
  String get settingsTitle => 'அமைப்புகள்';

  @override
  String get settingsLanguageTitle => 'மொழி';

  @override
  String get settingsLanguageSubtitle =>
      'உங்கள் விருப்ப மொழியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get languagePickerTitle => 'மொழி';

  @override
  String get languageSystemDefault => 'சாதன இயல்புநிலை';

  @override
  String get languageSystemDefaultSubtitle =>
      'உங்கள் சாதனத்தின் மொழியைப் பின்பற்று';

  @override
  String get loginContinueWithPhone => 'தொலைபேசி எண் மூலம் தொடரவும்';

  @override
  String get loginContinueWithGoogle => 'Google மூலம் தொடரவும்';

  @override
  String get loginUseEmailPassword =>
      'மின்னஞ்சல் மற்றும் கடவுச்சொல்லைப் பயன்படுத்தவும்';

  @override
  String get loginSignIn => 'உள்நுழையவும்';

  @override
  String get loginSignUp => 'பதிவு செய்யவும்';

  @override
  String get loginCreateAccount => 'கணக்கை உருவாக்கவும்';

  @override
  String get loginForgotPassword => 'கடவுச்சொல் மறந்துவிட்டதா?';

  @override
  String get loginOfflineChat => 'ஆஃப்லைன் அரட்டை';

  @override
  String get loginHintName => 'உங்கள் பெயர்';

  @override
  String get loginHintEmail => 'மின்னஞ்சல்';

  @override
  String get loginHintPassword => 'கடவுச்சொல்';

  @override
  String get loginPasswordHelper =>
      'குறைந்தது 8 எழுத்துகள், ஒரு எழுத்து மற்றும் எண்ணுடன்';

  @override
  String loginResetEmailSent(String email) {
    return '$email முகவரிக்கு கடவுச்சொல் மீட்டமைப்பு மின்னஞ்சல் அனுப்பப்பட்டது';
  }

  @override
  String get loginErrorEnterEmail => 'உங்கள் மின்னஞ்சலை உள்ளிடவும்';

  @override
  String get loginErrorValidEmail => 'சரியான மின்னஞ்சலை உள்ளிடவும்';

  @override
  String get loginErrorEnterPassword => 'உங்கள் கடவுச்சொல்லை உள்ளிடவும்';

  @override
  String get loginErrorPasswordMin6 =>
      'கடவுச்சொல் குறைந்தது 6 எழுத்துகளாக இருக்க வேண்டும்';

  @override
  String get loginErrorEnterPasswordSignup => 'கடவுச்சொல்லை உள்ளிடவும்';

  @override
  String get loginErrorPasswordMin8 =>
      'கடவுச்சொல் குறைந்தது 8 எழுத்துகளாக இருக்க வேண்டும்';

  @override
  String get loginErrorPasswordLetter =>
      'கடவுச்சொல்லில் ஒரு எழுத்து இருக்க வேண்டும்';

  @override
  String get loginErrorPasswordNumber =>
      'கடவுச்சொல்லில் ஒரு எண் இருக்க வேண்டும்';

  @override
  String get loginErrorEnterName => 'உங்கள் பெயரை உள்ளிடவும்';

  @override
  String get loginErrorGoogleCancelled =>
      'Google உள்நுழைவு ரத்து செய்யப்பட்டது.';

  @override
  String get loginErrorProfileLoad =>
      'சுயவிவரத்தை ஏற்ற முடியவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get loginErrorGoogleFailed =>
      'Google உள்நுழைவு தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get loginErrorSignInFailed =>
      'உள்நுழைய முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get loginErrorSignUpFailed =>
      'பதிவு செய்ய முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get loginErrorGeneric => 'பிழை ஏற்பட்டது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get loginErrorResetFailed =>
      'மீட்டமைப்பு மின்னஞ்சலை அனுப்ப முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get loginErrorUserNotFound =>
      'இந்த மின்னஞ்சலில் கணக்கு எதுவும் இல்லை. பதிவு செய்யவும்.';

  @override
  String get loginErrorWrongPassword =>
      'தவறான கடவுச்சொல். மீண்டும் முயற்சிக்கவும்.';

  @override
  String get loginErrorEmailInUse =>
      'இந்த மின்னஞ்சலில் ஏற்கனவே கணக்கு உள்ளது. உள்நுழையவும்.';

  @override
  String get loginErrorInvalidEmail => 'சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும்.';

  @override
  String get loginErrorWeakPassword =>
      'கடவுச்சொல் மிகவும் எளிதாக உள்ளது. குறைந்தது 6 எழுத்துகளைப் பயன்படுத்தவும்.';

  @override
  String get loginErrorInvalidCredential =>
      'தவறான மின்னஞ்சல் அல்லது கடவுச்சொல். சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get loginErrorTooManyRequests =>
      'அதிக முயற்சிகள் மேற்கொள்ளப்பட்டன. பின்னர் முயற்சிக்கவும்.';

  @override
  String get homeNavChats => 'செய்திகள்';

  @override
  String get homeNavMoments => 'தருணங்கள்';

  @override
  String get homeNavCalls => 'அழைப்புகள்';

  @override
  String get homeNavProfile => 'சுயவிவரம்';

  @override
  String get homeTooltipOfflineChat =>
      'ஆஃப்லைன் அரட்டை — அருகிலுள்ளவர்களுடன் பேசுங்கள்';

  @override
  String get homeTooltipSearch => 'தேடு';

  @override
  String get homeMenuProfile => 'சுயவிவரம்';

  @override
  String get homeMenuPrivateVault => 'தனிப்பட்ட பெட்டகம்';

  @override
  String get homeMenuSettings => 'அமைப்புகள்';

  @override
  String get homeMenuRateUs => 'மதிப்பிடுங்கள்';

  @override
  String get homeMenuReportIssue => 'சிக்கலைப் புகாரளிக்கவும்';

  @override
  String get homeMenuWhatsNew => 'புதியவை';

  @override
  String get homeMenuLogOut => 'வெளியேறு';

  @override
  String get homeEmptyChatsTitle => 'இன்னும் அரட்டைகள் இல்லை';

  @override
  String get homeEmptyChatsSubtitle =>
      'கீழே உள்ள பொத்தானைத் தட்டி உரையாடலைத் தொடங்குங்கள்';

  @override
  String get homeNewChatButton => 'புதிய அரட்டை';

  @override
  String get homeAiAssistantTitle => 'GupAI';

  @override
  String get homeAiAssistantSubtitle =>
      'வரைவு, மொழிபெயர்ப்பு, சுருக்கம் மற்றும் பல';

  @override
  String get homeStrangerMatchTitle => 'அந்நியருடன் இணையுங்கள்';

  @override
  String get homeStrangerMatchSubtitle => 'அநாமதேய அரட்டை — பொருத்த தட்டவும்!';

  @override
  String get homeMyMoment => 'என் தருணம்';

  @override
  String get homeRecentMoments => 'சமீபத்திய தருணங்கள்';

  @override
  String get homeEmptyMomentsTitle => 'இன்னும் புதுப்பிப்புகள் இல்லை.';

  @override
  String get homeEmptyMomentsSubtitle => 'பகிர கேமராவைத் தட்டவும்.';

  @override
  String get homeTapToAddMoment => 'புதுப்பிப்பைச் சேர்க்க தட்டவும்';

  @override
  String get homeEmptyCallsTitle => 'அழைப்பு வரலாறு இல்லை';

  @override
  String get homeEmptyCallsSubtitle =>
      'உங்கள் சமீபத்திய அழைப்புகள் இங்கே தோன்றும்';

  @override
  String get chatInputHint => 'செய்தி...';

  @override
  String get chatSearchHint => 'செய்திகளைத் தேடு...';

  @override
  String get chatStatusTyping => 'தட்டச்சு செய்கிறார்...';

  @override
  String get chatStatusOnline => 'ஆன்லைனில்';

  @override
  String get chatStatusOffline => 'ஆஃப்லைனில்';

  @override
  String chatStatusLastSeen(String time) {
    return 'கடைசியாகப் பார்த்தது $time';
  }

  @override
  String get chatEndToEndEncrypted => 'முழுமையாக குறியாக்கம் செய்யப்பட்டது';

  @override
  String get chatNoInternetOfflineTitle =>
      'இணையம் இல்லையா? அருகிலுள்ள சாதனங்களுடன் ஆஃப்லைனில் அரட்டையடிக்கவும்';

  @override
  String get chatEnableOfflineButton => 'இயக்கு';

  @override
  String get chatSlideToCancel => 'ரத்து செய்ய ஸ்லைடு செய்யவும்';

  @override
  String get chatTooltipVoiceCall => 'குரல் அழைப்பு';

  @override
  String get chatTooltipVideoCall => 'வீடியோ அழைப்பு';

  @override
  String get chatMenuContactInfo => 'தொடர்பு தகவல்';

  @override
  String get chatMenuSearch => 'தேடு';

  @override
  String get chatMenuChatTheme => 'அரட்டை தீம்';

  @override
  String get chatMenuExportChat => 'அரட்டையை ஏற்றுமதி செய்';

  @override
  String get chatMenuMuteNotifications => 'அறிவிப்புகளை முடக்கு';

  @override
  String get chatMenuUnmuteNotifications => 'அறிவிப்புகளை இயக்கு';

  @override
  String get chatMenuBlockContact => 'தொடர்பைத் தடு';

  @override
  String get chatActionReply => 'பதிலளி';

  @override
  String get chatActionCopy => 'நகலெடு';

  @override
  String get chatActionForward => 'முன்னோக்கு';

  @override
  String get chatActionTranslate => 'மொழிபெயர்';

  @override
  String get chatActionSummarise => 'சுருக்கம்';

  @override
  String get chatActionAskGupAi => 'GupAI இடம் கேள்';

  @override
  String get chatActionEdit => 'திருத்து';

  @override
  String get chatActionDelete => 'நீக்கு';

  @override
  String get chatDeleteMessageTitle => 'செய்தியை நீக்கவா?';

  @override
  String get chatDeleteMessageForEveryonePrompt =>
      'உங்களுக்கு மட்டும் நீக்கவா, அல்லது இந்த அரட்டையில் உள்ள அனைவருக்கும் நீக்கவா?';

  @override
  String chatDeleteMessageForMeOnlyPrompt(String name) {
    return 'இது உங்கள் சாதனங்களிலிருந்து மட்டுமே அகற்றப்படும். $name தொடர்ந்து பார்க்க முடியும்.';
  }

  @override
  String get chatDeleteForMe => 'எனக்கு மட்டும் நீக்கு';

  @override
  String get chatDeleteForEveryone => 'அனைவருக்கும் நீக்கு';

  @override
  String chatBlockContactTitle(String name) {
    return '$name ஐத் தடுக்கவா?';
  }

  @override
  String get chatBlockContactPrompt =>
      'தடுக்கப்பட்ட தொடர்புகள் உங்களுக்கு செய்தி அனுப்பவோ அழைக்கவோ முடியாது. அமைப்புகள் → தனியுரிமையில் இருந்து மாற்றலாம்.';

  @override
  String get chatBlockButton => 'தடு';

  @override
  String get chatForwardTo => 'முன்னோக்கு';

  @override
  String get chatNoForwardChats => 'முன்னோக்க வேறு அரட்டைகள் இல்லை';

  @override
  String get chatCannotSendMediaBlocked =>
      'இந்த தொடர்புக்கு மீடியாவை அனுப்ப முடியாது';

  @override
  String get attachmentShareTitle => 'பகிர்';

  @override
  String get attachmentPhoto => 'புகைப்படம்';

  @override
  String get attachmentPhotoSubtitle =>
      'உங்கள் கேலரியில் இருந்து ஒரு படத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get attachmentVideo => 'வீடியோ';

  @override
  String get attachmentVideoSubtitle =>
      'உங்கள் கேலரியில் இருந்து ஒரு வீடியோவைத் தேர்ந்தெடுக்கவும்';

  @override
  String get attachmentDocument => 'ஆவணம்';

  @override
  String get attachmentDocumentSubtitle => 'PDF, Office கோப்பு, ஜிப் கோப்பு';

  @override
  String get attachmentLocation => 'இருப்பிடம்';

  @override
  String get attachmentLocationSubtitle =>
      'உங்கள் தற்போதைய இருப்பிடத்தைப் பகிரவும்';

  @override
  String get attachmentScreenShare => 'திரையைப் பகிரவும்';

  @override
  String get attachmentScreenShareSubtitle =>
      'அரட்டையின் போது உங்கள் திரையை நேரலையாகக் காட்டுங்கள்';

  @override
  String get attachmentViewOnce => 'ஒருமுறை பார்க்கவும்';

  @override
  String get attachmentViewOnceSubtitle =>
      'திறந்த பிறகு புகைப்படம் அல்லது வீடியோ மறைந்துவிடும்';

  @override
  String get contactsTitle => 'தொடர்புகள் & கண்டறி';

  @override
  String get contactsTabFriends => 'நண்பர்கள்';

  @override
  String get contactsTabRequests => 'கோரிக்கைகள்';

  @override
  String get contactsTabDiscover => 'கண்டறி';

  @override
  String get contactsScanQrTooltip => 'QR குறியீட்டை ஸ்கேன் செய்க';

  @override
  String get contactsMyHandleTooltip => 'எனது பயனர் பெயர்';

  @override
  String get contactsSetUsernamePrompt =>
      'முதலில் உங்கள் சுயவிவரத்தில் @username ஐ அமைக்கவும் — உங்கள் QR குறியீடு அதையே பகிர்கிறது.';

  @override
  String get contactsMyQrCodeTitle => 'எனது சுயவிவர QR குறியீடு';

  @override
  String get contactsMyQrCodeSubtitle =>
      'உங்களுடன் உடனடியாக இணைய நண்பர்கள் இந்த குறியீட்டை ஸ்கேன் செய்யலாம்';

  @override
  String get contactsCopyProfileLink => 'சுயவிவர இணைப்பை நகலெடு';

  @override
  String contactsProfileLinkCopied(String username) {
    return '@$username-க்கான சுயவிவர இணைப்பு நகலெடுக்கப்பட்டது!';
  }

  @override
  String get contactsScanSomeonesCode => 'வேறொருவரின் குறியீட்டை ஸ்கேன் செய்க';

  @override
  String get contactsPermissionDenied =>
      'தொடர்புகளை அணுக அனுமதி மறுக்கப்பட்டது.';

  @override
  String get contactsNoUsersFound =>
      'உங்கள் தொடர்புகளில் இதுவரை GupShupGo பயனர்கள் இல்லை.';

  @override
  String contactsFailedToSync(String error) {
    return 'தொடர்புகளை ஒத்திசைக்க முடியவில்லை: $error';
  }

  @override
  String contactsMatchedCount(int count) {
    return 'GupShupGo-வில் உள்ள $count தொடர்புகள்';
  }

  @override
  String get contactsFromDeviceContacts => 'உங்கள் சாதனத் தொடர்புகளிலிருந்து';

  @override
  String get contactsLoadFriendsError => 'நண்பர்களை ஏற்ற முடியவில்லை.';

  @override
  String get contactsNoFriendsTitle => 'இன்னும் நண்பர்கள் சேர்க்கப்படவில்லை';

  @override
  String get contactsNoFriendsPrompt =>
      '@username, தொலைபேசி அல்லது மின்னஞ்சல் மூலம் தேட கண்டறி தாவலைப் பயன்படுத்தவும்!';

  @override
  String get contactsDiscoverPeopleButton => 'நபர்களைக் கண்டறி';

  @override
  String get contactsQuickConnectHeader => 'விரைவு இணைப்பு';

  @override
  String get contactsNoSuggestions => 'தற்போது பரிந்துரைகள் எதுவும் இல்லை.';

  @override
  String get contactsLoadRequestsError => 'கோரிக்கைகளை ஏற்ற முடியவில்லை.';

  @override
  String contactsPendingRequestsHeader(int count) {
    return 'நிலுவையிலுள்ள கோரிக்கைகள் ($count)';
  }

  @override
  String get contactsNoPendingRequestsTitle =>
      'நிலுவையிலுள்ள கோரிக்கைகள் இல்லை';

  @override
  String get contactsNoPendingRequestsSubtitle =>
      'பயனர்கள் உங்களுக்கு கோரிக்கைகளை அனுப்பும்போது அவை இங்கே தோன்றும்.';

  @override
  String get contactsWantsToConnect => 'இணைய விரும்புகிறார்';

  @override
  String get contactsAcceptButton => 'ஏற்றுக்கொள்';

  @override
  String get contactsAcceptFailed =>
      'கோரிக்கையை ஏற்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String contactsConnectedWith(String name) {
    return '$name உடன் இணைக்கப்பட்டது!';
  }

  @override
  String get contactsDeclineFailed =>
      'கோரிக்கையை நிராகரிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get contactsYouMightKnowHeader => 'தெரிந்திருக்கலாம்';

  @override
  String get contactsSeeAll => 'அனைத்தையும் காட்டு';

  @override
  String get contactsSearchHint =>
      'பெயர், @பயனர்பெயர், தொலைபேசி அல்லது மின்னஞ்சலைத் தேடுங்கள்...';

  @override
  String get contactsTurnOnDiscoverability =>
      'தேடல்கள் மற்றும் பரிந்துரைகளில் தோன்ற கண்டறியப்படுதலை இயக்கவும்.';

  @override
  String get contactsNoMatchingUsersTitle =>
      'பொருந்தும் பயனர்கள் கிடைக்கவில்லை';

  @override
  String get contactsNoMatchingUsersSubtitle =>
      '@username, தொலைபேசி அல்லது மின்னஞ்சலைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get contactsDiscoverHeroTitle =>
      'GupShupGo-வில் புதிய நபர்களைக் கண்டறியுங்கள்';

  @override
  String get contactsDiscoverHeroSubtitle =>
      'உலகெங்கிலும் நம்பகமான இணைப்புகளுடன் உங்கள் வட்டத்தை விரிவாக்குங்கள்.';

  @override
  String get contactsSyncDeviceContacts => 'சாதனத் தொடர்புகளை ஒத்திசைக்கவும்';

  @override
  String get contactsSyncingContacts => 'தொடர்புகள் ஒத்திசைக்கப்படுகின்றன...';

  @override
  String get contactsSyncDeviceSubtitle =>
      'தொலைபேசி தொடர்புகளிலிருந்து நண்பர்களை உடனே கண்டறியுங்கள்';

  @override
  String get contactsSuggestedUsersHeader => 'பரிந்துரைக்கப்பட்ட பயனர்கள்';

  @override
  String get contactsAddFriendButton => 'நண்பரைச் சேர்';

  @override
  String get contactsRequestedButton => 'கோரப்பட்டது';

  @override
  String contactsRequestSent(String name) {
    return '$name-க்கு நட்புக் கோரிக்கை அனுப்பப்பட்டது!';
  }

  @override
  String get contactsRequestFailed =>
      'கோரிக்கை ஏற்கனவே நிலுவையில் உள்ளது அல்லது தோல்வியடைந்தது.';

  @override
  String get contactsRequestUnavailable => 'அந்தக் கோரிக்கை இனி கிடைக்காது.';

  @override
  String get profileEditTitle => 'சுயவிவரத்தைத் திருத்து';

  @override
  String get profileSaveButton => 'சேமி';

  @override
  String get profileTapToChangePhoto => 'புகைப்படத்தை மாற்ற தட்டவும்';

  @override
  String get profileUpgradeToPro => 'Pro-விற்கு மேம்படுத்தவும்';

  @override
  String get profileSectionName => 'உங்கள் பெயர்';

  @override
  String get profileNameHint => 'உங்கள் பெயரை உள்ளிடவும்';

  @override
  String get profileSectionHandle => 'தனித்துவமான பெயர்';

  @override
  String get profileHandleNotSet => 'இன்னும் அமைக்கப்படவில்லை';

  @override
  String get profileChangeHandle => 'மாற்று';

  @override
  String get profileSectionAbout => 'பற்றி';

  @override
  String get profileAboutHint => 'உங்கள் மனதில் என்ன உள்ளது?';

  @override
  String get profileDefaultAbout =>
      'வணக்கம்! நான் GupShupGo பயன்படுத்துகிறேன்.';

  @override
  String get profileSectionPhone => 'தொலைபேசி';

  @override
  String get profileSectionEmail => 'மின்னஞ்சல்';

  @override
  String get profileSectionLinkedMethods => 'இணைக்கப்பட்ட உள்நுழைவு முறைகள்';

  @override
  String get profileNotLinked => 'இணைக்கப்படவில்லை';

  @override
  String get profileNameEmpty => 'பெயர் காலியாக இருக்கக்கூடாது.';

  @override
  String get profileUpdatedSuccess => 'சுயவிவரம் புதுப்பிக்கப்பட்டது';

  @override
  String profileUploadPhotoFailed(String error) {
    return 'புகைப்படத்தைப் பதிவேற்ற முடியவில்லை: $error';
  }

  @override
  String profileSaveFailed(String error) {
    return 'சுயவிவரத்தைச் சேமிக்க முடியவில்லை: $error';
  }

  @override
  String get profilePoints => 'புள்ளிகள்';

  @override
  String get profileBadges => 'பேட்ஜ்கள்';

  @override
  String get profileBestBond => 'சிறந்த பிணைப்பு';

  @override
  String get settingsAccountCard => 'கணக்கு';

  @override
  String get settingsProfileTile => 'சுயவிவரம்';

  @override
  String get settingsLinkedMethodsTile => 'இணைக்கப்பட்ட உள்நுழைவு முறைகள்';

  @override
  String get settingsPhoneTile => 'தொலைபேசி எண்';

  @override
  String get settingsEmailTile => 'மின்னஞ்சல்';

  @override
  String get settingsPrivacyCard => 'தனியுரிமை';

  @override
  String get settingsDiscoverability => 'கண்டறியப்படுதல்';

  @override
  String get settingsLastSeen => 'கடைசியாகப் பார்த்தது';

  @override
  String get settingsReadReceipts => 'படித்த ரசீதுகள்';

  @override
  String get settingsAdPreferences => 'விளம்பர விருப்பத்தேர்வுகள்';

  @override
  String get settingsManage => 'நிர்வகி';

  @override
  String get settingsAppearanceCard => 'தோற்றம்';

  @override
  String get settingsTheme => 'தீம்';

  @override
  String get settingsThemeLight => 'வெளிச்சம்';

  @override
  String get settingsThemeDark => 'இருள்';

  @override
  String get settingsThemeSystem => 'கணினி';

  @override
  String get settingsChatTheme => 'அரட்டை தீம்';

  @override
  String get settingsHelpSecurityCard => 'உதவி & பாதுகாப்பு';

  @override
  String get settingsHelpCenter => 'உதவி மையம்';

  @override
  String get settingsReportProblem => 'சிக்கலைப் புகாரளிக்கவும்';

  @override
  String get settingsE2EEShield => 'முழுமையான குறியாக்கம் (வால்ட்)';

  @override
  String get settingsVerifySafetyNumber => 'பாதுகாப்பு எண்ணைச் சரிபார்க்கவும்';

  @override
  String get settingsBlockedContacts => 'தடுக்கப்பட்ட தொடர்புகள்';

  @override
  String get settingsClearAllGupHistory =>
      'அனைத்து அரட்டை வரலாற்றையும் அழிக்கவும்';

  @override
  String get settingsRateUs => 'எங்களை மதிப்பிடுங்கள்';

  @override
  String get settingsWhatsNew => 'புதியவை';

  @override
  String get settingsCheckForUpdates => 'புதுப்பிப்புகளைச் சரிபார்க்கவும்';

  @override
  String get settingsAppInfo => 'பயன்பாட்டுத் தகவல்';

  @override
  String get settingsLogOut => 'வெளியேறு';

  @override
  String get settingsLogOutConfirmTitle => 'வெளியேறு';

  @override
  String get settingsLogOutConfirmPrompt =>
      'GupShupGo-விலிருந்து நிச்சயமாக வெளியேற விரும்புகிறீர்களா?';

  @override
  String get settingsSigningOut => 'வெளியேறுகிறது…';

  @override
  String get settingsClearChatsConfirmTitle =>
      'அனைத்து அரட்டைகளையும் அழிக்கவும்';

  @override
  String get settingsClearChatsConfirmPrompt =>
      'இது உங்கள் செய்தி வரலாற்றை நிரந்தரமாக நீக்கும். இதை மீட்டெடுக்க முடியாது.';

  @override
  String get settingsDeleteAll => 'அனைத்தையும் நீக்கு';

  @override
  String get settingsClearingChats => 'அரட்டைகள் அழிக்கப்படுகின்றன...';

  @override
  String get settingsAllChatsCleared => 'அனைத்து அரட்டைகளும் அழிக்கப்பட்டன';

  @override
  String settingsClearChatsFailed(String error) {
    return 'அரட்டைகளை அழிக்க முடியவில்லை: $error';
  }

  @override
  String get settingsChooseThemeTitle => 'தீமைத் தேர்ந்தெடுக்கவும்';

  @override
  String get settingsUnlockPremiumFeatures =>
      'பிரீமியம் அம்சங்களை அன்லாக் செய்க';

  @override
  String settingsProDaysLeft(String planLabel, int daysRemaining) {
    return '$planLabel · $daysRemaining நாட்கள் மீதமுள்ளன';
  }

  @override
  String get settingsCheckingForUpdates =>
      'புதுப்பிப்புகள் சரிபார்க்கப்படுகின்றன…';

  @override
  String settingsUpToDate(String version) {
    return 'நீங்கள் சமீபத்திய பதிப்பில் உள்ளீர்கள் (v$version).';
  }

  @override
  String get settingsUpdateCheckUnavailable =>
      'புதுப்பிப்புகளைச் சரிபார்க்க முடியவில்லை. Google Play Store-லிருந்து நிறுவப்பட்டதை உறுதிசெய்யவும்.';

  @override
  String get settingsNoBlockedContacts => 'தடுக்கப்பட்ட தொடர்புகள் இல்லை';

  @override
  String get settingsUnblock => 'தடையை நீக்கு';

  @override
  String settingsUserUnblocked(String name) {
    return '$name தடையை நீக்கியது';
  }

  @override
  String get settingsVerifyContactTitle => 'தொடர்பைச் சரிபார்க்கவும்';

  @override
  String get settingsVerifyContactSubtitle =>
      'பகிர்ந்த பாதுகாப்பு எண்ணைக் காண ஒரு தொடர்பைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get settingsComputingSafetyNumber =>
      'பாதுகாப்பு எண் கணக்கிடப்படுகிறது…';

  @override
  String settingsSafetyNumberExplanation(String name) {
    return 'கீழே உள்ள எண் $name-இன் சாதனத்துடன் பொருந்தினால் குறியாக்கம் சரிபார்க்கப்பட்டது.';
  }

  @override
  String get settingsSafetyNumberNoBundle =>
      'இந்தத் தொடர்பு இன்னும் குறியாக்க விசைக் கற்றையை வெளியிடவில்லை.';

  @override
  String get settingsSafetyNumberCompareHint =>
      'நேரிலோ அல்லது பாதுகாப்பான அழைப்பிலோ இந்த எண்ணை ஒப்பிடவும்.';

  @override
  String get callEndToEndEncrypted => 'முழுமையாக என்க்ரிப்ட் செய்யப்பட்டது';

  @override
  String get callSecuring => 'அழைப்பு பாதுகாக்கப்படுகிறது…';

  @override
  String get callNotEncrypted => 'என்க்ரிப்ட் செய்யப்படவில்லை';

  @override
  String get callIncomingVoice => 'உள்வரும் குரல் அழைப்பு';

  @override
  String get callIncomingVideo => 'உள்வரும் வீடியோ அழைப்பு';

  @override
  String get callVoiceCall => 'குரல் அழைப்பு';

  @override
  String get callVideoCall => 'வீடியோ அழைப்பு';

  @override
  String get callDecline => 'நிராகரி';

  @override
  String get callAccept => 'ஏற்றுக்கொள்';

  @override
  String get callConnecting => 'இணைக்கப்படுகிறது...';

  @override
  String get callSettingUp => 'அழைப்பு அமைக்கப்படுகிறது...';

  @override
  String callNotifying(String name) {
    return '$name-க்கு அறிவிக்கப்படுகிறது...';
  }

  @override
  String get callRinging => 'ஒலிக்கிறது...';

  @override
  String get callConnected => 'இணைக்கப்பட்டது';

  @override
  String get callOnHold => 'காத்திருப்பில்';

  @override
  String get callCalling => 'அழைக்கப்படுகிறது...';

  @override
  String get callWaitingForUser => 'பயனருக்காக காத்திருக்கிறது...';

  @override
  String get callEnded => 'அழைப்பு முடிந்தது';

  @override
  String get callDeclined => 'அழைப்பு நிராகரிக்கப்பட்டது';

  @override
  String get callNoAnswer => 'பதில் இல்லை';

  @override
  String get callFailedToConnect => 'இணைக்க முடியவில்லை';

  @override
  String callFailedToStart(String error) {
    return 'அழைப்பைத் தொடங்க முடியவில்லை: $error';
  }

  @override
  String get callTokenExpired =>
      'டோக்கன் காலாவதியானது. அழைப்பை மீண்டும் தொடங்கவும்.';

  @override
  String callFailedToInit(String type, String error) {
    return '$type அழைப்பைத் தொடங்க முடியவில்லை: $error';
  }

  @override
  String get callTurnOffSpeaker => 'ஸ்பீக்கரை அணைக்கவும்';

  @override
  String get callTurnOnSpeaker => 'ஸ்பீக்கரை இயக்கவும்';

  @override
  String get callMuteMic => 'மைக்கை முடக்கு';

  @override
  String get callUnmuteMic => 'மைக்கை இயக்கு';

  @override
  String get callEndCall => 'அழைப்பை முடிக்கவும்';

  @override
  String get callSwitchCamera => 'கேமராவை மாற்றவும்';

  @override
  String get callTurnOffCamera => 'கேமராவை அணைக்கவும்';

  @override
  String get callTurnOnCamera => 'கேமராவை இயக்கவும்';

  @override
  String statusViewedByCount(int count) {
    return '$count பேர் பார்த்துள்ளனர்';
  }

  @override
  String get statusNoViewsYet => 'இன்னும் பார்வைகள் இல்லை';

  @override
  String statusViewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count பார்வைகள்',
      one: '1 பார்வை',
    );
    return '$_temp0';
  }

  @override
  String get statusDeleteTitle => 'நிலையை நீக்கு';

  @override
  String get statusDeleteConfirm =>
      'இந்த நிலையை நிச்சயமாக நீக்க விரும்புகிறீர்களா?';

  @override
  String get statusDeleteButton => 'நீக்கு';

  @override
  String get statusReplySent => 'பதில் அனுப்பப்பட்டது';

  @override
  String statusReplyFailed(String error) {
    return 'பதில் அனுப்ப முடியவில்லை: $error';
  }

  @override
  String get statusNoActive => 'செயலில் உள்ள நிலை இல்லை';

  @override
  String get statusCouldNotLoad => 'இந்த புதுப்பிப்பை ஏற்ற முடியவில்லை';

  @override
  String get statusTapToRetry => 'மீண்டும் முயற்சிக்க தட்டவும்';

  @override
  String get statusFailedToLoadImage => 'படத்தை ஏற்ற முடியவில்லை';

  @override
  String get statusLoadingVideo => 'வீடியோ ஏற்றப்படுகிறது...';

  @override
  String get statusEnterTextPrompt => 'உரையை உள்ளிடவும்';

  @override
  String get statusNoContactsNotice =>
      'இன்னும் தொடர்புகள் இல்லை — பகிர்வதற்கு முன் அரட்டையைத் தொடங்குங்கள்.';

  @override
  String statusPostFailed(String error) {
    return 'நிலையைப் பகிர முடியவில்லை: $error';
  }

  @override
  String get statusTypeHint => 'நிலையை உள்ளிடவும்...';

  @override
  String get statusCamera => 'கேமரா';

  @override
  String get statusTakePhoto => 'புகைப்படம் எடுக்கவும்';

  @override
  String get statusGalleryPhoto => 'கேலரி புகைப்படம்';

  @override
  String get statusChooseImageGallery => 'கேலரியிலிருந்து தேர்வு செய்யவும்';

  @override
  String get statusRecordVideo => 'வீடியோ பதிவு செய்';

  @override
  String get statusRecordShortVideo => 'குறுகிய வீடியோவை பதிவு செய்';

  @override
  String get statusGalleryVideo => 'கேலரி வீடியோ';

  @override
  String get statusChooseVideoGallery =>
      'கேலரியிலிருந்து வீடியோவை தேர்வு செய்யவும்';

  @override
  String statusFailedPickImage(String error) {
    return 'படத்தைத் தேர்ந்தெடுக்க முடியவில்லை: $error';
  }

  @override
  String statusFailedPickVideo(String error) {
    return 'வீடியோவைத் தேர்ந்தெடுக்க முடியவில்லை: $error';
  }

  @override
  String get statusChangeBgColorTooltip => 'பின்னணி நிறத்தை மாற்றவும்';

  @override
  String aiMessagesRemaining(int count) {
    return '$count மீதமுள்ளது';
  }

  @override
  String get aiQuotaDialogTitle => 'GupAI செய்திகள்';

  @override
  String aiQuotaRemainingOfTotal(int remaining, int total) {
    return 'இன்று $total-இல் $remaining மீதமுள்ளது';
  }

  @override
  String aiQuotaUsedResetNote(int used) {
    return 'இன்று $used பயன்படுத்தப்பட்டது · நாளை மீட்டமைக்கப்படும்.';
  }

  @override
  String get aiQuotaGotIt => 'புரிந்தது';

  @override
  String get aiTitle => 'GupAI';

  @override
  String get aiSubtitle => 'உங்கள் செயலி உதவியாளர்';

  @override
  String get aiEmptyHelpTitle => 'நான் எவ்வாறு உதவ முடியும்?';

  @override
  String get aiEmptyHelpSubtitle =>
      'பதில்களை உருவாக்கவும், மொழிபெயர்க்கவும், சுருக்கவும் அல்லது கேள்விகளைக் கேட்கவும்.';

  @override
  String get meshOfflineChatConnected => 'ஆஃப்லைன் அரட்டை · இணைக்கப்பட்டது';

  @override
  String get meshConnecting => 'இணைக்கப்படுகிறது…';

  @override
  String get meshBannerNotice =>
      'ஆஃப்லைன் அரட்டை — இணையம் மற்றும் சேவையகங்கள் தேவையில்லை';

  @override
  String meshSayHiTo(String name) {
    return '$name-க்கு வணக்கம் சொல்லுங்கள்';
  }

  @override
  String meshOfflineDescription(String name) {
    return 'நீங்கள் ஆஃப்லைன் அரட்டையில் உள்ளீர்கள். செய்திகள் உங்களுக்கும் $name-க்கும் இடையே மட்டுமே இருக்கும்.';
  }

  @override
  String get meshMediaUnavailable => 'இந்த ஊடகம் இனி கிடைக்காது.';

  @override
  String get meshViewOnceTitle => 'ஒரு முறை மட்டும் பார்க்க';

  @override
  String meshViewOncePrompt(String type) {
    return 'இந்த $type-ஐ நீங்கள் ஒரு முறை மட்டுமே திறக்க முடியும்.';
  }

  @override
  String get arcadeTabOverview => 'கண்ணோட்டம்';

  @override
  String get arcadeTabChallenges => 'சவால்கள்';

  @override
  String get arcadeTabLeaderboard => 'முன்னணி பட்டியல்';

  @override
  String get arcadeFailedLoadStats => 'புள்ளிவிவரங்களை ஏற்ற முடியவில்லை.';

  @override
  String get aiAskHint => 'GupAI-யிடம் எதையும் கேளுங்கள்…';

  @override
  String get settingsNotificationsTile => 'அறிவிப்புகள்';

  @override
  String get settingsNotificationsStatusOn => 'இயக்கத்தில்';

  @override
  String get settingsNotificationsStatusOff => 'முடக்கப்பட்டது';

  @override
  String get settingsNotificationsEnabledToast =>
      'அறிவிப்புகள் இயக்கத்தில் உள்ளன.';

  @override
  String get settingsEnableNotificationsTitle => 'அறிவிப்புகளை இயக்கு';

  @override
  String get settingsEnableNotificationsBody =>
      'அறிவிப்புகள் முடக்கப்பட்டுள்ளன. புதிய செய்திகள் மற்றும் அழைப்புகள் குறித்து GupShupGo உங்களுக்கு அறிவிக்க கணினி அமைப்புகளைத் திறக்கவும்.';

  @override
  String get settingsOpenSystemSettings => 'அமைப்புகளைத் திற';

  @override
  String get loginTagline =>
      'இணையம் இல்லாமலும் செயல்படும் தனிப்பட்ட செய்திப் பரிமாற்றம்.';

  @override
  String get settingsPrivacyPolicy => 'தனியுரிமைக் கொள்கை';

  @override
  String get settingsTerms => 'சேவை விதிமுறைகள்';

  @override
  String get settingsDeleteAccount => 'கணக்கை நீக்கு';

  @override
  String get inviteSheetTitle => 'நண்பர்களை அழைக்கவும்';

  @override
  String get inviteSheetSubtitle =>
      'அனைவருக்கும் தெரியப்படுத்துங்கள் — GupShupGo-வைப் பகிருங்கள்';

  @override
  String get inviteShareImageBtn => 'படத்தைப் பகிர்';

  @override
  String get inviteShareLinkBtn => 'இணைப்பைப் பகிர்';

  @override
  String get inviteCopyLinkBtn => 'இணைப்பை நகலெடு';

  @override
  String get inviteLinkCopied => 'அழைப்பு இணைப்பு நகலெடுக்கப்பட்டது';

  @override
  String inviteMessage(String link) {
    return 'GupShupGo-வில் என்னுடன் அரட்டையடிக்கவும் — இது இணையம் இல்லாமலும் வேலை செய்யும் 👋 $link';
  }

  @override
  String get inviteCardTagline => 'ஆஃப்லைனிலும் வேலை செய்யும் தனிப்பட்ட அரட்டை';

  @override
  String get inviteCardScan => 'பதிவிறக்க ஸ்கேன் செய்யவும்';

  @override
  String get inviteCardDownload => 'Google Play-யில் பதிவிறக்கவும்';

  @override
  String get homeMenuInvite => 'நண்பர்களை அழைக்கவும்';

  @override
  String get invitePromptTitle => 'GupShupGo பிடித்திருக்கிறதா?';

  @override
  String get invitePromptBody =>
      'நண்பர்களுடன் இது இன்னும் சிறப்பானது — இணையம் இல்லாமலும் இயங்கும். யாரையாவது அழைக்கலாமா?';

  @override
  String get invitePromptInvite => 'நண்பர்களை அழைக்கவும்';

  @override
  String get invitePromptLater => 'பிறகு பார்க்கலாம்';

  @override
  String get homeOfflineBannerTitle => 'இணையம் இல்லையா? கவலையில்லை';

  @override
  String get homeOfflineBannerSubtitle =>
      'ப்ளூடூத் மூலம் அருகிலுள்ளவர்களுக்கு நீங்கள் இன்னும் செய்திகளை அனுப்பலாம்.';

  @override
  String homeNearbyBannerTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'அருகில் $count நபர்கள்',
      one: 'அருகில் 1 நபர்',
    );
    return '$_temp0';
  }

  @override
  String get homeNearbyBannerSubtitle =>
      'ப்ளூடூத் மூலம் அரட்டையடிக்கவும் — இணையம் தேவையில்லை.';

  @override
  String get linkBackupTitle => 'காப்பு உள்நுழைவு முறையைச் சேர்க்கவும்';

  @override
  String get linkBackupSubtitle =>
      'சிம் இல்லாவிட்டாலும் மீண்டும் உள்நுழைய Google அல்லது மின்னஞ்சலை இணைக்கவும்.';

  @override
  String get linkGoogleTitle => 'Google கணக்கை இணைக்கவும்';

  @override
  String get linkGoogleSubtitleLinked => 'இணைக்கப்பட்டது ✓';

  @override
  String get linkGoogleSubtitleUnlinked =>
      'சிம் இல்லாமல் ஒரு தட்டலில் உள்நுழையவும்';

  @override
  String get linkGoogleAction => 'இணைக்கவும்';

  @override
  String get linkGoogleSuccess => 'Google கணக்கு வெற்றிகரமாக இணைக்கப்பட்டது!';

  @override
  String get linkGoogleAlreadyUsed =>
      'இந்த Google கணக்கு ஏற்கனவே வேறொரு கணக்காகப் பதிவு செய்யப்பட்டுள்ளது.';

  @override
  String get linkGoogleFailed =>
      'Google இணைப்பு தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get linkSessionExpired =>
      'அமர்வு காலாவதியானது. மீண்டும் உள்நுழையவும்.';

  @override
  String get linkEmailTitle => 'மின்னஞ்சல் & கடவுச்சொல்லை இணைக்கவும்';

  @override
  String get linkEmailSubtitleLinked => 'இணைக்கப்பட்டது ✓';

  @override
  String get linkEmailSubtitleUnlinked =>
      'சிம் அல்லது Google இல்லாவிட்டால் மின்னஞ்சல் மூலம் உள்நுழையவும்';

  @override
  String get linkEmailActionAdd => 'சேர்';

  @override
  String get linkEmailActionCancel => 'ரத்து செய்';

  @override
  String get linkEmailFieldLabel => 'மின்னஞ்சல்';

  @override
  String get linkPasswordFieldLabel => 'கடவுச்சொல்லை உருவாக்கவும்';

  @override
  String get linkPasswordHelper => 'குறைந்தது 6 எழுத்துகள்';

  @override
  String get linkEmailButton => 'மின்னஞ்சலை இணைக்கவும்';

  @override
  String get linkEmailSuccess => 'மின்னஞ்சல் வெற்றிகரமாக இணைக்கப்பட்டது!';

  @override
  String get linkEmailInvalid => 'சரியான மின்னஞ்சலை உள்ளிடவும்.';

  @override
  String get linkPasswordTooShort =>
      'கடவுச்சொல் குறைந்தது 6 எழுத்துகள் இருக்க வேண்டும்.';

  @override
  String get linkEmailAlreadyInUse =>
      'இந்த மின்னஞ்சல் ஏற்கனவே பதிவு செய்யப்பட்டுள்ளது.';

  @override
  String get linkEmailAlreadyLinked =>
      'உங்கள் கணக்கில் ஏற்கனவே மின்னஞ்சல் இணைக்கப்பட்டுள்ளது.';

  @override
  String get linkEmailFailed => 'மின்னஞ்சல் இணைப்பு தோல்வியடைந்தது.';

  @override
  String get linkContinueToApp => 'பயன்பாட்டிற்குச் செல்லவும்';

  @override
  String get linkSkipForNow => 'இப்போதைக்குத் தவிர்';

  @override
  String get linkSkip => 'தவிர்';

  @override
  String get phoneAuthTitleEntry => 'உங்கள் தொலைபேசி எண்ணுடன் உள்நுழையவும்.';

  @override
  String get phoneAuthTitleOtp => 'நாங்கள் அனுப்பிய குறியீட்டை உள்ளிடவும்.';

  @override
  String get phoneAuthNameHint => 'உங்கள் பெயர்';

  @override
  String get phoneAuthPhoneHint => 'தொலைபேசி எண்';

  @override
  String get phoneAuthUseSim => 'சிம்மைப் பயன்படுத்து';

  @override
  String get phoneAuthSendOtp => 'OTP அனுப்பவும்';

  @override
  String phoneAuthOtpPrompt(String phone) {
    return '$phone எண்ணிற்கு அனுப்பப்பட்ட 6 இலக்கக் குறியீட்டை உள்ளிடவும்';
  }

  @override
  String get phoneAuthOtpPromptGeneric =>
      'நாங்கள் அனுப்பிய 6 இலக்கக் குறியீட்டை உள்ளிடவும்';

  @override
  String get phoneAuthOtpHint => 'குறியீட்டை உள்ளிடவும்';

  @override
  String get phoneAuthVerify => 'சரிபார்க்கவும்';

  @override
  String get phoneAuthGoBack => 'திரும்பிச் செல்';

  @override
  String get phoneAuthResendCode => 'குறியீட்டை மீண்டும் அனுப்பு';

  @override
  String get phoneAuthEnterName => 'உங்கள் பெயரை உள்ளிடவும்';

  @override
  String get phoneAuthEnterValidPhone => 'சரியான தொலைபேசி எண்ணை உள்ளிடவும்';

  @override
  String get phoneAuthEnterCode => 'குறியீட்டை உள்ளிடவும்';

  @override
  String get phoneAuthRequestNewCode => 'புதிய குறியீட்டைக் கோரவும்.';

  @override
  String get phoneAuthCodeIncorrect =>
      'அந்தக் குறியீடு தவறானது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get phoneAuthErrCodeIncorrect =>
      'குறியீடு தவறானது. சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get phoneAuthErrCodeExpired =>
      'குறியீடு காலாவதியானது. மீண்டும் அனுப்பவும்.';

  @override
  String get phoneAuthErrTooManyRequests =>
      'அதிக முயற்சிகள். சிறிது நேரம் காத்திருக்கவும்.';

  @override
  String get phoneAuthErrInvalidPhone => 'தொலைபேசி எண் தவறானது.';

  @override
  String get phoneAuthErrQuotaExceeded => 'SMS வரம்பு முடிந்தது.';

  @override
  String get phoneAuthErrFailed => 'சரிபார்ப்பு தோல்வியடைந்தது.';

  @override
  String get usernameSetupAppBarTitle => 'உங்கள் ஹேண்டிலை தேர்வு செய்யவும்';

  @override
  String get usernameSetupHeaderTitle => 'உங்கள் அடையாளத்தைப் பாதுகாக்கவும்';

  @override
  String get usernameSetupHeaderDesc =>
      'உங்கள் @handle GupShupGo-வில் உங்கள் தனித்துவமான சாவி. தொலைபேசி அல்லது மின்னஞ்சல் பகிராமல் மற்றவர்கள் உங்களைத் தொடர்பு கொள்ளலாம்.';

  @override
  String get usernameSetupInputHint => 'your_handle';

  @override
  String get usernameSetupChecking => 'இருப்பு சரிபார்க்கப்படுகிறது...';

  @override
  String usernameSetupAvailable(String handle) {
    return '@$handle கிடைக்கிறது!';
  }

  @override
  String usernameSetupTaken(String handle) {
    return '@$handle ஏற்கனவே வேறொருவரால் எடுக்கப்பட்டது.';
  }

  @override
  String get usernameSetupCharRules => '3–20 எழுத்துகள் (a-z, 0-9, _)';

  @override
  String get usernameSetupTooShort => 'குறைந்தது 3 எழுத்துகள் இருக்க வேண்டும்.';

  @override
  String get usernameSetupTooLong => 'அதிகபட்சம் 20 எழுத்துகள் மட்டுமே.';

  @override
  String get usernameSetupInvalidChars =>
      'எழுத்துகள், எண்கள், அடிக்கோடுகள் மட்டுமே அனுமதிக்கப்படும்.';

  @override
  String get usernameSetupRecommended => 'உங்களுக்காகப் பரிந்துரைக்கப்பட்டவை';

  @override
  String get usernameSetupSaveBtn => 'சேமித்துத் தொடரவும்';

  @override
  String get usernameSetupSkipBtn => 'இப்போதைக்குத் தவிர்';

  @override
  String usernameSetupFailed(String error) {
    return 'பயனர்பெயரை அமைக்க முடியவில்லை: $error';
  }

  @override
  String get vaultProtectTitle => 'வால்ட்டைப் பாதுகாக்கவும்';

  @override
  String get vaultUnlockTitle => 'வால்ட்டைத் திறக்கவும்';

  @override
  String get vaultSetupDesc =>
      'செய்தி வரலாற்றை என்க்ரிப்ட் செய்ய பின்னைத் தேர்வுசெய்யவும். புதிய போனில் படிக்க இது தேவைப்படும்.';

  @override
  String get vaultUnlockDescBio =>
      'வரலாற்றை அணுக பின்னை உள்ளிடவும் அல்லது கைரேகையைத் தொடவும்.';

  @override
  String get vaultUnlockDescPin => 'வரலாற்றை அணுக உங்கள் பின்னை உள்ளிடவும்.';

  @override
  String get vaultReinstallHint =>
      'வரலாற்றை மீட்டெடுக்க உங்கள் பின்னை உள்ளிடவும்.';

  @override
  String get vaultUnlockWithFingerprint => 'கைரேகையுடன் திறக்கவும்';

  @override
  String get vaultOrDivider => 'அல்லது';

  @override
  String get vaultNewPin => 'புதிய பின்';

  @override
  String get vaultConfirmPin => 'பின்னை உறுதிப்படுத்தவும்';

  @override
  String get vaultEnterPin => 'பின்னை உள்ளிடவும்';

  @override
  String get vaultKeyboardUseLetters => 'எழுத்துகளைப் பயன்படுத்து';

  @override
  String get vaultKeyboardUseNumbers => 'எண்களைப் பயன்படுத்து';

  @override
  String get vaultRestoreLater => 'பிறகு மீட்டெடு';

  @override
  String get vaultForgotPin => 'பின் மறந்துவிட்டதா?';

  @override
  String get vaultSetPinBtn => 'பின் அமைக்கவும்';

  @override
  String get vaultDecryptBtn => 'திறக்கவும்';

  @override
  String get vaultPinMinLength =>
      'பின் குறைந்தது 6 எழுத்துகள் இருக்க வேண்டும்.';

  @override
  String get vaultPinsDoNotMatch => 'பின்கள் பொருந்தவில்லை.';

  @override
  String get vaultSetupFailed => 'அமைப்பு தோல்வியடைந்தது.';

  @override
  String get vaultIncorrectPin => 'தவறான பின். மீண்டும் முயற்சிக்கவும்.';

  @override
  String get vaultFingerprintOutOfDate =>
      'கைரேகை புதுப்பிக்கப்பட வேண்டும். பின்னை உள்ளிடவும்.';

  @override
  String get vaultBiometricError => 'பயோமெட்ரிக் பிழை. பின்னை உள்ளிடவும்.';

  @override
  String get vaultBioReasonUnlock =>
      'வால்ட்டைத் திறக்க பயோமெட்ரிக்ஸைப் பயன்படுத்தவும்';

  @override
  String get vaultBioReasonEnrol =>
      'விரைவுத் திறப்பைச் செயல்படுத்த கைரேகையை உறுதிப்படுத்தவும்';

  @override
  String get vaultAskBioTitle => 'கைரேகையால் திறக்கலாமா?';

  @override
  String get vaultAskBioDesc =>
      'பின் தட்டச்சு செய்வதைத் தவிர்க்கலாம். ஆனால் புதிய போனுக்கு பின்னை நினைவில் வைக்கவும்.';

  @override
  String get vaultAskBioNotNow => 'இப்போது வேண்டாம்';

  @override
  String get vaultAskBioEnable => 'இயக்கு';

  @override
  String get vaultDeleteMessagesTitle => 'அனைத்து செய்திகளையும் நீக்கவா?';

  @override
  String get vaultDeleteMessagesDesc =>
      'பின் இல்லாமல் வரலாற்றை மீட்க முடியாது, ரீசெட் செய்தால் அனைத்தும் நீக்கப்படும்.';

  @override
  String get vaultDeleteMessagesCancel => 'ரத்து';

  @override
  String get vaultDeleteMessagesConfirm => 'அனைத்தையும் நீக்கு';

  @override
  String get vaultCustodyConfirmTitle => 'வால்ட் பின்னை உறுதிப்படுத்தவும்';

  @override
  String get vaultCustodyChooseTitle => 'பின்னைத் தேர்ந்தெடுக்கவும்';

  @override
  String get vaultCustodyConfirmDesc =>
      'உங்கள் வரலாறு பின்னால் பாதுகாக்கப்பட்டுள்ளது. ஒருமுறை உறுதிப்படுத்தவும்.';

  @override
  String get vaultCustodyChooseDesc =>
      'நினைவில் நிற்கும் பின்னைத் தேர்ந்தெடுக்கவும். பழைய செய்திகள் புதிய பின்னால் என்க்ரிப்ட் செய்யப்படும்.';

  @override
  String get vaultCustodyDontKnow => 'எனக்கு பின் தெரியாது';

  @override
  String get vaultCustodyConfirmBtn => 'உறுதி செய்';

  @override
  String get vaultCustodySaveBtn => 'பின்னைச் சேமி';

  @override
  String get vaultCustodyMismatchError => 'பின் பொருந்தவில்லை.';

  @override
  String get vaultCustodyAutoUpdateFailed => 'தானாகப் புதுப்பிக்க முடியவில்லை.';

  @override
  String vaultCustodyReencrypting(int done, int total) {
    return '$total-இல் $done மீண்டும் என்க்ரிப்ட் ஆகிறது… செயலியை மூட வேண்டாம்.';
  }

  @override
  String get vaultCustodyPreparing => 'தயாராகிறது… செயலியை மூட வேண்டாம்.';

  @override
  String get vaultSettingsTitle => 'வால்ட்';

  @override
  String get vaultSettingsAboutTitle => 'வால்ட் பற்றி';

  @override
  String get vaultSettingsAboutDesc =>
      'உங்கள் அரட்டை வரலாற்றின் தனிப்பட்ட காப்புப்பிரதி. உங்கள் பின் மட்டுமே இதைத் திறக்கும்.';

  @override
  String get vaultSettingsBulletMessages => 'உங்கள் செய்திகள்';

  @override
  String get vaultSettingsBulletStatuses => 'நீங்கள் காணும் நிலைகள்';

  @override
  String get vaultSettingsNeverKept =>
      'இங்கு சேமிக்கப்படாதவை: அழைப்பு வரலாறு, தொடர்புகள் அல்லது மற்றவர்களின் தனிப்பட்ட செய்திகள்.';

  @override
  String get vaultSettingsSectionPrivacy => 'தனியுரிமை';

  @override
  String get vaultSettingsAutoDelete => 'பழைய செய்திகளைத் தானாக நீக்கு';

  @override
  String get vaultSettingsKeepForever => 'எப்போதும் வைத்திரு';

  @override
  String vaultSettingsDeleteAfter(String label) {
    return '$label கழித்து நீக்கு';
  }

  @override
  String get vaultSettingsSectionPin => 'பின்';

  @override
  String get vaultSettingsChangePin => 'பின்னை மாற்று';

  @override
  String get vaultSettingsChangePinSubtitle =>
      'அனைத்து உள்ளடக்கங்களையும் மீண்டும் என்க்ரிப்ட் செய்யும்';

  @override
  String get vaultSettingsBioTitle => 'கைரேகை மூலம் திறத்தல்';

  @override
  String get vaultSettingsBioSubOn => 'இந்த சாதனத்தில் இயக்கத்தில் உள்ளது';

  @override
  String get vaultSettingsBioSubOff => 'பின் தட்டச்சு செய்வதைத் தவிர்க்கவும்';

  @override
  String get vaultSettingsSectionDanger => 'ஆபத்தான பகுதி';

  @override
  String get vaultSettingsDeleteData => 'வால்ட் தரவை நீக்கு';

  @override
  String get vaultSettingsDeleteDataSubtitle =>
      'வரலாற்றை நீக்கும், பின்னை வைத்திருக்கும்';

  @override
  String get vaultSettingsResetVault => 'வால்ட்டை ரீசெட் செய்';

  @override
  String get vaultSettingsResetVaultSubtitle =>
      'பின்னை மறந்து அனைத்தையும் நீக்கும்';

  @override
  String get vaultSettingsPinChanged => 'பின் மாற்றப்பட்டது.';

  @override
  String get vaultSettingsBioTurnedOff => 'கைரேகைத் திறத்தல் அணைக்கப்பட்டது.';

  @override
  String get vaultSettingsBioTurnedOn => 'கைரேகைத் திறத்தல் இயக்கப்பட்டது.';

  @override
  String get vaultSettingsClearDataTitle => 'வால்ட் தரவை நீக்கவா?';

  @override
  String get vaultSettingsClearDataDesc =>
      'கிளவுட் வால்ட்டிலிருந்து அனைத்துச் செய்திகளையும் நீக்கும். பின் அப்படியே இருக்கும்.';

  @override
  String get vaultSettingsClearDataCancel => 'ரத்து';

  @override
  String get vaultSettingsClearDataConfirm => 'தரவை நீக்கு';

  @override
  String get vaultSettingsDataDeleted => 'வால்ட் தரவு நீக்கப்பட்டது.';

  @override
  String get vaultSettingsResetTitle => 'வால்ட்டை ரீசெட் செய்யவா?';

  @override
  String get vaultSettingsResetDesc =>
      'அனைத்தையும் நீக்கும். புதிய பின்னை அமைக்க வேண்டும்.';

  @override
  String get vaultSettingsResetConfirm => 'ரீசெட் செய்';

  @override
  String get vaultSettingsChangeDialogDesc =>
      'புதிய பின்னால் அனைத்தும் மாற்றப்படும். செயலியைத் திறந்து வைக்கவும்.';

  @override
  String get vaultSettingsCurrentPin => 'தற்போதைய பின்';

  @override
  String get vaultSettingsNewPin => 'புதிய பின்';

  @override
  String get vaultSettingsConfirmNewPin => 'புதிய பின்னை உறுதி செய்';

  @override
  String get vaultSettingsEnterCurrentPin => 'தற்போதைய பின்னை உள்ளிடவும்.';

  @override
  String get vaultSettingsNewPinMinLength =>
      'குறைந்தது 6 எழுத்துகள் இருக்க வேண்டும்.';

  @override
  String get vaultSettingsNewPinMismatch => 'புதிய பின்கள் பொருந்தவில்லை.';

  @override
  String get vaultSettingsCurrentPinIncorrect => 'தற்போதைய பின் தவறானது.';

  @override
  String vaultSettingsReencryptingCount(int done, int total) {
    return '$total-இல் $done மீண்டும் என்க்ரிப்ட் ஆகிறது…';
  }

  @override
  String get vaultSettingsChangeBtn => 'மாற்று';

  @override
  String get vaultSettingsBioPinDialogTitle => 'உங்கள் பின்னை உள்ளிடவும்';

  @override
  String get vaultSettingsBioPinDialogDesc =>
      'கைரேகைக்காக உங்கள் பின் தேவைப்படுகிறது.';

  @override
  String get vaultSettingsContinueBtn => 'தொடரவும்';

  @override
  String get premiumTitle => 'GupShupGo ப்ரோ';

  @override
  String get premiumSubtitleMember => 'நீங்கள் ஒரு ப்ரோ உறுப்பினர்! 🎉';

  @override
  String get premiumSubtitleUnlock => 'முழு அனுபவத்தைத் திறக்கவும்';

  @override
  String premiumActiveDaysRemaining(int days) {
    return '$days நாட்கள் மீதமுள்ளன';
  }

  @override
  String get premiumFeaturesHeader => 'ப்ரோ மூலம் உங்களுக்குக் கிடைப்பவை';

  @override
  String get premiumPlansHeader => 'திட்டத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get premiumSubscribeBtn => 'இப்போதே சந்தா பெறுங்கள்';

  @override
  String get premiumCancelAnytime =>
      'Google Play-இல் எப்போது வேண்டுமானாலும் ரத்து செய்யலாம்.';

  @override
  String get premiumRestoreBtn => 'முந்தைய வாங்குதலை மீட்டெடு';

  @override
  String get premiumRestoring => 'மீட்டெடுக்கப்படுகிறது…';

  @override
  String get premiumRestoredSuccess => 'ப்ரோ சந்தா மீட்டெடுக்கப்பட்டது! 🎉';

  @override
  String get premiumNoActiveSub => 'செயலில் உள்ள சந்தா எதுவும் இல்லை.';

  @override
  String get premiumProductUnavailable => 'பொருள் கிடைக்கவில்லை.';

  @override
  String get premiumFeatureMediaTitle => 'மீடியா தருணங்கள்';

  @override
  String get premiumFeatureMediaDesc =>
      'புகைப்படங்கள் & வீடியோக்களை ஸ்டேட்டஸாகப் பகிரவும்';

  @override
  String get premiumFeatureMediaFree => 'உரை மட்டும்';

  @override
  String get premiumFeatureMediaPro => 'படங்கள் + வீடியோக்கள்';

  @override
  String get premiumFeatureScreenShareTitle => 'திரைப் பகிர்வு';

  @override
  String get premiumFeatureScreenShareDesc =>
      'அரட்டையின் போது திரையை நேரடியாகப் பகிரவும்';

  @override
  String get premiumFeatureScreenShareFree => 'பூட்டப்பட்டது';

  @override
  String get premiumFeatureScreenSharePro => 'முழு அணுகல்';

  @override
  String get premiumFeatureThemesTitle => 'அரட்டை தீம்கள்';

  @override
  String get premiumFeatureThemesDesc =>
      'தனிப்பயன் பின்னணிகள் மற்றும் வண்ணக் குமிழ்கள்';

  @override
  String get premiumFeatureThemesFree => '6 தீம்கள்';

  @override
  String get premiumFeatureThemesPro => 'அனைத்து 12 + உங்கள் புகைப்படம்';

  @override
  String get premiumFeatureVoiceTitle => 'நீண்ட குரல் செய்திகள்';

  @override
  String get premiumFeatureVoiceDesc =>
      'நீண்ட குரல் குறிப்புகளைப் பதிவு செய்யவும்';

  @override
  String get premiumFeatureVoiceFree => '2 நிமிடங்கள்';

  @override
  String get premiumFeatureVoicePro => 'வரம்பற்றது';

  @override
  String get premiumFeatureQualityTitle => 'உயர்தர மீடியா';

  @override
  String get premiumFeatureQualityDesc =>
      'தெளிவான படங்கள் மற்றும் 90 வினாடி வீடியோக்கள்';

  @override
  String get premiumFeatureQualityFree => 'வழக்கமான தரம்';

  @override
  String get premiumFeatureQualityPro => 'உயர்தரம் + 90s வீடியோக்கள்';

  @override
  String get premiumFeatureBondTitle => 'பாண்ட் மீட்டெடுப்பு';

  @override
  String get premiumFeatureBondDesc =>
      'முறிந்த பாண்டுகளை இலவசமாக மீட்டெடுக்கவும்';

  @override
  String get premiumFeatureBondFree => 'புள்ளிகள் அல்லது விளம்பரம்';

  @override
  String get premiumFeatureBondPro => 'வாரத்திற்கு 1 இலவசம்';

  @override
  String get premiumFeatureBadgeTitle => 'ப்ரோ பேட்ஜ்';

  @override
  String get premiumFeatureBadgeDesc => 'உங்கள் ப்ரோ அந்தஸ்தைக் காட்டவும்';

  @override
  String get premiumFeatureBadgeFree => 'பேட்ஜ் இல்லை';

  @override
  String get premiumFeatureBadgePro => 'சிறப்பு ப்ரோ பேட்ஜ்';

  @override
  String get premiumFeatureExportTitle => 'அரட்டை ஏற்றுமதி';

  @override
  String get premiumFeatureExportDesc =>
      'அரட்டையை PDF அல்லது உரையாகச் சேமிக்கவும்';

  @override
  String get premiumFeatureExportFree => 'கிடைக்கவில்லை';

  @override
  String get premiumFeatureExportPro => 'PDF & TXT ஏற்றுமதி';

  @override
  String get premiumFeatureAdFreeTitle => 'விளம்பரமில்லா அனுபவம்';

  @override
  String get premiumFeatureAdFreeDesc =>
      'செயலியில் எந்த பேனர் விளம்பரமும் இல்லை';

  @override
  String get premiumFeatureAdFreeFree => 'பேனர்கள் உண்டு';

  @override
  String get premiumFeatureAdFreePro => 'பேனர்கள் இல்லை';

  @override
  String get premiumPlanMonthly => 'மாதாந்திர';

  @override
  String get premiumPlanYearly => 'வருடாந்திர';

  @override
  String get premiumPlanSavings => '~33% சேமிப்பு';

  @override
  String get premiumPeriodMonth => '/மாதம்';

  @override
  String get premiumPeriodYear => '/ஆண்டு';

  @override
  String get nearbyOfflineChatTitle => 'ஆஃப்லைன் அரட்டை';

  @override
  String get nearbySearchingDevices => 'அருகிலுள்ள சாதனங்களைத் தேடுகிறது…';

  @override
  String get nearbyTooltipStop => 'ஆஃப்லைன் அரட்டையை நிறுத்து';

  @override
  String get nearbyTooltipStart => 'ஆஃப்லைன் அரட்டையைத் தொடங்கு';

  @override
  String get nearbyDevicesSection => 'அருகிலுள்ள சாதனங்கள்';

  @override
  String get nearbyDiscoveryOn => 'கண்டறிதல் ஆன்';

  @override
  String get nearbyDiscoveryOff => 'கண்டறிதல் ஆஃப்';

  @override
  String get nearbyHeroTitle => 'ஆஃப்லைன் பயன்முறை';

  @override
  String nearbyHeroNearbyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count அருகில்',
      one: '1 அருகில்',
    );
    return '$_temp0';
  }

  @override
  String get nearbyHeroOff => 'ஆஃப்லைன் அரட்டை அணைக்கப்பட்டுள்ளது';

  @override
  String get nearbyHeroDesc =>
      '100 மீட்டருக்குள் சாதனங்களை ஸ்கேன் செய்கிறது. இணையம் தேவையில்லை.';

  @override
  String get nearbyYourNameHint => 'உங்கள் பெயர்';

  @override
  String get nearbyEmptySearching => 'அருகிலுள்ள சாதனங்களைத் தேடுகிறது…';

  @override
  String get nearbyEmptyOff => 'ஆஃப்லைன் அரட்டை அணைக்கப்பட்டுள்ளது';

  @override
  String get nearbyEmptySearchingDesc =>
      'புளூடூத் ஆன் செய்து மற்ற சாதனங்களில் GupShupGo-வைத் திறந்து வைக்கவும்.';

  @override
  String get nearbyEmptyOffDesc =>
      'ஸ்கேன் செய்ய மேலே உள்ள தொடங்கு பொத்தானைத் தொடவும்.';

  @override
  String get nearbyPeerConnected => 'இணைக்கப்பட்டது · அரட்டையடிக்கத் தட்டவும்';

  @override
  String get nearbyPeerConnecting => 'இணைகிறது…';

  @override
  String get nearbyPeerTapToConnect => 'இணையத் தட்டவும்';

  @override
  String get nearbyActionChat => 'அரட்டை';

  @override
  String get nearbyActionConnecting => 'இணைகிறது';

  @override
  String get nearbyActionConnect => 'இணை';

  @override
  String get nearbyPermNeededTitle => 'அனுமதிகள் தேவை';

  @override
  String get nearbyPermNeededDesc =>
      'இணையமின்றி இணைக்க புளூடூத் அனுமதி தேவைப்படுகிறது.';

  @override
  String get nearbyTryAgainBtn => 'மீண்டும் முயற்சி செய்';

  @override
  String get nearbySettingsBtn => 'அமைப்புகள்';

  @override
  String get nearbyHelpTip =>
      'சாதனங்கள் தெரியவில்லையா? இரண்டிலும் புளூடூத் ஆன் செய்யப்பட்டுள்ளதா எனப் பார்க்கவும்.';

  @override
  String get anonLobbyTitle => 'அநாமதேய அரட்டை';

  @override
  String get anonLobbyFinding => 'ஒருவரைத் தேடுகிறது…';

  @override
  String get anonLobbyHangTight =>
      'காத்திருங்கள் — ஒரு புதிய நபருடன் இணைக்கப்படுவீர்கள்.';

  @override
  String get anonLobbyCancelBtn => 'தேடலை ரத்து செய்';

  @override
  String get anonLobbyPrivacyNote => 'உங்கள் அடையாளம் மறைக்கப்பட்டிருக்கும்.';

  @override
  String get anonLobbyConnecting => 'இணைகிறது…';

  @override
  String get anonLobbyWaitingOthers =>
      'மற்றவர்கள் ஆன்லைனுக்கு வரும் வரை காத்திருக்கிறது…';

  @override
  String anonLobbyOnlineCount(int count) {
    return '$count பேர் இப்போது ஆன்லைனில்';
  }

  @override
  String get anonChatNotEncrypted => 'செய்திகள் என்க்ரிப்ட் செய்யப்படவில்லை';

  @override
  String get anonChatRequestSentTooltip => 'கோரிக்கை அனுப்பப்பட்டது';

  @override
  String get anonChatAddFriendTooltip => 'நண்பராகச் சேர்';

  @override
  String get anonChatNextStrangerTooltip => 'அடுத்த நபர்';

  @override
  String get anonChatReportTooltip => 'புகாரளி';

  @override
  String get anonChatSayHi => 'வணக்கம் சொல்லுங்கள்! 👋';

  @override
  String get anonChatFriendsTransition =>
      'இப்போது நீங்கள் நண்பர்கள்! பாதுகாப்பான அரட்டை திறக்கிறது…';

  @override
  String get anonChatStrangerDisconnected => 'அந்நியர் வெளியேறிவிட்டார் 👋';

  @override
  String get anonChatFindNextBtn => 'அடுத்தவரைக் கண்டுபிடி';

  @override
  String get anonChatFriendReqTitle => 'இணைய விரும்புகிறார்!';

  @override
  String get anonChatFriendReqDesc =>
      'ஏற்றுக் கொண்டால் அடையாளம் வெளிப்படும், என்க்ரிப்ட் அரட்டை தொடங்கும்.';

  @override
  String get anonChatDecline => 'நிராகரி';

  @override
  String get anonChatAccept => 'ஏற்றுக்கொள்';

  @override
  String get anonChatWaitingReqTitle => 'நட்புக் கோரிக்கை அனுப்பப்பட்டது';

  @override
  String get anonChatWaitingReqDesc => 'பதிலுக்காகக் காத்திருக்கிறது…';

  @override
  String get anonChatReportTitle => 'புகாரளிக்கவும்';

  @override
  String get anonChatReportQuestion => 'ஏன் புகாரளிக்கிறீர்கள்?';

  @override
  String get anonChatReportReasonInappropriate => 'பொருத்தமற்ற உள்ளடக்கம்';

  @override
  String get anonChatReportReasonHarassment => 'துன்புறுத்தல்';

  @override
  String get anonChatReportReasonSpam => 'ஸ்பேம் அல்லது மோசடி';

  @override
  String get anonChatReportReasonThreatening => 'அச்சுறுத்தும் நடத்தை';

  @override
  String get anonChatReportReasonOther => 'மற்றவை';

  @override
  String get anonChatReportCancel => 'ரத்து';

  @override
  String get anonChatReportSubmit => 'புகாரளித்து வெளியேறு';

  @override
  String get anonChatReportSubmitted => 'புகார் சமர்ப்பிக்கப்பட்டது.';

  @override
  String get anonChatViewOnceVideoTitle => 'ஒருமுறை இயக்கவா?';

  @override
  String get anonChatViewOncePhotoTitle => 'ஒருமுறை திறக்கவா?';

  @override
  String get anonChatViewOnceVideoDesc =>
      'இந்த வீடியோவை ஒருமுறை மட்டுமே பார்க்க முடியும்.';

  @override
  String get anonChatViewOncePhotoDesc =>
      'இந்த புகைப்படத்தை ஒருமுறை மட்டுமே பார்க்க முடியும்.';

  @override
  String get anonChatViewOnceCancel => 'ரத்து';

  @override
  String get anonChatViewOnceOpen => 'திற';

  @override
  String get unsupportedVersionTitle => 'GupShupGo-வைப் புதுப்பிக்கவும்';

  @override
  String get unsupportedVersionDesc =>
      'இந்தப் பதிப்பு இனி செயல்படாது. புதிய பதிப்பிற்குப் புதுப்பிக்கவும்.';

  @override
  String get unsupportedVersionUpdateNow => 'இப்போதே புதுப்பி';

  @override
  String get unsupportedVersionOpenPlayStore => 'Play Store-ஐத் திற';

  @override
  String publicProfileNotFound(String username) {
    return '@$username கிடைக்கவில்லை';
  }

  @override
  String get publicProfileUserNotFound => 'பயனர் கிடைக்கவில்லை';

  @override
  String get publicProfileNotFoundDesc =>
      'இந்த ஹேண்டில் இல்லை அல்லது இணைப்பு உடைந்துவிட்டது.';

  @override
  String get publicProfileTitle => 'சுயவிவரம்';

  @override
  String get publicProfileOnline => 'ஆன்லைன்';

  @override
  String publicProfileLastSeen(String time) {
    return 'கடைசியாகப் பார்த்தது $time';
  }

  @override
  String get publicProfileJustNow => 'சற்றுமுன்';

  @override
  String publicProfileMinutesAgo(int minutes) {
    return '$minutes நிமிடம் முன்';
  }

  @override
  String publicProfileHoursAgo(int hours) {
    return '$hours மணிநேரம் முன்';
  }

  @override
  String publicProfileDaysAgo(int days) {
    return '$days நாள் முன்';
  }

  @override
  String publicProfileJoined(String date) {
    return '$date இல் இணைந்தார்';
  }

  @override
  String get publicProfileOwnLink => 'இது உங்கள் சொந்த இணைப்பு.';

  @override
  String publicProfileGupPoints(int points) {
    return '$points கப் புள்ளிகள்';
  }

  @override
  String publicProfileLevel(int level) {
    return 'நிலை $level';
  }

  @override
  String get publicProfileStatPoints => 'புள்ளிகள்';

  @override
  String get publicProfileStatBadges => 'பேட்ஜ்கள்';

  @override
  String get publicProfileStatBestBond => 'சிறந்த பாண்ட்';

  @override
  String get publicProfileBadges => 'பேட்ஜ்கள்';

  @override
  String get qrScannerTitle => 'QR குறியீட்டை ஸ்கேன் செய்';

  @override
  String get qrScannerFlashOnTooltip => 'ஃப்ளாஷ் ஆன்';

  @override
  String get qrScannerFlashOffTooltip => 'ஃப்ளாஷ் ஆஃப்';

  @override
  String get qrScannerPrompt => 'கேமராவை QR குறியீட்டை நோக்கிக் காட்டவும்';

  @override
  String get qrScannerNotProfileCode => 'இது GupShupGo குறியீடு அல்ல.';

  @override
  String get qrScannerCameraErrorTitle => 'கேமராவைத் தொடங்க முடியவில்லை.';

  @override
  String get qrScannerCameraErrorRetry => 'மீண்டும் முயற்சிக்கவும்.';

  @override
  String get qrScannerPermissionMsg => 'ஸ்கேன் செய்ய கேமரா அனுமதி தேவை.';

  @override
  String get qrScannerPermissionAllow => 'கேமராவுக்கு அனுமதி அளி';

  @override
  String get qrScannerBlockedMsg =>
      'கேமரா தடுக்கப்பட்டுள்ளது. அமைப்புகளில் இயக்கவும்.';

  @override
  String get qrScannerBlockedSettings => 'அமைப்புகளைத் திற';

  @override
  String get screenShareIncomingTitle => 'திரைப் பகிர்வு அழைப்பு';

  @override
  String get screenShareWantsToShare => 'திரையைப் பகிர விரும்புகிறார்';

  @override
  String get screenShareReject => 'நிராகரி';

  @override
  String get screenShareAccept => 'ஏற்றுக்கொள்';

  @override
  String get screenShareCantAccept => 'ஏற்க முடியவில்லை.';

  @override
  String screenShareDeclined(String name) {
    return '$name நிராகரித்துவிட்டார்';
  }

  @override
  String get screenShareNoAnswer => 'பதில் இல்லை';

  @override
  String get screenShareStartError => 'தொடங்க முடியவில்லை';

  @override
  String get screenShareStatusRequesting => 'அனுமதி கேட்கப்படுகிறது';

  @override
  String get screenShareStatusInitializing => 'தொடங்குகிறது';

  @override
  String get screenShareStatusWaitingParticipant => 'காத்திருக்கிறது';

  @override
  String get screenShareStatusActive => 'திரைப் பகிர்வு நேரலையில்';

  @override
  String screenShareSubWaitingAccept(String name) {
    return '$name ஏற்கும் வரை காத்திருக்கிறது…';
  }

  @override
  String get screenShareSubEstablishing => 'இணைப்பு ஏற்படுகிறது...';

  @override
  String screenShareSubWaitingJoin(String name) {
    return '$name இணையும் வரை காத்திருக்கிறது...';
  }

  @override
  String get screenShareSubActive => 'உங்கள் திரை தெரிகிறது.';

  @override
  String get screenShareBadgeRequesting => 'கோருகிறது';

  @override
  String get screenShareBadgeConnecting => 'இணைகிறது';

  @override
  String get screenShareSharedWith => 'பகிரப்பட்டது: ';

  @override
  String get screenShareRequestingFrom => 'கோரப்படுகிறது: ';

  @override
  String get screenShareMinimizeTip => 'பயன்படுத்திக்கொண்டே சிறிதாக்கலாம்.';

  @override
  String get screenShareStop => 'பகிர்வை நிறுத்து';

  @override
  String get screenShareCancelRequest => 'கோரிக்கையை ரத்து செய்';

  @override
  String screenShareViewerTitle(String name) {
    return '$name பகிர்கிறார்';
  }

  @override
  String get screenShareViewerLive => 'நேரலை';

  @override
  String get screenShareViewerMinimize => 'சிறிதாக்கு';

  @override
  String get screenShareViewerLeave => 'வெளியேறு';

  @override
  String screenShareViewerWaitingStream(String name) {
    return 'காத்திருக்கிறது…';
  }

  @override
  String get screenShareViewerConnecting => 'இணைகிறது...';

  @override
  String get viewOnceVideoTitle => 'வீடியோ · ஒருமுறை பார்வை';

  @override
  String get viewOncePhotoTitle => 'படம் · ஒருமுறை பார்வை';

  @override
  String get viewOnceCantOpen => 'திறக்க முடியவில்லை.';

  @override
  String get viewOnceUnavailable => 'இனி கிடைக்காது.';

  @override
  String get viewOnceBlockedFooter => 'ஸ்கிரீன்ஷாட்கள் தடுக்கப்பட்டுள்ளன.';

  @override
  String get anonRestoreBanner => 'அநாமதேய பேனர்';

  @override
  String get contactsInviteFriends => 'நண்பர்களை GupShupGo-க்கு அழைக்கவும்';

  @override
  String get inviteImageShareFailed =>
      'படத்தைப் பகிர முடியவில்லை. மீண்டும் முயலவும் அல்லது இணைப்பைப் பகிரவும்.';

  @override
  String get viewOnceUnblockedFooter => 'மீண்டும் திறக்க முடியாது.';

  @override
  String get tabMessages => 'செய்திகள்';
}
