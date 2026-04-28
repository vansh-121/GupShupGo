# GupShupGo – Chat, Voice & Video Calling App

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Platform](https://img.shields.io/badge/platform-flutter-blue.svg)
![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)
[![Forks](https://img.shields.io/github/forks/vansh-121/GupShupGo.svg)](https://github.com/vansh-121/GupShupGo/network/members)
[![Issues](https://img.shields.io/github/issues/vansh-121/GupShupGo.svg)](https://github.com/vansh-121/GupShupGo/issues)
[![Made with Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?logo=flutter)](https://flutter.dev)

GupShupGo is a **production-ready Flutter communication app** inspired by WhatsApp, featuring real-time video/voice calling, messaging, status updates, and a full settings experience. Built with **Agora SDK** for high-quality video/audio, **Firebase** for backend infrastructure, **Cloud Functions** for secure server-side notification delivery, and **Flutter CallKit** for native call UI on Android/iOS.

---

## 📽️ Video Demo

▶️ [Full Video Demo](https://drive.google.com/file/d/1SiRGrnEmd6NfMtUpOwt14ZydMXcQpD0l/view?usp=drive_link)

▶️ [Background Call Architecture Demo](https://drive.google.com/file/d/1rzKF0wo0TkwQmZVnYHOweSIJxczKQAmL/view?usp=sharing)

---

## ✨ Core Features

### 📞 Video & Voice Calling
- 🎥 **HD video calling** with Agora RTC Engine
- 🎙️ **Audio-only voice calls** — lightweight, no camera required
- 🔊 Crystal-clear audio quality
- 📱 One-to-one real-time communication
- 🔔 **Push notifications** for incoming calls (even when app is closed)
- 📲 **Native CallKit call UI** — full-screen accept/decline like WhatsApp using `flutter_callkit_incoming`
- 💤 Background, terminated, and cold-start call support
- 🎛️ In-call controls: mute, video on/off, speaker, flip camera, hold
- ⏱️ Real-time call duration tracking (talk time only)
- 📋 **Call log history** — records caller, callee, duration, type (audio/video), and status (answered/missed/cancelled)

### 💬 Real-Time Messaging
- 📨 **Instant messaging** with typing indicators
- 📷 Send images, videos, and media files
- ✅ **Read receipts** (seen/delivered status)
- ⏰ Message timestamps
- 🗑️ Delete messages
- 💾 Message persistence with Firestore
- 🔄 Real-time sync across devices
- ⚡ **Instant chat list** on launch via local chat caching (`ChatCacheService`)

### 📸 WhatsApp-Style Status
- 📝 **Text status** with 16 colorful backgrounds
- 🖼️ **Image status** — Camera capture or gallery upload
- 🎬 **Video status** — Record or upload (max 30 seconds)
- ⏱️ **24-hour auto-expiry**
- 👁️ View count and viewer list
- ▶️ Full-screen viewer with progress bars
- 📊 Tap navigation and swipe gestures
- 🎨 Add captions to media statuses

### 🔐 Authentication & User Management
- 📱 **Phone authentication** with OTP verification
- 📲 **Carrier-based phone verification** (Phone Number Hint API — no SMS needed)
- 🔗 **Google Sign-In** — link or sign in with Google
- 👤 **Guest login** for quick testing
- 🔗 **Link multiple sign-in methods** (Phone, Google, Email) to one account
- 👥 Browse all registered users
- 🟢 **Real-time online/offline status**
- 🔍 **User search** functionality
- 👤 User profiles with editable name, about, and photo upload

### ⚙️ Settings & Privacy
- 🔔 **Notification controls** — toggle messages, groups, and call notifications
- 🙈 **Privacy settings** — last seen visibility, read receipt toggle
- 🚫 **Block/unblock users** — manage blocked contacts
- 🔇 **Mute chats** — per-chat notification muting
- 🗑️ **Clear all chats** — per-user timestamp-based clearing (non-destructive to other participants)
- 🐛 **Report a problem** — in-app email to support
- ❓ **Help Center** — in-app FAQ with expandable answers

### 👤 Profile Management
- 📸 **Profile photo** — upload from gallery with compression
- ✏️ **Edit name & about** — real-time Firestore + Firebase Auth sync
- 📱 View linked phone number and email
- 🔗 View linked sign-in providers (Phone, Google, Email)

### 🔄 In-App Updates
- 📲 **Google Play In-App Updates** — mandatory full-screen update flow
- ⚡ Automatic update detection via Play Store API
- 🔒 Users must update before continuing (immediate update type)
- 🔄 Flexible fallback for non-critical updates

### 🎨 Modern UI/UX
- 🎨 **Custom design system** — Poppins typography, purple-indigo brand palette
- 📑 Tab navigation (Chats, Status, Calls)
- ⚡ Smooth animations and transitions
- 📱 Responsive design for all screen sizes
- 🎯 Intuitive gesture controls
- 💫 Loading states and error handling
- 🌙 Material Design 3 throughout

---

## 🏗️ Architecture

### Tech Stack
```
Frontend:
  ├── Flutter / Dart (SDK ≥3.2.0)
  ├── Provider (State Management)
  ├── Material Design 3
  ├── Custom Design System (AppTheme / AppColors)
  ├── Google Fonts (Poppins — bundled locally)
  ├── Image Picker & Video Player
  ├── SharedPreferences (local caching & settings)
  └── Flutter CallKit Incoming (native call UI)

Backend:
  ├── Firebase Authentication (Phone, Google, Email, Anonymous)
  ├── Cloud Firestore (Database)
  ├── Firebase Storage (Media uploads)
  ├── Firebase Cloud Functions (secure FCM delivery)
  ├── Firebase Cloud Messaging (FCM — push notifications)
  ├── Firebase App Check (API security)
  ├── Agora RTC Engine (video/audio calling)
  └── Google Play In-App Updates

Cloud Functions (Node.js):
  ├── sendCallNotification  — data-only FCM for CallKit
  └── sendMessageNotification — FCM for chat messages

Architecture Pattern:
  ├── Clean Architecture
  ├── Service Layer Pattern
  ├── Provider Pattern
  └── Repository Pattern
```

### Project Structure
```plaintext
lib/
├── main.dart                           → App entry point, CallKit listener, cold-start handler
├── models/                             → Data models
│   ├── user_model.dart                → User data structure
│   ├── message_model.dart             → Chat message model
│   ├── status_model.dart              → Status data model
│   └── call_log_model.dart            → Call log (type, status, duration, media type)
├── services/                           → Business logic
│   ├── auth_service.dart              → Authentication (Phone, Google, Email, Guest)
│   ├── user_service.dart              → User profile management
│   ├── chat_service.dart              → Messaging & chat rooms
│   ├── chat_cache_service.dart        → Local chat list caching for instant UI
│   ├── status_service.dart            → Status CRUD
│   ├── fcm_service.dart               → Push notifications & incoming call handling
│   ├── agora_services.dart            → Agora RTC engine init, permissions, release
│   ├── call_log_service.dart          → Call log CRUD (Firestore)
│   ├── settings_service.dart          → Local settings persistence (SharedPreferences)
│   ├── update_service.dart            → Google Play In-App Updates
│   └── phone_verification_service.dart → Carrier-based phone verification (Phone Hint API)
├── provider/                           → State management
│   ├── status_provider.dart           → Status state
│   └── call_state_provider.dart       → Real-time call state (ringing/connected/ended)
├── screens/                            → UI pages
│   ├── auth/                          → Authentication screens
│   │   ├── login_screen.dart          → Main login (Phone, Google, Guest)
│   │   ├── phone_auth_screen.dart     → Phone OTP verification flow
│   │   └── link_accounts_screen.dart  → Link/unlink sign-in providers
│   ├── home_screen.dart               → Main tabbed interface (Chats, Status, Calls)
│   ├── chat_screen.dart               → Chat conversation with media attachments
│   ├── call_screen.dart               → Video/voice call UI with in-call controls
│   ├── incoming_call_screen.dart      → Incoming call UI (accept/decline)
│   ├── contacts_screen.dart           → User list / contacts
│   ├── profile_screen.dart            → Edit profile (name, about, photo)
│   ├── settings_screen.dart           → Settings (notifications, privacy, help, logout)
│   ├── add_text_status_screen.dart    → Create text status
│   ├── add_media_status_screen.dart   → Create image/video status
│   └── status_viewer_screen.dart      → Full-screen status viewer
└── theme/                              → Design system
    └── app_theme.dart                 → AppColors, AppTheme (Material 3)

functions/                              → Firebase Cloud Functions (Node.js)
├── index.js                           → sendCallNotification, sendMessageNotification
└── package.json                       → Dependencies (firebase-admin, firebase-functions)

firestore.rules                         → Firestore security rules
storage.rules                           → Firebase Storage security rules
privacy-policy.txt                      → App privacy policy
terms-of-service.txt                    → Terms of service
```

---

## 🎯 Key Highlights

### 🔥 WhatsApp Parity
- ✅ Chats with read receipts & delivery status
- ✅ HD video calling with Agora
- ✅ Voice/audio-only calling
- ✅ Native call UI (CallKit) — accept/decline from lock screen
- ✅ Background & cold-start call handling
- ✅ Call log history (Calls tab)
- ✅ Status updates (24h expiry)
- ✅ Online/offline indicators
- ✅ Typing indicators
- ✅ Push notifications (via Cloud Functions)
- ✅ Media sharing (images)
- ✅ Profile editing with photo upload
- ✅ Settings & privacy controls
- ✅ Block/unblock users
- ✅ Mute chat notifications

### 🚀 Production Ready
- ✅ Firebase security rules (Firestore + Storage)
- ✅ Server-side FCM via Cloud Functions (no service account in client)
- ✅ Firebase App Check for API security
- ✅ Google Play In-App Updates (mandatory update flow)
- ✅ Error handling & validation
- ✅ Offline support (Firestore cache + SharedPreferences)
- ✅ Image compression & optimization
- ✅ Video length limits (30s)
- ✅ Proper memory management
- ✅ Clean code architecture
- ✅ Privacy policy & terms of service included

### 📈 Scalable Infrastructure
- ✅ Support for unlimited users
- ✅ Real-time data synchronization
- ✅ Automatic expired content cleanup
- ✅ Firestore cost optimization
- ✅ Firebase Storage integration
- ✅ Efficient query patterns
- ✅ Per-user chat clearing (non-destructive)

---

## 🛠️ Setup Instructions

### Prerequisites
- Flutter SDK (≥3.2.0)
- Android Studio / Xcode
- Firebase account
- Agora account
- Node.js (for Cloud Functions deployment)

### 1. Clone Repository
```bash
git clone https://github.com/vansh-121/GupShupGo.git
cd GupShupGo/gupshupgo
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup

#### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project
3. Add Android and iOS apps
4. Download configuration files:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`

#### Enable Firebase Services
1. **Authentication**
   - Enable Phone authentication
   - Enable Anonymous sign-in (for guest mode)
   - Enable Google sign-in
   - Enable Email/Password sign-in

2. **Firestore Database**
   - Create database in production mode
   - Deploy security rules from `firestore.rules`
   ```bash
   firebase deploy --only firestore:rules
   ```
   Or manually copy from `firestore.rules` in Console

3. **Firebase Storage**
   - Go to Storage → Get Started
   - Deploy security rules from `storage.rules`
   ```bash
   firebase deploy --only storage
   ```
   Or manually paste rules in Firebase Console

4. **Cloud Messaging (FCM)**
   - Automatically enabled with Firebase
   - No additional setup needed

5. **App Check** (recommended)
   - Enable in Firebase Console → App Check
   - Use Play Integrity for production, Debug provider for development
   - Add debug tokens from console logs during development

#### Deploy Cloud Functions
The app uses **Firebase Cloud Functions** for secure server-side FCM delivery (no service account bundled in the client).

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

This deploys two HTTP endpoints:
- `sendCallNotification` — data-only FCM for native CallKit call UI
- `sendMessageNotification` — FCM for chat message notifications

### 4. Agora Setup
1. Sign up at [agora.io](https://www.agora.io/)
2. Create a new project
3. Get your **App ID**
4. (Optional) Set up token server for secure channels
5. Update configuration in `lib/services/agora_services.dart`:
   ```dart
   // lib/services/agora_services.dart
   appId: 'YOUR_AGORA_APP_ID', // Replace with your Agora App ID
   ```

### 5. Required Permissions

The app requires these permissions (already configured in `AndroidManifest.xml`):

| Permission | Purpose |
|------------|---------|
| `INTERNET` | Network access for Firebase & Agora |
| `CAMERA` | Camera access for video calls & status |
| `RECORD_AUDIO` | Microphone for voice calls |
| `READ_EXTERNAL_STORAGE` | Access gallery for images |
| `WRITE_EXTERNAL_STORAGE` | Save media files |
| `POST_NOTIFICATIONS` | Show incoming call notifications (Android 13+) |
| `FOREGROUND_SERVICE` | Background call handling |
| `WAKE_LOCK` | Keep device awake during calls |

### 6. Run the App
```bash
# For Android
flutter run

# For iOS
flutter run -d ios
```

---

## 🧪 Testing Guide

### Testing with 2 Devices

#### Device 1 (Alice)
1. Open app → Select "Continue as Guest"
2. Enter name: "Alice"
3. Main screen shows 3 tabs: Chats, Status, Calls

#### Device 2 (Bob)
1. Open app → Select "Continue as Guest"
2. Enter name: "Bob"
3. Both users should now see each other in contacts

### Test Messaging
1. **Alice:** Tap search icon → Select "Bob" → Start chatting
2. **Bob:** Receives real-time messages
3. Test: Send text, images, read receipts

### Test Video Calling
1. **Alice:** Tap search icon → Tap video icon next to Bob's name
2. **Bob:** Receives push notification → **Native CallKit call UI appears** → Tap accept
3. Both devices show live video streams
4. Test: Mute, video toggle, hold, end call
5. Check Calls tab on both devices for the call log entry

### Test Voice Calling
1. **Alice:** Tap search icon → Tap phone icon next to Bob's name
2. **Bob:** Receives push notification → **Native CallKit call UI appears** → Tap accept
3. Audio-only call connects (no video UI)
4. Test: Mute, speaker toggle, hold, end call

### Test Status Feature
1. **Alice:** Go to Status tab → Tap camera FAB
2. Select "Gallery Photo" or "Take Photo"
3. Add caption → Send
4. **Bob:** Status tab shows Alice's status in "Recent updates"
5. **Bob:** Tap to view full-screen
6. Test: Text status, video status, navigation, viewer list

### Test Settings
1. Open **⚙ Settings** from the menu
2. Test: Profile editing, notification toggles, privacy toggles
3. Test: Block a user, clear all chats, report a problem

---

## 🔒 Security & Privacy

### Firestore Security Rules
- Users can only edit their own profile
- Read access requires authentication
- Chat messages protected by participant rules (with legacy chatRoomId fallback)
- Status uploads restricted to owner's folder
- Call records limited to caller/callee
- Call logs limited to participants
- Chat room deletion is disabled (data preservation)

### Firebase Storage Rules
- Max file size: 30 MB
- Only authenticated users can upload
- Users can only write to their own folders
- Media types restricted to images/videos
- Everything outside status folders is denied by default

### Cloud Functions Security
- All Cloud Function endpoints validate Firebase Auth ID tokens
- FCM tokens are never exposed to client-side code
- No service account files bundled in the app

### Firebase App Check
- Play Integrity (production) / Debug provider (development)
- Prevents unauthorized API access
- Runs in background — never blocks app startup

### Best Practices Implemented
- ✅ No sensitive data in client code (service account removed)
- ✅ Server-side FCM delivery via Cloud Functions
- ✅ Firebase Auth token validation on all endpoints
- ✅ User data isolation via security rules
- ✅ Automatic permission handling
- ✅ Input sanitization
- ✅ Per-user data operations (clear chats doesn't affect others)

---

## 📊 Performance Optimizations

- **Image Compression**: Max 1920x1920px, 80% quality
- **Video Limits**: 30-second max recording
- **Lazy Loading**: Only active statuses (last 24h)
- **Firestore Indexing**: Optimized queries
- **Caching**: Offline data persistence via Firestore cache + SharedPreferences
- **Chat List Caching**: `ChatCacheService` renders chat list instantly on launch
- **Memory Management**: Proper disposal of controllers and streams
- **Font Bundling**: Poppins loaded locally (no runtime network fetch)
- **Parallel Init**: Firebase and SharedPreferences initialized concurrently

---

## 🐛 Troubleshooting

### Common Issues

**1. Firebase Connection Error**
```
Solution: Verify google-services.json / GoogleService-Info.plist are in correct folders
```

**2. Push Notifications Not Working**
```
Solution: 
- Ensure Cloud Functions are deployed: `firebase deploy --only functions`
- Check FCM is enabled in Firebase Console
- Verify POST_NOTIFICATIONS permission for Android 13+
- Test on real device (not emulator)
```

**3. Agora Video Not Showing**
```
Solution:
- Verify App ID is correct
- Check CAMERA and RECORD_AUDIO permissions
- Test on physical device (emulators may have issues)
```

**4. Status Upload Fails**
```
Solution:
- Deploy Firebase Storage security rules
- Check internet connection
- Verify file size < 30 MB
```

**5. In-App Update Not Working**
```
Solution:
- This only works when installed from Google Play
- ERROR_API_NOT_AVAILABLE is expected in debug/local installs
- Use Google Play internal testing track for testing
```

**6. CallKit Notification Not Showing**
```
Solution:
- Cloud Functions must be deployed
- Call notifications use data-only FCM (no notification block)
- Test on a real device with the app fully killed
```

**7. Build Errors**
```bash
flutter clean
flutter pub get
flutter run
```

---

## 🚀 Deployment

### Android Release
```bash
flutter build apk --release
# Or for app bundle
flutter build appbundle --release
```

### iOS Release
```bash
flutter build ios --release
```

### Pre-Release Checklist
- [ ] Firebase security rules deployed (Firestore + Storage)
- [ ] Cloud Functions deployed (`firebase deploy --only functions`)
- [ ] Agora App ID configured
- [ ] Google Services files added
- [ ] App Check enabled in Firebase Console
- [ ] Permissions declared in manifests
- [ ] Test on real devices (2+)
- [ ] Verify push notifications work (calls + messages)
- [ ] Test all core features (chat, call, status, settings)
- [ ] Verify in-app update flow (via Play internal testing)
- [ ] Performance profiling done
- [ ] App icons & splash screen set
- [ ] Privacy policy & terms of service accessible

---

## 💡 Future Enhancements

### Potential Features
- [ ] Group chats
- [ ] Group video calls
- [ ] End-to-end encryption
- [ ] Voice messages
- [ ] GIF support
- [ ] Contact sync (phone contacts)
- [ ] Dark mode
- [ ] Status replies
- [ ] Message search
- [ ] Chat backup/restore
- [x] ~~Call history~~ (implemented — call logs with duration, type & status)
- [x] ~~Profile pictures~~ (implemented — upload from gallery, Firebase Storage)
- [x] ~~Custom themes~~ (implemented — brand design system with Poppins + purple-indigo palette)
- [x] ~~Block/report users~~ (implemented — block list management + email support)

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📬 Contact & Support

**Developer:** Vansh Sethi  
**GitHub:** [@vansh-121](https://github.com/vansh-121)  
**Repository:** [GupShupGo](https://github.com/vansh-121/GupShupGo)

### Getting Help
- 📝 Open an [Issue](https://github.com/vansh-121/GupShupGo/issues)
- 💬 Start a [Discussion](https://github.com/vansh-121/GupShupGo/discussions)
- ⭐ Star this repo if you find it useful!

---

## 🙏 Acknowledgements

- [Flutter Team](https://flutter.dev) — Amazing framework
- [Firebase](https://firebase.google.com) — Backend infrastructure
- [Agora](https://www.agora.io) — Real-time video/audio SDK
- [Flutter CallKit Incoming](https://pub.dev/packages/flutter_callkit_incoming) — Native call UI
- WhatsApp — Design inspiration

---

<div align="center">

**Built with ❤️ by Vansh Sethi**

If this project helped you, consider giving it a ⭐!

</div>
