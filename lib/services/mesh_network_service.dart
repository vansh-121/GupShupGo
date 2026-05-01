import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:path_provider/path_provider.dart';
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

/// Tracks an incoming file payload until the transfer completes.
class _PendingFileTransfer {
  final String messageId;
  final Map<String, dynamic> messageJson;
  final String fileName;

  _PendingFileTransfer({
    required this.messageId,
    required this.messageJson,
    required this.fileName,
  });
}

/// Reason the most recent [MeshNetworkService.start] call did not result
/// in an active session — used by the UI to surface actionable error states.
enum MeshStartError {
  none,
  permissionsDenied,
  unknown,
}

/// Public-facing record of a peer discovered or connected via mesh.
class MeshPeer {
  final String endpointId;
  final String userId;
  final String displayName;
  final bool isConnected;

  const MeshPeer({
    required this.endpointId,
    required this.userId,
    required this.displayName,
    required this.isConnected,
  });

  MeshPeer copyWith({String? endpointId, String? userId, String? displayName, bool? isConnected}) {
    return MeshPeer(
      endpointId: endpointId ?? this.endpointId,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      isConnected: isConnected ?? this.isConnected,
    );
  }
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

  // ─── Peer discovery state ────────────────────────────────────────────
  /// Peers discovered (or connected) via mesh, keyed by endpointId.
  final Map<String, MeshPeer> _peers = {};
  List<MeshPeer> get peers => List.unmodifiable(_peers.values);

  /// Emits whenever the peer list changes.
  final StreamController<List<MeshPeer>> _peersController =
      StreamController<List<MeshPeer>>.broadcast();
  Stream<List<MeshPeer>> get peersStream => _peersController.stream;

  /// Friendly name shown to other devices when advertising.
  String _displayName = 'Anonymous';
  String get displayName => _displayName;

  /// Outcome of the last [start] attempt. Reset to [MeshStartError.none]
  /// every time [start] succeeds.
  MeshStartError _startError = MeshStartError.none;
  MeshStartError get startError => _startError;

  /// userId of the conversation the user is currently viewing. While set,
  /// the global notification listener suppresses banners for messages from
  /// this peer (the chat screen already shows them in-line).
  String? _activeConversationUserId;
  String? get activeConversationUserId => _activeConversationUserId;
  void setActiveConversation(String? userId) {
    _activeConversationUserId = userId;
  }

  /// Currently signed-in (or guest) userId — exposed read-only for the
  /// global notification listener which needs to filter own messages.
  String get currentUserId => _currentUserId;

  // ─── File transfer tracking ──────────────────────────────────────
  /// Maps file-payload-id → metadata for incoming file transfers.
  final Map<int, _PendingFileTransfer> _pendingFileTransfers = {};

  /// Maps file-payload-id → received file URI (from onPayloadReceived).
  final Map<int, String> _receivedFileUris = {};

  /// Payload IDs whose transfer has completed successfully.
  final Set<int> _completedFilePayloads = {};

  // ─── Dependencies ────────────────────────────────────────────────────
  String _currentUserId;
  final ChatCacheService _cacheService;
  final ConnectivityProvider _connectivityProvider;
  final ChatService _chatService = ChatService();

  MeshNetworkService({
    required String currentUserId,
    required ChatCacheService cacheService,
    required ConnectivityProvider connectivityProvider,
    String displayName = 'Anonymous',
  })  : _currentUserId = currentUserId,
        _cacheService = cacheService,
        _connectivityProvider = connectivityProvider,
        _displayName = displayName {
    // When connectivity is restored, sync pending mesh messages to Firestore.
    _connectivityProvider.addOnBackOnlineCallback(_syncPendingToFirestore);
  }

  /// Update the current user ID (called after auth completes).
  void updateUserId(String userId) {
    _currentUserId = userId;
  }

  /// Update the friendly display name shown to other devices.
  /// Returns true when the name actually changed — callers can use this to
  /// decide whether to [restart] the mesh so the new name re-broadcasts.
  bool updateDisplayName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == _displayName) return false;
    _displayName = trimmed;
    notifyListeners();
    return true;
  }

  /// Update both userId and displayName atomically and restart mesh if
  /// it was active so the new identity takes effect on the wire.
  Future<void> applyIdentity({
    required String userId,
    required String displayName,
  }) async {
    final wasActive = isActive;
    final userIdChanged = _currentUserId != userId;
    final nameChanged = updateDisplayName(displayName);
    if (userIdChanged) _currentUserId = userId;
    if (wasActive && (userIdChanged || nameChanged)) {
      await restart();
    }
  }

  /// Resolve the userId for a given peer endpoint, or null if unknown.
  String? userIdForEndpoint(String endpointId) =>
      _peers[endpointId]?.userId;

  /// Encode userId + displayName into the single string Nearby Connections
  /// uses for the advertising / discovering identity.
  String _encodeIdentity() => '$_currentUserId|$_displayName';

  /// Parse an advertised identity back into (userId, displayName).
  ({String userId, String displayName}) _decodeIdentity(String raw) {
    final i = raw.indexOf('|');
    if (i < 0) return (userId: raw, displayName: raw);
    return (userId: raw.substring(0, i), displayName: raw.substring(i + 1));
  }

  void _publishPeers() {
    _peersController.add(peers);
    notifyListeners();
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
      Permission.location, // required by Nearby Connections on Android
    ];

    // NEARBY_WIFI_DEVICES was introduced in Android 13 (API 33).
    // On Android 12 and below this permission doesn't exist and the
    // permission_handler plugin will always report it as denied.
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        permissions.add(Permission.nearbyWifiDevices);
      }
    }

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
    if (_isAdvertising && _isDiscovering) {
      _startError = MeshStartError.none;
      return;
    }

    // Request runtime permissions first (Android 12+)
    final granted = await _requestPermissions();
    if (!granted) {
      debugPrint('[Mesh] Cannot start — permissions not granted');
      _startError = MeshStartError.permissionsDenied;
      notifyListeners();
      return;
    }

    await _startAdvertising();
    await _startDiscovering();

    if (!_isAdvertising && !_isDiscovering) {
      _startError = MeshStartError.unknown;
    } else {
      _startError = MeshStartError.none;
    }
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
    _peers.clear();
    // Clear dedup set so restarted sessions accept all messages fresh.
    _seenMessageIds.clear();
    // Discard in-flight file transfers — they won't complete after stop.
    _pendingFileTransfers.clear();
    _receivedFileUris.clear();
    _completedFilePayloads.clear();
    _publishPeers();
  }

  /// Restart advertising + discovering — needed when displayName changes
  /// after [start] has already been called.
  Future<void> restart() async {
    await stop();
    await start();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Advertising
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _startAdvertising() async {
    try {
      _isAdvertising = await Nearby().startAdvertising(
        _encodeIdentity(),
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
        _encodeIdentity(),
        _strategy,
        onEndpointFound: (endpointId, endpointName, serviceId) {
          final id = _decodeIdentity(endpointName);
          debugPrint('[Mesh] Found peer: ${id.displayName} ($endpointId)');
          _peers[endpointId] = MeshPeer(
            endpointId: endpointId,
            userId: id.userId,
            displayName: id.displayName,
            isConnected: false,
          );
          _publishPeers();
          Nearby().requestConnection(
            _encodeIdentity(),
            endpointId,
            onConnectionInitiated: _onConnectionInitiated,
            onConnectionResult: _onConnectionResult,
            onDisconnected: _onDisconnected,
          );
        },
        onEndpointLost: (endpointId) {
          debugPrint('[Mesh] Lost endpoint: $endpointId');
          _connectedEndpoints.remove(endpointId);
          _peers.remove(endpointId);
          _publishPeers();
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
    // Capture peer identity from the advertised name (covers the advertiser
    // side, where onEndpointFound never fires).
    final id = _decodeIdentity(info.endpointName);
    final existing = _peers[endpointId];
    _peers[endpointId] = MeshPeer(
      endpointId: endpointId,
      userId: id.userId,
      displayName: id.displayName,
      isConnected: existing?.isConnected ?? false,
    );
    _publishPeers();

    // Auto-accept all connections for mesh relay
    Nearby().acceptConnection(
      endpointId,
      onPayLoadRecieved: (endpointId, payload) {
        _handlePayload(endpointId, payload);
      },
      onPayloadTransferUpdate: (endpointId, update) {
        _handlePayloadTransferUpdate(endpointId, update);
      },
    );
  }

  void _onConnectionResult(String endpointId, Status status) {
    if (status == Status.CONNECTED) {
      _connectedEndpoints.add(endpointId);
      final existing = _peers[endpointId];
      if (existing != null) {
        _peers[endpointId] = existing.copyWith(isConnected: true);
      }
      debugPrint('[Mesh] Connected to $endpointId (${connectedPeers} peers)');
    } else {
      _connectedEndpoints.remove(endpointId);
      _peers.remove(endpointId);
      debugPrint('[Mesh] Connection failed with $endpointId: $status');
    }
    _publishPeers();
  }

  void _onDisconnected(String endpointId) {
    _connectedEndpoints.remove(endpointId);
    _peers.remove(endpointId);
    debugPrint('[Mesh] Disconnected from $endpointId (${connectedPeers} peers)');
    _publishPeers();

    // The Nearby SDK does NOT re-fire onEndpointFound when a connection drops
    // while the peer is still in range — so auto-reconnect is the only path
    // back without the peer going fully out of range and returning.
    if (isActive) _scheduleReconnect(endpointId);
  }

  void _scheduleReconnect(String endpointId) {
    Future.delayed(const Duration(seconds: 2), () async {
      // Bail if mesh was stopped or peer already reconnected via other path.
      if (!isActive || _connectedEndpoints.contains(endpointId)) return;
      debugPrint('[Mesh] Auto-reconnect attempt → $endpointId');
      try {
        await Nearby().requestConnection(
          _encodeIdentity(),
          endpointId,
          onConnectionInitiated: _onConnectionInitiated,
          onConnectionResult: _onConnectionResult,
          onDisconnected: _onDisconnected,
        );
      } catch (e) {
        debugPrint('[Mesh] Auto-reconnect failed for $endpointId: $e');
      }
    });
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

  /// Send an image file via the mesh network.
  /// Returns a [MessageModel] with [localFilePath] set to the picked image.
  Future<MessageModel> sendImageViaMesh({
    required String receiverId,
    required String filePath,
    String? senderName,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('Image file does not exist: $filePath');
    }

    // Copy the image to app-local storage so it survives temp cleanup.
    final appDir = await getApplicationDocumentsDirectory();
    final meshImagesDir = Directory('${appDir.path}/mesh_images');
    if (!meshImagesDir.existsSync()) {
      meshImagesDir.createSync(recursive: true);
    }
    final ext = filePath.contains('.') ? filePath.split('.').last : 'jpg';
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${_generateId()}.$ext';
    final savedFile = await file.copy('${meshImagesDir.path}/$fileName');

    final message = MessageModel(
      id: _generateId(),
      senderId: _currentUserId,
      receiverId: receiverId,
      text: '📷 Photo',
      type: MessageType.image,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      localFilePath: savedFile.path,
      isOfflineMesh: true,
      meshHops: 0,
      syncPending: true,
    );

    // Store locally for persistence & Firestore sync
    _cacheService.storePendingMeshMessage(message);
    _seenMessageIds.add(message.id);

    // For each connected peer:
    //  1. Send the FILE payload (returns its payloadId).
    //  2. Send a BYTES metadata payload so receiver can match file → message.
    for (final endpoint in _connectedEndpoints) {
      try {
        final filePayloadId =
            await Nearby().sendFilePayload(endpoint, savedFile.path);

        final metadata = <String, dynamic>{
          'payloadType': 'file_metadata',
          'filePayloadId': filePayloadId,
          'fileName': fileName,
          'messageId': message.id,
          'messageJson': message.toJson(),
          'hops': 0,
          'ttl': maxHops,
        };
        final bytes = utf8.encode(jsonEncode(metadata));
        await Nearby().sendBytesPayload(endpoint, bytes);
      } catch (e) {
        debugPrint('[Mesh] Failed to send image to $endpoint: $e');
      }
    }

    return message;
  }

  /// Send an audio voice note via the mesh network.
  /// Returns a [MessageModel] with [localFilePath] set to the recorded audio.
  Future<MessageModel> sendAudioViaMesh({
    required String receiverId,
    required String filePath,
    required int durationSeconds,
    String? senderName,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('Audio file does not exist: $filePath');
    }

    // Copy the audio to app-local storage so it survives temp cleanup.
    final appDir = await getApplicationDocumentsDirectory();
    final meshAudioDir = Directory('${appDir.path}/mesh_audio');
    if (!meshAudioDir.existsSync()) {
      meshAudioDir.createSync(recursive: true);
    }
    final ext = filePath.contains('.') ? filePath.split('.').last : 'm4a';
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${_generateId()}.$ext';
    final savedFile = await file.copy('${meshAudioDir.path}/$fileName');

    final message = MessageModel(
      id: _generateId(),
      senderId: _currentUserId,
      receiverId: receiverId,
      text: '🎤 Voice message',
      type: MessageType.audio,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      localFilePath: savedFile.path,
      audioDuration: durationSeconds,
      isOfflineMesh: true,
      meshHops: 0,
      syncPending: true,
    );

    // Store locally for persistence & Firestore sync
    _cacheService.storePendingMeshMessage(message);
    _seenMessageIds.add(message.id);

    // For each connected peer:
    //  1. Send the FILE payload (returns its payloadId).
    //  2. Send a BYTES metadata payload so receiver can match file → message.
    for (final endpoint in _connectedEndpoints) {
      try {
        final filePayloadId =
            await Nearby().sendFilePayload(endpoint, savedFile.path);

        final metadata = <String, dynamic>{
          'payloadType': 'file_metadata',
          'filePayloadId': filePayloadId,
          'fileName': fileName,
          'messageId': message.id,
          'messageJson': message.toJson(),
          'hops': 0,
          'ttl': maxHops,
        };
        final bytes = utf8.encode(jsonEncode(metadata));
        await Nearby().sendBytesPayload(endpoint, bytes);
      } catch (e) {
        debugPrint('[Mesh] Failed to send audio to $endpoint: $e');
      }
    }

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
    // ── Handle incoming FILE payloads (image data) ────────────────────
    if (payload.type == PayloadType.FILE) {
      final uri = payload.uri;
      if (uri != null) {
        // Store the URI keyed by payloadId. The file is NOT ready yet —
        // we must wait for onPayloadTransferUpdate with SUCCESS.
        _receivedFileUris[payload.id] = uri;
      }
      return;
    }

    if (payload.type != PayloadType.BYTES || payload.bytes == null) return;

    try {
      final jsonStr = utf8.decode(payload.bytes!);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      // ── File metadata bytes ─────────────────────────────────────────
      if (data['payloadType'] == 'file_metadata') {
        _handleFileMetadata(data);
        return;
      }

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
  // File transfer helpers
  // ═══════════════════════════════════════════════════════════════════════

  /// Handle the bytes-metadata that accompanies a file payload.
  void _handleFileMetadata(Map<String, dynamic> data) {
    final int filePayloadId = data['filePayloadId'] ?? -1;
    final String messageId = data['messageId'] ?? '';
    final String fileName = data['fileName'] ?? '';
    final Map<String, dynamic> messageJson =
        Map<String, dynamic>.from(data['messageJson'] ?? {});

    if (filePayloadId == -1 || messageId.isEmpty) return;

    // Dedup
    if (_seenMessageIds.contains(messageId)) return;

    _pendingFileTransfers[filePayloadId] = _PendingFileTransfer(
      messageId: messageId,
      messageJson: messageJson,
      fileName: fileName,
    );

    // The file may have already arrived before this metadata.
    _tryCompleteFileTransfer(filePayloadId);
  }

  /// Called on every payload transfer progress update.
  void _handlePayloadTransferUpdate(
      String endpointId, PayloadTransferUpdate update) {
    if (update.status == PayloadStatus.SUCCESS) {
      _completedFilePayloads.add(update.id);
      _tryCompleteFileTransfer(update.id);
    } else if (update.status == PayloadStatus.FAILURE ||
        update.status == PayloadStatus.CANCELED) {
      _pendingFileTransfers.remove(update.id);
      _receivedFileUris.remove(update.id);
      _completedFilePayloads.remove(update.id);
      debugPrint('[Mesh] File transfer ${update.id} failed/cancelled');
    }
  }

  /// Attempt to finalise a file transfer once we have the metadata,
  /// the file URI, AND the transfer has completed successfully.
  Future<void> _tryCompleteFileTransfer(int payloadId) async {
    final meta = _pendingFileTransfers[payloadId];
    final uri = _receivedFileUris[payloadId];
    final isComplete = _completedFilePayloads.contains(payloadId);
    if (meta == null || uri == null || !isComplete) return; // not ready yet

    try {
      // Move the received file to a permanent app-local directory.
      final appDir = await getApplicationDocumentsDirectory();
      final meshImagesDir = Directory('${appDir.path}/mesh_images');
      if (!meshImagesDir.existsSync()) {
        meshImagesDir.createSync(recursive: true);
      }
      final destPath = '${meshImagesDir.path}/${meta.fileName}';

      await Nearby().copyFileAndDeleteOriginal(uri, destPath);

      // Build the MessageModel with the local file path.
      final message = MessageModel.fromJson(meta.messageJson).copyWith(
        localFilePath: destPath,
        isOfflineMesh: true,
        meshHops: (meta.messageJson['meshHops'] ?? 0) + 1,
      );

      _seenMessageIds.add(meta.messageId);

      // Is this message for us?
      if (message.receiverId == _currentUserId) {
        _incomingMeshMessages.add(message);
        _meshMessageController.add(message);
        _cacheService.storePendingMeshMessage(message);
        debugPrint('[Mesh] Received image for me: ${meta.fileName}');
      }

      // Clean up tracking maps.
      _pendingFileTransfers.remove(payloadId);
      _receivedFileUris.remove(payloadId);
      _completedFilePayloads.remove(payloadId);
      notifyListeners();
    } catch (e) {
      debugPrint('[Mesh] Error completing file transfer $payloadId: $e');
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
          String? mediaUrl = msg.mediaUrl;

          // If this is an image with a local file, upload it first.
          if (msg.type == MessageType.image &&
              msg.localFilePath != null &&
              mediaUrl == null) {
            mediaUrl = await _uploadLocalFile(msg, 'chat_images', 'jpg');
          }

          // If this is an audio voice note with a local file, upload it.
          if (msg.type == MessageType.audio &&
              msg.localFilePath != null &&
              mediaUrl == null) {
            mediaUrl = await _uploadLocalFile(msg, 'chat_audio', 'm4a');
          }

          await _chatService.sendMessage(
            senderId: msg.senderId,
            receiverId: msg.receiverId,
            text: msg.text,
            type: msg.type,
            mediaUrl: mediaUrl,
            audioDuration: msg.audioDuration,
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

  /// Upload a locally-stored mesh file (image / audio) to Firebase Storage.
  Future<String?> _uploadLocalFile(
      MessageModel msg, String folder, String fallbackExt) async {
    try {
      final file = File(msg.localFilePath!);
      if (!file.existsSync()) return null;

      final chatRoomId =
          _chatService.getChatRoomId(msg.senderId, msg.receiverId);
      final fileName =
          '${msg.timestamp.millisecondsSinceEpoch}_mesh_${msg.id}.$fallbackExt';
      final ref = FirebaseStorage.instance
          .ref()
          .child('$folder/$chatRoomId/$fileName');

      final contentType = fallbackExt == 'm4a' ? 'audio/m4a' : 'image/jpeg';
      final metadata = SettableMetadata(contentType: contentType);

      await ref.putFile(file, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('[Mesh] Failed to upload file for ${msg.id}: $e');
      return null;
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
    _peersController.close();
    super.dispose();
  }
}
