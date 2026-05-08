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
