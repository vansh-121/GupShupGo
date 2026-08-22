import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_chat_app/services/streak/streak_state.dart';

enum MessageType { text, image, audio, video, reaction }

enum MessageStatus {
  // Local-only state. The message is in the outbox: the bubble is on
  // screen but the encrypt + Firestore commit hasn't completed yet.
  // Never persisted to Firestore — it only exists for the brief window
  // between user tap and commit, and is replaced by `sent` the moment
  // the Firestore stream re-delivers the message.
  sending,
  // Local-only state. Encrypt or Firestore commit failed; the bubble
  // stays in the outbox with this status so the user can retry.
  failed,
  sent, // Message sent but not delivered
  delivered, // Message delivered to device but not read
  read // Message read by receiver
}

/// Every key that may appear inside the **encrypted** payload of a v2 message.
///
/// A content field is not one edit — it is seven, and six of the seven fail
/// *silently* in a different way if you miss them. When adding one, touch all of:
///
///  1. the five serializers in this file (`toMap`, `toJson`, `fromJson`,
///     `fromMap`, `copyWith`) — miss one and the field vanishes on a cold
///     restart or over mesh;
///  2. `ChatService.sendMessage`'s parameters and its `optimistic` model — miss
///     it and the sender's own bubble renders bare until the app restarts;
///  3. `ChatService._commitMessage`'s wire `payload` — miss it and the receiver
///     never gets the data at all;
///  4. `ChatService._commitMessage`'s `outgoingPayload` — miss it and the
///     *sender* loses the field on cold restart, and the vault copy is short;
///  5. the `schemaVersion == 2 ? null : …` guards on the committed
///     `MessageModel` — miss it and **the content is written to Firestore in
///     the clear**;
///  6. `ChatService._applyPayload` — miss it and decryption succeeds while the
///     field silently never renders;
///  7. `SyncService._serveOneResend`'s `wire` map — miss it and a *resent*
///     message loses the field, which only ever reproduces after a decrypt
///     failure.
///
/// `test/models/message_model_serialization_test.dart` pins 1 and 6 against
/// this list. 2-5 and 7 are still on you.
///
/// Two keys travel in the payload but are deliberately absent here: `type`
/// (restored from the plaintext Firestore field, not the envelope) and
/// `localFilePath` (a path on *this* device, so it goes in the sender's local
/// copy only and must never reach the wire).
const List<String> kMessageContentKeys = <String>[
  'text',
  'mediaUrl',
  'audioDuration',
  'reactionTargetMessageId',
  'statusReplyOwnerId',
  'statusReplyItemId',
  'statusReplyOwnerName',
  'statusReplyOwnerPhotoUrl',
  'statusReplyType',
  'statusReplyText',
  'statusReplyMediaUrl',
  'statusReplyCaption',
  'statusReplyBackgroundColor',
  'linkPreviewUrl',
  'linkPreviewTitle',
  'linkPreviewDescription',
  'linkPreviewSiteName',
  'linkPreviewImageBase64',
  'replyToMessageId',
  'replyToSenderId',
  'replyToSenderName',
  'replyToType',
  'replyToText',
];

/// Longest reply snippet we snapshot into a quote. Long enough to identify the
/// original at a glance, short enough that quoting a wall of text doesn't
/// multiply into every recipient device's envelope.
const int kReplySnippetMaxLength = 160;

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final String? mediaUrl;

  // ─── End-to-end encryption (v2) ─────────────────────────────────────
  /// 1 = legacy plaintext, 2 = E2EE. Persisted to Firestore. Old clients
  /// see only schemaVersion=1 messages; new clients can render both.
  final int schemaVersion;

  /// Sender's deviceId. Needed by the recipient to pick the right Signal
  /// session for decryption.
  final int? senderDeviceId;

  /// Map "<recipientUid>:<deviceId>" → { ct: base64, pk: bool }.
  /// One entry per recipient device + one per sender's other devices
  /// (self-sync). Only the device that owns the matching session can
  /// decrypt its own entry.
  final Map<String, Map<String, dynamic>>? envelopes;

  /// Metadata for a reply sent from a status update.
  final String? statusReplyOwnerId;
  final String? statusReplyItemId;
  final String? statusReplyOwnerName;
  final String? statusReplyOwnerPhotoUrl;
  final String? statusReplyType;
  final String? statusReplyText;
  final String? statusReplyMediaUrl;
  final String? statusReplyCaption;
  final String? statusReplyBackgroundColor;

  /// Local file path for images received/sent via mesh (not yet uploaded).
  final String? localFilePath;

  /// Duration of audio in seconds (for voice messages).
  final int? audioDuration;

  // ─── Offline Mesh Messaging fields ──────────────────────────────────
  /// Whether this message was sent/received via the mesh network.
  final bool isOfflineMesh;

  /// Number of peer-to-peer hops this message has traveled (0 = direct).
  final int meshHops;

  /// True if the message hasn't been synced to Firestore yet.
  final bool syncPending;

  // ─── Gamification & Reactions ───────────────────────────────────────
  /// Map of `userId` -> `emoji` (e.g. `{'userId1': '👍', 'userId2': '😂'}`)
  final Map<String, String>? reactions;

  /// The ID of the message this reaction is targeting (only populated when type == MessageType.reaction)
  final String? reactionTargetMessageId;

  // ─── Link preview ───────────────────────────────────────────────────────
  // Resolved by the SENDER before encrypting and carried inside the envelope,
  // so the receiver renders the card without ever contacting the link host —
  // no IP leak to whoever sent the link, no tracking pixel on delivery, and
  // the card still works offline. See lib/services/link_preview_service.dart.

  /// The URL the card opens. Non-null iff this message carries a preview.
  final String? linkPreviewUrl;
  final String? linkPreviewTitle;
  final String? linkPreviewDescription;

  /// Human-readable source ("YouTube", "github.com").
  final String? linkPreviewSiteName;

  /// JPEG micro-thumbnail, base64, capped at 6 KB by the fetcher. Null when the
  /// page had no usable image — the card then renders text-only.
  final String? linkPreviewImageBase64;

  // ─── Reply quote ────────────────────────────────────────────────────────
  // A self-contained SNAPSHOT, not a pointer. The quote must still render when
  // the original was deleted, cleared from this device, or never decrypted
  // here — so everything needed to draw it travels with the reply.

  /// Original message id. Used for tap-to-jump only; never required to render.
  final String? replyToMessageId;
  final String? replyToSenderId;
  final String? replyToSenderName;

  /// `MessageType.name` of the original, so a quoted photo can render an icon
  /// even when its bytes are nowhere on this device.
  final String? replyToType;

  /// Snapshot of the original's text, capped at [kReplySnippetMaxLength].
  final String? replyToText;

  // ─── Delete & edit ──────────────────────────────────────────────────────
  //
  // These three are **cleartext metadata**, and deliberately so. They are
  // absent from [kMessageContentKeys] and must never gain a
  // `schemaVersion == 2 ? null : …` guard — that guard exists to keep message
  // *content* off the server, whereas these have to be on the server document
  // to do their job at all:
  //
  //  • a delete has to outlive a reinstall. SyncService backfills the latest 50
  //    documents on first install, so a purely local delete comes straight back
  //    — and never reaches the user's other devices.
  //  • a tombstone has to be something the receiver's sync can *see*. A deleted
  //    document is indistinguishable from one that slid out of the 50-document
  //    window, which SyncService correctly refuses to act on.
  //
  // None of the three reveals anything the server didn't already know: who
  // talked to whom and when is already plaintext on the document.

  /// UIDs that have deleted this message for themselves. Bounded to 2 in a 1:1
  /// chat. Filtered out at read time by `ChatService.getMessages`; the document
  /// itself stays intact for the other participant.
  final List<String> deletedFor;

  /// Deleted for everyone by its sender. The ciphertext is stripped from the
  /// document at the same time, so this is a genuine deletion with a marker
  /// left behind — not a flag hiding content that is still there.
  final bool deletedForEveryone;

  /// When the sender last edited the text. Server timestamp. Also the signal
  /// SyncService uses to decide that an already-synced message needs decrypting
  /// again — without it an edit is invisible to the receiver forever.
  final DateTime? editedAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.type = MessageType.text,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.mediaUrl,
    this.statusReplyOwnerId,
    this.statusReplyItemId,
    this.statusReplyOwnerName,
    this.statusReplyOwnerPhotoUrl,
    this.statusReplyType,
    this.statusReplyText,
    this.statusReplyMediaUrl,
    this.statusReplyCaption,
    this.statusReplyBackgroundColor,
    this.localFilePath,
    this.audioDuration,
    this.isOfflineMesh = false,
    this.meshHops = 0,
    this.syncPending = false,
    this.schemaVersion = 1,
    this.senderDeviceId,
    this.envelopes,
    this.reactions,
    this.reactionTargetMessageId,
    this.linkPreviewUrl,
    this.linkPreviewTitle,
    this.linkPreviewDescription,
    this.linkPreviewSiteName,
    this.linkPreviewImageBase64,
    this.replyToMessageId,
    this.replyToSenderId,
    this.replyToSenderName,
    this.replyToType,
    this.replyToText,
    this.deletedFor = const [],
    this.deletedForEveryone = false,
    this.editedAt,
  });

  // Convenience getters for status
  bool get isDelivered =>
      status == MessageStatus.delivered || status == MessageStatus.read;
  bool get isRead => status == MessageStatus.read;
  bool get hasStatusReply =>
      statusReplyOwnerId != null && statusReplyItemId != null;

  /// True when the sender has edited this message since sending it.
  bool get isEdited => editedAt != null;

  /// Whether [uid] has deleted this message for themselves.
  bool isDeletedFor(String uid) => deletedFor.contains(uid);

  /// This message reduced to "deleted for everyone": identity and routing kept,
  /// every trace of content gone.
  ///
  /// Deliberately a constructor call and not [copyWith]. `copyWith` is
  /// `x ?? this.x` for all forty of its parameters, so it *cannot* clear a
  /// field — passing `mediaUrl: null` keeps the old URL. A tombstone built with
  /// `copyWith(deletedForEveryone: true, text: '')` therefore still carries the
  /// media URL, the downloaded file path, the envelopes, the reactions and the
  /// base64 link-preview thumbnail. Listing what survives, rather than what
  /// dies, is the only version of this that stays correct as fields are added.
  MessageModel asTombstone() => MessageModel(
        id: id,
        senderId: senderId,
        receiverId: receiverId,
        text: '',
        // Kept as-is: the bubble needs to know it *was* an image to say so, and
        // MessageType is not content.
        type: type,
        timestamp: timestamp,
        status: status,
        schemaVersion: schemaVersion,
        senderDeviceId: senderDeviceId,
        isOfflineMesh: isOfflineMesh,
        meshHops: meshHops,
        deletedFor: deletedFor,
        deletedForEveryone: true,
        editedAt: editedAt,
      );

  /// True when this message carries a link preview card.
  bool get hasLinkPreview =>
      linkPreviewUrl != null && linkPreviewUrl!.isNotEmpty;

  /// True when this message quotes another message.
  bool get hasReplyQuote =>
      replyToMessageId != null && replyToMessageId!.isNotEmpty;

  // Convert MessageModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.name,
      'mediaUrl': mediaUrl,
      'statusReplyOwnerId': statusReplyOwnerId,
      'statusReplyItemId': statusReplyItemId,
      'statusReplyOwnerName': statusReplyOwnerName,
      'statusReplyOwnerPhotoUrl': statusReplyOwnerPhotoUrl,
      'statusReplyType': statusReplyType,
      'statusReplyText': statusReplyText,
      'statusReplyMediaUrl': statusReplyMediaUrl,
      'statusReplyCaption': statusReplyCaption,
      'statusReplyBackgroundColor': statusReplyBackgroundColor,
      'audioDuration': audioDuration,
      // localFilePath is intentionally excluded from Firestore — it's local only.
      'isOfflineMesh': isOfflineMesh,
      'meshHops': meshHops,
      'syncPending': syncPending,
      'schemaVersion': schemaVersion,
      if (senderDeviceId != null) 'senderDeviceId': senderDeviceId,
      if (envelopes != null) 'envelopes': envelopes,
      if (reactions != null) 'reactions': reactions,
      if (reactionTargetMessageId != null) 'reactionTargetMessageId': reactionTargetMessageId,
      // Link preview and reply quote are written conditionally rather than as
      // explicit nulls: on a v2 message every one of them is null by design
      // (the real values ride inside `envelopes`), and 10 null fields per
      // document is pure noise. An absent key reads back as null either way.
      if (linkPreviewUrl != null) 'linkPreviewUrl': linkPreviewUrl,
      if (linkPreviewTitle != null) 'linkPreviewTitle': linkPreviewTitle,
      if (linkPreviewDescription != null)
        'linkPreviewDescription': linkPreviewDescription,
      if (linkPreviewSiteName != null) 'linkPreviewSiteName': linkPreviewSiteName,
      if (linkPreviewImageBase64 != null)
        'linkPreviewImageBase64': linkPreviewImageBase64,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (replyToSenderId != null) 'replyToSenderId': replyToSenderId,
      if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
      if (replyToType != null) 'replyToType': replyToType,
      if (replyToText != null) 'replyToText': replyToText,
      // Written conditionally for the same reason as the block above, and with
      // one extra benefit: a conditional key can never clobber. The real
      // delete/edit writes are targeted `update()` calls, but if this map is
      // ever handed to a merging `set()`, an unconditional `deletedFor: []`
      // would wipe the other participant's deletion.
      if (deletedFor.isNotEmpty) 'deletedFor': deletedFor,
      if (deletedForEveryone) 'deletedForEveryone': true,
      if (editedAt != null) 'editedAt': Timestamp.fromDate(editedAt!),
    };
  }

  /// Lightweight JSON map (no Firestore types) for mesh/local storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'type': type.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.name,
      'mediaUrl': mediaUrl,
      'statusReplyOwnerId': statusReplyOwnerId,
      'statusReplyItemId': statusReplyItemId,
      'statusReplyOwnerName': statusReplyOwnerName,
      'statusReplyOwnerPhotoUrl': statusReplyOwnerPhotoUrl,
      'statusReplyType': statusReplyType,
      'statusReplyText': statusReplyText,
      'statusReplyMediaUrl': statusReplyMediaUrl,
      'statusReplyCaption': statusReplyCaption,
      'statusReplyBackgroundColor': statusReplyBackgroundColor,
      'localFilePath': localFilePath,
      'audioDuration': audioDuration,
      'isOfflineMesh': isOfflineMesh,
      'meshHops': meshHops,
      'syncPending': syncPending,
      'schemaVersion': schemaVersion,
      if (senderDeviceId != null) 'senderDeviceId': senderDeviceId,
      if (envelopes != null) 'envelopes': envelopes,
      if (reactions != null) 'reactions': reactions,
      if (reactionTargetMessageId != null) 'reactionTargetMessageId': reactionTargetMessageId,
      if (linkPreviewUrl != null) 'linkPreviewUrl': linkPreviewUrl,
      if (linkPreviewTitle != null) 'linkPreviewTitle': linkPreviewTitle,
      if (linkPreviewDescription != null)
        'linkPreviewDescription': linkPreviewDescription,
      if (linkPreviewSiteName != null) 'linkPreviewSiteName': linkPreviewSiteName,
      if (linkPreviewImageBase64 != null)
        'linkPreviewImageBase64': linkPreviewImageBase64,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (replyToSenderId != null) 'replyToSenderId': replyToSenderId,
      if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
      if (replyToType != null) 'replyToType': replyToType,
      if (replyToText != null) 'replyToText': replyToText,
      if (deletedFor.isNotEmpty) 'deletedFor': deletedFor,
      if (deletedForEveryone) 'deletedForEveryone': true,
      if (editedAt != null) 'editedAt': editedAt!.millisecondsSinceEpoch,
    };
  }

  /// Create from a plain JSON map (mesh / SharedPreferences).
  factory MessageModel.fromJson(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      type: _parseMessageType(map['type']),
      timestamp: map['timestamp'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
      status: _parseMessageStatus(map['status']),
      mediaUrl: map['mediaUrl'],
      statusReplyOwnerId: map['statusReplyOwnerId'],
      statusReplyItemId: map['statusReplyItemId'],
      statusReplyOwnerName: map['statusReplyOwnerName'],
      statusReplyOwnerPhotoUrl: map['statusReplyOwnerPhotoUrl'],
      statusReplyType: map['statusReplyType'],
      statusReplyText: map['statusReplyText'],
      statusReplyMediaUrl: map['statusReplyMediaUrl'],
      statusReplyCaption: map['statusReplyCaption'],
      statusReplyBackgroundColor: map['statusReplyBackgroundColor'],
      localFilePath: map['localFilePath'],
      audioDuration: map['audioDuration'],
      isOfflineMesh: map['isOfflineMesh'] ?? false,
      meshHops: map['meshHops'] ?? 0,
      syncPending: map['syncPending'] ?? false,
      schemaVersion: (map['schemaVersion'] as int?) ?? 1,
      senderDeviceId: map['senderDeviceId'] as int?,
      envelopes: _parseEnvelopes(map['envelopes']),
      reactions: map['reactions'] != null ? Map<String, String>.from(map['reactions']) : null,
      reactionTargetMessageId: map['reactionTargetMessageId'],
      linkPreviewUrl: map['linkPreviewUrl'],
      linkPreviewTitle: map['linkPreviewTitle'],
      linkPreviewDescription: map['linkPreviewDescription'],
      linkPreviewSiteName: map['linkPreviewSiteName'],
      linkPreviewImageBase64: map['linkPreviewImageBase64'],
      replyToMessageId: map['replyToMessageId'],
      replyToSenderId: map['replyToSenderId'],
      replyToSenderName: map['replyToSenderName'],
      replyToType: map['replyToType'],
      replyToText: map['replyToText'],
      deletedFor: _parseStringList(map['deletedFor']),
      deletedForEveryone: map['deletedForEveryone'] ?? false,
      editedAt: map['editedAt'] != null ? _parseTimestamp(map['editedAt']) : null,
    );
  }

  static Map<String, Map<String, dynamic>>? _parseEnvelopes(dynamic raw) {
    if (raw == null) return null;
    if (raw is! Map) return null;
    return raw.map((k, v) =>
        MapEntry(k as String, Map<String, dynamic>.from(v as Map)));
  }

  /// Tolerant list parse for [deletedFor]. Always returns a list, never null:
  /// "nobody has deleted this" and "the key was never written" are the same
  /// thing, and a nullable list here would push a `?? const []` onto every
  /// caller.
  static List<String> _parseStringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  // Create MessageModel from Firestore document
  factory MessageModel.fromMap(Map<String, dynamic> map, String documentId) {
    return MessageModel(
      id: documentId,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      type: _parseMessageType(map['type']),
      timestamp: _parseTimestamp(map['timestamp']),
      status: _parseMessageStatus(map['status']),
      mediaUrl: map['mediaUrl'],
      statusReplyOwnerId: map['statusReplyOwnerId'],
      statusReplyItemId: map['statusReplyItemId'],
      statusReplyOwnerName: map['statusReplyOwnerName'],
      statusReplyOwnerPhotoUrl: map['statusReplyOwnerPhotoUrl'],
      statusReplyType: map['statusReplyType'],
      statusReplyText: map['statusReplyText'],
      statusReplyMediaUrl: map['statusReplyMediaUrl'],
      statusReplyCaption: map['statusReplyCaption'],
      statusReplyBackgroundColor: map['statusReplyBackgroundColor'],
      audioDuration: map['audioDuration'],
      isOfflineMesh: map['isOfflineMesh'] ?? false,
      meshHops: map['meshHops'] ?? 0,
      syncPending: map['syncPending'] ?? false,
      schemaVersion: (map['schemaVersion'] as int?) ?? 1,
      senderDeviceId: map['senderDeviceId'] as int?,
      envelopes: _parseEnvelopes(map['envelopes']),
      reactions: map['reactions'] != null ? Map<String, String>.from(map['reactions']) : null,
      reactionTargetMessageId: map['reactionTargetMessageId'],
      linkPreviewUrl: map['linkPreviewUrl'],
      linkPreviewTitle: map['linkPreviewTitle'],
      linkPreviewDescription: map['linkPreviewDescription'],
      linkPreviewSiteName: map['linkPreviewSiteName'],
      linkPreviewImageBase64: map['linkPreviewImageBase64'],
      replyToMessageId: map['replyToMessageId'],
      replyToSenderId: map['replyToSenderId'],
      replyToSenderName: map['replyToSenderName'],
      replyToType: map['replyToType'],
      replyToText: map['replyToText'],
      deletedFor: _parseStringList(map['deletedFor']),
      deletedForEveryone: map['deletedForEveryone'] ?? false,
      editedAt: map['editedAt'] != null ? _parseTimestamp(map['editedAt']) : null,
    );
  }

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MessageModel.fromMap(data, doc.id);
  }

  static MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'image':
        return MessageType.image;
      case 'audio':
        return MessageType.audio;
      case 'video':
        return MessageType.video;
      case 'reaction':
        return MessageType.reaction;
      default:
        return MessageType.text;
    }
  }

  static MessageStatus _parseMessageStatus(dynamic status) {
    if (status == null) return MessageStatus.sent;
    // Handle legacy isRead boolean
    if (status is bool) {
      return status ? MessageStatus.read : MessageStatus.delivered;
    }
    switch (status.toString()) {
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      // `sending` and `failed` are local-only states that should never
      // appear in a Firestore payload, but a stale write from a buggy
      // client would otherwise stick a permanent "sending" bubble on the
      // receiver. Map them back to the safe `sent` baseline.
      default:
        return MessageStatus.sent;
    }
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? text,
    MessageType? type,
    DateTime? timestamp,
    MessageStatus? status,
    String? mediaUrl,
    String? statusReplyOwnerId,
    String? statusReplyItemId,
    String? statusReplyOwnerName,
    String? statusReplyOwnerPhotoUrl,
    String? statusReplyType,
    String? statusReplyText,
    String? statusReplyMediaUrl,
    String? statusReplyCaption,
    String? statusReplyBackgroundColor,
    String? localFilePath,
    int? audioDuration,
    bool? isOfflineMesh,
    int? meshHops,
    bool? syncPending,
    int? schemaVersion,
    int? senderDeviceId,
    Map<String, Map<String, dynamic>>? envelopes,
    Map<String, String>? reactions,
    String? reactionTargetMessageId,
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
    List<String>? deletedFor,
    bool? deletedForEveryone,
    DateTime? editedAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      statusReplyOwnerId: statusReplyOwnerId ?? this.statusReplyOwnerId,
      statusReplyItemId: statusReplyItemId ?? this.statusReplyItemId,
      statusReplyOwnerName: statusReplyOwnerName ?? this.statusReplyOwnerName,
      statusReplyOwnerPhotoUrl:
          statusReplyOwnerPhotoUrl ?? this.statusReplyOwnerPhotoUrl,
      statusReplyType: statusReplyType ?? this.statusReplyType,
      statusReplyText: statusReplyText ?? this.statusReplyText,
      statusReplyMediaUrl: statusReplyMediaUrl ?? this.statusReplyMediaUrl,
      statusReplyCaption: statusReplyCaption ?? this.statusReplyCaption,
      statusReplyBackgroundColor:
          statusReplyBackgroundColor ?? this.statusReplyBackgroundColor,
      localFilePath: localFilePath ?? this.localFilePath,
      audioDuration: audioDuration ?? this.audioDuration,
      isOfflineMesh: isOfflineMesh ?? this.isOfflineMesh,
      meshHops: meshHops ?? this.meshHops,
      syncPending: syncPending ?? this.syncPending,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      senderDeviceId: senderDeviceId ?? this.senderDeviceId,
      envelopes: envelopes ?? this.envelopes,
      reactions: reactions ?? this.reactions,
      reactionTargetMessageId: reactionTargetMessageId ?? this.reactionTargetMessageId,
      linkPreviewUrl: linkPreviewUrl ?? this.linkPreviewUrl,
      linkPreviewTitle: linkPreviewTitle ?? this.linkPreviewTitle,
      linkPreviewDescription:
          linkPreviewDescription ?? this.linkPreviewDescription,
      linkPreviewSiteName: linkPreviewSiteName ?? this.linkPreviewSiteName,
      linkPreviewImageBase64:
          linkPreviewImageBase64 ?? this.linkPreviewImageBase64,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToSenderId: replyToSenderId ?? this.replyToSenderId,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      replyToType: replyToType ?? this.replyToType,
      replyToText: replyToText ?? this.replyToText,
      deletedFor: deletedFor ?? this.deletedFor,
      deletedForEveryone: deletedForEveryone ?? this.deletedForEveryone,
      editedAt: editedAt ?? this.editedAt,
    );
  }
}

// Chat room model to track conversations
class ChatRoom {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final MessageStatus? lastMessageStatus;
  final Map<String, int> unreadCount;
  // ── LEGACY STREAK FIELDS — DEPRECATED, READ-ONLY ──────────────────────────
  //
  // These five mirror the pre-v2 room document, where the client computed and
  // wrote the streak on every send. The authoritative state now lives at
  // `chatRooms/{roomId}/streak/state` and is surfaced through [streakState]
  // (stored) / `StreakRepository` + `StreakEngine` (derived, what you render).
  //
  // They are kept ONLY for the dual-read window, so rooms the repair job has
  // not reached yet still render via `StreakState.fromLegacy(room)`. Treat them
  // as read-only: nothing in the client may write them, and no display or
  // restore decision may be made from them directly. Task 10.4 removes them
  // together with the fields on the room document.

  /// Legacy stored count. Deprecated — see [streakState].
  final int streakCount;

  /// Legacy day anchor, device-local and client-stamped. Deprecated — see
  /// [streakState]; the deadline comes from `StreakState.deadlineAt`.
  final DateTime? lastInteractionDate;

  /// Legacy per-participant last-send timestamps. Deprecated — the server keeps
  /// `sendDays`/`sendInstants` on `chatRooms/{id}/streak/state`.
  final Map<String, DateTime> lastSentAt;

  /// Legacy pre-break count used by the old client restore flow. Deprecated —
  /// use `StreakState.previousCount` / the server restore quote.
  final int previousStreakCount;

  /// Legacy break stamp. Deprecated — use `StreakState.brokenAt` and
  /// `restoreDeadlineAt` from `chatRooms/{id}/streak/state`.
  final DateTime? streakBrokenAt;

  /// The authoritative streak state carried alongside the room, when one is
  /// available (currently: hydrated by `ChatCacheService` from the disk cache).
  ///
  /// Optional and deliberately untyped as `Object?`-free: it holds a
  /// [StreakState]. It is *stored* state only — the count that gets rendered
  /// must still come from `StreakEngine`/`StreakRepository` derivation, never
  /// straight off this field. Never written to Firestore (`toMap` ignores it);
  /// the authoritative copy lives at `chatRooms/{roomId}/streak/state`.
  final StreakState? streakState;

  ChatRoom({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.lastMessageStatus,
    this.unreadCount = const {},
    this.streakCount = 0,
    this.lastInteractionDate,
    this.lastSentAt = const {},
    this.previousStreakCount = 0,
    this.streakBrokenAt,
    this.streakState,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime':
          lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageStatus': lastMessageStatus?.name,
      'unreadCount': unreadCount,
      'streakCount': streakCount,
      'lastInteractionDate':
          lastInteractionDate != null ? Timestamp.fromDate(lastInteractionDate!) : null,
      'lastSentAt': lastSentAt.map((k, v) => MapEntry(k, Timestamp.fromDate(v))),
      'previousStreakCount': previousStreakCount,
      'streakBrokenAt':
          streakBrokenAt != null ? Timestamp.fromDate(streakBrokenAt!) : null,
    };
  }

  factory ChatRoom.fromMap(Map<String, dynamic> map, String documentId) {
    // Parse lastSentAt map: each value can be a Timestamp or int (from cache).
    final rawLastSent = map['lastSentAt'] as Map<String, dynamic>? ?? {};
    final parsedLastSent = <String, DateTime>{};
    rawLastSent.forEach((key, value) {
      final dt = _parseDateTime(value);
      if (dt != null) parsedLastSent[key] = dt;
    });

    return ChatRoom(
      id: documentId,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : null,
      lastMessageSenderId: map['lastMessageSenderId'],
      lastMessageStatus: _parseMessageStatus(map['lastMessageStatus']),
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      streakCount: map['streakCount'] ?? 0,
      lastInteractionDate: map['lastInteractionDate'] != null
          ? _parseDateTime(map['lastInteractionDate'])
          : null,
      lastSentAt: parsedLastSent,
      previousStreakCount: map['previousStreakCount'] ?? 0,
      streakBrokenAt: map['streakBrokenAt'] != null
          ? _parseDateTime(map['streakBrokenAt'])
          : null,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }

  static MessageStatus? _parseMessageStatus(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return MessageStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => MessageStatus.sent,
      );
    }
    return MessageStatus.sent;
  }

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatRoom.fromMap(data, doc.id);
  }
}
