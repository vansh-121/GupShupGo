// The ordering guarantee that keeps two libsignal operations off one
// SessionRecord at the same time.
//
// This is the primitive the "message can't be decrypted" bug came down to
// twice. The first fix made each caller's own loop sequential, which was not
// enough: ChatService.decryptForRendering has six independent callers and
// nothing serialized them against each other, so opening a chat with a backlog
// ran two of them over the same messages concurrently. Hence a lock, and hence
// these tests — an untested concurrency primitive in the crypto path is exactly
// the thing that regresses silently.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/services/crypto/address_lock.dart';

void main() {
  group('AddressLock', () {
    test('serializes overlapping actions on one key', () async {
      final lock = AddressLock();
      final log = <String>[];

      Future<void> op(String tag, int ms) => lock.run('peer:1', () async {
            log.add('$tag:enter');
            await Future<void>.delayed(Duration(milliseconds: ms));
            log.add('$tag:exit');
          });

      // The second operation is far quicker, so without the lock it would
      // finish inside the first one's window — which is precisely the
      // load/mutate/store interleaving that loses a ratchet advance.
      await Future.wait([op('slow', 40), op('fast', 1)]);

      expect(log, ['slow:enter', 'slow:exit', 'fast:enter', 'fast:exit']);
    });

    test('preserves submission order across a queue of three', () async {
      final lock = AddressLock();
      final order = <int>[];

      await Future.wait([
        for (var i = 0; i < 3; i++)
          lock.run('peer:1', () async {
            // Descending delays: FIFO only holds if the lock is doing the work.
            await Future<void>.delayed(Duration(milliseconds: 30 - i * 10));
            order.add(i);
          }),
      ]);

      expect(order, [0, 1, 2]);
    });

    test('runs different keys concurrently', () async {
      // Distinct peers hold distinct SessionRecords, so serializing them would
      // be a pure latency cost — a busy account would decrypt one conversation
      // at a time.
      final lock = AddressLock();
      final log = <String>[];

      await Future.wait([
        lock.run('peer:1', () async {
          log.add('a:enter');
          await Future<void>.delayed(const Duration(milliseconds: 40));
          log.add('a:exit');
        }),
        lock.run('peer:2', () async {
          log.add('b:enter');
          await Future<void>.delayed(const Duration(milliseconds: 1));
          log.add('b:exit');
        }),
      ]);

      expect(log, ['a:enter', 'b:enter', 'b:exit', 'a:exit']);
    });

    test('same uid on different devices does not contend', () async {
      final lock = AddressLock();
      var concurrent = 0;
      var peak = 0;

      Future<void> op(int device) => lock.run('peer:$device', () async {
            peak = ++concurrent > peak ? concurrent : peak;
            await Future<void>.delayed(const Duration(milliseconds: 10));
            concurrent--;
          });

      await Future.wait([op(1), op(2)]);
      expect(peak, 2);
    });

    test('a throwing action releases the lock and does not strand the queue',
        () async {
      // A failed decrypt is routine — it is what the whole resend protocol
      // exists for. If it stranded the queue, one unreadable message would
      // block every later message from that peer, which is a far worse failure
      // than the one we started with.
      final lock = AddressLock();
      final log = <String>[];

      final failing = lock.run<void>('peer:1', () async {
        log.add('boom');
        throw StateError('decrypt failed');
      });
      final queued = lock.run('peer:1', () async {
        log.add('after');
        return 7;
      });

      await expectLater(failing, throwsStateError);
      expect(await queued, 7);
      expect(log, ['boom', 'after']);
    });

    test('an error reaches only its own caller', () async {
      final lock = AddressLock();
      final ok = lock.run('peer:1', () async => 'fine');
      final bad = lock.run<String>('peer:1', () async => throw StateError('x'));
      final alsoOk = lock.run('peer:1', () async => 'also fine');

      expect(await ok, 'fine');
      await expectLater(bad, throwsStateError);
      expect(await alsoOk, 'also fine');
    });

    test('does not retain a key once its queue drains', () async {
      // One permanent entry per peer device ever contacted would be a slow leak
      // in a long-lived process.
      final lock = AddressLock();

      await Future.wait([
        lock.run('peer:1', () async {}),
        lock.run('peer:1', () async {}),
        lock.run('peer:2', () async {}),
      ]);

      expect(lock.pendingKeys, 0);
    });

    test('holds the key while work is queued behind it', () async {
      final lock = AddressLock();
      final gate = Completer<void>();

      final held = lock.run('peer:1', () => gate.future);
      final behind = lock.run('peer:1', () async {});

      expect(lock.pendingKeys, 1);
      gate.complete();
      await Future.wait([held, behind]);
      expect(lock.pendingKeys, 0);
    });
  });
}
