import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:video_chat_app/screens/public_profile_screen.dart';
import 'package:video_chat_app/services/deep_link_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// Camera scanner for GupShupGo profile QR codes.
///
/// Completes the QR feature: the app could already *display* a profile code
/// (Contacts → QR icon) and could already *handle* the resulting
/// `https://gupshupgo.app/u/<handle>` link (see [DeepLinkService] and the
/// autoVerify intent filter in AndroidManifest.xml), but nothing could read
/// one, so "Friends can scan this QR code" was not actually true.
///
/// A scanned code is validated with [DeepLinkService.extractUsername] — the
/// same parser the deep-link path uses — and then routed to
/// [PublicProfileScreen], which resolves the handle and offers the usual
/// connect / message actions.
class QrScannerScreen extends StatefulWidget {
  final String currentUserId;
  final String? currentUserName;

  const QrScannerScreen({
    super.key,
    required this.currentUserId,
    this.currentUserName,
  });

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

enum _PermissionPhase { checking, granted, denied, permanentlyDenied }

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  // A controller is supplied explicitly (rather than letting MobileScanner
  // create its own) because this screen needs the torch toggle and needs to
  // stop the camera the instant a valid code is found. The trade-off is that
  // MobileScanner's built-in `useAppLifecycleState` handling only applies to
  // a controller it owns — so pausing/resuming on background is handled by
  // this State via WidgetsBindingObserver. Without that, the camera would
  // keep streaming while the app sits in the background.
  MobileScannerController? _controller;

  _PermissionPhase _phase = _PermissionPhase.checking;

  /// Latches on the first accepted code. onDetect fires continuously while a
  /// code is in frame, so without this the screen would push a stack of
  /// identical profile routes.
  bool _handled = false;

  /// Shown for codes that scan cleanly but aren't GupShupGo profile links.
  String? _rejectMessage;
  Timer? _rejectTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resolvePermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rejectTimer?.cancel();
    // MobileScanner stops a supplied controller on its own dispose, but never
    // disposes it — that's this screen's responsibility.
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final controller = _controller;
    if (controller == null || _phase != _PermissionPhase.granted) return;

    switch (state) {
      case AppLifecycleState.resumed:
        if (!_handled) unawaited(controller.start());
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        unawaited(controller.stop());
        break;
    }
  }

  Future<void> _resolvePermission() async {
    // Requested via permission_handler rather than relying on the plugin's
    // implicit request, so a permanent denial can be told apart from a plain
    // "not now" and routed to app settings.
    final status = await ph.Permission.camera.request();
    if (!mounted) return;

    setState(() {
      if (status.isGranted || status.isLimited) {
        _phase = _PermissionPhase.granted;
        _controller = MobileScannerController(
          // Only QR — narrowing the formats avoids spending frames looking
          // for barcode symbologies this feature can't use.
          formats: const [BarcodeFormat.qrCode],
          detectionSpeed: DetectionSpeed.noDuplicates,
        );
      } else if (status.isPermanentlyDenied || status.isRestricted) {
        _phase = _PermissionPhase.permanentlyDenied;
      } else {
        _phase = _PermissionPhase.denied;
      }
    });
  }

  void _showReject(String message) {
    _rejectTimer?.cancel();
    setState(() => _rejectMessage = message);
    _rejectTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _rejectMessage = null);
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.trim().isEmpty) continue;

      final uri = Uri.tryParse(raw.trim());
      final username =
          uri == null ? null : DeepLinkService.extractUsername(uri);

      if (username == null) {
        // Wrong kind of QR code (a URL, wifi config, plain text...). Keep
        // scanning rather than closing the screen.
        _showReject('That\'s not a GupShupGo profile code.');
        return;
      }

      _handled = true;
      unawaited(_controller?.stop());
      _openProfile(username);
      return;
    }
  }

  Future<void> _openProfile(String username) async {
    // Replace rather than push: popping back to a live camera that has
    // already latched `_handled` would present a scanner that ignores codes.
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          username: username,
          currentUserId: widget.currentUserId,
          currentUserName: widget.currentUserName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Scan QR Code',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        actions: [
          if (_phase == _PermissionPhase.granted && _controller != null)
            ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller!,
              builder: (context, state, _) {
                if (state.torchState == TorchState.unavailable) {
                  return const SizedBox.shrink();
                }
                final on = state.torchState == TorchState.on;
                return IconButton(
                  tooltip: on ? 'Turn off flash' : 'Turn on flash',
                  icon: Icon(
                    on ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: on ? c.primary : Colors.white,
                  ),
                  onPressed: () => unawaited(_controller!.toggleTorch()),
                );
              },
            ),
        ],
      ),
      body: switch (_phase) {
        _PermissionPhase.checking => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        _PermissionPhase.granted => _buildScanner(c),
        _PermissionPhase.denied => _buildPermissionState(
            c,
            message: 'Camera access is needed to scan QR codes.',
            actionLabel: 'Allow camera',
            onAction: _resolvePermission,
          ),
        _PermissionPhase.permanentlyDenied => _buildPermissionState(
            c,
            message:
                'Camera access is blocked. Enable it in Settings to scan QR codes.',
            actionLabel: 'Open settings',
            onAction: () => unawaited(ph.openAppSettings()),
          ),
      },
    );
  }

  Widget _buildScanner(AppThemeColors c) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error, child) => _buildCameraError(c, error),
          fit: BoxFit.cover,
        ),
        _buildReticle(c),
        Positioned(
          left: 24,
          right: 24,
          bottom: 48,
          child: Column(
            children: [
              if (_rejectMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _rejectMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Text(
                'Point your camera at a GupShupGo profile QR code',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReticle(AppThemeColors c) {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: c.primary, width: 3),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Widget _buildCameraError(AppThemeColors c, MobileScannerException error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off_rounded,
                size: 48, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              'Couldn\'t start the camera.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.errorDetails?.message ?? 'Please try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionState(
    AppThemeColors c, {
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_photography_rounded,
                size: 48, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                actionLabel,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
