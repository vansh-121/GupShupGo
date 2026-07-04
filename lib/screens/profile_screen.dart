import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_chat_app/models/gamification_data.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/services/auth_service.dart';
import 'package:video_chat_app/services/user_service.dart';
import 'package:video_chat_app/screens/gup_arcade_screen.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/provider/subscription_provider.dart';
import 'package:video_chat_app/screens/premium_screen.dart';
import 'package:video_chat_app/widgets/premium_badge.dart';

/// Full WhatsApp-style profile screen: edit name, about, and profile picture.
class ProfileScreen extends StatefulWidget {
  final UserModel currentUser;

  const ProfileScreen({super.key, required this.currentUser});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _aboutController;

  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _photoUrl;
  String? _errorMessage;

  static const String _defaultAbout = 'Hey there! I am using GupShupGo.';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.name);
    _aboutController =
        TextEditingController(text: widget.currentUser.about ?? _defaultAbout);
    _photoUrl = widget.currentUser.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final XFile? picked = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 70);
      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);

      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos/${widget.currentUser.id}.jpg');

      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();

      setState(() {
        _photoUrl = url;
        _isUploadingPhoto = false;
      });
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      _showError('Failed to upload photo: $e');
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Name cannot be empty.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updatedUser = widget.currentUser.copyWith(
        name: name,
        about: _aboutController.text.trim(),
        photoUrl: _photoUrl,
      );
      await _userService.createOrUpdateUser(updatedUser);

      // Also update Firebase Auth display name
      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile updated'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(updatedUser);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('Failed to save profile: $e');
    }
  }

  void _showError(String msg) {
    setState(() => _errorMessage = msg);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final avatarUrl = _photoUrl ??
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_nameController.text.isNotEmpty ? _nameController.text : "U")}&background=4CAF50&color=fff&size=256';

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Save',
                    style: TextStyle(
                        color: c.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Avatar ──────────────────────────────────────────────────
            GestureDetector(
              onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(avatarUrl),
                    backgroundColor: c.surfaceAlt,
                    child: _isUploadingPhoto
                        ? const CircularProgressIndicator(color: Colors.white)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: c.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.surface, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Pro badge
            if (context.watch<SubscriptionProvider>().isPro)
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: PremiumBadge(size: PremiumBadgeSize.medium),
              ),
            Text('Tap to change photo',
                style: TextStyle(color: c.textMid, fontSize: 12)),

            // Upgrade to Pro button (only for free users)
            if (!context.watch<SubscriptionProvider>().isPro) ...[  
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PremiumScreen()),
                ),
                icon: const Icon(Icons.workspace_premium_rounded,
                    size: 18, color: Color(0xFFFFD700)),
                label: Text(
                  'Upgrade to Pro',
                  style: TextStyle(
                    color: c.textHigh,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  side: BorderSide(color: const Color(0xFFFFD700).withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),

            // ── Gup Arcade Mini-Stats Card ─────────────────────────────────
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.currentUser.id)
                  .snapshots(),
              builder: (context, snap) {
                final liveUser = snap.hasData && snap.data!.exists
                    ? UserModel.fromFirestore(snap.data!)
                    : widget.currentUser;
                final level = liveUser.level;
                final levelName = getLevelName(level);
                final levelIcon = getLevelIcon(level);

                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: c.isDark
                          ? [const Color(0xFF1E1E2C), const Color(0xFF2A2040)]
                          : [c.primary.withOpacity(0.06), c.primary.withOpacity(0.02)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.border.withOpacity(0.4), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: c.primary.withOpacity(c.isDark ? 0.15 : 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GupArcadeScreen(
                              currentUserId: widget.currentUser.id,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Header row
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [c.primary, c.primary.withOpacity(0.7)],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$level',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(levelIcon, style: const TextStyle(fontSize: 14)),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              levelName,
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: c.textHigh,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Gup Arcade',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: c.textMid,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: c.textMid,
                                  size: 22,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Stats row
                            Row(
                              children: [
                                _miniStat(c, '⚡', '${liveUser.gupPoints}', 'Points'),
                                _miniStatDivider(c),
                                _miniStat(c, '🏅', '${liveUser.badges.length}', 'Badges'),
                                _miniStatDivider(c),
                                _miniStat(c, '🔥', '${liveUser.longestStreak}', 'Best Bond'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── Name ────────────────────────────────────────────────────
            _buildSectionLabel('YOUR NAME'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              maxLength: 25,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Enter your name',
                counterStyle: TextStyle(color: c.textLow, fontSize: 12),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── About ───────────────────────────────────────────────────
            _buildSectionLabel('ABOUT'),
            const SizedBox(height: 8),
            TextField(
              controller: _aboutController,
              maxLength: 139,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'What\'s on your mind?',
                counterStyle: TextStyle(color: c.textLow, fontSize: 12),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Read-only info ───────────────────────────────────────────
            if (widget.currentUser.phoneNumber != null) ...[
              _buildSectionLabel('PHONE'),
              const SizedBox(height: 8),
              _ReadOnlyField(
                icon: Icons.phone_outlined,
                value: widget.currentUser.phoneNumber!,
              ),
              const SizedBox(height: 16),
            ],
            if (widget.currentUser.email != null) ...[
              _buildSectionLabel('EMAIL'),
              const SizedBox(height: 8),
              _ReadOnlyField(
                icon: Icons.email_outlined,
                value: widget.currentUser.email!,
              ),
              const SizedBox(height: 16),
            ],

            // ── Linked providers ─────────────────────────────────────────
            const SizedBox(height: 8),
            _buildSectionLabel('LINKED SIGN-IN METHODS'),
            const SizedBox(height: 8),
            _LinkedProvidersCard(authService: _authService),

            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: c.error),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_errorMessage!,
                            style: TextStyle(color: c.error))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    final c = AppThemeColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label,
          style: TextStyle(
              color: c.textMid,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8)),
    );
  }

  Widget _miniStat(AppThemeColors c, String emoji, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 3),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: c.textHigh,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: c.textLow,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStatDivider(AppThemeColors c) {
    return Container(
      width: 1,
      height: 28,
      color: c.border.withOpacity(0.4),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final IconData icon;
  final String value;

  const _ReadOnlyField({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: c.textMid, size: 20),
          const SizedBox(width: 12),
          Text(value, style: TextStyle(color: c.textHigh)),
        ],
      ),
    );
  }
}

class _LinkedProvidersCard extends StatelessWidget {
  final AuthService authService;
  const _LinkedProvidersCard({required this.authService});

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final providers = authService.getLinkedProviders();
    final items = <_ProviderInfo>[
      _ProviderInfo('phone', Icons.phone_android, 'Phone', Colors.green),
      _ProviderInfo('google.com', Icons.g_mobiledata, 'Google', Colors.red),
      _ProviderInfo('password', Icons.email_outlined, 'Email', Colors.blue),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final linked = providers.contains(item.id);
          return Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                title: Text(item.label, style: const TextStyle(fontSize: 14)),
                trailing: linked
                    ? const Icon(Icons.check_circle,
                        color: Colors.green, size: 20)
                    : Text('Not linked',
                        style:
                            TextStyle(color: c.textLow, fontSize: 12)),
              ),
              if (i < items.length - 1)
                Divider(height: 1, indent: 56, color: c.divider),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ProviderInfo {
  final String id;
  final IconData icon;
  final String label;
  final Color color;

  _ProviderInfo(this.id, this.icon, this.label, this.color);
}
