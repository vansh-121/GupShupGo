import 'dart:ffi';
import 'dart:io';

import 'package:sqlite3/open.dart';

/// Points `package:sqlite3` at a native SQLite the Dart test VM can actually
/// load, so Drift's `NativeDatabase.memory()` works in unit tests.
///
/// On a device this never comes up: `sqlite3_flutter_libs` bundles SQLite into
/// the app. Unit tests run on the host VM instead, where that plugin's binary
/// isn't present, and Drift falls back to looking for a system library:
///
///  * **Linux / macOS** — `libsqlite3` is part of the OS, so the default lookup
///    works and this call is a no-op.
///  * **Windows** — there is no `sqlite3.dll` on a stock machine and the open
///    fails with a bare "specified module could not be found" from `dart:ffi`,
///    which reads like a broken test rather than a missing dependency. Windows
///    does ship `winsqlite3.dll` in System32 (SQLite 3.51.1 at time of writing,
///    with FTS5 compiled in — see `test/services/database/fts_search_test.dart`,
///    which asserts that rather than assuming it), so point at that.
///
/// Call once from a test's `main()` before opening any database. Safe to call
/// more than once.
///
/// Deliberately test-only. Nothing in `lib/` should reach for a host SQLite —
/// the app's copy comes from the plugin, and overriding the lookup there would
/// swap the bundled, version-pinned engine for whatever the OS happens to have.
void useNativeSqliteForTests() {
  if (_done) return;
  _done = true;

  if (!Platform.isWindows) return;

  open.overrideFor(
    OperatingSystem.windows,
    () {
      // Prefer a real sqlite3.dll if one is on the search path (a dev who has
      // installed the SQLite tools, or CI that fetched it) — it is the same
      // build the app ships. Fall back to the OS copy.
      try {
        return DynamicLibrary.open('sqlite3.dll');
      } catch (_) {
        return DynamicLibrary.open(r'C:\Windows\System32\winsqlite3.dll');
      }
    },
  );
}

bool _done = false;
