/// GupShupGo Pro — Subscription state provider.
///
/// A [ChangeNotifier] that wraps [SubscriptionService] and exposes
/// reactive subscription state to the widget tree via Provider.
///
/// Robustness features:
/// - Loading state timeout (60s safety net)
/// - Completer-based restore (no arbitrary delays)
/// - Granular error messages from the server

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:video_chat_app/models/subscription_model.dart';
import 'package:video_chat_app/services/subscription_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _service = SubscriptionService.instance;

  bool _isLoading = false;
  String? _error;

  /// Safety-net timer: auto-resets [_isLoading] after 60 seconds if
  /// the purchase stream never fires (e.g. Google Play dialog dismissed
  /// without the app receiving a stream event).
  Timer? _loadingTimeout;
  static const _loadingTimeoutDuration = Duration(seconds: 60);

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get isPro => _service.isPro;
  bool get isLoading => _isLoading;
  String? get error => _error;
  SubscriptionModel get subscription => _service.subscription;
  List<ProductDetails> get products => _service.products;

  /// Find a product by ID.
  ProductDetails? getProduct(String id) => _service.getProduct(id);

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Call once from main.dart after the provider is created.
  Future<void> init() async {
    _service.onSubscriptionChanged = _onChanged;
    _service.onPurchaseError = _onError;
    await _service.init();
    
    // Automatically trigger a server sync on cold start if already signed in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _service.syncFromServer(currentUser.uid);
    }
    
    notifyListeners();
  }

  /// Set the user ID once the user is authenticated.
  void setUserId(String uid) {
    _service.setUserId(uid);
    // Verify subscription status with server (re-validates with Google Play)
    _service.syncFromServer(uid);
  }

  // ── Purchase actions ──────────────────────────────────────────────────────

  /// Purchase a specific product.
  Future<bool> purchase(ProductDetails product) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Start safety-net timeout: if the purchase stream never fires
    // (e.g. user dismisses the Google Play dialog without the app receiving
    // a stream event), auto-reset loading state after 60 seconds.
    _startLoadingTimeout();

    final success = await _service.purchase(product);

    // Note: the actual subscription activation happens asynchronously
    // via the purchase stream listener in SubscriptionService.
    // _isLoading will be cleared when _onChanged or _onError fires.
    if (!success) {
      _cancelLoadingTimeout();
      _isLoading = false;
      notifyListeners();
    }

    return success;
  }

  /// Convenience: purchase monthly plan.
  Future<bool> purchaseMonthly() async {
    final product = _service.getProduct(ProProductIds.monthly);
    if (product == null) {
      _error = 'Monthly plan not available';
      notifyListeners();
      return false;
    }
    return purchase(product);
  }

  /// Convenience: purchase yearly plan.
  Future<bool> purchaseYearly() async {
    final product = _service.getProduct(ProProductIds.yearly);
    if (product == null) {
      _error = 'Yearly plan not available';
      notifyListeners();
      return false;
    }
    return purchase(product);
  }

  /// Restore previous purchases.
  /// Uses the service's Completer-based approach (no arbitrary delays).
  Future<void> restorePurchases() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await _service.restorePurchases();

    _isLoading = false;
    notifyListeners();
  }

  // ── Streak restore (Pro perk) ─────────────────────────────────────────────

  Future<bool> canRestoreStreakFree() => _service.canRestoreStreakFree();
  Future<void> recordStreakRestore() => _service.recordStreakRestore();

  // ── Feature gate helpers ──────────────────────────────────────────────────

  bool get canPostMediaStatus => PlanLimits.canPostMediaStatus(isPro);
  bool get canScreenShare => PlanLimits.canScreenShare(isPro);
  bool get canExportChat => PlanLimits.canExportChat(isPro);
  bool get canCustomWallpaper => PlanLimits.canCustomWallpaper(isPro);
  int get maxVoiceDurationSec => PlanLimits.maxVoiceDurationSec(isPro);
  int get maxMediaSizeBytes => PlanLimits.maxMediaSizeBytes(isPro);

  // ── Loading timeout ───────────────────────────────────────────────────────

  void _startLoadingTimeout() {
    _cancelLoadingTimeout();
    _loadingTimeout = Timer(_loadingTimeoutDuration, () {
      if (_isLoading) {
        debugPrint(
            '[SubscriptionProvider] Loading timeout — resetting after ${_loadingTimeoutDuration.inSeconds}s');
        _isLoading = false;
        _error ??=
            'Purchase may still be processing — check back shortly';
        notifyListeners();
      }
    });
  }

  void _cancelLoadingTimeout() {
    _loadingTimeout?.cancel();
    _loadingTimeout = null;
  }

  // ── Private callbacks ─────────────────────────────────────────────────────

  void _onChanged() {
    _cancelLoadingTimeout();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  void _onError(String error) {
    _cancelLoadingTimeout();
    _isLoading = false;
    _error = error;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelLoadingTimeout();
    _service.onSubscriptionChanged = null;
    _service.onPurchaseError = null;
    super.dispose();
  }
}
