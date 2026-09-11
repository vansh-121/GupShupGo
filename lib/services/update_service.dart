import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

import 'package:video_chat_app/main.dart' show sharedPrefs;
import 'package:video_chat_app/services/notification_service.dart';

/// Google Play In-App Updates, in the **flexible** (non-blocking) style.
///
/// The old behaviour forced a full-screen immediate update on launch. We now
/// nudge instead of block:
///  • On launch, [checkAndNotifyOnLaunch] posts an "Update available"
///    notification (throttled) — it never takes over the screen and never
///    blocks the app.
///  • The Settings "Check for updates" button ([checkForUpdate]) reports the
///    status on demand and lets the user opt in.
///  • Either path (notification tap or button) runs [startFlexibleUpdate]:
///    Play downloads the update in the background while the app stays usable,
///    then installs it with a quick restart the user consents to.
///
/// ⚠ Works only when the app was installed from Google Play. Debug and
/// sideloaded builds get `ERROR_API_NOT_AVAILABLE` from the Play API — that is
/// expected and surfaces as [UpdateCheckStatus.unavailable].
class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  /// Guards against launching a second flexible flow while one is already in
  /// flight (e.g. the user taps the button and the notification in quick
  /// succession).
  bool _flexibleInProgress = false;

  // The "Update available" nudge is throttled so a user who ignores it doesn't
  // get it on every single cold start: at most once a day, and again whenever
  // Play starts offering a genuinely different version code.
  static const _prefLastNotifiedMs = 'pref_update_notif_last_ms';
  static const _prefLastNotifiedVersion = 'pref_update_notif_version';

  // ─── Manual check (Settings → "Check for updates") ──────────────────────────
  /// Queries Play for a newer version. Never throws — an off-Play or errored
  /// check resolves to [UpdateCheckStatus.unavailable] so the caller can show a
  /// graceful message rather than crash.
  Future<UpdateCheckResult> checkForUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();

      // A flexible download from an earlier session is already staged and only
      // needs a restart to install — surface that ahead of everything else.
      if (info.installStatus == InstallStatus.downloaded) {
        return const UpdateCheckResult(UpdateCheckStatus.readyToInstall);
      }

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        return UpdateCheckResult(
          UpdateCheckStatus.updateAvailable,
          flexibleAllowed: info.flexibleUpdateAllowed,
          availableVersionCode: info.availableVersionCode,
        );
      }

      return const UpdateCheckResult(UpdateCheckStatus.upToDate);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('checkForUpdate failed (expected off-Play): $e');
      }
      return const UpdateCheckResult(UpdateCheckStatus.unavailable);
    }
  }

  // ─── Flexible update ────────────────────────────────────────────────────────
  /// Starts — or resumes — Google Play's background flexible update. The
  /// download runs while the app stays usable; once it finishes, Play's install
  /// prompt (a quick restart) is triggered. Re-checks first, so it safely
  /// no-ops when nothing is available, and is guarded against double-starts.
  ///
  /// [onDownloadStarted] fires once the download has been accepted, so a caller
  /// with a live BuildContext can show its own "downloading in the background"
  /// hint. Never throws.
  Future<void> startFlexibleUpdate({VoidCallback? onDownloadStarted}) async {
    if (_flexibleInProgress) return;
    _flexibleInProgress = true;
    try {
      final info = await InAppUpdate.checkForUpdate();

      // Already downloaded on an earlier run → just install.
      if (info.installStatus == InstallStatus.downloaded) {
        await InAppUpdate.completeFlexibleUpdate();
        return;
      }

      if (info.updateAvailability != UpdateAvailability.updateAvailable ||
          !info.flexibleUpdateAllowed) {
        return;
      }

      onDownloadStarted?.call();

      // Resolves once the download completes (or the user cancels it).
      final result = await InAppUpdate.startFlexibleUpdate();
      if (result == AppUpdateResult.success) {
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('startFlexibleUpdate failed: $e');
      }
    } finally {
      _flexibleInProgress = false;
    }
  }

  // ─── Launch hook ─────────────────────────────────────────────────────────────
  /// Fire-and-forget launch check. If Play has a newer version, posts the
  /// "Update available" notification (throttled). It never forces a full-screen
  /// update and never blocks launch — the download is the user's choice, taken
  /// from the notification or Settings → Check for updates.
  Future<void> checkAndNotifyOnLaunch() async {
    try {
      final info = await InAppUpdate.checkForUpdate();

      // A staged flexible download from a previous session just needs a
      // restart — nudge the user toward finishing it.
      if (info.installStatus == InstallStatus.downloaded) {
        await _maybeNotify(info.availableVersionCode, ready: true);
        return;
      }

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await _maybeNotify(info.availableVersionCode, ready: false);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Launch update check failed (expected off-Play): $e');
      }
    }
  }

  /// Posts the update notification, throttled to once per 24h and re-armed by a
  /// new version code.
  Future<void> _maybeNotify(int? versionCode, {required bool ready}) async {
    final lastMs = sharedPrefs.getInt(_prefLastNotifiedMs) ?? 0;
    final lastVersion = sharedPrefs.getInt(_prefLastNotifiedVersion) ?? -1;
    final now = DateTime.now().millisecondsSinceEpoch;

    final isNewVersion = versionCode != null && versionCode != lastVersion;
    final dayElapsed =
        now - lastMs >= const Duration(hours: 24).inMilliseconds;

    // Show it for a version we've never nudged about, or once a day thereafter.
    if (!isNewVersion && !dayElapsed) return;

    await NotificationService.instance.showUpdateAvailable(ready: ready);

    await sharedPrefs.setInt(_prefLastNotifiedMs, now);
    if (versionCode != null) {
      await sharedPrefs.setInt(_prefLastNotifiedVersion, versionCode);
    }
  }
}

/// Outcome of a manual [UpdateService.checkForUpdate] tap.
enum UpdateCheckStatus {
  /// A newer version is live on the Play Store.
  updateAvailable,

  /// The installed build is already the newest one on Play.
  upToDate,

  /// A flexible update finished downloading earlier and is staged, waiting
  /// only for a restart to install.
  readyToInstall,

  /// The check couldn't run: the build was installed outside Google Play, Play
  /// services are missing, or the API errored. Whether an update exists is
  /// unknown.
  unavailable,
}

/// Result of [UpdateService.checkForUpdate].
class UpdateCheckResult {
  const UpdateCheckResult(
    this.status, {
    this.flexibleAllowed = false,
    this.availableVersionCode,
  });

  final UpdateCheckStatus status;

  /// Whether Play will allow the background flexible flow for this update.
  final bool flexibleAllowed;

  /// The version code Play is offering when [status] is
  /// [UpdateCheckStatus.updateAvailable]. Informational only.
  final int? availableVersionCode;
}
