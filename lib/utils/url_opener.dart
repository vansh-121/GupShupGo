// Opens a URL tapped inside a chat bubble in the user's browser.
//
// Note the absence of `canLaunchUrl`. On Android 11+ (API 30) package
// visibility hides every installed app from us unless the manifest declares an
// intent query, and `canLaunchUrl` answers "false" in that state — so gating on
// it is the classic way link-opening ships looking implemented while doing
// nothing at all. We declare the ACTION_VIEW query in AndroidManifest.xml and
// then just attempt the launch, reporting the failure if one happens.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Launches [url] in the system browser. Never throws; shows a snackbar when
/// no handler could be found.
Future<void> openExternalUrl(BuildContext context, String url) async {
  // Captured before the await — the context may be gone by the time the
  // platform channel answers.
  final messenger = ScaffoldMessenger.maybeOf(context);

  try {
    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) _reportFailure(messenger);
  } catch (e) {
    if (kDebugMode) debugPrint('[UrlOpener] could not open $url: $e');
    _reportFailure(messenger);
  }
}

void _reportFailure(ScaffoldMessengerState? messenger) {
  messenger?.showSnackBar(
    const SnackBar(content: Text("Couldn't open this link")),
  );
}
