import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/services/call_device_identity.dart';

void main() {
  test('simultaneous auth, Home and resume registration share one device ID',
      () async {
    final read = Completer<String?>();
    var created = 0;
    final saved = <String>[];
    final identity = CallDeviceIdentity(
      read: () => read.future,
      create: () => 'device-${++created}',
      write: (id) async {
        saved.add(id);
      },
    );
    final requests = List.generate(10, (_) => identity.getOrCreate());
    read.complete(null);
    expect(await Future.wait(requests), everyElement('device-1'));
    expect(saved, ['device-1']);
    expect(await identity.getOrCreate(), 'device-1');
    expect(created, 1);
  });

  test('an upgrade retains the previously saved install ID', () async {
    final identity = CallDeviceIdentity(
      read: () async => 'released-device',
      create: () => throw StateError('must not rotate'),
      write: (_) async => throw StateError('must not overwrite'),
    );
    expect(await identity.getOrCreate(), 'released-device');
  });

  test('failed persistence can be retried and never returns an unsaved ID',
      () async {
    var attempts = 0;
    final identity = CallDeviceIdentity(
      read: () async => null,
      create: () => 'device',
      write: (_) async {
        if (++attempts == 1) throw StateError('storage unavailable');
      },
    );
    await expectLater(identity.getOrCreate(), throwsStateError);
    expect(await identity.getOrCreate(), 'device');
    expect(attempts, 2);
  });
}
