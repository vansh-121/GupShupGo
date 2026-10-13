// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get commonCancel => 'रद्द करें';

  @override
  String get commonOk => 'ठीक है';

  @override
  String get commonContinue => 'जारी रखें';

  @override
  String get commonSave => 'सहेजें';

  @override
  String get commonRetry => 'पुनः प्रयास करें';

  @override
  String get commonClose => 'बंद करें';

  @override
  String get commonGotIt => 'समझ गए';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsLanguageTitle => 'भाषा';

  @override
  String get settingsLanguageSubtitle => 'अपनी पसंदीदा भाषा चुनें';

  @override
  String get languagePickerTitle => 'भाषा';

  @override
  String get languageSystemDefault => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get languageSystemDefaultSubtitle => 'अपने डिवाइस की भाषा के अनुसार';

  @override
  String get loginContinueWithPhone => 'फ़ोन के साथ जारी रखें';

  @override
  String get loginContinueWithGoogle => 'Google के साथ जारी रखें';

  @override
  String get loginUseEmailPassword => 'ईमेल और पासवर्ड का उपयोग करें';

  @override
  String get loginSignIn => 'साइन इन करें';

  @override
  String get loginSignUp => 'साइन अप करें';

  @override
  String get loginCreateAccount => 'खाता बनाएं';

  @override
  String get loginForgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get loginOfflineChat => 'ऑफ़लाइन चैट';

  @override
  String get loginHintName => 'आपका नाम';

  @override
  String get loginHintEmail => 'ईमेल';

  @override
  String get loginHintPassword => 'पासवर्ड';

  @override
  String get loginPasswordHelper =>
      'कम से कम 8 अक्षर, जिसमें एक अक्षर और एक संख्या हो';

  @override
  String loginResetEmailSent(String email) {
    return '$email पर पासवर्ड रीसेट ईमेल भेजा गया';
  }

  @override
  String get loginErrorEnterEmail => 'कृपया अपना ईमेल दर्ज करें';

  @override
  String get loginErrorValidEmail => 'कृपया एक मान्य ईमेल दर्ज करें';

  @override
  String get loginErrorEnterPassword => 'कृपया अपना पासवर्ड दर्ज करें';

  @override
  String get loginErrorPasswordMin6 =>
      'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए';

  @override
  String get loginErrorEnterPasswordSignup => 'कृपया एक पासवर्ड दर्ज करें';

  @override
  String get loginErrorPasswordMin8 =>
      'पासवर्ड कम से कम 8 अक्षरों का होना चाहिए';

  @override
  String get loginErrorPasswordLetter =>
      'पासवर्ड में कम से कम एक अक्षर होना चाहिए';

  @override
  String get loginErrorPasswordNumber =>
      'पासवर्ड में कम से कम एक संख्या होनी चाहिए';

  @override
  String get loginErrorEnterName => 'कृपया अपना नाम दर्ज करें';

  @override
  String get loginErrorGoogleCancelled => 'Google साइन-इन रद्द कर दिया गया था।';

  @override
  String get loginErrorProfileLoad =>
      'आपकी प्रोफ़ाइल लोड नहीं हो सकी। अपना कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String get loginErrorGoogleFailed =>
      'Google साइन-इन विफल रहा। कृपया पुनः प्रयास करें।';

  @override
  String get loginErrorSignInFailed =>
      'साइन इन करने में विफल। कृपया पुनः प्रयास करें।';

  @override
  String get loginErrorSignUpFailed =>
      'साइन अप करने में विफल। कृपया पुनः प्रयास करें।';

  @override
  String get loginErrorGeneric => 'कोई त्रुटि हुई। कृपया पुनः प्रयास करें।';

  @override
  String get loginErrorResetFailed =>
      'रीसेट ईमेल भेजने में विफल। कृपया पुनः प्रयास करें।';

  @override
  String get loginErrorUserNotFound =>
      'इस ईमेल से कोई खाता नहीं मिला। कृपया साइन अप करें।';

  @override
  String get loginErrorWrongPassword => 'गलत पासवर्ड। कृपया पुनः प्रयास करें।';

  @override
  String get loginErrorEmailInUse =>
      'इस ईमेल से पहले से ही एक खाता मौजूद है। कृपया साइन इन करें।';

  @override
  String get loginErrorInvalidEmail => 'कृपया एक मान्य ईमेल पता दर्ज करें।';

  @override
  String get loginErrorWeakPassword =>
      'पासवर्ड बहुत कमज़ोर है। कम से कम 6 अक्षरों का उपयोग करें।';

  @override
  String get loginErrorInvalidCredential =>
      'अमान्य ईमेल या पासवर्ड। कृपया जांचें और पुनः प्रयास करें।';

  @override
  String get loginErrorTooManyRequests =>
      'बहुत सारे प्रयास। कृपया बाद में पुनः प्रयास करें。';

  @override
  String get homeNavChats => 'गपशप';

  @override
  String get homeNavMoments => 'पल';

  @override
  String get homeNavCalls => 'कॉल';

  @override
  String get homeNavProfile => 'प्रोफ़ाइल';

  @override
  String get homeTooltipOfflineChat =>
      'ऑफ़लाइन चैट — आस-पास के लोगों से बात करें';

  @override
  String get homeTooltipSearch => 'खोजें';

  @override
  String get homeMenuProfile => 'प्रोफ़ाइल';

  @override
  String get homeMenuSettings => 'सेटिंग्स';

  @override
  String get homeMenuRateUs => 'रेट करें';

  @override
  String get homeMenuReportIssue => 'समस्या की रिपोर्ट करें';

  @override
  String get homeMenuWhatsNew => 'नया क्या है';

  @override
  String get homeMenuLogOut => 'लॉग आउट';

  @override
  String get homeEmptyChatsTitle => 'अभी कोई चैट नहीं';

  @override
  String get homeEmptyChatsSubtitle =>
      'नीचे दिए गए बटन पर टैप करके बातचीत शुरू करें';

  @override
  String get homeNewChatButton => 'नई चैट';

  @override
  String get homeAiAssistantTitle => 'GupAI';

  @override
  String get homeAiAssistantSubtitle =>
      'ड्राफ्ट करें, अनुवाद करें, सारांश बनाएं और बहुत कुछ';

  @override
  String get homeStrangerMatchTitle => 'अजनबी से जुड़ें';

  @override
  String get homeStrangerMatchSubtitle =>
      'गुमनाम चैट — मैच करने के लिए टैप करें!';

  @override
  String get homeMyMoment => 'मेरा पल';

  @override
  String get homeRecentMoments => 'हाल के पल';

  @override
  String get homeEmptyMomentsTitle => 'अभी कोई अपडेट नहीं।';

  @override
  String get homeEmptyMomentsSubtitle => 'साझा करने के लिए कैमरे पर टैप करें।';

  @override
  String get homeTapToAddMoment => 'अपडेट जोड़ने के लिए टैप करें';

  @override
  String get homeEmptyCallsTitle => 'कोई कॉल इतिहास नहीं';

  @override
  String get homeEmptyCallsSubtitle => 'आपकी हाल की कॉल यहां दिखाई देंगी';

  @override
  String get chatInputHint => 'संदेश लिखें...';

  @override
  String get chatSearchHint => 'संदेश खोजें...';

  @override
  String get chatStatusTyping => 'टाइप कर रहे हैं...';

  @override
  String get chatStatusOnline => 'ऑनलाइन';

  @override
  String get chatStatusOffline => 'ऑफ़लाइन';

  @override
  String chatStatusLastSeen(String time) {
    return 'अंतिम बार देखा $time';
  }

  @override
  String get chatEndToEndEncrypted => 'एंड-टू-एंड एन्क्रिप्टेड';

  @override
  String get chatNoInternetOfflineTitle =>
      'इंटरनेट नहीं है? आस-पास के डिवाइस से ऑफ़लाइन चैट करें';

  @override
  String get chatEnableOfflineButton => 'सक्षम करें';

  @override
  String get chatSlideToCancel => 'रद्द करने के लिए स्लाइड करें';

  @override
  String get chatTooltipVoiceCall => 'वॉयस कॉल';

  @override
  String get chatTooltipVideoCall => 'वीडियो कॉल';

  @override
  String get chatMenuContactInfo => 'संपर्क जानकारी';

  @override
  String get chatMenuSearch => 'खोजें';

  @override
  String get chatMenuChatTheme => 'चैट थीम';

  @override
  String get chatMenuExportChat => 'चैट निर्यात करें';

  @override
  String get chatMenuMuteNotifications => 'सूचनाएं म्यूट करें';

  @override
  String get chatMenuUnmuteNotifications => 'सूचनाएं अनम्यूट करें';

  @override
  String get chatMenuBlockContact => 'संपर्क को ब्लॉक करें';

  @override
  String get chatActionReply => 'उत्तर दें';

  @override
  String get chatActionCopy => 'कॉपी करें';

  @override
  String get chatActionForward => 'आगे भेजें';

  @override
  String get chatActionTranslate => 'अनुवाद करें';

  @override
  String get chatActionSummarise => 'सारांश बनाएं';

  @override
  String get chatActionAskGupAi => 'GupAI से पूछें';

  @override
  String get chatActionEdit => 'संपादित करें';

  @override
  String get chatActionDelete => 'हटाएं';

  @override
  String get chatDeleteMessageTitle => 'संदेश हटाएं?';

  @override
  String get chatDeleteMessageForEveryonePrompt =>
      'इसे केवल अपने लिए हटाएं, या सभी के लिए?';

  @override
  String chatDeleteMessageForMeOnlyPrompt(String name) {
    return 'यह केवल आपके डिवाइस से हटेगा। $name इसे देख सकेंगे।';
  }

  @override
  String get chatDeleteForMe => 'मेरे लिए हटाएं';

  @override
  String get chatDeleteForEveryone => 'सभी के लिए हटाएं';

  @override
  String chatBlockContactTitle(String name) {
    return '$name को ब्लॉक करें?';
  }

  @override
  String get chatBlockContactPrompt =>
      'ब्लॉक किए गए संपर्क आपको संदेश या कॉल नहीं कर सकते। आप उन्हें सेटिंग्स → गोपनीयता से अनब्लॉक कर सकते हैं।';

  @override
  String get chatBlockButton => 'ब्लॉक करें';

  @override
  String get chatForwardTo => 'आगे भेजें';

  @override
  String get chatNoForwardChats => 'आगे भेजने के लिए कोई अन्य चैट नहीं';

  @override
  String get chatCannotSendMediaBlocked => 'इस संपर्क को मीडिया नहीं भेज सकते';

  @override
  String get attachmentShareTitle => 'साझा करें';

  @override
  String get attachmentPhoto => 'फ़ोटो';

  @override
  String get attachmentPhotoSubtitle => 'गैलरी से एक छवि चुनें';

  @override
  String get attachmentVideo => 'वीडियो';

  @override
  String get attachmentVideoSubtitle => 'गैलरी से एक वीडियो चुनें';

  @override
  String get attachmentDocument => 'दस्तावेज़';

  @override
  String get attachmentDocumentSubtitle =>
      'पीडीएफ, ऑफिस फ़ाइल, संग्रह — मूल रूप में भेजा गया';

  @override
  String get attachmentLocation => 'स्थान';

  @override
  String get attachmentLocationSubtitle => 'अपना वर्तमान स्थान साझा करें';

  @override
  String get attachmentViewOnce => 'एक बार देखें';

  @override
  String get attachmentViewOnceSubtitle =>
      'खोलने के बाद फ़ोटो या वीडियो गायब हो जाता है';

  @override
  String get contactsTitle => 'संपर्क और खोजें';

  @override
  String get contactsTabFriends => 'मित्र';

  @override
  String get contactsTabRequests => 'अनुरोध';

  @override
  String get contactsTabDiscover => 'खोजें';

  @override
  String get contactsScanQrTooltip => 'QR कोड स्कैन करें';

  @override
  String get contactsMyHandleTooltip => 'मेरा हैंडल';

  @override
  String get contactsSetUsernamePrompt =>
      'पहले अपनी प्रोफ़ाइल में @username सेट करें — आपका QR कोड यही साझा करता है।';

  @override
  String get contactsMyQrCodeTitle => 'मेरी प्रोफ़ाइल का QR कोड';

  @override
  String get contactsMyQrCodeSubtitle =>
      'मित्र तुरंत आपसे जुड़ने के लिए इस QR कोड को स्कैन कर सकते हैं';

  @override
  String get contactsCopyProfileLink => 'प्रोफ़ाइल लिंक कॉपी करें';

  @override
  String contactsProfileLinkCopied(String username) {
    return '@$username का प्रोफ़ाइल लिंक कॉपी किया गया!';
  }

  @override
  String get contactsScanSomeonesCode => 'किसी का कोड स्कैन करें';

  @override
  String get contactsPermissionDenied =>
      'संपर्कों तक पहुँचने की अनुमति अस्वीकृत कर दी गई थी।';

  @override
  String get contactsNoUsersFound =>
      'आपके संपर्कों में अभी कोई GupShupGo उपयोगकर्ता नहीं मिला।';

  @override
  String contactsFailedToSync(String error) {
    return 'संपर्क सिंक करने में विफल: $error';
  }

  @override
  String contactsMatchedCount(int count) {
    return 'GupShupGo पर $count संपर्क';
  }

  @override
  String get contactsFromDeviceContacts => 'आपके डिवाइस संपर्कों से';

  @override
  String get contactsLoadFriendsError =>
      'आपके मित्रों को लोड नहीं किया जा सका।';

  @override
  String get contactsNoFriendsTitle => 'अभी कोई मित्र नहीं जोड़े गए';

  @override
  String get contactsNoFriendsPrompt =>
      'उपयोगकर्ताओं को @username, फोन या ईमेल से खोजने और मित्र अनुरोध भेजने के लिए खोजें टैब का उपयोग करें!';

  @override
  String get contactsDiscoverPeopleButton => 'लोगों को खोजें';

  @override
  String get contactsQuickConnectHeader => 'त्वरित कनेक्ट';

  @override
  String get contactsNoSuggestions => 'वर्तमान में कोई सुझाव उपलब्ध नहीं है।';

  @override
  String get contactsLoadRequestsError =>
      'आपके अनुरोधों को लोड नहीं किया जा सका।';

  @override
  String contactsPendingRequestsHeader(int count) {
    return 'लंबित अनुरोध ($count)';
  }

  @override
  String get contactsNoPendingRequestsTitle => 'कोई लंबित अनुरोध नहीं';

  @override
  String get contactsNoPendingRequestsSubtitle =>
      'जब उपयोगकर्ता आपको कनेक्शन अनुरोध भेजेंगे, तो वे यहां दिखाई देंगे।';

  @override
  String get contactsWantsToConnect => 'जुड़ना चाहते हैं';

  @override
  String get contactsAcceptButton => 'स्वीकार करें';

  @override
  String get contactsAcceptFailed =>
      'अनुरोध स्वीकार नहीं किया जा सका। कृपया पुनः प्रयास करें।';

  @override
  String contactsConnectedWith(String name) {
    return '$name से जुड़े!';
  }

  @override
  String get contactsDeclineFailed =>
      'अनुरोध अस्वीकार नहीं किया जा सका। कृपया पुनः प्रयास करें।';

  @override
  String get contactsYouMightKnowHeader => 'आप जान सकते हैं';

  @override
  String get contactsSeeAll => 'सभी देखें';

  @override
  String get contactsSearchHint => 'नाम, @हैंडल, फोन या ईमेल खोजें...';

  @override
  String get contactsTurnOnDiscoverability =>
      'खोज और सुझावों में दिखने के लिए दृश्यता चालू करें।';

  @override
  String get contactsNoMatchingUsersTitle =>
      'कोई मेल खाने वाला उपयोगकर्ता नहीं मिला';

  @override
  String get contactsNoMatchingUsersSubtitle =>
      '@username, फ़ोन नंबर या ईमेल की जाँच करें और पुनः प्रयास करें।';

  @override
  String get contactsDiscoverHeroTitle => 'GupShupGo पर लोगों को खोजें';

  @override
  String get contactsDiscoverHeroSubtitle =>
      'दुनिया भर में उच्च-गुणवत्ता वाले संपर्कों के साथ अपना दायरा बढ़ाएं।';

  @override
  String get contactsSyncDeviceContacts => 'डिवाइस संपर्क सिंक करें';

  @override
  String get contactsSyncingContacts => 'संपर्क सिंक हो रहे हैं...';

  @override
  String get contactsSyncDeviceSubtitle =>
      'फ़ोन संपर्कों से अपने मित्रों को तुरंत खोजें';

  @override
  String get contactsSuggestedUsersHeader => 'सुझाए गए उपयोगकर्ता';

  @override
  String get contactsAddFriendButton => 'मित्र जोड़ें';

  @override
  String get contactsRequestedButton => 'अनुरोध भेजा गया';

  @override
  String contactsRequestSent(String name) {
    return '$name को मित्र अनुरोध भेजा गया!';
  }

  @override
  String get contactsRequestFailed =>
      'मित्र अनुरोध पहले से लंबित है या विफल हो गया।';

  @override
  String get contactsRequestUnavailable => 'वह अनुरोध अब उपलब्ध नहीं है।';

  @override
  String get profileEditTitle => 'प्रोफ़ाइल संपादित करें';

  @override
  String get profileSaveButton => 'सहेजें';

  @override
  String get profileTapToChangePhoto => 'फ़ोटो बदलने के लिए टैप करें';

  @override
  String get profileUpgradeToPro => 'प्रो में अपग्रेड करें';

  @override
  String get profileSectionName => 'आपका नाम';

  @override
  String get profileNameHint => 'अपना नाम दर्ज करें';

  @override
  String get profileSectionHandle => 'विशिष्ट हैंडल';

  @override
  String get profileHandleNotSet => 'अभी सेट नहीं है';

  @override
  String get profileChangeHandle => 'बदलें';

  @override
  String get profileSectionAbout => 'के बारे में';

  @override
  String get profileAboutHint => 'आपके मन में क्या है?';

  @override
  String get profileDefaultAbout => 'अरे! मैं GupShupGo का उपयोग कर रहा हूँ।';

  @override
  String get profileSectionPhone => 'फ़ोन';

  @override
  String get profileSectionEmail => 'ईमेल';

  @override
  String get profileSectionLinkedMethods => 'लिंक किए गए साइन-इन तरीके';

  @override
  String get profileNotLinked => 'लिंक नहीं है';

  @override
  String get profileNameEmpty => 'नाम खाली नहीं हो सकता।';

  @override
  String get profileUpdatedSuccess => 'प्रोफ़ाइल अपडेट की गई';

  @override
  String profileUploadPhotoFailed(String error) {
    return 'फ़ोटो अपलोड करने में विफल: $error';
  }

  @override
  String profileSaveFailed(String error) {
    return 'प्रोफ़ाइल सहेजने में विफल: $error';
  }

  @override
  String get profilePoints => 'अंक';

  @override
  String get profileBadges => 'बैज';

  @override
  String get profileBestBond => 'सर्वश्रेष्ठ बॉन्ड';

  @override
  String get settingsAccountCard => 'खाता';

  @override
  String get settingsProfileTile => 'प्रोफ़ाइल';

  @override
  String get settingsLinkedMethodsTile => 'लिंक किए गए साइन-इन तरीके';

  @override
  String get settingsPhoneTile => 'फ़ोन नंबर';

  @override
  String get settingsEmailTile => 'ईमेल';

  @override
  String get settingsPrivacyCard => 'गोपनीयता';

  @override
  String get settingsDiscoverability => 'दृश्यता';

  @override
  String get settingsLastSeen => 'अंतिम बार देखा गया';

  @override
  String get settingsReadReceipts => 'पढ़े गए संदेश की रसीद';

  @override
  String get settingsAdPreferences => 'विज्ञापन प्राथमिकताएं';

  @override
  String get settingsManage => 'प्रबंधित करें';

  @override
  String get settingsAppearanceCard => 'दिखावट';

  @override
  String get settingsTheme => 'थीम';

  @override
  String get settingsThemeLight => 'लाइट';

  @override
  String get settingsThemeDark => 'डार्क';

  @override
  String get settingsThemeSystem => 'सिस्टम';

  @override
  String get settingsChatTheme => 'चैट थीम';

  @override
  String get settingsHelpSecurityCard => 'सहायता और सुरक्षा';

  @override
  String get settingsHelpCenter => 'सहायता केंद्र';

  @override
  String get settingsReportProblem => 'समस्या की रिपोर्ट करें';

  @override
  String get settingsE2EEShield => 'सुरक्षित एन्क्रिप्शन (वॉल्ट)';

  @override
  String get settingsVerifySafetyNumber => 'सुरक्षा संख्या सत्यापित करें';

  @override
  String get settingsBlockedContacts => 'ब्लॉक किए गए संपर्क';

  @override
  String get settingsClearAllGupHistory => 'सभी चैट इतिहास साफ़ करें';

  @override
  String get settingsRateUs => 'रेट करें';

  @override
  String get settingsWhatsNew => 'नया क्या है';

  @override
  String get settingsCheckForUpdates => 'अपडेट जांचें';

  @override
  String get settingsAppInfo => 'ऐप जानकारी';

  @override
  String get settingsLogOut => 'लॉग आउट';

  @override
  String get settingsLogOutConfirmTitle => 'लॉग आउट';

  @override
  String get settingsLogOutConfirmPrompt =>
      'क्या आप वाकई GupShupGo से लॉग आउट करना चाहते हैं?';

  @override
  String get settingsSigningOut => 'लॉग आउट हो रहे हैं…';

  @override
  String get settingsClearChatsConfirmTitle => 'सभी चैट साफ़ करें';

  @override
  String get settingsClearChatsConfirmPrompt =>
      'यह आपके संपूर्ण संदेश इतिहास को स्थायी रूप से हटा देगा। यह क्रिया पूर्ववत नहीं की जा सकती।';

  @override
  String get settingsDeleteAll => 'सभी हटाएं';

  @override
  String get settingsClearingChats => 'चैट साफ़ हो रही हैं...';

  @override
  String get settingsAllChatsCleared => 'सभी चैट साफ़ हो गईं';

  @override
  String settingsClearChatsFailed(String error) {
    return 'चैट साफ़ करने में विफल: $error';
  }

  @override
  String get settingsChooseThemeTitle => 'थीम चुनें';

  @override
  String get settingsUnlockPremiumFeatures => 'प्रीमियम सुविधाएं अनलॉक करें';

  @override
  String settingsProDaysLeft(String planLabel, int daysRemaining) {
    return '$planLabel · $daysRemaining दिन शेष';
  }

  @override
  String get settingsCheckingForUpdates => 'अपडेट जांचे जा रहे हैं…';

  @override
  String settingsUpToDate(String version) {
    return 'आप नवीनतम संस्करण (v$version) पर हैं।';
  }

  @override
  String get settingsUpdateCheckUnavailable =>
      'अपडेट की जांच नहीं हो सकी। सुनिश्चित करें कि GupShupGo Google Play Store से इंस्टॉल किया गया था।';

  @override
  String get settingsNoBlockedContacts => 'कोई ब्लॉक किया गया संपर्क नहीं';

  @override
  String get settingsUnblock => 'अनब्लॉक करें';

  @override
  String settingsUserUnblocked(String name) {
    return '$name को अनब्लॉक किया गया';
  }

  @override
  String get settingsVerifyContactTitle => 'संपर्क सत्यापित करें';

  @override
  String get settingsVerifyContactSubtitle =>
      'अपनी साझा सुरक्षा संख्या देखने के लिए एक संपर्क चुनें।';

  @override
  String get settingsComputingSafetyNumber =>
      'सुरक्षा संख्या की गणना हो रही है…';

  @override
  String settingsSafetyNumberExplanation(String name) {
    return 'यदि नीचे दी गई संख्या $name के डिवाइस से मेल खाती है, तो आपका एंड-टू-एंड एन्क्रिप्शन सत्यापित है।';
  }

  @override
  String get settingsSafetyNumberNoBundle =>
      'इस संपर्क ने अभी तक कोई एन्क्रिप्शन कुंजी प्रकाशित नहीं की है। वे पुराने संस्करण का उपयोग कर रहे हो सकते हैं।';

  @override
  String get settingsSafetyNumberCompareHint =>
      'व्यक्तिगत रूप से या किसी विश्वसनीय कॉल पर इस संख्या की तुलना करें।';

  @override
  String get callEndToEndEncrypted => 'शुरुआत से अंत तक एन्क्रिप्टेड';

  @override
  String get callSecuring => 'कॉल सुरक्षित की जा रही है…';

  @override
  String get callNotEncrypted => 'एन्क्रिप्टेड नहीं है';

  @override
  String get callIncomingVoice => 'इनकमिंग वॉयस कॉल';

  @override
  String get callIncomingVideo => 'इनकमिंग वीडियो कॉल';

  @override
  String get callVoiceCall => 'वॉयस कॉल';

  @override
  String get callVideoCall => 'वीडियो कॉल';

  @override
  String get callDecline => 'अस्वीकार करें';

  @override
  String get callAccept => 'स्वीकार करें';

  @override
  String get callConnecting => 'कनेक्ट हो रहा है...';

  @override
  String get callSettingUp => 'कॉल सेट अप हो रही है...';

  @override
  String callNotifying(String name) {
    return '$name को सूचित किया जा रहा है...';
  }

  @override
  String get callRinging => 'घंटी बज रही है...';

  @override
  String get callConnected => 'जुड़ गया';

  @override
  String get callOnHold => 'होल्ड पर';

  @override
  String get callCalling => 'कॉल किया जा रहा है...';

  @override
  String get callWaitingForUser => 'उपयोगकर्ता की प्रतीक्षा की जा रही है...';

  @override
  String get callEnded => 'कॉल समाप्त';

  @override
  String get callDeclined => 'कॉल अस्वीकार की गई';

  @override
  String get callNoAnswer => 'कोई उत्तर नहीं';

  @override
  String get callFailedToConnect => 'कनेक्ट करने में विफल';

  @override
  String callFailedToStart(String error) {
    return 'कॉल शुरू करने में विफल: $error';
  }

  @override
  String get callTokenExpired =>
      'टोकन समाप्त या अमान्य है। कृपया कॉल दोबारा शुरू करें।';

  @override
  String callFailedToInit(String type, String error) {
    return '$type कॉल प्रारंभ करने में विफल: $error';
  }

  @override
  String get callTurnOffSpeaker => 'स्पीकर बंद करें';

  @override
  String get callTurnOnSpeaker => 'स्पीकर चालू करें';

  @override
  String get callMuteMic => 'माइक म्यूट करें';

  @override
  String get callUnmuteMic => 'माइक अनम्यूट करें';

  @override
  String get callEndCall => 'कॉल समाप्त करें';

  @override
  String get callSwitchCamera => 'कैमरा बदलें';

  @override
  String get callTurnOffCamera => 'कैमरा बंद करें';

  @override
  String get callTurnOnCamera => 'कैमरा चालू करें';

  @override
  String statusViewedByCount(int count) {
    return '$count लोगों द्वारा देखा गया';
  }

  @override
  String get statusNoViewsYet => 'अभी तक कोई दृश्य नहीं';

  @override
  String statusViewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बार देखा गया',
      one: '1 बार देखा गया',
    );
    return '$_temp0';
  }

  @override
  String get statusDeleteTitle => 'स्टेटस हटाएं';

  @override
  String get statusDeleteConfirm => 'क्या आप वाकई यह स्टेटस हटाना चाहते हैं?';

  @override
  String get statusDeleteButton => 'हटाएं';

  @override
  String get statusReplySent => 'उत्तर भेजा गया';

  @override
  String statusReplyFailed(String error) {
    return 'उत्तर भेजने में विफल: $error';
  }

  @override
  String get statusNoActive => 'कोई सक्रिय स्टेटस नहीं';

  @override
  String get statusCouldNotLoad => 'यह अपडेट लोड नहीं हो सका';

  @override
  String get statusTapToRetry => 'पुनः प्रयास करने के लिए टैप करें';

  @override
  String get statusFailedToLoadImage => 'चित्र लोड करने में विफल';

  @override
  String get statusLoadingVideo => 'वीडियो लोड हो रहा है...';

  @override
  String get statusEnterTextPrompt => 'कृपया कुछ टेक्स्ट दर्ज करें';

  @override
  String get statusNoContactsNotice =>
      'अभी कोई संपर्क नहीं है — स्टेटस पोस्ट करने से पहले चैट शुरू करें।';

  @override
  String statusPostFailed(String error) {
    return 'स्टेटस पोस्ट करने में विफल: $error';
  }

  @override
  String get statusTypeHint => 'स्टेटस लिखें...';

  @override
  String get statusCamera => 'कैमरा';

  @override
  String get statusTakePhoto => 'फोटो लें';

  @override
  String get statusGalleryPhoto => 'गैलरी फोटो';

  @override
  String get statusChooseImageGallery => 'गैलरी से फोटो चुनें';

  @override
  String get statusRecordVideo => 'वीडियो रिकॉर्ड करें';

  @override
  String get statusRecordShortVideo => 'छोटा वीडियो रिकॉर्ड करें';

  @override
  String get statusGalleryVideo => 'गैलरी वीडियो';

  @override
  String get statusChooseVideoGallery => 'गैलरी से वीडियो चुनें';

  @override
  String statusFailedPickImage(String error) {
    return 'फोटो चुनने में विफल: $error';
  }

  @override
  String statusFailedPickVideo(String error) {
    return 'वीडियो चुनने में विफल: $error';
  }

  @override
  String get statusChangeBgColorTooltip => 'पृष्ठभूमि का रंग बदलें';

  @override
  String aiMessagesRemaining(int count) {
    return '$count शेष';
  }

  @override
  String get aiQuotaDialogTitle => 'GupAI संदेश';

  @override
  String aiQuotaRemainingOfTotal(int remaining, int total) {
    return 'आज $total में से $remaining शेष';
  }

  @override
  String aiQuotaUsedResetNote(int used) {
    return 'आज $used उपयोग किए · कल रीसेट होगा। अधिक के लिए विज्ञापन देखें या प्रो बनें।';
  }

  @override
  String get aiQuotaGotIt => 'समझ गया';

  @override
  String get aiTitle => 'GupAI';

  @override
  String get aiSubtitle => 'आपका इन-ऐप सहायक';

  @override
  String get aiEmptyHelpTitle => 'मैं आपकी क्या मदद कर सकता हूँ?';

  @override
  String get aiEmptyHelpSubtitle =>
      'उत्तर का मसौदा तैयार करें, अनुवाद करें, सारांश बनाएं या बस कोई प्रश्न पूछें।';

  @override
  String get meshOfflineChatConnected => 'ऑफ़लाइन चैट · कनेक्टेड';

  @override
  String get meshConnecting => 'कनेक्ट हो रहा है…';

  @override
  String get meshBannerNotice =>
      'ऑफ़लाइन चैट — कोई इंटरनेट नहीं, कोई सर्वर नहीं';

  @override
  String meshSayHiTo(String name) {
    return '$name को नमस्ते कहें';
  }

  @override
  String meshOfflineDescription(String name) {
    return 'आप ऑफ़लाइन चैट में हैं। संदेश आपके और $name के बीच ही रहते हैं।';
  }

  @override
  String get meshMediaUnavailable => 'यह मीडिया अब उपलब्ध नहीं है।';

  @override
  String get meshViewOnceTitle => 'एक बार देखें';

  @override
  String meshViewOncePrompt(String type) {
    return 'आप इस $type को केवल एक बार खोल सकते हैं।';
  }

  @override
  String get arcadeTabOverview => 'अवलोकन';

  @override
  String get arcadeTabChallenges => 'चुनौतियाँ';

  @override
  String get arcadeTabLeaderboard => 'लीडरबोर्ड';

  @override
  String get arcadeFailedLoadStats => 'आंकड़े लोड करने में विफल।';

  @override
  String get aiAskHint => 'GupAI से कुछ भी पूछें…';
}
