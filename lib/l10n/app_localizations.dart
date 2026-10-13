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
  /// **'Gup'**
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
