import 'package:flutter/services.dart';

/// Service that uses Firebase Phone Number Verification (carrier-based).
/// This verifies phone numbers directly via the carrier — no SMS OTP needed.
/// Uses Android's Phone Number Hint API to show a system dialog where the user
/// shares their SIM phone number, then verifies it with the carrier.
class PhoneVerificationService {
  static const MethodChannel _channel =
      MethodChannel('com.gupshupgo.app/phone_verification');

  /// Requests the phone number hint from the Android system.
  /// Shows a bottom sheet dialog: "Share your phone number with GupShupGo"
  /// Returns the verified phone number (e.g., "+919876543210") or throws.
  Future<String> requestPhoneNumberHint() async {
    try {
      final String phoneNumber =
          await _channel.invokeMethod('requestPhoneNumberHint');
      return phoneNumber;
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'CANCELLED':
          throw PhoneVerificationException(
            'Phone number selection was cancelled.',
            PhoneVerificationError.cancelled,
          );
        case 'HINT_ERROR':
          throw PhoneVerificationException(
            'Phone number hint is not available on this device. '
            'Please use OTP verification instead.',
            PhoneVerificationError.notAvailable,
          );
        case 'LAUNCH_ERROR':
          throw PhoneVerificationException(
            'Could not launch phone number picker.',
            PhoneVerificationError.launchFailed,
          );
        case 'PARSE_ERROR':
          throw PhoneVerificationException(
            'Failed to read phone number from the system.',
            PhoneVerificationError.parseFailed,
          );
        default:
          throw PhoneVerificationException(
            e.message ?? 'Unknown error during phone verification.',
            PhoneVerificationError.unknown,
          );
      }
    } catch (e) {
      throw PhoneVerificationException(
        'Phone verification failed: $e',
        PhoneVerificationError.unknown,
      );
    }
  }

  /// Check if carrier-based phone verification is likely supported.
  /// This is a heuristic — Play Services Identity API requires Android 6+
  /// and Google Play Services.
  bool get isSupported {
    // Method channels only work on Android in this implementation.
    // iOS doesn't support carrier-based phone verification.
    return true; // On Android, we attempt and handle failure gracefully.
  }
}

enum PhoneVerificationError {
  cancelled,
  notAvailable,
  launchFailed,
  parseFailed,
  unknown,
}

class PhoneVerificationException implements Exception {
  final String message;
  final PhoneVerificationError error;

  PhoneVerificationException(this.message, this.error);

  @override
  String toString() => 'PhoneVerificationException: $message';
}
