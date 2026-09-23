// Feature discovery — the dot that says "this is new, go look".
//
// Two of the 1.1.7 features live behind an overflow menu: chat themes (chat ⋮,
// and Settings → Appearance) and chat export (chat ⋮). An existing user has no
// reason to open either menu, so without a nudge the features are simply never
// found. This is the WhatsApp pattern: a dot on the ⋮, a dot on the row inside
// it, and a NEW pill on the item itself, all clearing once the feature is
// actually visited.
//
// Three rules make it behave rather than nag:
//
//   • **A fresh install shows nothing.** To a first-time user nothing is new —
//     it is just the app — so lighting up every menu would be noise, and would
//     teach them the dot means nothing before they ever met a real one. This
//     mirrors the same guard [maybeShowWhatsNew] already applies to the
//     changelog dialog, and for the same reason.
//   • **Only visiting the feature clears it.** Opening the menu does not count;
//     the point is that they used the thing, not that they scrolled past it.
//   • **A dot retires after three weeks** even if untouched. A dot that never
//     goes away is worse than no dot, because the next one is ignored too.
//
// Cascade is data, not conditionals. Each feature lists the *anchors* — entry
// points — it is reachable through, and a container asks [hasUnseenAt] whether
// anything unseen lives behind it. Adding a feature is one registry entry, and
// no call site changes.

import 'package:flutter/foundation.dart';
import 'package:video_chat_app/main.dart' show sharedPrefs;

/// The entry points a dot can appear on.
///
/// A dot on one of these means "something unseen is reachable through here",
/// which is why a single feature names several: chat themes can be reached from
/// the home menu, from Settings, and from inside any conversation, and all three
/// paths should advertise it.
abstract final class NewFeatureAnchor {
  static const String homeOverflow = 'home_overflow';
  static const String settingsMenuItem = 'settings_menu_item';
  static const String settingsAppearance = 'settings_appearance';
  static const String chatOverflow = 'chat_overflow';

  /// The composer's paperclip — the attachment sheet behind it.
  ///
  /// Added in 1.2.0, where three of the four new features live in that one
  /// sheet. It is a busier anchor than the others by design: the sheet is
  /// already the place a user looks when they want to send something that
  /// isn't text, so the dot points at a door they half expect to open.
  static const String chatAttachment = 'chat_attachment';
}

/// Ids of the features worth pointing at.
///
/// Only features with somewhere to *go* belong here. The 1.1.7 voice-length and
/// media-quality changes are real but have no entry point — you do not "visit"
/// the microphone or the image compressor — so they are announced in the What's
/// New dialog instead of being given a dot with nothing to attach to.
abstract final class NewFeature {
  static const String chatThemes = 'chat_themes';
  static const String chatExport = 'chat_export';

  // ── 1.2.0 ────────────────────────────────────────────────────────────────
  static const String documents = 'documents';
  static const String chatSearch = 'chat_search';
  static const String locationShare = 'location_share';
  static const String viewOnce = 'view_once';
}

/// One discoverable feature and the entry points that should advertise it.
@immutable
class _Discoverable {
  const _Discoverable(this.id, this.anchors);

  final String id;
  final Set<String> anchors;
}

/// Tracks which newly shipped features the user has yet to discover.
///
/// A [ChangeNotifier] singleton rather than a registered provider: this is a
/// service, not app state, and exposing it directly lets the badge widgets
/// subscribe with `ListenableBuilder` without every screen having to thread a
/// provider down to an app-bar icon.
class WhatsNewService extends ChangeNotifier {
  WhatsNewService._();

  static final WhatsNewService instance = WhatsNewService._();

  /// How long a feature keeps advertising itself when the user never bites.
  static const Duration _shelfLife = Duration(days: 21);

  static const String _seenPrefix = 'pref_newfeat_seen_';
  static const String _sincePrefix = 'pref_newfeat_since_';
  static const String _bootstrapKey = 'pref_newfeat_bootstrap';

  /// Written by [maybeShowWhatsNew]. Its *absence* is how a genuine first
  /// install is told apart from an update — see [bootstrap].
  static const String _whatsNewVersionKey = 'pref_whats_new_version';

  static const List<_Discoverable> _registry = [
    _Discoverable(NewFeature.chatThemes, {
      NewFeatureAnchor.homeOverflow,
      NewFeatureAnchor.settingsMenuItem,
      NewFeatureAnchor.settingsAppearance,
      NewFeatureAnchor.chatOverflow,
    }),
    _Discoverable(NewFeature.chatExport, {
      NewFeatureAnchor.chatOverflow,
    }),

    // ── 1.2.0 ──────────────────────────────────────────────────────────────
    // Three of the four sit behind the paperclip. That is one dot advertising
    // three things, which is the cascade working as intended: the dot says
    // "look in here", and the pills inside say which ones.
    _Discoverable(NewFeature.documents, {
      NewFeatureAnchor.chatAttachment,
    }),
    _Discoverable(NewFeature.locationShare, {
      NewFeatureAnchor.chatAttachment,
    }),
    // View once is a switch rather than a destination, but it is a switch the
    // user has to *find*, and the sheet is where it lives — so it earns an
    // entry on the same terms as the two above.
    _Discoverable(NewFeature.viewOnce, {
      NewFeatureAnchor.chatAttachment,
    }),
    // The only entry here for a menu row that already existed. What changed is
    // what it can reach: the filter used to see the loaded page window, and now
    // searches the whole local history. A user who tried search once and found
    // nothing has no reason to try again, so this is the one that most needs a
    // nudge — it advertises a fix, not a new door.
    _Discoverable(NewFeature.chatSearch, {
      NewFeatureAnchor.chatOverflow,
    }),
  ];

  /// Call once from `main()`, right after [sharedPrefs] is assigned.
  ///
  /// This must run before the home screen calls `maybeShowWhatsNew`, because
  /// that writes [_whatsNewVersionKey] — the very key used below to recognise a
  /// first install. Running from `main()` clears that ordering by a wide margin,
  /// but it is the reason this is not lazily initialised on first read.
  ///
  /// Safe to call more than once: the sentinel guards the one-time decision, and
  /// the stamping pass below only ever fills in a missing value.
  static void bootstrap() {
    final prefs = sharedPrefs;

    if (!prefs.containsKey(_bootstrapKey)) {
      // No changelog version on record means nobody has ever run an older
      // build here: this is a first install, and nothing in it is "new".
      final isFirstInstall = !prefs.containsKey(_whatsNewVersionKey);
      if (isFirstInstall) {
        for (final feature in _registry) {
          prefs.setBool(_seenPrefix + feature.id, true);
        }
      }
      prefs.setBool(_bootstrapKey, true);
    }

    // Stamp anything still unseen and unstamped so its three weeks start now.
    // Doing this here rather than lazily inside [isNew] keeps writes out of the
    // widget build path, and means a feature added in a later release gets its
    // stamp on the first launch after that update rather than on first glance.
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final feature in _registry) {
      final seen = prefs.getBool(_seenPrefix + feature.id) ?? false;
      if (seen) continue;
      if (prefs.containsKey(_sincePrefix + feature.id)) continue;
      prefs.setInt(_sincePrefix + feature.id, now);
    }
  }

  /// Whether [featureId] should still advertise itself.
  ///
  /// False once the user has visited it, and false again once its shelf life has
  /// run out. An unstamped feature is treated as new: [bootstrap] stamps before
  /// anything can ask, so reaching here unstamped means the registry gained an
  /// entry mid-session, and erring towards showing it is the harmless direction.
  bool isNew(String featureId) {
    if (sharedPrefs.getBool(_seenPrefix + featureId) ?? false) return false;

    final since = sharedPrefs.getInt(_sincePrefix + featureId);
    if (since == null) return true;

    final age = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(since))
        .abs(); // a clock moved backwards should not read as "expired"
    return age < _shelfLife;
  }

  /// Whether any unseen feature is reachable through [anchor].
  ///
  /// This is what makes a dot on a menu button mean something without the menu
  /// button knowing which features exist behind it.
  bool hasUnseenAt(String anchor) => _registry
      .any((f) => f.anchors.contains(anchor) && isNew(f.id));

  /// Record that the user has actually visited [featureId], clearing its badge
  /// and any container dot that existed only because of it.
  Future<void> markSeen(String featureId) async {
    if (sharedPrefs.getBool(_seenPrefix + featureId) ?? false) return;
    await sharedPrefs.setBool(_seenPrefix + featureId, true);
    notifyListeners();
  }

  /// Every registered feature id, for tests and for a debug reset.
  @visibleForTesting
  static List<String> get registeredIds =>
      _registry.map((f) => f.id).toList(growable: false);
}
