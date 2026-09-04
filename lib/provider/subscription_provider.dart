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
import 'package:video_chat_app/services/feature_flag_service.dart';
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

  /// Whether the Pro feature set is visible in the UI at all.
  /// Controlled by Firebase Remote Config — when `false`, all Pro UI
  /// (cards, badges, upgrade prompts, purchase flows) is hidden.
  bool get isProFeatureVisible => FeatureFlagService.instance.isProEnabled;

  /// Whether the current user has an active Pro subscription AND the
  /// feature flag allows it. When the flag is off, this always returns
  /// `false` so all existing `isPro` checks throughout the app
  /// automatically treat the user as free.
  ///
  /// Delegates to [SubscriptionService.isProGated] so that services without a
  /// `BuildContext` apply the identical masking rule.
  bool get isPro => _service.isProGated;

  /// The raw Play entitlement, ignoring the `pro_enabled` flag.
  ///
  /// Ad suppression MUST use this and never [isPro]. [isPro] is deliberately
  /// masked by the flag so that turning Pro off treats everyone as free — but
  /// applied to ads that logic inverts: with `pro_enabled=false`, [isPro] is
  /// `false` even for someone with a live subscription, so banners would be
  /// shown to the exact users who paid to remove them.
  ///
  /// This is only for "has this person paid?" questions. For "should Pro UI be
  /// visible?", keep using [isPro] / [isProFeatureVisible].
  bool get hasActiveProEntitlement => _service.isPro;

  /// **The** gate for a Pro *capability*. Every feature check should use this.
  ///
  /// `pro_enabled` off does not mean "everyone is free" — it means the Pro
  /// programme is not live: no Premium screen, no pricing, nothing to buy. A
  /// capability withheld in that state is withheld from *everybody*, forever,
  /// in exchange for nothing. So with the flag off every gate opens, which is
  /// already what [PremiumGate.checkAndPrompt] does, and what
  /// `SubscriptionService.isProUnlocked` does for callers with no `BuildContext`.
  ///
  /// The three things this deliberately does **not** cover:
  ///   * **Purchase surfaces** — the upgrade card, pricing, upsell sheets. Those
  ///     follow [isProFeatureVisible]: there is nothing to sell yet.
  ///   * **The Pro badge** — an identity marker for someone who paid, not a
  ///     capability. It follows [isPro], so the flag being off hides it rather
  ///     than handing it to everyone.
  ///   * **Ad suppression** — [hasActiveProEntitlement], see its doc. Ads are
  ///     the revenue *because* Pro is not live; opening this gate must not turn
  ///     them off.
  ///
  /// The cost, accepted deliberately: on the day the flag flips, users lose
  /// features they had been using. That is the normal shape of a paid tier
  /// arriving, and it is strictly better than shipping a picker with one theme
  /// in it and an export button nobody can press.
  bool get isProUnlocked => !isProFeatureVisible || isPro;

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
    
    // Listen to real-time changes of feature flags to update UI immediately
    FeatureFlagService.instance.addListener(notifyListeners);

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
  //
  // `canRestoreStreakFree` / `recordStreakRestore` are gone. The weekly free
  // restore allowance is server-side (`users/{uid}.streakRestoreAllowance`):
  // availability comes from `GET /streakRestoreQuote` (`canUseFreePerk`) and it
  // is consumed inside the `POST /streakRestore` transaction. See `StreakApi`.

  // ── Feature gate helpers ──────────────────────────────────────────────────
  //
  // All of these route through `isProUnlocked`, never `isPro` — see its doc.
  // `isPro` here would mean a capability is locked whenever `pro_enabled` is
  // false, i.e. locked for everyone with no way to unlock it.

  bool get canPostMediaStatus => PlanLimits.canPostMediaStatus(isProUnlocked);
  bool get canScreenShare => PlanLimits.canScreenShare(isProUnlocked);
  bool get canExportChat => PlanLimits.canExportChat(isProUnlocked);
  bool get canCustomWallpaper => PlanLimits.canCustomWallpaper(isProUnlocked);

  /// Whether outgoing media gets the Pro quality tier.
  bool get hasProMediaQuality => isProUnlocked;
  int get maxStatusVideoSec => PlanLimits.maxStatusVideoSec(isProUnlocked);

  /// Voice cap in seconds, or `null` for uncapped.
  int? get maxVoiceDurationSec => PlanLimits.maxVoiceDurationSec(isProUnlocked);

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
    FeatureFlagService.instance.removeListener(notifyListeners);
    super.dispose();
  }
}
