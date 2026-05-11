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

import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  Future<MediaKeyBundle> encryptAndUpload({
    required File file,
    required String storagePath,
    String contentType = 'application/octet-stream',
  }) async {
    final plaintext = await file.readAsBytes();
    return _encryptAndUploadBytes(
      bytes: plaintext,
      storagePath: storagePath,
      contentType: contentType,
    );
  }

  Future<MediaKeyBundle> encryptAndUploadBytes({
    required Uint8List bytes,
    required String storagePath,
    String contentType = 'application/octet-stream',
  }) =>
      _encryptAndUploadBytes(
        bytes: bytes,
        storagePath: storagePath,
        contentType: contentType,
      );

  Future<MediaKeyBundle> _encryptAndUploadBytes({
    required Uint8List bytes,
    required String storagePath,
    required String contentType,
  }) async {
    final secretKey = await _gcm.newSecretKey();
    final keyBytes = await secretKey.extractBytes();
    final nonce = _gcm.newNonce();

    final box = await _gcm.encrypt(
      bytes,
      secretKey: secretKey,
      nonce: nonce,
    );

    // Wire format: [ciphertext bytes || 16-byte GCM tag].
    final wire = Uint8List(box.cipherText.length + box.mac.bytes.length)
      ..setRange(0, box.cipherText.length, box.cipherText)
      ..setRange(box.cipherText.length, box.cipherText.length + box.mac.bytes.length,
          box.mac.bytes);

    final ref = _storage.ref().child(storagePath);
    await ref.putData(
      wire,
      // Don't leak the original content-type; server should see "opaque".
      SettableMetadata(contentType: 'application/octet-stream'),
    );
    final url = await ref.getDownloadURL();

    return MediaKeyBundle(
      key: keyBytes,
      iv: nonce,
      hash: crypto.sha256.convert(wire).bytes,
      url: url,
      sizeBytes: wire.length,
      contentType: contentType,
    );
  }

  /// Downloads ciphertext from `bundle.url`, verifies SHA-256, decrypts,
  /// and returns plaintext bytes.
  Future<Uint8List> downloadAndDecrypt(MediaKeyBundle bundle) async {
    final response = await http.get(Uri.parse(bundle.url));
    if (response.statusCode != 200) {
      throw StateError(
          'media download failed: ${response.statusCode} ${response.reasonPhrase}');
    }
    final wire = response.bodyBytes;

    final actualHash = crypto.sha256.convert(wire).bytes;
    if (!_constTimeEq(actualHash, bundle.hash)) {
      throw StateError('media integrity check failed');
    }

    final tagLen = 16;
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
