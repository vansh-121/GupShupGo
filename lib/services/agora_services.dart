import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:video_chat_app/services/crashlytics_service.dart';
import 'package:video_chat_app/services/crypto/call_encryption_service.dart';
import 'package:video_chat_app/services/performance_service.dart';

class AgoraService {
  static bool _isReleasing = false;

  static Future<RtcEngine> initAgora({bool isAudioOnly = false}) async {
    // Wait if previous engine is still being released
    if (_isReleasing) {
      print('Waiting for previous engine to release...');
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return PerformanceService.traceAsync(
      PerformanceService.kTraceAgoraInit,
      (trace) async {
        PerformanceService.setAttribute(
            trace, 'mode', isAudioOnly ? 'audio' : 'video');

        RtcEngine engine = createAgoraRtcEngine();

        await engine.initialize(const RtcEngineContext(
          appId: '49a88df036b446d892ed933756e9fe6f',
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ));

        // ── Audio configuration ──────────────────────────────────────────
        await engine.enableAudio();

        // High-quality audio profile (like WhatsApp voice clarity)
        await engine.setAudioProfile(
          profile: AudioProfileType.audioProfileDefault,
          scenario: AudioScenarioType.audioScenarioChatroom,
        );

        // Enhanced noise suppression for clearer voice
        await engine.setAINSMode(
          enabled: true,
          mode: AudioAinsMode.ainsModeAggressive,
        );

        if (!isAudioOnly) {
          // ── Video configuration ──────────────────────────────────────
          await engine.enableVideo();

          // 720p @ 30fps — WhatsApp/FaceTime-level quality.
          // 1080p causes heavy CPU encoding lag on mobile; 720p @ 2000kbps
          // is the industry-proven sweet spot for mobile video calls.
          await engine.setVideoEncoderConfiguration(
            const VideoEncoderConfiguration(
              dimensions: VideoDimensions(width: 1280, height: 720),
              frameRate: 30,
              bitrate: 2000,
              minBitrate: 600,
              orientationMode: OrientationMode.orientationModeAdaptive,
              // Smooth motion first: reduce resolution before dropping FPS
              degradationPreference: DegradationPreference.maintainFramerate,
              mirrorMode: VideoMirrorModeType.videoMirrorModeDisabled,
            ),
          );

          // Start preview
          await engine.startPreview();
        }

        return engine;
      },
      attributes: {'mode': isAudioOnly ? 'audio' : 'video'},
    );
  }

  static Future<bool> requestPermissions({bool isAudioOnly = false}) async {
    List<Permission> permissions = [Permission.microphone];

    if (!isAudioOnly) {
      permissions.add(Permission.camera);
    }

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    bool allGranted = statuses.values.every(
      (status) => status == PermissionStatus.granted,
    );

    if (!allGranted) {
      print('Permissions not granted: $statuses');
    }

    return allGranted;
  }

  /// E2EE for the media stream. Call BEFORE joinChannel.
  ///
  /// `key` is the shared 32-byte secret derived per-call and exchanged via
  /// the Signal-encrypted CallEncryptionService envelope. `salt` is the
  /// matching 16-byte KDF salt. Both sides must pass the exact same bytes
  /// or the stream will be unintelligible (Agora drops un-decryptable frames
  /// silently — there is no failure callback).
  static Future<void> enableMediaEncryption(
      RtcEngine engine, CallEncryptionKey k) async {
    await engine.enableEncryption(
      enabled: true,
      config: EncryptionConfig(
        encryptionMode: EncryptionMode.aes256Gcm2,
        encryptionKey:
            k.key.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        encryptionKdfSalt: k.salt,
      ),
    );
  }

  static const String _tokenFunctionUrl =
      'https://us-central1-videocallapp-81166.cloudfunctions.net/generateAgoraToken';

  /// Fetches a short-lived Agora RTC token from the server for [channelName].
  ///
  /// The App Certificate that signs the token lives only in the Cloud Function
  /// secret store — never in the client. Requires the user to be signed in
  /// (the request carries their Firebase ID token).
  ///
  /// Returns null on any failure so callers can fall back to token-less join
  /// (only works if the Agora project is still in "testing / no-certificate"
  /// mode). Once the App Certificate is enabled on the Agora dashboard, a null
  /// here means the join will fail — which is the intended, secure behaviour.
  static Future<String?> generateToken(String channelName, {int uid = 0}) async {
    try {
      final idToken =
          await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        print('generateToken: no signed-in user; cannot mint Agora token');
        return null;
      }

      final response = await http
          .post(
            Uri.parse(_tokenFunctionUrl),
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'channelName': channelName, 'uid': uid}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        if (token != null && token.isNotEmpty) return token;
        print('generateToken: server returned empty token');
        return null;
      }

      print('generateToken failed: ${response.statusCode} ${response.body}');
      return null;
    } catch (e, stack) {
      print('generateToken error: $e');
      CrashlyticsService.logError(e, stack,
          reason: 'AgoraService.generateToken failed for $channelName');
      return null;
    }
  }

  /// Initialise the engine for screen sharing.
  ///
  /// Unlike a normal video call this does NOT enable the camera or start a
  /// camera preview — the published video track is the device screen, captured
  /// via [startScreenShare]. Audio is enabled so the device's system audio
  /// (e.g. a voice note or video playing on the sharer's screen) can be
  /// captured and sent to the viewer along with the screen video.
  static Future<RtcEngine> initAgoraForScreenShare() async {
    if (_isReleasing) {
      print('Waiting for previous engine to release...');
      await Future.delayed(const Duration(milliseconds: 500));
    }

    RtcEngine engine = createAgoraRtcEngine();

    await engine.initialize(const RtcEngineContext(
      appId: '49a88df036b446d892ed933756e9fe6f',
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    await engine.enableVideo();
    await engine.enableAudio();

    // Agora recommends the game-streaming scenario to improve the success
    // rate of capturing system audio during screen sharing (Android 10+).
    await engine.setAudioScenario(
      AudioScenarioType.audioScenarioGameStreaming,
    );

    return engine;
  }

  /// Request the permissions needed to view a shared screen (the viewer side).
  ///
  /// The viewer renders the remote screen video and plays the remote system
  /// audio (so it can hear sounds playing on the sharer's device). No local
  /// camera/mic capture is required.
  static Future<RtcEngine> initAgoraForScreenShareViewer() async {
    if (_isReleasing) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    RtcEngine engine = createAgoraRtcEngine();

    await engine.initialize(const RtcEngineContext(
      appId: '49a88df036b446d892ed933756e9fe6f',
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    await engine.enableVideo();
    await engine.enableAudio();

    return engine;
  }

  /// Start capturing the device screen.
  ///
  /// On Android this triggers the system MediaProjection consent dialog. This
  /// must be called BEFORE [RtcEngine.joinChannel]; the channel's media options
  /// (publishScreenCaptureVideo: true) are what actually publish the captured
  /// screen to the remote viewer. Do NOT call updateChannelMediaOptions before
  /// joining — it fails with error -8 (invalid state).
  static Future<void> startScreenShare(RtcEngine engine) async {
    await engine.startScreenCapture(
      const ScreenCaptureParameters2(
        // Capture the device's system audio so the viewer can hear sounds
        // (voice notes, videos, etc.) playing on the sharer's screen.
        // System-audio capture requires Android 10 (API 29) or later; on
        // older versions the SDK simply ignores it and shares video only.
        captureAudio: true,
        audioParams: ScreenAudioParameters(
          sampleRate: 16000,
          channels: 2,
          captureSignalVolume: 100,
        ),
        captureVideo: true,
        videoParams: ScreenVideoParameters(
          dimensions: VideoDimensions(width: 1280, height: 720),
          frameRate: 15,
          bitrate: 0, // 0 = let the SDK pick a standard bitrate for the size
        ),
      ),
    );
  }

  /// Stop screen capture and stop publishing the screen track.
  static Future<void> stopScreenShare(RtcEngine engine) async {
    try {
      await engine.updateChannelMediaOptions(
        const ChannelMediaOptions(
          publishScreenCaptureVideo: false,
          publishScreenCaptureAudio: false,
        ),
      );
      await engine.stopScreenCapture();
    } catch (e) {
      print('Error stopping screen share: $e');
    }
  }

  static Future<void> releaseEngine(RtcEngine? engine) async {
    if (engine == null) return;

    _isReleasing = true;
    try {
      await PerformanceService.traceAsync(
        PerformanceService.kTraceAgoraRelease,
        (_) async {
          await engine.leaveChannel();
          await engine.release();
          // Add a small delay to ensure complete cleanup
          await Future.delayed(const Duration(milliseconds: 300));
        },
      );
    } catch (e, stack) {
      print('Error releasing engine: $e');
      CrashlyticsService.logError(
        e,
        stack,
        reason: 'Agora engine release failed',
      );
    } finally {
      _isReleasing = false;
    }
  }
}
