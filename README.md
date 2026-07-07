# GupShupGo — Enterprise Communication & Decentralized Gaming Ecosystem

<div align="center">

```
   ______              _____ __                 ______     
  / ____/_  ______  __/ ___// /_  __  ______  _/ ____/___  
 / / __/ / / / __ \/ /\__ \/ __ \/ / / / __ \/ / __/ __ \ 
/ /_/ / /_/ / /_/ / /___/ / / / / /_/ / /_/ / /_/ / /_/ / 
\____/\__,_/ .___/_//____/_/ /_/\__,_/ .___/\____/\____/  
          /_/                       /_/                  
```

**The Next-Generation, Offline-Capable, Military-Grade Encrypted Messenger & Arcade built with Flutter & Firebase.**

[![License: MIT](https://img.shields.io/badge/License-MIT-4F46E5.svg?style=flat-square)](LICENSE)
[![Flutter SDK](https://img.shields.io/badge/Flutter-%E2%89%A53.2.0-02569B.svg?style=flat-square&logo=flutter)](https://flutter.dev)
[![Signal Protocol E2EE](https://img.shields.io/badge/Security-Signal%20E2EE-10B981.svg?style=flat-square&logo=signal)](https://signal.org)
[![Mesh Network P2P](https://img.shields.io/badge/Offline-P2P%20Mesh-F59E0B.svg?style=flat-square&logo=bluetooth)](https://pub.dev/packages/nearby_connections)
[![Agora RTC](https://img.shields.io/badge/Calling-Agora%20RTC-0096E6.svg?style=flat-square&logo=agora)](https://agora.io)
[![Firebase Suite](https://img.shields.io/badge/Backend-Firebase-FFCA28.svg?style=flat-square&logo=firebase&logoColor=black)](https://firebase.google.com)

[📖 Architecture Guide](ARCHITECTURE.md) • [📲 Play Store Pre-Register](https://play.google.com/store/apps/details?id=com.gupshupgo.app) • [📽️ Core System Demo](https://drive.google.com/file/d/1SiRGrnEmd6NfMtUpOwt14ZydMXcQpD0l/view?usp=drive_link) • [📽️ Background Call Demo](https://drive.google.com/file/d/1rzKF0wo0TkwQmZVnYHOweSIJxczKQAmL/view?usp=sharing)

</div>

---

## 🏢 Executive Overview

GupShupGo is a production-grade, enterprise-ready messaging and real-time communication application built on Flutter. Engineered for extreme security and absolute offline resilience, GupShupGo integrates zero-knowledge cryptography, peer-to-peer decentralized mesh networks, low-latency video and audio calling with native system CallKit integration, and an interactive casual gaming ecosystem.

### 📐 Core Architectural Pillars

* **Zero-Knowledge Architecture:** Cryptographic keys are generated and stored strictly on-device. Group and direct messages are encrypted before they hit transit, ensuring that no intermediary—including the Firebase backend—can read message contents.
* **Offline-First Resilience:** Powered by a reactive Drift (SQLite) local engine, all application states, message queues, and media caches are stored locally first. Real-time sync mechanisms handle recovery and conflicts seamlessly.
* **Decentralized Peer-to-Peer Routing:** Leveraging nearby network interfaces (Bluetooth & Wi-Fi Direct), devices form ad-hoc mesh networks to deliver messages when cellular networks and internet connections are completely unavailable.
* **Multi-Threaded Security Engine:** Computationally heavy cryptographic operations are offloaded from the main UI thread to dedicated Dart Background Isolates (`crypto_worker.dart`), maintaining 60+ FPS fluid animations.

---

## 🗺️ Table of Contents

1. [🏛️ Core System Architecture](#%EF%B8%8F-core-system-architecture)
2. [✨ Feature Ecosystem](#-feature-ecosystem)
3. [🔐 Cryptographic & Security Specification](#-cryptographic--security-specification)
4. [📡 Decentralized Mesh Protocol](#-decentralized-mesh-protocol)
5. [💻 Technical Stack Specification](#-technical-stack-specification)
6. [📂 Workspace Organization](#-workspace-organization)
7. [🛠️ Infrastructure Setup & Installation](#%EF%B8%8F-infrastructure-setup--installation)
8. [🧪 Verification & Testing Procedures](#-verification--testing-procedures)
9. [⚡ Performance Optimization & Diagnostics](#-performance-optimization--diagnostics)
10. [📈 Roadmap & Release Plan](#-roadmap--release-plan)
11. [🤝 Contribution & Compliance](#-contribution--compliance)

---

## 🏛️ Core System Architecture

GupShupGo utilizes a clean, decoupled architecture utilizing the **Repository Pattern** and **Service Layer** structure to keep UI separate from persistence and external services.

```
+-------------------------------------------------------------------------------+
|                             UI LAYOUT / SCREENS VIEW                           |
|       Home | Chat Screen | Video/Voice Calling | Vault | Arcade | Status      |
+---------------------------------------+---------------------------------------+
                                        | (State Consumers / Observers)
+---------------------------------------v---------------------------------------+
|                            STATE CONTROLLER LAYER                             |
|          Provider State | CallStateProvider | StatusProvider | Theme          |
+---------------------------------------+---------------------------------------+
                                        | (Reactive Service Calls)
+---------------------------------------v---------------------------------------+
|                            BUSINESS SERVICE LAYER                             |
|    SignalService | AgoraService | MeshNetworkService | AuthService | Sync     |
+-------------------+-------------------+-------------------+-------------------+
                    |                   |                   |
                    | (Drift / Crypto)  | (P2P Discovery)   | (Network API)
+-------------------v---+           +---v---------------+   +---v---------------+
|  LOCAL STORAGE & COGNITION  |     |  OFF-GRID AD-HOC  |   | FIREBASE INFRA    |
| - Drift SQLite Database     |     | - Nearby Connect  |   | - Firestore DB    |
| - Crypto Isolate Worker     |     | - Bluetooth/Wi-Fi |   | - Cloud Functions |
| - Android Secure Keystore   |     | - Mesh Routing    |   | - Agora RTC       |
+-----------------------------+     +-------------------+   +-------------------+
```

---

## ✨ Feature Ecosystem

### 💬 Real-Time Messaging & Media Sharing
* **Reactive Drift Database:** Integrates `drift` and `sqlite3_flutter_libs` to perform local persistent message storage, query caching, and UI reactivity. The chat list loads instantly, independent of network speed.
* **Voice Messaging Suite:** In-app audio recording with real-time waveform visualization, scrubbable playback controllers, and adjustable playback speeds (`1.0x`, `1.5x`, `2.0x`).
* **Intelligent Media Pipelines:** Automatic multi-pass client-side image compression (`flutter_image_compress`) reducing data footprints by up to 20× before encrypting and uploading to Firebase Storage.
* **Read Receipts & Delivery Indicators:** State tracking for message lifecycles: Sent (single check), Delivered (double check), and Seen (blue double checks).
* **Non-Destructive Chat Clears:** Timestamp-based chat cleaning allows local wipeout of message history without affecting the conversation logs of other participants.

### 📞 HD calling & Collaborative Screen Sharing
* **Agora RTC Engine:** Ultra-low latency voice and HD video streams configured through `agora_rtc_engine` (`agora_services.dart`).
* **Live Screen Sharing:** Real-time desktop/mobile screen casting during active video calls, managed via dedicated screen share controllers (`screen_share_session.dart`).
* **Native OS Integration:** Integrates `flutter_callkit_incoming` to process incoming data-only push notifications, invoking the native Android/iOS call screen (CallKit) even if the app is killed or sleeping.
* **Hardware Controls:** Multi-state microphone mute, camera flip, speakerphone toggle, call hold, and real-time call logs synchronized to cloud storage.

### 📸 Ephemeral Updates & Stories (WhatsApp-Style Status)
* **Interactive Media Statuses:** Rich text stories with 16 vibrant backgrounds or media uploads (photos & video clips up to 30 seconds).
* **Viewer Analytics:** Logs who has viewed your status with precise timestamps.
* **Direct Status Replies:** Interactive swiping on active statuses that routes text replies directly into the private, encrypted chat thread.
* **24-Hour Expiration:** Auto-expiring records managed through background database cleanups.

### 🎮 Gup Arcade & Gamification
* **In-Chat Casual Gaming:** Launch and play casual arcade games directly from chat rooms (`gup_arcade_screen.dart`).
* **User Progression Framework:** A gamified experience engine (`gamification_service.dart`) rewarding users with XP and unlockable profile badges for messaging, calling, and community interactions.
* **Interactive Leaderboards:** High-score leaderboards displaying rankings across contacts.

---

## 🔐 Cryptographic & Security Specification

GupShupGo implements a zero-trust cryptographic model designed to protect user data from local and network eavesdropping.

```
       [ALICE]                                                 [BOB]
          |                                                      |
    Generate Keys (IK, SPK, OPK)                           Download Alice's
    Publish PreKey Bundle to Cloud                        PreKey Bundle from Cloud
          |                                                      |
          | <-------------------------------------------- Perform X3DH (IK_B, EK_B)
          |                                                      |
    Perform X3DH (IK_A, SPK_A)                                   |
    Derive Shared Master Key                               Derive Shared Master Key
          |                                                      |
    Init Double Ratchet Chain                              Init Double Ratchet Chain
          |                                                      |
          | ===================================================> |
          |               Send E2EE Message                      |
          |               (AES-256-GCM + Ratchet)                |
```

### 🔑 Key Agreement & Ratcheting (Signal Protocol)
* **X3DH (Extended Triple Diffie-Hellman):** Performs initial key agreement to establish a shared master secret key between two parties who do not trust each other, supporting asynchronous communication.
* **Double Ratchet Algorithm:** Utilizes Diffie-Hellman ratcheting paired with symmetric KDF chains to generate new session keys for every single message. This guarantees:
  * **Forward Secrecy:** Compromising current keys does not expose past messages.
  * **Break-in Recovery (Post-compromise Security):** Compromising current keys does not allow attackers to decrypt future messages once normal ratcheting resumes.
* **Safety Numbers & QR Code Auditing:** Provides a cryptographic fingerprint based on concatenated identity keys, letting users verify their E2EE sessions in-person or via QR scanning.

### 🛡️ Secret Vault & Local Encryption Keys
* **Argon2id Key Derivation Function (KDF):** User PIN codes for the hidden chat vaults are processed using Argon2id (configured with memory-hard parameters) to derive the local database decryption keys.
* **AES-256-GCM Payload Encryption:** Local database caches and media files are encrypted using AES-256 in Galois/Counter Mode (GCM), providing authenticated encryption to prevent tampering.
* **Android Keystore / iOS Keychain:** Device session tokens and master cryptographic identity keys are stored using hardware-backed secure storage through `flutter_secure_storage`.

---

## 📡 Decentralized Mesh Protocol

In situations where internet or cellular backhaul is fully absent, GupShupGo deploys a peer-to-peer mesh networking layer using the Google Nearby Connections framework (`nearby_connections`).

```
  +--------------+  1. P2P Discover & Connect  +--------------+
  |   DEVICE A   |<===========================>|   DEVICE B   |
  |   (Alice)    |    (Bluetooth / Wi-Fi P2P)  |    (Bob)     |
  +-------+------+                             +-------+------+
          |                                            |
          | 2. Store offline messages                  | 2. Store offline messages
          v                                            v
  +--------------+                             +--------------+
  | Drift SQLite |                             | Drift SQLite |
  +-------+------+                             +-------+------+
          |                                            |
          | 3. Recover internet connectivity           | 3. Recover internet connectivity
          v                                            v
  +--------------+    4. Sync to cloud backend         +--------------+
  | Firebase API |====================================>| Firebase API |
  +--------------+                                     +--------------+
```

### 📡 Ad-Hoc Connectivity Mechanics
* **Dual-Radio Topology:** Operates simultaneously over Bluetooth Low Energy (BLE) for low-power discovery and Wi-Fi Direct / High-Bandwidth Wi-Fi for media and text routing.
* **Connection Lifecycle Manager:** Automates discovery, handshake verification, connection acceptance, and channel heartbeat monitoring (`mesh_network_service.dart`).
* **Automatic Queue Synchronization:** Offline message payloads generated in mesh mode are structured in localized tables and automatically synchronized to the cloud when internet access is restored.

---

## 💻 Technical Stack Specification

| Category | Technology | Packages / Dependency | Purpose |
| :--- | :--- | :--- | :--- |
| **Framework** | Flutter / Dart | `sdk: ">=3.2.0 <4.0.0"` | Client runtime engine |
| **State Engine** | Provider | `provider: ^6.1.1` | Decoupled state management |
| **E2E Cryptography**| Signal Protocol | `libsignal_protocol_dart: ^0.7.1` | X3DH key exchange & Double Ratchet |
| **KDF & Cryptography**| Crypto Suite | `cryptography: ^2.7.0`, `pointycastle` | Argon2id vault KDF, AES-256-GCM engine |
| **Local Database** | Drift SQLite | `drift: ^2.18.0`, `sqlite3_flutter_libs` | Reactive local database & cache |
| **Secure Storage** | OS Keystore | `flutter_secure_storage: ^9.2.2` | Persistent session token vault |
| **Real-Time Calling**| Agora RTC | `agora_rtc_engine: ^6.3.1` | Low-latency audio and HD video calls |
| **Native Calling UI**| CallKit | `flutter_callkit_incoming: ^2.5.2` | Native OS call screens |
| **P2P Mesh Network** | Nearby Conn | `nearby_connections: ^4.1.0` | Peer-to-peer offline chat routing |
| **Backend Suite** | Firebase | `firebase_core`, `cloud_firestore`, `firebase_storage` | Authentication, database & file storage |
| **Cloud Messages** | FCM & Functions | `firebase_messaging`, `firebase_functions` | Serverless notifications & data payloads |
| **App Security** | App Check | `firebase_app_check: ^0.2.1+8` | API call validation & fraud prevention |
| **Observability** | Telemetry | `firebase_crashlytics`, `firebase_performance` | Real-time crash logs and speed diagnostics |

---

## 📂 Workspace Organization

The project workspace strictly divides visual assets, local functions, client-side Dart files, and backend definitions:

```plaintext
gupshupgo/
├── android/                      # Native Android configuration, Manifests & Build Scripts
├── ios/                          # Native iOS workspace, Plists, Runner & Certificates
├── functions/                    # Node.js Serverless Cloud Functions (FCM signaling backend)
│   ├── index.js                  # Cloud messaging triggers (FCM call notifications)
│   └── package.json              # Firebase Admin & SDK requirements
├── lib/                          # Main Flutter application codebase
│   ├── main.dart                 # Application entry point, system initialization & FCM routing
│   ├── models/                   # Clean data models (User, Message, Status, CallLog)
│   ├── provider/                 # Reactive State Management providers (Status, Call, Theme)
│   ├── theme/                    # Material 3 typography, spacing & color configurations
│   ├── services/                 # Business logic, API communication & hardware handlers
│   │   ├── crypto/               # End-to-End Encryption & Secure Vault engine
│   │   │   ├── signal_service.dart         # Double Ratchet & X3DH key cycle handling
│   │   │   ├── vault_cipher.dart           # Argon2id database encryption utilities
│   │   │   ├── safety_number_service.dart  # QR verification fingerprint calculations
│   │   │   └── crypto_worker.dart          # Multi-threaded background Dart Isolate
│   │   ├── database/             # Drift SQLite database structure and Dao entities
│   │   ├── auth_service.dart     # Identity providers (Phone Hint, Google, Anonymous)
│   │   ├── chat_service.dart     # Messaging rules, read receipts, and storage sync
│   │   ├── mesh_network_service.dart       # Offline ad-hoc mesh routing system
│   │   ├── agora_services.dart            # Voice/Video engine initialization
│   │   └── screen_share_session.dart       # Screen cast and broadcast pipelines
│   └── screens/                  # Presentation layout screens (divided by domain)
│       ├── auth/                 # OTP verification, login screens, account linking
│       ├── chat_screen.dart      # Interactive conversation layout with waveforms
│       ├── call_screen.dart      # Real-time video calling controls & display
│       ├── mesh_chat_screen.dart # P2P Offline chat UI
│       ├── gup_arcade_screen.dart# Embedded gaming interface
│       └── vault_settings_screen.dart      # Secured chat PIN setup & vault settings
├── firestore.rules               # Firestore read/write security rules
├── storage.rules                 # Cloud Storage object-level permission rules
└── pubspec.yaml                  # Unified dependency file and asset declarations
```

---

## 🛠️ Infrastructure Setup & Installation

### 📋 Environment Requirements
* **Flutter SDK:** `>=3.2.0` (ensure `flutter doctor` passes successfully)
* **Android Tools:** SDK 34, Build Tools 34.0.0, and Android Studio
* **iOS Tools:** Xcode 15+, CocoaPods (if running on macOS)
* **Node.js Environment:** Version `>=18.10` (required for Firebase Cloud CLI functions)
* **Agora Account:** Valid Agora App ID and authorization token (for call services)

---

### 1️⃣ Clone & Dependency Installation
Download the workspace repository and trigger package retrieval:
```bash
git clone https://github.com/vansh-121/GupShupGo.git
cd GupShupGo/gupshupgo
flutter pub get
```

---

### 2️⃣ Firebase Configuration

#### Step A: Register Clients
1. Create a project inside the [Firebase Console](https://console.firebase.google.com).
2. Register your Android app package name (`com.gupshupgo.app`) and iOS bundle identifier.
3. Download and place client configuration files:
   * **Android:** Put `google-services.json` into `android/app/`.
   * **iOS:** Put `GoogleService-Info.plist` into `ios/Runner/`.

#### Step B: Activate Authentication & Databases
1. **Authentication:** Turn on **Phone Auth** (with OTP verification), **Google Sign-In**, and **Anonymous Login** (for testing guest mode).
2. **Cloud Firestore:** Enable Database in production mode.
3. **Firebase Storage:** Configure a media storage bucket in production.

#### Step C: Deploy Security Rules
Using the Firebase CLI, deploy rules from the workspace root to ensure data access restrictions:
```bash
# Log in and deploy
firebase login
firebase deploy --only firestore:rules
firebase deploy --only storage
```

#### Step D: Deploy Cloud Functions (Signaling Server)
Navigate to the serverless folder and deploy background handlers to FCM:
```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```
*This deploys `sendCallNotification` (data-only FCM call wakeups) and `sendMessageNotification` endpoints.*

---

### 3️⃣ Agora Service Configuration
1. Log into your account on the [Agora Developer Portal](https://console.agora.io).
2. Generate an **Agora App ID**.
3. Open `lib/services/agora_services.dart` and update the core connection string:
   ```dart
   // lib/services/agora_services.dart
   const String kAgoraAppId = 'YOUR_AGORA_APP_ID';
   ```

---

### 4️⃣ System Permissions Manifest Matrix

GupShupGo requires hardware accesses to run. The configuration files are pre-loaded with:

| Permission | Android Target | iOS Key | Purpose |
| :--- | :--- | :--- | :--- |
| **Camera** | `CAMERA` | `NSCameraUsageDescription` | Video calling & status media |
| **Microphone** | `RECORD_AUDIO` | `NSMicrophoneUsageDescription` | Voice calls & audio recording |
| **Network State** | `ACCESS_NETWORK_STATE` | Standard | Connection monitoring |
| **Bluetooth P2P** | `BLUETOOTH_ADVERTISE`, `BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN` | Standard | Bluetooth discovery for mesh |
| **Local Wi-Fi** | `NEARBY_WIFI_DEVICES` | Standard | High-speed Wi-Fi P2P mesh chat |
| **Fine Location** | `ACCESS_FINE_LOCATION` | `NSLocationWhenInUseUsageDescription` | Endpoint discovery for Nearby Connections |
| **Media Store** | `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO` | `NSPhotoLibraryUsageDescription` | Uploading photos/videos to chat/status |
| **Notifications**| `POST_NOTIFICATIONS` | Standard | Background notifications (Android 13+) |

---

### 5️⃣ Execution
Ensure a test device is connected (or launch an emulator instance) and build:
```bash
# Run local debug instance
flutter run

# Compile production Android APK
flutter build apk --release
```

---

## 🧪 Verification & Testing Procedures

### 📱 Scenario 1: Multi-Device E2EE Verification
1. Open GupShupGo on **Device A (Alice)** and **Device B (Bob)**.
2. Register both devices using different numbers, or select **Continue as Guest** for rapid sandbox verification.
3. On Device A, open contacts and start a conversation with Bob.
4. Verify the E2E lock symbol in the app bar. Tap on Bob's user profile to verify **Safety Numbers** or scan Bob's QR code.
5. Send messages and media, verifying real-time delivery and read states.

### 📡 Scenario 2: Off-Grid Mesh Networking Verification
1. Put both **Device A** and **Device B** in **Airplane Mode** (cellular and Wi-Fi networks disabled).
2. Turn on **Bluetooth** and **Local Wi-Fi** on both devices.
3. Open the sidebar navigation menu and select **🌐 Off-Grid Mesh Chat**.
4. Tap **Discover Peers** on both devices.
5. Accept the pairing invitation. Verify that text messages transmit directly between the devices without internet routing.
6. Disable Airplane Mode on either device, and verify that mesh messages synchronize to the cloud backend.

### 📞 Scenario 3: CallKit Lock-Screen Integration
1. Lock **Device B (Bob)** and completely swipe-close the GupShupGo application (ensuring the process is terminated).
2. From **Device A (Alice)**, initiate a Video Call.
3. Verify that Bob's device wakes up from suspension, displaying the full-screen native call receiver UI.
4. Answer the call, toggling video feeds, microphones, and speakers.
5. Tap **Share Screen** on Alice's device and confirm Bob can view the cast in real-time.

---

## ⚡ Performance Optimization & Diagnostics

GupShupGo is built to meet strict performance requirements:

* **Garbage Collection Preservation:** Stream controllers and animation controllers implement robust cleanup sequences inside `dispose()` methods, eliminating memory leaks in infinite scroll views.
* **Local Crypto Performance:** Cryptographic payloads are isolated inside a dedicated background worker (`crypto_worker.dart`), leaving the main Dart isolate free to render smooth transitions.
* **Network Payload Controls:** Video status clips are limited to 30 seconds, and images undergo a multi-pass compression algorithm to guarantee fast upload/download cycles.
* **Startup Initialization:** Shared Preferences and Firebase configurations initialize concurrently during the boot process (`main.dart`) to optimize cold start performance.

---

## 📈 Roadmap & Release Plan

### 🚀 Phase 1: Completed Features
* [x] **Signal Protocol Core integration:** Fully functional X3DH key exchanges and Double Ratchet pipelines.
* [x] **Ad-Hoc Mesh Chat Engine:** Decoupled peer-to-peer message routing via Bluetooth and Wi-Fi.
* [x] **Drift SQLite Caching:** Reactively bound local query caching.
* [x] **Agora Voice/Video Call integration:** Low latency voice/video streams and native CallKit screens.
* [x] **Argon2id PIN Vault:** Hidden chats stored behind memory-hard cryptographic keys.
* [x] **Carrier Hint integration:** Rapid user phone verification without manual SMS entry.

### 📅 Phase 2: Future Pipeline
* [ ] **E2EE Multi-Party Group Calling:** Extending the Double Ratchet protocol to support group calls.
* [ ] **IPFS Media Backing:** Decentralized media storage integrations using peer-to-peer storage pools.
* [ ] **Cross-Platform Desktop Apps:** Fully compiled native builds for macOS, Windows, and Linux.

---

## 🤝 Contribution & Compliance

We welcome contributions from developers, security auditors, and UX designers.

1. **Fork the Repository:** Create your workspace fork on GitHub.
2. **Setup a Feature Branch:** `git checkout -b feat/your-awesome-feature`.
3. **Commit Code Standards:** Ensure all additions match analysis options and formatting rules (`flutter format .`).
4. **Deploy Pull Requests:** Provide detailed verification steps, screenshot evidence for UI alterations, and test records.

### 📄 Licensing
This repository is licensed under the **MIT License**.  
*(Note: Building and distributing binaries linked with GPL-3.0 libraries like `libsignal_protocol_dart` implies compliance with copyleft specifications. Please review licensing requirements before deployment).*
