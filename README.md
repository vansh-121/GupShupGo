# 📞 GupShupGo – Real-Time Messaging & Video Calling App

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Platform](https://img.shields.io/badge/platform-flutter-blue.svg)
![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)
[![Forks](https://img.shields.io/github/forks/vansh-121/GupShupGo.svg)](https://github.com/vansh-121/GupShupGo/network/members)
[![Issues](https://img.shields.io/github/issues/vansh-121/GupShupGo.svg)](https://github.com/vansh-121/GupShupGo/issues)
[![Made with Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?logo=flutter)](https://flutter.dev)

GupShupGo is a **production-ready Flutter communication app** inspired by WhatsApp, featuring real-time video calling, messaging, and status updates. Built with **Agora SDK** for high-quality video/audio and **Firebase** for backend infrastructure, it delivers a complete social communication experience.

---

## 📽️ Video Demo

▶️ [Full Video Demo](https://drive.google.com/file/d/1SiRGrnEmd6NfMtUpOwt14ZydMXcQpD0l/view?usp=drive_link)

▶️ [Background Call Architecture Demo](https://drive.google.com/file/d/1rzKF0wo0TkwQmZVnYHOweSIJxczKQAmL/view?usp=sharing)

---

## ✨ Core Features

### 📞 Video & Audio Calling
- 🎥 **HD video calling** with Agora RTC Engine
- 🔊 Crystal-clear audio quality
- 📱 One-to-one real-time communication
- 🔔 **Push notifications** for incoming calls (even when app is closed)
- 💤 Background and terminated app call support
- 🎛️ In-call controls: mute, video on/off, speaker, flip camera
- ⏱️ Real-time call duration tracking

### 💬 Real-Time Messaging
- 📨 **Instant messaging** with typing indicators
- 📷 Send images, videos, and media files
- ✅ **Read receipts** (seen/delivered status)
- ⏰ Message timestamps
- 🗑️ Delete messages
- 💾 Message persistence with Firestore
- 🔄 Real-time sync across devices

### 📸 WhatsApp-Style Status
- 📝 **Text status** with 16 colorful backgrounds
- 🖼️ **Image status** - Camera capture or gallery upload
- 🎬 **Video status** - Record or upload (max 30 seconds)
- ⏱️ **24-hour auto-expiry** 
- 👁️ View count and viewer list
- ▶️ Full-screen viewer with progress bars
- 📊 Tap navigation and swipe gestures
- 🎨 Add captions to media statuses

### 🔐 Authentication & User Management
- 📱 **Phone authentication** with OTP verification
- 👤 **Guest login** for quick testing
- 👥 Browse all registered users
- 🟢 **Real-time online/offline status**
- 🔍 **User search** functionality
- 👤 User profiles with photos
- 📞 Contact list with online indicators

### 🎨 Modern UI/UX
- 🌓 Clean Material Design interface
- 📑 Tab navigation (Chats, Status, Calls)
- ⚡ Smooth animations and transitions
- 📱 Responsive design for all screen sizes
- 🎯 Intuitive gesture controls
- 💫 Loading states and error handling

---

## 🏗️ Architecture

### Tech Stack
```
Frontend:
  ├── Flutter/Dart
  ├── Provider (State Management)
  ├── Material Design 3
  ├── Image Picker
  ├── Video Player
  └── Google Fonts

Backend:
  ├── Firebase Authentication
  ├── Cloud Firestore (Database)
  ├── Firebase Storage (Media)
  ├── Cloud Messaging (FCM)
  └── Agora RTC Engine

Architecture Pattern:
  ├── Clean Architecture
  ├── Service Layer Pattern
  ├── Provider Pattern
  └── Repository Pattern
```

### Project Structure
```plaintext
lib/
├── models/                    → Data models
│   ├── user_model.dart       → User data structure
│   ├── message_model.dart    → Chat message model
│   └── status_model.dart     → Status data model
├── services/                  → Business logic
│   ├── auth_service.dart     → Authentication
│   ├── user_service.dart     → User management
│   ├── chat_service.dart     → Messaging
│   ├── status_service.dart   → Status CRUD
│   └── fcm_service.dart      → Push notifications
├── provider/                  → State management
│   └── status_provider.dart  → Status state
├── screens/                   → UI pages
│   ├── auth/                 → Login screens
│   ├── home_screen.dart      → Main tabbed interface
│   ├── chat_screen.dart      → Chat conversation
│   ├── call_screen.dart      → Video call UI
│   ├── contacts_screen.dart  → User list
│   ├── add_text_status_screen.dart
│   ├── add_media_status_screen.dart
│   └── status_viewer_screen.dart
└── main.dart                  → App entry point
```

---

## 🎯 Key Highlights

### 🔥 WhatsApp Parity
- ✅ Chats with read receipts
- ✅ Video/voice calling
- ✅ Status updates (24h expiry)
- ✅ Online/offline indicators
- ✅ Typing indicators
- ✅ Push notifications
- ✅ Media sharing

### 🚀 Production Ready
- ✅ Firebase security rules configured
- ✅ Error handling & validation
- ✅ Offline support (Firestore cache)
- ✅ Image compression & optimization
- ✅ Video length limits (30s)
- ✅ Proper memory management
- ✅ Clean code architecture

### 📈 Scalable Infrastructure
- ✅ Support for unlimited users
- ✅ Real-time data synchronization
- ✅ Automatic expired content cleanup
- ✅ Firestore cost optimization
- ✅ Firebase Storage integration
- ✅ Efficient query patterns

---

## 🛠️ Setup Instructions

### Prerequisites
- Flutter SDK (^3.5.3)
- Android Studio / Xcode
- Firebase account
- Agora account

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

### 4. Agora Setup
1. Sign up at [agora.io](https://www.agora.io/)
2. Create a new project
3. Get your **App ID**
4. (Optional) Set up token server for secure channels
5. Update configuration:
   ```dart
   // lib/utils/agora_config.dart
   const String appId = "YOUR_AGORA_APP_ID";
   const String token = ""; // Leave empty if not using token
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
2. **Bob:** Receives push notification → Call screen opens
3. Both devices show live video streams
4. Test: Mute, video toggle, end call

### Test Status Feature
1. **Alice:** Go to Status tab → Tap camera FAB
2. Select "Gallery Photo" or "Take Photo"
3. Add caption → Send
4. **Bob:** Status tab shows Alice's status in "Recent updates"
5. **Bob:** Tap to view full-screen
6. Test: Text status, video status, navigation, viewer list

---

## 🔒 Security & Privacy

### Firestore Security Rules
- Users can only edit their own profile
- Read access requires authentication
- Chat messages protected by participant rules
- Status uploads restricted to owner's folder

### Firebase Storage Rules
- Max file size: 30 MB
- Only authenticated users can upload
- Users can only write to their own folders
- Media types restricted to images/videos

### Best Practices Implemented
- ✅ No sensitive data in client code
- ✅ Server-side validation via Firebase rules
- ✅ Secure token management
- ✅ User data isolation
- ✅ Automatic permission handling
- ✅ Input sanitization

---

## 📊 Performance Optimizations

- **Image Compression**: Max 1920x1920px, 80% quality
- **Video Limits**: 30-second max recording
- **Lazy Loading**: Only active statuses (last 24h)
- **Firestore Indexing**: Optimized queries
- **Caching**: Offline data persistence
- **Memory Management**: Proper disposal of controllers

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

**5. Build Errors**
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📚 Documentation

### Detailed Guides
- **[QUICK_START.md](QUICK_START.md)** - Get running in 5 minutes
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System design & data flow diagrams
- **[FIRESTORE_SETUP.md](FIRESTORE_SETUP.md)** - Database configuration & rules
- **[DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)** - Pre-launch checklist
- **[IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)** - Technical deep-dive
- **[SUMMARY.md](SUMMARY.md)** - Feature summary & changelog

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
- [ ] Agora App ID configured
- [ ] Google Services files added
- [ ] Permissions declared in manifests
- [ ] Test on real devices (2+)
- [ ] Verify push notifications work
- [ ] Test all core features (chat, call, status)
- [ ] Performance profiling done
- [ ] App icons & splash screen set

---

## 💡 Future Enhancements

### Potential Features
- [ ] Group video calls
- [ ] End-to-end encryption
- [ ] Voice messages
- [ ] GIF support
- [ ] Contact sync
- [ ] Profile pictures
- [ ] Custom themes
- [ ] Block/report users
- [ ] Status replies
- [ ] Call history
- [ ] Message search
- [ ] Chat backup/restore

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

- [Flutter Team](https://flutter.dev) - Amazing framework
- [Firebase](https://firebase.google.com) - Backend infrastructure
- [Agora](https://www.agora.io) - Real-time video/audio SDK
- WhatsApp - Design inspiration

---

<div align="center">

**Built with ❤️ by Vansh Sethi**

If this project helped you, consider giving it a ⭐!

</div>
