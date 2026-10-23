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
  String get homeNavChats => 'Messages';

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
  String get attachmentScreenShare => 'Share screen';

  @override
  String get attachmentScreenShareSubtitle =>
      'Show your screen live during the chat';

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

  @override
  String get settingsNotificationsTile => 'Notifications';

  @override
  String get settingsNotificationsStatusOn => 'On';

  @override
  String get settingsNotificationsStatusOff => 'Off';

  @override
  String get settingsNotificationsEnabledToast => 'Notifications are on.';

  @override
  String get settingsEnableNotificationsTitle => 'Enable notifications';

  @override
  String get settingsEnableNotificationsBody =>
      'Notifications are turned off. Open system settings to let GupShupGo notify you about new messages and calls.';

  @override
  String get settingsOpenSystemSettings => 'Open settings';

  @override
  String get loginTagline =>
      'Private messaging that works even without the internet.';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsTerms => 'Terms of Service';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get inviteSheetTitle => 'Invite friends';

  @override
  String get inviteSheetSubtitle => 'Spread the word — share GupShupGo';

  @override
  String get inviteShareImageBtn => 'Share image';

  @override
  String get inviteShareLinkBtn => 'Share link';

  @override
  String get inviteCopyLinkBtn => 'Copy link';

  @override
  String get inviteLinkCopied => 'Invite link copied';

  @override
  String inviteMessage(String link) {
    return 'Chat with me on GupShupGo — it even works without the internet 👋 $link';
  }

  @override
  String get inviteCardTagline => 'Private chat that works even offline';

  @override
  String get inviteCardScan => 'Scan to download';

  @override
  String get inviteCardDownload => 'Download on Google Play';

  @override
  String get homeMenuInvite => 'Invite friends';

  @override
  String get invitePromptTitle => 'Enjoying GupShupGo?';

  @override
  String get invitePromptBody =>
      'It\'s better with friends — and it works even without internet. Invite someone?';

  @override
  String get invitePromptInvite => 'Invite friends';

  @override
  String get invitePromptLater => 'Maybe later';

  @override
  String get homeOfflineBannerTitle => 'No internet? No problem';

  @override
  String get homeOfflineBannerSubtitle =>
      'You can still message people nearby over Bluetooth.';

  @override
  String homeNearbyBannerTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people nearby',
      one: '1 person nearby',
    );
    return '$_temp0';
  }

  @override
  String get homeNearbyBannerSubtitle =>
      'Chat over Bluetooth — no internet needed.';

  @override
  String get linkBackupTitle => 'Add a backup sign-in method';

  @override
  String get linkBackupSubtitle =>
      'Link Google or email so you can sign back in\neven if your SIM is unavailable.';

  @override
  String get linkGoogleTitle => 'Link Google Account';

  @override
  String get linkGoogleSubtitleLinked => 'Linked ✓';

  @override
  String get linkGoogleSubtitleUnlinked => 'One-tap sign-in without SIM';

  @override
  String get linkGoogleAction => 'Link';

  @override
  String get linkGoogleSuccess => 'Google account linked successfully!';

  @override
  String get linkGoogleAlreadyUsed =>
      'This Google account is already registered as a separate GupShupGo account. To merge, sign out and sign in with Google, then link your phone number from settings.';

  @override
  String get linkGoogleFailed => 'Google linking failed. Try again.';

  @override
  String get linkSessionExpired => 'Session expired. Please sign in again.';

  @override
  String get linkEmailTitle => 'Link Email & Password';

  @override
  String get linkEmailSubtitleLinked => 'Linked ✓';

  @override
  String get linkEmailSubtitleUnlinked =>
      'Sign in with email if no SIM or Google';

  @override
  String get linkEmailActionAdd => 'Add';

  @override
  String get linkEmailActionCancel => 'Cancel';

  @override
  String get linkEmailFieldLabel => 'Email';

  @override
  String get linkPasswordFieldLabel => 'Create a password';

  @override
  String get linkPasswordHelper => 'Minimum 6 characters';

  @override
  String get linkEmailButton => 'Link Email';

  @override
  String get linkEmailSuccess => 'Email linked successfully!';

  @override
  String get linkEmailInvalid => 'Enter a valid email address.';

  @override
  String get linkPasswordTooShort => 'Password must be at least 6 characters.';

  @override
  String get linkEmailAlreadyInUse =>
      'This email is already registered separately on GupShupGo. Sign in with email first, then link your phone from settings.';

  @override
  String get linkEmailAlreadyLinked =>
      'An email is already linked to your account.';

  @override
  String get linkEmailFailed => 'Email linking failed. Try again.';

  @override
  String get linkContinueToApp => 'Continue to App';

  @override
  String get linkSkipForNow => 'Skip for Now';

  @override
  String get linkSkip => 'Skip';

  @override
  String get phoneAuthTitleEntry => 'Sign in with your phone number.';

  @override
  String get phoneAuthTitleOtp => 'Enter the code we sent you.';

  @override
  String get phoneAuthNameHint => 'Your Name';

  @override
  String get phoneAuthPhoneHint => 'Phone Number';

  @override
  String get phoneAuthUseSim => 'Use SIM';

  @override
  String get phoneAuthSendOtp => 'Send OTP';

  @override
  String phoneAuthOtpPrompt(String phone) {
    return 'Enter the 6-digit code sent to $phone';
  }

  @override
  String get phoneAuthOtpPromptGeneric => 'Enter the 6-digit code we sent you';

  @override
  String get phoneAuthOtpHint => 'Enter code';

  @override
  String get phoneAuthVerify => 'Verify';

  @override
  String get phoneAuthGoBack => 'Go Back';

  @override
  String get phoneAuthResendCode => 'Resend code';

  @override
  String get phoneAuthEnterName => 'Please enter your name';

  @override
  String get phoneAuthEnterValidPhone => 'Please enter a valid phone number';

  @override
  String get phoneAuthEnterCode => 'Please enter the code';

  @override
  String get phoneAuthRequestNewCode => 'Please request a new code.';

  @override
  String get phoneAuthCodeIncorrect =>
      'That code is incorrect. Please try again.';

  @override
  String get phoneAuthErrCodeIncorrect =>
      'That code is incorrect. Please check and try again.';

  @override
  String get phoneAuthErrCodeExpired =>
      'The code expired. Tap \"Resend code\" to get a new one.';

  @override
  String get phoneAuthErrTooManyRequests =>
      'Too many attempts. Please wait a while and try again.';

  @override
  String get phoneAuthErrInvalidPhone =>
      'That phone number looks invalid. Please check it.';

  @override
  String get phoneAuthErrQuotaExceeded =>
      'SMS limit reached. Please try again later.';

  @override
  String get phoneAuthErrFailed => 'Verification failed. Please try again.';

  @override
  String get usernameSetupAppBarTitle => 'Choose Your Handle';

  @override
  String get usernameSetupHeaderTitle => 'Secure Your Identity';

  @override
  String get usernameSetupHeaderDesc =>
      'Your @handle is your unique key on GupShupGo. Others can search and add you securely without sharing your phone or email.';

  @override
  String get usernameSetupInputHint => 'your_handle';

  @override
  String get usernameSetupChecking => 'Checking availability...';

  @override
  String usernameSetupAvailable(String handle) {
    return '@$handle is available!';
  }

  @override
  String usernameSetupTaken(String handle) {
    return '@$handle is already taken by another user.';
  }

  @override
  String get usernameSetupCharRules => '3–20 characters (a-z, 0-9, _)';

  @override
  String get usernameSetupTooShort =>
      'Username must be at least 3 characters long.';

  @override
  String get usernameSetupTooLong =>
      'Username must be at most 20 characters long.';

  @override
  String get usernameSetupInvalidChars =>
      'Only letters, numbers, and underscores allowed.';

  @override
  String get usernameSetupRecommended => 'RECOMMENDED FOR YOU';

  @override
  String get usernameSetupSaveBtn => 'Save & Continue';

  @override
  String get usernameSetupSkipBtn => 'Skip for now';

  @override
  String usernameSetupFailed(String error) {
    return 'Failed to set username: $error';
  }

  @override
  String get vaultProtectTitle => 'Protect Vault';

  @override
  String get vaultUnlockTitle => 'Unlock Vault';

  @override
  String get vaultSetupDesc =>
      'Choose a PIN to encrypt your message history. You will need it to read your messages on a new phone, so pick something you can remember.';

  @override
  String get vaultUnlockDescBio =>
      'Enter your PIN or tap fingerprint to decrypt history.';

  @override
  String get vaultUnlockDescPin => 'Enter your PIN to decrypt your history.';

  @override
  String get vaultReinstallHint =>
      'Enter your PIN to restore your history on this device. You can turn fingerprint unlock back on afterwards.';

  @override
  String get vaultUnlockWithFingerprint => 'Unlock with Fingerprint';

  @override
  String get vaultOrDivider => 'OR';

  @override
  String get vaultNewPin => 'New PIN';

  @override
  String get vaultConfirmPin => 'Confirm PIN';

  @override
  String get vaultEnterPin => 'Enter PIN';

  @override
  String get vaultKeyboardUseLetters => 'Use letters instead';

  @override
  String get vaultKeyboardUseNumbers => 'Use numbers instead';

  @override
  String get vaultRestoreLater => 'Restore later';

  @override
  String get vaultForgotPin => 'Forgot PIN?';

  @override
  String get vaultSetPinBtn => 'Set PIN';

  @override
  String get vaultDecryptBtn => 'Decrypt';

  @override
  String get vaultPinMinLength => 'PIN must be at least 6 characters.';

  @override
  String get vaultPinsDoNotMatch => 'PINs do not match.';

  @override
  String get vaultSetupFailed => 'Setup failed. Check connection.';

  @override
  String get vaultIncorrectPin => 'Incorrect PIN. Try again.';

  @override
  String get vaultFingerprintOutOfDate =>
      'Fingerprint unlock is out of date. Enter your PIN.';

  @override
  String get vaultBiometricError => 'Biometric error. Enter PIN manually.';

  @override
  String get vaultBioReasonUnlock =>
      'Authenticate using biometrics to unlock your vault';

  @override
  String get vaultBioReasonEnrol =>
      'Confirm your fingerprint to enable quick unlock';

  @override
  String get vaultAskBioTitle => 'Unlock with fingerprint?';

  @override
  String get vaultAskBioDesc =>
      'Skip typing your PIN on this phone. Your PIN is still what protects the vault — keep it somewhere safe, because you will need it on a new phone or after reinstalling.';

  @override
  String get vaultAskBioNotNow => 'Not now';

  @override
  String get vaultAskBioEnable => 'Enable';

  @override
  String get vaultDeleteMessagesTitle => 'Delete all messages?';

  @override
  String get vaultDeleteMessagesDesc =>
      'Without your PIN your history cannot be decrypted, so resetting deletes all of it — the encrypted cloud copy and the copy on this phone. Your chats will be empty.\n\nYour account and contacts are not affected, and you can keep messaging normally afterwards. This cannot be undone.';

  @override
  String get vaultDeleteMessagesCancel => 'Cancel';

  @override
  String get vaultDeleteMessagesConfirm => 'Delete everything';

  @override
  String get vaultCustodyConfirmTitle => 'Confirm your vault PIN';

  @override
  String get vaultCustodyChooseTitle => 'Choose a PIN';

  @override
  String get vaultCustodyConfirmDesc =>
      'Your message history is encrypted with a PIN. Confirm it once so you can restore your messages on a new phone or after reinstalling.\n\nIf your vault was set up with just your fingerprint, you may never have been shown a PIN.';

  @override
  String get vaultCustodyChooseDesc =>
      'Pick a PIN you will remember. Every message you already have is kept — it is re-encrypted under the new PIN, nothing is deleted.';

  @override
  String get vaultCustodyDontKnow => 'I don\'t know my PIN';

  @override
  String get vaultCustodyConfirmBtn => 'Confirm';

  @override
  String get vaultCustodySaveBtn => 'Save PIN';

  @override
  String get vaultCustodyMismatchError =>
      'That PIN does not match. If you never chose one, tap \"I don\'t know my PIN\".';

  @override
  String get vaultCustodyAutoUpdateFailed =>
      'Could not update the PIN automatically. Please enter your current PIN.';

  @override
  String vaultCustodyReencrypting(int done, int total) {
    return 'Re-encrypting $done of $total… keep the app open.';
  }

  @override
  String get vaultCustodyPreparing => 'Preparing… keep the app open.';

  @override
  String get vaultSettingsTitle => 'Vault';

  @override
  String get vaultSettingsAboutTitle => 'About the vault';

  @override
  String get vaultSettingsAboutDesc =>
      'A private backup of your chat history, locked with your PIN. It brings your messages back when you reinstall the app or switch to a new phone. Only your PIN can open it — nobody else can read what is inside, not even us.';

  @override
  String get vaultSettingsBulletMessages => 'Your messages';

  @override
  String get vaultSettingsBulletStatuses => 'Statuses you can see';

  @override
  String get vaultSettingsNeverKept =>
      'Never kept here: your call history, contacts, photos shared in chats, or anyone else\'s private messages.';

  @override
  String get vaultSettingsSectionPrivacy => 'PRIVACY';

  @override
  String get vaultSettingsAutoDelete => 'Auto-delete old messages';

  @override
  String get vaultSettingsKeepForever => 'Keep forever';

  @override
  String vaultSettingsDeleteAfter(String label) {
    return 'Delete after $label';
  }

  @override
  String get vaultSettingsSectionPin => 'PIN';

  @override
  String get vaultSettingsChangePin => 'Change PIN';

  @override
  String get vaultSettingsChangePinSubtitle => 'Re-encrypts every vault entry';

  @override
  String get vaultSettingsBioTitle => 'Unlock with fingerprint';

  @override
  String get vaultSettingsBioSubOn => 'On for this device';

  @override
  String get vaultSettingsBioSubOff => 'Skip typing your PIN on this device';

  @override
  String get vaultSettingsSectionDanger => 'DANGER ZONE';

  @override
  String get vaultSettingsDeleteData => 'Delete vault data';

  @override
  String get vaultSettingsDeleteDataSubtitle =>
      'Wipes encrypted history, keeps PIN';

  @override
  String get vaultSettingsResetVault => 'Reset vault';

  @override
  String get vaultSettingsResetVaultSubtitle =>
      'Forgets PIN and deletes everything';

  @override
  String get vaultSettingsPinChanged => 'PIN changed.';

  @override
  String get vaultSettingsBioTurnedOff =>
      'Fingerprint unlock turned off. Your PIN still works.';

  @override
  String get vaultSettingsBioTurnedOn =>
      'Fingerprint unlock enabled on this device.';

  @override
  String get vaultSettingsClearDataTitle => 'Delete vault data?';

  @override
  String get vaultSettingsClearDataDesc =>
      'Removes every encrypted message and status from the cloud vault. Your PIN stays the same — new messages will encrypt under it as before. Cannot be undone.';

  @override
  String get vaultSettingsClearDataCancel => 'Cancel';

  @override
  String get vaultSettingsClearDataConfirm => 'Delete data';

  @override
  String get vaultSettingsDataDeleted => 'Vault data deleted.';

  @override
  String get vaultSettingsResetTitle => 'Reset vault?';

  @override
  String get vaultSettingsResetDesc =>
      'Removes your PIN, deletes every encrypted entry, and clears the local cache. You will be asked to set a fresh PIN. Cannot be undone.';

  @override
  String get vaultSettingsResetConfirm => 'Reset';

  @override
  String get vaultSettingsChangeDialogDesc =>
      'Every encrypted entry will be re-encrypted under the new PIN. Keep the app open until this finishes.';

  @override
  String get vaultSettingsCurrentPin => 'Current PIN';

  @override
  String get vaultSettingsNewPin => 'New PIN';

  @override
  String get vaultSettingsConfirmNewPin => 'Confirm new PIN';

  @override
  String get vaultSettingsEnterCurrentPin => 'Enter your current PIN.';

  @override
  String get vaultSettingsNewPinMinLength =>
      'New PIN must be at least 6 characters.';

  @override
  String get vaultSettingsNewPinMismatch => 'New PINs do not match.';

  @override
  String get vaultSettingsCurrentPinIncorrect => 'Current PIN is incorrect.';

  @override
  String vaultSettingsReencryptingCount(int done, int total) {
    return 'Re-encrypting $done of $total…';
  }

  @override
  String get vaultSettingsChangeBtn => 'Change';

  @override
  String get vaultSettingsBioPinDialogTitle => 'Enter your PIN';

  @override
  String get vaultSettingsBioPinDialogDesc =>
      'Your PIN is stored on this device so your fingerprint can unlock the vault. You will still need the PIN itself on a new phone or after reinstalling, so keep it somewhere safe.';

  @override
  String get vaultSettingsContinueBtn => 'Continue';

  @override
  String get premiumTitle => 'GupShupGo Pro';

  @override
  String get premiumSubtitleMember => 'You\'re a Pro member! 🎉';

  @override
  String get premiumSubtitleUnlock => 'Unlock the full experience';

  @override
  String premiumActiveDaysRemaining(int days) {
    return '$days days remaining';
  }

  @override
  String get premiumFeaturesHeader => 'What you get with Pro';

  @override
  String get premiumPlansHeader => 'Choose your plan';

  @override
  String get premiumSubscribeBtn => 'Subscribe Now';

  @override
  String get premiumCancelAnytime =>
      'Cancel anytime from Google Play subscriptions.';

  @override
  String get premiumRestoreBtn => 'Restore previous purchase';

  @override
  String get premiumRestoring => 'Restoring…';

  @override
  String get premiumRestoredSuccess => 'Pro subscription restored! 🎉';

  @override
  String get premiumNoActiveSub => 'No active subscription found.';

  @override
  String get premiumProductUnavailable =>
      'Product not available. Make sure you have an active internet connection and the app is downloaded from the Play Store.';

  @override
  String get premiumFeatureMediaTitle => 'Media Moments';

  @override
  String get premiumFeatureMediaDesc =>
      'Share photos & videos as status updates';

  @override
  String get premiumFeatureMediaFree => 'Text only';

  @override
  String get premiumFeatureMediaPro => 'Photos + Videos';

  @override
  String get premiumFeatureScreenShareTitle => 'Screen Sharing';

  @override
  String get premiumFeatureScreenShareDesc =>
      'Share your screen live during chats';

  @override
  String get premiumFeatureScreenShareFree => 'Locked';

  @override
  String get premiumFeatureScreenSharePro => 'Full access';

  @override
  String get premiumFeatureThemesTitle => 'Chat Themes';

  @override
  String get premiumFeatureThemesDesc =>
      'Patterned backgrounds & gradient bubbles, per chat';

  @override
  String get premiumFeatureThemesFree => '6 themes';

  @override
  String get premiumFeatureThemesPro => 'All 12 + your own photo';

  @override
  String get premiumFeatureVoiceTitle => 'Longer Voice Messages';

  @override
  String get premiumFeatureVoiceDesc => 'Record longer voice notes';

  @override
  String get premiumFeatureVoiceFree => '2 minutes';

  @override
  String get premiumFeatureVoicePro => 'Unlimited';

  @override
  String get premiumFeatureQualityTitle => 'Higher Quality Media';

  @override
  String get premiumFeatureQualityDesc =>
      'Sharper photos and longer status videos';

  @override
  String get premiumFeatureQualityFree => 'Standard quality';

  @override
  String get premiumFeatureQualityPro => 'High quality + 90s videos';

  @override
  String get premiumFeatureBondTitle => 'Bond Restore';

  @override
  String get premiumFeatureBondDesc => 'Restore broken bonds for free';

  @override
  String get premiumFeatureBondFree => 'Points or watch an ad';

  @override
  String get premiumFeatureBondPro => '1 free restore/week';

  @override
  String get premiumFeatureBadgeTitle => 'Pro Badge';

  @override
  String get premiumFeatureBadgeDesc => 'Show off your Pro status';

  @override
  String get premiumFeatureBadgeFree => 'No badge';

  @override
  String get premiumFeatureBadgePro => 'Exclusive Pro badge';

  @override
  String get premiumFeatureExportTitle => 'Chat Export';

  @override
  String get premiumFeatureExportDesc =>
      'Save a chat as a PDF you can print, or as plain text';

  @override
  String get premiumFeatureExportFree => 'Not available';

  @override
  String get premiumFeatureExportPro => 'PDF & TXT export';

  @override
  String get premiumFeatureAdFreeTitle => 'Ad-Free Experience';

  @override
  String get premiumFeatureAdFreeDesc => 'No banner ads anywhere in the app';

  @override
  String get premiumFeatureAdFreeFree => 'Banner ads shown';

  @override
  String get premiumFeatureAdFreePro => 'No banners (reward ads stay optional)';

  @override
  String get premiumPlanMonthly => 'Monthly';

  @override
  String get premiumPlanYearly => 'Yearly';

  @override
  String get premiumPlanSavings => 'Save ~33%';

  @override
  String get premiumPeriodMonth => '/month';

  @override
  String get premiumPeriodYear => '/year';

  @override
  String get nearbyOfflineChatTitle => 'Offline Chat';

  @override
  String get nearbySearchingDevices => 'Searching nearby devices…';

  @override
  String get nearbyTooltipStop => 'Stop offline chat';

  @override
  String get nearbyTooltipStart => 'Start offline chat';

  @override
  String get nearbyDevicesSection => 'Devices Nearby';

  @override
  String get nearbyDiscoveryOn => 'DISCOVERY ON';

  @override
  String get nearbyDiscoveryOff => 'DISCOVERY OFF';

  @override
  String get nearbyHeroTitle => 'Offline Mode';

  @override
  String nearbyHeroNearbyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nearby',
      one: '1 nearby',
    );
    return '$_temp0';
  }

  @override
  String get nearbyHeroOff => 'Offline Chat Off';

  @override
  String get nearbyHeroDesc =>
      'Scanning for devices within 100 meters. Connections are encrypted and peer-to-peer.';

  @override
  String get nearbyYourNameHint => 'Your name';

  @override
  String get nearbyEmptySearching => 'Searching for devices nearby…';

  @override
  String get nearbyEmptyOff => 'Offline Chat is Off';

  @override
  String get nearbyEmptySearchingDesc =>
      'Ensure GupShupGo is open on nearby devices with Bluetooth active.';

  @override
  String get nearbyEmptyOffDesc =>
      'Tap the start icon top right to begin scanning.';

  @override
  String get nearbyPeerConnected => 'Connected · Tap to chat';

  @override
  String get nearbyPeerConnecting => 'Connecting…';

  @override
  String get nearbyPeerTapToConnect => 'Tap to connect';

  @override
  String get nearbyActionChat => 'Chat';

  @override
  String get nearbyActionConnecting => 'Connecting';

  @override
  String get nearbyActionConnect => 'Connect';

  @override
  String get nearbyPermNeededTitle => 'Permissions Needed';

  @override
  String get nearbyPermNeededDesc =>
      'Offline chat requires nearby-device and Bluetooth access to discover devices without internet.';

  @override
  String get nearbyTryAgainBtn => 'Try Again';

  @override
  String get nearbySettingsBtn => 'Settings';

  @override
  String get nearbyHelpTip =>
      'Don\'t see your friend? Ensure Bluetooth is enabled on both devices.';

  @override
  String get anonLobbyTitle => 'Anonymous Chat';

  @override
  String get anonLobbyFinding => 'Finding someone for you…';

  @override
  String get anonLobbyHangTight =>
      'Hang tight — you\'ll be paired with a random stranger.';

  @override
  String get anonLobbyCancelBtn => 'Cancel Search';

  @override
  String get anonLobbyPrivacyNote =>
      'Your identity stays hidden. Chat as a stranger.';

  @override
  String get anonLobbyConnecting => 'Connecting…';

  @override
  String get anonLobbyWaitingOthers => 'Waiting for others to come online…';

  @override
  String anonLobbyOnlineCount(int count) {
    return '$count online now';
  }

  @override
  String get anonChatNotEncrypted => 'Messages are not end-to-end encrypted';

  @override
  String get anonChatRequestSentTooltip => 'Request sent';

  @override
  String get anonChatAddFriendTooltip => 'Add friend';

  @override
  String get anonChatNextStrangerTooltip => 'Next stranger';

  @override
  String get anonChatReportTooltip => 'Report';

  @override
  String get anonChatSayHi => 'Say hi to the stranger! 👋';

  @override
  String get anonChatFriendsTransition =>
      'You are now friends! Opening secure chat…';

  @override
  String get anonChatStrangerDisconnected => 'Stranger has disconnected 👋';

  @override
  String get anonChatFindNextBtn => 'Find Next Stranger';

  @override
  String get anonChatFriendReqTitle => 'Stranger wants to connect!';

  @override
  String get anonChatFriendReqDesc =>
      'Accepting reveals your real profile and starts an encrypted chat.';

  @override
  String get anonChatDecline => 'Decline';

  @override
  String get anonChatAccept => 'Accept';

  @override
  String get anonChatWaitingReqTitle => 'Friend request sent';

  @override
  String get anonChatWaitingReqDesc => 'Waiting for stranger to respond…';

  @override
  String get anonChatReportTitle => 'Report Stranger';

  @override
  String get anonChatReportQuestion => 'Why are you reporting this user?';

  @override
  String get anonChatReportReasonInappropriate => 'Inappropriate content';

  @override
  String get anonChatReportReasonHarassment => 'Harassment or bullying';

  @override
  String get anonChatReportReasonSpam => 'Spam or scam';

  @override
  String get anonChatReportReasonThreatening => 'Threatening behaviour';

  @override
  String get anonChatReportReasonOther => 'Other';

  @override
  String get anonChatReportCancel => 'Cancel';

  @override
  String get anonChatReportSubmit => 'Report & Leave';

  @override
  String get anonChatReportSubmitted =>
      'Report submitted. Thank you for keeping GupShupGo safe.';

  @override
  String get anonChatViewOnceVideoTitle => 'Play once?';

  @override
  String get anonChatViewOncePhotoTitle => 'Open once?';

  @override
  String get anonChatViewOnceVideoDesc =>
      'You can only open this video one time. Once you close it, it\'s gone.';

  @override
  String get anonChatViewOncePhotoDesc =>
      'You can only open this photo one time. Once you close it, it\'s gone.';

  @override
  String get anonChatViewOnceCancel => 'Cancel';

  @override
  String get anonChatViewOnceOpen => 'Open';

  @override
  String get unsupportedVersionTitle => 'Update GupShupGo';

  @override
  String get unsupportedVersionDesc =>
      'This version of GupShupGo is no longer supported. Update to the latest version to keep chatting — your messages and chats are safe and will be there when you come back.';

  @override
  String get unsupportedVersionUpdateNow => 'Update now';

  @override
  String get unsupportedVersionOpenPlayStore => 'Open Play Store';

  @override
  String publicProfileNotFound(String username) {
    return '@$username not found';
  }

  @override
  String get publicProfileUserNotFound => 'User not found';

  @override
  String get publicProfileNotFoundDesc =>
      'This handle doesn\'t exist or the link is broken.';

  @override
  String get publicProfileTitle => 'Profile';

  @override
  String get publicProfileOnline => 'Online';

  @override
  String publicProfileLastSeen(String time) {
    return 'Last seen $time';
  }

  @override
  String get publicProfileJustNow => 'just now';

  @override
  String publicProfileMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String publicProfileHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String publicProfileDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String publicProfileJoined(String date) {
    return 'Joined $date';
  }

  @override
  String get publicProfileOwnLink => 'This is your own profile link.';

  @override
  String publicProfileGupPoints(int points) {
    return '$points Gup Points';
  }

  @override
  String publicProfileLevel(int level) {
    return 'Level $level';
  }

  @override
  String get publicProfileStatPoints => 'Points';

  @override
  String get publicProfileStatBadges => 'Badges';

  @override
  String get publicProfileStatBestBond => 'Best Bond';

  @override
  String get publicProfileBadges => 'BADGES';

  @override
  String get qrScannerTitle => 'Scan QR Code';

  @override
  String get qrScannerFlashOnTooltip => 'Turn on flash';

  @override
  String get qrScannerFlashOffTooltip => 'Turn off flash';

  @override
  String get qrScannerPrompt =>
      'Point your camera at a GupShupGo profile QR code';

  @override
  String get qrScannerNotProfileCode => 'That\'s not a GupShupGo profile code.';

  @override
  String get qrScannerCameraErrorTitle => 'Couldn\'t start the camera.';

  @override
  String get qrScannerCameraErrorRetry => 'Please try again.';

  @override
  String get qrScannerPermissionMsg =>
      'Camera access is needed to scan QR codes.';

  @override
  String get qrScannerPermissionAllow => 'Allow camera';

  @override
  String get qrScannerBlockedMsg =>
      'Camera access is blocked. Enable it in Settings to scan QR codes.';

  @override
  String get qrScannerBlockedSettings => 'Open settings';

  @override
  String get screenShareIncomingTitle => 'Incoming Screen Share';

  @override
  String get screenShareWantsToShare => 'wants to share their screen';

  @override
  String get screenShareReject => 'Reject';

  @override
  String get screenShareAccept => 'Accept';

  @override
  String get screenShareCantAccept =>
      'Couldn\'t accept the screen share — check your connection and try again.';

  @override
  String screenShareDeclined(String name) {
    return '$name declined your screen share';
  }

  @override
  String get screenShareNoAnswer => 'No answer';

  @override
  String get screenShareStartError => 'Couldn\'t start screen sharing';

  @override
  String get screenShareStatusRequesting => 'Requesting Permission';

  @override
  String get screenShareStatusInitializing => 'Initializing Broadcast';

  @override
  String get screenShareStatusWaitingParticipant => 'Waiting for Participant';

  @override
  String get screenShareStatusActive => 'Screen Sharing Active';

  @override
  String screenShareSubWaitingAccept(String name) {
    return 'Waiting for $name to accept…';
  }

  @override
  String get screenShareSubEstablishing => 'Establishing encrypted stream...';

  @override
  String screenShareSubWaitingJoin(String name) {
    return 'Waiting for $name to join...';
  }

  @override
  String get screenShareSubActive =>
      'Your entire screen is visible in high definition.';

  @override
  String get screenShareBadgeRequesting => 'REQUESTING';

  @override
  String get screenShareBadgeConnecting => 'CONNECTING';

  @override
  String get screenShareSharedWith => 'Shared with ';

  @override
  String get screenShareRequestingFrom => 'Requesting ';

  @override
  String get screenShareMinimizeTip =>
      'You can minimize this screen to keep using GupShupGo.';

  @override
  String get screenShareStop => 'Stop sharing';

  @override
  String get screenShareCancelRequest => 'Cancel request';

  @override
  String screenShareViewerTitle(String name) {
    return '$name is sharing';
  }

  @override
  String get screenShareViewerLive => 'LIVE STREAM';

  @override
  String get screenShareViewerMinimize => 'Minimize';

  @override
  String get screenShareViewerLeave => 'Leave';

  @override
  String screenShareViewerWaitingStream(String name) {
    return 'Waiting for $name to stream screen...';
  }

  @override
  String get screenShareViewerConnecting => 'Connecting to encrypted stream...';

  @override
  String get viewOnceVideoTitle => 'Video · View once';

  @override
  String get viewOncePhotoTitle => 'Photo · View once';

  @override
  String get viewOnceCantOpen => 'Couldn\'t open this media.';

  @override
  String get viewOnceUnavailable => 'This media is no longer available.';

  @override
  String get viewOnceBlockedFooter =>
      'Screenshots are blocked. You can\'t open this again.';

  @override
  String get anonRestoreBanner => 'Show Anonymous Chat banner';

  @override
  String get contactsInviteFriends => 'Invite Friends to GupShupGo';

  @override
  String get inviteImageShareFailed =>
      'Couldn\'t share the image. Try again or share the link instead.';

  @override
  String get viewOnceUnblockedFooter =>
      'You can\'t open this again. Screenshots can\'t be blocked on iOS.';

  @override
  String get tabMessages => 'Messages';
}
