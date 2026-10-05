import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// Acquires the device's current position and asks the user to confirm before
/// returning it, as a plain `(latitude, longitude)` record.
///
/// This is the single source of truth for the "share a pin" acquire + confirm
/// flow, used by both the online chat (`ChatScreen`) and the offline mesh chat
/// (`MeshChatScreen`). Keeping the sensitive permission handling and the
/// confirmation UI in one place means a fix to either can never drift between
/// the two transports. Returning a record rather than a geolocator `Position`
/// keeps that package a private detail of this file.
///
/// Returns null — after showing a snackbar explaining which — when:
///   • location services (the OS GPS toggle) are off,
///   • permission is denied or blocked,
///   • the fix fails or times out, or
///   • the user cancels the confirmation sheet.
///
/// so callers only ever handle the non-null, user-confirmed case. The position
/// is **never returned silently:** location is the most sensitive thing this app
/// transmits, so the fetched coordinate and its accuracy are shown in a
/// confirmation sheet first, and nothing is returned until the user taps Send.
Future<({double latitude, double longitude})?> pickLocationToShare(
    BuildContext context) async {
  Position position;
  try {
    // 1. Location services (the OS-level GPS toggle) must be on — a
    //    permission grant is meaningless while they're off.
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (context.mounted) {
        _snack(context, 'Turn on location services to share a pin.');
      }
      return null;
    }

    // 2. Permission. `whileInUse` is all a one-shot pin needs; we never ask
    //    for background/"always".
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      if (context.mounted) {
        _snack(
          context,
          perm == LocationPermission.deniedForever
              ? 'Location is blocked. Enable it in Settings to share a pin.'
              : 'Location permission is needed to share a pin.',
        );
      }
      return null;
    }

    // 3. Fix. Show an indeterminate spinner while the GPS settles — a first
    //    fix can take a few seconds. Timeout so a device that never gets one
    //    fails cleanly instead of hanging the sheet open.
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );
    } finally {
      // Drop the spinner however the fix turns out.
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  } catch (e) {
    if (context.mounted) _snack(context, "Couldn't get your location.");
    return null;
  }

  // The try/catch above returns on any failure, so reaching here means the
  // fix succeeded.
  if (!context.mounted) return null;

  // 4. Confirm before anything is returned.
  final confirmed = await _confirmLocationSend(context, position);
  if (confirmed != true) return null;

  return (latitude: position.latitude, longitude: position.longitude);
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Bottom sheet that shows the fetched coordinate and its accuracy and asks
/// the user to confirm. Returns true only on an explicit Send tap.
Future<bool?> _confirmLocationSend(BuildContext context, Position position) {
  final c = AppThemeColors.of(context);
  final coords = '${position.latitude.toStringAsFixed(5)}, '
      '${position.longitude.toStringAsFixed(5)}';
  final accuracy = position.accuracy > 0
      ? 'Accurate to about ${position.accuracy.round()} m'
      : null;

  return showModalBottomSheet<bool>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.location_on_rounded, color: c.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Share your location',
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(coords,
                            style: GoogleFonts.poppins(
                                fontSize: 12.5, color: c.textMid)),
                        if (accuracy != null) ...[
                          const SizedBox(height: 1),
                          Text(accuracy,
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: c.textLow)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(sheetContext, true),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Send'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
