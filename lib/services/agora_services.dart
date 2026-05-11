import 'package:agora_rtc_engine/agora_rtc_engine.dart';
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
      await Future.delayed(Duration(milliseconds: 500));
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
              degradationPreference:
                  DegradationPreference.maintainFramerate,
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
        encryptionKey: String.fromCharCodes(k.key),
        encryptionKdfSalt: k.salt,
      ),
    );
  }

  // For production use: implement token generation
  static Future<String?> generateToken(String channelName, int uid) async {
    // TODO: Implement server-side token generation
    // For now, return null to use no-token mode (testing only)
    return null;
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
          await Future.delayed(Duration(milliseconds: 300));
        },
      );
    } catch (e, stack) {
      print('Error releasing engine: $e');
      CrashlyticsService.logError(
        e, stack,
        reason: 'Agora engine release failed',
      );
    } finally {
      _isReleasing = false;
    }
  }
}
