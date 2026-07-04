/// GupShupGo Pro — Subscription data model.
///
/// Tracks which plan the user is on, when it expires, and the
/// purchase token for validation. This model is persisted to
/// both SharedPreferences (for instant cold-start checks) and
/// Firestore `users/{uid}` (server-side source of truth).

import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Plan enum ──────────────────────────────────────────────────────────────
enum SubscriptionPlan { free, pro }

// ─── Product IDs — must match Google Play Console exactly ─────────────────
class ProProductIds {
  ProProductIds._();

  /// Monthly auto-renewing subscription.
  static const String monthly = 'gupshupgo_pro_monthly';

  /// Yearly auto-renewing subscription.
  static const String yearly = 'gupshupgo_pro_yearly';

  /// All subscription product IDs used when querying the store.
  static const Set<String> all = {monthly, yearly};
}

// ─── Subscription model ─────────────────────────────────────────────────────
class SubscriptionModel {
  final SubscriptionPlan plan;
  final DateTime? expiresAt;
  final String? purchaseToken;
  final String? productId;

  const SubscriptionModel({
    this.plan = SubscriptionPlan.free,
    this.expiresAt,
    this.purchaseToken,
    this.productId,
  });

  // ── Convenience getters ──────────────────────────────────────────────────
  bool get isPro => plan == SubscriptionPlan.pro && !isExpired;

  bool get isExpired {
    if (plan == SubscriptionPlan.free) return false; // free never expires
    if (expiresAt == null) return true;
    return DateTime.now().isAfter(expiresAt!);
  }

  int get daysRemaining {
    if (expiresAt == null) return 0;
    final diff = expiresAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  String get planLabel {
    if (!isPro) return 'Free';
    if (productId == ProProductIds.monthly) return 'Pro Monthly';
    if (productId == ProProductIds.yearly) return 'Pro Yearly';
    return 'Pro';
  }

  // ── Serialisation ────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'plan': plan.name,
        'expiresAt': expiresAt?.millisecondsSinceEpoch,
        'purchaseToken': purchaseToken,
        'productId': productId,
      };

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      plan: map['plan'] == 'pro' ? SubscriptionPlan.pro : SubscriptionPlan.free,
      expiresAt: map['expiresAt'] != null
          ? _parseDateTime(map['expiresAt'])
          : null,
      purchaseToken: map['purchaseToken'] as String?,
      productId: map['productId'] as String?,
    );
  }

  factory SubscriptionModel.free() => const SubscriptionModel();

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  SubscriptionModel copyWith({
    SubscriptionPlan? plan,
    DateTime? expiresAt,
    String? purchaseToken,
    String? productId,
  }) {
    return SubscriptionModel(
      plan: plan ?? this.plan,
      expiresAt: expiresAt ?? this.expiresAt,
      purchaseToken: purchaseToken ?? this.purchaseToken,
      productId: productId ?? this.productId,
    );
  }
}

// ─── Feature limits by plan ─────────────────────────────────────────────────
class PlanLimits {
  PlanLimits._();

  /// Max voice message duration in seconds.
  static int maxVoiceDurationSec(bool isPro) => isPro ? 300 : 60;

  /// Max media file size in bytes.
  static int maxMediaSizeBytes(bool isPro) =>
      isPro ? 50 * 1024 * 1024 : 10 * 1024 * 1024;

  /// Whether media statuses (photo/video) are allowed.
  static bool canPostMediaStatus(bool isPro) => isPro;

  /// Whether screen sharing is allowed.
  static bool canScreenShare(bool isPro) => isPro;

  /// Whether chat export is allowed.
  static bool canExportChat(bool isPro) => isPro;

  /// Whether custom chat wallpapers are allowed.
  static bool canCustomWallpaper(bool isPro) => isPro;

  /// Number of free streak restores per week.
  static int freeStreakRestoresPerWeek(bool isPro) => isPro ? 1 : 0;
}
