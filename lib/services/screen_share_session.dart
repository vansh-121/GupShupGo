import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:video_chat_app/services/agora_services.dart';
import 'package:video_chat_app/services/call_signaling_service.dart';

/// Which side of a one-way screen share this session represents.
enum ScreenShareRole { sharer, viewer }

/// A long-lived, app-global screen-share session.
///
/// The Agora [RtcEngine] is owned here — NOT by the screen widget — so the
/// session keeps running when the user navigates away (e.g. taps back to keep
/// chatting). The full-screen views and the floating mini-bubble are just
/// observers of this singleton. This is what enables the WhatsApp-style
/// "minimise, keep sharing, tap to return" behaviour.
class ScreenShareSession extends ChangeNotifier {
  ScreenShareSession._();
  static final ScreenShareSession instance = ScreenShareSession._();

  RtcEngine? _engine;
  RtcEngine? get engine => _engine;

  ScreenShareRole? _role;
  ScreenShareRole? get role => _role;

  String? _channelId;
  String? get channelId => _channelId;

  /// Display name of the OTHER participant (viewer name for the sharer,
  /// sharer name for the viewer).
  String _peerName = '';
  String get peerName => _peerName;

  bool _active = false;
  bool get active => _active;

  bool _connected = false; // local engine has joined the channel
  bool get connected => _connected;

  /// Sharer side: a viewer has joined. Viewer side: the remote screen track
  /// is available. Either way, media is flowing.
  bool _peerPresent = false;
  bool get peerPresent => _peerPresent;

  /// Viewer side: the remote uid whose screen we render. Null until present.
  int? _remoteUid;
  int? get remoteUid => _remoteUid;

  /// Whether the full-screen view is currently shown (vs. minimised to the
  /// floating bubble).
  bool _expanded = false;
  bool get expanded => _expanded;

  int _elapsedSeconds = 0;
  int get elapsedSeconds => _elapsedSeconds;
  Timer? _timer;

  bool _ending = false;
  StreamSubscription<CallSignalStatus?>? _signalingSub;

  /// Fired when the session fully ends, so the overlay host / routes can
  /// react (e.g. pop the full-screen view if it is open).
  VoidCallback? onEnded;

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  /// Start sharing this device's screen on [channelId]. Triggers the Android
  /// MediaProjection consent dialog. Throws on failure (caller resets state).
  Future<void> startAsSharer({
    required String channelId,
    required String viewerName,
  }) async {
    _role = ScreenShareRole.sharer;
    _channelId = channelId;
    _peerName = viewerName;
    _active = true;
    _expanded = true;
    notifyListeners();

    _engine = await AgoraService.initAgoraForScreenShare();
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection c, int elapsed) {
          _connected = true;
          notifyListeners();
        },
        onUserJoined: (RtcConnection c, int remoteUid, int elapsed) {
          _peerPresent = true;
          _startTimer();
          notifyListeners();
        },
        onUserOffline: (RtcConnection c, int remoteUid,
            UserOfflineReasonType reason) {
          if (_peerPresent && !_ending) end();
        },
        onError: (ErrorCodeType err, String msg) {
          if (kDebugMode) debugPrint('Agora screen share error: $err - $msg');
        },
      ),
    );

    await AgoraService.startScreenShare(_engine!);

    await _engine!.joinChannel(
      token: '',
      channelId: channelId,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishScreenCaptureVideo: true,
        publishScreenCaptureAudio: true,
        publishCameraTrack: false,
        publishMicrophoneTrack: false,
        autoSubscribeVideo: false,
        autoSubscribeAudio: false,
      ),
    );
  }

  /// Join an existing screen share as the viewer.
  Future<void> startAsViewer({
    required String channelId,
    required String sharerName,
  }) async {
    _role = ScreenShareRole.viewer;
    _channelId = channelId;
    _peerName = sharerName;
    _active = true;
    _expanded = true;
    notifyListeners();

    _engine = await AgoraService.initAgoraForScreenShareViewer();
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection c, int elapsed) {
          _connected = true;
          _engine?.setEnableSpeakerphone(true).catchError((e) {
            if (kDebugMode) debugPrint('setEnableSpeakerphone failed: $e');
          });
          notifyListeners();
        },
        onUserJoined: (RtcConnection c, int remoteUid, int elapsed) {
          _remoteUid = remoteUid;
          _peerPresent = true;
          _startTimer();
          notifyListeners();
        },
        onUserOffline: (RtcConnection c, int remoteUid,
            UserOfflineReasonType reason) {
          // Sharer stopped — end the viewer session.
          if (!_ending) end();
        },
        onError: (ErrorCodeType err, String msg) {
          if (kDebugMode) debugPrint('Agora viewer error: $err - $msg');
        },
      ),
    );

    await _engine!.joinChannel(
      token: '',
      channelId: channelId,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishCameraTrack: false,
        publishMicrophoneTrack: false,
        publishScreenCaptureVideo: false,
        publishScreenCaptureAudio: false,
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
      ),
    );

    // Viewer also ends when the signaling doc flips to ended/declined.
    _signalingSub =
        CallSignalingService.listenToCallStatus(channelId).listen((status) {
      if (status == CallSignalStatus.ended ||
          status == CallSignalStatus.declined) {
        if (!_ending) end();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      notifyListeners();
    });
  }

  String get formattedDuration {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ─── View state ────────────────────────────────────────────────────────

  /// Minimise the full-screen view to the floating bubble (session keeps
  /// running).
  void minimize() {
    if (!_expanded) return;
    _expanded = false;
    notifyListeners();
  }

  /// Expand from the floating bubble back to the full-screen view.
  void expand() {
    if (_expanded) return;
    _expanded = true;
    notifyListeners();
  }

  // ─── Teardown ────────────────────────────────────────────────────────────

  /// End the session: stop capture, leave the channel, release the engine,
  /// and notify observers so the UI tears down.
  Future<void> end() async {
    if (_ending) return;
    _ending = true;

    _timer?.cancel();
    await _signalingSub?.cancel();
    _signalingSub = null;

    final engine = _engine;
    final channelId = _channelId;
    final role = _role;

    // Reset published state so the bubble/overlay disappears immediately.
    _active = false;
    _expanded = false;
    _connected = false;
    _peerPresent = false;
    _remoteUid = null;
    _engine = null;
    notifyListeners();
    onEnded?.call();

    try {
      if (engine != null && role == ScreenShareRole.sharer) {
        await AgoraService.stopScreenShare(engine);
      }
      if (channelId != null) {
        await CallSignalingService.endCall(channelId);
      }
      await AgoraService.releaseEngine(engine);
    } catch (e) {
      if (kDebugMode) debugPrint('Error ending screen share session: $e');
    }

    // Reset the rest for reuse.
    _role = null;
    _channelId = null;
    _peerName = '';
    _elapsedSeconds = 0;
    _ending = false;
  }
}
