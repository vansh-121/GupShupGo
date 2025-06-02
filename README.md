# 📞 GupShupGo – 1:1 Video Calling with Friends

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Platform](https://img.shields.io/badge/platform-flutter-blue.svg)
![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)
[![Forks](https://img.shields.io/github/forks/vansh-121/GupShupGo.svg)](https://github.com/vansh-121/GupShupGo/network/members)
[![Issues](https://img.shields.io/github/issues/vansh-121/GupShupGo.svg)](https://github.com/vansh-121/GupShupGo/issues)
[![Made with Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?logo=flutter)](https://flutter.dev)

GupShupGo is a modern Flutter-based video calling app that leverages **Agora SDK** for low-latency real-time communication and **Firebase Cloud Messaging (FCM)** for push notifications—even when the app is running in the background or is completely closed. It allows seamless, private video calls with smart call handling.

---

## 📽️ Video Demo

▶️ **Video Call using Device A and Device B:** 

https://github.com/user-attachments/assets/e4f4f005-3ce5-4afa-a6cf-6ddd3dce5b09

> **Tip** : Unmute sound for voice instructions & userguide. 

---

▶️ **Background Call using Firebase Cloud Messaging**

https://github.com/user-attachments/assets/ac001810-0c6f-4f1d-bb83-8cd345dcd267

> **Tip** : Unmute sound for voice instructions & userguide. 

---

## ✨ Features

- 🔗 One-to-one real-time video calling with **Agora**
- 🔔 Push notifications using **FCM**
- 💤 Supports background and terminated call notifications
- 🔐 Firebase Authentication for secure login
- 👥 User list for initiating calls
- 🚀 Fast and responsive Flutter UI
- 📱 Supports Android & iOS devices

---

## 🧪 How to Test With Two Users

You can easily test GupShupGo using:

### ✅ 1. Two Physical Devices
- Sign in with two different accounts.
- From one device, tap on the user in the list and initiate a call.
- The second device receives a push notification and joins the call.

### ✅ 2. Emulator + Physical Device
- Run one instance on your emulator and one on your phone.
- Login with different users and follow the same steps.

> 📌 Note: Push notifications on emulators (especially iOS) might not be reliable. Prefer using real devices for testing FCM features.

---

## 🧠 Background Call Handling Logic

GupShupGo ensures seamless calling even when the app is closed or minimized using a combination of:

### 🔄 Workflow:

1. User A initiates a call → triggers Firestore entry + FCM push.
2. User B receives the push via a **background handler**.
3. A **local notification** is shown with options to accept/decline.
4. If accepted, the app wakes and joins the Agora channel instantly.
5. If ignored, a timeout cancels the call and removes metadata.

### ✅ Reliable in:
- App running in background
- App fully terminated
- Device locked

---

## 📁 Project Structure

```plaintext
lib/
├── auth/               → Login & register flows
├── screens/            → UI pages (Home, Call, Incoming)
├── services/           → Firebase, Agora, Notification logic
├── utils/              → Constants, theme, helpers
├── models/             → Data classes (User, Call, etc.)
└── main.dart           → App entry point
```

---

## 📦 Agora and FCM Configuration

### 🔧 Agora Setup
- Sign up at [agora.io](https://www.agora.io/)
- Create a project and obtain the **App ID**
- Optional: Setup token generation if using secured channels
- Update the file:
  ```dart
  // lib/utils/agora_config.dart
  const appId = "YOUR_AGORA_APP_ID";
  const token = "YOUR_TEMP_TOKEN"; // Leave empty if not using token
  ```

---


## 🛠️ Setup Instructions

1. **Clone the repo**
   ```bash
   git clone https://github.com/vansh-121/GupShupGo.git
   cd GupShupGo
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```
3. **Create Firebase project**

  - Add Android and iOS apps in Firebase Console.

  - Download google-services.json (Android) and GoogleService-Info.plist (iOS) to the correct platform folders.
    
4. **Agora Setup**
  
  - Create a Agora.io account.

  - Generate a temporary App ID and Token (or use your own token generation server).

  - Add your App ID in lib/utils/agora_config.dart.
  
5. **Add these permissions in AndroidManifest.xml** 

GupShupGo requests the following permissions to ensure a smooth and secure video calling experience:

| Permission              | Platform     | Purpose                                      |
|-------------------------|--------------|----------------------------------------------|
| `INTERNET`              | Android/iOS  | Required for network access (Firebase, Agora) |
| `CAMERA`                | Android/iOS  | To access the camera for video calling        |
| `RECORD_AUDIO`          | Android/iOS  | To use the microphone during calls            |
| `POST_NOTIFICATIONS`    | Android 13+  | To show incoming call notifications           |
| `FOREGROUND_SERVICE`    | Android      | Enables persistent call services in background |
| `WAKE_LOCK`             | Android      | Keeps the device awake during active calls    |
| `RECEIVE_BOOT_COMPLETED`| Android      | *(Optional)* Restarts services after reboot   |


> ⚠️ Be sure to request runtime permissions where required (especially for `CAMERA`, `RECORD_AUDIO`, and `POST_NOTIFICATIONS` on Android 13+).


6. **Run on device**
```bash
flutter run
```

---

## 📬 Contact

Built with ❤️ by **Vansh Sethi**.

Have questions? Open an issue or ping me on GitHub!
