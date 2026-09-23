// EncryptedMediaService — AES-256-GCM file encryption for chat media and
// status broadcasts.
//
// Flow on send:
//   1. Generate a random 256-bit key + 96-bit IV.
//   2. Encrypt file bytes → ciphertext (+ Poly1305 tag).
//   3. Upload ciphertext to Firebase Storage.
//   4. Return MediaKeyBundle { key, iv, sha256(ciphertext), url, sizeBytes }
//      to the caller, who embeds it INSIDE the Signal-encrypted message
//      payload. The server only ever sees the opaque ciphertext URL.
//
// Flow on receive:
//   1. Caller decrypts the Signal payload → MediaKeyBundle.
//   2. Download ciphertext from `url`.
//   3. Verify sha256 matches `hash` (integrity).
//   4. AES-GCM decrypt → plaintext file bytes.

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart' as crypto;

class MediaKeyBundle {
  MediaKeyBundle({
    required this.key,
    required this.iv,
    required this.hash,
    required this.url,
    required this.sizeBytes,
    required this.contentType,
  });

  final List<int> key;       // 32 bytes
  final List<int> iv;        // 12 bytes
  final List<int> hash;      // sha256 of ciphertext
  final String url;
  final int sizeBytes;
  final String contentType;

  Map<String, dynamic> toMap() => {
        'k': base64Encode(key),
        'i': base64Encode(iv),
        'h': base64Encode(hash),
        'u': url,
        's': sizeBytes,
        'c': contentType,
      };

  factory MediaKeyBundle.fromMap(Map<String, dynamic> map) => MediaKeyBundle(
        key: base64Decode(map['k'] as String),
        iv: base64Decode(map['i'] as String),
        hash: base64Decode(map['h'] as String),
        url: map['u'] as String,
        sizeBytes: map['s'] as int,
        contentType: map['c'] as String? ?? 'application/octet-stream',
      );
}

class EncryptedMediaService {
  static final _gcm = AesGcm.with256bits();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Encrypts and uploads a file. Returns the bundle the sender embeds
  /// inside the Signal payload.
  ///
  /// [onProgress] reports upload completion in 0.0–1.0 and fires only while the
  /// bytes are in flight — the encrypt that precedes it has no meaningful
  /// progress to report, so a caller driving a determinate bar should show an
  /// indeterminate state until the first callback arrives.
  Future<MediaKeyBundle> encryptAndUpload({
    required File file,
    required String storagePath,
    String contentType = 'application/octet-stream',
    void Function(double)? onProgress,
  }) async {
    final plaintext = await file.readAsBytes();
    return _encryptAndUploadBytes(
      bytes: plaintext,
      storagePath: storagePath,
      contentType: contentType,
      onProgress: onProgress,
    );
  }

  Future<MediaKeyBundle> encryptAndUploadBytes({
    required Uint8List bytes,
    required String storagePath,
    String contentType = 'application/octet-stream',
    void Function(double)? onProgress,
  }) =>
      _encryptAndUploadBytes(
        bytes: bytes,
        storagePath: storagePath,
        contentType: contentType,
        onProgress: onProgress,
      );

  Future<MediaKeyBundle> _encryptAndUploadBytes({
    required Uint8List bytes,
    required String storagePath,
    required String contentType,
    void Function(double)? onProgress,
  }) async {
    final secretKey = await _gcm.newSecretKey();
    final keyBytes = await secretKey.extractBytes();
    final nonce = _gcm.newNonce();

    // Key material is generated here and only the raw bytes cross the isolate
    // boundary — `SecretKey` is not sendable, and re-deriving it on the other
    // side is what [_encryptIsolate] does.
    final sealed = await _seal(
      bytes: bytes,
      key: Uint8List.fromList(keyBytes),
      iv: Uint8List.fromList(nonce),
    );

    final ref = _storage.ref().child(storagePath);
    final task = ref.putData(
      sealed.wire,
      // Don't leak the original content-type; server should see "opaque".
      SettableMetadata(contentType: 'application/octet-stream'),
    );

    StreamSubscription<TaskSnapshot>? sub;
    if (onProgress != null) {
      sub = task.snapshotEvents.listen(
        (s) {
          final total = s.totalBytes;
          if (total > 0) onProgress(s.bytesTransferred / total);
        },
        // Swallowed on purpose: the real failure surfaces from `await task`
        // below with its FirebaseException intact. An unhandled error on this
        // side-channel would otherwise crash the zone before that happens.
        onError: (_) {},
      );
    }
    try {
      await task;
    } finally {
      await sub?.cancel();
    }

    final url = await ref.getDownloadURL();

    return MediaKeyBundle(
      key: keyBytes,
      iv: nonce,
      hash: sealed.hash,
      url: url,
      sizeBytes: sealed.wire.length,
      contentType: contentType,
    );
  }

  /// AES-GCM encrypt + framing + integrity hash, offloaded above
  /// [_isolateThresholdBytes] for the same reason [downloadAndDecrypt] offloads
  /// the reverse. This side matters more: `package:cryptography` has no native
  /// backend in this project, so a 64 MB document — the chat cap — is several
  /// seconds of pure-Dart AES on whichever isolate runs it, and on the UI
  /// isolate that is a frozen app rather than a slow one.
  Future<_SealedMedia> _seal({
    required Uint8List bytes,
    required Uint8List key,
    required Uint8List iv,
  }) {
    final req = _MediaEncryptRequest(plaintext: bytes, key: key, iv: iv);
    return bytes.length >= _isolateThresholdBytes
        ? compute(_encryptIsolate, req)
        : _encryptIsolate(req);
  }

  /// Downloads ciphertext from `bundle.url`, verifies SHA-256, decrypts,
  /// and returns plaintext bytes.
  ///
  /// The SHA-256 verify + AES-GCM decrypt are CPU-bound and scale with file
  /// size. For anything but tiny payloads we run them in a background isolate
  /// via [compute] so the UI thread never janks while a status image or chat
  /// video is being opened. Small payloads stay inline — spawning an isolate
  /// costs more than the work saved.
  static const _isolateThresholdBytes = 32 * 1024; // 32 KB

  Future<Uint8List> downloadAndDecrypt(MediaKeyBundle bundle) async {
    final response = await http.get(Uri.parse(bundle.url));
    if (response.statusCode != 200) {
      throw StateError(
          'media download failed: ${response.statusCode} ${response.reasonPhrase}');
    }
    final wire = response.bodyBytes;

    if (wire.length >= _isolateThresholdBytes) {
      return compute(
        _verifyAndDecryptIsolate,
        _MediaDecryptRequest(
          wire: wire,
          key: Uint8List.fromList(bundle.key),
          iv: Uint8List.fromList(bundle.iv),
          expectedHash: Uint8List.fromList(bundle.hash),
        ),
      );
    }

    // Small payload: run inline.
    final actualHash = crypto.sha256.convert(wire).bytes;
    if (!_constTimeEq(actualHash, bundle.hash)) {
      throw StateError('media integrity check failed');
    }

    const tagLen = 16;
    final ct = wire.sublist(0, wire.length - tagLen);
    final tag = wire.sublist(wire.length - tagLen);

    final secretKey = SecretKey(bundle.key);
    final box = SecretBox(ct, nonce: bundle.iv, mac: Mac(tag));
    final pt = await _gcm.decrypt(box, secretKey: secretKey);
    return Uint8List.fromList(pt);
  }

  bool _constTimeEq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

// ─── Isolate-compatible top-level helpers ──────────────────────────────────
// Everything below runs inside the isolate spawned by `compute()`. It must be
// top-level (not a method) and take only sendable args, so we pass a plain
// data holder and reconstruct the crypto primitives on the other side.

/// The output of [_encryptIsolate]: the bytes to upload and their integrity
/// hash, computed together so the wire buffer crosses the isolate boundary
/// once instead of being re-hashed on the caller's side.
class _SealedMedia {
  _SealedMedia({required this.wire, required this.hash});

  /// `[ciphertext || 16-byte GCM tag]`.
  final Uint8List wire;
  final Uint8List hash;
}

/// Sendable payload for [_encryptIsolate].
class _MediaEncryptRequest {
  _MediaEncryptRequest({
    required this.plaintext,
    required this.key,
    required this.iv,
  });

  final Uint8List plaintext;
  final Uint8List key;
  final Uint8List iv;
}

/// AES-256-GCM encrypts [_MediaEncryptRequest.plaintext], frames it as
/// `[ciphertext || tag]`, and returns that buffer with its SHA-256. Top-level
/// and isolate-safe for the same reasons as [_verifyAndDecryptIsolate].
Future<_SealedMedia> _encryptIsolate(_MediaEncryptRequest req) async {
  final gcm = AesGcm.with256bits();
  final box = await gcm.encrypt(
    req.plaintext,
    secretKey: SecretKey(req.key),
    nonce: req.iv,
  );

  final ct = box.cipherText;
  final tag = box.mac.bytes;
  final wire = Uint8List(ct.length + tag.length)
    ..setRange(0, ct.length, ct)
    ..setRange(ct.length, ct.length + tag.length, tag);

  return _SealedMedia(
    wire: wire,
    hash: Uint8List.fromList(crypto.sha256.convert(wire).bytes),
  );
}

/// Sendable payload for [_verifyAndDecryptIsolate]. All fields are TypedData,
/// which transfers across the isolate boundary without a deep copy on most
/// platforms.
class _MediaDecryptRequest {
  _MediaDecryptRequest({
    required this.wire,
    required this.key,
    required this.iv,
    required this.expectedHash,
  });

  final Uint8List wire;
  final Uint8List key;
  final Uint8List iv;
  final Uint8List expectedHash;
}

/// Runs in a background isolate: verifies the ciphertext integrity hash in
/// constant time, then AES-256-GCM decrypts and returns the plaintext bytes.
/// Throws [StateError] on integrity failure — surfaced back on the caller's
/// future by `compute`.
Future<Uint8List> _verifyAndDecryptIsolate(_MediaDecryptRequest req) async {
  final wire = req.wire;

  final actualHash = crypto.sha256.convert(wire).bytes;
  if (!_constTimeEqBytes(actualHash, req.expectedHash)) {
    throw StateError('media integrity check failed');
  }

  const tagLen = 16;
  final ct = wire.sublist(0, wire.length - tagLen);
  final tag = wire.sublist(wire.length - tagLen);

  final gcm = AesGcm.with256bits();
  final secretKey = SecretKey(req.key);
  final box = SecretBox(ct, nonce: req.iv, mac: Mac(tag));
  final pt = await gcm.decrypt(box, secretKey: secretKey);
  return Uint8List.fromList(pt);
}

/// Constant-time byte comparison, duplicated at top level for isolate use.
bool _constTimeEqBytes(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
