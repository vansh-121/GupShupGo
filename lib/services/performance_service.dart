import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Thin, static-only wrapper around [FirebasePerformance].
///
/// Why a wrapper?
/// - One import to rule them all — no `firebase_performance` scattered everywhere.
/// - Debug-mode guard in a single place (debug builds are excluded from the
///   Performance dashboard but we still allow traces so they surface in
///   verbose logging).
/// - Provides typed helpers so call-sites don't have to remember the API.
///
/// Usage examples:
/// ```dart
/// // ── Custom traces ──────────────────────────────────────────────────────
/// final trace = await PerformanceService.startTrace('agora_init');
/// // ... do work ...
/// await PerformanceService.stopTrace(trace);
///
/// // ── HTTP metrics ───────────────────────────────────────────────────────
/// final metric = PerformanceService.newHttpMetric(url, HttpMethod.Post);
/// await metric.start();
/// final response = await http.post(...);
/// metric.httpResponseCode = response.statusCode;
/// metric.responsePayloadSize = response.contentLength;
/// await metric.stop();
/// ```
class PerformanceService {
  PerformanceService._(); // static-only

  static final _perf = FirebasePerformance.instance;

  // ── Trace names (constants so typos are caught at compile time) ───────────

  /// Agora RTC engine init (from createAgoraRtcEngine to startPreview).
  static const kTraceAgoraInit = 'agora_engine_init';

  /// Agora RTC engine teardown (leaveChannel + release).
  static const kTraceAgoraRelease = 'agora_engine_release';

  /// Time from sendCallNotification() call to HTTP response.
  static const kTraceCallNotification = 'fcm_call_notification';

  /// Time from sendMessageNotification() call to HTTP response.
  static const kTraceMessageNotification = 'fcm_message_notification';

  /// Full call setup time (createCallDocument → Agora join).
  static const kTraceCallSetup = 'call_setup_e2e';

  // ── Auth traces ─────────────────────────────────────────────────────────
  static const kTraceAuthGoogle = 'auth_sign_in_google';
  static const kTraceAuthPhone  = 'auth_sign_in_phone';
  static const kTraceAuthEmail  = 'auth_sign_in_email';

  // ── Messaging ────────────────────────────────────────────────────────────
  static const kTraceChatSend = 'chat_send_message';

  // ── Status uploads ───────────────────────────────────────────────────────
  static const kTraceStatusUpload = 'status_upload_file';

  // ── Performance collection toggle ─────────────────────────────────────────

  /// Enables or disables collection (mirrors Crashlytics' pattern).
  /// Call this from main() after Firebase.initializeApp().
  static Future<void> init() async {
    // Performance data is always collected in non-debug mode.
    // In debug mode we keep it enabled so developers can still verify that
    // traces fire; the console filters them with the "Debug" label.
    await _perf.setPerformanceCollectionEnabled(true);

    if (kDebugMode) {
      debugPrint('📊 Firebase Performance Monitoring initialised '
          '(collection enabled — debug mode)');
    }
  }

  // ── Custom traces ──────────────────────────────────────────────────────────

  /// Creates **and starts** a custom trace with the given [name].
  ///
  /// Always pair with [stopTrace] to avoid orphaned traces.
  static Future<Trace> startTrace(
    String name, {
    Map<String, String> attributes = const {},
  }) async {
    final trace = _perf.newTrace(name);
    for (final entry in attributes.entries) {
      trace.putAttribute(entry.key, entry.value);
    }
    await trace.start();
    return trace;
  }

  /// Stops a trace started with [startTrace].
  ///
  /// [attributes] — optional key/value pairs added just before stopping (e.g.
  ///   result codes, counts known only at completion).
  static Future<void> stopTrace(
    Trace trace, {
    Map<String, String> attributes = const {},
    Map<String, int> metrics = const {},
  }) async {
    for (final entry in attributes.entries) {
      trace.putAttribute(entry.key, entry.value);
    }
    for (final entry in metrics.entries) {
      trace.setMetric(entry.key, entry.value);
    }
    await trace.stop();
  }

  // ── Convenience: run a block inside a trace ────────────────────────────────

  /// Wraps [block] in a start/stop trace pair and returns its result.
  ///
  /// If [block] throws, the trace is stopped before re-throwing.
  static Future<T> traceAsync<T>(
    String traceName,
    Future<T> Function(Trace trace) block, {
    Map<String, String> attributes = const {},
  }) async {
    final trace = await startTrace(traceName, attributes: attributes);
    try {
      final result = await block(trace);
      await stopTrace(trace, attributes: {'result': 'success'});
      return result;
    } catch (e) {
      // Record failure attribute before stopping so it shows in the console
      try {
        await stopTrace(trace, attributes: {
          'result': 'error',
          'error_type': e.runtimeType.toString(),
        });
      } catch (_) {} // stopTrace itself should never throw
      rethrow;
    }
  }

  // ── HTTP metrics ───────────────────────────────────────────────────────────

  /// Returns a pre-configured [HttpMetric] for the given [url] and [method].
  ///
  /// Callers are responsible for calling [HttpMetric.start], populating
  /// [HttpMetric.httpResponseCode] / [HttpMetric.responsePayloadSize], and
  /// then calling [HttpMetric.stop].
  static HttpMetric newHttpMetric(String url, HttpMethod method) {
    return _perf.newHttpMetric(url, method);
  }

  // ── Attribute helpers ──────────────────────────────────────────────────────

  /// Safely sets an attribute on [trace], silently ignoring any errors.
  static void setAttribute(Trace trace, String key, String value) {
    try {
      trace.putAttribute(key, value);
    } catch (_) {}
  }

  /// Safely increments a counter metric on [trace].
  static void incrementMetric(Trace trace, String metric, {int by = 1}) {
    try {
      trace.incrementMetric(metric, by);
    } catch (_) {}
  }
}
