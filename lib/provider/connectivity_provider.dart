import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Watches the device's network connectivity and exposes a simple
/// [isOnline] flag. When the device transitions from offline → online,
/// [onBackOnline] fires so callers can flush any queued mesh messages.
class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// Callbacks registered by MeshNetworkService (or others) that should
  /// run when the device regains internet connectivity.
  final List<VoidCallback> _onBackOnlineCallbacks = [];

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    // Seed with current state
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    // Listen for changes
    _sub = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final wasOffline = !_isOnline;
    _isOnline = results.any((r) => r != ConnectivityResult.none);

    if (wasOffline && _isOnline) {
      // Just came back online — fire all callbacks
      for (final cb in _onBackOnlineCallbacks) {
        cb();
      }
    }
    notifyListeners();
  }

  /// Register a callback that fires whenever connectivity is restored.
  void addOnBackOnlineCallback(VoidCallback callback) {
    _onBackOnlineCallbacks.add(callback);
  }

  void removeOnBackOnlineCallback(VoidCallback callback) {
    _onBackOnlineCallbacks.remove(callback);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _onBackOnlineCallbacks.clear();
    super.dispose();
  }
}
