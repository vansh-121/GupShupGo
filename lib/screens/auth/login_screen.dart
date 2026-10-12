import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/l10n/app_localizations.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/services/auth_service.dart';
import 'package:video_chat_app/screens/home_screen.dart';
import 'package:video_chat_app/screens/auth/phone_auth_screen.dart';
import 'package:video_chat_app/screens/nearby_peers_screen.dart';
import 'package:video_chat_app/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _signInWithGoogle() async {
    final t = AppLocalizations.of(context);
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      UserModel? user = await _authService.signInWithGoogle();
      if (!mounted) return;
      if (user != null) {
        setState(() => _isLoading = false);
        _goHome();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = t.loginErrorGoogleCancelled;
        });
      }
    } catch (e) {
      if (!mounted) return;
      // A failed profile read is the one exception we must NOT wave through.
      // The branch below exists for the case where Firebase Auth succeeded and
      // only some later step complained — letting the user in is right there.
      // But ProfileReadException means sign-in stopped precisely because it
      // could not tell whether this account already exists, so Home would load
      // with no profile and the "choose a username" prompt could fire at an
      // account that already has one. Retrying is the honest answer.
      if (e is ProfileReadException) {
        setState(() {
          _isLoading = false;
          _errorMessage = t.loginErrorProfileLoad;
        });
        return;
      }
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        setState(() => _isLoading = false);
        _goHome();
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = t.loginErrorGoogleFailed;
      });
    }
  }

  String? _validateEmail(AppLocalizations t, String email) {
    if (email.isEmpty) {
      return t.loginErrorEnterEmail;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return t.loginErrorValidEmail;
    }
    return null;
  }

  String? _validatePassword(AppLocalizations t, String password) {
    if (password.isEmpty) {
      return t.loginErrorEnterPassword;
    }
    if (password.length < 6) {
      return t.loginErrorPasswordMin6;
    }
    return null;
  }

  /// Stronger rules applied only at sign-up. Sign-in keeps the lenient check
  /// above so existing accounts created before these rules aren't locked out.
  String? _validateNewPassword(AppLocalizations t, String password) {
    if (password.isEmpty) {
      return t.loginErrorEnterPasswordSignup;
    }
    if (password.length < 8) {
      return t.loginErrorPasswordMin8;
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(password)) {
      return t.loginErrorPasswordLetter;
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return t.loginErrorPasswordNumber;
    }
    return null;
  }

  Future<void> _signInWithEmail() async {
    final t = AppLocalizations.of(context);
    final emailError = _validateEmail(t, _emailController.text.trim());
    if (emailError != null) {
      setState(() => _errorMessage = emailError);
      return;
    }
    final passwordError = _validatePassword(t, _passwordController.text);
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
        setState(() => _errorMessage = t.loginErrorSignInFailed);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(t, e.code);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = t.loginErrorGeneric;
      });
    }
  }

  Future<void> _signUpWithEmail() async {
    final t = AppLocalizations.of(context);
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = t.loginErrorEnterName);
      return;
    }
    final emailError = _validateEmail(t, _emailController.text.trim());
    if (emailError != null) {
      setState(() => _errorMessage = emailError);
      return;
    }
    final passwordError = _validateNewPassword(t, _passwordController.text);
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
        setState(() => _errorMessage = t.loginErrorSignUpFailed);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(t, e.code);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = t.loginErrorGeneric;
      });
    }
  }

  Future<void> _resetPassword() async {
    final t = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    final emailError = _validateEmail(t, email);
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
          content: Text(t.loginResetEmailSent(email)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = t.loginErrorResetFailed;
      });
    }
  }

  String _getErrorMessage(AppLocalizations t, String code) {
    switch (code) {
      case 'user-not-found':
        return t.loginErrorUserNotFound;
      case 'wrong-password':
        return t.loginErrorWrongPassword;
      case 'email-already-in-use':
        return t.loginErrorEmailInUse;
      case 'invalid-email':
        return t.loginErrorInvalidEmail;
      case 'weak-password':
        return t.loginErrorWeakPassword;
      case 'invalid-credential':
        return t.loginErrorInvalidCredential;
      case 'too-many-requests':
        return t.loginErrorTooManyRequests;
      default:
        return t.loginErrorGeneric;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── GupShupGo App Icon & Title ─────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: c.primary.withOpacity(0.3),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'GupShupGo',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: c.textHigh,
                  letterSpacing: -0.6,
                ),
              ),

              const Spacer(flex: 3),

              // ── Action Buttons Stack (Stitch Design + Theme Aware) ─────────
              if (!_showEmailForm) ...[
                // 1. Primary: Phone Auth
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const PhoneAuthScreen()),
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          t.loginContinueWithPhone,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Secondary: Google Auth
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: c.surfaceAlt,
                      elevation: 0,
                      side: BorderSide(color: c.border, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: c.primary,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'G',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: c.textHigh,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                t.loginContinueWithGoogle,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: c.textHigh,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Tertiary: Email & Password
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _showEmailForm = true),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: c.surfaceAlt,
                      elevation: 0,
                      side: BorderSide(color: c.border, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mail_outline_rounded,
                            color: c.textHigh, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          t.loginUseEmailPassword,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: c.textHigh,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Expandable Email/Password Form in System Theme
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ModeChip(
                      label: t.loginSignIn,
                      selected: !_isSignUp,
                      onTap: () => setState(() {
                        _isSignUp = false;
                        _errorMessage = null;
                      }),
                    ),
                    const SizedBox(width: 12),
                    _ModeChip(
                      label: t.loginSignUp,
                      selected: _isSignUp,
                      onTap: () => setState(() {
                        _isSignUp = true;
                        _errorMessage = null;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_isSignUp) ...[
                  TextField(
                    controller: _nameController,
                    style: TextStyle(color: c.textHigh),
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: t.loginHintName,
                      hintStyle: TextStyle(color: c.textLow),
                      prefixIcon: Icon(Icons.person_outline,
                          color: c.textMid),
                      filled: true,
                      fillColor: c.surfaceAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: c.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: c.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: c.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                TextField(
                  controller: _emailController,
                  style: TextStyle(color: c.textHigh),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: t.loginHintEmail,
                    hintStyle: TextStyle(color: c.textLow),
                    prefixIcon:
                        Icon(Icons.email_outlined, color: c.textMid),
                    filled: true,
                    fillColor: c.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: c.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: c.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: c.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _passwordController,
                  style: TextStyle(color: c.textHigh),
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: t.loginHintPassword,
                    hintStyle: TextStyle(color: c.textLow),
                    helperText: _isSignUp
                        ? t.loginPasswordHelper
                        : null,
                    helperStyle:
                        TextStyle(color: c.textLow, fontSize: 11),
                    helperMaxLines: 2,
                    prefixIcon:
                        Icon(Icons.lock_outline, color: c.textMid),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: c.textMid,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: c.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: c.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: c.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: c.primary, width: 1.5),
                    ),
                  ),
                ),

                if (!_isSignUp)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      child: Text(
                        t.loginForgotPassword,
                        style: GoogleFonts.poppins(
                          color: c.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (_isSignUp ? _signUpWithEmail : _signInWithEmail),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
                            _isSignUp ? t.loginCreateAccount : t.loginSignIn,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() {
                    _showEmailForm = false;
                    _errorMessage = null;
                  }),
                  child: Text(
                    t.commonCancel,
                    style: GoogleFonts.poppins(
                      color: c.textMid,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              // Error display
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: c.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: c.error.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: c.error, size: 18),
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

              const Spacer(flex: 2),

              // ── Bottom Action: Offline Chat (Stitch Design) ────────────────
              GestureDetector(
                onTap: _isLoading
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NearbyPeersScreen()),
                        ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sensors_rounded,
                        color: c.textHigh,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t.loginOfflineChat,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: c.textHigh,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
