import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/services/auth_service.dart';
import 'package:video_chat_app/screens/home_screen.dart';
import 'package:video_chat_app/screens/auth/phone_auth_screen.dart';
import 'package:video_chat_app/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

/// Pill-shaped toggle chip for Sign In / Sign Up.
class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? c.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? c.primary : c.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: selected ? Colors.white : c.textMid,
          ),
        ),
      ),
    );
  }
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLoading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _showEmailForm = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _requestAllPermissions();
  }

  /// Requests all permissions the app needs upfront so they're already
  /// granted by the time the user makes or receives a call.
  ///
  /// Permissions requested:
  /// - Camera & Microphone → video/audio calls
  /// - Notifications → FCM push notifications (Android 13+)
  /// - Phone → call state detection
  /// - CallKit notification + full-screen intent → incoming call UI
  Future<void> _requestAllPermissions() async {
    // ── Standard Android permissions via permission_handler ──
    await [
      Permission.camera,
      Permission.microphone,
      Permission.notification,
      Permission.phone,
    ].request();

    // ── CallKit-specific permissions (Android 13+ notification & 14+ full-screen) ──
    try {
      FlutterCallkitIncoming.requestNotificationPermission({
        "rationaleMessagePermission":
            "Notification permission is required to receive incoming calls.",
        "postNotificationMessageRequired":
            "Please allow notification permission from settings to receive calls.",
      });
      FlutterCallkitIncoming.requestFullIntentPermission();
    } catch (e) {
      print('CallKit permission request error (non-fatal): $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen()),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      UserModel? user = await _authService.signInWithGoogle();
      setState(() => _isLoading = false);
      if (user != null) {
        _goHome();
      } else {
        setState(() => _errorMessage = 'Google sign-in was cancelled.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Google sign-in failed. Please try again.';
      });
    }
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return 'Please enter your password';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _signInWithEmail() async {
    final emailError = _validateEmail(_emailController.text.trim());
    if (emailError != null) {
      setState(() => _errorMessage = emailError);
      return;
    }
    final passwordError = _validatePassword(_passwordController.text);
    if (passwordError != null) {
      setState(() => _errorMessage = passwordError);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserModel? user = await _authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      setState(() => _isLoading = false);
      if (user != null) {
        _goHome();
      } else {
        setState(() => _errorMessage = 'Failed to sign in. Please try again.');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  Future<void> _signUpWithEmail() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your name');
      return;
    }
    final emailError = _validateEmail(_emailController.text.trim());
    if (emailError != null) {
      setState(() => _errorMessage = emailError);
      return;
    }
    final passwordError = _validatePassword(_passwordController.text);
    if (passwordError != null) {
      setState(() => _errorMessage = passwordError);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserModel? user = await _authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );
      setState(() => _isLoading = false);
      if (user != null) {
        _goHome();
      } else {
        setState(() => _errorMessage = 'Failed to sign up. Please try again.');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final emailError = _validateEmail(email);
    if (emailError != null) {
      setState(() => _errorMessage = emailError);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.resetPassword(email);
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent to $email'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to send reset email. Please try again.';
      });
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email. Please sign up.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Please sign in.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Scaffold(
      backgroundColor: c.surface,
      body: Column(
        children: [
          // ── Gradient brand header ────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 40,
              bottom: 40,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6C5CE7), Color(0xFF9B8FF0)],
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'GupShupGo',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Stay connected with everyone',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable actions ───────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── PRIMARY: Phone OTP ───────────────────────────────
                  ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => PhoneAuthScreen()),
                            ),
                    icon: const Icon(Icons.phone_android_rounded,
                        color: Colors.white, size: 20),
                    label: Text(
                      'Continue with Phone',
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── SECONDARY: Google Sign-In ────────────────────────
                  OutlinedButton(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: c.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.g_mobiledata,
                                  size: 26, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(
                                'Continue with Google',
                                style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: c.textHigh),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 28),

                  // ── Divider ──────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(child: Divider(color: c.divider)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'or sign in with email',
                          style: GoogleFonts.poppins(
                              color: c.textLow, fontSize: 13),
                        ),
                      ),
                      Expanded(child: Divider(color: c.divider)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── TERTIARY: Email/Password (collapsible) ───────────
                  if (!_showEmailForm)
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _showEmailForm = true),
                      icon: Icon(Icons.email_outlined,
                          color: c.primary),
                      label: Text(
                        'Use Email & Password',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: c.primary),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: c.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    )
                  else ...[
                    // Mode toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ModeChip(
                          label: 'Sign In',
                          selected: !_isSignUp,
                          onTap: () => setState(() {
                            _isSignUp = false;
                            _errorMessage = null;
                          }),
                        ),
                        const SizedBox(width: 12),
                        _ModeChip(
                          label: 'Sign Up',
                          selected: _isSignUp,
                          onTap: () => setState(() {
                            _isSignUp = true;
                            _errorMessage = null;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Name field (sign up only)
                    if (_isSignUp) ...[
                      TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Your Name',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Email field
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    // Forgot password
                    if (!_isSignUp)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading ? null : _resetPassword,
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.poppins(
                                color: c.primary,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 24),

                    // Submit button
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : (_isSignUp ? _signUpWithEmail : _signInWithEmail),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isSignUp ? 'Create Account' : 'Sign In',
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                    ),

                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() {
                        _showEmailForm = false;
                        _errorMessage = null;
                      }),
                      child: Text(
                        'Hide email options',
                        style: GoogleFonts.poppins(
                            color: c.textMid,
                            fontWeight: FontWeight.w400),
                      ),
                    ),
                  ],

                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: c.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: c.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: c.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
