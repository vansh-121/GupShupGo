import 'dart:convert';
import 'package:video_chat_app/main.dart'; // sharedPrefs global
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/models/user_model.dart';

/// Lightweight JSON cache for the chat list displayed on the home screen.
/// Stores chat rooms + the contact info for each room so the UI can
/// render instantly on app launch — exactly like WhatsApp does.
class ChatCacheService {
  static const _chatListKey = 'cached_chat_list';
  static const _userCacheKey = 'cached_chat_users';
  static const _pendingMeshKey = 'pending_mesh_messages';

  // ─── In-memory user cache (populated from disk or Firestore) ────────

  /// User profiles indexed by userId — avoids N Firestore reads per frame.
  final Map<String, UserModel> _userCache = {};

  UserModel? getCachedUser(String userId) => _userCache[userId];

  void cacheUser(UserModel user) {
    _userCache[user.id] = user;
    _persistUserCache();
  }

  void cacheUsers(List<UserModel> users) {
    for (final u in users) {
      _userCache[u.id] = u;
    }
    _persistUserCache();
  }

  // ─── Chat list cache ───────────────────────────────────────────────

  /// Save chat rooms as a JSON list to SharedPreferences.
  void cacheChatRooms(List<ChatRoom> rooms) {
    try {
      final list = rooms.map((r) => _chatRoomToJson(r)).toList();
      sharedPrefs.setString(_chatListKey, jsonEncode(list));
    } catch (e) {
      print('Error caching chat rooms: $e');
    }
  }

  /// Load cached chat rooms synchronously. Returns empty list if none.
  List<ChatRoom> getCachedChatRooms() {
    try {
      final json = sharedPrefs.getString(_chatListKey);
      if (json == null) return [];
      final list = jsonDecode(json) as List;
      return list.map((e) => _chatRoomFromJson(e)).toList();
    } catch (e) {
      print('Error reading cached chat rooms: $e');
      return [];
    }
  }

  // ─── User cache persistence ────────────────────────────────────────

  /// Persist the in-memory user map to SharedPreferences.
  void _persistUserCache() {
    try {
      final map = <String, dynamic>{};
      _userCache.forEach((id, user) {
        map[id] = user.toMap();
      });
      sharedPrefs.setString(_userCacheKey, jsonEncode(map));
    } catch (e) {
      print('Error persisting user cache: $e');
    }
  }

  /// Load persisted user cache from SharedPreferences into memory.
  void loadUserCacheFromDisk() {
    try {
      final json = sharedPrefs.getString(_userCacheKey);
      if (json == null) return;
      final map = jsonDecode(json) as Map<String, dynamic>;
      map.forEach((id, data) {
        _userCache[id] =
            UserModel.fromMap(data as Map<String, dynamic>, id);
      });
    } catch (e) {
      print('Error loading user cache from disk: $e');
    }
  }

  // ─── JSON helpers (Firestore-free serialization) ───────────────────

  Map<String, dynamic> _chatRoomToJson(ChatRoom room) {
    return {
      'id': room.id,
      'participants': room.participants,
      'lastMessage': room.lastMessage,
      'lastMessageTime': room.lastMessageTime?.millisecondsSinceEpoch,
      'lastMessageSenderId': room.lastMessageSenderId,
      'lastMessageStatus': room.lastMessageStatus?.name,
      'unreadCount': room.unreadCount,
    };
  }

  ChatRoom _chatRoomFromJson(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime'])
          : null,
      lastMessageSenderId: map['lastMessageSenderId'],
      lastMessageStatus: _parseStatus(map['lastMessageStatus']),
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
    );
  }

  static MessageStatus? _parseStatus(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return MessageStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => MessageStatus.sent,
      );
    }
    return MessageStatus.sent;
  }

  // ─── Mesh message queue (offline store-and-forward) ────────────────

  /// Store a message that was sent/received via the mesh network and
  /// hasn't been synced to Firestore yet.
  void storePendingMeshMessage(MessageModel message) {
    try {
      final pending = getPendingMeshMessages();
      // Dedup by id
      if (pending.any((m) => m.id == message.id)) return;
      pending.add(message);
      final list = pending.map((m) => m.toJson()).toList();
      sharedPrefs.setString(_pendingMeshKey, jsonEncode(list));
    } catch (e) {
      print('Error storing pending mesh message: $e');
    }
  }

  /// Get all messages waiting to be synced to Firestore.
  List<MessageModel> getPendingMeshMessages() {
    try {
      final json = sharedPrefs.getString(_pendingMeshKey);
      if (json == null) return [];
      final list = jsonDecode(json) as List;
      return list
          .map((e) =>
              MessageModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('Error reading pending mesh messages: $e');
      return [];
    }
  }

  /// Remove messages that have been successfully synced to Firestore.
  void removeSyncedMeshMessages(List<String> syncedIds) {
    try {
      final pending = getPendingMeshMessages();
      pending.removeWhere((m) => syncedIds.contains(m.id));
      final list = pending.map((m) => m.toJson()).toList();
      sharedPrefs.setString(_pendingMeshKey, jsonEncode(list));
    } catch (e) {
      print('Error removing synced mesh messages: $e');
    }
  }

  /// Count of messages waiting to sync.
  int get pendingMeshCount => getPendingMeshMessages().length;
}
