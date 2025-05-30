import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraService {
  static Future<RtcEngine> initAgora() async {
    RtcEngine engine = createAgoraRtcEngine();

    await engine.initialize(const RtcEngineContext(
      appId: 'f895972511b643da8d29d84ea25e4801', // Your Agora App ID
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    // Enable audio and video
    await engine.enableAudio();
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

    return engine;
  }

  static Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> permissions = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    bool allGranted = permissions.values.every(
      (status) => status == PermissionStatus.granted,
    );

    if (!allGranted) {
      print('Permissions not granted: $permissions');
    }

    return allGranted;
  }

  // For production use: implement token generation
  static Future<String?> generateToken(String channelName, int uid) async {
    // TODO: Implement server-side token generation
    // For now, return null to use no-token mode (testing only)
    return null;
  }
}
