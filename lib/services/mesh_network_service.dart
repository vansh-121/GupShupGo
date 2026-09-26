import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/provider/connectivity_provider.dart';
import 'package:video_chat_app/services/chat_cache_service.dart';
import 'package:video_chat_app/services/chat_service.dart';
import 'package:video_chat_app/services/crypto/encrypted_media_service.dart';
import 'package:video_chat_app/services/mesh_file_utils.dart';

export 'package:video_chat_app/services/mesh_file_utils.dart'
    show kMaxMeshDocumentBytes;

/// Largest video a mesh send will carry, in bytes (25 MB).
///
/// The P2P `FILE` channel has no size limit of its own and no progress bar, and
/// unlike the 64 MB online cap ([_kMaxChatVideoBytes] in chat_screen.dart) a mesh
/// clip is streamed peer-to-peer with no server compression — so it gets its own,
/// tighter ceiling. Enforced defensively inside [MeshNetworkService.sendVideoViaMesh]
/// and pre-checked by the UI so the user is told before a clip is probed.
const int kMaxMeshVideoBytes = 25 * 1024 * 1024;

/// Safe ceiling for a `file_metadata` BYTES packet. Nearby caps a BYTES payload
/// at ~32,768 bytes and overflows silently; a video's metadata embeds the base64
/// poster, so we measure the encoded packet and drop the poster from the wire if
/// it crosses this — leaving headroom for the rest of the JSON.
const int _kMeshMetaSafeBytes = 30000;

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
      debugPrint('[Mesh] Connected to $endpointId ($connectedPeers peers)');
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
    debugPrint('[Mesh] Disconnected from $endpointId ($connectedPeers peers)');
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
  ///
  /// E2EE: if the receiver has a published key bundle (i.e. they've been
  /// online recently to register) we encrypt the text into a v2 envelope
  /// before broadcasting. If not, we fall back to plaintext mesh —
  /// mesh-only deployments where peers have never had internet would
  /// otherwise be unreachable.
  Future<MessageModel> sendViaMesh({
    required String receiverId,
    required String text,
    String? senderName,
    // Link preview + reply quote. The serializers carry these across the wire
    // on their own, but the model built here has to actually hold them or an
    // offline send silently drops the card and the quote.
    String? linkPreviewUrl,
    String? linkPreviewTitle,
    String? linkPreviewDescription,
    String? linkPreviewSiteName,
    String? linkPreviewImageBase64,
    String? replyToMessageId,
    String? replyToSenderId,
    String? replyToSenderName,
    String? replyToType,
    String? replyToText,
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
      linkPreviewUrl: linkPreviewUrl,
      linkPreviewTitle: linkPreviewTitle,
      linkPreviewDescription: linkPreviewDescription,
      linkPreviewSiteName: linkPreviewSiteName,
      linkPreviewImageBase64: linkPreviewImageBase64,
      replyToMessageId: replyToMessageId,
      replyToSenderId: replyToSenderId,
      replyToSenderName: replyToSenderName,
      replyToType: replyToType,
      replyToText: replyToText,
    );

    _cacheService.storePendingMeshMessage(message);
    _seenMessageIds.add(message.id);

    final payload = _MeshPayload(
      messageId: message.id,
      messageJson: message.toJson(),
      hops: 0,
    );
    await _broadcastToAllPeers(payload);

    return message;
  }

  /// Send a location pin via the mesh network.
  ///
  /// A pin is just two doubles — no media, no Storage upload — so it rides the
  /// same BYTES channel as a text message rather than a FILE transfer. The
  /// [MessageModel.toJson] wire format already carries `latitude`/`longitude`,
  /// and the receive path rebuilds any BYTES message with
  /// [MessageModel.fromJson], so a pin renders on the far side with no
  /// receiver-side change. `text` is set to `📍 Location` as the fallback label
  /// for a client that predates the location type.
  Future<MessageModel> sendLocationViaMesh({
    required String receiverId,
    required double latitude,
    required double longitude,
    String? senderName,
  }) async {
    final message = MessageModel(
      id: _generateId(),
      senderId: _currentUserId,
      receiverId: receiverId,
      text: '📍 Location',
      type: MessageType.location,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      latitude: latitude,
      longitude: longitude,
      isOfflineMesh: true,
      meshHops: 0,
      syncPending: true,
    );

    _cacheService.storePendingMeshMessage(message);
    _seenMessageIds.add(message.id);

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
    bool viewOnce = false,
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
      viewOnce: viewOnce,
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


  /// Send a video over the mesh: streams the clip on the `FILE` channel and a
  /// companion `file_metadata` BYTES packet, exactly like [sendAudioViaMesh].
  ///
  /// [thumbnailBase64] is a small first-frame poster (see [generateMeshVideoPoster])
  /// and [durationSeconds] the clip length; both are optional and only feed the
  /// bubble label/preview. The poster is kept on the sender's stored copy, but is
  /// **stripped from the wire copy** when the metadata packet would otherwise
  /// exceed Nearby's BYTES cap ([_kMeshMetaSafeBytes]) — the file itself always
  /// crosses on the FILE channel, so the receiver still gets the clip (falling
  /// back to the film glyph).
  Future<MessageModel> sendVideoViaMesh({
    required String receiverId,
    required String filePath,
    int? durationSeconds,
    String? thumbnailBase64,
    String? senderName,
    bool viewOnce = false,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('Video file does not exist: $filePath');
    }

    // Defensive size guard — the UI pre-checks and shows a friendly message, but
    // the transport is the source of truth so an uncapped clip can't slip through.
    final length = await file.length();
    if (length > kMaxMeshVideoBytes) {
      throw Exception('Video exceeds the mesh size limit');
    }

    // Copy the video to app-local storage so it survives temp cleanup.
    final appDir = await getApplicationDocumentsDirectory();
    final meshVideoDir = Directory('${appDir.path}/mesh_videos');
    if (!meshVideoDir.existsSync()) {
      meshVideoDir.createSync(recursive: true);
    }
    final ext = filePath.contains('.') ? filePath.split('.').last : 'mp4';
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${_generateId()}.$ext';
    final savedFile = await file.copy('${meshVideoDir.path}/$fileName');

    final message = MessageModel(
      id: _generateId(),
      senderId: _currentUserId,
      receiverId: receiverId,
      text: '🎬 Video',
      type: MessageType.video,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      localFilePath: savedFile.path,
      audioDuration: durationSeconds,
      videoThumbnailBase64: thumbnailBase64,
      isOfflineMesh: true,
      meshHops: 0,
      syncPending: true,
      viewOnce: viewOnce,
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

        // The metadata packet embeds the message JSON, which for a video carries
        // the base64 poster. Encode it; if it would blow the BYTES cap, drop the
        // poster from the WIRE copy only (toJson returns a fresh map, so the
        // stored/returned message keeps its poster).
        var wireJson = message.toJson();
        final metadata = <String, dynamic>{
          'payloadType': 'file_metadata',
          'filePayloadId': filePayloadId,
          'fileName': fileName,
          'messageId': message.id,
          'messageJson': wireJson,
          'hops': 0,
          'ttl': maxHops,
        };
        var encoded = utf8.encode(jsonEncode(metadata));
        if (encoded.length > _kMeshMetaSafeBytes) {
          wireJson = Map<String, dynamic>.of(wireJson)
            ..remove('videoThumbnailBase64');
          metadata['messageJson'] = wireJson;
          encoded = utf8.encode(jsonEncode(metadata));
        }
        await Nearby().sendBytesPayload(endpoint, encoded);
      } catch (e) {
        debugPrint('[Mesh] Failed to send video to $endpoint: $e');
      }
    }

    return message;
  }


  /// Send a document over the mesh: the file streams on the `FILE` channel with a
  /// companion `file_metadata` BYTES packet, exactly like [sendAudioViaMesh] and
  /// [sendVideoViaMesh].
  ///
  /// [fileName] is the user-visible original name, and it is the one thing about a
  /// document that has to survive the trip. The stored copy is named opaquely
  /// (`${ts}_${id}.ext`, as the other three senders do), so the real name travels
  /// inside the message as [MessageModel.fileName] and is what the bubble renders —
  /// the same split the online document path uses. `text` carries that name too, as
  /// the plaintext fallback that makes a build predating documents show something
  /// instead of an empty bubble, and that feeds the reply snippet and notification.
  ///
  /// Nothing is uploaded here: a mesh document has no `mediaKey`. It is encrypted
  /// and uploaded by [_syncPendingToFirestore] when the network comes back.
  Future<MessageModel> sendDocumentViaMesh({
    required String receiverId,
    required String filePath,
    required String fileName,
    String? senderName,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('Document does not exist: $filePath');
    }

    // Defensive size guard — the UI pre-checks and shows a friendly message, but
    // the transport is the source of truth so an uncapped file can't slip through.
    final length = await file.length();
    if (length > kMaxMeshDocumentBytes) {
      throw Exception('Document exceeds the mesh size limit');
    }
    if (length == 0) {
      throw Exception('Document is empty');
    }

    // Clamp and scrub the display name here, once, so the sender's stored copy and
    // the wire copy are the same string — and so a pathological name can't be the
    // thing that pushes the metadata packet over Nearby's BYTES cap.
    final displayName = sanitiseMeshFileName(fileName);

    // Copy into app-local storage so the file survives temp cleanup: file_picker
    // hands back a cache path that Android is free to reap at any time.
    final appDir = await getApplicationDocumentsDirectory();
    final meshDocDir =
        Directory('${appDir.path}/${meshDirNameForType(MessageType.document)}');
    if (!meshDocDir.existsSync()) {
      meshDocDir.createSync(recursive: true);
    }
    final dot = displayName.lastIndexOf('.');
    final ext = (dot > 0 && displayName.length - dot <= 6)
        ? displayName.substring(dot + 1)
        : 'bin';
    final storedName =
        '${DateTime.now().millisecondsSinceEpoch}_${_generateId()}.$ext';
    final savedFile = await file.copy('${meshDocDir.path}/$storedName');

    final message = MessageModel(
      id: _generateId(),
      senderId: _currentUserId,
      receiverId: receiverId,
      text: displayName,
      type: MessageType.document,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      localFilePath: savedFile.path,
      fileName: displayName,
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
          // The opaque on-disk name, not the display name — this is what the
          // receiver builds its local path from.
          'fileName': storedName,
          'messageId': message.id,
          'messageJson': message.toJson(),
          'hops': 0,
          'ttl': maxHops,
        };
        final bytes = utf8.encode(jsonEncode(metadata));
        await Nearby().sendBytesPayload(endpoint, bytes);
      } catch (e) {
        debugPrint('[Mesh] Failed to send document to $endpoint: $e');
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
    _handlePayloadAsync(endpointId, payload).catchError((Object e) {
      debugPrint('[Mesh] Error handling payload: $e');
    });
  }

  Future<void> _handlePayloadAsync(String endpointId, Payload payload) async {
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

    final MessageModel message = MessageModel.fromJson(meshPayload.messageJson).copyWith(
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
      final base = MessageModel.fromJson(meta.messageJson);

      // Move the received file to a permanent app-local directory, keyed on the
      // message's own type. This used to be `mesh_images` for everything, which
      // put received voice notes and video in the photos folder and would have
      // dropped documents there too. Only new arrivals move — a message already
      // received holds an absolute path and keeps resolving.
      final appDir = await getApplicationDocumentsDirectory();
      final destDir = Directory('${appDir.path}/${meshDirNameForType(base.type)}');
      if (!destDir.existsSync()) {
        destDir.createSync(recursive: true);
      }
      // `meta.fileName` arrives from an unauthenticated peer over an open Nearby
      // link. Our own senders generate an opaque name, but a tampered one could
      // send `../../databases/app.db` and write straight through the sandbox.
      final safeName = sanitiseMeshFileName(meta.fileName);
      final destPath = '${destDir.path}/$safeName';

      await Nearby().copyFileAndDeleteOriginal(uri, destPath);

      // Build the MessageModel with the local file path.
      final message = base.copyWith(
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
        debugPrint('[Mesh] Received ${base.type.name} for me: $safeName');
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
          // A view-once photo/video is ephemeral by intent — it must never
          // become a permanent, plaintext cloud object. It was already shown
          // (or not) over the mesh; reconcile it as a short note so the online
          // history isn't a silent gap, and drop the local media instead of
          // uploading it.
          if (msg.viewOnce &&
              (msg.type == MessageType.image ||
                  msg.type == MessageType.video)) {
            await _chatService.sendMessage(
              senderId: msg.senderId,
              receiverId: msg.receiverId,
              text: msg.type == MessageType.video
                  ? '🎬 View-once video sent nearby'
                  : '📷 View-once photo sent nearby',
            );
            synced.add(msg.id);
            continue;
          }

          String? mediaUrl = msg.mediaUrl;
          Map<String, dynamic>? mediaKey = msg.mediaKey;

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

          // If this is a video with a local file, upload it.
          if (msg.type == MessageType.video &&
              msg.localFilePath != null &&
              mediaUrl == null) {
            mediaUrl = await _uploadLocalFile(msg, 'chat_videos', 'mp4');
          }

          // A document is the one mesh media type that is encrypted at rest, so
          // it goes through EncryptedMediaService rather than the plaintext
          // putFile above — the same pipeline the online send uses. Its readiness
          // signal is the key bundle, not a URL.
          if (msg.type == MessageType.document &&
              msg.localFilePath != null &&
              (mediaKey == null || mediaKey.isEmpty)) {
            mediaKey = await _uploadEncryptedLocalFile(msg);
          }

          // A media message can't be reconciled until its file actually
          // uploaded. If the upload produced nothing (a transient Storage error,
          // or — for video and documents — the chat_videos / chat_documents rule
          // not yet deployed), leave it pending so the next reconnect retries,
          // instead of sending an unopenable message and dropping the pending
          // item for good.
          if (meshMessageNeedsUpload(
            msg.type,
            localFilePath: msg.localFilePath,
            mediaUrl: mediaUrl,
            mediaKey: mediaKey,
          )) {
            debugPrint(
                '[Mesh] Upload not ready for ${msg.id}; keeping it pending for retry');
            continue;
          }

          await _chatService.sendMessage(
            senderId: msg.senderId,
            receiverId: msg.receiverId,
            text: msg.text,
            type: msg.type,
            mediaUrl: mediaUrl,
            audioDuration: msg.audioDuration,
            videoThumbnailBase64: msg.videoThumbnailBase64,
            // A location pin carries its coordinates in the message itself, not
            // in a media file. Without these two the pin would reconcile to the
            // cloud as an empty bubble the online chat can't render.
            latitude: msg.latitude,
            longitude: msg.longitude,
            // A document's real name and its key bundle both live inside the
            // envelope; without them the receiver gets a bubble it can neither
            // label nor decrypt.
            fileName: msg.fileName,
            mediaKey: mediaKey,
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

  /// Upload a locally-stored mesh file (image / audio / video) to Firebase Storage.
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

      final contentType = switch (fallbackExt) {
        'm4a' => 'audio/m4a',
        'mp4' => 'video/mp4',
        _ => 'image/jpeg',
      };
      final metadata = SettableMetadata(contentType: contentType);

      await ref.putFile(file, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('[Mesh] Failed to upload file for ${msg.id}: $e');
      return null;
    }
  }

  /// Encrypt and upload a locally-stored mesh document, returning the
  /// `MediaKeyBundle` map the message carries inside its envelope.
  ///
  /// Separate from [_uploadLocalFile] because that one is a plaintext `putFile`
  /// by design: images, voice notes and video reconcile to the legacy unencrypted
  /// paths. Documents don't — they are AES-256-GCM sealed on-device and land in
  /// `chat_documents/` under an opaque name as `application/octet-stream`, so the
  /// server sees neither the contents nor the filename. Same call shape as the
  /// online send in `chat_screen._pickAndSendDocument`.
  ///
  /// Returns `null` on any failure so the caller keeps the message pending.
  Future<Map<String, dynamic>?> _uploadEncryptedLocalFile(
      MessageModel msg) async {
    try {
      final file = File(msg.localFilePath!);
      if (!file.existsSync()) return null;

      final chatRoomId =
          _chatService.getChatRoomId(msg.senderId, msg.receiverId);
      final bundle = await EncryptedMediaService().encryptAndUpload(
        file: file,
        storagePath:
            'chat_documents/$chatRoomId/${EncryptedMediaService.opaqueObjectName()}',
        // The real type is recorded in the bundle, not on the Storage object —
        // it is what tells the receiver which app to open the file with.
        contentType:
            lookupMimeType(msg.fileName ?? msg.localFilePath!) ??
                'application/octet-stream',
      );
      return bundle.toMap();
    } catch (e) {
      debugPrint('[Mesh] Failed to upload document for ${msg.id}: $e');
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
