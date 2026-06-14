import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? email;
  final String? photoUrl;
  final String? fcmToken;
  final String? about;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime? createdAt;

  // Gamification fields
  final int gupPoints;
  final List<String> badges;
  final Map<String, int> challengeProgress;
  final List<String> completedChallenges;

  UserModel({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.email,
    this.photoUrl,
    this.fcmToken,
    this.about,
    this.isOnline = false,
    this.lastSeen,
    this.createdAt,
    this.gupPoints = 0,
    this.badges = const [],
    this.challengeProgress = const {},
    this.completedChallenges = const [],
  });

  // Level computation: e.g. 100 points per level
  int get level => (gupPoints / 100).floor() + 1;
  double get levelProgress => (gupPoints % 100) / 100.0;

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'about': about,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'gupPoints': gupPoints,
      'badges': badges,
      'challengeProgress': challengeProgress,
      'completedChallenges': completedChallenges,
    };
  }

  // Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      id: documentId,
      name: map['name'] ?? 'Unknown',
      phoneNumber: map['phoneNumber'],
      email: map['email'],
      photoUrl: map['photoUrl'],
      fcmToken: map['fcmToken'],
      about: map['about'],
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null
          ? _parseDateTime(map['lastSeen'])
          : null,
      createdAt: map['createdAt'] != null
          ? _parseDateTime(map['createdAt'])
          : null,
      gupPoints: map['gupPoints'] ?? 0,
      badges: List<String>.from(map['badges'] ?? []),
      challengeProgress: Map<String, int>.from(map['challengeProgress'] ?? {}),
      completedChallenges: List<String>.from(map['completedChallenges'] ?? []),
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
    String? phoneNumber,
    String? email,
    String? photoUrl,
    String? fcmToken,
    String? about,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
    int? gupPoints,
    List<String>? badges,
    Map<String, int>? challengeProgress,
    List<String>? completedChallenges,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      about: about ?? this.about,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      gupPoints: gupPoints ?? this.gupPoints,
      badges: badges ?? this.badges,
      challengeProgress: challengeProgress ?? this.challengeProgress,
      completedChallenges: completedChallenges ?? this.completedChallenges,
    );
  }
}
