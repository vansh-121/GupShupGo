/// Transport for the streak Cloud Functions endpoints (task 5.8).
///
/// This file is exempt from the streak purity guard: it is the layer that is
/// *allowed* to touch the network and the device clock. Everything above it
/// (`streak_state.dart`, `streak_engine.dart`) stays pure.
///
/// Conventions copied from [FCMService] / [SubscriptionService] so there is one
/// HTTP idiom in the app:
///
///  * one `const` `…cloudfunctions.net/<name>` URL per endpoint,
///  * `Authorization: 'Bearer $idToken'` from `FirebaseAuth.currentUser`,
///  * `package:http` with a 15 second timeout,
///  * `debugPrint` on failure, never an uncaught throw for an expected outcome.
///
/// Every response's `Date` header is offered to [ServerClock] (task 7.1) as a
/// clock sample — see [_observeDateHeader].
library;

import 'dart:convert';
import 'dart:io' show HttpDate;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'streak_state.dart';

/// The quote rendered by `StreakRestoreDialog` before the user commits.
///
/// Shape: `{ previousCount, cost, canUseFreePerk, restoreDeadlineAt,
/// serverNow, contactName }`.
@immutable
class StreakRestoreQuote {
  const StreakRestoreQuote({
    required this.previousCount,
    required this.cost,
    required this.canUseFreePerk,
    this.restoreDeadlineAt,
    this.serverNow,
    this.contactName,
  });

  /// The count that will be restored.
  final int previousCount;

  /// Points the server will charge when the free perk is not used.
  final int cost;

  /// True when the caller is Pro and has an unused weekly allowance. Comes
  /// from the server, never from `SubscriptionService`.
  final bool canUseFreePerk;

  /// End of the restore window, server-stamped.
  final DateTime? restoreDeadlineAt;

  /// Server time at the moment the quote was produced.
  final DateTime? serverNow;

  /// Display name of the other participant.
  final String? contactName;

  static StreakRestoreQuote? fromJson(Map<String, dynamic> json) {
    final previousCount = _asInt(json['previousCount']);
    if (previousCount == null) return null;
    return StreakRestoreQuote(
      previousCount: previousCount,
      cost: _asInt(json['cost']) ?? 0,
      canUseFreePerk: json['canUseFreePerk'] == true,
      restoreDeadlineAt: streakInstantFrom(json['restoreDeadlineAt']),
      serverNow: streakInstantFrom(json['serverNow']),
      contactName: json['contactName'] as String?,
    );
  }
}

/// Outcome of `POST /streakRestore`.
///
/// Expected refusals are statuses, not exceptions: the dialog has a distinct
/// message for each one and none of them is a programming error.
enum StreakRestoreStatus {
  /// Restored. [StreakRestoreResult.restoredCount] and `costPaid` are set.
  success,

  /// The user does not have `cost` gup points.
  insufficientPoints,

  /// `brokenAt == null` — there is no broken streak to restore.
  nothingToRestore,

  /// `serverNow > restoreDeadlineAt` per **server** time.
  windowExpired,

  /// The caller is not in `state.participants`.
  notParticipant,

  /// Not signed in, so no ID token could be attached.
  notSignedIn,

  /// Network failure, timeout, 5xx, or an unrecognised server response. Safe
  /// to retry.
  transportFailure,
}

/// Result of `POST /streakRestore`.
@immutable
class StreakRestoreResult {
  const StreakRestoreResult({
    required this.status,
    this.restoredCount,
    this.costPaid,
    this.usedFreePerk = false,
    this.message,
  });

  const StreakRestoreResult.failure(this.status, {this.message})
      : restoredCount = null,
        costPaid = null,
        usedFreePerk = false;

  final StreakRestoreStatus status;

  /// The count after the restore (equal to the previous count).
  final int? restoredCount;

  /// Points actually deducted — `0` when the free perk covered it.
  final int? costPaid;

  /// True when the Pro weekly allowance was consumed instead of points.
  final bool usedFreePerk;

  /// Server-supplied detail, useful for the transport-failure snackbar.
  final String? message;

  bool get isSuccess => status == StreakRestoreStatus.success;
}

/// Thin, stateless client for the streak endpoints.
class StreakApi {
  StreakApi._();
  static final StreakApi instance = StreakApi._();

  // ── Cloud Function endpoints ──────────────────────────────────────────────
  static const _base =
      'https://us-central1-videocallapp-81166.cloudfunctions.net';
  static const _serverTimeUrl = '$_base/serverTime';
  static const _streakEvaluateUrl = '$_base/streakEvaluate';
  static const _streakRestoreQuoteUrl = '$_base/streakRestoreQuote';
  static const _streakRestoreUrl = '$_base/streakRestore';

  // ── HTTP config ───────────────────────────────────────────────────────────
  static const _httpTimeout = Duration(seconds: 15);

  /// `GET /serverTime` → `{ now: <epochMillis> }`. Unauthenticated.
  ///
  /// Returns `null` on any failure — [ServerClock] treats a null as "this
  /// source is unavailable" and moves on to the next one, so this must never
  /// throw.
  Future<DateTime?> serverTime() async {
    try {
      final response = await http
          .get(Uri.parse(_serverTimeUrl))
          .timeout(_httpTimeout);
      _observeDateHeader(response);
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return null;
      return streakInstantFrom(data['now']);
    } catch (e) {
      debugPrint('[StreakApi] serverTime failed: $e');
      return null;
    }
  }

  /// `POST /streakEvaluate { roomId }`. Authenticated.
  ///
  /// Fire-and-forget nudge used when the client's derived state is broken but
  /// the stored document has not caught up yet. Rate-limited server-side to one
  /// call per room per five minutes and purely an optimisation, so every
  /// failure is swallowed.
  Future<void> streakEvaluate(String roomId) async {
    if (roomId.isEmpty) return;
    try {
      final idToken = await _getIdToken();
      if (idToken == null) return;
      final response = await http
          .post(
            Uri.parse(_streakEvaluateUrl),
            headers: _authHeaders(idToken),
            body: jsonEncode({'roomId': roomId}),
          )
          .timeout(_httpTimeout);
      _observeDateHeader(response);
      if (response.statusCode != 200) {
        debugPrint(
            '[StreakApi] streakEvaluate ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[StreakApi] streakEvaluate failed: $e');
    }
  }

  /// `GET /streakRestoreQuote?roomId=…`. Authenticated.
  ///
  /// Returns `null` when the quote cannot be obtained (not signed in, no broken
  /// streak, network failure) — the dialog then shows its unavailable state.
  Future<StreakRestoreQuote?> streakRestoreQuote(String roomId) async {
    if (roomId.isEmpty) return null;
    try {
      final idToken = await _getIdToken();
      if (idToken == null) return null;
      final uri = Uri.parse(_streakRestoreQuoteUrl)
          .replace(queryParameters: {'roomId': roomId});
      final response = await http
          .get(uri, headers: _authHeaders(idToken))
          .timeout(_httpTimeout);
      _observeDateHeader(response);
      if (response.statusCode != 200) {
        debugPrint(
            '[StreakApi] streakRestoreQuote ${response.statusCode}: ${response.body}');
        return null;
      }
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return null;
      return StreakRestoreQuote.fromJson(data);
    } catch (e) {
      debugPrint('[StreakApi] streakRestoreQuote failed: $e');
      return null;
    }
  }

  /// `POST /streakRestore { roomId, useFreePerk }`. Authenticated.
  ///
  /// The server owns the whole decision: window validity against server time,
  /// the cost tier, the Pro weekly allowance and the point deduction. Expected
  /// refusals come back as a [StreakRestoreStatus] rather than a thrown error.
  Future<StreakRestoreResult> streakRestore(
    String roomId, {
    bool useFreePerk = false,
  }) async {
    if (roomId.isEmpty) {
      return const StreakRestoreResult.failure(
        StreakRestoreStatus.nothingToRestore,
      );
    }

    final idToken = await _getIdToken();
    if (idToken == null) {
      return const StreakRestoreResult.failure(
        StreakRestoreStatus.notSignedIn,
      );
    }

    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(_streakRestoreUrl),
            headers: _authHeaders(idToken),
            body: jsonEncode({
              'roomId': roomId,
              'useFreePerk': useFreePerk,
            }),
          )
          .timeout(_httpTimeout);
    } catch (e) {
      debugPrint('[StreakApi] streakRestore transport failure: $e');
      return StreakRestoreResult.failure(
        StreakRestoreStatus.transportFailure,
        message: '$e',
      );
    }

    _observeDateHeader(response);

    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {
      // Non-JSON body — fall through with the raw text as the message.
    }

    final reason = (body?['reason'] ?? body?['error'] ?? body?['code'])
        ?.toString()
        .toLowerCase();
    final message =
        body?['message'] as String? ?? body?['detail'] as String? ?? reason;

    if (response.statusCode == 200 && body != null && body['ok'] != false) {
      return StreakRestoreResult(
        status: StreakRestoreStatus.success,
        restoredCount: _asInt(body['restoredCount']) ?? _asInt(body['count']),
        costPaid: _asInt(body['costPaid']) ?? _asInt(body['cost']),
        usedFreePerk: body['usedFreePerk'] == true,
        message: message,
      );
    }

    return StreakRestoreResult.failure(
      _statusFor(response.statusCode, reason),
      message: message ?? response.body,
    );
  }

  /// Maps the server's refusal onto the statuses the dialog renders.
  static StreakRestoreStatus _statusFor(int httpStatus, String? reason) {
    if (reason != null) {
      if (reason.contains('insufficient') || reason.contains('points')) {
        return StreakRestoreStatus.insufficientPoints;
      }
      if (reason.contains('expired') || reason.contains('window')) {
        return StreakRestoreStatus.windowExpired;
      }
      if (reason.contains('nothing') || reason.contains('not-broken')) {
        return StreakRestoreStatus.nothingToRestore;
      }
      if (reason.contains('participant') ||
          reason.contains('forbidden') ||
          reason.contains('permission')) {
        return StreakRestoreStatus.notParticipant;
      }
      if (reason.contains('unauthenticated') || reason.contains('unauth')) {
        return StreakRestoreStatus.notSignedIn;
      }
    }
    switch (httpStatus) {
      case 401:
        return StreakRestoreStatus.notSignedIn;
      case 402:
        return StreakRestoreStatus.insufficientPoints;
      case 403:
        return StreakRestoreStatus.notParticipant;
      case 404:
        return StreakRestoreStatus.nothingToRestore;
      case 409:
      case 410:
        return StreakRestoreStatus.windowExpired;
      default:
        return StreakRestoreStatus.transportFailure;
    }
  }

  static Map<String, String> _authHeaders(String idToken) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      };

  /// Returns the current user's Firebase ID token, or null if not signed in.
  static Future<String?> _getIdToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }

  /// Offers the response's `Date` header to [ServerClock] as a free clock
  /// sample (design §"Client read path", task 7.1).
  ///
  /// HOOK — `server_clock.dart` does not exist yet. Once task 7.1 lands,
  /// replace the body with `ServerClock.instance.observeDateHeader(raw)` and
  /// import it; the parse below stays there so the clock only ever sees a
  /// normalised UTC instant.
  static void _observeDateHeader(http.BaseResponse response) {
    final raw = response.headers['date'];
    if (raw == null || raw.isEmpty) return;
    final parsed = _parseHttpDate(raw);
    if (parsed == null) return;
    // TODO(task 7.1): ServerClock.instance.observeServerInstant(parsed);
    _lastObservedServerDate = parsed;
  }

  /// Most recent `Date` header seen, in UTC. Exposed so [ServerClock] can pull
  /// the sample until the push hook above is wired up.
  static DateTime? _lastObservedServerDate;
  static DateTime? get lastObservedServerDate => _lastObservedServerDate;

  static DateTime? _parseHttpDate(String raw) {
    try {
      return HttpDate.parse(raw).toUtc();
    } catch (_) {
      return DateTime.tryParse(raw)?.toUtc();
    }
  }
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
