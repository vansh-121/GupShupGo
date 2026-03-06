import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/services/auth_service.dart';
import 'package:video_chat_app/services/user_service.dart';

/// Full WhatsApp-style profile screen: edit name, about, and profile picture.
class ProfileScreen extends StatefulWidget {
  final UserModel currentUser;

  const ProfileScreen({Key? key, required this.currentUser}) : super(key: key);

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
    _nameController =
        TextEditingController(text: widget.currentUser.name);
    _aboutController = TextEditingController(
        text: widget.currentUser.about ?? _defaultAbout);
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
      final XFile? picked =
          await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
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
      await FirebaseAuth.instance.currentUser
          ?.updateDisplayName(name);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile updated'),
              backgroundColor: Colors.green),
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
    final avatarUrl = _photoUrl ??
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_nameController.text.isNotEmpty ? _nameController.text : "U")}&background=4CAF50&color=fff&size=256';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save',
                    style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.w600)),
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
                    backgroundColor: Colors.grey.shade200,
                    child: _isUploadingPhoto
                        ? const CircularProgressIndicator(color: Colors.white)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('Tap to change photo',
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 32),

            // ── Name ────────────────────────────────────────────────────
            _buildSectionLabel('YOUR NAME'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              maxLength: 25,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Enter your name',
                counterStyle:
                    TextStyle(color: Colors.grey[400], fontSize: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue),
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
                counterStyle:
                    TextStyle(color: Colors.grey[400], fontSize: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue),
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
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_errorMessage!,
                            style:
                                TextStyle(color: Colors.red[700]))),
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label,
          style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8)),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final IconData icon;
  final String value;

  const _ReadOnlyField({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 20),
          const SizedBox(width: 12),
          Text(value, style: TextStyle(color: Colors.grey[700])),
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
    final providers = authService.getLinkedProviders();
    final items = <_ProviderInfo>[
      _ProviderInfo('phone', Icons.phone_android, 'Phone', Colors.green),
      _ProviderInfo('google.com', Icons.g_mobiledata, 'Google', Colors.red),
      _ProviderInfo('password', Icons.email_outlined, 'Email', Colors.blue),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
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
                  child:
                      Icon(item.icon, color: item.color, size: 20),
                ),
                title: Text(item.label,
                    style: const TextStyle(fontSize: 14)),
                trailing: linked
                    ? const Icon(Icons.check_circle,
                        color: Colors.green, size: 20)
                    : Text('Not linked',
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 12)),
              ),
              if (i < items.length - 1)
                Divider(
                    height: 1,
                    indent: 56,
                    color: Colors.grey.shade100),
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
