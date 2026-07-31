import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Purity guard: the pure domain layer under `lib/services/streak/` must never
/// touch the device clock or the device zone, and must never take a day
/// difference off wall-clock values.
///
/// Exempt by name:
///  * `server_clock.dart` — the one place allowed to read the device clock,
///  * `streak_api.dart`   — transport, not domain logic.
///
/// The sanctioned `.inDays` is `(startUtc - other.startUtc).inDays` inside
/// `streak_day.dart`, so `.inDays` is banned everywhere except that file.
///
/// Validates: Requirements 2.12, 2.5
void main() {
  const exempt = {'server_clock.dart', 'streak_api.dart'};
  const inDaysAllowedIn = 'streak_day.dart';

  test('no banned clock/zone APIs under lib/services/streak/', () {
    final dir = Directory('lib/services/streak');
    expect(dir.existsSync(), isTrue, reason: 'streak domain dir missing');

    final violations = <String>[];

    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final name = entity.uri.pathSegments.last;
      if (exempt.contains(name)) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        // Strip line comments — the ban is on code, not on prose describing it.
        final commentAt = lines[i].indexOf('//');
        final code = commentAt == -1 ? lines[i] : lines[i].substring(0, commentAt);

        void flag(String token) =>
            violations.add('$name:${i + 1} uses banned `$token`');

        if (code.contains('DateTime.now()')) flag('DateTime.now()');
        if (code.contains('.toLocal()')) flag('.toLocal()');
        if (code.contains('.inDays') && name != inDaysAllowedIn) {
          flag('.inDays');
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
