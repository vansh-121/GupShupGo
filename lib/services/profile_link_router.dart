/// Validates public profile URLs and retains links until navigation is ready.
class ProfileLinkRouter {
  ProfileLinkRouter({required this.openProfile, DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final bool Function(String username) openProfile;
  final DateTime Function() _now;
  bool _ready = false;
  String? _pending;
  Uri? _lastUri;
  DateTime? _lastReceivedAt;

  bool get hasPendingLink => _pending != null;

  static String? extractUsername(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    if (uri.userInfo.isNotEmpty || uri.hasPort) return null;

    if (scheme == 'videocallapp') {
      final segments = uri.pathSegments;
      if (segments.length == 2 && segments.first == 'u') {
        final handle = segments[1].toLowerCase();
        return RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(handle) ? handle : null;
      }
      if (host == 'u' && segments.length == 1) {
        final handle = segments[0].toLowerCase();
        return RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(handle) ? handle : null;
      }
      return null;
    }

    if ((scheme != 'https' && scheme != 'http') ||
        (host != 'gupshupgo.app' && host != 'www.gupshupgo.app')) {
      return null;
    }
    final segments = uri.pathSegments;
    if (segments.length != 2 || segments.first != 'u') return null;
    final handle = segments[1].toLowerCase();
    return RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(handle) ? handle : null;
  }

  void receive(Uri uri) {
    final username = extractUsername(uri);
    if (username == null) return;
    final now = _now();
    // app_links may deliver the launch intent through both initial and stream.
    if (uri == _lastUri &&
        _lastReceivedAt != null &&
        now.difference(_lastReceivedAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastUri = uri;
    _lastReceivedAt = now;
    _pending = username;
    _flush();
  }

  void setReady(bool ready) {
    _ready = ready;
    _flush();
  }

  void _flush() {
    final username = _pending;
    if (_ready && username != null && openProfile(username)) _pending = null;
  }
}
