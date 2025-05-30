import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraService {
  static Future<RtcEngine> initAgora() async {
    RtcEngine engine = createAgoraRtcEngine();
    await engine.initialize(const RtcEngineContext(
      appId:
          'e7f6e9aeecf14b2ba10e3f40be9f56e7', // Replace with your Agora App ID
    ));
    await engine.enableVideo();
    await engine.startPreview();

    return engine;
  }

  static Future<void> requestPermissions() async {
    await [Permission.camera, Permission.microphone].request();
  }
}
