import Flutter
import UIKit
import AVFAudio
import CallKit
import PushKit
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate, CallkitIncomingAppDelegate {
  private var voipRegistry: PKPushRegistry?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // FCM notification tokens cannot receive APNs VoIP pushes. PushKit is the
    // only supported way to wake a terminated iOS app and report the call to
    // CallKit within Apple's deadline.
    let registry = PKPushRegistry(queue: .main)
    registry.delegate = self
    registry.desiredPushTypes = [.voIP]
    voipRegistry = registry

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func pushRegistry(
    _ registry: PKPushRegistry,
    didUpdate credentials: PKPushCredentials,
    for type: PKPushType
  ) {
    guard type == .voIP else { return }
    let token = credentials.token.map { String(format: "%02x", $0) }.joined()
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(token)
  }

  func pushRegistry(
    _ registry: PKPushRegistry,
    didInvalidatePushTokenFor type: PKPushType
  ) {
    guard type == .voIP else { return }
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
  }

  func pushRegistry(
    _ registry: PKPushRegistry,
    didReceiveIncomingPushWith payload: PKPushPayload,
    for type: PKPushType,
    completion: @escaping () -> Void
  ) {
    guard type == .voIP else {
      completion()
      return
    }

    let push = payload.dictionaryPayload
    let rawChannelId = push["channelId"] as? String ?? push["id"] as? String ?? ""
    let callId = UUID(uuidString: rawChannelId)?.uuidString ?? UUID().uuidString
    let callerId = push["callerId"] as? String ?? ""
    let callerName = push["callerName"] as? String ?? callerId
    let callerPhotoUrl = push["callerPhotoUrl"] as? String ?? ""
    let isAudioOnly = (push["isAudioOnly"] as? String) == "true" ||
      (push["isAudioOnly"] as? Bool) == true

    guard !rawChannelId.isEmpty else {
      completion()
      return
    }

    let data = flutter_callkit_incoming.Data(
      id: callId,
      nameCaller: callerName.isEmpty ? "Unknown" : callerName,
      handle: isAudioOnly ? "Audio Call" : "Video Call",
      type: isAudioOnly ? 0 : 1
    )
    data.appName = "GupShupGo"
    data.avatar = callerPhotoUrl
    data.duration = 45_000
    data.iconName = "AppIcon"
    data.supportsVideo = true
    data.maximumCallsPerCallGroup = 1
    data.audioSessionMode = "default"
    data.audioSessionActive = true
    data.ringtonePath = "system_ringtone_default"
    data.extra = [
      "callerId": callerId,
      "channelId": rawChannelId,
      "isAudioOnly": isAudioOnly ? "true" : "false",
    ]

    SwiftFlutterCallkitIncomingPlugin.sharedInstance?
      .showCallkitIncoming(data, fromPushKit: true)
    completion()
  }

  // The plugin forwards native CallKit actions to Dart. Fulfil the system
  // transactions immediately so iOS does not time them out while Flutter boots.
  func onAccept(_ call: Call, _ action: CXAnswerCallAction) {
    action.fulfill()
  }

  func onDecline(_ call: Call, _ action: CXEndCallAction) {
    action.fulfill()
  }

  func onEnd(_ call: Call, _ action: CXEndCallAction) {
    action.fulfill()
  }

  func onTimeOut(_ call: Call) {}

  func didActivateAudioSession(_ audioSession: AVAudioSession) {}

  func didDeactivateAudioSession(_ audioSession: AVAudioSession) {}
}
