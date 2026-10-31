<p align="center">
  <img src="assets/icon/email_logo_color.png" width="320" alt="GupShupGo Wordmark Logo">
</p>

# <div align="center">GupShupGo : Next-Gen Private Messenger & RTC Platform</div>

<div align="center">

**The Next-Generation, Offline-Capable, Zero-Knowledge Encrypted Messenger, Real-Time Calling Engine & Arcade.**

[![Release: 1.2.3](https://img.shields.io/badge/Release-v1.2.3_(Build_61)-blue.svg?style=flat-square)](CHANGELOG.md)
[![Privacy: Zero-Knowledge](https://img.shields.io/badge/Privacy-Zero--Knowledge-10B981.svg?style=flat-square)](PRIVACY.md)
[![Encryption: Signal Protocol](https://img.shields.io/badge/Encryption-Signal%20Protocol-0284C7.svg?style=flat-square)](PRIVACY.md#3-cryptographic-specification)
[![Offline: P2P Mesh](https://img.shields.io/badge/Offline-P2P%20Mesh-F59E0B.svg?style=flat-square)](PRIVACY.md#5-decentralized-offline-mesh-protocol)
[![Languages: 16 Supported](https://img.shields.io/badge/Languages-16%20Global-8B5CF6.svg?style=flat-square)](CHANGELOG.md#122---2026-10-24)
[![Google Play](https://img.shields.io/badge/Google_Play-Available_Now-00875F?style=flat-square&logo=google-play&logoColor=white)](https://play.google.com/store/apps/details?id=com.gupshupgo.app)

[📲 Google Play](https://play.google.com/store/apps/details?id=com.gupshupgo.app) • [🌐 Official Website](https://www.gupshupgo.app) • [🔐 Privacy Whitepaper](PRIVACY.md) • [🧪 Verification Guide](VERIFICATION.md) • [🛡️ Security Policy](SECURITY.md) • [❓ FAQ](FAQ.md) • [📝 Changelog](CHANGELOG.md)

<br>
<img src="assets/images/gupshupgo_portfolio_cover_1783416921910.png" width="900" alt="GupShupGo Hero Graphic">

</div>

---

## 🏢 About This Repository

Welcome to the official public repository, transparency center, and issue tracker for **GupShupGo**.

GupShupGo is developed by **VANSHORA LABS** as a production-grade, enterprise-ready real-time communication platform built on Flutter and Google Cloud. While the primary application binary and backend services are maintained privately to safeguard platform infrastructure, **we firmly believe that private communication requires verifiable transparency**.

This public repository serves as the community reference for:
* **Cryptographic & Privacy Specifications:** Rigorous mathematical models of our Signal Protocol (X3DH + Double Ratchet) and Argon2id implementations.
* **Offline Mesh Architecture:** Disclosures on dual-radio Bluetooth Low Energy and Wi-Fi Direct ad-hoc store-and-forward mesh routing.
* **Independent Auditing Guidelines:** Step-by-step procedures for security researchers to verify ciphertext payloads, safety numbers, and local SQLite database encryption.
* **Public Feedback & Tracking:** Issue reporting, feature requests, and coordinated security vulnerability disclosures.
* **Official Release History:** Complete changelog of production updates shipped to Google Play.

---

## 📲 Download GupShupGo

<div align="center">

[![Get it on Google Play](https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png)](https://play.google.com/store/apps/details?id=com.gupshupgo.app)

**Available now for Android on the Google Play Store!**  
*Direct Package: `com.gupshupgo.app`*  
*Download Link: [play.google.com/store/apps/details?id=com.gupshupgo.app](https://play.google.com/store/apps/details?id=com.gupshupgo.app)*

</div>

---

## ✨ Exact Shipped Feature Set

GupShupGo ships with 23 core capabilities across 6 functional categories:

### 1. 💬 Messaging & Media
* **Real-Time Messaging:** Instant 1-on-1 messaging with delivery and read receipts, swipe-to-reply, status message replies, and live typing indicators.
* **Send Any File & Document:** Share documents, PDFs, audio recordings, and media from the attachment sheet with end-to-end encryption.
* **In-Chat & Offline Message Search:** Search your entire on-device chat history instantly with zero server roundtrips.
* **Location Sharing:** Drop precise location pins with coordinate inspection before transmission, compatible with any installed mapping application.
* **Rich Link Previews:** Client-generated link preview cards that never ping target websites from chat viewing threads.
* **Gup AI In-Chat Assistant:** An intelligent assistant residing in its own isolated thread, powered by Groq LLM pipelines for translation, summarization, and query assistance without indexing personal chats.

### 2. 🔐 Privacy & Cryptography
* **End-to-End Encryption (Signal Protocol):** Default asynchronous Double Ratchet and X3DH key agreement. Cryptographic operations run on dedicated Dart background isolates (`crypto_worker.dart`) to keep animations fluid.
* **Secret Vault:** Protect sensitive chats behind a dedicated Argon2id memory-hard PIN or biometric fingerprint inside an isolated encrypted database.
* **View-Once Media:** Self-destructing photos and videos with cryptographic key shredding and Android OS `FLAG_SECURE` screenshot blocking.
* **Safety Number Verification:** Out-of-band QR code scanning and 60-digit cryptographic fingerprint comparison to verify contact authenticity.

### 3. 📞 Calling & Real-Time RTC
* **Native Lock-Screen Incoming Calls (v1.2.3):** Full-Screen Intent activities on Android and native CallKit on iOS. Ring, answer, or decline calls directly from the system lock screen even when terminated or cold-started.
* **HD Voice & Video Calls:** Ultra-low-latency peer calling powered by the Agora RTC engine with pre-warmed audio/video media pipelines.
* **Call History & Logs:** Unified incoming, outgoing, and missed call records.
* **Live Screen Sharing:** In-call high-definition screen sharing with dedicated presenter and viewer layouts.

### 4. 📡 Off-Grid Connectivity
* **Offline Nearby P2P Mesh:** Send messages and files peer-to-peer over Bluetooth Low Energy and Wi-Fi Direct without cell coverage, internet access, or central servers, with automatic cloud sync upon reconnection.

### 5. 🎮 Social, Casual Gaming & Profiles
* **Status Updates (Moments):** 24-hour self-healing encrypted ephemeral text and media stories.
* **Gup Arcade & Chat Streaks:** Earn Gup Points, complete daily challenges, climb the leaderboard, and preserve chat streaks ("Bonds") with streak restore.
* **Anonymous Chat:** Match in a private lobby and chat under randomized pseudonyms with tap-to-reveal blurred photo, video, and audio messaging.
* **QR Contact Adding:** Add friends instantly by scanning personalized in-app QR codes.
* **Public Profiles & Deep Links:** Share profile cards (`https://gupshupgo.app/u/<handle>`) displaying badges, Gup Points, and verified handles.
* **Contacts & Privacy Management:** Manage friend requests, address book discovery, and block lists.

### 6. ⚙️ Account, Personalization & System
* **Phone Number Sign-In:** Frictionless phone OTP verification with multi-device session management.
* **Notifications & Presence:** Granular controls over push alerts, online presence indicators, and last-seen timestamps.
* **Theming & Personalization:** System-adaptive light and dark themes with per-conversation custom bubble colors and chat backgrounds.
* **16-Language Internationalization:** Full native localization for English, Hindi, Spanish, Arabic, French, Portuguese, Bengali, Russian, Indonesian, German, Japanese, Chinese Simplified, Urdu, Turkish, Tamil, and Telugu.
* **GupShupGo Pro & Monetization:** Google Play Billing integration (`in_app_purchase`) supporting monthly/yearly tiers, paired with lightweight, privacy-isolated Google AdMob banner units.

---

## ⚔️ Feature Parity Matrix

| Capability / Feature | GupShupGo 🚀 | WhatsApp 🟢 | Signal 🔵 | Telegram ✈️ | Discord 🎮 |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Signal Protocol E2EE by Default** | ✅ **Yes (X3DH + Ratchet)** | ✅ Yes | ✅ Yes | ❌ No (Secret Chats only) | ❌ No |
| **Off-Grid P2P Mesh Networking** | ✅ **Yes (Bluetooth / Wi-Fi Direct)** | ❌ No | ❌ No | ❌ No | ❌ No |
| **Native Lock-Screen Incoming Calls** | ✅ **Yes (Full-Screen Intent + CallKit)** | ✅ Yes | ✅ Yes | ✅ Yes | ⚠️ Partial |
| **HD Voice & Video Calls** | ✅ **Yes (Agora Low-Latency RTC)**| ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| **In-Call Live Screen Sharing** | ✅ **Yes (HD Real-Time)** | ✅ Yes | ❌ No | ✅ Yes | ✅ Yes |
| **Secret PIN Vault (Argon2id KDF)** | ✅ **Yes (Encrypted SQLite Store)**| ⚠️ Basic Lock | ❌ No | ⚠️ Passcode Lock | ❌ No |
| **View-Once Media with Key Erasure** | ✅ **Yes (Cryptographic Shredding)**| ✅ Yes | ✅ Yes | ✅ Yes | ❌ No |
| **In-Chat AI Assistant (GupAI)** | ✅ **Yes (Groq LLM Isolated)** | ⚠️ Meta AI Only | ❌ No | ⚠️ Third-Party Bots | ⚠️ Server Bots |
| **Integrated Arcade Mini-Games** | ✅ **Yes (Gup Arcade & Bonds)** | ❌ No | ❌ No | ⚠️ Bots Only | ✅ Yes |
| **Multi-Language Localization** | ✅ **Yes (16 World Languages)** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| **Offline Reactive SQLite Caching** | ✅ **Yes (Drift Database)** | ✅ Yes | ✅ Yes | ✅ Yes | ⚠️ Partial |

---

## 📸 App Preview & Visuals

<p align="center">
  <img src="assets/images/gupshupgo_chat_mockup_1783418008610.png" width="280" alt="Chat Interface">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="assets/images/gupshupgo_call_mockup_1783418021488.png" width="280" alt="HD Call & Screen Share">
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="assets/images/gupshupgo_gamification_mockup_1783418034370.png" width="280" alt="Gup Arcade & Streaks">
</p>

---

## 🔍 Independent Verification & Audit

We believe privacy claims must be independently auditable. We provide full procedures to verify:
1. **Cryptographic Identity Verification:** Verify Safety Numbers and public key fingerprints between contacts via in-app QR scanning or out-of-band comparison.
2. **Network Traffic Auditing:** Monitor network frames using tools like `mitmproxy` or `Wireshark` to confirm that all message payloads sent across the wire are encrypted ciphertexts.
3. **Local Storage Inspection:** Verify that on-disk databases utilize authenticated encryption and that private keys never leak into unencrypted logs or SQLite files.

👉 Read the step-by-step [Verification & Audit Guide](VERIFICATION.md).

---

## 🔒 Summary of Data Handling & Privacy Policy

| Data Category | Stored Locally On Device | Relayed Via Cloud | Accessible By GupShupGo |
| :--- | :---: | :---: | :---: |
| **Private Chat Messages** | ✅ Encrypted SQLite (Drift) | ⚡ Encrypted Ciphertext Relay Only | ❌ **NEVER (Mathematically Impossible)** |
| **Cryptographic Private Keys** | ✅ Hardware Keystore / Secure Enclave | ❌ **NEVER leaves your device** | ❌ **NEVER** |
| **Photos, Videos & Documents** | ✅ Stored locally | ⚡ End-to-End Encrypted Storage | ❌ **NEVER** |
| **Voice & Video Audio Streams** | ❌ Real-time ephemeral | ⚡ Encrypted Agora RTC Transport | ❌ **NEVER Recorded** |
| **Offline Mesh Messages** | ✅ Stored locally | ❌ Zero Server Transfer (P2P Radio) | ❌ **NEVER** |
| **Vault Conversations** | ✅ Argon2id Encrypted Store | ⚡ Encrypted Ciphertext Relay Only | ❌ **NEVER** |
| **Phone Number (for Auth)** | ✅ Cached for session | ⚡ Hashed / Tokenized in Firebase Auth | ⚠️ Verification & Account ID Only |

👉 Read the complete [Privacy Whitepaper & Policy](PRIVACY.md).

---

## 🛡️ Security Vulnerability Disclosure

If you discover a security or privacy vulnerability in GupShupGo, please report it responsibly:
* **Reporting Email:** `support@gupshupgo.app`
* **Alternative Channel:** Confidential draft advisory via [GitHub Security Advisories](https://github.com/vansh-121/GupShupGo-Public/security/advisories/new)
* **Response SLO:** Initial acknowledgment within **24 to 48 hours**.
* Please refer to [`SECURITY.md`](SECURITY.md) for full instructions.

---

## 📬 Contact, Community & Inquiries

* **Official Support & Inquiries:** `support@gupshupgo.app`
* **Official Website:** [https://www.gupshupgo.app](https://www.gupshupgo.app)
* **Bug Reports:** Submit via our [Public Bug Report Form](.github/ISSUE_TEMPLATE/bug_report.md)
* **Feature Requests:** Submit via our [Feature Request Template](.github/ISSUE_TEMPLATE/feature_request.md)
* **GitHub Repository:** [https://github.com/vansh-121/GupShupGo-Public](https://github.com/vansh-121/GupShupGo-Public)

---

## 📄 License & Terms

Documentation, architectural whitepapers, and verification specifications in this public repository are licensed under [Creative Commons Attribution 4.0 International (CC BY 4.0)](LICENSE).

The GupShupGo application code, binaries, trademarks, and associated brand assets are proprietary software owned by **VANSHORA LABS / Vansh Sethi**.

---

<div align="center">

**Built with pride by VANSHORA LABS**

[![Google Play](https://img.shields.io/badge/Google_Play-Download_Now-00875F?style=for-the-badge&logo=google-play&logoColor=white)](https://play.google.com/store/apps/details?id=com.gupshupgo.app)
[![Website](https://img.shields.io/badge/Website-gupshupgo.app-2563EB?style=for-the-badge)](https://www.gupshupgo.app)
[![GitHub](https://img.shields.io/badge/GitHub-vansh--121-181717?style=for-the-badge&logo=github)](https://github.com/vansh-121)

</div>
