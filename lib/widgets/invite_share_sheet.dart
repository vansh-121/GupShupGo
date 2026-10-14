import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_chat_app/l10n/app_localizations.dart';
import 'package:video_chat_app/theme/app_theme.dart';

const String _kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.gupshupgo.app';

/// The link we invite people with: the user's public profile when they have a
/// handle (so a tap lands on *them*), otherwise the Play Store listing.
String _inviteLink(String? handle) =>
    (handle != null && handle.trim().isNotEmpty)
        ? 'https://gupshupgo.app/u/${handle.trim()}'
        : _kPlayStoreUrl;

/// Opens the "Invite friends" sheet: share a link, copy it, or share a
/// ready-made Instagram-story image. [handle] is the user's @username (no @),
/// or null if unset.
Future<void> showInviteShareSheet(BuildContext context, {String? handle}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _InviteShareSheet(handle: handle),
  );
}

class _InviteShareSheet extends StatefulWidget {
  const _InviteShareSheet({required this.handle});
  final String? handle;

  @override
  State<_InviteShareSheet> createState() => _InviteShareSheetState();
}

class _InviteShareSheetState extends State<_InviteShareSheet> {
  // Wraps the full-size (1080×1920) story card so it can be rasterised to a
  // PNG regardless of how small it's previewed.
  final _cardKey = GlobalKey();
  bool _busy = false;

  String get _link => _inviteLink(widget.handle);

  String _message(AppLocalizations t) => t.inviteMessage(_link);

  Future<void> _shareLink() async {
    await Share.share(_message(AppLocalizations.of(context)));
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _link));
    if (!mounted) return;
    final t = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(t.inviteLinkCopied),
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _shareImage() async {
    if (_busy) return;
    setState(() => _busy = true);
    final t = AppLocalizations.of(context);
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      // The card's own logical size is 1080×1920, so pixelRatio 1.0 yields a
      // native story-sized PNG even though it's previewed much smaller.
      final image = await boundary.toImage(pixelRatio: 1.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = await File('${dir.path}/gupshupgo_invite.png')
          .writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: _message(t),
      );
    } catch (_) {
      // Best-effort: a capture/share failure just leaves the sheet open.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    final t = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    // Preview width tuned so the 9:16 card and the buttons both fit a short
    // screen without scrolling.
    final previewW = (media.size.width * 0.42).clamp(150.0, 230.0);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: 16 + media.viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              t.inviteSheetTitle,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: c.textHigh,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t.inviteSheetSubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12.5, color: c.textMid),
            ),
            const SizedBox(height: 16),

            // ── Story-card preview (also the rasterisation source) ──
            SizedBox(
              width: previewW,
              height: previewW * 16 / 9,
              child: FittedBox(
                fit: BoxFit.contain,
                child: RepaintBoundary(
                  key: _cardKey,
                  child: _StoryCard(handle: widget.handle),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ── Primary: share the ready-made image ──
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: c.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _busy ? null : _shareImage,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.ios_share_rounded, size: 18),
                label: Text(
                  t.inviteShareImageBtn,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.textHigh,
                      side: BorderSide(color: c.border),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: _busy ? null : _shareLink,
                    icon: const Icon(Icons.link_rounded, size: 18),
                    label: Text(
                      t.inviteShareLinkBtn,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.textHigh,
                      side: BorderSide(color: c.border),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: _busy ? null : _copyLink,
                    icon: const Icon(Icons.content_copy_rounded, size: 16),
                    label: Text(
                      t.inviteCopyLinkBtn,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The branded 1080×1920 share card. Fixed logical size so it rasterises to a
/// native Instagram-story resolution; previewed scaled-down via a FittedBox.
class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.handle});
  final String? handle;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final hasHandle = handle != null && handle!.trim().isNotEmpty;
    final qrData = _inviteLink(handle);

    return SizedBox(
      width: 1080,
      height: 1920,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6C5CE7), Color(0xFF845EC2), Color(0xFFD65DB1)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(96, 150, 96, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(56),
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  width: 220,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'GupShupGo',
                style: GoogleFonts.poppins(
                  fontSize: 92,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                t.inviteCardTagline,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 44,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.92),
                  height: 1.3,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 440,
                      padding: EdgeInsets.zero,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF4A1A6B),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.circle,
                        color: Color(0xFF2A1F4E),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      hasHandle ? '@${handle!.trim()}' : t.inviteCardScan,
                      style: GoogleFonts.poppins(
                        fontSize: 46,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4A1A6B),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 56),
                  const SizedBox(width: 12),
                  Text(
                    t.inviteCardDownload,
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
