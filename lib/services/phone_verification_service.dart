import 'package:flutter/services.dart';

/// Thin wrapper over Android's **Phone Number Hint API** (Play Services
/// Identity). This is a SIM-number *autofill hint* only — it shows a system
/// picker so the user can drop their SIM number into the phone field. It does
/// **not** verify anything and performs no carrier check; proving ownership is
/// entirely the job of the SMS OTP flow in [AuthService.verifyPhoneNumber].
///
/// Treat every failure (cancel / unavailable) as a harmless no-op: the user can
/// always type the number manually.
class PhoneVerificationService {
  static const MethodChannel _channel =
      MethodChannel('com.gupshupgo.app/phone_verification');

  /// Shows the Android SIM-number picker ("Choose a number") and returns the
  /// selected number (e.g. "+919876543210") for use as a field prefill, or
  /// throws [PhoneVerificationException] if the user cancels / it's unavailable.
  /// No verification is performed on the returned number.
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
            'SIM number autofill is not available on this device. '
            'Please type your phone number.',
            PhoneVerificationError.notAvailable,
          );
        case 'LAUNCH_ERROR':
          throw PhoneVerificationException(
            'Could not open the phone number picker.',
            PhoneVerificationError.launchFailed,
          );
        case 'PARSE_ERROR':
          throw PhoneVerificationException(
            'Failed to read the phone number from the system.',
            PhoneVerificationError.parseFailed,
          );
        default:
          throw PhoneVerificationException(
            e.message ?? 'Unknown error while reading the SIM number.',
            PhoneVerificationError.unknown,
          );
      }
    } catch (e) {
      throw PhoneVerificationException(
        'SIM number autofill failed: $e',
        PhoneVerificationError.unknown,
      );
    }
  }

  /// Whether the SIM-number autofill hint is likely available. The Phone Number
  /// Hint API requires Android 6+ and Google Play Services; we attempt it and
  /// handle failure gracefully, so this is only a coarse capability flag.
  bool get isSupported {
    // Method channel is Android-only; iOS has no equivalent hint picker.
    return true;
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
