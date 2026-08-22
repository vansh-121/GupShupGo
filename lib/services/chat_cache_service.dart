import 'dart:convert';
import 'package:video_chat_app/main.dart'; // sharedPrefs global
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/models/user_model.dart';
import 'package:video_chat_app/services/presence_service.dart';
import 'package:video_chat_app/services/streak/streak_state.dart';

/// Lightweight JSON cache for the chat list displayed on the home screen.
/// Stores chat rooms + the contact info for each room so the UI can
/// render instantly on app launch — exactly like WhatsApp does.
class ChatCacheService {
  static const _chatListKey = 'cached_chat_list';
  static const _userCacheKey = 'cached_chat_users';
  static const _pendingMeshKey = 'pending_mesh_messages';

  /// Schema version of a cached chat-room entry.
  ///
  ///  * 1 (implicit — the key is absent) — legacy entry: flat `streakCount` /
  ///    `lastInteractionDate` / `lastSentAt` / `previousStreakCount` /
  ///    `streakBrokenAt` only.
  ///  * 2 — adds the `streakState` block and a room-level `cachedAt`, while
  ///    still writing the legacy keys for the compatibility window.
  ///
  /// The reader tolerates both, and every added key is optional, so an entry
  /// written by an older build still loads.
  static const int cacheSchemaVersion = 2;

  // ─── In-memory user cache (populated from disk or Firestore) ────────

  /// User profiles indexed by userId — avoids N Firestore reads per frame.
  final Map<String, UserModel> _userCache = {};

  /// Returns the cached profile with its presence re-checked against the
  /// clock.
  ///
  /// The cache is persisted to SharedPreferences and `UserModel.toMap()`
  /// includes `isOnline`, so without this a green dot would survive process
  /// death and reappear on the next launch. `lastSeen` is persisted too, which
  /// is what makes the check possible offline.
  UserModel? getCachedUser(String userId) {
    final user = _userCache[userId];
    if (user == null) return null;
    if (user.isOnline && !PresenceService.isRecentlyActive(user.lastSeen)) {
      return user.copyWith(isOnline: false);
    }
    return user;
  }

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

  // ─── Chat list cache (in-memory + immediate disk write) ─────────────

  /// In-memory chat room list — serves reads instantly without SharedPrefs I/O.
  /// Written to disk immediately so it survives app kill.
  List<ChatRoom> _cachedRooms = [];

  /// Save chat rooms. Updates in-memory cache and SharedPreferences
  /// immediately — the Firestore stream already debounces naturally.
  void cacheChatRooms(List<ChatRoom> rooms) {
    _cachedRooms = rooms;
    try {
      // One stamp for the whole batch: every entry was observed at the same
      // instant, and freshness is judged against it on read.
      final cachedAt = DateTime.now().toUtc();
      final list = rooms.map((r) => _chatRoomToJson(r, cachedAt)).toList();
      sharedPrefs.setString(_chatListKey, jsonEncode(list));
    } catch (e) {
      print('Error caching chat rooms: $e');
    }
  }

  /// Load cached chat rooms. Returns in-memory cache if available,
  /// otherwise loads from disk and caches in memory for next call.
  List<ChatRoom> getCachedChatRooms() {
    if (_cachedRooms.isNotEmpty) return _cachedRooms;
    try {
      final json = sharedPrefs.getString(_chatListKey);
      if (json == null) return [];
      final list = jsonDecode(json) as List;
      _cachedRooms = list.map((e) => _chatRoomFromJson(e)).toList();
      return _cachedRooms;
    } catch (e) {
      print('Error reading cached chat rooms: $e');
      return [];
    }
  }

  // ─── User cache persistence ────────────────────────────────────────

  /// Persist the in-memory user map to SharedPreferences immediately.
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
        // Force presence off on restore: an entry written by a previous
        // process is never evidence of a live connection, whatever it says.
        // The real value arrives with the first Firestore refresh.
        _userCache[id] = UserModel.fromMap(data as Map<String, dynamic>, id)
            .copyWith(isOnline: false);
      });
    } catch (e) {
      print('Error loading user cache from disk: $e');
    }
  }

  // ─── JSON helpers (Firestore-free serialization) ───────────────────

  Map<String, dynamic> _chatRoomToJson(ChatRoom room, [DateTime? cachedAt]) {
    final stamp = (cachedAt ?? DateTime.now()).toUtc();
    // Prefer the state the room already carries; otherwise project the legacy
    // fields so a v2 entry always has a `streakState` block to read back.
    final state = room.streakState ??
        StreakState.fromLegacy(
          participants: room.participants,
          streakCount: room.streakCount,
          lastInteractionDate: room.lastInteractionDate,
          lastSentAt: room.lastSentAt,
          previousStreakCount: room.previousStreakCount,
          streakBrokenAt: room.streakBrokenAt,
        );
    return {
      'cacheSchemaVersion': cacheSchemaVersion,
      'cachedAt': stamp.millisecondsSinceEpoch,
      'streakState': state.toCacheJson(cachedAt: stamp),
      'id': room.id,
      'participants': room.participants,
      'lastMessage': room.lastMessage,
      'lastMessageTime': room.lastMessageTime?.millisecondsSinceEpoch,
      'lastMessageSenderId': room.lastMessageSenderId,
      'lastMessageStatus': room.lastMessageStatus?.name,
      'unreadCount': room.unreadCount,
      'streakCount': room.streakCount,
      'lastInteractionDate': room.lastInteractionDate?.millisecondsSinceEpoch,
      'lastSentAt': room.lastSentAt.map((k, v) => MapEntry(k, v.millisecondsSinceEpoch)),
      'previousStreakCount': room.previousStreakCount,
      'streakBrokenAt': room.streakBrokenAt?.millisecondsSinceEpoch,
    };
  }

  ChatRoom _chatRoomFromJson(Map<String, dynamic> map) {
    // Parse lastSentAt from cache (values are int milliseconds)
    final rawSent = map['lastSentAt'] as Map<String, dynamic>? ?? {};
    final parsedSent = <String, DateTime>{};
    rawSent.forEach((key, value) {
      if (value is int) {
        parsedSent[key] = DateTime.fromMillisecondsSinceEpoch(value);
      }
    });

    final participants = List<String>.from(map['participants'] ?? []);

    // `cachedAt` is absent on entries written by older builds — those get no
    // freshness stamp, which `StreakState.isStaleAt` already treats as stale.
    final cachedAt = streakInstantFrom(map['cachedAt']);

    // v2 entries carry the authoritative block; older ones only have the flat
    // legacy keys, so project those instead. Either way this is *stored* state:
    // the badge renders through StreakRepository's derivation, never off the
    // raw count.
    final rawState = map['streakState'];
    StreakState? state = rawState is Map
        ? StreakState.fromCacheJson(Map<String, dynamic>.from(rawState))
        : null;
    state ??= StreakState.fromLegacyRoomMap(
      map,
      participants: participants,
      cachedAt: cachedAt,
    );
    if (state.cachedAt == null && cachedAt != null) {
      state = state.copyWith(cachedAt: cachedAt);
    }

    return ChatRoom(
      streakState: state,
      id: map['id'] ?? '',
      participants: participants,
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime'])
          : null,
      lastMessageSenderId: map['lastMessageSenderId'],
      lastMessageStatus: _parseStatus(map['lastMessageStatus']),
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      streakCount: map['streakCount'] ?? 0,
      lastInteractionDate: map['lastInteractionDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastInteractionDate'])
          : null,
      lastSentAt: parsedSent,
      previousStreakCount: map['previousStreakCount'] ?? 0,
      streakBrokenAt: map['streakBrokenAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['streakBrokenAt'])
          : null,
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
