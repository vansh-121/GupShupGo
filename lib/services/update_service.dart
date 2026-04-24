import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Service that uses Google Play's native In-App Updates API to prompt users
/// to update. Uses the **immediate** update type which shows a full-screen
/// Play Store update flow — the user cannot use the app until the update is
/// installed.
///
/// How it works:
/// 1. Checks Play Store for a newer version via [checkForUpdate].
/// 2. If an update is available AND immediate update is allowed, triggers
///    [performImmediateUpdate] which hands control to the Play Store.
/// 3. The Play Store downloads, verifies, and installs the update — then
///    restarts the app automatically.
///
/// ⚠ IMPORTANT:
/// - This only works when the app is installed from Google Play (not from
///   debug/local APK installs). During development you'll see
///   `ERROR_API_NOT_AVAILABLE` — this is expected.
/// - For testing, use Google Play's internal testing track.
class UpdateService {
  /// Checks for an available update and triggers the native Play Store
  /// immediate update flow if one exists.
  ///
  /// Call this from [HomeScreen.initState] or equivalent — it's fire-and-forget
  /// and will never throw to the caller.
  Future<void> checkAndPromptUpdate() async {
    try {
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();

      print('Update check: available=${info.updateAvailability}, '
          'immediateAllowed=${info.immediateUpdateAllowed}, '
          'flexibleAllowed=${info.flexibleUpdateAllowed}');

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          // This launches the full-screen Play Store update UI.
          // The user MUST update before they can continue using the app.
          // After the update is installed, the app restarts automatically.
          await InAppUpdate.performImmediateUpdate();
          print('Immediate update completed — app will restart.');
        } else if (info.flexibleUpdateAllowed) {
          // Fallback: if immediate isn't allowed (e.g., the update isn't
          // flagged as high-priority), use the flexible flow which downloads
          // in the background and shows a snackbar-style banner.
          await InAppUpdate.startFlexibleUpdate();
          // Once downloaded, complete the install
          await InAppUpdate.completeFlexibleUpdate();
          print('Flexible update completed.');
        }
      } else {
        print('App is up to date.');
      }
    } catch (e) {
      // Expected to fail during local/debug builds since the Play Core
      // API requires the app to be installed via Google Play.
      if (kDebugMode) {
        print('In-app update check failed (expected in debug): $e');
      }
    }
  }
}
