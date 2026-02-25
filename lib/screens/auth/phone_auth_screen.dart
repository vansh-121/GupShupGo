import 'package:flutter/material.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/services/auth_service.dart';
import 'package:video_chat_app/services/phone_verification_service.dart';
import 'package:video_chat_app/screens/home_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
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
            MaterialPageRoute(builder: (_) => HomeScreen()),
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
      SnackBar(
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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen()),
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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      setState(() {
        _errorMessage = 'Failed to sign in. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 40),
              Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: Colors.blue,
              ),
              SizedBox(height: 24),
              Text(
                'Welcome to GupShupGo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 12),

              // ─── Carrier verification flow ───
              if (_flowStep == 0) ...[
                Text(
                  'Use your phone number to sign in',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    "We'll use a Google service to verify your number "
                    "with your carrier. It's simple and secure—and only "
                    "takes a few seconds.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      height: 1.4,
                    ),
                  ),
                ),
                SizedBox(height: 32),

                // Name field
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Your Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Primary: Carrier-based verification button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _startCarrierVerification,
                  icon: Icon(Icons.verified_user, color: Colors.white),
                  label: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Verify with Phone Number',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR use OTP',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                SizedBox(height: 20),

                // Fallback: Manual phone number + OTP
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                    hintText: '+91 1234567890',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _isLoading ? null : _sendOTP,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Send OTP Instead',
                    style: TextStyle(fontSize: 16),
                  ),
                ),

                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                SizedBox(height: 16),

                OutlinedButton(
                  onPressed: _isLoading ? null : _signInAnonymously,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue as Guest',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],

              // ─── Carrier verification in progress ───
              if (_flowStep == 1 || _flowStep == 2) ...[
                SizedBox(height: 40),
                Icon(
                  Icons.phone_android,
                  size: 64,
                  color: Colors.blue,
                ),
                SizedBox(height: 24),
                Text(
                  _flowStep == 1
                      ? 'Requesting phone number...'
                      : 'Verifying with carrier...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),
                if (_verifiedPhoneNumber != null) ...[
                  Text(
                    _verifiedPhoneNumber!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 12),
                ],
                Text(
                  'Google is verifying your device info with your carrier. '
                  'This only takes a few seconds.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 32),
                Center(
                  child: CircularProgressIndicator(),
                ),
                SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _flowStep = 0;
                      _isLoading = false;
                      _carrierVerifying = false;
                    });
                  },
                  child: Text('Cancel'),
                ),
              ],

              // ─── Fallback OTP entry (Step 3) ───
              if (_flowStep == 3) ...[
                SizedBox(height: 20),
                if (_verifiedPhoneNumber != null) ...[
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Carrier verification timed out. '
                            'Please enter the OTP sent to $_verifiedPhoneNumber',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Your Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Enter OTP',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Verify OTP',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _otpSent = false;
                      _flowStep = 0;
                      _otpController.clear();
                      _verifiedPhoneNumber = null;
                    });
                  },
                  child: Text('Go Back'),
                ),
              ],

              // Error message
              if (_errorMessage != null) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

