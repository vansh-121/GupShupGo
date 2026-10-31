import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_chat_app/main.dart' show navigatorKey;
import 'package:video_chat_app/screens/call_screen.dart';
import 'package:video_chat_app/screens/incoming_call_screen.dart';
import 'package:video_chat_app/services/call_acceptance.dart';
import 'package:video_chat_app/services/call_signaling_service.dart';
import 'package:video_chat_app/services/crashlytics_service.dart';

/// Android owns ringing and its durable inbox. An existing foreground engine
/// mirrors that state in the app; both Accept buttons use the same handoff.
class NativeCallService with WidgetsBindingObserver {
  NativeCallService._()
      : _currentUserId = (() => FirebaseAuth.instance.currentUser?.uid),
        _navigator = (() => navigatorKey.currentState),
        _supported = (() => Platform.isAndroid),
        _callBuilder = null;

  @visibleForTesting
  NativeCallService.forTest({
    required String? Function() currentUserId,
    required NavigatorState? Function() navigator,
    required Widget Function(Map<String, dynamic>, CallAcceptance) callBuilder,
  })  : _currentUserId = currentUserId,
        _navigator = navigator,
        _supported = (() => true),
        _callBuilder = callBuilder;

  static final instance = NativeCallService._();
  static const channel = MethodChannel('com.gupshupgo.app/native_calls');
  final String? Function() _currentUserId;
  final NavigatorState? Function() _navigator;
  final bool Function() _supported;
  final Widget Function(Map<String, dynamic>, CallAcceptance)? _callBuilder;
  bool _processing = false;
  bool _checkAgain = false;
  bool _started = false;
  Timer? _retry;
  final Set<String> _opened = {};
  Route<void>? _incomingRoute;
  String? _incomingId;

  bool get isShowingCall => _incomingRoute != null || _opened.isNotEmpty;

  void start() {
    if (!_supported() || _started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    channel.setMethodCallHandler((call) async {
      if (call.method == 'accepted' || call.method == 'stateChanged') {
        await checkPending();
      }
    });
    unawaited(checkPending());
  }

  @visibleForTesting
  void stop() {
    _started = false;
    _retry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    channel.setMethodCallHandler(null);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(checkPending());
  }

  static Future<void> bind(String uid, String deviceId) async {
    if (!Platform.isAndroid) return;
    await channel
        .invokeMethod<void>('bind', {'userId': uid, 'deviceId': deviceId});
    unawaited(instance.checkPending());
  }

  static Future<void> clear() async {
    if (Platform.isAndroid) await channel.invokeMethod<void>('clear');
  }

  static Future<void> finish(String id) async {
    if (Platform.isAndroid) {
      await channel.invokeMethod<void>('finish', {'channelId': id});
    }
  }

  static Future<void> setActive(String id) async {
    if (Platform.isAndroid) {
      await channel.invokeMethod<void>('active', {'channelId': id});
    }
  }

  static void recordEvent(String id, String event) {
    debugPrint('Call $id: $event');
    if (Platform.isAndroid) {
      final safeEvent = event.replaceAll(RegExp(r'[^A-Za-z0-9_:-]'), '_');
      unawaited(channel.invokeMethod<void>('recordEvent', {
        'channelId': id,
        'event':
            safeEvent.length > 100 ? safeEvent.substring(0, 100) : safeEvent,
      }).catchError((_) {}));
    }
    try {
      unawaited(CrashlyticsService.log('Call $id: $event').catchError((_) {}));
    } catch (_) {
      // Diagnostics must never prevent accepting or closing a call.
    }
  }

  void _retryPending() {
    _retry?.cancel();
    _retry = Timer(const Duration(seconds: 1), checkPending);
  }

  Future<void> checkPending() async {
    if (!_supported()) return;
    if (_processing) {
      _checkAgain = true;
      return;
    }
    _processing = true;
    try {
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return;
      }
      final pending = await channel.invokeMapMethod<String, dynamic>('pending');
      final ringing = await channel.invokeMapMethod<String, dynamic>('ringing');
      final uid = _currentUserId();
      final nav = _navigator();
      if (uid == null || nav == null) {
        if (pending != null || ringing != null) _retryPending();
        return;
      }
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return;
      }
      final acceptedId = pending?['channelId'] as String?;
      if (acceptedId != null && acceptedId.isNotEmpty) {
        if (pending!['calleeId'] != uid) {
          await channel.invokeMethod<void>('finish', {'channelId': acceptedId});
        } else if (!_opened.contains(acceptedId)) {
          _openAcceptedCall(nav, acceptedId, uid, pending);
        }
      }
      final ringingId = ringing?['channelId'] as String?;
      if (_incomingRoute != null && _incomingId != ringingId) {
        _removeIncoming(nav);
      }
      if (ringingId != null &&
          ringingId.isNotEmpty &&
          ringing!['calleeId'] == uid &&
          _opened.isEmpty &&
          _incomingRoute == null) {
        _openIncomingCall(nav, ringingId, ringing);
      }
    } catch (error) {
      debugPrint('Native call state unavailable: $error');
      _retryPending();
    } finally {
      _processing = false;
      if (_checkAgain) {
        _checkAgain = false;
        unawaited(checkPending());
      }
    }
  }

  void _removeIncoming(NavigatorState nav) {
    final route = _incomingRoute;
    _incomingRoute = null;
    _incomingId = null;
    // Remove our route specifically. A notification must not pop an unrelated
    // screen or a permission dialog that happened to open above it.
    if (route != null && route.isActive) nav.removeRoute(route);
  }

  void _openIncomingCall(
      NavigatorState nav, String id, Map<String, dynamic> call) {
    final route = MaterialPageRoute<void>(
      settings: RouteSettings(name: '/calls/$id/incoming'),
      builder: (_) => IncomingCallScreen(
        channelId: id,
        callerId: call['callerId'] as String? ?? '',
        callerName: call['callerName'] as String? ?? 'Incoming caller',
        callerPhotoUrl: call['callerPhotoUrl'] as String?,
        isAudioOnly: call['isAudioOnly'] == 'true',
        onNativeAccept: () async {
          await channel.invokeMethod<bool>('accept', {'channelId': id});
          await checkPending();
        },
        onNativeDecline: () async {
          await channel.invokeMethod<void>('decline', {'channelId': id});
          await checkPending();
        },
      ),
    );
    _incomingId = id;
    _incomingRoute = route;
    unawaited(nav.push(route).whenComplete(() {
      if (identical(_incomingRoute, route)) {
        _incomingRoute = null;
        _incomingId = null;
      }
    }));
  }

  void _openAcceptedCall(
      NavigatorState nav, String id, String uid, Map<String, dynamic> call) {
    final deviceId = call['deviceId'] as String? ?? '';
    final acceptance = CallAcceptance(
      isPending: () async {
        final pending =
            await channel.invokeMapMethod<String, dynamic>('pending');
        return pending?['channelId'] == id && _currentUserId() == uid;
      },
      answer: () => CallSignalingService.answerCallOnDevice(id,
          userId: uid,
          deviceId: deviceId,
          onEvent: (event) => recordEvent(id, event)),
      acknowledge: () async =>
          await channel.invokeMethod<bool>('acknowledge', {'channelId': id}) ==
          true,
      finishNative: () =>
          channel.invokeMethod<void>('finish', {'channelId': id}),
      releaseClaim: () => CallSignalingService.finishCallOnDevice(id,
          userId: uid, deviceId: deviceId),
      onEvent: (event) => recordEvent(id, event),
    );
    _opened.add(id);
    final route = MaterialPageRoute<void>(
      settings: RouteSettings(name: '/calls/$id/active'),
      builder: (_) =>
          _callBuilder?.call(call, acceptance) ??
          CallScreen(
            channelId: id,
            isCaller: false,
            calleeId: call['callerId'] as String? ?? '',
            calleeName: call['callerName'] as String? ?? 'Incoming caller',
            isAudioOnly: call['isAudioOnly'] == 'true',
            acceptance: acceptance,
          ),
    );
    final incoming = _incomingRoute;
    final replaceIncoming = incoming != null && incoming.isCurrent;
    _incomingRoute = null;
    _incomingId = null;
    final closed = replaceIncoming
        ? nav.pushReplacement<void, void>(route)
        : nav.push(route);
    if (!replaceIncoming && incoming != null && incoming.isActive) {
      nav.removeRoute(incoming);
    }
    unawaited(closed.whenComplete(() {
      unawaited(acceptance.close());
      _opened.remove(id);
    }));
  }
}
