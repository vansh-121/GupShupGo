// CryptoWorker — a long-lived background isolate for CPU-intensive
// cryptographic operations.
//
// Why this exists:
//
// VaultCipher uses Dart's `compute()` for heavy operations like Argon2id
// key derivation and batch AES-GCM decrypts. Each `compute()` call spawns
// a fresh isolate, which carries 5–15ms of setup overhead per call on low-
// end devices. On cold start, batch-decrypting 200+ vault entries fires
// `compute()` multiple times, wasting tens of milliseconds on isolate
// lifecycle management.
//
// CryptoWorker spawns a SINGLE isolate at app launch and keeps it alive
// for the lifetime of the process. All vault crypto operations are routed
// through it as request/response messages over SendPort/ReceivePort. The
// worker isolate stays warm between calls, amortizing the spawn overhead
// to a single ~10ms cost at app start.
//
// Signal Protocol (encrypt/decrypt) stays on the main isolate because
// libsignal_protocol_dart's in-memory stores (sessions, prekeys, identity
// keys) can't be safely shared across isolate boundaries without complex
// serialization and synchronization. Signal operations are already fast
// after session setup (10–30ms per message), and the real bottleneck —
// batch vault decrypts on cold start — is what this worker targets.
//
// Usage:
//   await CryptoWorker.instance.init();
//   final result = await CryptoWorker.instance.batchDecryptDocs(key, docs);
//   await CryptoWorker.instance.deriveKey(pin, salt);
//   CryptoWorker.instance.dispose();

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:pointycastle/key_derivators/argon2.dart';
import 'package:pointycastle/key_derivators/api.dart' as pc;

/// A long-lived background isolate for vault crypto operations.
///
/// Replaces per-call `compute()` spawns with a persistent worker, saving
/// 5–15ms of isolate setup overhead per operation on low-end devices.
class CryptoWorker {
  CryptoWorker._();
  static final CryptoWorker instance = CryptoWorker._();

  Isolate? _isolate;
  SendPort? _workerPort;
  final _pendingRequests = <int, Completer<dynamic>>{};
  int _nextId = 0;

  bool get isReady => _workerPort != null;

  /// Spawns the background isolate. Safe to call multiple times — subsequent
  /// calls are no-ops if the worker is already running.
  Future<void> init() async {
    if (_workerPort != null) return;

    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(
      _workerEntryPoint,
      receivePort.sendPort,
    );

    final completer = Completer<SendPort>();
    receivePort.listen((message) {
      if (message is SendPort) {
        completer.complete(message);
      } else if (message is _WorkerResponse) {
        final pending = _pendingRequests.remove(message.id);
        if (pending != null) {
          if (message.error != null) {
            pending.completeError(message.error!);
          } else {
            pending.complete(message.result);
          }
        }
      }
    });

    _workerPort = await completer.future;
  }

  /// Shuts down the worker isolate. Call on app teardown or sign-out.
  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _workerPort = null;
    // Fail any pending requests.
    for (final c in _pendingRequests.values) {
      c.completeError(StateError('CryptoWorker disposed'));
    }
    _pendingRequests.clear();
  }

  // ─── Public API ──────────────────────────────────────────────────────────

  /// Batch-decrypt vault docs (JSON payloads). Runs on the worker isolate.
  /// Falls back to in-process execution if the worker isn't initialized.
  Future<Map<String, Map<String, dynamic>>> batchDecryptDocs(
    Uint8List key,
    Map<String, Map<String, dynamic>> docs,
  ) async {
    if (docs.isEmpty) return {};
    return _sendRequest<Map<String, Map<String, dynamic>>>(
      _WorkerRequest.batchDecryptDocs(key, docs),
    );
  }

  /// Batch-decrypt vault docs to raw bytes (for media AES keys).
  Future<Map<String, Uint8List>> batchDecryptBytes(
    Uint8List key,
    Map<String, Map<String, dynamic>> docs,
  ) async {
    if (docs.isEmpty) return {};
    return _sendRequest<Map<String, Uint8List>>(
      _WorkerRequest.batchDecryptBytes(key, docs),
    );
  }

  /// Derive a 32-byte AES key from a PIN + salt using Argon2id.
  Future<Uint8List> deriveKey(String pin, List<int> salt) {
    return _sendRequest<Uint8List>(
      _WorkerRequest.deriveKey(pin, salt),
    );
  }

  // ─── Request/response plumbing ───────────────────────────────────────────

  Future<T> _sendRequest<T>(_WorkerRequest request) async {
    if (_workerPort == null) {
      // Worker not started — initialize on demand.
      await init();
    }
    final id = _nextId++;
    final completer = Completer<dynamic>();
    _pendingRequests[id] = completer;
    _workerPort!.send(_WorkerEnvelope(id, request));
    return (await completer.future) as T;
  }
}

// ─── Messages ──────────────────────────────────────────────────────────────

enum _RequestType { batchDecryptDocs, batchDecryptBytes, deriveKey }

class _WorkerRequest {
  final _RequestType type;
  final Uint8List? key;
  final Map<String, Map<String, dynamic>>? docs;
  final String? pin;
  final List<int>? salt;

  _WorkerRequest._({
    required this.type,
    this.key,
    this.docs,
    this.pin,
    this.salt,
  });

  factory _WorkerRequest.batchDecryptDocs(
    Uint8List key,
    Map<String, Map<String, dynamic>> docs,
  ) =>
      _WorkerRequest._(
        type: _RequestType.batchDecryptDocs,
        key: key,
        docs: docs,
      );

  factory _WorkerRequest.batchDecryptBytes(
    Uint8List key,
    Map<String, Map<String, dynamic>> docs,
  ) =>
      _WorkerRequest._(
        type: _RequestType.batchDecryptBytes,
        key: key,
        docs: docs,
      );

  factory _WorkerRequest.deriveKey(String pin, List<int> salt) =>
      _WorkerRequest._(
        type: _RequestType.deriveKey,
        pin: pin,
        salt: salt,
      );
}

class _WorkerEnvelope {
  final int id;
  final _WorkerRequest request;
  _WorkerEnvelope(this.id, this.request);
}

class _WorkerResponse {
  final int id;
  final dynamic result;
  final Object? error;
  _WorkerResponse(this.id, this.result, [this.error]);
}

// ─── Worker isolate entry point ────────────────────────────────────────────

void _workerEntryPoint(SendPort mainPort) {
  final workerReceivePort = ReceivePort();
  mainPort.send(workerReceivePort.sendPort);

  final gcm = AesGcm.with256bits();

  workerReceivePort.listen((message) async {
    if (message is! _WorkerEnvelope) return;
    final req = message.request;
    try {
      dynamic result;
      switch (req.type) {
        case _RequestType.batchDecryptDocs:
          result = await _doBatchDecryptDocs(gcm, req.key!, req.docs!);
          break;
        case _RequestType.batchDecryptBytes:
          result = await _doBatchDecryptBytes(gcm, req.key!, req.docs!);
          break;
        case _RequestType.deriveKey:
          result = _doDeriveKey(req.pin!, req.salt!);
          break;
      }
      mainPort.send(_WorkerResponse(message.id, result));
    } catch (e) {
      mainPort.send(_WorkerResponse(message.id, null, e.toString()));
    }
  });
}

// ─── Worker-side implementations ───────────────────────────────────────────

Future<Map<String, Map<String, dynamic>>> _doBatchDecryptDocs(
  AesGcm gcm,
  Uint8List key,
  Map<String, Map<String, dynamic>> docs,
) async {
  final secretKey = SecretKey(key);
  final out = <String, Map<String, dynamic>>{};
  for (final entry in docs.entries) {
    final doc = entry.value;
    // Legacy plaintext passthrough.
    final legacy = doc['p'] as String?;
    if (legacy != null) {
      try {
        out[entry.key] = jsonDecode(legacy) as Map<String, dynamic>;
      } catch (_) {}
      continue;
    }
    final iv = doc['iv'] as String?;
    final c = doc['c'] as String?;
    final m = doc['m'] as String?;
    if (iv == null || c == null || m == null) continue;
    try {
      final pt = await gcm.decrypt(
        SecretBox(base64Decode(c),
            nonce: base64Decode(iv), mac: Mac(base64Decode(m))),
        secretKey: secretKey,
      );
      out[entry.key] = jsonDecode(utf8.decode(pt)) as Map<String, dynamic>;
    } catch (_) {}
  }
  return out;
}

Future<Map<String, Uint8List>> _doBatchDecryptBytes(
  AesGcm gcm,
  Uint8List key,
  Map<String, Map<String, dynamic>> docs,
) async {
  final secretKey = SecretKey(key);
  final out = <String, Uint8List>{};
  for (final entry in docs.entries) {
    final doc = entry.value;
    final legacy = doc['k'] as String?;
    if (legacy != null) {
      try {
        out[entry.key] = base64Decode(legacy);
      } catch (_) {}
      continue;
    }
    final iv = doc['iv'] as String?;
    final c = doc['c'] as String?;
    final m = doc['m'] as String?;
    if (iv == null || c == null || m == null) continue;
    try {
      final pt = await gcm.decrypt(
        SecretBox(base64Decode(c),
            nonce: base64Decode(iv), mac: Mac(base64Decode(m))),
        secretKey: secretKey,
      );
      out[entry.key] = Uint8List.fromList(pt);
    } catch (_) {}
  }
  return out;
}

Uint8List _doDeriveKey(String pin, List<int> salt) {
  final params = pc.Argon2Parameters(
    pc.Argon2Parameters.ARGON2_id,
    Uint8List.fromList(salt),
    version: pc.Argon2Parameters.ARGON2_VERSION_13,
    iterations: 3,
    lanes: 4,
    memoryPowerOf2: 16,
    desiredKeyLength: 32,
  );
  final kd = Argon2BytesGenerator()..init(params);
  final out = Uint8List(32);
  kd.deriveKey(Uint8List.fromList(utf8.encode(pin)), 0, out, 0);
  return out;
}
