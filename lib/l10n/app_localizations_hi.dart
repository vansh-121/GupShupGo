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
  String get homeNavChats => 'संदेश';

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
  String get homeMenuPrivateVault => 'निजी वॉल्ट';

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
  String get attachmentScreenShare => 'स्क्रीन साझा करें';

  @override
  String get attachmentScreenShareSubtitle =>
      'चैट के दौरान अपनी स्क्रीन लाइव दिखाएं';

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

  @override
  String get settingsNotificationsTile => 'सूचनाएं';

  @override
  String get settingsNotificationsStatusOn => 'चालू';

  @override
  String get settingsNotificationsStatusOff => 'बंद';

  @override
  String get settingsNotificationsEnabledToast => 'सूचनाएं चालू हैं।';

  @override
  String get settingsEnableNotificationsTitle => 'सूचनाएं सक्षम करें';

  @override
  String get settingsEnableNotificationsBody =>
      'सूचनाएं बंद हैं। नए संदेशों और कॉलों के बारे में GupShupGo द्वारा सूचित करने के लिए सिस्टम सेटिंग्स खोलें।';

  @override
  String get settingsOpenSystemSettings => 'सेटिंग्स खोलें';

  @override
  String get loginTagline => 'निजी मैसेजिंग जो बिना इंटरनेट के भी काम करती है।';

  @override
  String get settingsPrivacyPolicy => 'गोपनीयता नीति';

  @override
  String get settingsTerms => 'सेवा की शर्तें';

  @override
  String get settingsDeleteAccount => 'खाता हटाएं';

  @override
  String get inviteSheetTitle => 'मित्रों को आमंत्रित करें';

  @override
  String get inviteSheetSubtitle => 'बात फैलाएं — GupShupGo साझा करें';

  @override
  String get inviteShareImageBtn => 'तस्वीर साझा करें';

  @override
  String get inviteShareLinkBtn => 'लिंक साझा करें';

  @override
  String get inviteCopyLinkBtn => 'लिंक कॉपी करें';

  @override
  String get inviteLinkCopied => 'आमंत्रण लिंक कॉपी किया गया';

  @override
  String inviteMessage(String link) {
    return 'GupShupGo पर मेरे साथ चैट करें — यह बिना इंटरनेट के भी काम करता है 👋 $link';
  }

  @override
  String get inviteCardTagline => 'निजी चैट जो ऑफ़लाइन भी काम करती है';

  @override
  String get inviteCardScan => 'डाउनलोड करने के लिए स्कैन करें';

  @override
  String get inviteCardDownload => 'Google Play पर डाउनलोड करें';

  @override
  String get homeMenuInvite => 'मित्रों को आमंत्रित करें';

  @override
  String get invitePromptTitle => 'क्या GupShupGo पसंद आ रहा है?';

  @override
  String get invitePromptBody =>
      'दोस्तों के साथ यह और भी बेहतर है — और बिना इंटरनेट भी चलता है। किसी को आमंत्रित करें?';

  @override
  String get invitePromptInvite => 'मित्रों को आमंत्रित करें';

  @override
  String get invitePromptLater => 'शायद बाद में';

  @override
  String get homeOfflineBannerTitle => 'इंटरनेट नहीं है? कोई समस्या नहीं';

  @override
  String get homeOfflineBannerSubtitle =>
      'आप अभी भी ब्लूटूथ से आस-पास के लोगों को संदेश भेज सकते हैं।';

  @override
  String homeNearbyBannerTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'आस-पास $count लोग',
      one: 'आस-पास 1 व्यक्ति',
    );
    return '$_temp0';
  }

  @override
  String get homeNearbyBannerSubtitle =>
      'ब्लूटूथ पर चैट करें — इंटरनेट की आवश्यकता नहीं।';

  @override
  String get linkBackupTitle => 'बैकअप साइन-इन तरीका जोड़ें';

  @override
  String get linkBackupSubtitle =>
      'Google या ईमेल लिंक करें ताकि सिम न होने पर भी आप वापस साइन इन कर सकें।';

  @override
  String get linkGoogleTitle => 'Google खाता लिंक करें';

  @override
  String get linkGoogleSubtitleLinked => 'लिंक किया गया ✓';

  @override
  String get linkGoogleSubtitleUnlinked => 'बिना सिम के वन-टैप साइन-इन';

  @override
  String get linkGoogleAction => 'लिंक करें';

  @override
  String get linkGoogleSuccess => 'Google खाता सफलतापूर्वक लिंक हो गया!';

  @override
  String get linkGoogleAlreadyUsed =>
      'यह Google खाता पहले से ही एक अलग GupShupGo खाते के रूप में पंजीकृत है। मर्ज करने के लिए, साइन आउट करके Google से साइन इन करें, फिर सेटिंग्स से अपना फोन नंबर लिंक करें।';

  @override
  String get linkGoogleFailed => 'Google लिंकिंग विफल रही। पुनः प्रयास करें।';

  @override
  String get linkSessionExpired =>
      'सत्र समाप्त हो गया। कृपया पुनः साइन इन करें।';

  @override
  String get linkEmailTitle => 'ईमेल और पासवर्ड लिंक करें';

  @override
  String get linkEmailSubtitleLinked => 'लिंक किया गया ✓';

  @override
  String get linkEmailSubtitleUnlinked =>
      'सिम या Google न होने पर ईमेल से साइन इन करें';

  @override
  String get linkEmailActionAdd => 'जोड़ें';

  @override
  String get linkEmailActionCancel => 'रद्द करें';

  @override
  String get linkEmailFieldLabel => 'ईमेल';

  @override
  String get linkPasswordFieldLabel => 'एक पासवर्ड बनाएं';

  @override
  String get linkPasswordHelper => 'न्यूनतम 6 वर्ण';

  @override
  String get linkEmailButton => 'ईमेल लिंक करें';

  @override
  String get linkEmailSuccess => 'ईमेल सफलतापूर्वक लिंक हो गया!';

  @override
  String get linkEmailInvalid => 'एक मान्य ईमेल पता दर्ज करें।';

  @override
  String get linkPasswordTooShort => 'पासवर्ड कम से कम 6 वर्णों का होना चाहिए।';

  @override
  String get linkEmailAlreadyInUse =>
      'यह ईमेल पहले से GupShupGo पर अलग से पंजीकृत है। पहले ईमेल से साइन इन करें, फिर सेटिंग्स से फोन लिंक करें।';

  @override
  String get linkEmailAlreadyLinked =>
      'आपके खाते से पहले से ही एक ईमेल लिंक है।';

  @override
  String get linkEmailFailed => 'ईमेल लिंकिंग विफल रही। पुनः प्रयास करें।';

  @override
  String get linkContinueToApp => 'ऐप पर जारी रखें';

  @override
  String get linkSkipForNow => 'अभी के लिए छोड़ें';

  @override
  String get linkSkip => 'छोड़ें';

  @override
  String get phoneAuthTitleEntry => 'अपने फोन नंबर से साइन इन करें।';

  @override
  String get phoneAuthTitleOtp => 'हमारे द्वारा भेजा गया कोड दर्ज करें।';

  @override
  String get phoneAuthNameHint => 'आपका नाम';

  @override
  String get phoneAuthPhoneHint => 'फ़ोन नंबर';

  @override
  String get phoneAuthUseSim => 'सिम का उपयोग करें';

  @override
  String get phoneAuthSendOtp => 'ओटीपी भेजें';

  @override
  String phoneAuthOtpPrompt(String phone) {
    return '$phone पर भेजा गया 6-अंकीय कोड दर्ज करें';
  }

  @override
  String get phoneAuthOtpPromptGeneric =>
      'हमारे द्वारा भेजा गया 6-अंकीय कोड दर्ज करें';

  @override
  String get phoneAuthOtpHint => 'कोड दर्ज करें';

  @override
  String get phoneAuthVerify => 'सत्यापित करें';

  @override
  String get phoneAuthGoBack => 'वापस जाएं';

  @override
  String get phoneAuthResendCode => 'कोड पुनः भेजें';

  @override
  String get phoneAuthEnterName => 'कृपया अपना नाम दर्ज करें';

  @override
  String get phoneAuthEnterValidPhone => 'कृपया एक मान्य फोन नंबर दर्ज करें';

  @override
  String get phoneAuthEnterCode => 'कृपया कोड दर्ज करें';

  @override
  String get phoneAuthRequestNewCode => 'कृपया नए कोड का अनुरोध करें।';

  @override
  String get phoneAuthCodeIncorrect => 'वह कोड गलत है। कृपया पुनः प्रयास करें।';

  @override
  String get phoneAuthErrCodeIncorrect =>
      'वह कोड गलत है। कृपया जांचें और पुनः प्रयास करें।';

  @override
  String get phoneAuthErrCodeExpired =>
      'कोड की समय सीमा समाप्त हो गई। नया पाने के लिए \"कोड पुनः भेजें\" पर टैप करें।';

  @override
  String get phoneAuthErrTooManyRequests =>
      'बहुत सारे प्रयास। कृपया थोड़ी देर प्रतीक्षा करें और पुनः प्रयास करें।';

  @override
  String get phoneAuthErrInvalidPhone =>
      'वह फोन नंबर अमान्य लग रहा है। कृपया जांचें।';

  @override
  String get phoneAuthErrQuotaExceeded =>
      'एसएमएस सीमा समाप्त। कृपया बाद में प्रयास करें।';

  @override
  String get phoneAuthErrFailed => 'सत्यापन विफल रहा। कृपया पुनः प्रयास करें।';

  @override
  String get usernameSetupAppBarTitle => 'अपना हैंडल चुनें';

  @override
  String get usernameSetupHeaderTitle => 'अपनी पहचान सुरक्षित करें';

  @override
  String get usernameSetupHeaderDesc =>
      'आपका @handle GupShupGo पर आपकी विशिष्ट कुंजी है। अन्य लोग आपका फोन या ईमेल साझा किए बिना आपको सुरक्षित रूप से खोज और जोड़ सकते हैं।';

  @override
  String get usernameSetupInputHint => 'your_handle';

  @override
  String get usernameSetupChecking => 'उपलब्धता की जांच हो रही है...';

  @override
  String usernameSetupAvailable(String handle) {
    return '@$handle उपलब्ध है!';
  }

  @override
  String usernameSetupTaken(String handle) {
    return '@$handle पहले से किसी अन्य उपयोगकर्ता द्वारा लिया गया है।';
  }

  @override
  String get usernameSetupCharRules => '3–20 वर्ण (a-z, 0-9, _)';

  @override
  String get usernameSetupTooShort =>
      'उपयोगकर्ता नाम कम से कम 3 वर्णों का होना चाहिए।';

  @override
  String get usernameSetupTooLong =>
      'उपयोगकर्ता नाम अधिकतम 20 वर्णों का होना चाहिए।';

  @override
  String get usernameSetupInvalidChars =>
      'केवल अक्षरों, संख्याओं और अंडरस्कोर की अनुमति है।';

  @override
  String get usernameSetupRecommended => 'आपके लिए अनुशंसित';

  @override
  String get usernameSetupSaveBtn => 'सहेजें और जारी रखें';

  @override
  String get usernameSetupSkipBtn => 'अभी के लिए छोड़ें';

  @override
  String usernameSetupFailed(String error) {
    return 'उपयोगकर्ता नाम सेट करने में विफल: $error';
  }

  @override
  String get vaultProtectTitle => 'वॉल्ट सुरक्षित करें';

  @override
  String get vaultUnlockTitle => 'वॉल्ट अनलॉक करें';

  @override
  String get vaultSetupDesc =>
      'अपने संदेश इतिहास को एन्क्रिप्ट करने के लिए एक पिन चुनें। नए फोन पर अपने संदेश पढ़ने के लिए आपको इसकी आवश्यकता होगी, इसलिए ऐसा कुछ चुनें जो आपको याद रहे।';

  @override
  String get vaultUnlockDescBio =>
      'इतिहास डिक्रिप्ट करने के लिए अपना पिन दर्ज करें या फिंगरप्रिंट टैप करें।';

  @override
  String get vaultUnlockDescPin =>
      'अपना इतिहास डिक्रिप्ट करने के लिए अपना पिन दर्ज करें।';

  @override
  String get vaultReinstallHint =>
      'इस डिवाइस पर अपना इतिहास पुनर्स्थापित करने के लिए अपना पिन दर्ज करें। आप बाद में फ़िंगरप्रिंट अनलॉक फिर से चालू कर सकते हैं।';

  @override
  String get vaultUnlockWithFingerprint => 'फ़िंगरप्रिंट से अनलॉक करें';

  @override
  String get vaultOrDivider => 'या';

  @override
  String get vaultNewPin => 'नया पिन';

  @override
  String get vaultConfirmPin => 'पिन की पुष्टि करें';

  @override
  String get vaultEnterPin => 'पिन दर्ज करें';

  @override
  String get vaultKeyboardUseLetters => 'अक्षरों का उपयोग करें';

  @override
  String get vaultKeyboardUseNumbers => 'संख्याओं का उपयोग करें';

  @override
  String get vaultRestoreLater => 'बाद में पुनर्स्थापित करें';

  @override
  String get vaultForgotPin => 'पिन भूल गए?';

  @override
  String get vaultSetPinBtn => 'पिन सेट करें';

  @override
  String get vaultDecryptBtn => 'डिक्रिप्ट करें';

  @override
  String get vaultPinMinLength => 'पिन कम से कम 6 वर्णों का होना चाहिए।';

  @override
  String get vaultPinsDoNotMatch => 'पिन मेल नहीं खाते।';

  @override
  String get vaultSetupFailed => 'सेटअप विफल रहा। कनेक्शन जांचें।';

  @override
  String get vaultIncorrectPin => 'गलत पिन। पुनः प्रयास करें।';

  @override
  String get vaultFingerprintOutOfDate =>
      'फ़िंगरप्रिंट अनलॉक पुराना हो चुका है। अपना पिन दर्ज करें।';

  @override
  String get vaultBiometricError =>
      'बायोमेट्रिक त्रुटि। मैन्युअल रूप से पिन दर्ज करें।';

  @override
  String get vaultBioReasonUnlock =>
      'अपने वॉल्ट को अनलॉक करने के लिए बायोमेट्रिक्स का उपयोग करें';

  @override
  String get vaultBioReasonEnrol =>
      'त्वरित अनलॉक सक्षम करने के लिए अपने फ़िंगरप्रिंट की पुष्टि करें';

  @override
  String get vaultAskBioTitle => 'फ़िंगरप्रिंट से अनलॉक करें?';

  @override
  String get vaultAskBioDesc =>
      'इस फ़ोन पर अपना पिन टाइप करने से बचें। आपका पिन ही आपके वॉल्ट की सुरक्षा करता है — इसे सुरक्षित रखें, क्योंकि नए फ़ोन पर या फिर से इंस्टॉल करने पर आपको इसकी आवश्यकता होगी।';

  @override
  String get vaultAskBioNotNow => 'अभी नहीं';

  @override
  String get vaultAskBioEnable => 'सक्षम करें';

  @override
  String get vaultDeleteMessagesTitle => 'सभी संदेश हटाएं?';

  @override
  String get vaultDeleteMessagesDesc =>
      'आपके पिन के बिना आपका इतिहास डिक्रिप्ट नहीं किया जा सकता, इसलिए रीसेट करने पर सब कुछ मिट जाता है — क्लाउड कॉपी और इस फोन की कॉपी। आपकी चैट खाली हो जाएगी।\n\nआपका खाता और संपर्क प्रभावित नहीं होंगे, और आप बाद में सामान्य रूप से संदेश भेज सकते हैं। इसे पूर्ववत नहीं किया जा सकता।';

  @override
  String get vaultDeleteMessagesCancel => 'रद्द करें';

  @override
  String get vaultDeleteMessagesConfirm => 'सब कुछ हटाएं';

  @override
  String get vaultCustodyConfirmTitle => 'अपने वॉल्ट पिन की पुष्टि करें';

  @override
  String get vaultCustodyChooseTitle => 'एक पिन चुनें';

  @override
  String get vaultCustodyConfirmDesc =>
      'आपका संदेश इतिहास पिन से एन्क्रिप्टेड है। एक बार पुष्टि करें ताकि आप नए फोन पर या पुनः इंस्टॉल करने पर संदेश वापस पा सकें।\n\nयदि आपका वॉल्ट केवल फिंगरप्रिंट से बना था, तो हो सकता है आपको कभी पिन न दिखाया गया हो।';

  @override
  String get vaultCustodyChooseDesc =>
      'ऐसा पिन चुनें जो आपको याद रहे। आपके सभी पुराने संदेश सुरक्षित रहेंगे — वे नए पिन से फिर से एन्क्रिप्ट होंगे, कुछ भी नहीं हटेगा।';

  @override
  String get vaultCustodyDontKnow => 'मुझे मेरा पिन नहीं पता';

  @override
  String get vaultCustodyConfirmBtn => 'पुष्टि करें';

  @override
  String get vaultCustodySaveBtn => 'पिन सहेजें';

  @override
  String get vaultCustodyMismatchError =>
      'वह पिन मेल नहीं खाता। यदि आपने कभी पिन नहीं चुना, तो \"मुझे मेरा पिन नहीं पता\" पर टैप करें।';

  @override
  String get vaultCustodyAutoUpdateFailed =>
      'पिन स्वचालित रूप से अपडेट नहीं हो सका। कृपया अपना वर्तमान पिन दर्ज करें।';

  @override
  String vaultCustodyReencrypting(int done, int total) {
    return '$total में से $done को फिर से एन्क्रिप्ट किया जा रहा है… ऐप को खुला रखें।';
  }

  @override
  String get vaultCustodyPreparing => 'तैयार हो रहा है… ऐप खुला रखें।';

  @override
  String get vaultSettingsTitle => 'वॉल्ट';

  @override
  String get vaultSettingsAboutTitle => 'वॉल्ट के बारे में';

  @override
  String get vaultSettingsAboutDesc =>
      'आपकी चैट हिस्ट्री का एक निजी बैकअप, जो आपके पिन से सुरक्षित रहता है। जब आप ऐप पुनः इंस्टॉल करते हैं या नया फोन बदलते हैं, तो यह आपके संदेश वापस लाता है। केवल आपका पिन इसे खोल सकता है — हमारे सहित कोई अन्य इसे नहीं पढ़ सकता।';

  @override
  String get vaultSettingsBulletMessages => 'आपके संदेश';

  @override
  String get vaultSettingsBulletStatuses => 'जो स्टेटस आप देख सकते हैं';

  @override
  String get vaultSettingsNeverKept =>
      'यहाँ कभी नहीं रखा जाता: आपकी कॉल हिस्ट्री, संपर्क, चैट में साझा की गई तस्वीरें, या किसी अन्य के निजी संदेश।';

  @override
  String get vaultSettingsSectionPrivacy => 'गोपनीयता';

  @override
  String get vaultSettingsAutoDelete => 'पुराने संदेश स्वतः हटाएं';

  @override
  String get vaultSettingsKeepForever => 'हमेशा रखें';

  @override
  String vaultSettingsDeleteAfter(String label) {
    return '$label के बाद हटाएं';
  }

  @override
  String get vaultSettingsSectionPin => 'पिन';

  @override
  String get vaultSettingsChangePin => 'पिन बदलें';

  @override
  String get vaultSettingsChangePinSubtitle =>
      'वॉल्ट की हर प्रविष्टि को दोबारा एन्क्रिप्ट करता है';

  @override
  String get vaultSettingsBioTitle => 'फ़िंगरप्रिंट से अनलॉक करें';

  @override
  String get vaultSettingsBioSubOn => 'इस डिवाइस के लिए चालू';

  @override
  String get vaultSettingsBioSubOff => 'इस डिवाइस पर पिन टाइप करना छोड़ें';

  @override
  String get vaultSettingsSectionDanger => 'खतरे का क्षेत्र';

  @override
  String get vaultSettingsDeleteData => 'वॉल्ट डेटा हटाएं';

  @override
  String get vaultSettingsDeleteDataSubtitle =>
      'एन्क्रिप्टेड इतिहास मिटाता है, पिन रखता है';

  @override
  String get vaultSettingsResetVault => 'वॉल्ट रीसेट करें';

  @override
  String get vaultSettingsResetVaultSubtitle =>
      'पिन भूल जाता है और सब कुछ मिटा देता है';

  @override
  String get vaultSettingsPinChanged => 'पिन बदल दिया गया।';

  @override
  String get vaultSettingsBioTurnedOff =>
      'फ़िंगरप्रिंट अनलॉक बंद कर दिया गया। आपका पिन अभी भी काम करता है।';

  @override
  String get vaultSettingsBioTurnedOn =>
      'इस डिवाइस पर फ़िंगरप्रिंट अनलॉक सक्षम किया गया।';

  @override
  String get vaultSettingsClearDataTitle => 'वॉल्ट डेटा हटाएं?';

  @override
  String get vaultSettingsClearDataDesc =>
      'क्लाउड वॉल्ट से सभी एन्क्रिप्टेड संदेश और स्टेटस हटाता है। आपका पिन वही रहता है — नए संदेश पहले की तरह एन्क्रिप्ट होंगे। पूर्ववत नहीं किया जा सकता।';

  @override
  String get vaultSettingsClearDataCancel => 'रद्द करें';

  @override
  String get vaultSettingsClearDataConfirm => 'डेटा हटाएं';

  @override
  String get vaultSettingsDataDeleted => 'वॉल्ट डेटा हटा दिया गया।';

  @override
  String get vaultSettingsResetTitle => 'वॉल्ट रीसेट करें?';

  @override
  String get vaultSettingsResetDesc =>
      'आपका पिन हटाता है, हर एन्क्रिप्टेड प्रविष्टि हटाता है, और स्थानीय कैश साफ़ करता है। आपको एक नया पिन सेट करने के लिए कहा जाएगा। पूर्ववत नहीं किया जा सकता।';

  @override
  String get vaultSettingsResetConfirm => 'रीसेट करें';

  @override
  String get vaultSettingsChangeDialogDesc =>
      'हर प्रविष्टि नए पिन के तहत दोबारा एन्क्रिप्ट होगी। इसके पूरा होने तक ऐप को खुला रखें।';

  @override
  String get vaultSettingsCurrentPin => 'वर्तमान पिन';

  @override
  String get vaultSettingsNewPin => 'नया पिन';

  @override
  String get vaultSettingsConfirmNewPin => 'नए पिन की पुष्टि करें';

  @override
  String get vaultSettingsEnterCurrentPin => 'अपना वर्तमान पिन दर्ज करें।';

  @override
  String get vaultSettingsNewPinMinLength =>
      'नया पिन कम से कम 6 वर्णों का होना चाहिए।';

  @override
  String get vaultSettingsNewPinMismatch => 'नए पिन मेल नहीं खाते।';

  @override
  String get vaultSettingsCurrentPinIncorrect => 'वर्तमान पिन गलत है।';

  @override
  String vaultSettingsReencryptingCount(int done, int total) {
    return '$total में से $done को पुनः एन्क्रिप्ट किया जा रहा है…';
  }

  @override
  String get vaultSettingsChangeBtn => 'बदलें';

  @override
  String get vaultSettingsBioPinDialogTitle => 'अपना पिन दर्ज करें';

  @override
  String get vaultSettingsBioPinDialogDesc =>
      'आपका पिन इस डिवाइस पर संग्रहीत है ताकि आपका फिंगरप्रिंट वॉल्ट को अनलॉक कर सके। नए फोन पर आपको इसकी आवश्यकता होगी, इसलिए इसे सुरक्षित रखें।';

  @override
  String get vaultSettingsContinueBtn => 'जारी रखें';

  @override
  String get premiumTitle => 'GupShupGo प्रो';

  @override
  String get premiumSubtitleMember => 'आप एक प्रो सदस्य हैं! 🎉';

  @override
  String get premiumSubtitleUnlock => 'पूर्ण अनुभव अनलॉक करें';

  @override
  String premiumActiveDaysRemaining(int days) {
    return '$days दिन शेष';
  }

  @override
  String get premiumFeaturesHeader => 'प्रो के साथ आपको क्या मिलता है';

  @override
  String get premiumPlansHeader => 'अपनी योजना चुनें';

  @override
  String get premiumSubscribeBtn => 'अभी सदस्यता लें';

  @override
  String get premiumCancelAnytime =>
      'Google Play सदस्यताओं से कभी भी रद्द करें।';

  @override
  String get premiumRestoreBtn => 'पिछली खरीदारी पुनर्स्थापित करें';

  @override
  String get premiumRestoring => 'पुनर्स्थापित हो रहा है…';

  @override
  String get premiumRestoredSuccess => 'प्रो सदस्यता पुनर्स्थापित हो गई! 🎉';

  @override
  String get premiumNoActiveSub => 'कोई सक्रिय सदस्यता नहीं मिली।';

  @override
  String get premiumProductUnavailable =>
      'उत्पाद उपलब्ध नहीं है। सुनिश्चित करें कि आपके पास इंटरनेट कनेक्शन है और ऐप प्ले स्टोर से डाउनलोड किया गया है।';

  @override
  String get premiumFeatureMediaTitle => 'मीडिया मोमेंट्स';

  @override
  String get premiumFeatureMediaDesc =>
      'फ़ोटो और वीडियो स्टेटस अपडेट के रूप में साझा करें';

  @override
  String get premiumFeatureMediaFree => 'केवल टेक्स्ट';

  @override
  String get premiumFeatureMediaPro => 'तस्वीरें + वीडियो';

  @override
  String get premiumFeatureScreenShareTitle => 'स्क्रीन शेयरिंग';

  @override
  String get premiumFeatureScreenShareDesc =>
      'चैट के दौरान अपनी स्क्रीन लाइव साझा करें';

  @override
  String get premiumFeatureScreenShareFree => 'लॉक किया गया';

  @override
  String get premiumFeatureScreenSharePro => 'पूर्ण पहुंच';

  @override
  String get premiumFeatureThemesTitle => 'चैट थीम';

  @override
  String get premiumFeatureThemesDesc =>
      'प्रति चैट पैटर्न वाले बैकग्राउंड और ग्रेडिएंट बबल';

  @override
  String get premiumFeatureThemesFree => '6 थीम';

  @override
  String get premiumFeatureThemesPro => 'सभी 12 + आपकी अपनी फोटो';

  @override
  String get premiumFeatureVoiceTitle => 'लंबे वॉयस संदेश';

  @override
  String get premiumFeatureVoiceDesc => 'लंबे वॉयस नोट्स रिकॉर्ड करें';

  @override
  String get premiumFeatureVoiceFree => '2 मिनट';

  @override
  String get premiumFeatureVoicePro => 'असीमित';

  @override
  String get premiumFeatureQualityTitle => 'उच्च गुणवत्ता वाला मीडिया';

  @override
  String get premiumFeatureQualityDesc =>
      'अधिक स्पष्ट तस्वीरें और 90s तक के स्टेटस वीडियो';

  @override
  String get premiumFeatureQualityFree => 'मानक गुणवत्ता';

  @override
  String get premiumFeatureQualityPro => 'उच्च गुणवत्ता + 90s वीडियो';

  @override
  String get premiumFeatureBondTitle => 'बॉन्ड पुनर्स्थापना';

  @override
  String get premiumFeatureBondDesc => 'टूटे हुए बॉन्ड मुफ्त में बहाल करें';

  @override
  String get premiumFeatureBondFree => 'पॉइंट्स या विज्ञापन देखें';

  @override
  String get premiumFeatureBondPro => 'प्रति सप्ताह 1 मुफ्त पुनर्स्थापना';

  @override
  String get premiumFeatureBadgeTitle => 'प्रो बैज';

  @override
  String get premiumFeatureBadgeDesc => 'अपना प्रो स्टेटस दिखाएं';

  @override
  String get premiumFeatureBadgeFree => 'कोई बैज नहीं';

  @override
  String get premiumFeatureBadgePro => 'विशेष प्रो बैज';

  @override
  String get premiumFeatureExportTitle => 'चैट निर्यात';

  @override
  String get premiumFeatureExportDesc =>
      'चैट को पीडीएफ या टेक्स्ट फाइल के रूप में सहेजें';

  @override
  String get premiumFeatureExportFree => 'उपलब्ध नहीं';

  @override
  String get premiumFeatureExportPro => 'पीडीएफ और टीएक्सटी निर्यात';

  @override
  String get premiumFeatureAdFreeTitle => 'विज्ञापन-मुक्त अनुभव';

  @override
  String get premiumFeatureAdFreeDesc =>
      'ऐप में कहीं भी कोई बैनर विज्ञापन नहीं';

  @override
  String get premiumFeatureAdFreeFree => 'बैनर विज्ञापन दिखाए जाते हैं';

  @override
  String get premiumFeatureAdFreePro =>
      'कोई बैनर नहीं (रिवॉर्ड विज्ञापन वैकल्पिक हैं)';

  @override
  String get premiumPlanMonthly => 'मासिक';

  @override
  String get premiumPlanYearly => 'वार्षिक';

  @override
  String get premiumPlanSavings => '~33% बचाएं';

  @override
  String get premiumPeriodMonth => '/माह';

  @override
  String get premiumPeriodYear => '/वर्ष';

  @override
  String get nearbyOfflineChatTitle => 'ऑफलाइन चैट';

  @override
  String get nearbySearchingDevices => 'आस-पास के डिवाइस खोजे जा रहे हैं…';

  @override
  String get nearbyTooltipStop => 'ऑफलाइन चैट बंद करें';

  @override
  String get nearbyTooltipStart => 'ऑफलाइन चैट शुरू करें';

  @override
  String get nearbyDevicesSection => 'आस-पास के उपकरण';

  @override
  String get nearbyDiscoveryOn => 'खोज चालू';

  @override
  String get nearbyDiscoveryOff => 'खोज बंद';

  @override
  String get nearbyHeroTitle => 'ऑफलाइन मोड';

  @override
  String nearbyHeroNearbyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count आस-पास',
      one: '1 आस-पास',
    );
    return '$_temp0';
  }

  @override
  String get nearbyHeroOff => 'ऑफलाइन चैट बंद है';

  @override
  String get nearbyHeroDesc =>
      '100 मीटर के भीतर उपकरणों को स्कैन किया जा रहा है। कनेक्शन एन्क्रिप्टेड और पीयर-टू-पीयर हैं।';

  @override
  String get nearbyYourNameHint => 'आपका नाम';

  @override
  String get nearbyEmptySearching => 'आस-पास के डिवाइस खोजे जा रहे हैं…';

  @override
  String get nearbyEmptyOff => 'ऑफलाइन चैट बंद है';

  @override
  String get nearbyEmptySearchingDesc =>
      'सुनिश्चित करें कि ब्लूटूथ सक्रिय के साथ आस-पास के उपकरणों पर GupShupGo खुला है।';

  @override
  String get nearbyEmptyOffDesc =>
      'स्कैनिंग शुरू करने के लिए ऊपर दाईं ओर स्टार्ट आइकन पर टैप करें।';

  @override
  String get nearbyPeerConnected => 'जुड़ा हुआ है · चैट करने के लिए टैप करें';

  @override
  String get nearbyPeerConnecting => 'कनेक्ट हो रहा है…';

  @override
  String get nearbyPeerTapToConnect => 'कनेक्ट करने के लिए टैप करें';

  @override
  String get nearbyActionChat => 'चैट';

  @override
  String get nearbyActionConnecting => 'कनेक्ट हो रहा है';

  @override
  String get nearbyActionConnect => 'कनेक्ट करें';

  @override
  String get nearbyPermNeededTitle => 'अनुमतियों की आवश्यकता है';

  @override
  String get nearbyPermNeededDesc =>
      'बिना इंटरनेट के डिवाइस खोजने के लिए ब्लूटूथ और आस-पास के डिवाइस एक्सेस की आवश्यकता होती है।';

  @override
  String get nearbyTryAgainBtn => 'पुनः प्रयास करें';

  @override
  String get nearbySettingsBtn => 'सेटिंग्स';

  @override
  String get nearbyHelpTip =>
      'दोस्त नहीं दिख रहे? सुनिश्चित करें कि दोनों उपकरणों पर ब्लूटूथ सक्षम है।';

  @override
  String get anonLobbyTitle => 'अनाम चैट';

  @override
  String get anonLobbyFinding => 'आपके लिए किसी को खोज रहे हैं…';

  @override
  String get anonLobbyHangTight =>
      'धैर्य रखें — आपको किसी अजनबी के साथ जोड़ा जाएगा।';

  @override
  String get anonLobbyCancelBtn => 'खोज रद्द करें';

  @override
  String get anonLobbyPrivacyNote =>
      'आपकी पहचान गुप्त रहती है। अजनबी के रूप में चैट करें।';

  @override
  String get anonLobbyConnecting => 'कनेक्ट हो रहा है…';

  @override
  String get anonLobbyWaitingOthers => 'दूसरों के ऑनलाइन आने की प्रतीक्षा है…';

  @override
  String anonLobbyOnlineCount(int count) {
    return '$count अभी ऑनलाइन हैं';
  }

  @override
  String get anonChatNotEncrypted => 'संदेश एंड-टू-एंड एन्क्रिप्टेड नहीं हैं';

  @override
  String get anonChatRequestSentTooltip => 'अनुरोध भेजा गया';

  @override
  String get anonChatAddFriendTooltip => 'मित्र जोड़ें';

  @override
  String get anonChatNextStrangerTooltip => 'अगला अजनबी';

  @override
  String get anonChatReportTooltip => 'रिपोर्ट करें';

  @override
  String get anonChatSayHi => 'अजनबी को नमस्ते कहें! 👋';

  @override
  String get anonChatFriendsTransition =>
      'अब आप दोस्त हैं! सुरक्षित चैट खुल रही है…';

  @override
  String get anonChatStrangerDisconnected => 'अजनबी डिस्कनेक्ट हो गया 👋';

  @override
  String get anonChatFindNextBtn => 'अगला अजनबी खोजें';

  @override
  String get anonChatFriendReqTitle => 'अजनबी जुड़ना चाहता है!';

  @override
  String get anonChatFriendReqDesc =>
      'स्वीकार करने पर आपकी असली प्रोफ़ाइल प्रकट होगी और एन्क्रिप्टेड चैट शुरू होगी।';

  @override
  String get anonChatDecline => 'अस्वीकार करें';

  @override
  String get anonChatAccept => 'स्वीकार करें';

  @override
  String get anonChatWaitingReqTitle => 'मित्र अनुरोध भेजा गया';

  @override
  String get anonChatWaitingReqDesc => 'अजनबी के जवाब की प्रतीक्षा है…';

  @override
  String get anonChatReportTitle => 'अजनबी की रिपोर्ट करें';

  @override
  String get anonChatReportQuestion =>
      'आप इस उपयोगकर्ता की रिपोर्ट क्यों कर रहे हैं?';

  @override
  String get anonChatReportReasonInappropriate => 'अनुचित सामग्री';

  @override
  String get anonChatReportReasonHarassment => 'उत्पीड़न या बदमाशी';

  @override
  String get anonChatReportReasonSpam => 'स्पैम या घोटाला';

  @override
  String get anonChatReportReasonThreatening => 'धमकी भरा व्यवहार';

  @override
  String get anonChatReportReasonOther => 'अन्य';

  @override
  String get anonChatReportCancel => 'रद्द करें';

  @override
  String get anonChatReportSubmit => 'रिपोर्ट करें और छोड़ें';

  @override
  String get anonChatReportSubmitted =>
      'रिपोर्ट सबमिट की गई। GupShupGo को सुरक्षित रखने के लिए धन्यवाद।';

  @override
  String get anonChatViewOnceVideoTitle => 'एक बार चलाएं?';

  @override
  String get anonChatViewOncePhotoTitle => 'एक बार खोलें?';

  @override
  String get anonChatViewOnceVideoDesc =>
      'आप इस वीडियो को केवल एक बार खोल सकते हैं। बंद करने के बाद यह गायब हो जाएगा।';

  @override
  String get anonChatViewOncePhotoDesc =>
      'आप इस तस्वीर को केवल एक बार खोल सकते हैं। बंद करने के बाद यह गायब हो जाएगी।';

  @override
  String get anonChatViewOnceCancel => 'रद्द करें';

  @override
  String get anonChatViewOnceOpen => 'खोलें';

  @override
  String get unsupportedVersionTitle => 'GupShupGo अपडेट करें';

  @override
  String get unsupportedVersionDesc =>
      'GupShupGo का यह संस्करण अब समर्थित नहीं है। चैटिंग जारी रखने के लिए नवीनतम संस्करण में अपडेट करें — आपके संदेश सुरक्षित हैं।';

  @override
  String get unsupportedVersionUpdateNow => 'अभी अपडेट करें';

  @override
  String get unsupportedVersionOpenPlayStore => 'Play Store खोलें';

  @override
  String publicProfileNotFound(String username) {
    return '@$username नहीं मिला';
  }

  @override
  String get publicProfileUserNotFound => 'उपयोगकर्ता नहीं मिला';

  @override
  String get publicProfileNotFoundDesc =>
      'यह हैंडल मौजूद नहीं है या लिंक टूट गया है।';

  @override
  String get publicProfileTitle => 'प्रोफ़ाइल';

  @override
  String get publicProfileOnline => 'ऑनलाइन';

  @override
  String publicProfileLastSeen(String time) {
    return 'अंतिम बार देखा गया $time';
  }

  @override
  String get publicProfileJustNow => 'अभी-अभी';

  @override
  String publicProfileMinutesAgo(int minutes) {
    return '$minutes मि॰ पहले';
  }

  @override
  String publicProfileHoursAgo(int hours) {
    return '$hours घंटे पहले';
  }

  @override
  String publicProfileDaysAgo(int days) {
    return '$days दिन पहले';
  }

  @override
  String publicProfileJoined(String date) {
    return '$date को शामिल हुए';
  }

  @override
  String get publicProfileOwnLink => 'यह आपका अपना प्रोफ़ाइल लिंक है।';

  @override
  String publicProfileGupPoints(int points) {
    return '$points गप पॉइंट्स';
  }

  @override
  String publicProfileLevel(int level) {
    return 'लेवल $level';
  }

  @override
  String get publicProfileStatPoints => 'अंक';

  @override
  String get publicProfileStatBadges => 'बैज';

  @override
  String get publicProfileStatBestBond => 'सर्वश्रेष्ठ बॉन्ड';

  @override
  String get publicProfileBadges => 'बैज';

  @override
  String get qrScannerTitle => 'क्यूआर कोड स्कैन करें';

  @override
  String get qrScannerFlashOnTooltip => 'फ़्लैश चालू करें';

  @override
  String get qrScannerFlashOffTooltip => 'फ़्लैश बंद करें';

  @override
  String get qrScannerPrompt =>
      'अपने कैमरे को GupShupGo प्रोफाइल क्यूआर कोड पर रखें';

  @override
  String get qrScannerNotProfileCode => 'यह GupShupGo प्रोफ़ाइल कोड नहीं है।';

  @override
  String get qrScannerCameraErrorTitle => 'कैमरा शुरू नहीं हो सका।';

  @override
  String get qrScannerCameraErrorRetry => 'कृपया पुनः प्रयास करें।';

  @override
  String get qrScannerPermissionMsg =>
      'क्यूआर कोड स्कैन करने के लिए कैमरा एक्सेस की आवश्यकता है।';

  @override
  String get qrScannerPermissionAllow => 'कैमरा की अनुमति दें';

  @override
  String get qrScannerBlockedMsg =>
      'कैमरा एक्सेस ब्लॉक है। क्यूआर कोड स्कैन करने के लिए इसे सेटिंग्स में सक्षम करें।';

  @override
  String get qrScannerBlockedSettings => 'सेटिंग्स खोलें';

  @override
  String get screenShareIncomingTitle => 'इनकमिंग स्क्रीन शेयर';

  @override
  String get screenShareWantsToShare => 'अपनी स्क्रीन साझा करना चाहते हैं';

  @override
  String get screenShareReject => 'अस्वीकार करें';

  @override
  String get screenShareAccept => 'स्वीकार करें';

  @override
  String get screenShareCantAccept =>
      'स्क्रीन शेयर स्वीकार नहीं किया जा सका — अपना कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String screenShareDeclined(String name) {
    return '$name ने आपका स्क्रीन शेयर अस्वीकार कर दिया';
  }

  @override
  String get screenShareNoAnswer => 'कोई उत्तर नहीं मिला';

  @override
  String get screenShareStartError => 'स्क्रीन शेयरिंग शुरू नहीं हो सकी';

  @override
  String get screenShareStatusRequesting => 'अनुमति का अनुरोध किया जा रहा है';

  @override
  String get screenShareStatusInitializing => 'प्रसारण शुरू हो रहा है';

  @override
  String get screenShareStatusWaitingParticipant =>
      'प्रतिभागी की प्रतीक्षा की जा रही है';

  @override
  String get screenShareStatusActive => 'स्क्रीन शेयरिंग सक्रिय है';

  @override
  String screenShareSubWaitingAccept(String name) {
    return '$name के स्वीकार करने की प्रतीक्षा की जा रही है…';
  }

  @override
  String get screenShareSubEstablishing =>
      'एन्क्रिप्टेड स्ट्रीम स्थापित की जा रही है...';

  @override
  String screenShareSubWaitingJoin(String name) {
    return '$name के शामिल होने की प्रतीक्षा की जा रही है...';
  }

  @override
  String get screenShareSubActive =>
      'आपकी पूरी स्क्रीन उच्च गुणवत्ता में दिखाई दे रही है।';

  @override
  String get screenShareBadgeRequesting => 'अनुरोध जारी';

  @override
  String get screenShareBadgeConnecting => 'कनेक्ट हो रहा है';

  @override
  String get screenShareSharedWith => 'इनके साथ साझा: ';

  @override
  String get screenShareRequestingFrom => 'इनसे अनुरोध: ';

  @override
  String get screenShareMinimizeTip =>
      'GupShupGo का उपयोग जारी रखने के लिए आप इस स्क्रीन को छोटा कर सकते हैं।';

  @override
  String get screenShareStop => 'शेयर करना बंद करें';

  @override
  String get screenShareCancelRequest => 'अनुरोध रद्द करें';

  @override
  String screenShareViewerTitle(String name) {
    return '$name स्क्रीन साझा कर रहे हैं';
  }

  @override
  String get screenShareViewerLive => 'लाइव स्ट्रीम';

  @override
  String get screenShareViewerMinimize => 'छोटा करें';

  @override
  String get screenShareViewerLeave => 'छोड़ें';

  @override
  String screenShareViewerWaitingStream(String name) {
    return '$name द्वारा स्क्रीन स्ट्रीम करने की प्रतीक्षा की जा रही है...';
  }

  @override
  String get screenShareViewerConnecting =>
      'एन्क्रिप्टेड स्ट्रीम से कनेक्ट हो रहा है...';

  @override
  String get viewOnceVideoTitle => 'वीडियो · एक बार देखें';

  @override
  String get viewOncePhotoTitle => 'तस्वीर · एक बार देखें';

  @override
  String get viewOnceCantOpen => 'यह मीडिया नहीं खोला जा सका।';

  @override
  String get viewOnceUnavailable => 'यह मीडिया अब उपलब्ध नहीं है।';

  @override
  String get viewOnceBlockedFooter =>
      'स्क्रीनशॉट ब्लॉक हैं। आप इसे दोबारा नहीं खोल सकते।';

  @override
  String get anonRestoreBanner => 'अनाम चैट बैनर दिखाएँ';

  @override
  String get contactsInviteFriends => 'दोस्तों को GupShupGo पर आमंत्रित करें';

  @override
  String get inviteImageShareFailed =>
      'चित्र साझा नहीं हो सका। फिर से कोशिश करें या लिंक साझा करें।';

  @override
  String get viewOnceUnblockedFooter =>
      'आप इसे दोबारा नहीं खोल सकते। iOS पर स्क्रीनशॉट ब्लॉक नहीं किए जा सकते।';

  @override
  String get tabMessages => 'संदेश';
}
