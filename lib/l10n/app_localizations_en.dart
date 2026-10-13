// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonOk => 'OK';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonClose => 'Close';

  @override
  String get commonGotIt => 'Got it';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Choose your preferred language';

  @override
  String get languagePickerTitle => 'Language';

  @override
  String get languageSystemDefault => 'System default';

  @override
  String get languageSystemDefaultSubtitle => 'Follow your device language';

  @override
  String get loginContinueWithPhone => 'Continue with Phone';

  @override
  String get loginContinueWithGoogle => 'Continue with Google';

  @override
  String get loginUseEmailPassword => 'Use Email & Password';

  @override
  String get loginSignIn => 'Sign In';

  @override
  String get loginSignUp => 'Sign Up';

  @override
  String get loginCreateAccount => 'Create Account';

  @override
  String get loginForgotPassword => 'Forgot Password?';

  @override
  String get loginOfflineChat => 'Offline Chat';

  @override
  String get loginHintName => 'Your Name';

  @override
  String get loginHintEmail => 'Email';

  @override
  String get loginHintPassword => 'Password';

  @override
  String get loginPasswordHelper =>
      'At least 8 characters, with a letter and a number';

  @override
  String loginResetEmailSent(String email) {
    return 'Password reset email sent to $email';
  }

  @override
  String get loginErrorEnterEmail => 'Please enter your email';

  @override
  String get loginErrorValidEmail => 'Please enter a valid email';

  @override
  String get loginErrorEnterPassword => 'Please enter your password';

  @override
  String get loginErrorPasswordMin6 => 'Password must be at least 6 characters';

  @override
  String get loginErrorEnterPasswordSignup => 'Please enter a password';

  @override
  String get loginErrorPasswordMin8 => 'Password must be at least 8 characters';

  @override
  String get loginErrorPasswordLetter => 'Password must include a letter';

  @override
  String get loginErrorPasswordNumber => 'Password must include a number';

  @override
  String get loginErrorEnterName => 'Please enter your name';

  @override
  String get loginErrorGoogleCancelled => 'Google sign-in was cancelled.';

  @override
  String get loginErrorProfileLoad =>
      'Couldn\'t load your profile. Check your connection and try again.';

  @override
  String get loginErrorGoogleFailed =>
      'Google sign-in failed. Please try again.';

  @override
  String get loginErrorSignInFailed => 'Failed to sign in. Please try again.';

  @override
  String get loginErrorSignUpFailed => 'Failed to sign up. Please try again.';

  @override
  String get loginErrorGeneric => 'An error occurred. Please try again.';

  @override
  String get loginErrorResetFailed =>
      'Failed to send reset email. Please try again.';

  @override
  String get loginErrorUserNotFound =>
      'No account found with this email. Please sign up.';

  @override
  String get loginErrorWrongPassword => 'Incorrect password. Please try again.';

  @override
  String get loginErrorEmailInUse =>
      'An account already exists with this email. Please sign in.';

  @override
  String get loginErrorInvalidEmail => 'Please enter a valid email address.';

  @override
  String get loginErrorWeakPassword =>
      'Password is too weak. Use at least 6 characters.';

  @override
  String get loginErrorInvalidCredential =>
      'Invalid email or password. Please check and try again.';

  @override
  String get loginErrorTooManyRequests =>
      'Too many attempts. Please try again later.';

  @override
  String get homeNavChats => 'Gup';

  @override
  String get homeNavMoments => 'Moments';

  @override
  String get homeNavCalls => 'Calls';

  @override
  String get homeNavProfile => 'Profile';

  @override
  String get homeTooltipOfflineChat => 'Offline Chat — talk to people nearby';

  @override
  String get homeTooltipSearch => 'Search';

  @override
  String get homeMenuProfile => 'Profile';

  @override
  String get homeMenuSettings => 'Settings';

  @override
  String get homeMenuRateUs => 'Rate us';

  @override
  String get homeMenuReportIssue => 'Report Issue';

  @override
  String get homeMenuWhatsNew => 'What\'s New';

  @override
  String get homeMenuLogOut => 'Log out';

  @override
  String get homeEmptyChatsTitle => 'No chats yet';

  @override
  String get homeEmptyChatsSubtitle =>
      'Start a conversation by tapping the button below';

  @override
  String get homeNewChatButton => 'New chat';

  @override
  String get homeAiAssistantTitle => 'GupAI';

  @override
  String get homeAiAssistantSubtitle => 'Draft, translate, summarise & more';

  @override
  String get homeStrangerMatchTitle => 'Connect with a Stranger';

  @override
  String get homeStrangerMatchSubtitle => 'Anonymous chat — tap to match!';

  @override
  String get homeMyMoment => 'My Moment';

  @override
  String get homeRecentMoments => 'Recent Moments';

  @override
  String get homeEmptyMomentsTitle => 'No updates yet.';

  @override
  String get homeEmptyMomentsSubtitle => 'Tap the camera to share.';

  @override
  String get homeTapToAddMoment => 'Tap to add an update';

  @override
  String get homeEmptyCallsTitle => 'No call history';

  @override
  String get homeEmptyCallsSubtitle => 'Your recent calls will appear here';

  @override
  String get chatInputHint => 'Message...';

  @override
  String get chatSearchHint => 'Search messages...';

  @override
  String get chatStatusTyping => 'typing...';

  @override
  String get chatStatusOnline => 'Online';

  @override
  String get chatStatusOffline => 'Offline';

  @override
  String chatStatusLastSeen(String time) {
    return 'Last seen $time';
  }

  @override
  String get chatEndToEndEncrypted => 'End-to-end encrypted';

  @override
  String get chatNoInternetOfflineTitle =>
      'No internet? Chat offline with nearby devices';

  @override
  String get chatEnableOfflineButton => 'Enable';

  @override
  String get chatSlideToCancel => 'Slide to cancel';

  @override
  String get chatTooltipVoiceCall => 'Voice Call';

  @override
  String get chatTooltipVideoCall => 'Video Call';

  @override
  String get chatMenuContactInfo => 'Contact info';

  @override
  String get chatMenuSearch => 'Search';

  @override
  String get chatMenuChatTheme => 'Chat theme';

  @override
  String get chatMenuExportChat => 'Export chat';

  @override
  String get chatMenuMuteNotifications => 'Mute notifications';

  @override
  String get chatMenuUnmuteNotifications => 'Unmute notifications';

  @override
  String get chatMenuBlockContact => 'Block contact';

  @override
  String get chatActionReply => 'Reply';

  @override
  String get chatActionCopy => 'Copy';

  @override
  String get chatActionForward => 'Forward';

  @override
  String get chatActionTranslate => 'Translate';

  @override
  String get chatActionSummarise => 'Summarise';

  @override
  String get chatActionAskGupAi => 'Ask GupAI';

  @override
  String get chatActionEdit => 'Edit';

  @override
  String get chatActionDelete => 'Delete';

  @override
  String get chatDeleteMessageTitle => 'Delete message?';

  @override
  String get chatDeleteMessageForEveryonePrompt =>
      'Delete it just for you, or for everyone in this chat?';

  @override
  String chatDeleteMessageForMeOnlyPrompt(String name) {
    return 'This removes it from your devices only. $name will still see it.';
  }

  @override
  String get chatDeleteForMe => 'Delete for me';

  @override
  String get chatDeleteForEveryone => 'Delete for everyone';

  @override
  String chatBlockContactTitle(String name) {
    return 'Block $name?';
  }

  @override
  String get chatBlockContactPrompt =>
      'Blocked contacts cannot send you messages or call you. You can unblock them from Settings → Privacy → Blocked contacts.';

  @override
  String get chatBlockButton => 'Block';

  @override
  String get chatForwardTo => 'Forward to';

  @override
  String get chatNoForwardChats => 'No other chats to forward to';

  @override
  String get chatCannotSendMediaBlocked => 'Cannot send media to this contact';

  @override
  String get attachmentShareTitle => 'Share';

  @override
  String get attachmentPhoto => 'Photo';

  @override
  String get attachmentPhotoSubtitle => 'Choose an image from your gallery';

  @override
  String get attachmentVideo => 'Video';

  @override
  String get attachmentVideoSubtitle => 'Choose a video from your gallery';

  @override
  String get attachmentDocument => 'Document';

  @override
  String get attachmentDocumentSubtitle =>
      'PDF, Office file, archive — sent as-is';

  @override
  String get attachmentLocation => 'Location';

  @override
  String get attachmentLocationSubtitle => 'Share your current location';

  @override
  String get attachmentViewOnce => 'View once';

  @override
  String get attachmentViewOnceSubtitle =>
      'Photo or video disappears after it\'s opened';

  @override
  String get contactsTitle => 'Contacts & Discover';

  @override
  String get contactsTabFriends => 'Friends';

  @override
  String get contactsTabRequests => 'Requests';

  @override
  String get contactsTabDiscover => 'Discover';

  @override
  String get contactsScanQrTooltip => 'Scan QR Code';

  @override
  String get contactsMyHandleTooltip => 'My Handle';

  @override
  String get contactsSetUsernamePrompt =>
      'Set a @username in your profile first — that\'s what your QR code shares.';

  @override
  String get contactsMyQrCodeTitle => 'My Profile QR Code';

  @override
  String get contactsMyQrCodeSubtitle =>
      'Friends can scan this QR code to connect with you instantly';

  @override
  String get contactsCopyProfileLink => 'Copy Profile Link';

  @override
  String contactsProfileLinkCopied(String username) {
    return 'Profile link for @$username copied!';
  }

  @override
  String get contactsScanSomeonesCode => 'Scan Someone\'s Code';

  @override
  String get contactsPermissionDenied =>
      'Permission to access contacts was denied.';

  @override
  String get contactsNoUsersFound =>
      'No GupShupGo users found in your contacts yet.';

  @override
  String contactsFailedToSync(String error) {
    return 'Failed to sync contacts: $error';
  }

  @override
  String contactsMatchedCount(int count) {
    return '$count contacts on GupShupGo';
  }

  @override
  String get contactsFromDeviceContacts => 'From your device contacts';

  @override
  String get contactsLoadFriendsError => 'Couldn\'t load your friends.';

  @override
  String get contactsNoFriendsTitle => 'No Friends Added Yet';

  @override
  String get contactsNoFriendsPrompt =>
      'Use the Discover tab to search for users by @username, phone, or email and send them a friend request!';

  @override
  String get contactsDiscoverPeopleButton => 'Discover People';

  @override
  String get contactsQuickConnectHeader => 'QUICK CONNECT';

  @override
  String get contactsNoSuggestions => 'No suggestions available at the moment.';

  @override
  String get contactsLoadRequestsError => 'Couldn\'t load your requests.';

  @override
  String contactsPendingRequestsHeader(int count) {
    return 'PENDING REQUESTS ($count)';
  }

  @override
  String get contactsNoPendingRequestsTitle => 'No Pending Requests';

  @override
  String get contactsNoPendingRequestsSubtitle =>
      'When users send you a connection request, they will show up here.';

  @override
  String get contactsWantsToConnect => 'Wants to connect';

  @override
  String get contactsAcceptButton => 'ACCEPT';

  @override
  String get contactsAcceptFailed =>
      'Couldn\'t accept the request. Please try again.';

  @override
  String contactsConnectedWith(String name) {
    return 'Connected with $name!';
  }

  @override
  String get contactsDeclineFailed =>
      'Couldn\'t decline the request. Please try again.';

  @override
  String get contactsYouMightKnowHeader => 'YOU MIGHT KNOW';

  @override
  String get contactsSeeAll => 'SEE ALL';

  @override
  String get contactsSearchHint => 'Search name, @handle, phone or email...';

  @override
  String get contactsTurnOnDiscoverability =>
      'Turn on Discoverability to appear in search and suggestions.';

  @override
  String get contactsNoMatchingUsersTitle => 'No Matching Users Found';

  @override
  String get contactsNoMatchingUsersSubtitle =>
      'Check the @username, phone number, or email and try again.';

  @override
  String get contactsDiscoverHeroTitle => 'Discover People on GupShupGo';

  @override
  String get contactsDiscoverHeroSubtitle =>
      'Expand your circle with high-fidelity connections across the globe.';

  @override
  String get contactsSyncDeviceContacts => 'Sync Device Contacts';

  @override
  String get contactsSyncingContacts => 'Syncing Contacts...';

  @override
  String get contactsSyncDeviceSubtitle =>
      'Find your friends instantly from phone contacts';

  @override
  String get contactsSuggestedUsersHeader => 'SUGGESTED USERS';

  @override
  String get contactsAddFriendButton => 'ADD FRIEND';

  @override
  String get contactsRequestedButton => 'Requested';

  @override
  String contactsRequestSent(String name) {
    return 'Friend request sent to $name!';
  }

  @override
  String get contactsRequestFailed =>
      'Friend request is already pending or failed.';

  @override
  String get contactsRequestUnavailable =>
      'That request is no longer available.';

  @override
  String get profileEditTitle => 'Edit Profile';

  @override
  String get profileSaveButton => 'Save';

  @override
  String get profileTapToChangePhoto => 'Tap to change photo';

  @override
  String get profileUpgradeToPro => 'Upgrade to Pro';

  @override
  String get profileSectionName => 'YOUR NAME';

  @override
  String get profileNameHint => 'Enter your name';

  @override
  String get profileSectionHandle => 'UNIQUE HANDLE';

  @override
  String get profileHandleNotSet => 'Not set yet';

  @override
  String get profileChangeHandle => 'Change';

  @override
  String get profileSectionAbout => 'ABOUT';

  @override
  String get profileAboutHint => 'What\'s on your mind?';

  @override
  String get profileDefaultAbout => 'Hey there! I am using GupShupGo.';

  @override
  String get profileSectionPhone => 'PHONE';

  @override
  String get profileSectionEmail => 'EMAIL';

  @override
  String get profileSectionLinkedMethods => 'LINKED SIGN-IN METHODS';

  @override
  String get profileNotLinked => 'Not linked';

  @override
  String get profileNameEmpty => 'Name cannot be empty.';

  @override
  String get profileUpdatedSuccess => 'Profile updated';

  @override
  String profileUploadPhotoFailed(String error) {
    return 'Failed to upload photo: $error';
  }

  @override
  String profileSaveFailed(String error) {
    return 'Failed to save profile: $error';
  }

  @override
  String get profilePoints => 'Points';

  @override
  String get profileBadges => 'Badges';

  @override
  String get profileBestBond => 'Best Bond';

  @override
  String get settingsAccountCard => 'Account';

  @override
  String get settingsProfileTile => 'Profile';

  @override
  String get settingsLinkedMethodsTile => 'Linked sign-in methods';

  @override
  String get settingsPhoneTile => 'Phone number';

  @override
  String get settingsEmailTile => 'Email';

  @override
  String get settingsPrivacyCard => 'Privacy';

  @override
  String get settingsDiscoverability => 'Discoverability';

  @override
  String get settingsLastSeen => 'Last seen';

  @override
  String get settingsReadReceipts => 'Read receipts';

  @override
  String get settingsAdPreferences => 'Ad preferences';

  @override
  String get settingsManage => 'Manage';

  @override
  String get settingsAppearanceCard => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsChatTheme => 'Chat theme';

  @override
  String get settingsHelpSecurityCard => 'Help & Security';

  @override
  String get settingsHelpCenter => 'Help Center';

  @override
  String get settingsReportProblem => 'Report a problem';

  @override
  String get settingsE2EEShield => 'End-to-end encryption (Vault)';

  @override
  String get settingsVerifySafetyNumber => 'Verify safety number';

  @override
  String get settingsBlockedContacts => 'Blocked contacts';

  @override
  String get settingsClearAllGupHistory => 'Clear all gup history';

  @override
  String get settingsRateUs => 'Rate us';

  @override
  String get settingsWhatsNew => 'What\'s New';

  @override
  String get settingsCheckForUpdates => 'Check for updates';

  @override
  String get settingsAppInfo => 'App info';

  @override
  String get settingsLogOut => 'Log Out';

  @override
  String get settingsLogOutConfirmTitle => 'Log out';

  @override
  String get settingsLogOutConfirmPrompt =>
      'Are you sure you want to log out of GupShupGo?';

  @override
  String get settingsSigningOut => 'Signing out…';

  @override
  String get settingsClearChatsConfirmTitle => 'Clear all chats';

  @override
  String get settingsClearChatsConfirmPrompt =>
      'This will permanently delete all your message history. This action cannot be undone.';

  @override
  String get settingsDeleteAll => 'Delete All';

  @override
  String get settingsClearingChats => 'Clearing chats...';

  @override
  String get settingsAllChatsCleared => 'All chats cleared';

  @override
  String settingsClearChatsFailed(String error) {
    return 'Failed to clear chats: $error';
  }

  @override
  String get settingsChooseThemeTitle => 'Choose theme';

  @override
  String get settingsUnlockPremiumFeatures => 'Unlock premium features';

  @override
  String settingsProDaysLeft(String planLabel, int daysRemaining) {
    return '$planLabel · $daysRemaining days left';
  }

  @override
  String get settingsCheckingForUpdates => 'Checking for updates…';

  @override
  String settingsUpToDate(String version) {
    return 'You\'re on the latest version (v$version).';
  }

  @override
  String get settingsUpdateCheckUnavailable =>
      'Couldn\'t check for updates. Make sure GupShupGo was installed from the Google Play Store.';

  @override
  String get settingsNoBlockedContacts => 'No blocked contacts';

  @override
  String get settingsUnblock => 'Unblock';

  @override
  String settingsUserUnblocked(String name) {
    return '$name unblocked';
  }

  @override
  String get settingsVerifyContactTitle => 'Verify a contact';

  @override
  String get settingsVerifyContactSubtitle =>
      'Select a contact to view your shared safety number.';

  @override
  String get settingsComputingSafetyNumber => 'Computing safety number…';

  @override
  String settingsSafetyNumberExplanation(String name) {
    return 'If the number below matches on $name\'s device, your end-to-end encryption is verified.';
  }

  @override
  String get settingsSafetyNumberNoBundle =>
      'This contact hasn\'t published an encryption key bundle yet. They may be using an older version of GupShupGo.';

  @override
  String get settingsSafetyNumberCompareHint =>
      'Compare this number in person or over a trusted call.';

  @override
  String get callEndToEndEncrypted => 'End-to-end encrypted';

  @override
  String get callSecuring => 'Securing call…';

  @override
  String get callNotEncrypted => 'Not encrypted';

  @override
  String get callIncomingVoice => 'Incoming Voice Call';

  @override
  String get callIncomingVideo => 'Incoming Video Call';

  @override
  String get callVoiceCall => 'Voice Call';

  @override
  String get callVideoCall => 'Video Call';

  @override
  String get callDecline => 'Decline';

  @override
  String get callAccept => 'Accept';

  @override
  String get callConnecting => 'Connecting...';

  @override
  String get callSettingUp => 'Setting up call...';

  @override
  String callNotifying(String name) {
    return 'Notifying $name...';
  }

  @override
  String get callRinging => 'Ringing...';

  @override
  String get callConnected => 'Connected';

  @override
  String get callOnHold => 'On hold';

  @override
  String get callCalling => 'Calling...';

  @override
  String get callWaitingForUser => 'Waiting for remote user...';

  @override
  String get callEnded => 'Call Ended';

  @override
  String get callDeclined => 'Call Declined';

  @override
  String get callNoAnswer => 'No Answer';

  @override
  String get callFailedToConnect => 'Failed to connect';

  @override
  String callFailedToStart(String error) {
    return 'Failed to start call: $error';
  }

  @override
  String get callTokenExpired =>
      'Token expired or invalid. Please restart the call.';

  @override
  String callFailedToInit(String type, String error) {
    return 'Failed to initialize $type call: $error';
  }

  @override
  String get callTurnOffSpeaker => 'Turn off speaker';

  @override
  String get callTurnOnSpeaker => 'Turn on speaker';

  @override
  String get callMuteMic => 'Mute microphone';

  @override
  String get callUnmuteMic => 'Unmute microphone';

  @override
  String get callEndCall => 'End call';

  @override
  String get callSwitchCamera => 'Switch camera';

  @override
  String get callTurnOffCamera => 'Turn off camera';

  @override
  String get callTurnOnCamera => 'Turn on camera';

  @override
  String statusViewedByCount(int count) {
    return 'Viewed by $count';
  }

  @override
  String get statusNoViewsYet => 'No views yet';

  @override
  String statusViewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count views',
      one: '1 view',
    );
    return '$_temp0';
  }

  @override
  String get statusDeleteTitle => 'Delete Status';

  @override
  String get statusDeleteConfirm =>
      'Are you sure you want to delete this status?';

  @override
  String get statusDeleteButton => 'Delete';

  @override
  String get statusReplySent => 'Reply sent';

  @override
  String statusReplyFailed(String error) {
    return 'Failed to send reply: $error';
  }

  @override
  String get statusNoActive => 'No active status';

  @override
  String get statusCouldNotLoad => 'Couldn\'t load this update';

  @override
  String get statusTapToRetry => 'Tap to retry';

  @override
  String get statusFailedToLoadImage => 'Failed to load image';

  @override
  String get statusLoadingVideo => 'Loading video...';

  @override
  String get statusEnterTextPrompt => 'Please enter some text';

  @override
  String get statusNoContactsNotice =>
      'No contacts yet — start a chat before posting a status.';

  @override
  String statusPostFailed(String error) {
    return 'Failed to post status: $error';
  }

  @override
  String get statusTypeHint => 'Type a status...';

  @override
  String get statusCamera => 'Camera';

  @override
  String get statusTakePhoto => 'Take a photo';

  @override
  String get statusGalleryPhoto => 'Gallery Photo';

  @override
  String get statusChooseImageGallery => 'Choose an image from gallery';

  @override
  String get statusRecordVideo => 'Record Video';

  @override
  String get statusRecordShortVideo => 'Record a short video';

  @override
  String get statusGalleryVideo => 'Gallery Video';

  @override
  String get statusChooseVideoGallery => 'Choose a video from gallery';

  @override
  String statusFailedPickImage(String error) {
    return 'Failed to pick image: $error';
  }

  @override
  String statusFailedPickVideo(String error) {
    return 'Failed to pick video: $error';
  }

  @override
  String get statusChangeBgColorTooltip => 'Change background color';

  @override
  String aiMessagesRemaining(int count) {
    return '$count left';
  }

  @override
  String get aiQuotaDialogTitle => 'GupAI messages';

  @override
  String aiQuotaRemainingOfTotal(int remaining, int total) {
    return '$remaining of $total left today';
  }

  @override
  String aiQuotaUsedResetNote(int used) {
    return 'Used $used today · resets tomorrow. Watch an ad or go Pro for more.';
  }

  @override
  String get aiQuotaGotIt => 'Got it';

  @override
  String get aiTitle => 'GupAI';

  @override
  String get aiSubtitle => 'Your in-app assistant';

  @override
  String get aiEmptyHelpTitle => 'How can I help?';

  @override
  String get aiEmptyHelpSubtitle =>
      'Draft replies, translate, summarise, brainstorm, or just ask a question. Tap an idea to start.';

  @override
  String get meshOfflineChatConnected => 'Offline chat · connected';

  @override
  String get meshConnecting => 'Connecting…';

  @override
  String get meshBannerNotice => 'Offline chat — no internet, no servers';

  @override
  String meshSayHiTo(String name) {
    return 'Say hi to $name';
  }

  @override
  String meshOfflineDescription(String name) {
    return 'You\'re in offline chat. Messages stay between you and $name.';
  }

  @override
  String get meshMediaUnavailable => 'This media is no longer available.';

  @override
  String get meshViewOnceTitle => 'View once';

  @override
  String meshViewOncePrompt(String type) {
    return 'You can only open this $type one time. It closes for good when you leave.';
  }

  @override
  String get arcadeTabOverview => 'Overview';

  @override
  String get arcadeTabChallenges => 'Challenges';

  @override
  String get arcadeTabLeaderboard => 'Leaderboard';

  @override
  String get arcadeFailedLoadStats => 'Failed to load reputation stats.';

  @override
  String get aiAskHint => 'Ask GupAI anything…';
}
