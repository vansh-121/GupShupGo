import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String? username;
  final String? authProvider; // 'phone' or 'google'
  final String? phoneNumber;
  final String? email;
  final String? photoUrl;
  final String? fcmToken;
  final String? about;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime? createdAt;

  // Subscription fields
  final String subscriptionPlan; // 'free' or 'pro'
  final DateTime? subscriptionExpiresAt;

  // Gamification fields
  final int gupPoints;
  final List<String> badges;
  final Map<String, int> challengeProgress;
  final List<String> completedChallenges;
  final int reactionsGiven;
  final int nightMessages;
  final int longestStreak;

  final bool isDiscoverable;

  UserModel({
    required this.id,
    required this.name,
    this.username,
    this.authProvider,
    this.phoneNumber,
    this.email,
    this.photoUrl,
    this.fcmToken,
    this.about,
    this.isOnline = false,
    this.isDiscoverable = true,
    this.lastSeen,
    this.createdAt,
    this.subscriptionPlan = 'free',
    this.subscriptionExpiresAt,
    this.gupPoints = 0,
    this.badges = const [],
    this.challengeProgress = const {},
    this.completedChallenges = const [],
    this.reactionsGiven = 0,
    this.nightMessages = 0,
    this.longestStreak = 0,
  });

  // Level computation: e.g. 100 points per level
  int get level => (gupPoints / 100).floor() + 1;
  double get levelProgress => (gupPoints % 100) / 100.0;

  // Subscription helpers
  bool get isPro {
    if (subscriptionPlan != 'pro') return false;
    if (subscriptionExpiresAt == null) return false;
    return DateTime.now().isBefore(subscriptionExpiresAt!);
  }

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'username_lowercase': username?.toLowerCase(),
      'authProvider': authProvider,
      'phoneNumber': phoneNumber,
      'email': email,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'about': about,
      'isOnline': isOnline,
      'isDiscoverable': isDiscoverable,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'subscriptionPlan': subscriptionPlan,
      'subscriptionExpiresAt': subscriptionExpiresAt?.millisecondsSinceEpoch,
      'gupPoints': gupPoints,
      'badges': badges,
      'challengeProgress': challengeProgress,
      'completedChallenges': completedChallenges,
      'reactionsGiven': reactionsGiven,
      'nightMessages': nightMessages,
      'longestStreak': longestStreak,
    };
  }

  /// Convert UserModel to Map for client-side Firestore writes.
  /// Omits server-managed subscription fields to comply with Firestore security rules.
  ///
  /// Also omits `isDiscoverable`: it is owned exclusively by
  /// `UserService.updateDiscoverableStatus`. Bulk profile writes (sign-in,
  /// profile save) often start from a UserModel that was read before the user
  /// toggled the setting, so including it here would silently flip an opted-out
  /// user back to discoverable. Absence of the field is read as `true` by
  /// [fromMap], which is the correct default for new accounts.
  ///
  /// `isOnline` and `lastSeen` are omitted for the same reason, and the stakes
  /// are higher. They are owned by `PresenceService` and the `presenceMirror`
  /// function, which write them alongside an RTDB `onDisconnect` handler — the
  /// thing that retracts an "online" claim when the app dies. A bulk profile
  /// write arms nothing, so shipping `isOnline: true` through here creates a
  /// claim with no retraction path: sign-in sites build models with
  /// `isOnline: true` and a client-clock `lastSeen`, and a profile save carries
  /// whatever presence the model was *read* with. Both then show the user
  /// online to everyone else with nothing left to correct it. Omitting the
  /// fields is safe under `SetOptions(merge: true)` — existing values are left
  /// alone, and a new account gets both within seconds from
  /// `PresenceService.setupPresence`. Absence reads as `isOnline: false` in
  /// [fromMap], the correct default.
  ///
  /// Gamification fields are omitted for the third time over the same reasoning,
  /// and they are the ones that actually bit. `gupPoints`, `badges`,
  /// `challengeProgress`, `completedChallenges`, `reactionsGiven`,
  /// `nightMessages` and `longestStreak` are owned by `GamificationService`
  /// (which moves points with `FieldValue.increment`) and by the Cloud
  /// Functions that award them. Nothing reaches them through here legitimately,
  /// and two ways of reaching them illegitimately both lose data: a profile save
  /// writes back whatever totals its model was *read* with, silently rolling
  /// back anything earned since, and a sign-in that built a fresh model writes
  /// `0` / `[]` over the real history. Note that the null-drop below cannot
  /// catch either case — `0` and `[]` are not null — so these have to be named.
  ///
  /// Finally, every remaining null is dropped, which is the general form of the
  /// same rule. `SetOptions(merge: true)` only protects keys that are *absent*
  /// from the payload — a key present with a null value overwrites whatever was
  /// stored. So a model that simply doesn't know a field's value used to erase
  /// it: when a sign-in couldn't read the existing profile it built a fresh
  /// model and this map carried `username: null` over a real account, wiping the
  /// handle.
  ///
  /// Dropping nulls costs nothing, because null never means "clear" anywhere in
  /// this class: [copyWith] resolves every field as `x ?? this.x`, so a null
  /// argument already means "leave it alone". Callers that genuinely clear a
  /// field write an empty string (profile save sends `about: ''`), which is not
  /// null and still goes through.
  Map<String, dynamic> toWritableMap() {
    final map = toMap();
    map.remove('isDiscoverable');
    map.remove('isOnline');
    map.remove('lastSeen');
    map.remove('subscriptionPlan');
    map.remove('subscriptionExpiresAt');
    map.remove('subscriptionProductId');
    map.remove('subscriptionVerifiedAt');
    map.remove('subscriptionPurchaseToken');
    for (final field in gamificationFields) {
      map.remove(field);
    }
    map.removeWhere((_, value) => value == null);
    return map;
  }

  /// Fields owned by `GamificationService` and the award Cloud Functions, never
  /// by a client profile write. Named here so [toWritableMap] and its test refer
  /// to one list instead of two that can drift.
  static const Set<String> gamificationFields = {
    'gupPoints',
    'badges',
    'challengeProgress',
    'completedChallenges',
    'reactionsGiven',
    'nightMessages',
    'longestStreak',
  };

  // Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      id: documentId,
      name: map['name'] ?? 'Unknown',
      username: map['username'],
      authProvider: map['authProvider'],
      phoneNumber: map['phoneNumber'],
      email: map['email'],
      photoUrl: map['photoUrl'],
      fcmToken: map['fcmToken'],
      about: map['about'],
      isOnline: map['isOnline'] ?? false,
      isDiscoverable: map['isDiscoverable'] ?? true,
      lastSeen: map['lastSeen'] != null
          ? _parseDateTime(map['lastSeen'])
          : null,
      createdAt: map['createdAt'] != null
          ? _parseDateTime(map['createdAt'])
          : null,
      subscriptionPlan: map['subscriptionPlan'] ?? 'free',
      subscriptionExpiresAt: map['subscriptionExpiresAt'] != null
          ? _parseDateTime(map['subscriptionExpiresAt'])
          : null,
      gupPoints: map['gupPoints'] ?? 0,
      badges: List<String>.from(map['badges'] ?? []),
      challengeProgress: Map<String, int>.from(map['challengeProgress'] ?? {}),
      completedChallenges: List<String>.from(map['completedChallenges'] ?? []),
      reactionsGiven: map['reactionsGiven'] ?? 0,
      nightMessages: map['nightMessages'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
    );
  }

  // Helper to parse DateTime from either Timestamp or int
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data, doc.id);
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? authProvider,
    String? phoneNumber,
    String? email,
    String? photoUrl,
    String? fcmToken,
    String? about,
    bool? isOnline,
    bool? isDiscoverable,
    DateTime? lastSeen,
    DateTime? createdAt,
    String? subscriptionPlan,
    DateTime? subscriptionExpiresAt,
    int? gupPoints,
    List<String>? badges,
    Map<String, int>? challengeProgress,
    List<String>? completedChallenges,
    int? reactionsGiven,
    int? nightMessages,
    int? longestStreak,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      authProvider: authProvider ?? this.authProvider,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      about: about ?? this.about,
      isOnline: isOnline ?? this.isOnline,
      isDiscoverable: isDiscoverable ?? this.isDiscoverable,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      gupPoints: gupPoints ?? this.gupPoints,
      badges: badges ?? this.badges,
      challengeProgress: challengeProgress ?? this.challengeProgress,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      reactionsGiven: reactionsGiven ?? this.reactionsGiven,
      nightMessages: nightMessages ?? this.nightMessages,
      longestStreak: longestStreak ?? this.longestStreak,
    );
  }
}
