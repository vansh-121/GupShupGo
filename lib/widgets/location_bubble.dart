import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// A static location pin bubble.
///
/// **Deliberately not a map image.** Rendering a static map tile would send the
/// exact coordinate to Google's or OSM's tile servers on every build, on *both*
/// devices — handing the one thing this message encrypts to a third party the
/// moment it's displayed. So the bubble is a styled card (pin glyph,
/// coordinates to 5 decimal places, an Open-in-Maps action) with zero render
/// dependencies, zero metadata leak, and it works offline. The map only ever
/// loads in the user's own maps app, after they choose to open it.
///
/// A location message carries no media — just two doubles inside the encrypted
/// payload — so unlike a document it also travels over the mesh transport.
class LocationBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const LocationBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final lat = message.latitude;
    final lng = message.longitude;

    // A location whose payload hasn't merged yet (undecryptable / awaiting
    // resend) has no coordinates. The dispatch in chat_screen already guards on
    // `latitude != null`, so this is defensive — never render a tappable card
    // that opens maps to nowhere.
    if (lat == null || lng == null) {
      return Text(
        '📍 Location',
        style: GoogleFonts.poppins(
          color: isMe ? Colors.white : c.textHigh,
          fontSize: 14.5,
        ),
      );
    }

    final fg = isMe ? Colors.white : c.textHigh;
    final fgLow = isMe ? Colors.white.withValues(alpha: 0.75) : c.textLow;
    final coords =
        '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

    return InkWell(
      onTap: () => _openInMaps(context, lat, lng),
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 200, maxWidth: 240),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.18)
                        : c.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 24,
                    color: isMe ? Colors.white : c.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Location',
                        style: GoogleFonts.poppins(
                          color: fg,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        coords,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: fgLow,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.open_in_new_rounded, size: 13, color: fgLow),
                const SizedBox(width: 4),
                Text(
                  'Open in Maps',
                  style: GoogleFonts.poppins(
                    color: fgLow,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the pin in the user's maps app.
  ///
  /// Tries the `geo:` scheme first — on Android it hits Google Maps / any
  /// installed maps app directly, with the `q=` label dropping a pin at exactly
  /// the shared point rather than just centring there. Falls back to the
  /// universal `https://maps.google.com/?q=` URL, which every platform
  /// (including iOS and desktop) resolves.
  ///
  /// No `canLaunchUrl` gate, for the reason [openExternalUrl] documents:
  /// Android 11+ package visibility makes it answer false even when a handler
  /// exists. We attempt the launch and only report an outright failure.
  static Future<void> _openInMaps(
      BuildContext context, double lat, double lng) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final geo = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    final web = Uri.parse('https://maps.google.com/?q=$lat,$lng');

    try {
      if (await launchUrl(geo, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // geo: unsupported (common on iOS/desktop) — fall through to the web URL.
    }
    try {
      if (await launchUrl(web, mode: LaunchMode.externalApplication)) return;
    } catch (e) {
      if (kDebugMode) debugPrint('[LocationBubble] could not open maps: $e');
    }
    messenger?.showSnackBar(
      const SnackBar(content: Text("Couldn't open Maps")),
    );
  }
}
