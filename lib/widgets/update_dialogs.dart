// The update prompts, in one place.
//
// These used to live inline in SettingsScreen, reachable only by tapping
// "Check for updates". They are shared now because the launch gate has to show
// *the same dialog* the button shows — a user who is told about an update on
// open and then sees a different-looking dialog from Settings has been shown
// two things, not one thing twice.
//
// Each dialog owns its own actions (start the download, open the store), so a
// call site is a single await with nothing to wire up.

import 'package:flutter/material.dart';

import 'package:video_chat_app/services/update_service.dart';
import 'package:video_chat_app/services/version_policy.dart';
import 'package:video_chat_app/utils/url_opener.dart';

/// Offers Google Play's background download. [flexibleAllowed] comes from
/// [UpdateCheckResult.flexibleAllowed]; when Play refuses the flexible flow
/// (rare — a high-priority release, say) the download button would silently
/// no-op, so the store listing is offered instead of a button that does
/// nothing.
Future<void> showUpdateAvailableDialog(
  BuildContext context, {
  required bool flexibleAllowed,
}) {
  if (!flexibleAllowed) {
    return showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Update available'),
        content: const Text(
          'A new version of GupShupGo is available on the Google Play Store. '
          'Open the store listing to update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              openExternalUrl(context, UpdateService.playStoreUrl);
            },
            child: const Text('Open Play Store'),
          ),
        ],
      ),
    );
  }

  return showDialog<void>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Update available'),
      content: const Text(
        'A new version of GupShupGo is ready. It downloads in the background '
        'while you keep using the app, then installs with a quick restart.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogCtx);
            _startFlexibleUpdate(context);
          },
          child: const Text('Update'),
        ),
      ],
    ),
  );
}

/// A flexible download from an earlier session finished and is staged; all
/// that is left is the restart.
Future<void> showUpdateReadyDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Update ready'),
      content: const Text(
        'An update has finished downloading. Restart GupShupGo to finish '
        'installing it.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogCtx);
            _startFlexibleUpdate(context);
          },
          child: const Text('Restart & install'),
        ),
      ],
    ),
  );
}

/// The countdown warning for a build that is scheduled to stop working.
///
/// On the last few days the barrier stops being dismissible: at that point an
/// accidental tap outside the dialog is the difference between updating and
/// being locked out tomorrow, so the user is made to choose.
Future<void> showVersionExpiringDialog(
  BuildContext context,
  VersionPolicy policy,
) {
  final days = policy.daysLeft;
  final title = days == null
      ? 'Update required soon'
      : days == 1
          ? 'This version stops working tomorrow'
          : 'This version stops working in $days days';

  final body = days == null
      ? 'This version of GupShupGo is no longer supported and will stop '
          'working soon. Update now to avoid losing access to your chats.'
      : 'You need to update GupShupGo to keep using it. After '
          '${days == 1 ? 'tomorrow' : '$days days'} this version will stop '
          'working, and you will have to update before you can open your '
          'chats again.';

  return showDialog<void>(
    context: context,
    barrierDismissible: days == null || days > 3,
    builder: (dialogCtx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogCtx);
            _startFlexibleUpdate(context);
          },
          child: const Text('Update now'),
        ),
      ],
    ),
  );
}

/// Kicks off the background download and tells the user it is happening —
/// Play's flexible flow is deliberately invisible, so without this the
/// "Update" button looks like it did nothing.
void _startFlexibleUpdate(BuildContext context) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.showSnackBar(
    const SnackBar(
      content: Text('Starting update — it downloads in the background.'),
    ),
  );
  UpdateService.instance.startFlexibleUpdate();
}
