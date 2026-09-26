import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_update/in_app_update.dart';

import 'package:video_chat_app/main.dart' show sharedPrefs;
import 'package:video_chat_app/services/notification_service.dart';
import 'package:video_chat_app/services/version_policy.dart';
import 'package:video_chat_app/widgets/update_dialogs.dart';

/// Google Play In-App Updates, in the **flexible** (non-blocking) style.
///
/// The old behaviour forced a full-screen immediate update on launch. We now
/// nudge instead of block:
///  • On launch, [runLaunchPrompts] shows the same "Update available" dialog
///    the Settings button shows (throttled), and — ahead of it — the expiry
///    warning when this build is on its way out. It never blocks the app.
///  • The Settings "Check for updates" button ([checkForUpdate]) reports the
///    status on demand and lets the user opt in.
///  • [checkAndNotifyOnLaunch] posts the "Update available" *notification*
///    instead, for the launches that have no screen to put a dialog on (the
///    user is sitting on the login screen).
///  • Every one of those paths runs [startFlexibleUpdate]: Play downloads the
///    update in the background while the app stays usable, then installs it
///    with a quick restart the user consents to.
///  • The one exception is [startImmediateUpdate], used only by
///    `UnsupportedVersionScreen`, where blocking *is* the intent.
///
/// ⚠ Works only when the app was installed from Google Play. Debug and
/// sideloaded builds get `ERROR_API_NOT_AVAILABLE` from the Play API — that is
/// expected and surfaces as [UpdateCheckStatus.unavailable].
class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  /// The store listing, used wherever the in-app Play API can't be reached.
  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.gupshupgo.app';

  /// Guards against launching a second flexible flow while one is already in
  /// flight (e.g. the user taps the button and the notification in quick
  /// succession).
  bool _flexibleInProgress = false;

  // The "Update available" nudge is throttled so a user who ignores it doesn't
  // get it on every single cold start: at most once a day, and again whenever
  // Play starts offering a genuinely different version code.
  static const _prefLastNotifiedMs = 'pref_update_notif_last_ms';
  static const _prefLastNotifiedVersion = 'pref_update_notif_version';

  // The launch dialog keeps its own throttle rather than sharing the
  // notification's. They fire in different circumstances (signed in vs not) and
  // a dialog the user dismissed should not also cost them the notification they
  // would otherwise have got on the next launch.
  static const _prefLastDialogMs = 'pref_update_dialog_last_ms';
  static const _prefLastDialogVersion = 'pref_update_dialog_version';

  /// How long the launch dialog stays quiet for a version the user has already
  /// been offered and declined.
  static const _dialogInterval = Duration(hours: 24);

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
        return UpdateCheckResult(
          UpdateCheckStatus.readyToInstall,
          availableVersionCode: info.availableVersionCode,
        );
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

  // ─── Immediate (blocking) update ────────────────────────────────────────────
  /// Hands the screen to Google Play for a full-screen, user-can't-proceed
  /// update. Reserved for `UnsupportedVersionScreen` — everywhere else the
  /// flexible flow is the right one.
  ///
  /// Returns `false` when Play can't run it (sideloaded build, no Play
  /// Services, nothing to update to, user backed out), which is the caller's
  /// cue to fall back to the store listing. On success Play restarts the app
  /// itself, so a `true` return is mostly theoretical.
  Future<bool> startImmediateUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable ||
          !info.immediateUpdateAllowed) {
        return false;
      }
      final result = await InAppUpdate.performImmediateUpdate();
      return result == AppUpdateResult.success;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('startImmediateUpdate failed (expected off-Play): $e');
      }
      return false;
    }
  }

  // ─── Launch hook ─────────────────────────────────────────────────────────────
  /// The prompt the user actually sees on open, and the reason the launch check
  /// is no longer notification-only.
  ///
  /// Runs two checks in priority order, and shows **at most one** dialog:
  ///  1. The supported-version policy. A build that is expiring gets the
  ///     countdown warning, on an escalating cadence. A build that is already
  ///     unsupported gets nothing here — `_AuthGate` renders
  ///     `UnsupportedVersionScreen` in place of the whole app instead.
  ///  2. Otherwise Play's ordinary "there is a newer version" offer, throttled
  ///     to once a day per version code so it nudges rather than nags.
  ///
  /// The ordering matters: being told "you have 3 days left" is strictly more
  /// important than being told "an update exists", and stacking both would be
  /// two dialogs saying the same thing.
  ///
  /// Never throws, and safe to call when the app was not installed from Play.
  Future<void> runLaunchPrompts(BuildContext context) async {
    // Cheap, local, no network: safe to run on every open and every resume.
    final policy = await VersionPolicyService.instance.evaluateAndLatch();

    // Already out of support — the gate owns that case, not a dialog.
    if (policy.blocks) return;

    if (policy.warns) {
      final versions = VersionPolicyService.instance;
      if (!versions.shouldWarn(policy)) return;
      await versions.markWarned();
      if (!context.mounted) return;
      await showVersionExpiringDialog(context, policy);
      return;
    }

    final result = await checkForUpdate();
    if (!context.mounted) return;

    // That was a network round-trip, and Remote Config may have landed during
    // it — in which case `_AuthGate` is already swapping the block screen in
    // and a dialog would push on top of it. Cheap local re-check.
    if (VersionPolicyService.instance.evaluate().blocks) return;

    switch (result.status) {
      case UpdateCheckStatus.updateAvailable:
        if (!await _claimDialogSlot(result.availableVersionCode)) return;
        if (!context.mounted) return;
        await showUpdateAvailableDialog(
          context,
          flexibleAllowed: result.flexibleAllowed,
        );

      case UpdateCheckStatus.readyToInstall:
        // A staged download is a one-tap restart away from being installed, so
        // it gets the same daily budget rather than a free pass on every open.
        if (!await _claimDialogSlot(result.availableVersionCode)) return;
        if (!context.mounted) return;
        await showUpdateReadyDialog(context);

      case UpdateCheckStatus.upToDate:
      case UpdateCheckStatus.unavailable:
        break;
    }
  }

  /// Throttles the launch dialog: at most once per [_dialogInterval], re-armed
  /// whenever Play starts offering a different version code. Records the slot
  /// as used when it returns `true`.
  Future<bool> _claimDialogSlot(int? versionCode) async {
    final lastMs = sharedPrefs.getInt(_prefLastDialogMs) ?? 0;
    final lastVersion = sharedPrefs.getInt(_prefLastDialogVersion) ?? -1;
    final now = DateTime.now().millisecondsSinceEpoch;

    final isNewVersion = versionCode != null && versionCode != lastVersion;
    // abs(): a clock moved backwards should not mute the prompt until it
    // catches up again.
    final intervalElapsed =
        (now - lastMs).abs() >= _dialogInterval.inMilliseconds;

    if (!isNewVersion && !intervalElapsed) return false;

    await sharedPrefs.setInt(_prefLastDialogMs, now);
    if (versionCode != null) {
      await sharedPrefs.setInt(_prefLastDialogVersion, versionCode);
    }
    return true;
  }

  /// Fire-and-forget launch check for the launches [runLaunchPrompts] can't
  /// serve — the user is on the login screen, so there is no home screen to put
  /// a dialog on. If Play has a newer version, posts the "Update available"
  /// notification (throttled). It never forces a full-screen update and never
  /// blocks launch — the download is the user's choice, taken from the
  /// notification or Settings → Check for updates.
  Future<void> checkAndNotifyOnLaunch() async {
    try {
      final info = await InAppUpdate.checkForUpdate();

      // A staged flexible download from a previous session just needs a
      // restart — nudge the user toward finishing it.
      if (info.installStatus == InstallStatus.downloaded) {
        await _maybeNotify(info.availableVersionCode, ready: true);
        return;
      }

      // Only nudge when Play will actually run the flexible flow. If flexible
      // isn't allowed (e.g. a high-priority update Play restricts to the
      // immediate path this app doesn't use), the notification would dead-end
      // in startFlexibleUpdate's no-op — so stay quiet rather than post an
      // un-actionable "Update available".
      if (info.updateAvailability == UpdateAvailability.updateAvailable &&
          info.flexibleUpdateAllowed) {
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
  /// [UpdateCheckStatus.updateAvailable] or [UpdateCheckStatus.readyToInstall].
  /// Informational, and the key the launch dialog's throttle is armed against.
  final int? availableVersionCode;
}
