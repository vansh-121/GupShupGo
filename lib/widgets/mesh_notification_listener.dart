import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_chat_app/main.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/screens/mesh_chat_screen.dart';
import 'package:video_chat_app/services/mesh_network_service.dart';

/// Wraps the entire navigator and renders a top-of-screen banner whenever
/// an offline-mesh message arrives for the user while they're not on the
/// matching chat screen.
///
/// Mounted via [MaterialApp.builder] so the banner sits above every route.
class MeshNotificationListener extends StatefulWidget {
  final Widget child;
  const MeshNotificationListener({Key? key, required this.child})
      : super(key: key);

  @override
  State<MeshNotificationListener> createState() =>
      _MeshNotificationListenerState();
}

class _MeshNotificationListenerState extends State<MeshNotificationListener> {
  StreamSubscription<MessageModel>? _sub;
  Timer? _dismissTimer;
  MessageModel? _current;
  // Pending messages while a banner is on screen — shown one after another
  // so a burst of arrivals doesn't lose any.
  final List<MessageModel> _queue = [];
  // De-dupe across hot reload + duplicate stream emissions.
  final Set<String> _shownIds = {};
  // Track the last service instance so we can resubscribe if it changes.
  MeshNetworkService? _mesh;

  static const _bannerDuration = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    // Actual subscription is set up in didChangeDependencies (called right
    // after initState) so that re-subscriptions are handled automatically if
    // the Provider value ever changes.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mesh = Provider.of<MeshNetworkService>(context, listen: false);
    if (_mesh == mesh) return; // Already subscribed to this instance.
    _sub?.cancel();
    _mesh = mesh;
    _sub = mesh.meshMessageStream.listen(
      _onMessage,
      // Prevent stream errors from silently killing the subscription.
      onError: (Object e) =>
          debugPrint('[MeshNotif] Stream error (staying subscribed): $e'),
      cancelOnError: false,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _onMessage(MessageModel msg) {
    try {
      if (!mounted) return;
      final mesh = Provider.of<MeshNetworkService>(context, listen: false);

      debugPrint(
        '[MeshNotif] received msg=${msg.id} from=${msg.senderId} '
        'active=${mesh.activeConversationUserId} current=${_current?.id}',
      );

      // Guard against own-loopback (defensive — upstream already filters).
      if (msg.senderId == mesh.currentUserId) return;

      // Suppress when the user is already viewing this conversation.
      if (mesh.activeConversationUserId == msg.senderId) return;

      // Drop duplicates (e.g., relay paths that re-emit before dedup catches).
      if (_shownIds.contains(msg.id)) return;
      _shownIds.add(msg.id);

      if (_current == null) {
        _showBanner(msg);
      } else {
        _queue.add(msg);
      }
    } catch (e) {
      debugPrint('[MeshNotif] Error handling message: $e');
    }
  }

  void _showBanner(MessageModel msg) {
    setState(() => _current = msg);
    _dismissTimer?.cancel();
    _dismissTimer = Timer(_bannerDuration, _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    if (_queue.isNotEmpty) {
      // Promote the next queued message instead of going blank.
      final next = _queue.removeAt(0);
      _showBanner(next);
    } else {
      setState(() => _current = null);
    }
  }

  // Manual close: drop everything queued so the user isn't surprised by
  // another banner sliding in right after they tapped X.
  void _dismissAll() {
    if (!mounted) return;
    _queue.clear();
    _dismissTimer?.cancel();
    setState(() => _current = null);
  }

  void _openConversation() {
    final msg = _current;
    if (msg == null) return;
    _dismiss();

    // Try to resolve the senderId to a currently-discovered peer so we can
    // open the mesh chat directly. If the peer is no longer in range, the
    // banner just dismisses.
    final mesh = Provider.of<MeshNetworkService>(context, listen: false);
    MeshPeer? peer;
    for (final p in mesh.peers) {
      if (p.userId == msg.senderId) {
        peer = p;
        break;
      }
    }
    if (peer == null) return;

    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute(
      builder: (_) => MeshChatScreen(peer: peer!),
    ));
  }

  String _previewFor(MessageModel msg) {
    switch (msg.type) {
      case MessageType.image:
        return '📷 Photo';
      case MessageType.audio:
        return '🎤 Voice message';
      case MessageType.video:
        return '🎬 Video';
      case MessageType.text:
        return msg.text;
    }
  }

  String _senderNameFor(MessageModel msg, MeshNetworkService mesh) {
    for (final p in mesh.peers) {
      if (p.userId == msg.senderId) return p.displayName;
    }
    return 'Nearby device';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        if (_current != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: _MeshBanner(
                key: ValueKey(_current!.id),
                message: _current!,
                senderName: _senderNameFor(
                    _current!,
                    Provider.of<MeshNetworkService>(context, listen: false)),
                preview: _previewFor(_current!),
                onTap: _openConversation,
                onDismiss: _dismissAll,
              ),
            ),
          ),
      ],
    );
  }
}

class _MeshBanner extends StatefulWidget {
  final MessageModel message;
  final String senderName;
  final String preview;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _MeshBanner({
    Key? key,
    required this.message,
    required this.senderName,
    required this.preview,
    required this.onTap,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<_MeshBanner> createState() => _MeshBannerState();
}

class _MeshBannerState extends State<_MeshBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: widget.onTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4ADE80),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cell_tower_rounded,
                        color: Colors.black, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.senderName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              'Offline chat',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF4ADE80),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white70, size: 18),
                    splashRadius: 18,
                    onPressed: widget.onDismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
