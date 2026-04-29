import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/provider/connectivity_provider.dart';
import 'package:video_chat_app/services/chat_cache_service.dart';
import 'package:video_chat_app/services/chat_service.dart';

/// Mesh message wrapper for relay / dedup across peers.
class _MeshPayload {
  final String messageId;
  final Map<String, dynamic> messageJson;
  final int hops;
  final int ttl; // max hops allowed

  _MeshPayload({
    required this.messageId,
    required this.messageJson,
    required this.hops,
    this.ttl = 3,
  });

  Map<String, dynamic> toJson() => {
        'messageId': messageId,
        'messageJson': messageJson,
        'hops': hops,
        'ttl': ttl,
      };

  factory _MeshPayload.fromJson(Map<String, dynamic> map) => _MeshPayload(
        messageId: map['messageId'] ?? '',
        messageJson: Map<String, dynamic>.from(map['messageJson'] ?? {}),
        hops: map['hops'] ?? 0,
        ttl: map['ttl'] ?? 3,
      );

  bool get canRelay => hops < ttl;
}

/// The MeshNetworkService advertises the current device and discovers nearby
/// peers using Google Nearby Connections (Bluetooth + WiFi Direct).
///
/// When the device is offline, messages are:
///   1. Stored locally via [ChatCacheService].
///   2. Broadcast to all discovered nearby peers.
///   3. Peers relay them forward (store-and-forward) up to [maxHops].
///
/// When connectivity returns, all pending messages are flushed to Firestore.
class MeshNetworkService extends ChangeNotifier {
  // ─── Config ──────────────────────────────────────────────────────────
  static const int maxHops = 3;
  static const Strategy _strategy = Strategy.P2P_CLUSTER;
  static const String _serviceId = 'com.gupshupgo.mesh';

  // ─── State ───────────────────────────────────────────────────────────
  bool _isAdvertising = false;
  bool _isDiscovering = false;
  bool get isActive => _isAdvertising || _isDiscovering;

  final Set<String> _connectedEndpoints = {};
  int get connectedPeers => _connectedEndpoints.length;

  /// IDs of messages already seen — prevents relay loops.
  final Set<String> _seenMessageIds = {};

  /// Messages received via mesh that are for the current user.
  final List<MessageModel> _incomingMeshMessages = [];
  List<MessageModel> get incomingMeshMessages =>
      List.unmodifiable(_incomingMeshMessages);

  /// Stream controller to push new mesh messages to the chat screen.
  final StreamController<MessageModel> _meshMessageController =
      StreamController<MessageModel>.broadcast();
  Stream<MessageModel> get meshMessageStream => _meshMessageController.stream;

  // ─── Dependencies ────────────────────────────────────────────────────
  String _currentUserId;
  final ChatCacheService _cacheService;
  final ConnectivityProvider _connectivityProvider;
  final ChatService _chatService = ChatService();

  MeshNetworkService({
    required String currentUserId,
    required ChatCacheService cacheService,
    required ConnectivityProvider connectivityProvider,
  })  : _currentUserId = currentUserId,
        _cacheService = cacheService,
        _connectivityProvider = connectivityProvider {
    // When connectivity is restored, sync pending mesh messages to Firestore.
    _connectivityProvider.addOnBackOnlineCallback(_syncPendingToFirestore);
  }

  /// Update the current user ID (called after auth completes).
  void updateUserId(String userId) {
    _currentUserId = userId;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Start / Stop
  // ═══════════════════════════════════════════════════════════════════════

  /// Request all Bluetooth / WiFi / Location permissions needed for mesh.
  /// Returns true if all critical permissions were granted.
  Future<bool> _requestPermissions() async {
    final permissions = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
      Permission.location, // required by Nearby Connections on Android
    ];

    final statuses = await permissions.request();

    final allGranted = statuses.values
        .every((s) => s.isGranted || s.isLimited);

    if (!allGranted) {
      debugPrint('[Mesh] Some permissions denied: $statuses');
    }
    return allGranted;
  }

  /// Start advertising + discovering nearby peers simultaneously.
  Future<void> start() async {
    if (_isAdvertising && _isDiscovering) return;

    // Request runtime permissions first (Android 12+)
    final granted = await _requestPermissions();
    if (!granted) {
      debugPrint('[Mesh] Cannot start — permissions not granted');
      return;
    }

    await _startAdvertising();
    await _startDiscovering();
    notifyListeners();
  }

  Future<void> stop() async {
    if (_isAdvertising) {
      await Nearby().stopAdvertising();
      _isAdvertising = false;
    }
    if (_isDiscovering) {
      await Nearby().stopDiscovery();
      _isDiscovering = false;
    }
    _connectedEndpoints.clear();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Advertising
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _startAdvertising() async {
    try {
      _isAdvertising = await Nearby().startAdvertising(
        _currentUserId,
        _strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: _serviceId,
      );
    } catch (e) {
      debugPrint('[Mesh] Advertising error: $e');
      _isAdvertising = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Discovery
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _startDiscovering() async {
    try {
      _isDiscovering = await Nearby().startDiscovery(
        _currentUserId,
        _strategy,
        onEndpointFound: (endpointId, endpointName, serviceId) {
          debugPrint('[Mesh] Found peer: $endpointName ($endpointId)');
          Nearby().requestConnection(
            _currentUserId,
            endpointId,
            onConnectionInitiated: _onConnectionInitiated,
            onConnectionResult: _onConnectionResult,
            onDisconnected: _onDisconnected,
          );
        },
        onEndpointLost: (endpointId) {
          debugPrint('[Mesh] Lost endpoint: $endpointId');
        },
        serviceId: _serviceId,
      );
    } catch (e) {
      debugPrint('[Mesh] Discovery error: $e');
      _isDiscovering = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Connection callbacks
  // ═══════════════════════════════════════════════════════════════════════

  void _onConnectionInitiated(String endpointId, ConnectionInfo info) {
    debugPrint('[Mesh] Connection initiated with ${info.endpointName}');
    // Auto-accept all connections for mesh relay
    Nearby().acceptConnection(
      endpointId,
      onPayLoadRecieved: (endpointId, payload) {
        _handlePayload(endpointId, payload);
      },
    );
  }

  void _onConnectionResult(String endpointId, Status status) {
    if (status == Status.CONNECTED) {
      _connectedEndpoints.add(endpointId);
      debugPrint('[Mesh] Connected to $endpointId (${connectedPeers} peers)');
    } else {
      _connectedEndpoints.remove(endpointId);
      debugPrint('[Mesh] Connection failed with $endpointId: $status');
    }
    notifyListeners();
  }

  void _onDisconnected(String endpointId) {
    _connectedEndpoints.remove(endpointId);
    debugPrint('[Mesh] Disconnected from $endpointId (${connectedPeers} peers)');
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Sending via Mesh
  // ═══════════════════════════════════════════════════════════════════════

  /// Send a text message via the mesh network.
  /// The message is also stored locally as pending for Firestore sync.
  Future<MessageModel> sendViaMesh({
    required String receiverId,
    required String text,
    String? senderName,
  }) async {
    final message = MessageModel(
      id: _generateId(),
      senderId: _currentUserId,
      receiverId: receiverId,
      text: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      isOfflineMesh: true,
      meshHops: 0,
      syncPending: true,
    );

    // Store locally
    _cacheService.storePendingMeshMessage(message);

    // Mark as seen to prevent relay loops
    _seenMessageIds.add(message.id);

    // Broadcast to all connected peers
    final payload = _MeshPayload(
      messageId: message.id,
      messageJson: message.toJson(),
      hops: 0,
    );
    await _broadcastToAllPeers(payload);

    return message;
  }

  /// Broadcast a mesh payload to every connected endpoint.
  Future<void> _broadcastToAllPeers(_MeshPayload payload) async {
    final bytes = utf8.encode(jsonEncode(payload.toJson()));
    for (final endpoint in _connectedEndpoints) {
      try {
        await Nearby().sendBytesPayload(endpoint, bytes);
      } catch (e) {
        debugPrint('[Mesh] Failed to send to $endpoint: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Receiving via Mesh
  // ═══════════════════════════════════════════════════════════════════════

  void _handlePayload(String endpointId, Payload payload) {
    if (payload.type != PayloadType.BYTES || payload.bytes == null) return;

    try {
      final jsonStr = utf8.decode(payload.bytes!);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final meshPayload = _MeshPayload.fromJson(data);

      // Dedup: skip if we've already seen this message
      if (_seenMessageIds.contains(meshPayload.messageId)) return;
      _seenMessageIds.add(meshPayload.messageId);

      final message = MessageModel.fromJson(meshPayload.messageJson).copyWith(
        meshHops: meshPayload.hops + 1,
        isOfflineMesh: true,
      );

      // Is this message for us?
      if (message.receiverId == _currentUserId) {
        _incomingMeshMessages.add(message);
        _meshMessageController.add(message);
        // Also store locally so it persists across app restarts
        _cacheService.storePendingMeshMessage(message);
        debugPrint('[Mesh] Received message for me: ${message.text}');
      }

      // Relay forward if TTL allows (store-and-forward)
      if (meshPayload.canRelay) {
        final relayPayload = _MeshPayload(
          messageId: meshPayload.messageId,
          messageJson: meshPayload.messageJson,
          hops: meshPayload.hops + 1,
          ttl: meshPayload.ttl,
        );
        _broadcastToAllPeers(relayPayload);
        debugPrint('[Mesh] Relaying message ${message.id} (hop ${relayPayload.hops})');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[Mesh] Error handling payload: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Sync pending messages to Firestore when back online
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _syncPendingToFirestore() async {
    final pending = _cacheService.getPendingMeshMessages();
    if (pending.isEmpty) return;

    debugPrint('[Mesh] Syncing ${pending.length} pending messages to Firestore');

    final synced = <String>[];

    for (final msg in pending) {
      try {
        // Only sync messages that we sent (not relayed ones for other users)
        if (msg.senderId == _currentUserId) {
          await _chatService.sendMessage(
            senderId: msg.senderId,
            receiverId: msg.receiverId,
            text: msg.text,
            type: msg.type,
            mediaUrl: msg.mediaUrl,
          );
        }
        synced.add(msg.id);
      } catch (e) {
        debugPrint('[Mesh] Failed to sync message ${msg.id}: $e');
      }
    }

    if (synced.isNotEmpty) {
      _cacheService.removeSyncedMeshMessages(synced);
      debugPrint('[Mesh] Synced ${synced.length} messages');
      notifyListeners();
    }
  }

  /// Manually trigger sync (e.g., from a UI button).
  Future<void> syncNow() => _syncPendingToFirestore();

  // ═══════════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════════

  String _generateId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  @override
  void dispose() {
    stop();
    _connectivityProvider.removeOnBackOnlineCallback(_syncPendingToFirestore);
    _meshMessageController.close();
    super.dispose();
  }
}
