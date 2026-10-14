import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bn'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('id'),
    Locale('ja'),
    Locale('pt'),
    Locale('ru'),
    Locale('ta'),
    Locale('te'),
    Locale('tr'),
    Locale('ur'),
    Locale('zh')
  ];

  /// Generic Cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Generic OK/confirm button.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// Generic Continue button.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// Generic Save button.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Generic Retry button after a failure.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// Generic Close button.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Dismiss button acknowledging a notice.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get commonGotIt;

  /// Title of Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings row that opens the app language picker.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// Subtitle under the Language settings row.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get settingsLanguageSubtitle;

  /// Title of the language picker screen.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languagePickerTitle;

  /// Option that follows the device's language instead of a fixed app language.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystemDefault;

  /// Subtitle for the System default language option.
  ///
  /// In en, this message translates to:
  /// **'Follow your device language'**
  String get languageSystemDefaultSubtitle;

  /// Primary login button: start phone-number auth.
  ///
  /// In en, this message translates to:
  /// **'Continue with Phone'**
  String get loginContinueWithPhone;

  /// Login button: sign in with a Google account.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginContinueWithGoogle;

  /// Login button: reveal the email/password form.
  ///
  /// In en, this message translates to:
  /// **'Use Email & Password'**
  String get loginUseEmailPassword;

  /// Sign In mode chip and submit button.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginSignIn;

  /// Sign Up mode chip.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get loginSignUp;

  /// Submit button in sign-up mode.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get loginCreateAccount;

  /// Link that triggers a password-reset email.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get loginForgotPassword;

  /// Bottom link to the offline/nearby mesh chat.
  ///
  /// In en, this message translates to:
  /// **'Offline Chat'**
  String get loginOfflineChat;

  /// Name field placeholder on sign-up.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get loginHintName;

  /// Email field placeholder.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginHintEmail;

  /// Password field placeholder.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginHintPassword;

  /// Helper text under the password field on sign-up.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters, with a letter and a number'**
  String get loginPasswordHelper;

  /// Confirmation snackbar after a password-reset email is sent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent to {email}'**
  String loginResetEmailSent(String email);

  /// Validation: email field empty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get loginErrorEnterEmail;

  /// Validation: email format invalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get loginErrorValidEmail;

  /// Validation: password field empty (sign-in).
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get loginErrorEnterPassword;

  /// Validation: sign-in password too short.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get loginErrorPasswordMin6;

  /// Validation: password field empty (sign-up).
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get loginErrorEnterPasswordSignup;

  /// Validation: sign-up password too short.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get loginErrorPasswordMin8;

  /// Validation: sign-up password needs a letter.
  ///
  /// In en, this message translates to:
  /// **'Password must include a letter'**
  String get loginErrorPasswordLetter;

  /// Validation: sign-up password needs a number.
  ///
  /// In en, this message translates to:
  /// **'Password must include a number'**
  String get loginErrorPasswordNumber;

  /// Validation: name field empty on sign-up.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get loginErrorEnterName;

  /// Google sign-in dismissed by the user.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was cancelled.'**
  String get loginErrorGoogleCancelled;

  /// Profile read failed during sign-in.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your profile. Check your connection and try again.'**
  String get loginErrorProfileLoad;

  /// Generic Google sign-in failure.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get loginErrorGoogleFailed;

  /// Email sign-in returned no user.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign in. Please try again.'**
  String get loginErrorSignInFailed;

  /// Email sign-up returned no user.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign up. Please try again.'**
  String get loginErrorSignUpFailed;

  /// Fallback error for an unexpected failure.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get loginErrorGeneric;

  /// Password-reset email could not be sent.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email. Please try again.'**
  String get loginErrorResetFailed;

  /// Firebase auth: user-not-found.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email. Please sign up.'**
  String get loginErrorUserNotFound;

  /// Firebase auth: wrong-password.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Please try again.'**
  String get loginErrorWrongPassword;

  /// Firebase auth: email-already-in-use.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email. Please sign in.'**
  String get loginErrorEmailInUse;

  /// Firebase auth: invalid-email.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get loginErrorInvalidEmail;

  /// Firebase auth: weak-password.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Use at least 6 characters.'**
  String get loginErrorWeakPassword;

  /// Firebase auth: invalid-credential.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password. Please check and try again.'**
  String get loginErrorInvalidCredential;

  /// Firebase auth: too-many-requests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get loginErrorTooManyRequests;

  /// Bottom nav: Chats tab.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get homeNavChats;

  /// Bottom nav: Moments tab.
  ///
  /// In en, this message translates to:
  /// **'Moments'**
  String get homeNavMoments;

  /// Bottom nav: Calls tab.
  ///
  /// In en, this message translates to:
  /// **'Calls'**
  String get homeNavCalls;

  /// Bottom nav: Profile tab.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get homeNavProfile;

  /// Tooltip for offline mesh chat icon in home app bar.
  ///
  /// In en, this message translates to:
  /// **'Offline Chat — talk to people nearby'**
  String get homeTooltipOfflineChat;

  /// Tooltip for search icon in home app bar.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get homeTooltipSearch;

  /// Overflow menu item: Profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get homeMenuProfile;

  /// Overflow menu item: Settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeMenuSettings;

  /// Overflow menu item: Rate us.
  ///
  /// In en, this message translates to:
  /// **'Rate us'**
  String get homeMenuRateUs;

  /// Overflow menu item: Report Issue.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get homeMenuReportIssue;

  /// Overflow menu item: What's New.
  ///
  /// In en, this message translates to:
  /// **'What\'s New'**
  String get homeMenuWhatsNew;

  /// Overflow menu item: Log out.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get homeMenuLogOut;

  /// Empty state title when user has no chats.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get homeEmptyChatsTitle;

  /// Empty state subtitle in chats tab.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation by tapping the button below'**
  String get homeEmptyChatsSubtitle;

  /// Button to start a new chat in empty state.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get homeNewChatButton;

  /// Pinned AI Assistant tile title.
  ///
  /// In en, this message translates to:
  /// **'GupAI'**
  String get homeAiAssistantTitle;

  /// Pinned AI Assistant tile subtitle.
  ///
  /// In en, this message translates to:
  /// **'Draft, translate, summarise & more'**
  String get homeAiAssistantSubtitle;

  /// Anonymous match banner title.
  ///
  /// In en, this message translates to:
  /// **'Connect with a Stranger'**
  String get homeStrangerMatchTitle;

  /// Anonymous match banner subtitle.
  ///
  /// In en, this message translates to:
  /// **'Anonymous chat — tap to match!'**
  String get homeStrangerMatchSubtitle;

  /// Moments tab section header for current user's status.
  ///
  /// In en, this message translates to:
  /// **'My Moment'**
  String get homeMyMoment;

  /// Moments tab section header for friends' statuses.
  ///
  /// In en, this message translates to:
  /// **'Recent Moments'**
  String get homeRecentMoments;

  /// Empty state title in moments tab.
  ///
  /// In en, this message translates to:
  /// **'No updates yet.'**
  String get homeEmptyMomentsTitle;

  /// Empty state subtitle in moments tab.
  ///
  /// In en, this message translates to:
  /// **'Tap the camera to share.'**
  String get homeEmptyMomentsSubtitle;

  /// Prompt when current user has no active moment.
  ///
  /// In en, this message translates to:
  /// **'Tap to add an update'**
  String get homeTapToAddMoment;

  /// Empty state title in calls tab.
  ///
  /// In en, this message translates to:
  /// **'No call history'**
  String get homeEmptyCallsTitle;

  /// Empty state subtitle in calls tab.
  ///
  /// In en, this message translates to:
  /// **'Your recent calls will appear here'**
  String get homeEmptyCallsSubtitle;

  /// Message input placeholder in chat.
  ///
  /// In en, this message translates to:
  /// **'Message...'**
  String get chatInputHint;

  /// Search input placeholder in chat.
  ///
  /// In en, this message translates to:
  /// **'Search messages...'**
  String get chatSearchHint;

  /// Subtitle typing status indicator in chat header.
  ///
  /// In en, this message translates to:
  /// **'typing...'**
  String get chatStatusTyping;

  /// Subtitle online status in chat header.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get chatStatusOnline;

  /// Subtitle offline status in chat header.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get chatStatusOffline;

  /// Subtitle last seen status in chat header.
  ///
  /// In en, this message translates to:
  /// **'Last seen {time}'**
  String chatStatusLastSeen(String time);

  /// Security trust banner in chat.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encrypted'**
  String get chatEndToEndEncrypted;

  /// Offline mesh banner in chat when internet is down.
  ///
  /// In en, this message translates to:
  /// **'No internet? Chat offline with nearby devices'**
  String get chatNoInternetOfflineTitle;

  /// Button to activate nearby mesh chat in offline banner.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get chatEnableOfflineButton;

  /// Audio recording gesture instruction.
  ///
  /// In en, this message translates to:
  /// **'Slide to cancel'**
  String get chatSlideToCancel;

  /// Tooltip for voice call icon in chat app bar.
  ///
  /// In en, this message translates to:
  /// **'Voice Call'**
  String get chatTooltipVoiceCall;

  /// Tooltip for video call icon in chat app bar.
  ///
  /// In en, this message translates to:
  /// **'Video Call'**
  String get chatTooltipVideoCall;

  /// Chat app bar overflow menu: Contact info.
  ///
  /// In en, this message translates to:
  /// **'Contact info'**
  String get chatMenuContactInfo;

  /// Chat app bar overflow menu: Search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get chatMenuSearch;

  /// Chat app bar overflow menu: Chat theme.
  ///
  /// In en, this message translates to:
  /// **'Chat theme'**
  String get chatMenuChatTheme;

  /// Chat app bar overflow menu: Export chat.
  ///
  /// In en, this message translates to:
  /// **'Export chat'**
  String get chatMenuExportChat;

  /// Chat app bar overflow menu: Mute.
  ///
  /// In en, this message translates to:
  /// **'Mute notifications'**
  String get chatMenuMuteNotifications;

  /// Chat app bar overflow menu: Unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute notifications'**
  String get chatMenuUnmuteNotifications;

  /// Chat app bar overflow menu: Block contact.
  ///
  /// In en, this message translates to:
  /// **'Block contact'**
  String get chatMenuBlockContact;

  /// Message long-press action: Reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get chatActionReply;

  /// Message long-press action: Copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get chatActionCopy;

  /// Message long-press action: Forward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get chatActionForward;

  /// Message long-press action: Translate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get chatActionTranslate;

  /// Message long-press action: Summarise.
  ///
  /// In en, this message translates to:
  /// **'Summarise'**
  String get chatActionSummarise;

  /// Message long-press action: Ask GupAI.
  ///
  /// In en, this message translates to:
  /// **'Ask GupAI'**
  String get chatActionAskGupAi;

  /// Message long-press action: Edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get chatActionEdit;

  /// Message long-press action: Delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get chatActionDelete;

  /// Confirmation title when deleting a message.
  ///
  /// In en, this message translates to:
  /// **'Delete message?'**
  String get chatDeleteMessageTitle;

  /// Delete prompt giving options for me or everyone.
  ///
  /// In en, this message translates to:
  /// **'Delete it just for you, or for everyone in this chat?'**
  String get chatDeleteMessageForEveryonePrompt;

  /// Delete prompt when message cannot be deleted for everyone.
  ///
  /// In en, this message translates to:
  /// **'This removes it from your devices only. {name} will still see it.'**
  String chatDeleteMessageForMeOnlyPrompt(String name);

  /// Button to delete message for current user only.
  ///
  /// In en, this message translates to:
  /// **'Delete for me'**
  String get chatDeleteForMe;

  /// Button to delete message for everyone.
  ///
  /// In en, this message translates to:
  /// **'Delete for everyone'**
  String get chatDeleteForEveryone;

  /// Confirmation dialog title when blocking contact.
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String chatBlockContactTitle(String name);

  /// Confirmation description when blocking contact.
  ///
  /// In en, this message translates to:
  /// **'Blocked contacts cannot send you messages or call you. You can unblock them from Settings → Privacy → Blocked contacts.'**
  String get chatBlockContactPrompt;

  /// Button to confirm blocking a contact.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get chatBlockButton;

  /// Header in forward message sheet.
  ///
  /// In en, this message translates to:
  /// **'Forward to'**
  String get chatForwardTo;

  /// Empty state in forward message sheet.
  ///
  /// In en, this message translates to:
  /// **'No other chats to forward to'**
  String get chatNoForwardChats;

  /// Snackbar when trying to send media to blocked contact.
  ///
  /// In en, this message translates to:
  /// **'Cannot send media to this contact'**
  String get chatCannotSendMediaBlocked;

  /// Title of attachment sheet.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get attachmentShareTitle;

  /// Attachment option: Photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get attachmentPhoto;

  /// Subtitle for Photo attachment.
  ///
  /// In en, this message translates to:
  /// **'Choose an image from your gallery'**
  String get attachmentPhotoSubtitle;

  /// Attachment option: Video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get attachmentVideo;

  /// Subtitle for Video attachment.
  ///
  /// In en, this message translates to:
  /// **'Choose a video from your gallery'**
  String get attachmentVideoSubtitle;

  /// Attachment option: Document.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get attachmentDocument;

  /// Subtitle for Document attachment.
  ///
  /// In en, this message translates to:
  /// **'PDF, Office file, archive — sent as-is'**
  String get attachmentDocumentSubtitle;

  /// Attachment option: Location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get attachmentLocation;

  /// Subtitle for Location attachment.
  ///
  /// In en, this message translates to:
  /// **'Share your current location'**
  String get attachmentLocationSubtitle;

  /// Attachment option: start a live screen-share session (Pro).
  ///
  /// In en, this message translates to:
  /// **'Share screen'**
  String get attachmentScreenShare;

  /// Subtitle for the Share screen attachment option.
  ///
  /// In en, this message translates to:
  /// **'Show your screen live during the chat'**
  String get attachmentScreenShareSubtitle;

  /// Toggle switch title for View Once mode.
  ///
  /// In en, this message translates to:
  /// **'View once'**
  String get attachmentViewOnce;

  /// Toggle switch subtitle for View Once mode.
  ///
  /// In en, this message translates to:
  /// **'Photo or video disappears after it\'s opened'**
  String get attachmentViewOnceSubtitle;

  /// Title of Contacts & Discover screen.
  ///
  /// In en, this message translates to:
  /// **'Contacts & Discover'**
  String get contactsTitle;

  /// Tab label for Friends list.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get contactsTabFriends;

  /// Tab label for Incoming Requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get contactsTabRequests;

  /// Tab label for Discover tab.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get contactsTabDiscover;

  /// Tooltip for Scan QR button in app bar.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get contactsScanQrTooltip;

  /// Tooltip for My Handle button in app bar.
  ///
  /// In en, this message translates to:
  /// **'My Handle'**
  String get contactsMyHandleTooltip;

  /// Prompt when user hasn't set username for QR code.
  ///
  /// In en, this message translates to:
  /// **'Set a @username in your profile first — that\'s what your QR code shares.'**
  String get contactsSetUsernamePrompt;

  /// Title in profile QR bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'My Profile QR Code'**
  String get contactsMyQrCodeTitle;

  /// Subtitle in profile QR bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Friends can scan this QR code to connect with you instantly'**
  String get contactsMyQrCodeSubtitle;

  /// Button to copy profile link.
  ///
  /// In en, this message translates to:
  /// **'Copy Profile Link'**
  String get contactsCopyProfileLink;

  /// Snackbar confirming profile link copied.
  ///
  /// In en, this message translates to:
  /// **'Profile link for @{username} copied!'**
  String contactsProfileLinkCopied(String username);

  /// Button to scan someone else's QR code.
  ///
  /// In en, this message translates to:
  /// **'Scan Someone\'s Code'**
  String get contactsScanSomeonesCode;

  /// Snackbar when contacts permission denied.
  ///
  /// In en, this message translates to:
  /// **'Permission to access contacts was denied.'**
  String get contactsPermissionDenied;

  /// Snackbar when no contacts match app users.
  ///
  /// In en, this message translates to:
  /// **'No GupShupGo users found in your contacts yet.'**
  String get contactsNoUsersFound;

  /// Snackbar when contacts sync fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to sync contacts: {error}'**
  String contactsFailedToSync(String error);

  /// Header in matched contacts sheet.
  ///
  /// In en, this message translates to:
  /// **'{count} contacts on GupShupGo'**
  String contactsMatchedCount(int count);

  /// Subtitle on user tile matched from device contacts.
  ///
  /// In en, this message translates to:
  /// **'From your device contacts'**
  String get contactsFromDeviceContacts;

  /// Error message when loading friends fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your friends.'**
  String get contactsLoadFriendsError;

  /// Title in empty friends tab.
  ///
  /// In en, this message translates to:
  /// **'No Friends Added Yet'**
  String get contactsNoFriendsTitle;

  /// Description in empty friends tab.
  ///
  /// In en, this message translates to:
  /// **'Use the Discover tab to search for users by @username, phone, or email and send them a friend request!'**
  String get contactsNoFriendsPrompt;

  /// Button to switch to discover tab.
  ///
  /// In en, this message translates to:
  /// **'Discover People'**
  String get contactsDiscoverPeopleButton;

  /// Section header for quick connect suggestions.
  ///
  /// In en, this message translates to:
  /// **'QUICK CONNECT'**
  String get contactsQuickConnectHeader;

  /// Empty state for quick suggestions.
  ///
  /// In en, this message translates to:
  /// **'No suggestions available at the moment.'**
  String get contactsNoSuggestions;

  /// Error message when loading requests fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your requests.'**
  String get contactsLoadRequestsError;

  /// Section header for pending incoming requests.
  ///
  /// In en, this message translates to:
  /// **'PENDING REQUESTS ({count})'**
  String contactsPendingRequestsHeader(int count);

  /// Title when there are no incoming requests.
  ///
  /// In en, this message translates to:
  /// **'No Pending Requests'**
  String get contactsNoPendingRequestsTitle;

  /// Subtitle when there are no incoming requests.
  ///
  /// In en, this message translates to:
  /// **'When users send you a connection request, they will show up here.'**
  String get contactsNoPendingRequestsSubtitle;

  /// Subtitle on incoming request tile when username missing.
  ///
  /// In en, this message translates to:
  /// **'Wants to connect'**
  String get contactsWantsToConnect;

  /// Button to accept friend request.
  ///
  /// In en, this message translates to:
  /// **'ACCEPT'**
  String get contactsAcceptButton;

  /// Snackbar when accepting friend request fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t accept the request. Please try again.'**
  String get contactsAcceptFailed;

  /// Snackbar when friend request accepted.
  ///
  /// In en, this message translates to:
  /// **'Connected with {name}!'**
  String contactsConnectedWith(String name);

  /// Snackbar when declining request fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t decline the request. Please try again.'**
  String get contactsDeclineFailed;

  /// Header for You Might Know suggestion grid.
  ///
  /// In en, this message translates to:
  /// **'YOU MIGHT KNOW'**
  String get contactsYouMightKnowHeader;

  /// Link to see all suggestions.
  ///
  /// In en, this message translates to:
  /// **'SEE ALL'**
  String get contactsSeeAll;

  /// Search hint for universal discover search.
  ///
  /// In en, this message translates to:
  /// **'Search name, @handle, phone or email...'**
  String get contactsSearchHint;

  /// Banner text when discoverability is disabled.
  ///
  /// In en, this message translates to:
  /// **'Turn on Discoverability to appear in search and suggestions.'**
  String get contactsTurnOnDiscoverability;

  /// Title when no search results found.
  ///
  /// In en, this message translates to:
  /// **'No Matching Users Found'**
  String get contactsNoMatchingUsersTitle;

  /// Subtitle when no search results found.
  ///
  /// In en, this message translates to:
  /// **'Check the @username, phone number, or email and try again.'**
  String get contactsNoMatchingUsersSubtitle;

  /// Hero title in Discover tab.
  ///
  /// In en, this message translates to:
  /// **'Discover People on GupShupGo'**
  String get contactsDiscoverHeroTitle;

  /// Hero subtitle in Discover tab.
  ///
  /// In en, this message translates to:
  /// **'Expand your circle with high-fidelity connections across the globe.'**
  String get contactsDiscoverHeroSubtitle;

  /// Title of sync device contacts card.
  ///
  /// In en, this message translates to:
  /// **'Sync Device Contacts'**
  String get contactsSyncDeviceContacts;

  /// Title while syncing device contacts.
  ///
  /// In en, this message translates to:
  /// **'Syncing Contacts...'**
  String get contactsSyncingContacts;

  /// Subtitle of sync device contacts card.
  ///
  /// In en, this message translates to:
  /// **'Find your friends instantly from phone contacts'**
  String get contactsSyncDeviceSubtitle;

  /// Header for suggested users list.
  ///
  /// In en, this message translates to:
  /// **'SUGGESTED USERS'**
  String get contactsSuggestedUsersHeader;

  /// Button to send friend request.
  ///
  /// In en, this message translates to:
  /// **'ADD FRIEND'**
  String get contactsAddFriendButton;

  /// Button label when friend request was sent.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get contactsRequestedButton;

  /// Snackbar when friend request sent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent to {name}!'**
  String contactsRequestSent(String name);

  /// Snackbar when friend request fails or already pending.
  ///
  /// In en, this message translates to:
  /// **'Friend request is already pending or failed.'**
  String get contactsRequestFailed;

  /// Snackbar when request is no longer available.
  ///
  /// In en, this message translates to:
  /// **'That request is no longer available.'**
  String get contactsRequestUnavailable;

  /// Title of Edit Profile screen.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditTitle;

  /// Button to save profile changes.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileSaveButton;

  /// Hint beneath avatar to change photo.
  ///
  /// In en, this message translates to:
  /// **'Tap to change photo'**
  String get profileTapToChangePhoto;

  /// Button to upgrade to GupShupGo Pro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get profileUpgradeToPro;

  /// Section label for user's full name.
  ///
  /// In en, this message translates to:
  /// **'YOUR NAME'**
  String get profileSectionName;

  /// Placeholder for user name field.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get profileNameHint;

  /// Section label for username handle.
  ///
  /// In en, this message translates to:
  /// **'UNIQUE HANDLE'**
  String get profileSectionHandle;

  /// Text when username handle is not yet set.
  ///
  /// In en, this message translates to:
  /// **'Not set yet'**
  String get profileHandleNotSet;

  /// Button to change username handle.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get profileChangeHandle;

  /// Section label for about/bio text.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get profileSectionAbout;

  /// Placeholder for about/bio text.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind?'**
  String get profileAboutHint;

  /// Default user status message.
  ///
  /// In en, this message translates to:
  /// **'Hey there! I am using GupShupGo.'**
  String get profileDefaultAbout;

  /// Section label for phone number.
  ///
  /// In en, this message translates to:
  /// **'PHONE'**
  String get profileSectionPhone;

  /// Section label for email address.
  ///
  /// In en, this message translates to:
  /// **'EMAIL'**
  String get profileSectionEmail;

  /// Section label for linked sign-in methods.
  ///
  /// In en, this message translates to:
  /// **'LINKED SIGN-IN METHODS'**
  String get profileSectionLinkedMethods;

  /// Label when sign-in method is not linked.
  ///
  /// In en, this message translates to:
  /// **'Not linked'**
  String get profileNotLinked;

  /// Validation error when name is blank.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty.'**
  String get profileNameEmpty;

  /// Snackbar on profile update success.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdatedSuccess;

  /// Error snackbar when photo upload fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload photo: {error}'**
  String profileUploadPhotoFailed(String error);

  /// Error snackbar when profile saving fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile: {error}'**
  String profileSaveFailed(String error);

  /// Label for points in arcade mini stat.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get profilePoints;

  /// Label for badges in arcade mini stat.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get profileBadges;

  /// Label for best streak bond in arcade mini stat.
  ///
  /// In en, this message translates to:
  /// **'Best Bond'**
  String get profileBestBond;

  /// Header for Account settings card.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccountCard;

  /// Settings tile for Profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfileTile;

  /// Settings tile for Linked sign-in methods.
  ///
  /// In en, this message translates to:
  /// **'Linked sign-in methods'**
  String get settingsLinkedMethodsTile;

  /// Settings tile for Phone number.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get settingsPhoneTile;

  /// Settings tile for Email address.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get settingsEmailTile;

  /// Header for Privacy settings card.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacyCard;

  /// Switch tile for Discoverability.
  ///
  /// In en, this message translates to:
  /// **'Discoverability'**
  String get settingsDiscoverability;

  /// Switch tile for Last seen.
  ///
  /// In en, this message translates to:
  /// **'Last seen'**
  String get settingsLastSeen;

  /// Switch tile for Read receipts.
  ///
  /// In en, this message translates to:
  /// **'Read receipts'**
  String get settingsReadReceipts;

  /// Tile for Google Ad preferences.
  ///
  /// In en, this message translates to:
  /// **'Ad preferences'**
  String get settingsAdPreferences;

  /// Button or trailing label for manage action.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get settingsManage;

  /// Header for Appearance settings card.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceCard;

  /// Tile label for Theme selection.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Light theme mode.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Dark theme mode.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// System theme mode.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// Tile label for Chat theme customization.
  ///
  /// In en, this message translates to:
  /// **'Chat theme'**
  String get settingsChatTheme;

  /// Header for Help & Security settings card.
  ///
  /// In en, this message translates to:
  /// **'Help & Security'**
  String get settingsHelpSecurityCard;

  /// Tile label for Help Center.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get settingsHelpCenter;

  /// Tile label for Report a problem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get settingsReportProblem;

  /// Tile label for Vault end-to-end encryption.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encryption (Vault)'**
  String get settingsE2EEShield;

  /// Tile label for Verify safety number.
  ///
  /// In en, this message translates to:
  /// **'Verify safety number'**
  String get settingsVerifySafetyNumber;

  /// Tile label for Blocked contacts.
  ///
  /// In en, this message translates to:
  /// **'Blocked contacts'**
  String get settingsBlockedContacts;

  /// Tile label for Clear all gup history.
  ///
  /// In en, this message translates to:
  /// **'Clear all gup history'**
  String get settingsClearAllGupHistory;

  /// Tile label for Rate us.
  ///
  /// In en, this message translates to:
  /// **'Rate us'**
  String get settingsRateUs;

  /// Tile label for What's New.
  ///
  /// In en, this message translates to:
  /// **'What\'s New'**
  String get settingsWhatsNew;

  /// Tile label for Check for updates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get settingsCheckForUpdates;

  /// Tile label for App info.
  ///
  /// In en, this message translates to:
  /// **'App info'**
  String get settingsAppInfo;

  /// Button to log out of the application.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get settingsLogOut;

  /// Title of log out confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogOutConfirmTitle;

  /// Prompt of log out confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of GupShupGo?'**
  String get settingsLogOutConfirmPrompt;

  /// Loading message while signing out.
  ///
  /// In en, this message translates to:
  /// **'Signing out…'**
  String get settingsSigningOut;

  /// Title of clear chats confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Clear all chats'**
  String get settingsClearChatsConfirmTitle;

  /// Prompt of clear chats confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all your message history. This action cannot be undone.'**
  String get settingsClearChatsConfirmPrompt;

  /// Confirm button in clear chats dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get settingsDeleteAll;

  /// Snackbar while clearing chats.
  ///
  /// In en, this message translates to:
  /// **'Clearing chats...'**
  String get settingsClearingChats;

  /// Snackbar when all chats cleared.
  ///
  /// In en, this message translates to:
  /// **'All chats cleared'**
  String get settingsAllChatsCleared;

  /// Snackbar when clearing chats fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear chats: {error}'**
  String settingsClearChatsFailed(String error);

  /// Title in theme selection bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Choose theme'**
  String get settingsChooseThemeTitle;

  /// Subtitle on Pro card when not subscribed.
  ///
  /// In en, this message translates to:
  /// **'Unlock premium features'**
  String get settingsUnlockPremiumFeatures;

  /// Subtitle on Pro card with remaining subscription days.
  ///
  /// In en, this message translates to:
  /// **'{planLabel} · {daysRemaining} days left'**
  String settingsProDaysLeft(String planLabel, int daysRemaining);

  /// Loading message while checking for updates.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates…'**
  String get settingsCheckingForUpdates;

  /// Snackbar confirming app is up to date.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the latest version (v{version}).'**
  String settingsUpToDate(String version);

  /// Snackbar when update check is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check for updates. Make sure GupShupGo was installed from the Google Play Store.'**
  String get settingsUpdateCheckUnavailable;

  /// Empty state in blocked contacts sheet.
  ///
  /// In en, this message translates to:
  /// **'No blocked contacts'**
  String get settingsNoBlockedContacts;

  /// Action button to unblock a user.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get settingsUnblock;

  /// Snackbar when a user is unblocked.
  ///
  /// In en, this message translates to:
  /// **'{name} unblocked'**
  String settingsUserUnblocked(String name);

  /// Header in verify safety number sheet.
  ///
  /// In en, this message translates to:
  /// **'Verify a contact'**
  String get settingsVerifyContactTitle;

  /// Subtitle in verify safety number sheet.
  ///
  /// In en, this message translates to:
  /// **'Select a contact to view your shared safety number.'**
  String get settingsVerifyContactSubtitle;

  /// Loading message while computing safety number.
  ///
  /// In en, this message translates to:
  /// **'Computing safety number…'**
  String get settingsComputingSafetyNumber;

  /// Explanation text in safety number dialog.
  ///
  /// In en, this message translates to:
  /// **'If the number below matches on {name}\'s device, your end-to-end encryption is verified.'**
  String settingsSafetyNumberExplanation(String name);

  /// Notice when peer hasn't published key bundle.
  ///
  /// In en, this message translates to:
  /// **'This contact hasn\'t published an encryption key bundle yet. They may be using an older version of GupShupGo.'**
  String get settingsSafetyNumberNoBundle;

  /// Footer hint in safety number dialog.
  ///
  /// In en, this message translates to:
  /// **'Compare this number in person or over a trusted call.'**
  String get settingsSafetyNumberCompareHint;

  /// Label indicating call is end-to-end encrypted.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encrypted'**
  String get callEndToEndEncrypted;

  /// Badge status when establishing call encryption.
  ///
  /// In en, this message translates to:
  /// **'Securing call…'**
  String get callSecuring;

  /// Badge status when call is not encrypted.
  ///
  /// In en, this message translates to:
  /// **'Not encrypted'**
  String get callNotEncrypted;

  /// Title on incoming voice call.
  ///
  /// In en, this message translates to:
  /// **'Incoming Voice Call'**
  String get callIncomingVoice;

  /// Title on incoming video call.
  ///
  /// In en, this message translates to:
  /// **'Incoming Video Call'**
  String get callIncomingVideo;

  /// Subtitle for voice call.
  ///
  /// In en, this message translates to:
  /// **'Voice Call'**
  String get callVoiceCall;

  /// Subtitle for video call.
  ///
  /// In en, this message translates to:
  /// **'Video Call'**
  String get callVideoCall;

  /// Decline incoming call button.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get callDecline;

  /// Accept incoming call button.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get callAccept;

  /// Status text while connecting call.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get callConnecting;

  /// Status text while setting up call.
  ///
  /// In en, this message translates to:
  /// **'Setting up call...'**
  String get callSettingUp;

  /// Status text while notifying remote callee.
  ///
  /// In en, this message translates to:
  /// **'Notifying {name}...'**
  String callNotifying(String name);

  /// Status text while call is ringing.
  ///
  /// In en, this message translates to:
  /// **'Ringing...'**
  String get callRinging;

  /// Status text when call is connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get callConnected;

  /// Status text when call is on hold.
  ///
  /// In en, this message translates to:
  /// **'On hold'**
  String get callOnHold;

  /// Status text when calling.
  ///
  /// In en, this message translates to:
  /// **'Calling...'**
  String get callCalling;

  /// Status text when waiting for remote user video.
  ///
  /// In en, this message translates to:
  /// **'Waiting for remote user...'**
  String get callWaitingForUser;

  /// Status text when call has ended.
  ///
  /// In en, this message translates to:
  /// **'Call Ended'**
  String get callEnded;

  /// Status text when call was declined.
  ///
  /// In en, this message translates to:
  /// **'Call Declined'**
  String get callDeclined;

  /// Status text when call timed out or was not answered.
  ///
  /// In en, this message translates to:
  /// **'No Answer'**
  String get callNoAnswer;

  /// Status text when connection fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect'**
  String get callFailedToConnect;

  /// Snackbar when call fails to start.
  ///
  /// In en, this message translates to:
  /// **'Failed to start call: {error}'**
  String callFailedToStart(String error);

  /// Snackbar when RTC token expired.
  ///
  /// In en, this message translates to:
  /// **'Token expired or invalid. Please restart the call.'**
  String get callTokenExpired;

  /// Snackbar when call initialization fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize {type} call: {error}'**
  String callFailedToInit(String type, String error);

  /// Tooltip to turn off speaker.
  ///
  /// In en, this message translates to:
  /// **'Turn off speaker'**
  String get callTurnOffSpeaker;

  /// Tooltip to turn on speaker.
  ///
  /// In en, this message translates to:
  /// **'Turn on speaker'**
  String get callTurnOnSpeaker;

  /// Tooltip to mute microphone.
  ///
  /// In en, this message translates to:
  /// **'Mute microphone'**
  String get callMuteMic;

  /// Tooltip to unmute microphone.
  ///
  /// In en, this message translates to:
  /// **'Unmute microphone'**
  String get callUnmuteMic;

  /// Tooltip to end call.
  ///
  /// In en, this message translates to:
  /// **'End call'**
  String get callEndCall;

  /// Tooltip to switch camera.
  ///
  /// In en, this message translates to:
  /// **'Switch camera'**
  String get callSwitchCamera;

  /// Tooltip to turn off camera.
  ///
  /// In en, this message translates to:
  /// **'Turn off camera'**
  String get callTurnOffCamera;

  /// Tooltip to turn on camera.
  ///
  /// In en, this message translates to:
  /// **'Turn on camera'**
  String get callTurnOnCamera;

  /// Header showing how many viewed the status.
  ///
  /// In en, this message translates to:
  /// **'Viewed by {count}'**
  String statusViewedByCount(int count);

  /// Empty state when status has no views.
  ///
  /// In en, this message translates to:
  /// **'No views yet'**
  String get statusNoViewsYet;

  /// Viewer count string on status view.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 view} other{{count} views}}'**
  String statusViewCount(int count);

  /// Title of delete status dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete Status'**
  String get statusDeleteTitle;

  /// Confirmation prompt to delete status.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this status?'**
  String get statusDeleteConfirm;

  /// Delete button in dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get statusDeleteButton;

  /// Snackbar confirming status reply sent.
  ///
  /// In en, this message translates to:
  /// **'Reply sent'**
  String get statusReplySent;

  /// Snackbar when status reply fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reply: {error}'**
  String statusReplyFailed(String error);

  /// Empty state when no active status items.
  ///
  /// In en, this message translates to:
  /// **'No active status'**
  String get statusNoActive;

  /// Error message when status cannot be decrypted.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this update'**
  String get statusCouldNotLoad;

  /// Prompt to tap and retry loading status.
  ///
  /// In en, this message translates to:
  /// **'Tap to retry'**
  String get statusTapToRetry;

  /// Error message when status image fails to load.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get statusFailedToLoadImage;

  /// Loading message for status video.
  ///
  /// In en, this message translates to:
  /// **'Loading video...'**
  String get statusLoadingVideo;

  /// Warning when trying to post empty text status.
  ///
  /// In en, this message translates to:
  /// **'Please enter some text'**
  String get statusEnterTextPrompt;

  /// Warning when user has no contacts for status.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet — start a chat before posting a status.'**
  String get statusNoContactsNotice;

  /// Snackbar when posting status fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to post status: {error}'**
  String statusPostFailed(String error);

  /// Hint text for text status editor.
  ///
  /// In en, this message translates to:
  /// **'Type a status...'**
  String get statusTypeHint;

  /// Media picker Camera option.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get statusCamera;

  /// Subtitle to take a photo.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get statusTakePhoto;

  /// Media picker Gallery Photo option.
  ///
  /// In en, this message translates to:
  /// **'Gallery Photo'**
  String get statusGalleryPhoto;

  /// Subtitle to choose photo from gallery.
  ///
  /// In en, this message translates to:
  /// **'Choose an image from gallery'**
  String get statusChooseImageGallery;

  /// Media picker Record Video option.
  ///
  /// In en, this message translates to:
  /// **'Record Video'**
  String get statusRecordVideo;

  /// Subtitle to record short video.
  ///
  /// In en, this message translates to:
  /// **'Record a short video'**
  String get statusRecordShortVideo;

  /// Media picker Gallery Video option.
  ///
  /// In en, this message translates to:
  /// **'Gallery Video'**
  String get statusGalleryVideo;

  /// Subtitle to choose video from gallery.
  ///
  /// In en, this message translates to:
  /// **'Choose a video from gallery'**
  String get statusChooseVideoGallery;

  /// Snackbar when picking image fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image: {error}'**
  String statusFailedPickImage(String error);

  /// Snackbar when picking video fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick video: {error}'**
  String statusFailedPickVideo(String error);

  /// Tooltip for changing status background color.
  ///
  /// In en, this message translates to:
  /// **'Change background color'**
  String get statusChangeBgColorTooltip;

  /// Chip label showing remaining AI messages.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String aiMessagesRemaining(int count);

  /// Title of AI quota info dialog.
  ///
  /// In en, this message translates to:
  /// **'GupAI messages'**
  String get aiQuotaDialogTitle;

  /// Quota status text.
  ///
  /// In en, this message translates to:
  /// **'{remaining} of {total} left today'**
  String aiQuotaRemainingOfTotal(int remaining, int total);

  /// Quota explanation footer note.
  ///
  /// In en, this message translates to:
  /// **'Used {used} today · resets tomorrow. Watch an ad or go Pro for more.'**
  String aiQuotaUsedResetNote(int used);

  /// Dismiss button in quota dialog.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get aiQuotaGotIt;

  /// App bar title for AI Assistant.
  ///
  /// In en, this message translates to:
  /// **'GupAI'**
  String get aiTitle;

  /// App bar subtitle for AI Assistant.
  ///
  /// In en, this message translates to:
  /// **'Your in-app assistant'**
  String get aiSubtitle;

  /// Greeting title on empty AI chat.
  ///
  /// In en, this message translates to:
  /// **'How can I help?'**
  String get aiEmptyHelpTitle;

  /// Description on empty AI chat.
  ///
  /// In en, this message translates to:
  /// **'Draft replies, translate, summarise, brainstorm, or just ask a question. Tap an idea to start.'**
  String get aiEmptyHelpSubtitle;

  /// Status text when mesh peer connected.
  ///
  /// In en, this message translates to:
  /// **'Offline chat · connected'**
  String get meshOfflineChatConnected;

  /// Status text when mesh peer is connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get meshConnecting;

  /// Banner explaining offline mesh mode.
  ///
  /// In en, this message translates to:
  /// **'Offline chat — no internet, no servers'**
  String get meshBannerNotice;

  /// Empty state title in mesh chat.
  ///
  /// In en, this message translates to:
  /// **'Say hi to {name}'**
  String meshSayHiTo(String name);

  /// Empty state description in mesh chat.
  ///
  /// In en, this message translates to:
  /// **'You\'re in offline chat. Messages stay between you and {name}.'**
  String meshOfflineDescription(String name);

  /// Snackbar when view once media is gone.
  ///
  /// In en, this message translates to:
  /// **'This media is no longer available.'**
  String get meshMediaUnavailable;

  /// Title of view once confirmation modal.
  ///
  /// In en, this message translates to:
  /// **'View once'**
  String get meshViewOnceTitle;

  /// Prompt explaining view once limitations.
  ///
  /// In en, this message translates to:
  /// **'You can only open this {type} one time. It closes for good when you leave.'**
  String meshViewOncePrompt(String type);

  /// Arcade tab label for Overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get arcadeTabOverview;

  /// Arcade tab label for Challenges.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get arcadeTabChallenges;

  /// Arcade tab label for Leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get arcadeTabLeaderboard;

  /// Error message when arcade stats fail to load.
  ///
  /// In en, this message translates to:
  /// **'Failed to load reputation stats.'**
  String get arcadeFailedLoadStats;

  /// Hint text for AI composer input field.
  ///
  /// In en, this message translates to:
  /// **'Ask GupAI anything…'**
  String get aiAskHint;

  /// Settings row to manage push notification permission.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsTile;

  /// Trailing status when notifications are enabled.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get settingsNotificationsStatusOn;

  /// Trailing status when notifications are disabled.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsNotificationsStatusOff;

  /// Snackbar shown when notifications are already/now enabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications are on.'**
  String get settingsNotificationsEnabledToast;

  /// Title of the dialog offering to open system settings for notifications.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get settingsEnableNotificationsTitle;

  /// Body of the enable-notifications dialog, shown when the OS permission is denied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off. Open system settings to let GupShupGo notify you about new messages and calls.'**
  String get settingsEnableNotificationsBody;

  /// Button that opens the OS app-settings page.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get settingsOpenSystemSettings;

  /// One-line value proposition under the app name on the login screen (offline Bluetooth chat is the differentiator).
  ///
  /// In en, this message translates to:
  /// **'Private messaging that works even without the internet.'**
  String get loginTagline;

  /// Settings row opening the privacy policy web page.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// Settings row opening the terms of service web page.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTerms;

  /// Settings row opening the account-deletion web page.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// Title of the invite / share sheet.
  ///
  /// In en, this message translates to:
  /// **'Invite friends'**
  String get inviteSheetTitle;

  /// Subtitle under the invite sheet title.
  ///
  /// In en, this message translates to:
  /// **'Spread the word — share GupShupGo'**
  String get inviteSheetSubtitle;

  /// Button that shares the ready-made story image.
  ///
  /// In en, this message translates to:
  /// **'Share image'**
  String get inviteShareImageBtn;

  /// Button that shares the invite link via the system sheet.
  ///
  /// In en, this message translates to:
  /// **'Share link'**
  String get inviteShareLinkBtn;

  /// Button that copies the invite link to the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get inviteCopyLinkBtn;

  /// Snackbar shown after the invite link is copied.
  ///
  /// In en, this message translates to:
  /// **'Invite link copied'**
  String get inviteLinkCopied;

  /// The text shared when inviting a friend; link is the profile or Play Store URL.
  ///
  /// In en, this message translates to:
  /// **'Chat with me on GupShupGo — it even works without the internet 👋 {link}'**
  String inviteMessage(String link);

  /// Tagline on the shareable story card.
  ///
  /// In en, this message translates to:
  /// **'Private chat that works even offline'**
  String get inviteCardTagline;

  /// Call to action under the QR on the story card when the user has no handle.
  ///
  /// In en, this message translates to:
  /// **'Scan to download'**
  String get inviteCardScan;

  /// Footer on the story card.
  ///
  /// In en, this message translates to:
  /// **'Download on Google Play'**
  String get inviteCardDownload;

  /// Home overflow-menu item that opens the invite sheet.
  ///
  /// In en, this message translates to:
  /// **'Invite friends'**
  String get homeMenuInvite;

  /// Title of the one-time post-signup invite prompt.
  ///
  /// In en, this message translates to:
  /// **'Enjoying GupShupGo?'**
  String get invitePromptTitle;

  /// Body of the one-time post-signup invite prompt.
  ///
  /// In en, this message translates to:
  /// **'It\'s better with friends — and it works even without internet. Invite someone?'**
  String get invitePromptBody;

  /// Confirm button on the invite prompt.
  ///
  /// In en, this message translates to:
  /// **'Invite friends'**
  String get invitePromptInvite;

  /// Dismiss button on the invite prompt.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get invitePromptLater;

  /// Title of the home banner shown when the device has no internet connection, inviting the user into offline mesh chat.
  ///
  /// In en, this message translates to:
  /// **'No internet? No problem'**
  String get homeOfflineBannerTitle;

  /// Subtitle of the offline home banner explaining the offline Bluetooth mesh capability.
  ///
  /// In en, this message translates to:
  /// **'You can still message people nearby over Bluetooth.'**
  String get homeOfflineBannerSubtitle;

  /// Title of the home banner shown when GupShupGo peers are detected nearby over mesh; count is the number of peers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person nearby} other{{count} people nearby}}'**
  String homeNearbyBannerTitle(int count);

  /// Subtitle of the nearby-peers home banner.
  ///
  /// In en, this message translates to:
  /// **'Chat over Bluetooth — no internet needed.'**
  String get homeNearbyBannerSubtitle;

  /// Title on the link-accounts screen.
  ///
  /// In en, this message translates to:
  /// **'Add a backup sign-in method'**
  String get linkBackupTitle;

  /// Subtitle on the link-accounts screen.
  ///
  /// In en, this message translates to:
  /// **'Link Google or email so you can sign back in\neven if your SIM is unavailable.'**
  String get linkBackupSubtitle;

  /// Label for linking Google account.
  ///
  /// In en, this message translates to:
  /// **'Link Google Account'**
  String get linkGoogleTitle;

  /// Status when Google is linked.
  ///
  /// In en, this message translates to:
  /// **'Linked ✓'**
  String get linkGoogleSubtitleLinked;

  /// Description for Google linking.
  ///
  /// In en, this message translates to:
  /// **'One-tap sign-in without SIM'**
  String get linkGoogleSubtitleUnlinked;

  /// Action button to link Google.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get linkGoogleAction;

  /// Snackbar when Google is linked.
  ///
  /// In en, this message translates to:
  /// **'Google account linked successfully!'**
  String get linkGoogleSuccess;

  /// Error when Google account belongs to another user.
  ///
  /// In en, this message translates to:
  /// **'This Google account is already registered as a separate GupShupGo account. To merge, sign out and sign in with Google, then link your phone number from settings.'**
  String get linkGoogleAlreadyUsed;

  /// Generic Google linking error.
  ///
  /// In en, this message translates to:
  /// **'Google linking failed. Try again.'**
  String get linkGoogleFailed;

  /// Error when session expired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please sign in again.'**
  String get linkSessionExpired;

  /// Label for linking Email & password.
  ///
  /// In en, this message translates to:
  /// **'Link Email & Password'**
  String get linkEmailTitle;

  /// Status when email is linked.
  ///
  /// In en, this message translates to:
  /// **'Linked ✓'**
  String get linkEmailSubtitleLinked;

  /// Description for email linking.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email if no SIM or Google'**
  String get linkEmailSubtitleUnlinked;

  /// Button to open email link form.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get linkEmailActionAdd;

  /// Button to cancel email link form.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get linkEmailActionCancel;

  /// Email textfield label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get linkEmailFieldLabel;

  /// Password textfield label.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get linkPasswordFieldLabel;

  /// Password minimum length helper.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get linkPasswordHelper;

  /// Button to submit email linking.
  ///
  /// In en, this message translates to:
  /// **'Link Email'**
  String get linkEmailButton;

  /// Snackbar when email is linked.
  ///
  /// In en, this message translates to:
  /// **'Email linked successfully!'**
  String get linkEmailSuccess;

  /// Validation error for invalid email.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get linkEmailInvalid;

  /// Validation error for short password.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get linkPasswordTooShort;

  /// Error when email is already in use.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered separately on GupShupGo. Sign in with email first, then link your phone from settings.'**
  String get linkEmailAlreadyInUse;

  /// Error when email is already linked.
  ///
  /// In en, this message translates to:
  /// **'An email is already linked to your account.'**
  String get linkEmailAlreadyLinked;

  /// Generic email linking error.
  ///
  /// In en, this message translates to:
  /// **'Email linking failed. Try again.'**
  String get linkEmailFailed;

  /// Button to continue to app when providers are linked.
  ///
  /// In en, this message translates to:
  /// **'Continue to App'**
  String get linkContinueToApp;

  /// Button to skip linking backup account.
  ///
  /// In en, this message translates to:
  /// **'Skip for Now'**
  String get linkSkipForNow;

  /// Top bar skip button.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get linkSkip;

  /// Title on phone number entry stage.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your phone number.'**
  String get phoneAuthTitleEntry;

  /// Title on OTP entry stage.
  ///
  /// In en, this message translates to:
  /// **'Enter the code we sent you.'**
  String get phoneAuthTitleOtp;

  /// Hint for name input.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get phoneAuthNameHint;

  /// Hint for phone number input.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneAuthPhoneHint;

  /// Button to auto-fill SIM phone number.
  ///
  /// In en, this message translates to:
  /// **'Use SIM'**
  String get phoneAuthUseSim;

  /// Button to send SMS verification code.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get phoneAuthSendOtp;

  /// Prompt showing which phone number received the OTP.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {phone}'**
  String phoneAuthOtpPrompt(String phone);

  /// Generic prompt for OTP.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code we sent you'**
  String get phoneAuthOtpPromptGeneric;

  /// Hint for OTP input field.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get phoneAuthOtpHint;

  /// Button to verify the OTP.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get phoneAuthVerify;

  /// Button to return to phone entry.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get phoneAuthGoBack;

  /// Button to resend OTP code.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get phoneAuthResendCode;

  /// Error when name is empty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get phoneAuthEnterName;

  /// Error when phone number is invalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get phoneAuthEnterValidPhone;

  /// Error when OTP code is empty.
  ///
  /// In en, this message translates to:
  /// **'Please enter the code'**
  String get phoneAuthEnterCode;

  /// Error when verification session is missing.
  ///
  /// In en, this message translates to:
  /// **'Please request a new code.'**
  String get phoneAuthRequestNewCode;

  /// Error when OTP is wrong.
  ///
  /// In en, this message translates to:
  /// **'That code is incorrect. Please try again.'**
  String get phoneAuthCodeIncorrect;

  /// FirebaseAuth error for invalid verification code.
  ///
  /// In en, this message translates to:
  /// **'That code is incorrect. Please check and try again.'**
  String get phoneAuthErrCodeIncorrect;

  /// FirebaseAuth error for expired code.
  ///
  /// In en, this message translates to:
  /// **'The code expired. Tap \"Resend code\" to get a new one.'**
  String get phoneAuthErrCodeExpired;

  /// FirebaseAuth error for too many attempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a while and try again.'**
  String get phoneAuthErrTooManyRequests;

  /// FirebaseAuth error for invalid phone number.
  ///
  /// In en, this message translates to:
  /// **'That phone number looks invalid. Please check it.'**
  String get phoneAuthErrInvalidPhone;

  /// FirebaseAuth error for SMS quota exceeded.
  ///
  /// In en, this message translates to:
  /// **'SMS limit reached. Please try again later.'**
  String get phoneAuthErrQuotaExceeded;

  /// Generic auth failure error.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Please try again.'**
  String get phoneAuthErrFailed;

  /// AppBar title on username setup screen.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Handle'**
  String get usernameSetupAppBarTitle;

  /// Header title on username setup screen.
  ///
  /// In en, this message translates to:
  /// **'Secure Your Identity'**
  String get usernameSetupHeaderTitle;

  /// Description of what a username/handle does.
  ///
  /// In en, this message translates to:
  /// **'Your @handle is your unique key on GupShupGo. Others can search and add you securely without sharing your phone or email.'**
  String get usernameSetupHeaderDesc;

  /// Placeholder hint for handle input.
  ///
  /// In en, this message translates to:
  /// **'your_handle'**
  String get usernameSetupInputHint;

  /// Status when checking handle availability.
  ///
  /// In en, this message translates to:
  /// **'Checking availability...'**
  String get usernameSetupChecking;

  /// Status when handle is available.
  ///
  /// In en, this message translates to:
  /// **'@{handle} is available!'**
  String usernameSetupAvailable(String handle);

  /// Status when handle is already taken.
  ///
  /// In en, this message translates to:
  /// **'@{handle} is already taken by another user.'**
  String usernameSetupTaken(String handle);

  /// Character rule guidance text.
  ///
  /// In en, this message translates to:
  /// **'3–20 characters (a-z, 0-9, _)'**
  String get usernameSetupCharRules;

  /// Error when handle is under 3 chars.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters long.'**
  String get usernameSetupTooShort;

  /// Error when handle is over 20 chars.
  ///
  /// In en, this message translates to:
  /// **'Username must be at most 20 characters long.'**
  String get usernameSetupTooLong;

  /// Error when handle contains illegal characters.
  ///
  /// In en, this message translates to:
  /// **'Only letters, numbers, and underscores allowed.'**
  String get usernameSetupInvalidChars;

  /// Header for suggested handles.
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED FOR YOU'**
  String get usernameSetupRecommended;

  /// Button to save handle and proceed.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get usernameSetupSaveBtn;

  /// Button to skip handle setup for now.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get usernameSetupSkipBtn;

  /// Error when setting username fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to set username: {error}'**
  String usernameSetupFailed(String error);

  /// Header title when setting up vault PIN.
  ///
  /// In en, this message translates to:
  /// **'Protect Vault'**
  String get vaultProtectTitle;

  /// Header title when unlocking vault.
  ///
  /// In en, this message translates to:
  /// **'Unlock Vault'**
  String get vaultUnlockTitle;

  /// Description when setting up vault PIN.
  ///
  /// In en, this message translates to:
  /// **'Choose a PIN to encrypt your message history. You will need it to read your messages on a new phone, so pick something you can remember.'**
  String get vaultSetupDesc;

  /// Description when unlocking with PIN or biometrics.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN or tap fingerprint to decrypt history.'**
  String get vaultUnlockDescBio;

  /// Description when unlocking with PIN.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to decrypt your history.'**
  String get vaultUnlockDescPin;

  /// Hint shown after reinstalling when biometrics is not yet enrolled.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to restore your history on this device. You can turn fingerprint unlock back on afterwards.'**
  String get vaultReinstallHint;

  /// Button to unlock using fingerprint.
  ///
  /// In en, this message translates to:
  /// **'Unlock with Fingerprint'**
  String get vaultUnlockWithFingerprint;

  /// Divider between biometric unlock and PIN.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get vaultOrDivider;

  /// Label for new PIN field.
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get vaultNewPin;

  /// Label for confirm PIN field.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get vaultConfirmPin;

  /// Label for enter PIN field.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get vaultEnterPin;

  /// Toggle to switch PIN keyboard to letters.
  ///
  /// In en, this message translates to:
  /// **'Use letters instead'**
  String get vaultKeyboardUseLetters;

  /// Toggle to switch PIN keyboard to numbers.
  ///
  /// In en, this message translates to:
  /// **'Use numbers instead'**
  String get vaultKeyboardUseNumbers;

  /// Button to postpone vault unlock.
  ///
  /// In en, this message translates to:
  /// **'Restore later'**
  String get vaultRestoreLater;

  /// Button when user forgot their PIN.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get vaultForgotPin;

  /// Button to set new PIN.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get vaultSetPinBtn;

  /// Button to decrypt vault.
  ///
  /// In en, this message translates to:
  /// **'Decrypt'**
  String get vaultDecryptBtn;

  /// Validation error when PIN is under 6 characters.
  ///
  /// In en, this message translates to:
  /// **'PIN must be at least 6 characters.'**
  String get vaultPinMinLength;

  /// Validation error when PINs do not match.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match.'**
  String get vaultPinsDoNotMatch;

  /// Error when vault setup fails.
  ///
  /// In en, this message translates to:
  /// **'Setup failed. Check connection.'**
  String get vaultSetupFailed;

  /// Error when PIN is incorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN. Try again.'**
  String get vaultIncorrectPin;

  /// Error when biometric stored PIN is out of date.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint unlock is out of date. Enter your PIN.'**
  String get vaultFingerprintOutOfDate;

  /// Generic biometric error message.
  ///
  /// In en, this message translates to:
  /// **'Biometric error. Enter PIN manually.'**
  String get vaultBiometricError;

  /// Biometric system prompt reason for unlock.
  ///
  /// In en, this message translates to:
  /// **'Authenticate using biometrics to unlock your vault'**
  String get vaultBioReasonUnlock;

  /// Biometric system prompt reason for enrolment.
  ///
  /// In en, this message translates to:
  /// **'Confirm your fingerprint to enable quick unlock'**
  String get vaultBioReasonEnrol;

  /// Dialog title asking to enable fingerprint.
  ///
  /// In en, this message translates to:
  /// **'Unlock with fingerprint?'**
  String get vaultAskBioTitle;

  /// Dialog description explaining fingerprint unlock.
  ///
  /// In en, this message translates to:
  /// **'Skip typing your PIN on this phone. Your PIN is still what protects the vault — keep it somewhere safe, because you will need it on a new phone or after reinstalling.'**
  String get vaultAskBioDesc;

  /// Button declining fingerprint unlock for now.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get vaultAskBioNotNow;

  /// Button enabling fingerprint unlock.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get vaultAskBioEnable;

  /// Dialog title confirming deletion of all messages on vault reset.
  ///
  /// In en, this message translates to:
  /// **'Delete all messages?'**
  String get vaultDeleteMessagesTitle;

  /// Dialog description explaining vault reset consequences.
  ///
  /// In en, this message translates to:
  /// **'Without your PIN your history cannot be decrypted, so resetting deletes all of it — the encrypted cloud copy and the copy on this phone. Your chats will be empty.\n\nYour account and contacts are not affected, and you can keep messaging normally afterwards. This cannot be undone.'**
  String get vaultDeleteMessagesDesc;

  /// Cancel button in vault reset dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get vaultDeleteMessagesCancel;

  /// Confirm button to delete everything in vault reset dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get vaultDeleteMessagesConfirm;

  /// Dialog title for vault PIN confirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirm your vault PIN'**
  String get vaultCustodyConfirmTitle;

  /// Dialog title for choosing a new vault PIN.
  ///
  /// In en, this message translates to:
  /// **'Choose a PIN'**
  String get vaultCustodyChooseTitle;

  /// Description for confirming current vault PIN.
  ///
  /// In en, this message translates to:
  /// **'Your message history is encrypted with a PIN. Confirm it once so you can restore your messages on a new phone or after reinstalling.\n\nIf your vault was set up with just your fingerprint, you may never have been shown a PIN.'**
  String get vaultCustodyConfirmDesc;

  /// Description for re-keying vault with a new PIN.
  ///
  /// In en, this message translates to:
  /// **'Pick a PIN you will remember. Every message you already have is kept — it is re-encrypted under the new PIN, nothing is deleted.'**
  String get vaultCustodyChooseDesc;

  /// Button when user doesn't know their current PIN.
  ///
  /// In en, this message translates to:
  /// **'I don\'t know my PIN'**
  String get vaultCustodyDontKnow;

  /// Confirm button in custody dialog.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get vaultCustodyConfirmBtn;

  /// Save button in custody dialog.
  ///
  /// In en, this message translates to:
  /// **'Save PIN'**
  String get vaultCustodySaveBtn;

  /// Error when custody confirmation PIN does not match.
  ///
  /// In en, this message translates to:
  /// **'That PIN does not match. If you never chose one, tap \"I don\'t know my PIN\".'**
  String get vaultCustodyMismatchError;

  /// Error when re-keying failed.
  ///
  /// In en, this message translates to:
  /// **'Could not update the PIN automatically. Please enter your current PIN.'**
  String get vaultCustodyAutoUpdateFailed;

  /// Progress text while re-encrypting vault entries.
  ///
  /// In en, this message translates to:
  /// **'Re-encrypting {done} of {total}… keep the app open.'**
  String vaultCustodyReencrypting(int done, int total);

  /// Progress text while preparing vault re-encryption.
  ///
  /// In en, this message translates to:
  /// **'Preparing… keep the app open.'**
  String get vaultCustodyPreparing;

  /// AppBar title for vault settings.
  ///
  /// In en, this message translates to:
  /// **'Vault'**
  String get vaultSettingsTitle;

  /// Title for about vault card.
  ///
  /// In en, this message translates to:
  /// **'About the vault'**
  String get vaultSettingsAboutTitle;

  /// Description of how vault works.
  ///
  /// In en, this message translates to:
  /// **'A private backup of your chat history, locked with your PIN. It brings your messages back when you reinstall the app or switch to a new phone. Only your PIN can open it — nobody else can read what is inside, not even us.'**
  String get vaultSettingsAboutDesc;

  /// Bullet list item for your messages.
  ///
  /// In en, this message translates to:
  /// **'Your messages'**
  String get vaultSettingsBulletMessages;

  /// Bullet list item for statuses you can see.
  ///
  /// In en, this message translates to:
  /// **'Statuses you can see'**
  String get vaultSettingsBulletStatuses;

  /// Footnote about what is never kept in the vault.
  ///
  /// In en, this message translates to:
  /// **'Never kept here: your call history, contacts, photos shared in chats, or anyone else\'s private messages.'**
  String get vaultSettingsNeverKept;

  /// Privacy section header in vault settings.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY'**
  String get vaultSettingsSectionPrivacy;

  /// Label for auto-delete old messages setting.
  ///
  /// In en, this message translates to:
  /// **'Auto-delete old messages'**
  String get vaultSettingsAutoDelete;

  /// Retention option to keep forever.
  ///
  /// In en, this message translates to:
  /// **'Keep forever'**
  String get vaultSettingsKeepForever;

  /// Retention subtitle showing expiry window.
  ///
  /// In en, this message translates to:
  /// **'Delete after {label}'**
  String vaultSettingsDeleteAfter(String label);

  /// PIN section header in vault settings.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get vaultSettingsSectionPin;

  /// Title for change PIN row.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get vaultSettingsChangePin;

  /// Subtitle for change PIN row.
  ///
  /// In en, this message translates to:
  /// **'Re-encrypts every vault entry'**
  String get vaultSettingsChangePinSubtitle;

  /// Title for fingerprint unlock toggle.
  ///
  /// In en, this message translates to:
  /// **'Unlock with fingerprint'**
  String get vaultSettingsBioTitle;

  /// Subtitle when fingerprint is enabled.
  ///
  /// In en, this message translates to:
  /// **'On for this device'**
  String get vaultSettingsBioSubOn;

  /// Subtitle when fingerprint is disabled.
  ///
  /// In en, this message translates to:
  /// **'Skip typing your PIN on this device'**
  String get vaultSettingsBioSubOff;

  /// Danger zone section header.
  ///
  /// In en, this message translates to:
  /// **'DANGER ZONE'**
  String get vaultSettingsSectionDanger;

  /// Title for delete vault data row.
  ///
  /// In en, this message translates to:
  /// **'Delete vault data'**
  String get vaultSettingsDeleteData;

  /// Subtitle for delete vault data row.
  ///
  /// In en, this message translates to:
  /// **'Wipes encrypted history, keeps PIN'**
  String get vaultSettingsDeleteDataSubtitle;

  /// Title for reset vault row.
  ///
  /// In en, this message translates to:
  /// **'Reset vault'**
  String get vaultSettingsResetVault;

  /// Subtitle for reset vault row.
  ///
  /// In en, this message translates to:
  /// **'Forgets PIN and deletes everything'**
  String get vaultSettingsResetVaultSubtitle;

  /// Snackbar when PIN is changed.
  ///
  /// In en, this message translates to:
  /// **'PIN changed.'**
  String get vaultSettingsPinChanged;

  /// Snackbar when fingerprint unlock is turned off.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint unlock turned off. Your PIN still works.'**
  String get vaultSettingsBioTurnedOff;

  /// Snackbar when fingerprint unlock is turned on.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint unlock enabled on this device.'**
  String get vaultSettingsBioTurnedOn;

  /// Dialog title for delete vault data.
  ///
  /// In en, this message translates to:
  /// **'Delete vault data?'**
  String get vaultSettingsClearDataTitle;

  /// Dialog description for delete vault data.
  ///
  /// In en, this message translates to:
  /// **'Removes every encrypted message and status from the cloud vault. Your PIN stays the same — new messages will encrypt under it as before. Cannot be undone.'**
  String get vaultSettingsClearDataDesc;

  /// Cancel button in clear vault data dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get vaultSettingsClearDataCancel;

  /// Confirm button to delete vault data.
  ///
  /// In en, this message translates to:
  /// **'Delete data'**
  String get vaultSettingsClearDataConfirm;

  /// Snackbar when vault data is deleted.
  ///
  /// In en, this message translates to:
  /// **'Vault data deleted.'**
  String get vaultSettingsDataDeleted;

  /// Dialog title for reset vault.
  ///
  /// In en, this message translates to:
  /// **'Reset vault?'**
  String get vaultSettingsResetTitle;

  /// Dialog description for reset vault.
  ///
  /// In en, this message translates to:
  /// **'Removes your PIN, deletes every encrypted entry, and clears the local cache. You will be asked to set a fresh PIN. Cannot be undone.'**
  String get vaultSettingsResetDesc;

  /// Confirm button in reset vault dialog.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get vaultSettingsResetConfirm;

  /// Description in change PIN dialog.
  ///
  /// In en, this message translates to:
  /// **'Every encrypted entry will be re-encrypted under the new PIN. Keep the app open until this finishes.'**
  String get vaultSettingsChangeDialogDesc;

  /// Hint for current PIN field.
  ///
  /// In en, this message translates to:
  /// **'Current PIN'**
  String get vaultSettingsCurrentPin;

  /// Hint for new PIN field.
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get vaultSettingsNewPin;

  /// Hint for confirm new PIN field.
  ///
  /// In en, this message translates to:
  /// **'Confirm new PIN'**
  String get vaultSettingsConfirmNewPin;

  /// Validation error when current PIN is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your current PIN.'**
  String get vaultSettingsEnterCurrentPin;

  /// Validation error when new PIN is too short.
  ///
  /// In en, this message translates to:
  /// **'New PIN must be at least 6 characters.'**
  String get vaultSettingsNewPinMinLength;

  /// Validation error when new PINs do not match.
  ///
  /// In en, this message translates to:
  /// **'New PINs do not match.'**
  String get vaultSettingsNewPinMismatch;

  /// Error when current PIN is wrong.
  ///
  /// In en, this message translates to:
  /// **'Current PIN is incorrect.'**
  String get vaultSettingsCurrentPinIncorrect;

  /// Progress label in change PIN dialog.
  ///
  /// In en, this message translates to:
  /// **'Re-encrypting {done} of {total}…'**
  String vaultSettingsReencryptingCount(int done, int total);

  /// Submit button in change PIN dialog.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get vaultSettingsChangeBtn;

  /// Dialog title asking for PIN to enable fingerprint.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get vaultSettingsBioPinDialogTitle;

  /// Dialog description explaining why PIN is needed for fingerprint.
  ///
  /// In en, this message translates to:
  /// **'Your PIN is stored on this device so your fingerprint can unlock the vault. You will still need the PIN itself on a new phone or after reinstalling, so keep it somewhere safe.'**
  String get vaultSettingsBioPinDialogDesc;

  /// Continue button in fingerprint PIN dialog.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get vaultSettingsContinueBtn;

  /// Title for Pro upgrade screen.
  ///
  /// In en, this message translates to:
  /// **'GupShupGo Pro'**
  String get premiumTitle;

  /// Subtitle when user is a Pro member.
  ///
  /// In en, this message translates to:
  /// **'You\'re a Pro member! 🎉'**
  String get premiumSubtitleMember;

  /// Subtitle when user is not Pro.
  ///
  /// In en, this message translates to:
  /// **'Unlock the full experience'**
  String get premiumSubtitleUnlock;

  /// Banner showing remaining Pro subscription days.
  ///
  /// In en, this message translates to:
  /// **'{days} days remaining'**
  String premiumActiveDaysRemaining(int days);

  /// Section header for Pro features list.
  ///
  /// In en, this message translates to:
  /// **'What you get with Pro'**
  String get premiumFeaturesHeader;

  /// Section header for pricing plans.
  ///
  /// In en, this message translates to:
  /// **'Choose your plan'**
  String get premiumPlansHeader;

  /// Primary subscribe button on Pro screen.
  ///
  /// In en, this message translates to:
  /// **'Subscribe Now'**
  String get premiumSubscribeBtn;

  /// Footnote about canceling Google Play subscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime from Google Play subscriptions.'**
  String get premiumCancelAnytime;

  /// Button to restore previous purchase.
  ///
  /// In en, this message translates to:
  /// **'Restore previous purchase'**
  String get premiumRestoreBtn;

  /// Status text while restoring purchase.
  ///
  /// In en, this message translates to:
  /// **'Restoring…'**
  String get premiumRestoring;

  /// Snackbar when Pro subscription is restored.
  ///
  /// In en, this message translates to:
  /// **'Pro subscription restored! 🎉'**
  String get premiumRestoredSuccess;

  /// Snackbar when no active subscription was found.
  ///
  /// In en, this message translates to:
  /// **'No active subscription found.'**
  String get premiumNoActiveSub;

  /// Error when in-app purchase product is not found.
  ///
  /// In en, this message translates to:
  /// **'Product not available. Make sure you have an active internet connection and the app is downloaded from the Play Store.'**
  String get premiumProductUnavailable;

  /// Feature title for Media Moments.
  ///
  /// In en, this message translates to:
  /// **'Media Moments'**
  String get premiumFeatureMediaTitle;

  /// Feature description for Media Moments.
  ///
  /// In en, this message translates to:
  /// **'Share photos & videos as status updates'**
  String get premiumFeatureMediaDesc;

  /// Free tier badge for Media Moments.
  ///
  /// In en, this message translates to:
  /// **'Text only'**
  String get premiumFeatureMediaFree;

  /// Pro tier badge for Media Moments.
  ///
  /// In en, this message translates to:
  /// **'Photos + Videos'**
  String get premiumFeatureMediaPro;

  /// Feature title for Screen Sharing.
  ///
  /// In en, this message translates to:
  /// **'Screen Sharing'**
  String get premiumFeatureScreenShareTitle;

  /// Feature description for Screen Sharing.
  ///
  /// In en, this message translates to:
  /// **'Share your screen live during chats'**
  String get premiumFeatureScreenShareDesc;

  /// Free tier badge for Screen Sharing.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get premiumFeatureScreenShareFree;

  /// Pro tier badge for Screen Sharing.
  ///
  /// In en, this message translates to:
  /// **'Full access'**
  String get premiumFeatureScreenSharePro;

  /// Feature title for Chat Themes.
  ///
  /// In en, this message translates to:
  /// **'Chat Themes'**
  String get premiumFeatureThemesTitle;

  /// Feature description for Chat Themes.
  ///
  /// In en, this message translates to:
  /// **'Patterned backgrounds & gradient bubbles, per chat'**
  String get premiumFeatureThemesDesc;

  /// Free tier badge for Chat Themes.
  ///
  /// In en, this message translates to:
  /// **'6 themes'**
  String get premiumFeatureThemesFree;

  /// Pro tier badge for Chat Themes.
  ///
  /// In en, this message translates to:
  /// **'All 12 + your own photo'**
  String get premiumFeatureThemesPro;

  /// Feature title for Voice Notes duration.
  ///
  /// In en, this message translates to:
  /// **'Longer Voice Messages'**
  String get premiumFeatureVoiceTitle;

  /// Feature description for Voice Notes duration.
  ///
  /// In en, this message translates to:
  /// **'Record longer voice notes'**
  String get premiumFeatureVoiceDesc;

  /// Free tier badge for Voice Notes.
  ///
  /// In en, this message translates to:
  /// **'2 minutes'**
  String get premiumFeatureVoiceFree;

  /// Pro tier badge for Voice Notes.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get premiumFeatureVoicePro;

  /// Feature title for Higher Quality Media.
  ///
  /// In en, this message translates to:
  /// **'Higher Quality Media'**
  String get premiumFeatureQualityTitle;

  /// Feature description for Higher Quality Media.
  ///
  /// In en, this message translates to:
  /// **'Sharper photos and longer status videos'**
  String get premiumFeatureQualityDesc;

  /// Free tier badge for Media Quality.
  ///
  /// In en, this message translates to:
  /// **'Standard quality'**
  String get premiumFeatureQualityFree;

  /// Pro tier badge for Media Quality.
  ///
  /// In en, this message translates to:
  /// **'High quality + 90s videos'**
  String get premiumFeatureQualityPro;

  /// Feature title for Bond Restore.
  ///
  /// In en, this message translates to:
  /// **'Bond Restore'**
  String get premiumFeatureBondTitle;

  /// Feature description for Bond Restore.
  ///
  /// In en, this message translates to:
  /// **'Restore broken bonds for free'**
  String get premiumFeatureBondDesc;

  /// Free tier badge for Bond Restore.
  ///
  /// In en, this message translates to:
  /// **'Points or watch an ad'**
  String get premiumFeatureBondFree;

  /// Pro tier badge for Bond Restore.
  ///
  /// In en, this message translates to:
  /// **'1 free restore/week'**
  String get premiumFeatureBondPro;

  /// Feature title for Pro Badge.
  ///
  /// In en, this message translates to:
  /// **'Pro Badge'**
  String get premiumFeatureBadgeTitle;

  /// Feature description for Pro Badge.
  ///
  /// In en, this message translates to:
  /// **'Show off your Pro status'**
  String get premiumFeatureBadgeDesc;

  /// Free tier badge for Pro Badge.
  ///
  /// In en, this message translates to:
  /// **'No badge'**
  String get premiumFeatureBadgeFree;

  /// Pro tier badge for Pro Badge.
  ///
  /// In en, this message translates to:
  /// **'Exclusive Pro badge'**
  String get premiumFeatureBadgePro;

  /// Feature title for Chat Export.
  ///
  /// In en, this message translates to:
  /// **'Chat Export'**
  String get premiumFeatureExportTitle;

  /// Feature description for Chat Export.
  ///
  /// In en, this message translates to:
  /// **'Save a chat as a PDF you can print, or as plain text'**
  String get premiumFeatureExportDesc;

  /// Free tier badge for Chat Export.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get premiumFeatureExportFree;

  /// Pro tier badge for Chat Export.
  ///
  /// In en, this message translates to:
  /// **'PDF & TXT export'**
  String get premiumFeatureExportPro;

  /// Feature title for Ad-Free Experience.
  ///
  /// In en, this message translates to:
  /// **'Ad-Free Experience'**
  String get premiumFeatureAdFreeTitle;

  /// Feature description for Ad-Free Experience.
  ///
  /// In en, this message translates to:
  /// **'No banner ads anywhere in the app'**
  String get premiumFeatureAdFreeDesc;

  /// Free tier badge for Ads.
  ///
  /// In en, this message translates to:
  /// **'Banner ads shown'**
  String get premiumFeatureAdFreeFree;

  /// Pro tier badge for Ads.
  ///
  /// In en, this message translates to:
  /// **'No banners (reward ads stay optional)'**
  String get premiumFeatureAdFreePro;

  /// Label for monthly subscription plan.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get premiumPlanMonthly;

  /// Label for yearly subscription plan.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get premiumPlanYearly;

  /// Badge showing percentage saved on yearly plan.
  ///
  /// In en, this message translates to:
  /// **'Save ~33%'**
  String get premiumPlanSavings;

  /// Period suffix for monthly plan.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get premiumPeriodMonth;

  /// Period suffix for yearly plan.
  ///
  /// In en, this message translates to:
  /// **'/year'**
  String get premiumPeriodYear;

  /// AppBar title for offline mesh chat screen.
  ///
  /// In en, this message translates to:
  /// **'Offline Chat'**
  String get nearbyOfflineChatTitle;

  /// Snackbar when searching nearby devices.
  ///
  /// In en, this message translates to:
  /// **'Searching nearby devices…'**
  String get nearbySearchingDevices;

  /// Tooltip to stop offline chat.
  ///
  /// In en, this message translates to:
  /// **'Stop offline chat'**
  String get nearbyTooltipStop;

  /// Tooltip to start offline chat.
  ///
  /// In en, this message translates to:
  /// **'Start offline chat'**
  String get nearbyTooltipStart;

  /// Section header for nearby discovered devices.
  ///
  /// In en, this message translates to:
  /// **'Devices Nearby'**
  String get nearbyDevicesSection;

  /// Status tag when discovery is running.
  ///
  /// In en, this message translates to:
  /// **'DISCOVERY ON'**
  String get nearbyDiscoveryOn;

  /// Status tag when discovery is off.
  ///
  /// In en, this message translates to:
  /// **'DISCOVERY OFF'**
  String get nearbyDiscoveryOff;

  /// Hero card title on offline mesh screen.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get nearbyHeroTitle;

  /// Hero card subtitle with count of nearby peers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 nearby} other{{count} nearby}}'**
  String nearbyHeroNearbyCount(int count);

  /// Hero card status when mesh is disabled.
  ///
  /// In en, this message translates to:
  /// **'Offline Chat Off'**
  String get nearbyHeroOff;

  /// Hero card explanation of offline peer-to-peer mesh.
  ///
  /// In en, this message translates to:
  /// **'Scanning for devices within 100 meters. Connections are encrypted and peer-to-peer.'**
  String get nearbyHeroDesc;

  /// Hint in display name editor.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get nearbyYourNameHint;

  /// Empty state title when scanning.
  ///
  /// In en, this message translates to:
  /// **'Searching for devices nearby…'**
  String get nearbyEmptySearching;

  /// Empty state title when offline chat is off.
  ///
  /// In en, this message translates to:
  /// **'Offline Chat is Off'**
  String get nearbyEmptyOff;

  /// Empty state guidance when searching.
  ///
  /// In en, this message translates to:
  /// **'Ensure GupShupGo is open on nearby devices with Bluetooth active.'**
  String get nearbyEmptySearchingDesc;

  /// Empty state guidance when mesh is off.
  ///
  /// In en, this message translates to:
  /// **'Tap the start icon top right to begin scanning.'**
  String get nearbyEmptyOffDesc;

  /// Peer status when connected.
  ///
  /// In en, this message translates to:
  /// **'Connected · Tap to chat'**
  String get nearbyPeerConnected;

  /// Peer status while connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get nearbyPeerConnecting;

  /// Peer status when discovered but not connected.
  ///
  /// In en, this message translates to:
  /// **'Tap to connect'**
  String get nearbyPeerTapToConnect;

  /// Button to open chat with connected peer.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get nearbyActionChat;

  /// Disabled button while connection is in progress.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get nearbyActionConnecting;

  /// Button to connect to a discovered peer.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get nearbyActionConnect;

  /// Card title when Bluetooth permissions are denied.
  ///
  /// In en, this message translates to:
  /// **'Permissions Needed'**
  String get nearbyPermNeededTitle;

  /// Card description explaining Bluetooth permission requirement.
  ///
  /// In en, this message translates to:
  /// **'Offline chat requires nearby-device and Bluetooth access to discover devices without internet.'**
  String get nearbyPermNeededDesc;

  /// Button to retry mesh initialization.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get nearbyTryAgainBtn;

  /// Button opening device app settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get nearbySettingsBtn;

  /// Helpful tip card for nearby device discovery.
  ///
  /// In en, this message translates to:
  /// **'Don\'t see your friend? Ensure Bluetooth is enabled on both devices.'**
  String get nearbyHelpTip;

  /// AppBar title on anonymous lobby screen.
  ///
  /// In en, this message translates to:
  /// **'Anonymous Chat'**
  String get anonLobbyTitle;

  /// Hero status text while searching for a stranger.
  ///
  /// In en, this message translates to:
  /// **'Finding someone for you…'**
  String get anonLobbyFinding;

  /// Subtitle while matchmaking.
  ///
  /// In en, this message translates to:
  /// **'Hang tight — you\'ll be paired with a random stranger.'**
  String get anonLobbyHangTight;

  /// Button to cancel searching and exit lobby.
  ///
  /// In en, this message translates to:
  /// **'Cancel Search'**
  String get anonLobbyCancelBtn;

  /// Footer note on anonymity.
  ///
  /// In en, this message translates to:
  /// **'Your identity stays hidden. Chat as a stranger.'**
  String get anonLobbyPrivacyNote;

  /// Live online pill label before count loads.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get anonLobbyConnecting;

  /// Live online pill label when 0 users online.
  ///
  /// In en, this message translates to:
  /// **'Waiting for others to come online…'**
  String get anonLobbyWaitingOthers;

  /// Live online pill label showing active count.
  ///
  /// In en, this message translates to:
  /// **'{count} online now'**
  String anonLobbyOnlineCount(int count);

  /// Top banner noting messages are unencrypted.
  ///
  /// In en, this message translates to:
  /// **'Messages are not end-to-end encrypted'**
  String get anonChatNotEncrypted;

  /// Tooltip on friend request icon after sending.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get anonChatRequestSentTooltip;

  /// Tooltip on friend request icon.
  ///
  /// In en, this message translates to:
  /// **'Add friend'**
  String get anonChatAddFriendTooltip;

  /// Tooltip on next stranger button.
  ///
  /// In en, this message translates to:
  /// **'Next stranger'**
  String get anonChatNextStrangerTooltip;

  /// Tooltip on report button.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get anonChatReportTooltip;

  /// Empty chat placeholder message.
  ///
  /// In en, this message translates to:
  /// **'Say hi to the stranger! 👋'**
  String get anonChatSayHi;

  /// Banner when friend request accepted, moving to E2EE chat.
  ///
  /// In en, this message translates to:
  /// **'You are now friends! Opening secure chat…'**
  String get anonChatFriendsTransition;

  /// Banner when stranger left the room.
  ///
  /// In en, this message translates to:
  /// **'Stranger has disconnected 👋'**
  String get anonChatStrangerDisconnected;

  /// Button to search for the next stranger.
  ///
  /// In en, this message translates to:
  /// **'Find Next Stranger'**
  String get anonChatFindNextBtn;

  /// Banner title when stranger sent a friend request.
  ///
  /// In en, this message translates to:
  /// **'Stranger wants to connect!'**
  String get anonChatFriendReqTitle;

  /// Banner description explaining consequence of friend request.
  ///
  /// In en, this message translates to:
  /// **'Accepting reveals your real profile and starts an encrypted chat.'**
  String get anonChatFriendReqDesc;

  /// Button to decline stranger's friend request.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get anonChatDecline;

  /// Button to accept stranger's friend request.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get anonChatAccept;

  /// Banner title while waiting for friend request response.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent'**
  String get anonChatWaitingReqTitle;

  /// Banner subtitle while waiting for friend request response.
  ///
  /// In en, this message translates to:
  /// **'Waiting for stranger to respond…'**
  String get anonChatWaitingReqDesc;

  /// Dialog title for reporting a stranger.
  ///
  /// In en, this message translates to:
  /// **'Report Stranger'**
  String get anonChatReportTitle;

  /// Question in stranger reporting dialog.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this user?'**
  String get anonChatReportQuestion;

  /// Report reason: inappropriate content.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get anonChatReportReasonInappropriate;

  /// Report reason: harassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment or bullying'**
  String get anonChatReportReasonHarassment;

  /// Report reason: spam or scam.
  ///
  /// In en, this message translates to:
  /// **'Spam or scam'**
  String get anonChatReportReasonSpam;

  /// Report reason: threatening behaviour.
  ///
  /// In en, this message translates to:
  /// **'Threatening behaviour'**
  String get anonChatReportReasonThreatening;

  /// Report reason: other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get anonChatReportReasonOther;

  /// Cancel button in report dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get anonChatReportCancel;

  /// Submit button in report dialog.
  ///
  /// In en, this message translates to:
  /// **'Report & Leave'**
  String get anonChatReportSubmit;

  /// Snackbar shown after submitting report.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thank you for keeping GupShupGo safe.'**
  String get anonChatReportSubmitted;

  /// Dialog title when opening a view-once video.
  ///
  /// In en, this message translates to:
  /// **'Play once?'**
  String get anonChatViewOnceVideoTitle;

  /// Dialog title when opening a view-once photo.
  ///
  /// In en, this message translates to:
  /// **'Open once?'**
  String get anonChatViewOncePhotoTitle;

  /// Dialog explanation when opening a view-once video.
  ///
  /// In en, this message translates to:
  /// **'You can only open this video one time. Once you close it, it\'s gone.'**
  String get anonChatViewOnceVideoDesc;

  /// Dialog explanation when opening a view-once photo.
  ///
  /// In en, this message translates to:
  /// **'You can only open this photo one time. Once you close it, it\'s gone.'**
  String get anonChatViewOncePhotoDesc;

  /// Cancel button in view-once confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get anonChatViewOnceCancel;

  /// Open button in view-once confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get anonChatViewOnceOpen;

  /// Title on retired build block screen.
  ///
  /// In en, this message translates to:
  /// **'Update GupShupGo'**
  String get unsupportedVersionTitle;

  /// Body text on retired build block screen.
  ///
  /// In en, this message translates to:
  /// **'This version of GupShupGo is no longer supported. Update to the latest version to keep chatting — your messages and chats are safe and will be there when you come back.'**
  String get unsupportedVersionDesc;

  /// Primary button to trigger immediate update.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get unsupportedVersionUpdateNow;

  /// Fallback button to open Google Play Store.
  ///
  /// In en, this message translates to:
  /// **'Open Play Store'**
  String get unsupportedVersionOpenPlayStore;

  /// Error title when username handle is not found.
  ///
  /// In en, this message translates to:
  /// **'@{username} not found'**
  String publicProfileNotFound(String username);

  /// Generic error title when user is not found.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get publicProfileUserNotFound;

  /// Explanation when profile link is broken.
  ///
  /// In en, this message translates to:
  /// **'This handle doesn\'t exist or the link is broken.'**
  String get publicProfileNotFoundDesc;

  /// AppBar title on public profile screen.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get publicProfileTitle;

  /// Online status indicator.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get publicProfileOnline;

  /// Last seen indicator.
  ///
  /// In en, this message translates to:
  /// **'Last seen {time}'**
  String publicProfileLastSeen(String time);

  /// Relative time: just now.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get publicProfileJustNow;

  /// Relative time in minutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String publicProfileMinutesAgo(int minutes);

  /// Relative time in hours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String publicProfileHoursAgo(int hours);

  /// Relative time in days.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String publicProfileDaysAgo(int days);

  /// User join date format.
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String publicProfileJoined(String date);

  /// Notice when viewing one's own public profile link.
  ///
  /// In en, this message translates to:
  /// **'This is your own profile link.'**
  String get publicProfileOwnLink;

  /// User Gup points display.
  ///
  /// In en, this message translates to:
  /// **'{points} Gup Points'**
  String publicProfileGupPoints(int points);

  /// User gamification level.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String publicProfileLevel(int level);

  /// Label for Points mini stat.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get publicProfileStatPoints;

  /// Label for Badges mini stat.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get publicProfileStatBadges;

  /// Label for Best Bond mini stat.
  ///
  /// In en, this message translates to:
  /// **'Best Bond'**
  String get publicProfileStatBestBond;

  /// Section header for earned badges.
  ///
  /// In en, this message translates to:
  /// **'BADGES'**
  String get publicProfileBadges;

  /// AppBar title for QR code scanner.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get qrScannerTitle;

  /// Tooltip to turn on flash.
  ///
  /// In en, this message translates to:
  /// **'Turn on flash'**
  String get qrScannerFlashOnTooltip;

  /// Tooltip to turn off flash.
  ///
  /// In en, this message translates to:
  /// **'Turn off flash'**
  String get qrScannerFlashOffTooltip;

  /// Camera viewfinder prompt.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at a GupShupGo profile QR code'**
  String get qrScannerPrompt;

  /// Error banner when scanned QR is not a GupShupGo profile.
  ///
  /// In en, this message translates to:
  /// **'That\'s not a GupShupGo profile code.'**
  String get qrScannerNotProfileCode;

  /// Error title when camera fails to start.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the camera.'**
  String get qrScannerCameraErrorTitle;

  /// Error subtitle prompting retry.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get qrScannerCameraErrorRetry;

  /// Message explaining camera permission requirement.
  ///
  /// In en, this message translates to:
  /// **'Camera access is needed to scan QR codes.'**
  String get qrScannerPermissionMsg;

  /// Button to request camera permission.
  ///
  /// In en, this message translates to:
  /// **'Allow camera'**
  String get qrScannerPermissionAllow;

  /// Message when camera permission is permanently blocked.
  ///
  /// In en, this message translates to:
  /// **'Camera access is blocked. Enable it in Settings to scan QR codes.'**
  String get qrScannerBlockedMsg;

  /// Button to open app settings for camera permission.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get qrScannerBlockedSettings;

  /// Screen header for incoming screen share request.
  ///
  /// In en, this message translates to:
  /// **'Incoming Screen Share'**
  String get screenShareIncomingTitle;

  /// Subtitle under caller name in incoming screen share.
  ///
  /// In en, this message translates to:
  /// **'wants to share their screen'**
  String get screenShareWantsToShare;

  /// Button to reject incoming screen share.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get screenShareReject;

  /// Button to accept incoming screen share.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get screenShareAccept;

  /// Snackbar when accepting screen share fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t accept the screen share — check your connection and try again.'**
  String get screenShareCantAccept;

  /// Snackbar when screen share was declined.
  ///
  /// In en, this message translates to:
  /// **'{name} declined your screen share'**
  String screenShareDeclined(String name);

  /// Snackbar when screen share request timed out without answer.
  ///
  /// In en, this message translates to:
  /// **'No answer'**
  String get screenShareNoAnswer;

  /// Snackbar when starting screen share failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start screen sharing'**
  String get screenShareStartError;

  /// Sharer view status when awaiting acceptance.
  ///
  /// In en, this message translates to:
  /// **'Requesting Permission'**
  String get screenShareStatusRequesting;

  /// Sharer view status while connecting.
  ///
  /// In en, this message translates to:
  /// **'Initializing Broadcast'**
  String get screenShareStatusInitializing;

  /// Sharer view status while waiting for viewer.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Participant'**
  String get screenShareStatusWaitingParticipant;

  /// Sharer view status when live.
  ///
  /// In en, this message translates to:
  /// **'Screen Sharing Active'**
  String get screenShareStatusActive;

  /// Sharer view subtitle while waiting for acceptance.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to accept…'**
  String screenShareSubWaitingAccept(String name);

  /// Sharer view subtitle while initializing stream.
  ///
  /// In en, this message translates to:
  /// **'Establishing encrypted stream...'**
  String get screenShareSubEstablishing;

  /// Sharer view subtitle while waiting for peer to join.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to join...'**
  String screenShareSubWaitingJoin(String name);

  /// Sharer view subtitle when streaming.
  ///
  /// In en, this message translates to:
  /// **'Your entire screen is visible in high definition.'**
  String get screenShareSubActive;

  /// Badge pill when requesting.
  ///
  /// In en, this message translates to:
  /// **'REQUESTING'**
  String get screenShareBadgeRequesting;

  /// Badge pill when connecting.
  ///
  /// In en, this message translates to:
  /// **'CONNECTING'**
  String get screenShareBadgeConnecting;

  /// Label prefix before participant name.
  ///
  /// In en, this message translates to:
  /// **'Shared with '**
  String get screenShareSharedWith;

  /// Label prefix when requesting from participant.
  ///
  /// In en, this message translates to:
  /// **'Requesting '**
  String get screenShareRequestingFrom;

  /// Helpful tip for minimizing screen share.
  ///
  /// In en, this message translates to:
  /// **'You can minimize this screen to keep using GupShupGo.'**
  String get screenShareMinimizeTip;

  /// Button to stop screen sharing.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing'**
  String get screenShareStop;

  /// Button to cancel pending screen share request.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get screenShareCancelRequest;

  /// Header in viewer screen showing who is sharing.
  ///
  /// In en, this message translates to:
  /// **'{name} is sharing'**
  String screenShareViewerTitle(String name);

  /// Badge in viewer screen indicating live stream.
  ///
  /// In en, this message translates to:
  /// **'LIVE STREAM'**
  String get screenShareViewerLive;

  /// Button in viewer screen to minimize.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get screenShareViewerMinimize;

  /// Button in viewer screen to leave stream.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get screenShareViewerLeave;

  /// Placeholder text while waiting for peer's video feed.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to stream screen...'**
  String screenShareViewerWaitingStream(String name);

  /// Placeholder text while connecting to stream.
  ///
  /// In en, this message translates to:
  /// **'Connecting to encrypted stream...'**
  String get screenShareViewerConnecting;

  /// AppBar title for view-once video.
  ///
  /// In en, this message translates to:
  /// **'Video · View once'**
  String get viewOnceVideoTitle;

  /// AppBar title for view-once photo.
  ///
  /// In en, this message translates to:
  /// **'Photo · View once'**
  String get viewOncePhotoTitle;

  /// Error message when media fails to open.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this media.'**
  String get viewOnceCantOpen;

  /// Error message when view-once media key is consumed or missing.
  ///
  /// In en, this message translates to:
  /// **'This media is no longer available.'**
  String get viewOnceUnavailable;

  /// Footer note on Android where screenshots are blocked.
  ///
  /// In en, this message translates to:
  /// **'Screenshots are blocked. You can\'t open this again.'**
  String get viewOnceBlockedFooter;

  /// Footer note on iOS where screenshots cannot be blocked.
  ///
  /// In en, this message translates to:
  /// **'You can\'t open this again. Screenshots can\'t be blocked on iOS.'**
  String get viewOnceUnblockedFooter;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'bn',
        'de',
        'en',
        'es',
        'fr',
        'hi',
        'id',
        'ja',
        'pt',
        'ru',
        'ta',
        'te',
        'tr',
        'ur',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'ja':
      return AppLocalizationsJa();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'tr':
      return AppLocalizationsTr();
    case 'ur':
      return AppLocalizationsUr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
