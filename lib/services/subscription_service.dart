/// GupShupGo Pro — Subscription service.
///
/// Handles the business logic of in-app purchases: querying products,
/// initiating purchases, listening to the purchase stream, verifying
/// receipts, and persisting subscription state to Firestore +
/// SharedPreferences.
library subscription_service;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_chat_app/models/subscription_model.dart';

class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const _kPlan = 'sub_plan';
  static const _kExpiresAt = 'sub_expires_at';
  static const _kPurchaseToken = 'sub_purchase_token';
  static const _kProductId = 'sub_product_id';
  static const _kLastStreakRestore = 'sub_last_streak_restore';
  static const _kStreakRestoreCount = 'sub_streak_restore_count';

  // ── Cached state ──────────────────────────────────────────────────────────
  SubscriptionModel _subscription = SubscriptionModel.free();
  SubscriptionModel get subscription => _subscription;
  bool get isPro => _subscription.isPro;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  // ── Callbacks for the provider to hook into ───────────────────────────────
  VoidCallback? onSubscriptionChanged;
  void Function(String error)? onPurchaseError;

  // ═══════════════════════════════════════════════════════════════════════════
  //  Initialisation
  // ═══════════════════════════════════════════════════════════════════════════

  /// Call once from main.dart. Loads cached state, queries store products,
  /// and starts listening to the purchase stream.
  Future<void> init() async {
    // 1. Load cached subscription from SharedPreferences (instant)
    await _loadFromPrefs();

    // 2. Check if IAP is available
    final available = await _iap.isAvailable();
    if (!available) {
      debugPrint('[Subscription] IAP not available on this device');
      return;
    }

    // 3. Query product details from the store
    await _loadProducts();

    // 4. Listen to the purchase update stream
    _purchaseSubscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        debugPrint('[Subscription] Purchase stream error: $error');
      },
    );
  }

  /// Clean up — call on app dispose if needed.
  void dispose() {
    _purchaseSubscription?.cancel();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Product loading
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadProducts() async {
    try {
      final response = await _iap.queryProductDetails(ProProductIds.all);
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
            '[Subscription] Products not found: ${response.notFoundIDs}');
      }
      _products = response.productDetails;
      // Sort so monthly comes first, then yearly
      _products.sort((a, b) {
        if (a.id == ProProductIds.monthly) return -1;
        if (b.id == ProProductIds.monthly) return 1;
        return 0;
      });
      debugPrint('[Subscription] Loaded ${_products.length} products');
    } catch (e) {
      debugPrint('[Subscription] Failed to load products: $e');
    }
  }

  /// Get a specific product by ID.
  ProductDetails? getProduct(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Purchase flow
  // ═══════════════════════════════════════════════════════════════════════════

  /// Initiate a purchase for the given product.
  Future<bool> purchase(ProductDetails product) async {
    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      // Subscriptions are non-consumable
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('[Subscription] Purchase failed: $e');
      onPurchaseError?.call('Purchase failed: $e');
      return false;
    }
  }

  /// Restore previous purchases (e.g. after reinstall).
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('[Subscription] Restore failed: $e');
      onPurchaseError?.call('Restore failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Purchase stream handler
  // ═══════════════════════════════════════════════════════════════════════════

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _verifyAndActivate(purchase);
          break;
        case PurchaseStatus.pending:
          debugPrint('[Subscription] Purchase pending: ${purchase.productID}');
          break;
        case PurchaseStatus.error:
          debugPrint(
              '[Subscription] Purchase error: ${purchase.error?.message}');
          onPurchaseError
              ?.call(purchase.error?.message ?? 'Purchase failed');
          // Complete the purchase even on error to clear it from the queue
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.canceled:
          debugPrint('[Subscription] Purchase canceled');
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
          break;
      }
    }
  }

  Future<void> _verifyAndActivate(PurchaseDetails purchase) async {
    try {
      // In a production app, you would verify the receipt server-side.
      // For now, we trust the local verification from the plugin.
      // The purchase is valid — activate Pro.

      // Determine expiry based on product type
      final now = DateTime.now();
      DateTime expiresAt;
      if (purchase.productID == ProProductIds.monthly) {
        expiresAt = now.add(const Duration(days: 30));
      } else if (purchase.productID == ProProductIds.yearly) {
        expiresAt = now.add(const Duration(days: 365));
      } else {
        expiresAt = now.add(const Duration(days: 30)); // fallback
      }

      _subscription = SubscriptionModel(
        plan: SubscriptionPlan.pro,
        expiresAt: expiresAt,
        purchaseToken: purchase.purchaseID,
        productId: purchase.productID,
      );

      // Persist locally + remotely
      await _saveToPrefs();
      // Firestore sync is fire-and-forget so UI updates instantly
      _syncToFirestore();

      onSubscriptionChanged?.call();

      debugPrint(
          '[Subscription] ✅ Activated Pro (${purchase.productID}) until $expiresAt');
    } catch (e) {
      debugPrint('[Subscription] Activation failed: $e');
    } finally {
      // Always complete the purchase
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Persistence — SharedPreferences (instant local cache)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final plan = prefs.getString(_kPlan);
    final expiresAt = prefs.getInt(_kExpiresAt);
    final token = prefs.getString(_kPurchaseToken);
    final productId = prefs.getString(_kProductId);

    if (plan == 'pro' && expiresAt != null) {
      _subscription = SubscriptionModel(
        plan: SubscriptionPlan.pro,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAt),
        purchaseToken: token,
        productId: productId,
      );
      // Check if expired
      if (_subscription.isExpired) {
        _subscription = SubscriptionModel.free();
        await _clearPrefs();
      }
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPlan, _subscription.plan.name);
    if (_subscription.expiresAt != null) {
      await prefs.setInt(
          _kExpiresAt, _subscription.expiresAt!.millisecondsSinceEpoch);
    }
    if (_subscription.purchaseToken != null) {
      await prefs.setString(_kPurchaseToken, _subscription.purchaseToken!);
    }
    if (_subscription.productId != null) {
      await prefs.setString(_kProductId, _subscription.productId!);
    }
  }

  Future<void> _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPlan);
    await prefs.remove(_kExpiresAt);
    await prefs.remove(_kPurchaseToken);
    await prefs.remove(_kProductId);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Persistence — Firestore (server-side source of truth)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sync subscription state to the user's Firestore document.
  void _syncToFirestore() {
    try {
      final uid =
          _currentUserId; // Set externally when user is authenticated
      if (uid == null) return;

      _firestore.collection('users').doc(uid).update({
        'subscriptionPlan': _subscription.plan.name,
        'subscriptionExpiresAt':
            _subscription.expiresAt?.millisecondsSinceEpoch,
        'subscriptionProductId': _subscription.productId,
      }).catchError((e) {
        debugPrint('[Subscription] Firestore sync failed: $e');
      });
    } catch (e) {
      debugPrint('[Subscription] Firestore sync error: $e');
    }
  }

  /// Load subscription from Firestore (for cross-device sync).
  Future<void> syncFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final plan = data['subscriptionPlan'] as String?;
      final expiresAt = data['subscriptionExpiresAt'];
      final productId = data['subscriptionProductId'] as String?;

      if (plan == 'pro' && expiresAt != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(expiresAt as int);
        if (expiry.isAfter(DateTime.now())) {
          _subscription = SubscriptionModel(
            plan: SubscriptionPlan.pro,
            expiresAt: expiry,
            productId: productId,
          );
          await _saveToPrefs();
          onSubscriptionChanged?.call();
        }
      }
    } catch (e) {
      debugPrint('[Subscription] Firestore load failed: $e');
    }
  }

  String? _currentUserId;

  /// Set the authenticated user ID for Firestore operations.
  void setUserId(String uid) {
    _currentUserId = uid;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Streak restore tracking (Pro perk: 1 free restore per week)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if the Pro user can still restore a streak this week.
  Future<bool> canRestoreStreakFree() async {
    if (!isPro) return false;

    final prefs = await SharedPreferences.getInstance();
    final lastRestore = prefs.getInt(_kLastStreakRestore);
    final restoreCount = prefs.getInt(_kStreakRestoreCount) ?? 0;

    if (lastRestore == null) return true; // never restored

    final lastDate = DateTime.fromMillisecondsSinceEpoch(lastRestore);
    final now = DateTime.now();

    // Reset counter if it's a new week (Monday-based)
    final lastWeek = _weekNumber(lastDate);
    final currentWeek = _weekNumber(now);

    if (currentWeek != lastWeek || now.year != lastDate.year) {
      return true; // new week
    }

    return restoreCount < 1; // 1 free restore per week for Pro
  }

  /// Record that a free streak restore was used.
  Future<void> recordStreakRestore() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setInt(_kLastStreakRestore, now.millisecondsSinceEpoch);

    final lastRestore = prefs.getInt(_kLastStreakRestore);
    final lastDate = lastRestore != null
        ? DateTime.fromMillisecondsSinceEpoch(lastRestore)
        : now;
    final lastWeek = _weekNumber(lastDate);
    final currentWeek = _weekNumber(now);

    int count = prefs.getInt(_kStreakRestoreCount) ?? 0;
    if (currentWeek != lastWeek || now.year != lastDate.year) {
      count = 1; // reset for new week
    } else {
      count += 1;
    }
    await prefs.setInt(_kStreakRestoreCount, count);
  }

  int _weekNumber(DateTime date) {
    // ISO 8601 week number
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }
}
