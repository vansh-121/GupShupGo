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
  String get homeNavChats => 'அரட்டைகள்';

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
}
