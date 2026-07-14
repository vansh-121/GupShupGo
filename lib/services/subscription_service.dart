/// GupShupGo Pro — Subscription service (Robust).
///
/// Handles the business logic of in-app purchases: querying products,
/// initiating purchases, listening to the purchase stream, and sending
/// purchase tokens to the server for verification. The Cloud Function
/// validates receipts with the Google Play Developer API before activating
/// Pro status in Firestore.
///
/// Robustness features:
/// - Retry with exponential backoff on server verification failures
/// - Deduplication of purchase events (prevents double-verification)
/// - Pending purchase recovery on app restart
/// - HTTP timeout on all server calls (15 seconds)
/// - Detailed error messages from server responses
/// - Completer-based restore tracking (no arbitrary delays)
library subscription_service;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

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

  // ── HTTP config ───────────────────────────────────────────────────────────
  static const _httpTimeout = Duration(seconds: 15);
  static const _maxRetries = 3;

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const _kPlan = 'sub_plan';
  static const _kExpiresAt = 'sub_expires_at';
  static const _kPurchaseToken = 'sub_purchase_token';
  static const _kProductId = 'sub_product_id';
  static const _kVerifiedAt = 'sub_verified_at';
  static const _kLastStreakRestore = 'sub_last_streak_restore';
  static const _kStreakRestoreCount = 'sub_streak_restore_count';
  // Pending verification keys — for crash recovery
  static const _kPendingToken = 'sub_pending_token';
  static const _kPendingProductId = 'sub_pending_product_id';

  // ── Cached state ──────────────────────────────────────────────────────────
  SubscriptionModel _subscription = SubscriptionModel.free();
  SubscriptionModel get subscription => _subscription;
  bool get isPro => _subscription.isPro;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  // ── Deduplication: track tokens currently being verified ───────────────────
  final Set<String> _processingTokens = {};

  // ── Restore tracking: Completer-based instead of arbitrary delay ──────────
  Completer<void>? _restoreCompleter;

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

    // 5. Recover any pending verification from a previous crash
    await _recoverPendingVerification();
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
  /// Returns a Future that completes when the restore stream has been processed
  /// or after a 10-second timeout — whichever comes first.
  Future<void> restorePurchases() async {
    _restoreCompleter = Completer<void>();

    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('[Subscription] Restore failed: $e');
      onPurchaseError?.call('Restore failed: $e');
      _restoreCompleter?.complete();
      _restoreCompleter = null;
      return;
    }

    // Wait for the purchase stream to process restored purchases,
    // but cap at 10 seconds to prevent hanging.
    await _restoreCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('[Subscription] Restore timed out after 10s');
      },
    );
    _restoreCompleter = null;
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
          _completeRestore();
          break;
        case PurchaseStatus.canceled:
          debugPrint('[Subscription] Purchase canceled');
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
          _completeRestore();
          break;
      }
    }
  }

  /// Signal that restore is done (called after each purchase event is processed).
  void _completeRestore() {
    if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
      _restoreCompleter!.complete();
    }
  }

  Future<void> _verifyAndActivate(PurchaseDetails purchase) async {
    final token = purchase.verificationData.serverVerificationData;

    // ── Deduplication: skip if this token is already being verified ──────
    if (_processingTokens.contains(token)) {
      debugPrint(
          '[Subscription] Skipping duplicate verification for ${purchase.productID}');
      // Still complete the purchase to clear it from the queue
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
      return;
    }
    _processingTokens.add(token);

    try {
      debugPrint(
          '[Subscription] Sending token to server (length=${token.length})');

      // Save pending verification state for crash recovery
      await _savePendingVerification(token, purchase.productID);

      final verified = await _verifyOnServerWithRetry(
        purchaseToken: token,
        productId: purchase.productID,
      );

      // Clear pending state on success or permanent failure
      await _clearPendingVerification();

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
      // Don't clear pending verification — we'll retry on next app start
    } finally {
      _processingTokens.remove(token);
      // Always complete the purchase to clear it from the queue
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
      _completeRestore();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  Server verification with retry
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sends the purchase token to the `verifyPurchase` Cloud Function with
  /// exponential backoff retry (up to [_maxRetries] attempts).
  ///
  /// Only retries on 5xx errors and timeouts. Client errors (400/401/402/404/410)
  /// are treated as permanent failures and NOT retried.
  Future<bool> _verifyOnServerWithRetry({
    required String purchaseToken,
    required String productId,
  }) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        final result = await _verifyOnServer(
          purchaseToken: purchaseToken,
          productId: productId,
        );
        return result;
      } on _PermanentVerificationFailure {
        // Don't retry — server said the purchase is definitively invalid
        debugPrint(
            '[Subscription] Permanent verification failure (attempt $attempt) — not retrying');
        return false;
      } catch (e) {
        if (attempt >= _maxRetries) {
          debugPrint(
              '[Subscription] All $attempt verification attempts failed: $e');
          rethrow;
        }
        // Exponential backoff: 2s, 4s, 8s
        final delay = Duration(seconds: pow(2, attempt).toInt());
        debugPrint(
            '[Subscription] Verification attempt $attempt failed, retrying in ${delay.inSeconds}s: $e');
        await Future.delayed(delay);
      }
    }
  }

  /// Sends the purchase token to the `verifyPurchase` Cloud Function.
  /// Returns `true` if the server confirmed the subscription is valid.
  ///
  /// Throws [_PermanentVerificationFailure] on 4xx errors (don't retry).
  /// Throws other exceptions on 5xx / network errors (safe to retry).
  Future<bool> _verifyOnServer({
    required String purchaseToken,
    required String productId,
  }) async {
    final idToken = await _getIdToken();
    if (idToken == null) {
      debugPrint('[Subscription] Cannot verify — user not signed in');
      return false;
    }

    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(_verifyPurchaseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'purchaseToken': purchaseToken,
              'productId': productId,
            }),
          )
          .timeout(_httpTimeout);
    } on TimeoutException {
      throw Exception('Server verification timed out after ${_httpTimeout.inSeconds}s');
    }

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

    // Parse error details from server response
    String errorDetail = response.body;
    try {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      errorDetail = errorData['detail'] as String? ??
          errorData['error'] as String? ??
          response.body;
    } catch (_) {
      // Response body wasn't JSON — use raw body
    }

    debugPrint(
        '[Subscription] Server verification failed: ${response.statusCode} — $errorDetail');

    // 4xx = permanent failure (bad input, expired, payment issue) — don't retry
    if (response.statusCode >= 400 && response.statusCode < 500) {
      // Surface the specific server message to the user
      onPurchaseError?.call(errorDetail);
      throw _PermanentVerificationFailure(errorDetail);
    }

    // 5xx = transient server error — throw generic exception to trigger retry
    throw Exception(
        'Server error ${response.statusCode}: $errorDetail');
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
  //  Pending verification recovery (crash resilience)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save pending verification state before calling the server.
  /// If the app crashes between payment and server response, we can retry.
  Future<void> _savePendingVerification(String token, String productId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPendingToken, token);
    await prefs.setString(_kPendingProductId, productId);
  }

  /// Clear pending verification state after success or permanent failure.
  Future<void> _clearPendingVerification() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPendingToken);
    await prefs.remove(_kPendingProductId);
  }

  /// On init, check for any pending verification from a previous crash
  /// and retry it.
  Future<void> _recoverPendingVerification() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingToken = prefs.getString(_kPendingToken);
    final pendingProductId = prefs.getString(_kPendingProductId);

    if (pendingToken == null || pendingProductId == null) return;
    if (pendingToken.isEmpty) {
      await _clearPendingVerification();
      return;
    }

    debugPrint(
        '[Subscription] Recovering pending verification for $pendingProductId');

    try {
      final verified = await _verifyOnServerWithRetry(
        purchaseToken: pendingToken,
        productId: pendingProductId,
      );
      await _clearPendingVerification();

      if (verified) {
        debugPrint('[Subscription] ✅ Recovered pending purchase successfully');
      } else {
        debugPrint('[Subscription] ❌ Pending purchase recovery failed — server rejected');
      }
    } catch (e) {
      debugPrint('[Subscription] Pending recovery failed (will retry next launch): $e');
      // Leave pending state — will retry on next app launch
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
  /// Also clears streak restore prefs to prevent data leaking across accounts.
  Future<void> clearSubscription() async {
    _subscription = SubscriptionModel.free();
    await _clearPrefs();
    // Also clear streak restore tracking — prevents cross-account data leaks
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastStreakRestore);
    await prefs.remove(_kStreakRestoreCount);
    // Clear any pending verification
    await _clearPendingVerification();
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

      final http.Response response;
      try {
        response = await http
            .post(
              Uri.parse(_verifyStatusUrl),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $idToken',
              },
              body: jsonEncode({}),
            )
            .timeout(_httpTimeout);
      } on TimeoutException {
        debugPrint('[Subscription] Server sync timed out');
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final plan = data['plan'] as String?;
        final expiresAtMs = data['expiresAt'];
        final productId = data['productId'] as String?;
        final onHold = data['onHold'] as bool? ?? false;

        // Handle account on hold
        if (onHold) {
          final detail = data['detail'] as String?;
          debugPrint('[Subscription] Account on hold: $detail');
          if (_subscription.isPro) {
            _subscription = SubscriptionModel.free();
            await _clearPrefs();
            onSubscriptionChanged?.call();
            onPurchaseError?.call(detail ?? 'Subscription on hold — update payment in Google Play');
          }
          return;
        }

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

/// Thrown when the server returns a 4xx error, meaning the purchase is
/// definitively invalid and should NOT be retried.
class _PermanentVerificationFailure implements Exception {
  final String message;
  _PermanentVerificationFailure(this.message);
  @override
  String toString() => '_PermanentVerificationFailure: $message';
}
