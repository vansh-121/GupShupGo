// SafetyNumberService — WhatsApp-style 60-digit fingerprint that two users
// can compare out-of-band (over a phone call, in person) to detect MITM.
//
// Derivation matches Signal's specification:
//   stable = SHA-512_5200(version || localIdentityPub || localUserId)
//          ‖ SHA-512_5200(version || remoteIdentityPub || remoteUserId)
//
// We then chunk the leading 30 bytes into 12 groups of 5 digits each, sorted
// lexicographically by user id so both sides display the same number.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart' as crypto;

import 'signal_service.dart';

class SafetyNumberService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns the 60-digit safety number for the current user ↔ peer pair,
  /// or null if either side hasn't published a key bundle.
  Future<String?> safetyNumberFor({
    required String selfUserId,
    required String peerUserId,
  }) async {
    final selfPub = SignalService.instance.publicIdentityKey.serialize();
    final peerSnap = await _firestore
        .collection('users')
        .doc(peerUserId)
        .collection('devices')
        .doc('1')
        .get();
    final peerBundle = peerSnap.data()?['keyBundle'] as Map<String, dynamic>?;
    if (peerBundle == null) return null;
    final peerPub = base64Decode(peerBundle['identityPub'] as String);

    final selfHash = _iterateHash(selfPub, selfUserId);
    final peerHash = _iterateHash(peerPub, peerUserId);

    // Sort by uid so both peers display the same number regardless of who
    // is "self".
    final sortedSelfFirst = selfUserId.compareTo(peerUserId) < 0;
    final a = sortedSelfFirst ? selfHash : peerHash;
    final b = sortedSelfFirst ? peerHash : selfHash;

    final combined = Uint8List(60)
      ..setRange(0, 30, a.sublist(0, 30))
      ..setRange(30, 60, b.sublist(0, 30));

    final buf = StringBuffer();
    for (var i = 0; i < 60; i += 5) {
      if (i != 0) buf.write(' ');
      buf.write(_encodeChunk(combined.sublist(i, i + 5)));
    }
    return buf.toString();
  }

  Uint8List _iterateHash(List<int> pub, String userId) {
    var data = <int>[
      0, 0, // version
      ...pub,
      ...utf8.encode(userId),
    ];
    for (var i = 0; i < 5200; i++) {
      data = crypto.sha512.convert(data).bytes;
    }
    return Uint8List.fromList(data);
  }

  String _encodeChunk(List<int> chunk) {
    // Big-endian 40-bit int → 5 decimal digits.
    var v = 0;
    for (final b in chunk) {
      v = (v << 8) | b;
    }
    return (v % 100000).toString().padLeft(5, '0');
  }
}
