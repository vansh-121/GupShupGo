// The end of the line for a retired build.
//
// Rendered *instead of* the app — see `_AuthGate.build` — rather than pushed on
// top of it. That distinction is the whole point: there is no route underneath
// to pop back to, no navigator state to get clever with, and nothing to
// dismiss. A user on an unsupported build simply does not have an app until
// they update.
//
// The back button is left alone on purpose. Trapping it would mean a user who
// cannot update right now (no Play Store, metered connection, 2% battery) has
// no way out of the screen except force-stopping the app, and being unable to
// *leave* is a different and worse thing than being unable to *use*.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:video_chat_app/services/update_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';
import 'package:video_chat_app/utils/url_opener.dart';

class UnsupportedVersionScreen extends StatefulWidget {
  const UnsupportedVersionScreen({super.key});

  @override
  State<UnsupportedVersionScreen> createState() =>
      _UnsupportedVersionScreenState();
}

class _UnsupportedVersionScreenState extends State<UnsupportedVersionScreen> {
  bool _busy = false;

  /// Play's immediate flow takes over the screen and restarts the app itself,
  /// so the happy path never comes back here. Anything that *does* come back
  /// has failed — the build was sideloaded, Play Services are missing, the user
  /// backed out — and the store listing is the fallback that still works when
  /// the in-app API does not.
  Future<void> _update() async {
    if (_busy) return;
    setState(() => _busy = true);

    final started = await UpdateService.instance.startImmediateUpdate();
    if (!mounted) return;
    setState(() => _busy = false);
    if (started) return;

    await openExternalUrl(context, UpdateService.playStoreUrl);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);

    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.system_update_rounded,
                    size: 44,
                    color: c.primary,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Update GupShupGo',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: c.textHigh,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This version of GupShupGo is no longer supported. Update to '
                  'the latest version to keep chatting — your messages and '
                  'chats are safe and will be there when you come back.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.55,
                    color: c.textMid,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _update,
                    style: FilledButton.styleFrom(
                      backgroundColor: c.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Update now',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () =>
                          openExternalUrl(context, UpdateService.playStoreUrl),
                  child: Text(
                    'Open Play Store',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: c.textMid,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
