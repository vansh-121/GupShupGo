/// GupShupGo Pro — Subscription state provider.
///
/// A [ChangeNotifier] that wraps [SubscriptionService] and exposes
/// reactive subscription state to the widget tree via Provider.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:video_chat_app/models/subscription_model.dart';
import 'package:video_chat_app/services/subscription_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _service = SubscriptionService.instance;

  bool _isLoading = false;
  String? _error;

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

    final success = await _service.purchase(product);

    // Note: the actual subscription activation happens asynchronously
    // via the purchase stream listener in SubscriptionService.
    // _isLoading will be cleared when _onChanged fires.
    if (!success) {
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
  Future<void> restorePurchases() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await _service.restorePurchases();

    // Wait a bit for the stream to process restored purchases
    await Future.delayed(const Duration(seconds: 2));

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

  // ── Private callbacks ─────────────────────────────────────────────────────

  void _onChanged() {
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  void _onError(String error) {
    _isLoading = false;
    _error = error;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.onSubscriptionChanged = null;
    _service.onPurchaseError = null;
    super.dispose();
  }
}
