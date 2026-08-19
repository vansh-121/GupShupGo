# Changelog

All notable changes to the GupShupGo project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned Features
- Group messaging support
- End-to-end encryption for messages
- Message forwarding
- Backup and restore functionality
- Search functionality for messages and users
- User blocking with UI improvements
- Custom themes and color palettes

## [1.1.6] - 2026-08-19

### Added
- 🔗 **Tappable Links in Chats** — Web links in any conversation are now underlined and open straight in your browser with a single tap, in normal chats, offline mesh chats, and anonymous rooms.
- 🖼️ **Link Previews** — Share a link and both of you see a neat card with the page's title, description, and thumbnail, so you know what you're opening before you tap it.
- ↩️ **Swipe to Reply** — Swipe any message to the right to reply to it directly. Your reply shows the quoted message above it, so nobody loses track of what you're answering.
- 👆 **Tap a Quote to Jump** — Tapping the quoted message in a reply scrolls you back to the original and briefly highlights it.
- 👆 **Fingerprint Unlock, On Your Terms** — Vault settings now has an "Unlock with fingerprint" switch you can turn on or off any time. Turning it on asks for your PIN once; turning it off just means you type your PIN again.

### Changed
- Updated version to 1.1.6 (build code 52).
- 🔒 **Previews Never Phone Home** — Link cards are prepared entirely on the sender's device, so opening a chat never contacts the linked website. Your IP address is never exposed to a link someone sent you, and cards still appear with no internet connection.
- 💬 **Replies Survive Deletions** — Each reply carries its own copy of the quoted text, so the quote keeps showing even if the original message was deleted or cleared from your device.
- 🔑 **You Always Choose Your Vault PIN** — Setting up the vault now always asks you to pick a PIN, and fingerprint unlock is offered afterwards as a convenience. Your PIN is what protects your history, and it is the only thing that can restore your messages on a new phone.
- ⏳ **"Decide Later" on the Unlock Screen** — Forgetting your PIN no longer forces a choice between deleting everything and being stuck. You can keep using the app with the vault locked, and unlocking later fills in whatever was missed.

### Fixed
- 👆 **Fingerprint No Longer Asks for a PIN You Never Set** — If you set the vault up with your fingerprint and later reinstalled the app, unlocking asked for a PIN that was never shown to you, leaving a full reset as the only way forward. Setup now always uses a PIN you chose, and anyone already in that situation is asked once — while their history is still readable — to pick a real PIN, with every existing message carried over.
- 🚫 **No Fingerprint Buttons That Cannot Work** — The unlock screen only offers fingerprint when there is actually something on this device for it to unlock, and explains what to do instead when there isn't.
- 🔐 **Your PIN Is Only Stored If You Ask** — Previously the app saved your PIN on the device after every unlock, whether or not you wanted fingerprint unlock. It is now saved only when you explicitly turn that feature on.

### Technical Details
- **Sender-Side Unfurl:** OpenGraph metadata is fetched by the sending device and travels *inside* the encrypted Signal payload (`linkPreview*` fields), so nothing about the link is ever readable by the server and the receiving client makes no outbound request. Thumbnails are re-encoded to a ≤6 KB base64 JPEG to stay well within the 1 MiB Firestore document ceiling after per-device envelope fan-out.
- **Snapshot Quotes:** `replyTo*` fields carry a self-contained copy of the quoted sender, type, and a 160-character snippet rather than a server-resolvable pointer, which is what makes quotes render for undecryptable, deleted, or never-synced originals.
- **Content Key Registry:** `kMessageContentKeys` now declares every key that may appear in an encrypted payload, covered by a serializer test asserting `ChatService.applyPayload` consumes all of them — the previously-silent failure mode when adding an encrypted field.
- **Package Visibility:** Added `android.intent.action.VIEW` `http`/`https` entries to the manifest `<queries>` block, required for link launching on Android 11+.
- **PIN Custody Flag:** `vaultMeta/config` now carries `pinIsUserChosen`, set only at the moments that *prove* the user supplied the PIN — `setup`, `changePin`, and a successful typed-PIN `unlock`. It lives in Firestore rather than local storage because the question "does this person know their PIN" is account-level and must survive uninstall, and it reveals nothing about the key. A stored PIN is deliberately *not* used as the signal: the old code wrote one on every unlock, so its presence says nothing about its origin, and shape heuristics ("6 digits") misfire in both directions.
- **One-Time Re-Key:** `classifyPinCustody` (pure, exhaustively tested over all 8 input combinations) resolves to exactly one state that may interrupt the user at launch — config present, custody unproven, old PIN still readable. That case re-keys the whole vault via the existing `changePin`, which validates the old PIN against the verifier, re-encrypts in 150-doc pages, and flips the verifier **last**, so an interrupted run leaves the old PIN valid and can simply be repeated. The window closes permanently once an affected install is removed.
- **No New Crypto Primitive:** The "confirm you know your PIN" path reuses `unlock`, which returns `false` *before* caching the derived key, so a wrong guess cannot disturb an already-open vault.
- **Known Limitation:** `flutter_secure_storage` has no biometric binding, so a successful `local_auth` scan is a UI gate rather than a cryptographic one — the stored PIN rests on `encryptedSharedPreferences` / Keychain `first_unlock`. Real binding needs an Android Keystore key with `setUserAuthenticationRequired(true)` behind a platform channel, and is not claimed by the opt-in copy.

---

## [1.1.5] - 2026-08-18

### Added
- ⚡ **Ultra-Fast & Reliable Messaging** — Rapid back-to-back messages now send and deliver instantly with zero dropped chats or stutter.
- 🔄 **Smart Chat Auto-Recovery** — If a message ever gets stuck or your connection drops, the app quietly fixes and restores it in the background without needing manual retries.
- 🌙 **Background Chat Sync** — New silent sync ensures your friends' devices automatically receive and process missing messages even when their phone is locked or in sleep mode.
- 🛡️ **Enhanced Protection & Spam Prevention** — Advanced security protections to prevent server spam and ensure safe, uninterrupted communication.

### Changed
- Updated version to 1.1.5 (build code 51).
- 💾 **Reliable Chat History Storage** — Chat sessions and keys are stored more securely so messages stay available even after phone restarts or app updates.
- 💬 **Clear Message Statuses** — Improved indicators like "Waiting for this message…" while the app automatically syncs missing conversations.

### Fixed
- Fixed rapid messages sometimes getting delayed or stuck when sent quickly in a row.
- Fixed chat sync issues occurring after restarting the device.
- Fixed unnecessary retry alerts when friends are offline.

### Technical Details
- **AddressLock Engine:** FIFO async lock per `(uid, deviceId)` tuple protecting libsignal session ratchets against concurrent race conditions.
- **Wakeup Protocol:** Cloud Function trigger bridging `resendWakeups` collection to high-priority FCM data messages for background recovery.
- **Store Architecture:** Re-entrant SQLite persistence layer for Double Ratchet sessions and PreKeys.

---

## [1.1.4] - 2026-08-14

### Added
- 🔐 **Real-Time E2EE Status Indicators** — Dynamic status badges in audio and video calls accurately displaying setup (`Securing call…`), active encryption (`End-to-end encrypted`), or fallback state (`Not encrypted`).
- ⚡ **Instant Call Teardown & Cancellation** — Aborting outbound calls while connecting immediately retracts signaling documents and stops notifications to prevent ghost ringing.
- 🛡️ **Support & Problem Report Protection** — Strict Firestore security schema validation (`isValidProblemReport()`) and sliding-window Cloud Function rate-limiting (5 reports / hr / user).

---

## [1.1.3] - 2026-08-10

### Added
- 📺 **Picture-in-Picture (PiP) Video Calling** — Support for background floating picture-in-picture window during active video calls, enabling uninterrupted multi-tasking.
- 👤 **Username Handles & QR Profile Sharing** — Reserve unique `@username` handles, generate dynamic QR code profiles, scan QR codes to instantly add friends, and sync contacts.
- 🔥 **Bond Streak System** — Interactive daily chat streaks with automated streak calculation, visual status badges, and streak restoration mechanism.
- 📲 **Auto-Verification Phone Auth** — Seamless carrier phone verification with auto-retrieval and streamlined onboarding flow.

### Changed
- Updated version to 1.1.3 (build code 46).
- 🚀 **Android 16 KB Page Size Alignment** — Native libraries (Agora RTC Engine, C++ binaries) built and aligned for 16 KB page-size compliance on Android 15+.
- 📱 **Edge-to-Edge Display Optimization** — Enforced full edge-to-edge UI rendering for Android 10–14+.
- 🛡️ **Play Integrity Provider** — Replaced deprecated SafetyNet provider with Google Play Integrity API for App Check verification.
- ⚡ **Progressive Message Sync** — Progressive stream flushing and reconciliation throttling for ultra-low latency chat synchronization.

### Fixed
- Fixed stale authentication screen issues during username handle setup navigation.
- Fixed reciprocal contact request privilege escalation in Firestore security rules.
- Fixed offline connectivity banner color harmonization in dark/light themes.

### Technical Details
- **PiP Architecture:** Android Picture-in-Picture lifecycle handlers with video aspect ratio preservation.
- **User Handles:** Firestore rules enforcement for handle uniqueness and sanitization regex.
- **Streak Engine:** Cloud Functions background trigger with vector-validated streak state transitions.
- **Target SDK:** Aligned targetSdk to Android API 36 (Android 16).

---

## [1.0.6] - 2026-05-09

### Changed
- 📹 **Video Quality Upgraded** — Resolution tuned to 720p @ 30fps with 2000 kbps target bitrate (up from 1800 kbps). Uses `maintainFramerate` degradation preference so video stays smooth; previous 1080p setting caused CPU encoding lag on mobile.
- 🎛️ **Call Controls Fixed** — All buttons on both video and audio call screens now work correctly:
  - **Speaker**: Replaced deprecated `setEnableSpeakerphone` with the correct `setRouteInCommunicationMode` API
  - **Mute**: Label dynamically updates to "Unmute" when mic is off
  - **Hold**: Fixed to use `adjustPlaybackSignalVolume` instead of `muteAllRemoteAudioStreams` (which permanently broke remote audio)
  - **Camera toggle**: Replaced `muteLocalVideoStream` with `enableLocalVideo` so turning off your camera is properly signalled to the remote user
  - **Switch camera**: Confirmed working
- 🖼️ **Camera-Off Placeholder** — When local camera is disabled, the preview tile shows a grey videocam-off icon instead of a frozen frame
- ⏱️ **Call Timer UI Fixed** — Timer pill now sits inline next to "Connected" on the same line (no more overlap with the username on any device)

### Fixed
- Fixed camera disable not hiding video feed on the remote user's screen
- Fixed speaker button having no visual icon change between on/off states
- Fixed call timer colliding with the username text at the top of the video call screen
- Fixed Hold button silencing the remote audio permanently across the session

### Technical Details
- **Video encoder**: `VideoEncoderConfiguration` with `VideoDimensions(1280, 720)`, `frameRate: 30`, `bitrate: 2000`, `minBitrate: 600`, `DegradationPreference.maintainFramerate`
- **Speaker API**: `setRouteInCommunicationMode(3)` = speaker, `(1)` = earpiece
- **Camera API**: `enableLocalVideo(bool)` — stops/starts hardware capture and signals remote
- **Hold audio**: `adjustPlaybackSignalVolume(0/100)` — non-destructive remote silence

---

## [1.0.5] - 2026-05-08

### Added
- 📱 **Device Session Management** — "Remember this device" feature using secure token storage
  - Survives OS-level data wipes (MIUI, HyperOS)
  - Survives force-stop and app data clearing
  - Maintains login even after battery drain or system crashes
- 📲 **Device-Specific FCM Token Management** — Per-device token storage and automatic refresh
- 💬 **Status Reply Functionality** — Users can send direct messages in response to status updates
- 🔌 **Connectivity Provider** — Real-time network connectivity monitoring with callback system
- ⚠️ **MIUI/HyperOS Notification Optimization** — Special handling for Xiaomi devices with enhanced layout rendering
- ✨ **Enhanced What's New Dialog** — Detailed feature descriptions with improved user experience

### Changed
- Updated version to 1.0.5 with improved feature descriptions
- Refactored FCM token handling for better reliability across device types
- Optimized notification rendering for all Android versions
- Improved device session token exchange with Cloud Functions

### Fixed
- Fixed notification layout rendering on MIUI/HyperOS devices
- Improved FCM token refresh handling on device reboot
- Enhanced device session stability across OS versions

### Technical Details
- **Device Session Service:** Uses FlutterSecureStorage with Android Keystore encryption
- **FCM Management:** Per-device token storage with automatic expiry handling
- **Connectivity Service:** Monitors all connection types (WiFi, mobile, Bluetooth)
- **Status Replies:** Direct messaging from status viewer with automated link creation

---

## [1.0.4] - 2026-05-03

### Added
- 🎙️ **Voice Messaging** — Send and receive audio messages within chat with playback controls
- 🌐 **Mesh Networking** — Offline peer-to-peer chat with nearby devices using Nearby Connections API
- 🌙 **Dark Mode Support** — Full dark mode implementation with seamless theme switching
- ✨ **What's New Dialog** — Shows new features and improvements on first launch after app update
- 📱 **Device Session Management** — Improved session stability and connectivity handling (especially for Redmi devices)
- 🔌 **Enhanced Connectivity Handling** — Better online/offline status detection with auto-reconnect logic
- 🔄 **Mesh Notification Listener** — Automatic message sync for offline messages via mesh network

### Changed
- Updated version code to 27 for Play Store compatibility
- Improved mesh service integration in chat screen UI
- Enhanced audio recording error handling with better user feedback
- Optimized connectivity checks for improved session management
- Refined Android build settings for peer-to-peer connectivity

### Fixed
- Fixed session management issues on Redmi devices and other device types
- Improved backup rules for better data integrity
- Enhanced authentication handling for better user experience
- Fixed audio recording errors with graceful fallback

### Technical Details
- **Mesh Service:** Implemented via Nearby Connections API for offline messaging
- **Voice Messages:** Native audio recording with platform-specific handling
- **Theme Provider:** Added theme switching with persistent storage
- **Connectivity Service:** Smart detection with exponential backoff for reconnection

---

## [1.0.3] - 2026-04-15

### Added
- 🎨 **Dark Mode Theme** — Complete dark theme support across the entire app
- ✨ **What's New Dialog** — Feature announcement on first launch after updates
- 🔄 **Auto-reconnect Logic** — Mesh network auto-reconnection with improved error handling

### Changed
- Updated version to 1.0.3
- Enhanced backup and security rules
- Improved auth handling for better reliability
- Refined UI components (PhoneAuthScreen, SettingsScreen) for consistent theming

### Fixed
- Fixed theme consistency across all screens
- Improved mesh service error handling

---

## [1.0.2] - 2026-03-28

### Added
- 🌙 **Light and Dark Mode Support** — Full theme switching capability
- 🎨 **Material Design 3 Theme Provider** — Unified design system

### Changed
- Updated version to 1.0.2
- Refactored code formatting for consistency

### Technical Details
- **Theme Implementation:** Provider-based state management
- **Persistence:** Uses SharedPreferences for theme persistence

---

## [1.0.1] - 2026-03-10

### Added
- 🔐 **Phone Authentication** with OTP verification
- 📱 **Carrier-based Phone Verification** (Phone Number Hint API)
- 🔗 **Google Sign-In** with account linking
- 👤 **Guest Login** for quick testing
- 📞 **Video Calling** with Agora RTC Engine
- 🎙️ **Voice Calling** (audio-only)
- 📲 **Native CallKit Call UI** for native call experience
- 💬 **Real-Time Messaging** with read receipts
- 📸 **Status Updates** (24-hour expiry)
- 🔔 **Push Notifications** via Firebase Cloud Messaging
- ⚙️ **Settings & Privacy Controls**
- 👥 **User Search** and profile browsing
- 🟢 **Online/Offline Status** indicators

### Technical Details
- **Backend:** Firebase (Auth, Firestore, Storage, Cloud Functions, FCM)
- **Video/Audio:** Agora RTC Engine
- **Real-Time:** Firebase Cloud Messaging for push notifications
- **Local Storage:** SharedPreferences for caching and settings
- **Security:** Firebase App Check, Firestore security rules

---

## [1.0.0] - 2026-02-15

### Initial Release
- ✅ **Core Chat Application** based on WhatsApp architecture
- 📞 **Video/Voice Calling** with Agora SDK
- 💬 **Real-Time Messaging** system
- 📸 **Status Updates** feature
- 🔐 **Authentication System**
- ⚙️ **Settings & Privacy** controls
- 🎨 **Modern Material Design 3 UI**

### Technical Foundation
- **Framework:** Flutter (Dart)
- **Architecture:** Clean Architecture with Service/Provider Pattern
- **Backend:** Firebase infrastructure
- **Real-Time:** Firestore with offline support
- **Calling:** Agora RTC Engine
- **Push Notifications:** Firebase Cloud Messaging

---

## Version History Summary

| Version | Date | Key Features |
|---------|------|--------------|
| 1.1.3 | August 2026 | Picture-in-Picture Video Calls, Username Handles & QR Sharing, Bond Streaks, Android 16 KB Page Size Alignment |
| 1.0.6 | May 2026 | Video quality, call controls fixed, camera-off signalling, timer UI |
| 1.0.5 | May 2026 | Device Session Mgmt, FCM Token Mgmt, Status Replies, Connectivity Monitoring, MIUI/HyperOS Optimization |
| 1.0.4 | May 2026 | Voice Messaging, Mesh Networking, Dark Mode, Device Session Mgmt |
| 1.0.3 | April 2026 | Dark Mode UI, What's New Dialog, Auto-Reconnect |
| 1.0.2 | March 2026 | Theme Provider, Dark/Light Mode |
| 1.0.1 | March 2026 | Complete messaging & calling features |
| 1.0.0 | February 2026 | Initial release |

---

## Installation Guide

See [README.md](README.md) for detailed installation and setup instructions.

---

## Contributing

Please refer to [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for contribution guidelines.

---

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

---

## Support

For issues, questions, or feature requests, please visit the [GitHub Issues](https://github.com/vansh-121/GupShupGo/issues) page.
