import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/utils/retained_stream.dart';

void main() {
  test('view replacement reuses one message subscription', () async {
    var listens = 0;
    var cancellations = 0;
    final source = StreamController<int>.broadcast(
      sync: true,
      onListen: () => listens++,
      onCancel: () => cancellations++,
    );
    final feed = RetainedStream(source.stream);
    final firstEvents = <int>[];
    final firstView = feed.stream.listen(firstEvents.add);
    source.add(1);
    await firstView.cancel();
    expect(cancellations, 0);

    final secondEvents = <int>[];
    final secondView = feed.stream.listen(secondEvents.add);
    source.add(2);
    expect(listens, 1);
    expect(firstEvents, [1]);
    expect(secondEvents, [2]);

    await feed.close();
    expect(cancellations, 1);
    await secondView.cancel();
    await source.close();
  });

  test('leaving a chat releases its source after the last view detaches',
      () async {
    var cancellations = 0;
    final source = StreamController<int>.broadcast(
      onCancel: () => cancellations++,
    );
    final feed = RetainedStream(source.stream);
    final view = feed.stream.listen((_) {});
    await view.cancel();
    expect(cancellations, 0);
    await feed.close();
    expect(cancellations, 1);
    await source.close();
  });

  test('closing the route cancels the source even before its view detaches',
      () async {
    var cancellations = 0;
    final source = StreamController<int>.broadcast(
      sync: true,
      onCancel: () => cancellations++,
    );
    final feed = RetainedStream(source.stream);
    final events = <int>[];
    final view = feed.stream.listen(events.add);
    source.add(1);
    await feed.close();
    await feed.close();
    source.add(2);
    expect(cancellations, 1);
    expect(events, [1]);
    await view.cancel();
    await source.close();
  });

  test('a chat closed before rendering never opens a message subscription',
      () async {
    var listens = 0;
    final source = StreamController<int>.broadcast(onListen: () => listens++);
    final feed = RetainedStream(source.stream);
    await feed.close();
    expect(listens, 0);
    await source.close();
  });

  test('message errors still reach the view', () async {
    final source = StreamController<int>.broadcast(sync: true);
    final feed = RetainedStream(source.stream);
    final errors = <Object>[];
    final view = feed.stream.listen((_) {}, onError: errors.add);
    final error = StateError('message read failed');
    source.addError(error);
    expect(errors, [error]);
    await feed.close();
    await view.cancel();
    await source.close();
  });
}
