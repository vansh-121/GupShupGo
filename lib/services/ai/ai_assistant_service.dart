/// GupShupGo — GupShup AI assistant service.
///
/// A dedicated you↔AI conversation that never touches the app's human↔human
/// E2EE (Signal) chats. The transcript lives only in [PlaintextStore] under a
/// per-account room id ([aiRoomIdFor]), so it is local-only and wiped on
/// sign-out by `PlaintextStore.wipe()` along with every other local message —
/// no Firestore, no Signal session, and none of `ChatService`'s streak /
/// notification side effects.
///
/// The client is deliberately dumb about cost: it never decides the quota. It
/// POSTs the turn to the `askGupShupAi` Cloud Function with the user's Firebase
/// ID token; the function reads `config/ai`, enforces the per-user daily
/// allowance server-side, and proxies to Gemini with a key that never ships in
/// the app. A 429 means today's cap is spent (offer an ad / upgrade); a 503
/// means the backend is off or Gemini is busy. Neither is charged, and on both
/// the user's own message is kept so a retry loses nothing.
library;

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:video_chat_app/models/message_model.dart';
import 'package:video_chat_app/services/crypto/plaintext_store.dart';

/// Reserved local room id *prefix* for the AI transcript. The full room id is
/// per-account ([aiRoomIdFor]) — `gupshup_ai:<uid>`.
///
/// Scoping by account is load-bearing for privacy: [PlaintextStore] is only
/// wiped by an explicit sign-out, but an auth invalidation (token revoked or
/// expired, `AuthService.listenForAuthInvalidation`) clears the saved uid
/// *without* wiping the store. A single shared room id would then be readable —
/// and replayed to Gemini as history — by whoever signs in next on the device.
/// A per-account id makes every other account read an empty transcript instead.
///
/// The prefix has no `uid_uid` shape, so a real 1:1 chat room id can never
/// collide with it. The assistant's own messages are still stored with
/// `senderId == kAiRoomId`, which is `!= <uid>`, and that inequality is how a
/// stored message is told apart from the user's own (`senderId == <uid>`) at
/// render — the per-account suffix lives only on the room key, not the sender.
const String kAiRoomId = 'gupshup_ai';

/// The per-account AI transcript room id for [uid]. See [kAiRoomId].
String aiRoomIdFor(String uid) => '$kAiRoomId:$uid';

/// Outcome of [AiAssistantService.sendMessage].
///
/// Expected control flow, not exceptions: a spent quota and a busy backend are
/// normal states the chat UI renders differently, so the screen switches over
/// these rather than catching. Only genuinely unrecoverable cases (not signed
/// in, unparseable response) land in [AiSendFailed].
sealed class AiSendResult {
  const AiSendResult();
}

/// Gemini replied. The reply is already persisted locally; [remaining] is how
/// many messages are left in today's allowance.
class AiReplyReceived extends AiSendResult {
  const AiReplyReceived(this.remaining);
  final int remaining;
}

/// Today's allowance is spent. [isPro] drives whether to offer an upgrade;
/// [canEarn] whether a rewarded top-up is still available today.
class AiQuotaExceeded extends AiSendResult {
  const AiQuotaExceeded({required this.isPro, required this.canEarn});
  final bool isPro;
  final bool canEarn;
}

/// The backend is temporarily unavailable — disabled in `config/ai`, Gemini
/// busy/timed out, or an empty reply. [reason] is the server's hint
/// (`disabled` / `busy` / `empty` / `timeout` / `network`). Transient.
class AiBusy extends AiSendResult {
  const AiBusy(this.reason);
  final String reason;
}

/// Something the client couldn't recover from — not signed in, no token, or a
/// response it couldn't parse. [message] is debug copy, not user-facing text.
class AiSendFailed extends AiSendResult {
  const AiSendFailed(this.message);
  final String message;
}

class AiAssistantService {
  AiAssistantService._();
  static final AiAssistantService instance = AiAssistantService._();

  static const _endpoint =
      'https://us-central1-videocallapp-81166.cloudfunctions.net/askGupShupAi';

  /// Outer bound for the whole round trip. Longer than the sibling services'
  /// 15s because this call waits on an upstream Gemini request the function
  /// caps at ~20s — the client must give the function time to return its own
  /// graceful 503 rather than time out first.
  static const _httpTimeout = Duration(seconds: 30);

  /// How many prior turns to send as context. Kept at the server's own
  /// `AI_MAX_HISTORY_TURNS`; the function slices to the last 20 regardless, so
  /// sending more would just be wasted bytes.
  static const _kMaxHistoryTurns = 20;

  /// Reactive transcript for the UI. A thin pass-through to the local store so
  /// the screen depends only on this service, not on [PlaintextStore] directly.
  Stream<List<MessageModel>> watchTranscript() async* {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      yield const [];
      return;
    }
    final store = await PlaintextStore.instance();
    yield* store.watchMessages(aiRoomIdFor(uid));
  }

  /// Whether the signed-in user has any AI transcript stored locally — used to
  /// decide whether to show the one-time first-run introduction notice.
  Future<bool> hasHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final store = await PlaintextStore.instance();
    final messages = await store.getMessages(aiRoomIdFor(uid));
    return messages.isNotEmpty;
  }

  /// Sends [text] to GupShup AI and persists both sides of the turn locally.
  ///
  /// Ordering is deliberate:
  ///  1. the prior transcript is read for history *before* this turn is saved,
  ///     so the new user turn isn't sent twice — the function appends it itself;
  ///  2. the user bubble is persisted *before* the network call so it appears
  ///     instantly beneath the typing indicator, and is kept on any failure so
  ///     a retry doesn't lose what they typed.
  Future<AiSendResult> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const AiSendFailed('empty-message');

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const AiSendFailed('not-signed-in');

    final PlaintextStore store;
    try {
      store = await PlaintextStore.instance();
    } catch (e) {
      return AiSendFailed('store-unavailable: $e');
    }

    // History first: the prior transcript, before this turn is appended.
    final prior = await store.getMessages(aiRoomIdFor(uid));
    final history = buildHistory(prior, uid);

    // Persist the user's turn so it renders immediately via watchTranscript().
    final userMsg = MessageModel(
      id: _newId(),
      senderId: uid,
      receiverId: kAiRoomId,
      text: trimmed,
      type: MessageType.text,
      timestamp: DateTime.now(),
      schemaVersion: 1,
    );
    await store.saveMessage(userMsg, aiRoomIdFor(uid));

    return _post(store: store, uid: uid, message: trimmed, history: history);
  }

  /// Re-asks the most recent user turn that never got a reply — used after a
  /// quota top-up (watch-an-ad) or a transient failure.
  ///
  /// Unlike [sendMessage] it does **not** persist a new user bubble: the turn is
  /// already the last message in the transcript, so this just asks the server
  /// again with that text and, on success, appends the assistant reply. If the
  /// last message isn't a dangling user turn (there's nothing waiting on a
  /// reply) it returns [AiSendFailed] without a network call.
  Future<AiSendResult> retryLast() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const AiSendFailed('not-signed-in');

    final PlaintextStore store;
    try {
      store = await PlaintextStore.instance();
    } catch (e) {
      return AiSendFailed('store-unavailable: $e');
    }

    final messages = await store.getMessages(aiRoomIdFor(uid));
    if (messages.isEmpty) return const AiSendFailed('nothing-to-retry');

    final last = messages.last;
    if (last.senderId != uid || last.type != MessageType.text) {
      return const AiSendFailed('nothing-to-retry');
    }
    final pending = last.text.trim();
    if (pending.isEmpty) return const AiSendFailed('nothing-to-retry');

    // The server appends the pending turn itself, so history is everything
    // *before* it — otherwise the question would be duplicated in the prompt.
    final history =
        buildHistory(messages.sublist(0, messages.length - 1), uid);
    return _post(store: store, uid: uid, message: pending, history: history);
  }

  /// POSTs one turn to `askGupShupAi` and routes the response. Shared by
  /// [sendMessage] and [retryLast]; the only difference between them is whether
  /// a user bubble was persisted first.
  Future<AiSendResult> _post({
    required PlaintextStore store,
    required String uid,
    required String message,
    required List<Map<String, String>> history,
  }) async {
    final idToken = await _getIdToken();
    if (idToken == null) return const AiSendFailed('no-id-token');

    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'message': message,
              'history': history,
            }),
          )
          .timeout(_httpTimeout);
    } on TimeoutException {
      return const AiBusy('timeout');
    } catch (e) {
      return AiBusy('network: $e');
    }

    return _handleResponse(response, store, uid);
  }

  Future<AiSendResult> _handleResponse(
    http.Response response,
    PlaintextStore store,
    String uid,
  ) async {
    final status = response.statusCode;

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      body = const {};
    }

    final (result, replyToPersist) = classifyResponse(status, body);

    // The one side effect, kept out of the pure classifier: a good reply is
    // persisted so it renders via watchTranscript(). Every other outcome — a
    // spent quota, a busy backend, a hard failure — saves nothing, which is
    // what keeps the user's own turn retryable without a duplicate reply.
    if (replyToPersist != null) {
      final aiMsg = MessageModel(
        id: _newId(),
        senderId: kAiRoomId,
        receiverId: uid,
        text: replyToPersist,
        type: MessageType.text,
        timestamp: DateTime.now(),
        schemaVersion: 1,
      );
      await store.saveMessage(aiMsg, aiRoomIdFor(uid));
    }

    return result;
  }

  /// Pure mapping of an HTTP status + decoded JSON body to the typed outcome.
  ///
  /// Returns the outcome paired with the assistant reply the caller must
  /// persist — non-null **only** on a good 200, so classification stays free of
  /// Firebase and the local store and can be unit-tested directly. The chat UI
  /// treats a spent quota (429) and a busy backend (503) as normal states, not
  /// exceptions; only the genuinely unmodelled cases become [AiSendFailed].
  @visibleForTesting
  static (AiSendResult, String?) classifyResponse(
    int status,
    Map<String, dynamic> body,
  ) {
    if (status == 200) {
      final reply = (body['reply'] as String?)?.trim() ?? '';
      // An empty 200 shouldn't happen (the function returns 503 'empty' for a
      // blank Gemini reply) but guard anyway rather than save a blank bubble.
      if (reply.isEmpty) return (const AiBusy('empty'), null);
      final remaining = (body['remaining'] as num?)?.toInt() ?? 0;
      return (AiReplyReceived(remaining), reply);
    }

    if (status == 429) {
      return (
        AiQuotaExceeded(
          isPro: body['isPro'] == true,
          canEarn: body['canEarn'] == true,
        ),
        null,
      );
    }

    if (status == 503) {
      return (AiBusy(body['reason'] as String? ?? 'busy'), null);
    }

    // 400 / 401 / 500 / … — not a state the chat UI models specially.
    final reason = body['reason'] as String? ??
        body['error'] as String? ??
        'http-$status';
    return (AiSendFailed(reason), null);
  }

  /// The last [_kMaxHistoryTurns] turns in the function's wire format,
  /// `[{role: 'user' | 'model', text}]`. Only non-empty text turns travel; a
  /// message is the user's iff its `senderId` is [uid] and the assistant's
  /// otherwise (its `senderId` is [kAiRoomId]).
  ///
  /// Static and [visibleForTesting]: a pure transform over the transcript, so
  /// the trim and role-mapping are unit-tested without Firebase or the store.
  @visibleForTesting
  static List<Map<String, String>> buildHistory(
    List<MessageModel> messages,
    String uid,
  ) {
    final turns = <Map<String, String>>[];
    for (final m in messages) {
      if (m.type != MessageType.text) continue;
      final text = m.text.trim();
      if (text.isEmpty) continue;
      turns.add({
        'role': m.senderId == uid ? 'user' : 'model',
        'text': text,
      });
    }
    if (turns.length > _kMaxHistoryTurns) {
      return turns.sublist(turns.length - _kMaxHistoryTurns);
    }
    return turns;
  }

  /// The current user's Firebase ID token, or null if not signed in. Mirrors
  /// `SubscriptionService._getIdToken` exactly — the `?.` keeps the result
  /// nullable regardless of the SDK's own signature.
  Future<String?> _getIdToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }

  /// A collision-free local id, minted the same way the rest of the app does it
  /// — a Firestore push id generated client-side, with no network round-trip
  /// and no `uuid` dependency (see the note in `encrypted_media_service.dart`).
  /// Nothing is ever written to this collection; only the id is taken.
  String _newId() =>
      FirebaseFirestore.instance.collection('_ai_local').doc().id;
}
