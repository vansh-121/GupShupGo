import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/main.dart';
import 'package:video_chat_app/screens/mesh_chat_screen.dart';
import 'package:video_chat_app/services/mesh_network_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// Lists nearby devices discovered over the mesh network and lets the user start
/// an offline peer-to-peer chat with any of them.
///
/// Pixel-perfect Google Stitch design overhaul with animated radar waves,
/// glowing avatar rings, dynamic Light & Dark mode support, and 100% preserved functionality.
class NearbyPeersScreen extends StatefulWidget {
  const NearbyPeersScreen({super.key});

  @override
  State<NearbyPeersScreen> createState() => _NearbyPeersScreenState();
}

class _NearbyPeersScreenState extends State<NearbyPeersScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _nameController;
  late final AnimationController _pulseController;
  bool _editingName = false;

  @override
  void initState() {
    super.initState();
    final mesh = Provider.of<MeshNetworkService>(context, listen: false);
    _nameController = TextEditingController(text: mesh.displayName);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    if (!mesh.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => mesh.start());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final mesh = Provider.of<MeshNetworkService>(context, listen: false);
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    sharedPrefs.setString('mesh_guest_name', name);
    mesh.updateDisplayName(name);
    setState(() => _editingName = false);
    if (mesh.isActive) await mesh.restart();
  }

  Future<void> _toggleMesh() async {
    final mesh = Provider.of<MeshNetworkService>(context, listen: false);
    if (mesh.isActive) {
      await mesh.stop();
    } else {
      await mesh.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppThemeColors.of(context);
    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.textHigh, size: 18),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Offline Chat',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: c.textHigh,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded, color: c.textMid, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Searching nearby devices…')),
              );
            },
          ),
          Consumer<MeshNetworkService>(
            builder: (_, mesh, __) => IconButton(
              tooltip: mesh.isActive ? 'Stop offline chat' : 'Start offline chat',
              icon: Icon(
                mesh.isActive
                    ? Icons.stop_circle_outlined
                    : Icons.play_circle_outline,
                color: mesh.isActive ? c.error : c.primary,
                size: 22,
              ),
              onPressed: _toggleMesh,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Consumer<MeshNetworkService>(
        builder: (_, mesh, __) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Hero Scanner Card with Radar Circles Background
                _buildStitchHeroCard(c, mesh),
                const SizedBox(height: 24),

                // 2. Devices Nearby Section Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Devices Nearby',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: c.textHigh,
                        ),
                      ),
                      Row(
                        children: [
                          if (mesh.isActive) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c.online,
                                boxShadow: [
                                  BoxShadow(
                                    color: c.online.withOpacity(0.4),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            mesh.isActive ? 'DISCOVERY ON' : 'DISCOVERY OFF',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                              color: mesh.isActive ? c.primary : c.textMid,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Peers List / Discovered Cards
                _buildPeerSection(c, mesh),
                const SizedBox(height: 20),

                // 4. Help Info Callout Card
                _buildHelpTipCard(c),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── 1. Hero Scanner Card (Stitch Radar Style) ──────────────────────────────
  Widget _buildStitchHeroCard(AppThemeColors c, MeshNetworkService mesh) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: c.surfaceAlt,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: c.border, width: 1.2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Custom Radar Background Painter
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RadarRingsPainter(
                      ringColor: c.primary,
                      pulseValue: mesh.isActive ? _pulseController.value : 0.5,
                    ),
                  ),
                ),
                // Card Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
                  child: Column(
                    children: [
                      // Signal Badge Container
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.primary.withOpacity(0.12),
                          border: Border.all(
                            color: c.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.sensors_rounded,
                          color: c.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Title
                      Text(
                        'Offline Mode',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: c.textHigh,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: c.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              mesh.isActive ? '${mesh.peers.length} nearby' : 'Offline Chat Off',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: c.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Description Subtitle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Scanning for devices within 100 meters. Connections are encrypted and peer-to-peer.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: c.textMid,
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Display Name Editor Tag
                      _buildNameTag(c),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Display Name Tag ───────────────────────────────────────────────────────
  Widget _buildNameTag(AppThemeColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline_rounded, color: c.textMid, size: 15),
          const SizedBox(width: 6),
          _editingName
              ? SizedBox(
                  width: 130,
                  child: TextField(
                    controller: _nameController,
                    autofocus: true,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: c.textHigh,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: 'Your name',
                    ),
                    onSubmitted: (_) => _saveName(),
                  ),
                )
              : Text(
                  _nameController.text.isEmpty ? 'Anonymous' : _nameController.text,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: c.textHigh,
                  ),
                ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () {
              if (_editingName) {
                _saveName();
              } else {
                setState(() => _editingName = true);
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                _editingName ? Icons.check_rounded : Icons.edit_rounded,
                color: c.primary,
                size: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Devices Nearby List ────────────────────────────────────────────────
  Widget _buildPeerSection(AppThemeColors c, MeshNetworkService mesh) {
    final peers = mesh.peers;

    if (mesh.startError == MeshStartError.permissionsDenied) {
      return _buildPermissionsDeniedState(c, mesh);
    }

    if (peers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: c.surfaceAlt,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.border, width: 1),
        ),
        child: Column(
          children: [
            Icon(Icons.radar_rounded, size: 38, color: c.textLow),
            const SizedBox(height: 10),
            Text(
              mesh.isActive ? 'Searching for devices nearby…' : 'Offline Chat is Off',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: c.textHigh,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mesh.isActive
                  ? 'Ensure GupShupGo is open on nearby devices with Bluetooth active.'
                  : 'Tap the start icon top right to begin scanning.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12, color: c.textMid),
            ),
          ],
        ),
      );
    }

    return Column(
      children: peers.map((peer) => _buildStitchPeerCard(peer, c)).toList(),
    );
  }

  // ── Stitch Peer Card with Avatar Glowing Ring ────────────────────────────
  Widget _buildStitchPeerCard(MeshPeer peer, AppThemeColors c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border, width: 1),
      ),
      child: Row(
        children: [
          // Avatar inside Blue Glowing Outline Ring (Stitch Style)
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: peer.isConnected ? c.online : c.primary,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: c.primary.withOpacity(0.12),
              child: Text(
                peer.displayName.isNotEmpty ? peer.displayName[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(
                  color: c.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name and Subtitle Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peer.displayName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                    color: c.textHigh,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  peer.isConnected ? 'Connected · Tap to chat' : 'Tap to Connect',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: peer.isConnected ? c.online : c.textMid,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Action Pill Button (Connect / Chat)
          OutlinedButton(
            onPressed: () {
              if (peer.isConnected) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MeshChatScreen(peer: peer),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Connecting to ${peer.displayName}…'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: peer.isConnected ? c.primary : c.border,
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              peer.isConnected ? 'Chat' : 'Connect',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: peer.isConnected ? c.primary : c.textHigh,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Permissions Denied Card ────────────────────────────────────────────────
  Widget _buildPermissionsDeniedState(AppThemeColors c, MeshNetworkService mesh) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.error.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_outline_rounded, size: 38, color: c.error),
          const SizedBox(height: 10),
          Text(
            'Permissions Needed',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: c.textHigh,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Offline chat requires nearby-device and Bluetooth access to discover devices without internet.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12, color: c.textMid),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => mesh.start(),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => openAppSettings(),
                icon: const Icon(Icons.settings_outlined, size: 16),
                label: const Text('Settings'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: c.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 3. Help Tip Callout Card ──────────────────────────────────────────────
  Widget _buildHelpTipCard(AppThemeColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: c.textMid, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Don\'t see your friend? Ensure Bluetooth is enabled on both devices.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: c.textMid,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom Painter for Hero Radar Waves ─────────────────────────────────────
class _RadarRingsPainter extends CustomPainter {
  final Color ringColor;
  final double pulseValue;

  _RadarRingsPainter({required this.ringColor, required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 54);
    final baseRadii = [60.0, 105.0, 150.0];

    for (int i = 0; i < baseRadii.length; i++) {
      final radius = baseRadii[i] + (i + 1) * 3.0 * pulseValue;
      final opacity = (0.12 - (i * 0.035)).clamp(0.015, 0.15);

      final paint = Paint()
        ..color = ringColor.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarRingsPainter oldDelegate) =>
      oldDelegate.ringColor != ringColor || oldDelegate.pulseValue != pulseValue;
}
