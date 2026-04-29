import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/services/auth_service.dart';
import 'package:video_chat_app/screens/home_screen.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// Shown once right after phone OTP verification, while the phone session is
/// still the current Firebase Auth user.  Lets the user link a Google account
/// or email/password so they can sign back in later without needing the SIM.
class LinkAccountsScreen extends StatefulWidget {
  final UserModel user;
  const LinkAccountsScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<LinkAccountsScreen> createState() => _LinkAccountsScreenState();
}

class _LinkAccountsScreenState extends State<LinkAccountsScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLinkingGoogle = false;
  bool _isLinkingEmail = false;
  bool _showEmailForm = false;
  bool _obscurePassword = true;
  bool _googleLinked = false;
  bool _emailLinked = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen()),
    );
  }

  Future<void> _linkGoogle() async {
    setState(() {
      _isLinkingGoogle = true;
      _errorMessage = null;
    });
    try {
      await _authService.linkGoogleProvider();
      setState(() {
        _isLinkingGoogle = false;
        _googleLinked = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google account linked successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLinkingGoogle = false);
      if (e.code == 'credential-already-in-use' ||
          e.code == 'account-exists-with-different-credential') {
        setState(() => _errorMessage =
            'This Google account is already registered as a separate GupShupGo account. '
                'To merge, sign out and sign in with Google, then link your phone number from settings.');
      } else {
        setState(() => _errorMessage = e.message ?? 'Failed to link Google.');
      }
    } catch (e) {
      setState(() {
        _isLinkingGoogle = false;
        _errorMessage = e.toString().contains('No active session')
            ? 'Session expired. Please sign in again.'
            : 'Google linking failed. Try again.';
      });
    }
  }

  Future<void> _linkEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLinkingEmail = true;
      _errorMessage = null;
    });
    try {
      await _authService.linkEmailProvider(email: email, password: password);
      setState(() {
        _isLinkingEmail = false;
        _emailLinked = true;
        _showEmailForm = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email linked successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLinkingEmail = false);
      if (e.code == 'email-already-in-use' ||
          e.code == 'credential-already-in-use') {
        setState(() => _errorMessage =
            'This email is already registered separately on GupShupGo. '
                'Sign in with email first, then link your phone from settings.');
      } else if (e.code == 'provider-already-linked') {
        setState(() =>
            _errorMessage = 'An email is already linked to your account.');
      } else {
        setState(() => _errorMessage = e.message ?? 'Failed to link email.');
      }
    } catch (e) {
      setState(() {
        _isLinkingEmail = false;
        _errorMessage = 'Email linking failed. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final linkedProviders = _authService.getLinkedProviders();
    final alreadyHasGoogle =
        linkedProviders.contains('google.com') || _googleLinked;
    final alreadyHasEmail =
        linkedProviders.contains('password') || _emailLinked;

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _goHome,
            child: Text(
              'Skip',
              style: TextStyle(fontSize: 15, color: c.textMid),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.link_rounded, size: 64, color: c.primary),
              const SizedBox(height: 20),
              Text(
                'Add a backup sign-in method',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: c.textHigh),
              ),
              const SizedBox(height: 10),
              Text(
                'Link Google or email so you can sign back in\neven if your SIM is unavailable.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: c.textMid),
              ),
              const SizedBox(height: 36),

              // ── Google Link ─────────────────────────────────────────
              _LinkTile(
                icon: Icons.g_mobiledata,
                iconColor: Colors.red,
                title: 'Link Google Account',
                subtitle: alreadyHasGoogle
                    ? 'Linked ✓'
                    : 'One-tap sign-in without SIM',
                trailing: alreadyHasGoogle
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : _isLinkingGoogle
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : ElevatedButton(
                            onPressed: _linkGoogle,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.surface,
                              foregroundColor: c.textHigh,
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side:
                                      BorderSide(color: c.border)),
                            ),
                            child: const Text('Link'),
                          ),
              ),

              const SizedBox(height: 16),

              // ── Email Link ──────────────────────────────────────────
              _LinkTile(
                icon: Icons.email_outlined,
                iconColor: Colors.blue,
                title: 'Link Email & Password',
                subtitle: alreadyHasEmail
                    ? 'Linked ✓'
                    : 'Sign in with email if no SIM or Google',
                trailing: alreadyHasEmail
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : TextButton(
                        onPressed: () =>
                            setState(() => _showEmailForm = !_showEmailForm),
                        child: Text(_showEmailForm ? 'Cancel' : 'Add'),
                      ),
              ),

              if (_showEmailForm && !alreadyHasEmail) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Create a password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    helperText: 'Minimum 6 characters',
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isLinkingEmail ? null : _linkEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLinkingEmail
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Link Email',
                          style: TextStyle(color: Colors.white, fontSize: 15)),
                ),
              ],

              // ── Error ───────────────────────────────────────────────
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.warning.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: c.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          color: c.warning, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                              color: c.textHigh, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 36),

              // ── Continue ────────────────────────────────────────────
              ElevatedButton(
                onPressed: _goHome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  (alreadyHasGoogle || alreadyHasEmail)
                      ? 'Continue to App'
                      : 'Skip for Now',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _LinkTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14, color: c.textHigh)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(color: c.textMid, fontSize: 12)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
