import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:video_chat_app/screens/call_readiness_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/widgets/e2ee_banner.dart';
import 'package:video_chat_app/widgets/anonymous_chat_icon.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/l10n/app_localizations.dart';
import 'package:video_chat_app/l10n/app_locales.dart';
import 'package:video_chat_app/provider/chat_theme_provider.dart';
import 'package:video_chat_app/provider/locale_provider.dart';
import 'package:video_chat_app/provider/theme_provider.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/widgets/chat_theme_sheet.dart';
import 'package:video_chat_app/widgets/new_feature_badge.dart';
import 'package:video_chat_app/widgets/report_problem_dialog.dart';
import 'package:video_chat_app/widgets/whats_new_dialog.dart'
    show kCurrentVersion, showWhatsNewDialog;
import 'package:video_chat_app/screens/auth/link_accounts_screen.dart';
import 'package:video_chat_app/screens/auth/login_screen.dart';
import 'package:video_chat_app/screens/language_picker_screen.dart';
import 'package:video_chat_app/screens/profile_screen.dart';
import 'package:video_chat_app/screens/vault_settings_screen.dart';
import 'package:video_chat_app/services/ads/ad_consent_service.dart';
import 'package:video_chat_app/services/auth_service.dart';
import 'package:video_chat_app/services/crypto/safety_number_service.dart';
import 'package:video_chat_app/services/review_prompt_service.dart';
import 'package:video_chat_app/services/settings_service.dart';
import 'package:video_chat_app/services/update_service.dart';
import 'package:video_chat_app/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_chat_app/services/notification_service.dart';
import 'package:video_chat_app/services/fcm_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_chat_app/provider/subscription_provider.dart';
import 'package:video_chat_app/screens/premium_screen.dart';
import 'package:video_chat_app/widgets/premium_badge.dart';
import 'package:video_chat_app/widgets/premium_gate.dart';
import 'package:video_chat_app/utils/avatar_image.dart';
import 'package:video_chat_app/utils/haptics.dart';
import 'package:video_chat_app/utils/url_opener.dart';
import 'package:video_chat_app/widgets/common/loading_overlay.dart';
import 'package:video_chat_app/widgets/update_dialogs.dart';

/// WhatsApp-style settings screen.
class SettingsScreen extends StatefulWidget {
  final UserModel currentUser;

  const SettingsScreen({super.key, required this.currentUser});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final SettingsService _settings = SettingsService();
  final UserService _userService = UserService();
  late UserModel _user;
  Map<String, bool> _notifPrefs = {};

  /// Whether the OS currently permits notifications. Drives the Notifications
  /// settings row's On/Off status; refreshed on open.
  bool _notificationsOn = false;

  @override
  void initState() {
    super.initState();
    _user = widget.currentUser;
    _loadNotifPrefs();
    _loadNotificationStatus();
  }

  Future<void> _loadNotifPrefs() async {
    final prefs = await NotificationService.instance.getPreferences();
    if (mounted) setState(() => _notifPrefs = prefs);
  }

  Future<void> _loadNotificationStatus() async {
    final on = await FCMService().hasNotificationPermission();
    if (mounted) setState(() => _notificationsOn = on);
  }

  /// Settings entry point to (re)enable notifications after the onboarding
  /// soft-ask was declined. If the OS permission can still be requested in-app
  /// this grants it; once the OS has hard-denied it, only system settings can
  /// change it, so we deep-link there.
  Future<void> _manageNotifications() async {
    final fcm = FCMService();
    if (!await fcm.hasNotificationPermission()) {
      // Try the in-app request first (works until the OS one-shot is spent).
      await fcm.setupFCM(userId: _user.id, requestPermissions: true);
    }
    final nowOn = await fcm.hasNotificationPermission();
    if (!mounted) return;
    setState(() => _notificationsOn = nowOn);
    final l10n = AppLocalizations.of(context);

    if (nowOn) {
      // Full-screen incoming-call access is a separate Android 14+ setting.
      // This explicit user action may retry even if Home already checked once.
      fcm.requestFullScreenIntentPermission(force: true);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(l10n.settingsNotificationsEnabledToast),
          behavior: SnackBarBehavior.floating,
        ));
      return;
    }

    // Still off → the OS has hard-denied; only system settings can change it.
    final c = AppThemeColors.of(context);
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.border, width: 1),
        ),
        title: Text(
          l10n.settingsEnableNotificationsTitle,
          style: GoogleFonts.poppins(
              color: c.textHigh, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: Text(
          l10n.settingsEnableNotificationsBody,
          style:
              GoogleFonts.poppins(color: c.textMid, fontSize: 13, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel,
                style: GoogleFonts.poppins(
                    color: c.textMid, fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: c.primary,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.settingsOpenSystemSettings,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (open == true) await openAppSettings();
  }

  Future<void> _setNotifPref(String key, bool value) async {
    await NotificationService.instance.setPreference(key, value);
    setState(() => _notifPrefs[key] = value);
  }

  /// Toggles profile discoverability. Applies the change optimistically, then
  /// reverts and tells the user if the write fails — a silently-failed privacy
  /// switch would leave them believing they are hidden when they are not.
  Future<void> _setDiscoverable(bool value) async {
    final previous = _user.isDiscoverable;
    setState(() => _user = _user.copyWith(isDiscoverable: value));

    try {
      await _userService.updateDiscoverableStatus(_user.id, value);
    } catch (_) {
      if (!mounted) return;
      setState(() => _user = _user.copyWith(isDiscoverable: previous));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Couldn't update discoverability. Check your connection and try again.",
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        ),
      );
    }
  }

  /// Reopens Google's privacy options form so the user can change or withdraw
  /// ad consent. The form is UMP's, not ours — it is the only UI allowed to
  /// record that choice, and it writes the result to the device itself, so there
  /// is nothing for this screen to save afterwards.
  Future<void> _openAdPreferences() async {
    final shown = await AdConsentService.instance.showPrivacyOptionsForm();
    if (!mounted) return;
    if (!shown) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Couldn't open ad preferences. Check your connection and try again.",
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        ),
      );
      return;
    }
    // The requirement status can flip once the choice is recorded, which decides
    // whether this row keeps existing.
    setState(() {});
  }

  bool _isSigningOut = false;

  Future<void> _signOut() async {
    if (_isSigningOut) return;
    final l10n = AppLocalizations.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.settingsLogOutConfirmTitle),
        content: Text(l10n.settingsLogOutConfirmPrompt),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  Text(l10n.settingsLogOut, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    AppHaptics.tap();
    setState(() => _isSigningOut = true);
    try {
      // Heavy multi-step teardown (Firestore listeners, presence, tokens) —
      // a blocking overlay so the confirm tap isn't a silent multi-second gap.
      // Navigation stays outside `during` (its finally pops the barrier).
      await LoadingOverlay.during(
        context,
        () => _authService.signOut(),
        message: l10n.settingsSigningOut,
      );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  // ── Clear all chats ──────────────────────────────────────────────────────
  Future<void> _clearAllChats() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.settingsClearChatsConfirmTitle),
        content: Text(l10n.settingsClearChatsConfirmPrompt),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.settingsDeleteAll,
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      // Show a loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsClearingChats)),
        );
      }

      final userId = _user.id;
      final firestore = FirebaseFirestore.instance;

      // Get all chat rooms the user is part of
      final chatRoomsSnapshot = await firestore
          .collection('chatRooms')
          .where('participants', arrayContains: userId)
          .get();

      final batch = firestore.batch();
      for (final chatDoc in chatRoomsSnapshot.docs) {
        // Set a per-user clearedAt timestamp — messages before this are hidden
        // for THIS user only (the other participant still sees everything).
        batch.update(chatDoc.reference, {
          'clearedAt.$userId': Timestamp.now(),
          'unreadCount.$userId': 0,
        });
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsAllChatsCleared),
            backgroundColor: AppThemeColors.of(context).success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsClearChatsFailed(e.toString())),
            backgroundColor: AppThemeColors.of(context).error,
          ),
        );
      }
    }
  }

  // ── Report a problem ─────────────────────────────────────────────────────
  // The form itself lives in ReportProblemDialog, because the home overflow
  // menu offers the same action and a second copy would drift.
  Future<void> _reportProblem() =>
      ReportProblemDialog.show(context, user: _user);

  // ── Help Center ──────────────────────────────────────────────────────────
  void _showHelpCenter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppThemeColors.of(context).textLow,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Help Center',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppThemeColors.of(context).textHigh),
                  ),
                  const SizedBox(height: 20),
                  _buildFAQItem(
                    'How do I start a new chat?',
                    'Tap the message icon (💬) at the bottom-right of the Gup tab, '
                        'or use the search icon in the top bar to find contacts.',
                  ),
                  _buildFAQItem(
                    'How do I make a voice or video call?',
                    'Open a chat with the person you want to call. '
                        'Tap the phone icon (🔊) for an audio call or the '
                        'camera icon (📹) for a video call in the top bar.',
                  ),
                  _buildFAQItem(
                    'How do I share a moment?',
                    'Go to the Moments tab and tap the pencil icon for a text moment '
                        'or the camera icon for a photo/video moment.',
                  ),
                  _buildFAQItem(
                    'How do I edit my profile?',
                    'Tap your profile picture in the top-right menu, then '
                        'tap your avatar to change your photo, or edit your '
                        'name and about section.',
                  ),
                  _buildFAQItem(
                    'How do I block someone?',
                    'Open a chat with the person, tap the ⋮ menu in the top-right, '
                        'and select "Block contact".',
                  ),
                  _buildFAQItem(
                    'Why am I not receiving notifications?',
                    'Check that notifications are enabled in Settings → Notifications. '
                        'Also ensure your phone\'s system notification settings '
                        'allow GupShupGo to send alerts.',
                  ),
                  _buildFAQItem(
                    'How do I mute a chat?',
                    'Open the chat, tap the ⋮ menu, and select "Mute notifications". '
                        'You\'ll still receive messages but won\'t get push notifications.',
                  ),
                  _buildFAQItem(
                    'How do I log out?',
                    'Go to Settings (gear icon in menu) and scroll to the bottom. '
                        'Tap "Log Out".',
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Still need help?',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppThemeColors.of(context).textHigh),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _reportProblem();
                    },
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Contact Support'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side:
                          BorderSide(color: AppThemeColors.of(context).primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    final c = AppThemeColors.of(context);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(question,
          style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14, color: c.textHigh)),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(answer, style: TextStyle(fontSize: 13, color: c.textMid)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final l10n = AppLocalizations.of(context);
    final avatarUrl = _user.photoUrl ??
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_user.name)}&background=7C5CFC&color=fff&size=128';

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.textHigh, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.settingsTitle,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: c.textHigh,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        children: [
          // ── Top User Profile Header (Stitch Design) ──────────────────────────
          GestureDetector(
            onTap: () async {
              final updated = await Navigator.push<UserModel>(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen(currentUser: _user)),
              );
              if (updated != null) setState(() => _user = updated);
            },
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundImage: avatarImage(avatarUrl, radius: 44),
                  backgroundColor: c.surfaceAlt,
                ),
                const SizedBox(height: 12),
                Text(
                  _user.name,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: c.textHigh,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (_user.about != null && _user.about!.isNotEmpty)
                      ? _user.about!
                      : 'Hey there! I am using GupShupGo.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: c.textMid,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── GupShupGo Pro subscription card ────────────────────────────────
          if (context.watch<SubscriptionProvider>().isProFeatureVisible) ...[
            _buildProCard(),
            const SizedBox(height: 16),
          ],

          // ── 1. Account Section Card (Full Width) ────────────────────────────
          _buildStitchCard(
            title: l10n.settingsAccountCard,
            children: [
              _buildStitchTile(
                icon: Icons.person_outline_rounded,
                title: l10n.settingsProfileTile,
                onTap: () async {
                  final updated = await Navigator.push<UserModel>(
                    context,
                    MaterialPageRoute(builder: (_) => ProfileScreen(currentUser: _user)),
                  );
                  if (updated != null) setState(() => _user = updated);
                },
              ),
              _buildStitchDivider(),
              _buildStitchTile(
                icon: Icons.link_rounded,
                title: l10n.settingsLinkedMethodsTile,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LinkAccountsScreen(user: _user)),
                ),
              ),
              _buildStitchDivider(),
              _buildStitchTile(
                icon: Icons.phone_outlined,
                title: l10n.settingsPhoneTile,
                trailingText: _user.phoneNumber ?? l10n.profileNotLinked,
              ),
              _buildStitchDivider(),
              _buildStitchTile(
                icon: Icons.email_outlined,
                title: l10n.settingsEmailTile,
                trailingText: _user.email ?? l10n.profileNotLinked,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 2. Privacy Card (Full Width) ────────────────────────────────────
          // Discoverability lives alongside last seen / read receipts so there
          // is a single place in Settings that answers "who can see what".
          _buildStitchCard(
            title: l10n.settingsPrivacyCard,
            children: [
              _buildStitchSwitchRow(
                icon: Icons.person_search_rounded,
                title: l10n.settingsDiscoverability,
                value: _user.isDiscoverable,
                onChanged: _setDiscoverable,
              ),
              const SizedBox(height: 10),
              _buildStitchSwitchRow(
                icon: Icons.access_time_rounded,
                title: l10n.settingsLastSeen,
                value: _settings.showLastSeen,
                onChanged: (v) => setState(() => _settings.showLastSeen = v),
              ),
              const SizedBox(height: 10),
              _buildStitchSwitchRow(
                icon: Icons.check_circle_outline_rounded,
                title: l10n.settingsReadReceipts,
                value: _settings.showReadReceipts,
                onChanged: (v) => setState(() => _settings.showReadReceipts = v),
              ),
              // UMP requires a permanent way to revisit an ad-consent choice
              // wherever privacy options apply — so this is a legal obligation in
              // the EEA/UK, not a convenience. Hidden elsewhere, because UMP
              // reports no privacy options and the form would be empty.
              if (AdConsentService.instance.privacyOptionsRequired) ...[
                _buildStitchDivider(),
                _buildStitchTile(
                  icon: Icons.ads_click_rounded,
                  title: l10n.settingsAdPreferences,
                  trailingText: l10n.settingsManage,
                  onTap: _openAdPreferences,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // ── 3. Appearance Card (Full Width) ─────────────────────────────────
          _buildStitchCard(
            title: l10n.settingsAppearanceCard,
            newAnchor: NewFeatureAnchor.settingsAppearance,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildStitchCompactTile(
                      icon: Icons.dark_mode_outlined,
                      title: l10n.settingsTheme,
                      subtitle: context.watch<ThemeProvider>().themeMode == ThemeMode.dark
                          ? l10n.settingsThemeDark
                          : context.watch<ThemeProvider>().themeMode == ThemeMode.light
                              ? l10n.settingsThemeLight
                              : l10n.settingsThemeSystem,
                      onTap: _showThemeModal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStitchCompactTile(
                      icon: Icons.g_translate_rounded,
                      title: 'App Language',
                      subtitle: context.watch<LocaleProvider>().isSystem
                          ? AppLocalizations.of(context).languageSystemDefault
                          : languageNativeName(context
                              .watch<LocaleProvider>()
                              .locale!
                              .languageCode),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const LanguagePickerScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _buildStitchDivider(),
              // Global default chat theme. Opens the same sheet the chat
              // overflow menu does, in default mode (`chatRoomId: null`) — a
              // per-chat pick made from inside a conversation still wins over
              // whatever is set here.
              _buildStitchTile(
                icon: Icons.palette_outlined,
                title: l10n.settingsChatTheme,
                badge: const NewFeatureChip(featureId: NewFeature.chatThemes),
                trailingText: context
                    .watch<ChatThemeProvider>()
                    .resolve(
                      null,
                      unlocked:
                          context.watch<SubscriptionProvider>().isProUnlocked,
                    )
                    .name,
                onTap: () {
                  WhatsNewService.instance.markSeen(NewFeature.chatThemes);
                  ChatThemeSheet.show(context);
                },
              ),
              _buildStitchDivider(),
              ListTileTheme.merge(
                minLeadingWidth: 0,
                horizontalTitleGap: 8,
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  secondary: AnonymousChatIcon(color: c.textMid, size: 18),
                  title: Text(
                    l10n.anonRestoreBanner,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: c.textHigh,
                    ),
                  ),
                  activeTrackColor: c.primary,
                  value: _settings.showAnonymousChatBanner,
                  onChanged: (value) =>
                      setState(() => _settings.showAnonymousChatBanner = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 4. Help & Security Card (Full Width) ────────────────────────────
          _buildStitchCard(
            title: l10n.settingsHelpSecurityCard,
            children: [
              _buildStitchTile(
                icon: Icons.help_outline_rounded,
                title: l10n.settingsHelpCenter,
                onTap: _showHelpCenter,
              ),
              _buildStitchDivider(),
              _buildStitchTile(
                icon: Icons.bug_report_outlined,
                title: l10n.settingsReportProblem,
                onTap: _reportProblem,
              ),
              _buildStitchDivider(),
              _buildStitchTile(
                icon: Icons.notifications_active_outlined,
                title: l10n.settingsNotificationsTile,
                trailingText: _notificationsOn
                    ? l10n.settingsNotificationsStatusOn
                    : l10n.settingsNotificationsStatusOff,
                onTap: _manageNotifications,
              ),
              if (Platform.isAndroid) ...[
                _buildStitchDivider(),
                _buildStitchTile(
                  icon: Icons.phone_in_talk_outlined,
                  title: CallReadinessScreen.title,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const CallReadinessScreen(),
                  )),
                ),
              ],
              _buildStitchDivider(),
              _buildStitchTile(
                icon: Icons.shield_outlined,
                title: l10n.settingsE2EEShield,
                onTap: _openVaultSettings,
              ),
              _buildStitchDivider(),
              _buildStitchTile(
                icon: Icons.verified_user_outlined,
                title: l10n.settingsVerifySafetyNumber,
                onTap: _verifySafetyNumber,
              ),
              _buildStitchDivider(),
              _buildStitchTile(
                icon: Icons.block_outlined,
                title: l10n.settingsBlockedContacts,
                onTap: _showBlockedContacts,
              ),
              _buildStitchDivider(),
              _buildStitchTile(
                icon: Icons.delete_sweep_outlined,
                title: l10n.settingsClearAllGupHistory,
                onTap: _clearAllChats,
              ),
              _buildStitchDivider(),
              _buildStitchTile(
                icon: Icons.star_rate_rounded,
                title: l10n.settingsRateUs,
                onTap: () => ReviewPromptService.instance
                    .openStoreListing(context: context),
              ),
              _buildStitchDivider(),
              _buildStitchTile(
                icon: Icons.auto_awesome_rounded,
                title: l10n.settingsWhatsNew,
                onTap: () => showWhatsNewDialog(context),
              ),
              _buildStitchDivider(),
              _buildStitchTile(
                icon: Icons.system_update_rounded,
                title: l10n.settingsCheckForUpdates,
                onTap: _checkForUpdates,
              ),
              _buildStitchDivider(),
              _buildStitchTile(
                icon: Icons.info_outline_rounded,
                title: l10n.settingsAppInfo,
                // From the changelog's constant, so the number here cannot drift
                // away from the version the What's New dialog announces.
                trailingText: 'v$kCurrentVersion',
                onTap: _showAboutDialog,
              ),
              _buildStitchDivider(),
              _buildStitchTile(
                icon: Icons.privacy_tip_outlined,
                title: l10n.settingsPrivacyPolicy,
                onTap: () =>
                    openExternalUrl(context, 'https://www.gupshupgo.app/privacy'),
              ),
              _buildStitchDivider(),
              _buildStitchTile(
                icon: Icons.description_outlined,
                title: l10n.settingsTerms,
                onTap: () =>
                    openExternalUrl(context, 'https://www.gupshupgo.app/terms'),
              ),
              _buildStitchDivider(),
              _buildStitchTile(
                icon: Icons.no_accounts_outlined,
                title: l10n.settingsDeleteAccount,
                onTap: () => openExternalUrl(
                    context, 'https://www.gupshupgo.app/delete-account'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Log Out Button (Stitch Design) ──────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _signOut,
              style: OutlinedButton.styleFrom(
                backgroundColor: c.isDark ? const Color(0xFF121422) : c.surfaceAlt,
                side: BorderSide(
                  color: c.error.withOpacity(0.7),
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l10n.settingsLogOut,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.error,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Stitch Custom Card & Tile Builders ─────────────────────────────────────
  Widget _buildStitchCard({
    required String title,
    required List<Widget> children,
    EdgeInsetsGeometry? padding,
    String? newAnchor,
  }) {
    final c = AppThemeColors.of(context);
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A dot on the heading, so a new control inside a card that sits below
          // the fold still announces itself while the user is scrolling past.
          if (newAnchor != null)
            NewFeatureDot(
              anchor: newAnchor,
              offset: NewFeatureDot.besideText,
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.textHigh,
                ),
              ),
            )
          else
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.textHigh,
              ),
            ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStitchTile({
    required IconData icon,
    required String title,
    String? trailingText,
    VoidCallback? onTap,
    bool compact = false,
    Widget? badge,
  }) {
    final c = AppThemeColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: c.textMid, size: 22),
            const SizedBox(width: 12),
            // The title and its badge share one Expanded slot so tiles without a
            // badge lay out exactly as they did before, and a badge never steals
            // width from the trailing value.
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: compact ? 13.5 : 15,
                        fontWeight: FontWeight.w500,
                        color: c.textHigh,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (badge != null) badge,
                ],
              ),
            ),
            if (trailingText != null) ...[
              const SizedBox(width: 8),
              Text(
                trailingText,
                style: GoogleFonts.poppins(
                  fontSize: compact ? 12 : 13,
                  color: c.textMid,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 6),
            ],
            Icon(Icons.chevron_right_rounded, color: c.textMid, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildStitchCompactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final c = AppThemeColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(icon, color: c.textMid, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.textHigh,
                    ),
                    maxLines: 1,
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: c.textMid,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.textMid, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStitchSwitchRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final c = AppThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: c.textMid, size: 15),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: c.textHigh,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onChanged(!value),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 16,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: value ? c.primary : c.border,
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStitchDivider() {
    final c = AppThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Divider(color: c.border.withOpacity(0.5), height: 1),
    );
  }

  void _showThemeModal() {
    final c = AppThemeColors.of(context);
    final l10n = AppLocalizations.of(context);
    final themeProvider = context.read<ThemeProvider>();
    final currentMode = themeProvider.themeMode;

    final options = [
      (ThemeMode.light, Icons.light_mode_outlined, l10n.settingsThemeLight),
      (ThemeMode.dark, Icons.dark_mode_outlined, l10n.settingsThemeDark),
      (ThemeMode.system, Icons.brightness_auto_outlined, l10n.settingsThemeSystem),
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: c.textLow,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l10n.settingsChooseThemeTitle,
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w700, color: c.textHigh)),
                  ),
                ),
                const SizedBox(height: 8),
                ...options.map((opt) {
                  final (mode, icon, label) = opt;
                  final selected = currentMode == mode;
                  return ListTile(
                    leading: Icon(icon, color: selected ? c.primary : c.textMid),
                    title: Text(label,
                        style: GoogleFonts.poppins(
                            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                            color: c.textHigh)),
                    trailing: selected
                        ? Icon(Icons.check_rounded, color: c.primary)
                        : null,
                    onTap: () {
                      context.read<ThemeProvider>().setThemeMode(mode);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── GupShupGo Pro card ────────────────────────────────────────────────────
  Widget _buildProCard() {
    final c = AppThemeColors.of(context);
    final l10n = AppLocalizations.of(context);
    final sub = context.watch<SubscriptionProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PremiumScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: sub.isPro
                  ? [
                      const Color(0xFFFFD700).withOpacity(0.12),
                      const Color(0xFFFFA500).withOpacity(0.06),
                    ]
                  : [
                      c.primary.withOpacity(0.08),
                      c.primary.withOpacity(0.03),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: sub.isPro
                  ? const Color(0xFFFFD700).withOpacity(0.3)
                  : c.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: sub.isPro
                        ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                        : [c.primary, c.primary.withOpacity(0.7)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'GupShupGo Pro',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: c.textHigh,
                          ),
                        ),
                        if (sub.isPro) ...[
                          const SizedBox(width: 8),
                          const PremiumBadge(size: PremiumBadgeSize.small),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub.isPro
                          ? l10n.settingsProDaysLeft(sub.subscription.planLabel, sub.subscription.daysRemaining)
                          : l10n.settingsUnlockPremiumFeatures,
                      style: TextStyle(
                        fontSize: 12,
                        color: c.textMid,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                sub.isPro ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
                color: sub.isPro
                    ? const Color(0xFFFFD700)
                    : c.textLow,
                size: sub.isPro ? 24 : 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openVaultSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VaultSettingsScreen(uid: widget.currentUser.id),
      ),
    );
  }

  Future<void> _verifySafetyNumber() async {
    final c = AppThemeColors.of(context);
    final selfUid = widget.currentUser.id;

    // Show a bottom-sheet contact picker populated from existing chats.
    final peerUser = await showModalBottomSheet<UserModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SafetyNumberContactPicker(selfUid: selfUid),
    );

    if (peerUser == null || !mounted) return;

    final l10n = AppLocalizations.of(context);
    // Compute behind a blocking overlay; `during` tears it down in a finally,
    // so a failure can't leave the spinner stuck on screen.
    final n = await LoadingOverlay.during(
      context,
      () => SafetyNumberService().safetyNumberFor(
        selfUserId: selfUid,
        peerUserId: peerUser.id,
      ),
      message: l10n.settingsComputingSafetyNumber,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: avatarImage(
                peerUser.photoUrl ??
                    'https://ui-avatars.com/api/?name=${Uri.encodeComponent(peerUser.name)}&background=4CAF50&color=fff&size=128',
                radius: 18,
              ),
              backgroundColor: c.surfaceAlt,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                peerUser.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: n == null
            ? Text(l10n.settingsSafetyNumberNoBundle)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsSafetyNumberExplanation(peerUser.name),
                    style: TextStyle(fontSize: 13, color: c.textMid),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      n,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        height: 1.8,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: c.textLow),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.settingsSafetyNumberCompareHint,
                          style: TextStyle(fontSize: 11, color: c.textLow),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ── Blocked contacts dialog ────────────────────────────────────────────
  void _showBlockedContacts() async {
    final l10n = AppLocalizations.of(context);
    final blockedIds = await _getBlockedUserIds();

    if (!mounted) return;

    if (blockedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsNoBlockedContacts)),
      );
      return;
    }

    // Fetch user details for blocked IDs
    final firestore = FirebaseFirestore.instance;
    final List<UserModel> blockedUsers = [];
    for (final id in blockedIds) {
      final doc = await firestore.collection('users').doc(id).get();
      if (doc.exists) {
        blockedUsers.add(UserModel.fromFirestore(doc));
      }
    }

    if (!mounted) return;

    final c = AppThemeColors.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: c.textLow,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(l10n.settingsBlockedContacts,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: c.textHigh)),
              const SizedBox(height: 12),
              if (blockedUsers.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(l10n.settingsNoBlockedContacts,
                        style: TextStyle(color: c.textMid)),
                  ),
                )
              else
                ...blockedUsers.map((user) => ListTile(
                      leading: CircleAvatar(
                        backgroundImage: avatarImage(
                            user.photoUrl ??
                                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}&background=4CAF50&color=fff&size=128',
                            radius: 20),
                        backgroundColor: c.surfaceAlt,
                      ),
                      title: Text(user.name),
                      trailing: TextButton(
                        onPressed: () async {
                          await _unblockUser(user.id);
                          Navigator.pop(context);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.settingsUserUnblocked(user.name))),
                            );
                          }
                        },
                        child:
                            Text(l10n.settingsUnblock, style: TextStyle(color: c.primary)),
                      ),
                    )),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<String>> _getBlockedUserIds() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user.id)
        .get();
    if (!doc.exists) return [];
    final data = doc.data();
    if (data == null) return [];
    return List<String>.from(data['blockedUsers'] ?? []);
  }

  Future<void> _unblockUser(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(_user.id).update({
      'blockedUsers': FieldValue.arrayRemove([userId]),
    });
  }

  // ── Check for updates ──────────────────────────────────────────────────
  Future<void> _checkForUpdates() async {
    AppHaptics.tap();
    final l10n = AppLocalizations.of(context);

    // The check itself is quick (not the download), so a blocking spinner is
    // fine here; the flexible download runs in the background afterwards.
    final result = await LoadingOverlay.during(
      context,
      () => UpdateService.instance.checkForUpdate(),
      message: l10n.settingsCheckingForUpdates,
    );

    if (!mounted) return;
    final c = AppThemeColors.of(context);

    switch (result.status) {
      case UpdateCheckStatus.updateAvailable:
        await showUpdateAvailableDialog(
          context,
          flexibleAllowed: result.flexibleAllowed,
        );
        break;

      case UpdateCheckStatus.readyToInstall:
        await showUpdateReadyDialog(context);
        break;

      case UpdateCheckStatus.upToDate:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsUpToDate(kCurrentVersion)),
            backgroundColor: c.success,
          ),
        );
        break;

      case UpdateCheckStatus.unavailable:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsUpdateCheckUnavailable),
          ),
        );
        break;
    }
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'GupShupGo',
      applicationVersion: kCurrentVersion,
      applicationLegalese: '© 2026 GupShupGo',
    );
  }
}

// ── Contact picker for safety number verification ─────────────────────────
/// A bottom-sheet widget that lists the user's recent chat contacts so they
/// can tap one to verify their safety number — no Firebase UID needed.
class _SafetyNumberContactPicker extends StatefulWidget {
  final String selfUid;
  const _SafetyNumberContactPicker({required this.selfUid});

  @override
  State<_SafetyNumberContactPicker> createState() =>
      _SafetyNumberContactPickerState();
}

class _SafetyNumberContactPickerState
    extends State<_SafetyNumberContactPicker> {
  List<UserModel> _contacts = [];
  List<UserModel> _filtered = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Fetch all chatRooms the current user participates in.
      final snap = await firestore
          .collection('chatRooms')
          .where('participants', arrayContains: widget.selfUid)
          .get();

      // Collect unique peer UIDs.
      final peerUids = <String>{};
      for (final doc in snap.docs) {
        final parts = List<String>.from(doc.data()['participants'] ?? []);
        for (final uid in parts) {
          if (uid != widget.selfUid) peerUids.add(uid);
        }
      }

      // Resolve each peer UID into a UserModel.
      final users = <UserModel>[];
      for (final uid in peerUids) {
        final userDoc = await firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          users.add(UserModel.fromFirestore(userDoc));
        }
      }

      // Sort alphabetically.
      users
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (mounted) {
        setState(() {
          _contacts = users;
          _filtered = users;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _contacts
          : _contacts.where((u) => u.name.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.85,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Column(
          children: [
            // ── Handle + title ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: c.textLow,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.verified_user, color: c.primary, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizations.of(context).settingsVerifyContactTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: c.textHigh,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context).settingsVerifyContactSubtitle,
                    style: TextStyle(fontSize: 13, color: c.textMid),
                  ),
                  const SizedBox(height: 14),
                  // ── Search bar ────────────────────────────────────────
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearch,
                    decoration: InputDecoration(
                      hintText: 'Search contacts...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: c.surfaceAlt,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // ── Contact list ──────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              _contacts.isEmpty
                                  ? 'No contacts yet.\nStart a chat first!'
                                  : 'No matching contacts.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: c.textMid),
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            indent: 72,
                            color: c.textLow.withOpacity(0.2),
                          ),
                          itemBuilder: (_, i) {
                            final user = _filtered[i];
                            final avatar = user.photoUrl ??
                                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.name)}&background=4CAF50&color=fff&size=128';
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    avatarImage(avatar, radius: 20),
                                backgroundColor: c.surfaceAlt,
                              ),
                              title: Text(
                                user.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: c.textHigh,
                                ),
                              ),
                              subtitle: Text(
                                user.about ??
                                    'Hey there! I am using GupShupGo.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    TextStyle(fontSize: 12, color: c.textMid),
                              ),
                              trailing: Icon(Icons.chevron_right,
                                  color: c.textLow, size: 20),
                              onTap: () => Navigator.pop(context, user),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}
