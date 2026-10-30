import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_chat_app/main.dart' show navigatorKey;
import 'package:video_chat_app/screens/call_screen.dart';
import 'package:video_chat_app/services/call_signaling_service.dart';

/// Android owns ringing. Flutter consumes only an explicit, persisted Accept.
class NativeCallService with WidgetsBindingObserver {
  NativeCallService._();
  static final instance = NativeCallService._();
  static const channel = MethodChannel('com.gupshupgo.app/native_calls');
  bool _processing = false;
  bool _started = false;
  Timer? _retry;
  final Set<String> _opened = {};

  void start() {
    if (!Platform.isAndroid || _started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    channel.setMethodCallHandler((call) async {
      if (call.method == 'accepted') await checkPending();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => checkPending());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) checkPending();
  }

  static Future<void> bind(String uid, String deviceId) async {
    if (!Platform.isAndroid) return;
    await channel
        .invokeMethod<void>('bind', {'userId': uid, 'deviceId': deviceId});
  }

  static Future<void> clear() async {
    if (Platform.isAndroid) await channel.invokeMethod<void>('clear');
  }

  static Future<void> finish(String id) async {
    if (!Platform.isAndroid) return;
    await channel.invokeMethod<void>('finish', {'channelId': id});
  }

  static Future<void> setActive(String id) async {
    if (Platform.isAndroid) await channel.invokeMethod<void>('active', {'channelId': id});
  }

  void _retryPending() {
    _retry?.cancel();
    _retry = Timer(const Duration(seconds: 1), checkPending);
  }

  Future<void> checkPending() async {
    if (!Platform.isAndroid || _processing) return;
    _processing = true;
    String? id;
    try {
      final call = await channel.invokeMapMethod<String, dynamic>('pending');
      if (call == null) return;
      id = call['channelId'] as String?;
      if (id == null || id.isEmpty) return;
      if (_opened.contains(id)) {
        await channel.invokeMethod<void>('acknowledge', {'channelId': id});
        return;
      }
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final nav = navigatorKey.currentState;
      if (uid == null || nav == null) {
        _retryPending();
        return;
      }
      if (uid != call['calleeId']) {
        await finish(id);
        return;
      }
      // Server transaction arbitrates Accept vs cancellation and simultaneous devices.
      final accepted = await CallSignalingService.answerCall(id,
          deviceId: call['deviceId'] as String?);
      if (!accepted) {
        await finish(id);
        return;
      }
      // A cancel may have arrived while the transaction was in flight.
      final pending = await channel.invokeMapMethod<String, dynamic>('pending');
      if (pending?['channelId'] != id ||
          FirebaseAuth.instance.currentUser?.uid != uid) return;
      _opened.add(id);
      unawaited(nav
          .push(MaterialPageRoute<void>(
              builder: (_) => CallScreen(
                    channelId: id!,
                    isCaller: false,
                    calleeId: call['callerId'] as String? ?? '',
                    calleeName:
                        call['callerName'] as String? ?? 'Incoming caller',
                    isAudioOnly: call['isAudioOnly'] == 'true',
                  )))
          .whenComplete(() => finish(id!)));
      await channel.invokeMethod<void>('acknowledge', {'channelId': id});
    } on FirebaseException catch (error) {
      debugPrint('Native call handoff: ${error.code}');
      // Native pending() has a bounded lifetime; transient network failures retry.
      if (error.code == 'permission-denied' ||
          error.code == 'unauthenticated') {
        if (id != null) await finish(id);
      } else {
        _retryPending();
      }
    } catch (error) {
      debugPrint('Native call handoff unavailable: $error');
      _retryPending();
    } finally {
      _processing = false;
    }
  }
}
