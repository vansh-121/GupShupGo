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

  /// When the server last verified this subscription with Google Play.
  /// Null for legacy client-only activations or free users.
  final DateTime? verifiedAt;

  const SubscriptionModel({
    this.plan = SubscriptionPlan.free,
    this.expiresAt,
    this.purchaseToken,
    this.productId,
    this.verifiedAt,
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
        'verifiedAt': verifiedAt?.millisecondsSinceEpoch,
      };

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      plan: map['plan'] == 'pro' ? SubscriptionPlan.pro : SubscriptionPlan.free,
      expiresAt: map['expiresAt'] != null
          ? _parseDateTime(map['expiresAt'])
          : null,
      purchaseToken: map['purchaseToken'] as String?,
      productId: map['productId'] as String?,
      verifiedAt: map['verifiedAt'] != null
          ? _parseDateTime(map['verifiedAt'])
          : null,
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
    DateTime? verifiedAt,
  }) {
    return SubscriptionModel(
      plan: plan ?? this.plan,
      expiresAt: expiresAt ?? this.expiresAt,
      purchaseToken: purchaseToken ?? this.purchaseToken,
      productId: productId ?? this.productId,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }
}

// ─── Feature limits by plan ─────────────────────────────────────────────────
class PlanLimits {
  PlanLimits._();

  /// Max voice message duration in seconds — `null` means uncapped (Pro).
  ///
  /// The recorder stops and sends automatically on reaching the cap; see
  /// `VoiceRecorderService.startRecording`. Pro is genuinely uncapped on the
  /// client, but `storage.rules` still bounds `chat_audio` at 50 MB, which is
  /// ~52 min at the recorder's 128 kbps mono AAC.
  static int? maxVoiceDurationSec(bool isPro) => isPro ? null : 120;

  /// Max status video duration in seconds.
  static int maxStatusVideoSec(bool isPro) => isPro ? 90 : 30;

  // ── Outgoing image quality ────────────────────────────────────────────────
  //
  // The Pro media perk is a *quality* tier, not a larger byte allowance. The
  // free numbers below are exactly what shipped before the tier existed, so
  // nobody loses anything; Pro simply stops downscaling as aggressively.
  // Chat images render at thumbnail size, hence the lower free baseline than
  // statuses, which fill the screen in the viewer.

  static int chatImageMaxEdge(bool isPro) => isPro ? 2560 : 1280;
  static int chatImageQuality(bool isPro) => isPro ? 90 : 70;

  static int statusImageMaxEdge(bool isPro) => isPro ? 2560 : 1600;
  static int statusImageQuality(bool isPro) => isPro ? 90 : 75;

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
