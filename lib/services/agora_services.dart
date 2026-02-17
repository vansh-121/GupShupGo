import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraService {
  static bool _isReleasing = false;
  
  static Future<RtcEngine> initAgora({bool isAudioOnly = false}) async {
    // Wait if previous engine is still being released
    if (_isReleasing) {
      print('Waiting for previous engine to release...');
      await Future.delayed(Duration(milliseconds: 500));
    }
    
    RtcEngine engine = createAgoraRtcEngine();

    await engine.initialize(const RtcEngineContext(
      appId: '49a88df036b446d892ed933756e9fe6f', // Your Agora App ID
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    // Enable audio (always needed)
    await engine.enableAudio();

    if (!isAudioOnly) {
      // Enable video only if not audio-only mode
      await engine.enableVideo();

      // Set video configuration
      await engine.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 480),
          frameRate: 15,
          bitrate: 400,
        ),
      );

      // Start preview
      await engine.startPreview();
    }

    return engine;
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
      await engine.leaveChannel();
      await engine.release();
      // Add a small delay to ensure complete cleanup
      await Future.delayed(Duration(milliseconds: 300));
    } catch (e) {
      print('Error releasing engine: $e');
    } finally {
      _isReleasing = false;
    }
  }
}
