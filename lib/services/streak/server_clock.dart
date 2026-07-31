/// Trustworthy `now` for the client read path.
///
/// Streak *correctness* never depends on this class: `deadlineAt`, `riskLevel`
/// and every break are computed and stamped by the server. The client clock
/// only drives the ticking countdown and the read-side derivation in
/// `StreakRepository`, so a skewed device shows the same count and the same
/// break time as an accurate one (requirement 2.13).
///
/// This is the one file under `lib/services/streak/` that is allowed to read
/// the device clock — the purity guard test exempts it by name. Nothing else in
/// the streak subsystem may call `DateTime.now()`.
///
/// ## Reboot invalidation
///
/// Dart has no portable uptime API and this fix does not add a native
/// dependency for one, so "was the device rebooted since the sample?" is
/// approximated with two persisted markers:
///
///  * [_kProcessMarker] — a random id minted once per process at first use.
///    A stored sample whose marker differs was taken by an *earlier* process,
///    which may have been separated from this one by a reboot, an OS clock
///    correction or a timezone/NTP change.
///  * [_kSampleWallMs] — the device wall clock at sample time. If the device
///    clock has since moved *backwards* past that instant, the sample is
///    provably describing a clock that no longer exists.
///
/// Consequences:
///
///  * same process → the stored offset is used and [trusted] is true;
///  * new process → the stored offset is loaded as a *provisional* value so the
///    first frame is not wildly wrong, but [trusted] stays false until
///    [refresh] lands a fresh sample, and the UI suppresses the countdown
///    meanwhile;
///  * wall clock moved backwards → the stored offset is discarded outright.
///
/// This is deliberately conservative: it can only ever mark a good offset
/// untrusted, never a bad one trusted.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpDate;
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'streak_state.dart' show streakInstantFrom;

/// Where a successful sample came from. Diagnostics only.
enum ServerClockSource {
  /// The `Date` response header of a call the app already makes.
  dateHeader,

  /// `GET /serverTime`.
  serverTimeEndpoint,

  /// `users/{uid}.clockPing` written with `serverTimestamp()` and read back.
  firestorePing,

  /// Restored from `SharedPreferences` by the same process that measured it.
  persisted,
}

class ServerClock {
  ServerClock._();

  // ── Cloud Function endpoints ──────────────────────────────────────────────
  static const _serverTimeUrl =
      'https://us-central1-videocallapp-81166.cloudfunctions.net/serverTime';

  // ── HTTP config ───────────────────────────────────────────────────────────
  static const _httpTimeout = Duration(seconds: 10);

  /// How often [start] re-samples.
  static const refreshInterval = Duration(hours: 1);

  /// A sample is only adopted when the round trip was tight enough for the
  /// midpoint estimate to be meaningful.
  static const _maxAcceptableRoundTrip = Duration(seconds: 8);

  /// Offsets beyond this are treated as a broken sample rather than a broken
  /// device clock — a full year of skew is not something we can usefully act on.
  static const _maxAcceptableOffset = Duration(days: 365);

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const _kOffsetMs = 'gsg_streak_clock_offset_ms_v1';
  static const _kSampleWallMs = 'gsg_streak_clock_sample_wall_ms_v1';
  static const _kProcessMarker = 'gsg_streak_clock_process_marker_v1';

  /// Minted once per process. See "Reboot invalidation" above.
  static final String _processMarker =
      '${DateTime.now().toUtc().microsecondsSinceEpoch.toRadixString(36)}'
      '-${Random().nextInt(1 << 32).toRadixString(36)}';

  static Duration _offset = Duration.zero;
  static bool _trusted = false;
  static ServerClockSource? _source;
  static DateTime? _sampledAt;
  static bool _loaded = false;
  static Timer? _timer;
  static Future<bool>? _inFlight;

  // ── Reading ───────────────────────────────────────────────────────────────

  /// The best available estimate of the server's `now`, in UTC.
  ///
  /// Always returns a value: with no sample this session the offset is either
  /// the provisional persisted one or zero, and [trusted] tells the caller
  /// whether to render a ticking countdown off it.
  static DateTime now() => DateTime.now().toUtc().add(_offset);

  /// `serverInstant - deviceInstant` as currently believed.
  static Duration get offset => _offset;

  /// False until a sample has been obtained *this session*. A provisional
  /// offset restored from disk does not count.
  static bool get trusted => _trusted;

  /// Where the current offset came from, or `null` when there is none.
  static ServerClockSource? get source => _source;

  /// Device instant at which the current offset was measured, in UTC.
  static DateTime? get sampledAt => _sampledAt;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Loads any persisted offset, samples once, and re-samples hourly.
  ///
  /// Safe to call repeatedly. The app owns the call site; nothing here wires
  /// itself into startup.
  static Future<void> start() async {
    await _loadPersisted();
    _timer?.cancel();
    _timer = Timer.periodic(refreshInterval, (_) => refresh());
    await refresh();
  }

  /// Stops the hourly timer. Keeps the current offset.
  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Drops the offset and its persisted sample. Called on sign-out.
  static Future<void> clear() async {
    stop();
    _offset = Duration.zero;
    _trusted = false;
    _source = null;
    _sampledAt = null;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kOffsetMs);
      await prefs.remove(_kSampleWallMs);
      await prefs.remove(_kProcessMarker);
    } catch (e) {
      debugPrint('[ServerClock] clear failed (non-fatal): $e');
    }
  }

  /// Test seam: forget in-memory state without touching disk.
  @visibleForTesting
  static void resetForTest() {
    stop();
    _offset = Duration.zero;
    _trusted = false;
    _source = null;
    _sampledAt = null;
    _loaded = false;
    _inFlight = null;
  }

  // ── Sampling ──────────────────────────────────────────────────────────────

  /// Feeds in a `Date` header the app already received, so source (1) is
  /// reachable without an extra round trip.
  ///
  /// Cheap and synchronous in effect: any HTTP caller can hand its
  /// `response.headers['date']` over unconditionally. Ignores anything
  /// unparseable. Persisting the sample is fire-and-forget.
  ///
  /// A header's resolution is one second and its round trip is unknown, so it
  /// is only adopted when there is no trusted sample yet — a measured sample
  /// with a known round trip is always better.
  static void observeDateHeader(String? headerValue) {
    if (headerValue == null || headerValue.isEmpty) return;
    if (_trusted) return;
    final DateTime serverInstant;
    try {
      serverInstant = HttpDate.parse(headerValue).toUtc();
    } catch (_) {
      return;
    }
    _adopt(
      serverInstant: serverInstant,
      deviceInstant: DateTime.now().toUtc(),
      source: ServerClockSource.dateHeader,
    );
  }

  /// Obtains a fresh sample, trying in order: an already-observed `Date`
  /// header, `GET /serverTime`, then a `users/{uid}.clockPing` write read back.
  ///
  /// Returns whether the clock is trusted afterwards. Never throws — a failed
  /// refresh leaves the previous offset in place and logs quietly.
  /// Concurrent calls share one in-flight attempt.
  static Future<bool> refresh() {
    final pending = _inFlight;
    if (pending != null) return pending;
    final attempt = _refresh();
    _inFlight = attempt;
    return attempt.whenComplete(() => _inFlight = null);
  }

  static Future<bool> _refresh() async {
    await _loadPersisted();

    // (1) A `Date` header fed in through [observeDateHeader] has already been
    //     adopted by the time we get here; the measured sources below can only
    //     improve on it, and failing to reach them never regresses it.
    //
    // (2) GET /serverTime. This endpoint may not be deployed yet — a 404 is a
    //     normal, quiet outcome.
    if (await _sampleFromServerTime()) return _trusted;

    // (3) users/{uid}.clockPing serverTimestamp() written and read back.
    if (await _sampleFromFirestorePing()) return _trusted;

    return _trusted;
  }

  static Future<bool> _sampleFromServerTime() async {
    try {
      final idToken = await _idToken();
      final before = DateTime.now().toUtc();
      final response = await http.get(
        Uri.parse(_serverTimeUrl),
        headers: {
          'Accept': 'application/json',
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
      ).timeout(_httpTimeout);
      final after = DateTime.now().toUtc();

      if (response.statusCode != 200) {
        // Not deployed yet (task 5.8) or transiently unavailable. The `Date`
        // header is still usable even on an error response.
        _adoptFromHeaders(response.headers, before, after);
        return false;
      }

      DateTime? serverInstant;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          serverInstant = streakInstantFrom(decoded['now']);
        }
      } catch (_) {
        // Fall through to the Date header.
      }
      if (serverInstant == null) {
        return _adoptFromHeaders(response.headers, before, after);
      }
      return _adopt(
        serverInstant: serverInstant,
        deviceInstant: _midpoint(before, after),
        roundTrip: after.difference(before),
        source: ServerClockSource.serverTimeEndpoint,
      );
    } catch (e) {
      debugPrint('[ServerClock] /serverTime sample failed (non-fatal): $e');
      return false;
    }
  }

  static bool _adoptFromHeaders(
    Map<String, String> headers,
    DateTime before,
    DateTime after,
  ) {
    final header = headers['date'] ?? headers['Date'];
    if (header == null || header.isEmpty) return false;
    try {
      return _adopt(
        serverInstant: HttpDate.parse(header).toUtc(),
        deviceInstant: _midpoint(before, after),
        roundTrip: after.difference(before),
        source: ServerClockSource.dateHeader,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _sampleFromFirestorePing() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    try {
      final ref = FirebaseFirestore.instance.collection('users').doc(uid);
      final before = DateTime.now().toUtc();
      await ref.set(
        <String, dynamic>{'clockPing': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      final snapshot = await ref.get(const GetOptions(source: Source.server));
      final after = DateTime.now().toUtc();

      final serverInstant = streakInstantFrom(snapshot.data()?['clockPing']);
      if (serverInstant == null) return false;
      return _adopt(
        serverInstant: serverInstant,
        deviceInstant: _midpoint(before, after),
        roundTrip: after.difference(before),
        source: ServerClockSource.firestorePing,
      );
    } catch (e) {
      debugPrint('[ServerClock] clockPing sample failed (non-fatal): $e');
      return false;
    }
  }

  /// Applies a sample. Returns whether it was accepted.
  static bool _adopt({
    required DateTime serverInstant,
    required DateTime deviceInstant,
    required ServerClockSource source,
    Duration? roundTrip,
  }) {
    if (roundTrip != null && roundTrip > _maxAcceptableRoundTrip) {
      debugPrint('[ServerClock] discarding sample: round trip $roundTrip');
      return false;
    }
    final offset = serverInstant.difference(deviceInstant);
    if (offset.abs() > _maxAcceptableOffset) {
      debugPrint('[ServerClock] discarding implausible offset $offset');
      return false;
    }
    _offset = offset;
    _trusted = true;
    _source = source;
    _sampledAt = deviceInstant;
    _loaded = true;
    // Fire and forget: a failed write costs the next cold start its
    // provisional offset, nothing more.
    _persist(offset: offset, sampleWall: deviceInstant);
    return true;
  }

  /// The current user's Firebase ID token, or `null` when not signed in.
  ///
  /// `/serverTime` is unauthenticated by design, but sending the token when we
  /// have one matches the rest of the app's Cloud Function calls and lets the
  /// endpoint be tightened later without a client change.
  static Future<String?> _idToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }

  static DateTime _midpoint(DateTime a, DateTime b) =>
      a.add(Duration(microseconds: b.difference(a).inMicroseconds ~/ 2));

  // ── Persistence ───────────────────────────────────────────────────────────

  static Future<void> _persist({
    required Duration offset,
    required DateTime sampleWall,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kOffsetMs, offset.inMilliseconds);
      await prefs.setInt(
          _kSampleWallMs, sampleWall.toUtc().millisecondsSinceEpoch);
      await prefs.setString(_kProcessMarker, _processMarker);
    } catch (e) {
      debugPrint('[ServerClock] persist failed (non-fatal): $e');
    }
  }

  /// Restores a persisted offset once per process.
  ///
  /// Trusts it only when the marker says *this* process wrote it; otherwise it
  /// is provisional (see "Reboot invalidation"). Discards it entirely when the
  /// device wall clock has moved backwards past the sample instant.
  static Future<void> _loadPersisted() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final offsetMs = prefs.getInt(_kOffsetMs);
      final sampleWallMs = prefs.getInt(_kSampleWallMs);
      if (offsetMs == null || sampleWallMs == null) return;

      final sampleWall =
          DateTime.fromMillisecondsSinceEpoch(sampleWallMs, isUtc: true);
      if (DateTime.now().toUtc().isBefore(sampleWall)) {
        // The clock that produced this sample no longer exists.
        await prefs.remove(_kOffsetMs);
        await prefs.remove(_kSampleWallMs);
        await prefs.remove(_kProcessMarker);
        return;
      }

      final offset = Duration(milliseconds: offsetMs);
      if (offset.abs() > _maxAcceptableOffset) return;

      _offset = offset;
      _sampledAt = sampleWall;
      final sameProcess = prefs.getString(_kProcessMarker) == _processMarker;
      _trusted = sameProcess;
      _source = sameProcess ? ServerClockSource.persisted : null;
    } catch (e) {
      debugPrint('[ServerClock] load failed (non-fatal): $e');
    }
  }
}
