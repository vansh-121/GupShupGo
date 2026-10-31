# Frequently Asked Questions (FAQ)

Everything you need to know about GupShupGo's privacy, security, and technology.

---

## 🔒 Privacy & Cryptography

### 1. Can GupShupGo, Google, or law enforcement read my messages or see my photos?
**No.** It is mathematically impossible. 

All 1-on-1 conversations, voice notes, photos, videos, and documents are encrypted using the **Signal Protocol** (X3DH + Double Ratchet) directly on your device before they enter the network. The cryptographic private keys required to decrypt your messages are generated and stored exclusively on your device (in the hardware-backed Android Keystore / iOS Keychain). 

Our servers, Firebase relays, and internet service providers only ever transmit opaque, randomized ciphertext blobs (`AES-256-GCM`). We do not hold your keys, so we cannot decrypt your communications under any circumstances.

---

### 2. Why is the main application codebase private, and why does this public repository exist?
Privacy and security are proven through **cryptographic protocols, mathematical specifications, and auditable network behavior** — not just raw application source code dumps.

Many production privacy products (like Telegram, Element, and Signal's proprietary server components) maintain private core production branches to protect infrastructure, prevent abusive clone spam on app stores, and safeguard platform integrity.

This public repository serves as the **official transparency center**:
* Complete cryptographic specifications and mathematical models ([PRIVACY.md](PRIVACY.md)).
* Step-by-step procedures to independently inspect and audit network traffic and local storage ([VERIFICATION.md](VERIFICATION.md)).
* Public issue tracking, feature requests, and vulnerability disclosure ([SECURITY.md](SECURITY.md)).
* Complete release history and changelog ([CHANGELOG.md](CHANGELOG.md)).

You do not have to trust our source code — you can directly verify that every byte leaving your phone is encrypted ciphertext by following our [Verification Guide](VERIFICATION.md).

---

### 3. Does GupShupGo sell my data or show me advertisements?
**Never.** GupShupGo contains **zero advertising SDKs** (no Google AdMob, no Meta Audience Network) and **zero behavioral analytics trackers** (no Adjust, no AppsFlyer, no tracker cookies). We do not build advertising profiles, and we will never monetize your private data.

---

### 4. How does GupAI protect my conversations? Does it read my chats?
**No, GupAI never reads your conversations in the background.**

* GupAI is completely dormant until you explicitly trigger an action (such as tapping the GupAI button to draft a response, summarize a specific paragraph, or translate a foreign message).
* It does not ambiently listen to your microphone or index your chat histories.
* Queries sent to GupAI are processed via isolated backend pipelines and are **never** used to train AI models or stored as user telemetry.

---

## 📡 Offline Mesh & Calling

### 5. How does Offline Mesh chat work when I don't have internet or cell service?
Offline Mesh connects phones directly to one another using local radio hardware: **Bluetooth Low Energy (BLE)** for discovery and **Wi-Fi Direct** for high-speed data transmission.
* Range extends up to 100 meters directly between devices.
* It operates without cellular networks, cell towers, Wi-Fi routers, or internet backhaul.
* Messages are encrypted end-to-end using the same Signal Protocol keys.
* When either party regains internet access, the app automatically and securely synchronizes delivery status with the cloud.

---

### 6. Are voice and video calls encrypted? Are calls ever recorded?
**Yes, calls are fully encrypted and NEVER recorded.**
* Audio and video streams are transmitted through encrypted real-time channels using the Agora RTC engine.
* Streams are completely ephemeral: once a call ends, the audio/video packets cease to exist. GupShupGo does not record, tap, or store audio/video data on any server.
* Incoming calls leverage native Android Full-Screen Intent activities and Apple CallKit to display native lock-screen alerts without transmitting call contents in notification payloads.

---

## 🛡️ Secret Vault & Ephemeral Features

### 7. What is the Secret Vault and how does it protect my hidden chats?
The Secret Vault allows you to hide sensitive conversations behind a separate 4-to-6 digit PIN or biometric fingerprint:
* **Argon2id Memory-Hard Hashing:** The PIN is derived using Argon2id with 64 MB memory cost parameters, rendering offline GPU/ASIC dictionary attacks ineffective.
* **Separated Encrypted Database:** Vault chats are stored in a distinct encrypted database table.
* **Hidden from Notifications:** Conversations in the Vault do not produce standard message preview banners or notification text on the lock screen.

---

### 8. What happens when I send a "View Once" photo or video?
* When you send a View-Once image or video, the recipient can open it exactly one time.
* The local decryption key is destroyed the moment the viewer is dismissed.
* The encrypted file cache on the recipient's phone is immediately deleted from disk.
* On Android devices, the viewer is protected with `FLAG_SECURE`, preventing screenshots or screen recordings while the media is displayed.

---

## 👤 Account & Data Management

### 9. What information is required to create an account?
To prevent spam and facilitate contact discovery, GupShupGo requires phone number verification via Firebase SMS OTP.
* If you prefer complete anonymity, GupShupGo also offers **Guest Mode / Anonymous Chat**, which assigns a random pseudonym (e.g., *Clever Eagle 🦅*) without collecting a phone number or email address.

---

### 10. How can I delete my account and data completely?
You can delete your account at any time in seconds:
1. Open GupShupGo.
2. Go to **Settings → Account → Delete Account**.
3. Confirm deletion.

**What happens immediately:**
* Your profile, user handle, and public PreKey bundles are permanently deleted from Firestore.
* Your local database is wiped from your device.
* All associated notification tokens and device registrations are permanently cleared.

---

### 11. Where can I report a bug or suggest a new feature?
* **Bug Reports:** Open an issue on our [GitHub Issues](https://github.com/vansh-121/GupShupGo/issues).
* **Feature Ideas:** Submit a feature proposal using our [Feature Request Template](.github/ISSUE_TEMPLATE/feature_request.md).
* **Security Issues:** Email `security@gupshupgo.app` (see [`SECURITY.md`](SECURITY.md)).
