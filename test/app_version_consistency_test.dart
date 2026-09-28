// Keeps the two hand-written version constants pinned to `pubspec.yaml`.
//
// `kAppVersionCode` decides whether this build is still supported, and
// `kCurrentVersion` decides what the What's New dialog claims to be. Both are
// plain `const`s that someone has to remember to bump, and both fail silently
// when they drift:
//
//   • A stale `kAppVersionCode` is the dangerous one. Ship 57 while the
//     constant still says 56, set `deprecated_below_version_code: 57`, and the
//     new build condemns *itself* — every user who updates is told to update,
//     and then locked out on the deadline. The people hit hardest would be the
//     ones who did exactly what they were asked.
//   • A stale `kCurrentVersion` just shows the wrong number in a dialog and
//     re-shows a changelog that was already seen.
//
// So this is the test that makes forgetting loud, and it is the reason those
// are constants instead of a `package_info_plus` lookup: the dependency buys
// nothing the release checklist plus this assertion doesn't already cover, and
// this project has paid for enough plugins in Gradle debugging.
//
// Bumping a release means three edits in lockstep — `pubspec.yaml`,
// `kCurrentVersion`, `kAppVersionCode`. Two of them are here.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_chat_app/services/version_policy.dart';
import 'package:video_chat_app/widgets/whats_new_dialog.dart'
    show kCurrentVersion;

void main() {
  // `flutter test` runs from the package root, so the pubspec is right here.
  // Parsed by hand rather than with a YAML package — one line, one shape, and
  // no reason to take a dependency for it.
  final line = File('pubspec.yaml')
      .readAsLinesSync()
      .firstWhere((l) => l.startsWith('version:'), orElse: () => '');

  test('pubspec still declares a version', () {
    expect(line, isNotEmpty,
        reason: 'no `version:` line in pubspec.yaml — did the key move?');
  });

  final value = line.substring('version:'.length).trim();
  final parts = value.split('+');

  test('pubspec version is name+code', () {
    expect(parts, hasLength(2),
        reason: 'expected `version: <name>+<code>`, found `$value`');
    expect(int.tryParse(parts[1]), isNotNull,
        reason: 'build number `${parts[1]}` is not an integer');
  });

  test('kAppVersionCode matches the pubspec build number', () {
    expect(
      kAppVersionCode,
      int.parse(parts[1]),
      reason: 'kAppVersionCode in lib/services/version_policy.dart is stale. '
          'A build whose constant is lower than its real version code can '
          'lock itself out under the supported-version policy.',
    );
  });

  test('kCurrentVersion matches the pubspec version name', () {
    expect(
      kCurrentVersion,
      parts[0],
      reason: 'kCurrentVersion in lib/widgets/whats_new_dialog.dart is stale; '
          'the What\'s New dialog would announce the wrong release.',
    );
  });
}
