import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/services/auth_service.dart';
import 'package:video_chat_app/services/phone_verification_service.dart';
import 'package:video_chat_app/screens/auth/link_accounts_screen.dart';
import 'package:video_chat_app/theme/app_theme.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  _PhoneAuthScreenState createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  bool _carrierVerifying = false;

  String? _verificationId;
  String? _errorMessage;
  String? _verifiedPhoneNumber;

  // Flow states
  // 0 = initial (enter name)
  // 1 = carrier verification in progress
  // 2 = carrier verification prompt (show phone number to confirm)
  // 3 = fallback OTP entry
  int _flowStep = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ─── NEW: Carrier-based phone verification (no SMS OTP) ───
  Future<void> _startCarrierVerification() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your name first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _flowStep = 1;
    });

    try {
      // Step 1: System dialog asks user to share phone number
      final phoneNumber = await _authService.requestCarrierVerification();

      setState(() {
        _verifiedPhoneNumber = phoneNumber;
        _flowStep = 2;
        _carrierVerifying = true;
      });

      // Step 2: Use carrier-verified number for Firebase Auth
      await _authService.signInWithVerifiedPhone(
        verifiedPhoneNumber: phoneNumber,
        name: _nameController.text.trim(),
        onAutoVerified: (user) {
          setState(() {
            _isLoading = false;
            _carrierVerifying = false;
          });
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => LinkAccountsScreen(user: user)),
          );
        },
        onCodeSent: (verificationId) {
          // Carrier auto-verify didn't complete — fall back to OTP
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _flowStep = 3;
            _isLoading = false;
            _carrierVerifying = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('OTP sent to $phoneNumber as fallback'),
              backgroundColor: Colors.orange,
            ),
          );
        },
        onError: (error) {
          setState(() {
            _errorMessage = error;
            _isLoading = false;
            _carrierVerifying = false;
            _flowStep = 0;
          });
        },
      );
    } on PhoneVerificationException catch (e) {
      setState(() {
        _isLoading = false;
        _flowStep = 0;
      });

      if (e.error == PhoneVerificationError.cancelled) {
        setState(() {
          _errorMessage = 'Phone number selection cancelled';
        });
      } else if (e.error == PhoneVerificationError.notAvailable) {
        // Carrier verification not available — show manual phone entry
        setState(() {
          _errorMessage = null;
        });
        _showManualPhoneEntry();
      } else {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Verification failed: $e';
        _isLoading = false;
        _flowStep = 0;
      });
    }
  }

  // ─── FALLBACK: Manual phone + OTP (old flow) ───
  void _showManualPhoneEntry() {
    setState(() {
      _flowStep = 0;
      _otpSent = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Carrier verification unavailable. Use OTP instead.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _sendOTP() async {
    if (_phoneController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter phone number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String phoneNumber = _phoneController.text.trim();
    if (!phoneNumber.startsWith('+')) {
      phoneNumber = '+91$phoneNumber';
    }

    await _authService.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId) {
        setState(() {
          _verificationId = verificationId;
          _otpSent = true;
          _flowStep = 3;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP sent to $phoneNumber')),
        );
      },
      onError: (error) {
        setState(() {
          _errorMessage = error;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter OTP';
      });
      return;
    }

    if (_nameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your name';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    UserModel? user = await _authService.signInWithPhoneOTP(
      verificationId: _verificationId!,
      otp: _otpController.text.trim(),
      name: _nameController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (user != null) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LinkAccountsScreen(user: user)),
      );
    } else {
      setState(() {
        _errorMessage = 'Invalid OTP. Please try again.';
      });
    }
  }

  Future<void> _signInAnonymously() async {
    if (_nameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your name';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    UserModel? user = await _authService.signInAnonymously(
      _nameController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (user != null) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LinkAccountsScreen(user: user)),
      );
    } else {
      setState(() {
        _errorMessage = 'Failed to sign in. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.textHigh, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // ── Top Header Logo (GupShupGo App Icon) ──
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 88,
                    height: 88,
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
              ),
              const SizedBox(height: 20),
              Text(
                'GupShupGo',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: c.textHigh,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Use your phone number to sign in.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: c.textMid,
                ),
              ),
              const SizedBox(height: 32),

              // ─── Carrier verification flow ───
              if (_flowStep == 0) ...[
                // 1. Name Input Field (Stitch Style)
                TextField(
                  controller: _nameController,
                  style: TextStyle(color: c.textHigh),
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Your Name',
                    hintStyle: TextStyle(color: c.textLow),
                    prefixIcon: Icon(Icons.person_outline_rounded, color: c.textMid),
                    filled: true,
                    fillColor: c.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: c.border, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: c.border, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: c.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Primary: Carrier-based verification button (Stitch Style)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _startCarrierVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Verify with Phone Number',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 20),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: c.divider, thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR use OTP',
                        style: GoogleFonts.poppins(
                          color: c.textLow,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: c.divider, thickness: 1)),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. Fallback: Manual phone number input (Stitch Style)
                TextField(
                  controller: _phoneController,
                  style: TextStyle(color: c.textHigh),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Phone Number',
                    hintStyle: TextStyle(color: c.textLow),
                    prefixIcon: Icon(Icons.phone_outlined, color: c.textMid),
                    filled: true,
                    fillColor: c.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: c.border, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: c.border, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: c.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Secondary Action Button (Stitch Style)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _sendOTP,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: c.surfaceAlt,
                      elevation: 0,
                      side: BorderSide(color: c.border, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Send OTP Instead',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: c.textHigh,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: c.divider, thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: GoogleFonts.poppins(
                          color: c.textLow,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: c.divider, thickness: 1)),
                  ],
                ),
                const SizedBox(height: 20),

                // 5. Tertiary Action: Continue as Guest (Stitch Style)
                GestureDetector(
                  onTap: _isLoading ? null : _signInAnonymously,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Continue as Guest',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.textHigh,
                      ),
                    ),
                  ),
                ),
              ],

              // ─── Carrier verification in progress ───
              if (_flowStep == 1 || _flowStep == 2) ...[
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: c.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: c.primary.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(Icons.phone_android_rounded,
                        size: 40, color: c.primary),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _flowStep == 1
                      ? 'Requesting phone number...'
                      : 'Verifying with carrier...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: c.textHigh),
                ),
                const SizedBox(height: 12),
                if (_verifiedPhoneNumber != null) ...[
                  Text(
                    _verifiedPhoneNumber!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: c.primary,
                        letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Google is verifying your device info with your carrier. '
                  'This only takes a few seconds.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: c.textMid, height: 1.4),
                ),
                const SizedBox(height: 32),
                Center(
                    child: CircularProgressIndicator(color: c.primary)),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => setState(() {
                    _flowStep = 0;
                    _isLoading = false;
                    _carrierVerifying = false;
                  }),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                        color: c.textMid, fontWeight: FontWeight.w600),
                  ),
                ),
              ],

              // ─── Fallback OTP entry (Step 3) ───
              if (_flowStep == 3) ...[
                const SizedBox(height: 20),
                if (_verifiedPhoneNumber != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: c.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.warning.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: c.warning, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Carrier verification timed out. '
                            'Please enter the OTP sent to $_verifiedPhoneNumber',
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: c.warning),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _nameController,
                  style: TextStyle(color: c.textHigh),
                  decoration: InputDecoration(
                    hintText: 'Your Name',
                    hintStyle: TextStyle(color: c.textLow),
                    prefixIcon:
                        Icon(Icons.person_outline_rounded, color: c.textMid),
                    filled: true,
                    fillColor: c.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: c.border, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: c.border, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: c.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _otpController,
                  style: TextStyle(color: c.textHigh),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: 'Enter OTP',
                    hintStyle: TextStyle(color: c.textLow),
                    prefixIcon:
                        Icon(Icons.lock_outline_rounded, color: c.textMid),
                    filled: true,
                    fillColor: c.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: c.border, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: c.border, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: c.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text('Verify OTP',
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() {
                    _otpSent = false;
                    _flowStep = 0;
                    _otpController.clear();
                    _verifiedPhoneNumber = null;
                  }),
                  child: Text(
                    'Go Back',
                    style: GoogleFonts.poppins(
                        color: c.textMid, fontWeight: FontWeight.w600),
                  ),
                ),
              ],

              // Error message banner
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: c.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: c.error.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: c.error, size: 20),
                      const SizedBox(width: 10),
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

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
