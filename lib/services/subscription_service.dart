/// GupShupGo Pro — Subscription service.
///
/// Handles the business logic of in-app purchases: querying products,
/// initiating purchases, listening to the purchase stream, and sending
/// purchase tokens to the server for verification. The Cloud Function
/// validates receipts with the Google Play Developer API before activating
/// Pro status in Firestore.
library subscription_service;

import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_chat_app/models/subscription_model.dart';

class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  final InAppPurchase _iap = InAppPurchase.instance;

  // ── Cloud Function endpoints ──────────────────────────────────────────────
  static const _verifyPurchaseUrl =
      'https://us-central1-videocallapp-81166.cloudfunctions.net/verifyPurchase';
  static const _verifyStatusUrl =
      'https://us-central1-videocallapp-81166.cloudfunctions.net/verifySubscriptionStatus';

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const _kPlan = 'sub_plan';
  static const _kExpiresAt = 'sub_expires_at';
  static const _kPurchaseToken = 'sub_purchase_token';
  static const _kProductId = 'sub_product_id';
  static const _kVerifiedAt = 'sub_verified_at';
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
      debugPrint('[Subscription] Querying store products: ${ProProductIds.all}');
      final response = await _iap.queryProductDetails(ProProductIds.all);
      
      if (response.error != null) {
        debugPrint('[Subscription] ❌ Billing API error: ${response.error!.code} - ${response.error!.message}');
      }
      
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
            '[Subscription] ⚠️ Products not found by Google Play: ${response.notFoundIDs}');
      }
      
      _products = response.productDetails;
      debugPrint('[Subscription] Raw products returned: ${_products.map((p) => '${p.id}: ${p.price}')}');
      
      // Sort so monthly comes first, then yearly
      _products.sort((a, b) {
        if (a.id == ProProductIds.monthly) return -1;
        if (b.id == ProProductIds.monthly) return 1;
        return 0;
      });
      debugPrint('[Subscription] ✅ Successfully loaded ${_products.length} products');
    } catch (e) {
      debugPrint('[Subscription] ❌ Failed to load products exception: $e');
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
      // Send purchase token to the server for verification.
      // The Cloud Function validates with the Google Play Developer API,
      // writes verified subscription status to Firestore, and acknowledges
      // the purchase if needed.
      final verified = await _verifyOnServer(
        purchaseToken: purchase.purchaseID ?? '',
        productId: purchase.productID,
      );

      if (verified) {
        debugPrint(
            '[Subscription] ✅ Server verified Pro (${purchase.productID})');
      } else {
        debugPrint(
            '[Subscription] ❌ Server rejected purchase (${purchase.productID})');
        onPurchaseError?.call('Purchase verification failed on server');
      }
    } catch (e) {
      debugPrint('[Subscription] Server verification error: $e');
      onPurchaseError?.call('Could not verify purchase — check your connection');
    } finally {
      // Always complete the purchase to clear it from the queue
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  /// Sends the purchase token to the `verifyPurchase` Cloud Function.
  /// Returns `true` if the server confirmed the subscription is valid.
  Future<bool> _verifyOnServer({
    required String purchaseToken,
    required String productId,
  }) async {
    final idToken = await _getIdToken();
    if (idToken == null) {
      debugPrint('[Subscription] Cannot verify — user not signed in');
      return false;
    }

    final response = await http.post(
      Uri.parse(_verifyPurchaseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'purchaseToken': purchaseToken,
        'productId': productId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final expiresAt = data['expiresAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(data['expiresAt'] as int)
          : null;

      _subscription = SubscriptionModel(
        plan: SubscriptionPlan.pro,
        expiresAt: expiresAt,
        purchaseToken: purchaseToken,
        productId: productId,
        verifiedAt: DateTime.now(),
      );

      await _saveToPrefs();
      onSubscriptionChanged?.call();
      return true;
    }

    debugPrint(
        '[Subscription] Server verification failed: ${response.statusCode} — ${response.body}');
    return false;
  }

  /// Returns the current user's Firebase ID token, or null if not signed in.
  Future<String?> _getIdToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      return null;
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
    final verifiedAt = prefs.getInt(_kVerifiedAt);

    if (plan == 'pro' && expiresAt != null) {
      _subscription = SubscriptionModel(
        plan: SubscriptionPlan.pro,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAt),
        purchaseToken: token,
        productId: productId,
        verifiedAt: verifiedAt != null
            ? DateTime.fromMillisecondsSinceEpoch(verifiedAt)
            : null,
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
    if (_subscription.verifiedAt != null) {
      await prefs.setInt(
          _kVerifiedAt, _subscription.verifiedAt!.millisecondsSinceEpoch);
    }
  }

  Future<void> _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPlan);
    await prefs.remove(_kExpiresAt);
    await prefs.remove(_kPurchaseToken);
    await prefs.remove(_kProductId);
    await prefs.remove(_kVerifiedAt);
  }

  /// Clears the cached subscription status (resets to free) when the user signs out.
  Future<void> clearSubscription() async {
    _subscription = SubscriptionModel.free();
    await _clearPrefs();
    onSubscriptionChanged?.call();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Server-verified sync (replaces direct Firestore read/write)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Re-verify subscription status with the server.
  /// Called on login and cross-device sync. The server checks Firestore AND
  /// re-validates with Google Play if a purchase token is stored.
  Future<void> syncFromServer(String uid) async {
    try {
      final idToken = await _getIdToken();
      if (idToken == null) {
        debugPrint('[Subscription] Cannot sync — user not signed in');
        return;
      }

      final response = await http.post(
        Uri.parse(_verifyStatusUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final plan = data['plan'] as String?;
        final expiresAtMs = data['expiresAt'];
        final productId = data['productId'] as String?;

        if (plan == 'pro' && expiresAtMs != null) {
          final expiry =
              DateTime.fromMillisecondsSinceEpoch(expiresAtMs as int);
          if (expiry.isAfter(DateTime.now())) {
            _subscription = SubscriptionModel(
              plan: SubscriptionPlan.pro,
              expiresAt: expiry,
              productId: productId,
              verifiedAt: DateTime.now(),
            );
            await _saveToPrefs();
            onSubscriptionChanged?.call();
            debugPrint('[Subscription] Server sync: Pro until $expiry');
            return;
          }
        }

        // Server says free (or expired)
        if (_subscription.isPro) {
          _subscription = SubscriptionModel.free();
          await _clearPrefs();
          onSubscriptionChanged?.call();
          debugPrint('[Subscription] Server sync: reverted to Free');
        }
      } else {
        debugPrint(
            '[Subscription] Server sync failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[Subscription] Server sync error: $e');
      // Don't revoke access on network error — keep cached state
    }
  }

  /// Set the authenticated user ID. Currently a no-op since server-side
  /// verification uses Firebase ID tokens, but kept for API compatibility
  /// with [SubscriptionProvider].
  void setUserId(String uid) {
    // Server verification uses FirebaseAuth.instance.currentUser directly.
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
