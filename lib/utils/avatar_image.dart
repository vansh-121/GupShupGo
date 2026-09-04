import 'package:flutter/widgets.dart';

/// Decode-size-limited [ImageProvider]s for remote images.
///
/// ## Why this exists
///
/// A bare `NetworkImage` decodes at the *source* resolution and parks that
/// full-size bitmap in Flutter's `imageCache`. Profile photos from Google
/// Sign-In and Firebase Storage are routinely 512–1024 px square, so a
/// `CircleAvatar(radius: 13)` — 26 logical pixels on screen — was holding a
/// 1024×1024×4 B ≈ **4 MB** bitmap to paint a 78 px circle. That is ~170× more
/// memory than the circle needs, and Flutter's default cache ceiling is 100 MB
/// / 1000 entries: scrolling a contact list evicts and re-decodes constantly,
/// which shows up as jank on scroll and OOM kills on low-RAM devices.
///
/// Google Play Console → "Improve your app's performance with bitmap image
/// optimization" flags exactly this pattern (its static analyzer only sees the
/// Java/Kotlin side, but the fix for a Flutter app lives here).
///
/// ## How it works
///
/// [ResizeImage] is the [ImageProvider] equivalent of the `cacheWidth`
/// argument already used for chat images (see the comment on
/// `_buildMessageImage` in `chat_screen.dart`). It hands the target dimensions
/// to the image codec, so the downsampling happens *during* decode — the
/// oversized bitmap is never allocated at all, and the cache stores only the
/// small one. It ships with the Flutter SDK, so this needs no new dependency.
///
/// Sizing uses a fixed 3× device-pixel-ratio budget, matching the existing
/// convention in `reply_quote_card.dart` (42 px box → `cacheWidth: 126`).
/// Going through `MediaQuery` for the real DPR would be more precise, but it
/// would make every provider depend on a `BuildContext` and vary the cache key
/// per device class for no visible gain — 3× already covers essentially every
/// phone in the fleet, and [ResizeImage] never upscales a smaller source.
const double _kDecodeDpr = 3.0;

/// An [ImageProvider] for [url] sized for a circular avatar of [radius].
///
/// [radius] is the `CircleAvatar.radius` in logical pixels; the avatar's
/// painted diameter is therefore `radius * 2`.
///
/// Pass this to `CircleAvatar.backgroundImage` in place of a raw
/// `NetworkImage(url)`:
///
/// ```dart
/// CircleAvatar(
///   radius: 24,
///   backgroundImage: avatarImage(user.photoUrl, radius: 24),
/// )
/// ```
ImageProvider avatarImage(String url, {required double radius}) {
  return ResizeImage(
    NetworkImage(url),
    width: (radius * 2 * _kDecodeDpr).round(),
    // Only width is constrained: avatars are square and painted with
    // BoxFit.cover, so height follows from the source aspect ratio.
    // allowUpscaling stays false (the default) so a 64 px source is left
    // alone rather than being inflated to fill the budget.
  );
}

// There is deliberately no rectangular counterpart here. The two non-avatar
// images that needed capping (the 46×58 status-reply thumbnail and the
// full-screen status view, both in this app's own widgets) pass `cacheWidth`
// straight to `Image.network`, which is the same ResizeImage machinery without
// a provider indirection. Only CircleAvatar needs a provider, because
// `backgroundImage` takes one.
