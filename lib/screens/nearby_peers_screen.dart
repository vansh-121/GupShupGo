import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/main.dart';
import 'package:video_chat_app/screens/mesh_chat_screen.dart';
import 'package:video_chat_app/services/mesh_network_service.dart';
import 'package:video_chat_app/theme/app_theme.dart';

/// Lists nearby devices discovered over the mesh and lets the user start
/// an offline peer-to-peer chat with any of them.
///
/// Works both pre-auth (from the login screen, when the user has no
/// internet to log in) and post-auth (an entry point in the home screen).
class NearbyPeersScreen extends StatefulWidget {
  const NearbyPeersScreen({Key? key}) : super(key: key);

  @override
  State<NearbyPeersScreen> createState() => _NearbyPeersScreenState();
}

class _NearbyPeersScreenState extends State<NearbyPeersScreen> {
  late final TextEditingController _nameController;
  bool _editingName = false;

  @override
  void initState() {
    super.initState();
    final mesh = Provider.of<MeshNetworkService>(context, listen: false);
    _nameController = TextEditingController(text: mesh.displayName);
    // Auto-start mesh on entry — that's the whole point of this screen.
    if (!mesh.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => mesh.start());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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
        title: Text('Offline Chat',
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: c.textHigh)),
        actions: [
          Consumer<MeshNetworkService>(
            builder: (_, mesh, __) => IconButton(
              tooltip: mesh.isActive ? 'Stop offline chat' : 'Start offline chat',
              icon: Icon(
                mesh.isActive
                    ? Icons.stop_circle_outlined
                    : Icons.play_circle_outline,
                color: mesh.isActive ? c.error : c.primary,
              ),
              onPressed: _toggleMesh,
            ),
          ),
        ],
      ),
      body: Consumer<MeshNetworkService>(
        builder: (_, mesh, __) {
          return Column(
            children: [
              _buildHeaderCard(c, mesh),
              Expanded(child: _buildPeerList(c, mesh)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(AppThemeColors c, MeshNetworkService mesh) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C5CE7), Color(0xFF9B8FF0)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cell_tower_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mesh.isActive
                      ? 'Offline chat is on · ${mesh.connectedPeers} connected'
                      : 'Offline chat is off',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${mesh.peers.length} nearby',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'No internet? Chat with people nearby — works fully offline.',
            style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.9), fontSize: 12),
          ),
          const SizedBox(height: 14),
          _buildNameField(),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Row(
      children: [
        const Icon(Icons.person_outline_rounded,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: _editingName
              ? TextField(
                  controller: _nameController,
                  autofocus: true,
                  cursorColor: Colors.white,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    isDense: true,
                    border: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    hintText: 'Your name',
                    hintStyle:
                        GoogleFonts.poppins(color: Colors.white60),
                  ),
                  onSubmitted: (_) => _saveName(),
                )
              : Text(
                  _nameController.text.isEmpty
                      ? 'Anonymous'
                      : _nameController.text,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
        ),
        IconButton(
          icon: Icon(
            _editingName ? Icons.check_rounded : Icons.edit_rounded,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () {
            if (_editingName) {
              _saveName();
            } else {
              setState(() => _editingName = true);
            }
          },
        ),
      ],
    );
  }

  Widget _buildPeerList(AppThemeColors c, MeshNetworkService mesh) {
    final peers = mesh.peers;
    if (peers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: c.primaryLt,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.radar_rounded, size: 48, color: c.primary),
              ),
              const SizedBox(height: 20),
              Text(
                mesh.isActive
                    ? 'Looking for people nearby…'
                    : 'Offline chat is off',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.textHigh,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mesh.isActive
                    ? 'Make sure the other person also has GupShupGo open with offline chat turned on.'
                    : 'Tap the start button above to find people nearby.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: c.textMid),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: peers.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: c.divider, indent: 72),
      itemBuilder: (_, i) => _buildPeerTile(peers[i], c),
    );
  }

  Widget _buildPeerTile(MeshPeer peer, AppThemeColors c) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: c.primaryLt,
            child: Text(
              peer.displayName.isNotEmpty
                  ? peer.displayName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: c.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          if (peer.isConnected)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: c.online,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        peer.displayName,
        style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: c.textHigh),
      ),
      subtitle: Text(
        peer.isConnected ? 'Connected · tap to chat' : 'Connecting…',
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: peer.isConnected ? c.online : c.textMid,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: c.textLow),
      onTap: peer.isConnected
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MeshChatScreen(peer: peer),
                ),
              );
            }
          : null,
    );
  }
}
