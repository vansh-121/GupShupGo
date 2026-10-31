# GupShupGo Privacy & Cryptography Whitepaper

**Last Updated:** October 31, 2026  
**Document Classification:** Public Transparency Specification  
**Version:** 1.2.3

---

## 1. Executive Privacy Pledge

> *"What you write is your business. What you share is between you and the recipient. We cannot read your private messages, we cannot listen to your calls, and we cannot track your physical location."*

At **GupShupGo**, privacy is not an afterthought, a toggle in an obscure sub-menu, or a marketing slogan. It is the mathematical foundation upon which every single line of code is structured.

Modern messaging apps routinely claim to be private while simultaneously collecting extensive contact graphs, communication metadata, device telemetry, and location history. GupShupGo was engineered to dismantle that paradigm by adhering to a strict **Zero-Knowledge Architecture**: our servers cannot decrypt your messages even if compelled by subpoena, rogue internal access, or infrastructure compromise.

---

## 2. Fundamental Architectural Principles

1. **Zero-Knowledge By Default:** All 1-on-1 chats, shared documents, photos, videos, and audio notes are end-to-end encrypted before they leave your device. The cryptographic keys required to decrypt them exist solely on client devices and are never transmitted to our servers.
2. **Local-First Data Residency:** All conversation histories, contact states, and media caches live in an encrypted, reactive local SQLite database (`Drift`) on your physical device. The cloud backend acts strictly as an asynchronous ciphertext delivery pipe.
3. **Decentralized Off-Grid Resilience:** When internet connectivity is absent or shut down, GupShupGo operates peer-to-peer over local radio waves (Bluetooth & Wi-Fi Direct), bypassing internet service providers, cell towers, and cloud backbones entirely.
4. **Zero Commercial Surveillance:** GupShupGo contains zero advertising frameworks, zero third-party tracking SDKs (e.g., no Facebook SDK, no Google AdMob, no behavioral trackers), and does not sell or broker user information to third parties.

---

## 3. Cryptographic Specification

GupShupGo implements the industry gold standard **Signal Protocol**, engineered for asynchronous, zero-trust messaging.

```
       [SENDER: ALICE]                                         [RECIPIENT: BOB]
              |                                                       |
   1. Generate Key Pairs (IK, SPK, OPK)                      1. Upload Public PreKey
              |                                                 Bundle to Relay Server
              |                                                       |
   2. Fetch Bob's Public PreKey Bundle <------------------------------+
              |
   3. Execute X3DH Agreement:
      DH1 = DH(IK_A, SPK_B)
      DH2 = DH(EK_A, IK_B)
      DH3 = DH(EK_A, SPK_B)
      DH4 = DH(EK_A, OPK_B)
      SK  = KDF(DH1 || DH2 || DH3 || DH4)
              |
   4. Initialize Double Ratchet Chain
      (Root Key, Sending Key, Receiving Key)
              |
   5. Step Symmetric KDF Chain:
      Message Key = KDF(Chain Key)
              |
   6. Encrypt Payload:
      Ciphertext = AES-256-GCM(Message Key, Plaintext)
              |
              | ====== [Opaque Ciphertext Envelope via Cloud Relay] =====> |
              |                                                            |
              |                                                 7. Step Receiving Chain
              |                                                 8. Derive Matching Key
              |                                                 9. Decrypt Plaintext
```

### 3.1 Extended Triple Diffie-Hellman (X3DH)
When Alice wishes to message Bob for the first time, she initiates the **X3DH** protocol:
* **Identity Keys (`IK`):** Long-term Curve25519 key pairs representing each user's cryptographic identity.
* **Signed PreKeys (`SPK`):** Medium-term key pairs signed by the identity key, rotated periodically.
* **One-Time PreKeys (`OPK`):** A pool of ephemeral key pairs consumed upon initial contact establishment.

By computing a combination of Diffie-Hellman operations between these keys, both devices arrive at an identical shared master secret key (`SK`) without ever transmitting that secret over the wire. This handshake succeeds even if Bob is offline when Alice sends the initial message.

### 3.2 The Double Ratchet Algorithm
Once initial key agreement is established, every message exchange utilizes the **Double Ratchet**:
* **Diffie-Hellman Ratchet:** With every round-trip reply, a fresh ephemeral DH key pair is generated and exchanged in the message header. This creates a new shared DH output, refreshing the root key chain.
* **Symmetric-Key KDF Ratchet:** For every single message sent within a conversation, the sending chain advances using an HMAC-based Key Derivation Function (HKDF). A unique 256-bit encryption key is generated for that specific message and immediately destroyed after use.

#### Security Guarantees:
* **Perfect Forward Secrecy (PFS):** Compromising a device's current cryptographic keys does not expose past messages, as past message keys cannot be derived backward from newer chain keys.
* **Post-Compromise Security (Break-in Recovery):** If an adversary temporarily compromises a device's keys, the conversation automatically heals and restores privacy as soon as a single DH ratchet step occurs in a new reply.

### 3.3 Safety Numbers & Cryptographic Fingerprinting
To protect against Man-in-the-Middle (MITM) attacks or unauthorized key substitution, GupShupGo generates a deterministic **Safety Number** for every conversation:
* The Safety Number is derived from the SHA-512 hash of the sorted public identity keys of both participants.
* Users can verify Safety Numbers either by visually comparing the 60-digit numeric block or by scanning each other's in-app QR code during an in-person meeting or over a verified channel.
* If a contact re-installs the app or changes devices, the identity key changes and GupShupGo alerts the user before transmitting new messages.

---

## 4. Secret Chat Vault & Local Storage Security

Even the strongest transport encryption is useless if local storage on the device is vulnerable to forensic extraction. GupShupGo implements military-grade local data isolation.

```
       [User PIN / Password Input]
                    |
                    v
       [Argon2id Memory-Hard KDF]  <--- Hardware Salt (OS Keystore)
                    |
                    v
       [256-bit Database Master Key]
                    |
                    v
       [AES-256-GCM Local Database Store]
```

### 4.1 Argon2id Key Derivation
Hidden conversations and confidential archives are locked inside the **Secret Vault**:
* The vault PIN is processed through **Argon2id**, the winner of the Password Hashing Competition.
* **Memory-Hard Parameters:** Configured with high memory and iteration costs, making brute-force attacks via parallel GPUs or specialized ASIC hardware mathematically intractable.
* The derived key unlocks a separate, encrypted SQLite storage segment.

### 4.2 Hardware Keystore & Keychain Integration
* Master identity keys and auth session credentials are never stored in plain text on the file system.
* They are delegated to the **Android Keystore** (utilizing hardware-backed TEE / StrongBox Keymaster) or **iOS Keychain** (Apple Secure Enclave).
* Keys are bound to the physical hardware and cannot be extracted or cloned, even via ADB backups.

---

## 5. Decentralized Offline P2P Mesh Protocol

One of GupShupGo's signature privacy features is its ability to communicate off-grid without any reliance on cell towers, satellites, or internet routers.

```
+--------------------------------------------------------------------------+
|                     OFFLINE P2P MESH TOPOLOGY                            |
|                                                                          |
|   [Device A: Alice]   <---- (BLE Handshake) ---->   [Device B: Bob]      |
|           \                                                /             |
|            \--- (Wi-Fi Direct High-Speed Payload Pipe) ---/              |
|                                                                          |
|   • 0% Cell Tower Traffic          • 0% Internet Connection              |
|   • 0% ISP Metadata Collection     • 100% Signal Protocol E2EE           |
+--------------------------------------------------------------------------+
```

### 5.1 Radio Layer Mechanics
* **Discovery:** Low-power Bluetooth Low Energy (BLE) adverts advertise transient, randomized peer identifiers.
* **Transport:** Upon pairing, high-bandwidth Wi-Fi Direct or local P2P Wi-Fi sockets are established for transmitting text, photos, voice notes, and documents up to 64 MB.
* **Payload Encryption:** Mesh packets are encapsulated in the identical Signal Protocol E2EE envelopes used over the internet. Nearby eavesdroppers monitoring radio frequencies only capture uncrackable ciphertext.

### 5.2 Metadata Resistance
Because offline mesh messages travel directly over local radio waves:
* No IP addresses are logged.
* No central servers register who is communicating with whom.
* No cellular carrier logs connection timestamps or cell tower triangulations.

---

## 6. Real-Time Calling & Media Privacy

### 6.1 Audio & Video Calling
* Real-time audio and video communications are powered by the **Agora RTC Engine**.
* Media streams are transmitted via low-latency, encrypted SRTP (Secure Real-time Transport Protocol) channels.
* **Zero Audio/Video Recording:** GupShupGo does not record, intercept, or store any call audio, video feeds, or screen share streams. Calls are completely ephemeral.
* **Native Incoming Call Notifications:** Android Full-Screen Intent activities and Apple CallKit securely notify devices using encrypted payload headers, waking the phone with zero exposure of call contents.

### 6.2 View-Once Media & Ephemeral Moments
* **View-Once Photos & Videos:** Media sent in View-Once mode is downloaded encrypted. The moment the recipient views and exits the media, the decryption key is purged from memory and the local file cache is immediately deleted from disk.
* **Anti-Screenshot Hardening:** GupShupGo enforces Android's `FLAG_SECURE` window attribute on View-Once viewers and Secret Vault screens, disabling screenshots and system screen recorders.
* **Moments (Statuses):** Status updates expire automatically after 24 hours. The cloud cleanup pipeline permanently purges status media from storage buckets upon expiration.

---

## 7. GupAI In-Chat Assistant Privacy

GupShupGo integrates an intelligent in-app assistant (**GupAI**). Unlike traditional chat platforms that continuously monitor conversations:

* **No Ambient Listening or Reading:** GupAI is completely inert and does not read, parse, or index your chat messages in the background.
* **Client-Initiated Queries Only:** GupAI is activated strictly when the user explicitly triggers an AI action (such as drafting an email, summarizing a specific highlighted snippet, or translating a message).
* **Zero Model Training on User Data:** Queries processed by GupAI are sent through secure, isolated backend endpoints and are **never** used to train public foundation models or build user marketing profiles.

---

## 8. Data Minimization & Retention Matrix

The following table explicitly details all data elements handled by GupShupGo:

| Data Type | Stored On Device | Relayed Via Cloud | Cloud Retention Policy | Can GupShupGo Access? |
| :--- | :---: | :---: | :---: | :---: |
| **Direct Chat Messages** | Yes (Encrypted SQLite) | Yes (Ciphertext Only) | Purged immediately upon successful delivery | ❌ **No (E2EE)** |
| **Private Keys & Identity Secrets** | Yes (Hardware Keystore) | **Never** | N/A | ❌ **No** |
| **Photos, Videos, Files** | Yes (Local Cache) | Yes (Ciphertext Only) | Stored in E2EE bucket until recipient downloads | ❌ **No (E2EE)** |
| **Call Audio / Video Streams** | **Never (Ephemeral)** | Yes (Encrypted RTC) | **Never recorded or stored** | ❌ **No** |
| **Offline Mesh Messages** | Yes (Local Queue) | **Never** (Direct P2P) | N/A | ❌ **No** |
| **Secret Vault Chats** | Yes (Argon2id Store) | Yes (Ciphertext Only) | Purged upon delivery | ❌ **No (E2EE)** |
| **View-Once Media** | Ephemeral Cache | Yes (Ciphertext Only) | Purged upon delivery | ❌ **No (E2EE)** |
| **Phone Number** | Yes (Local Session) | Yes (Tokenized in Auth) | Duration of account lifecycle | ⚠️ Account Verification Only |
| **Display Name & Avatar** | Yes | Yes (Public Profile) | Duration of account lifecycle | Public to contacts |
| **Contact Address Book** | Stored locally | **Never uploaded in bulk** | Only queries requested handles | ❌ **No contact scraping** |
| **Advertising Telemetry** | **None** | **None** | **Zero Trackers** | ❌ **None** |

---

## 9. Third-Party Infrastructure Disclosures

To operate real-time communications reliably worldwide, GupShupGo utilizes select infrastructure providers under strict security contracts:

* **Google Firebase & Google Cloud Platform:** Used for user authentication (phone OTP), Firestore real-time signaling, Cloud Storage (for encrypted media envelopes), and Firebase Cloud Messaging (FCM) for wake-up push notifications. Firebase only processes encrypted ciphertext for message payloads.
* **Agora RTC Engine:** Transmits live audio, video, and screen-sharing packets over encrypted real-time networks. Streams are ephemeral and never recorded.
* **Brevo SMTP Relay:** Used exclusively for dispatching verified transactional security emails and invite links with DKIM, SPF, and DMARC verification (`noreply@gupshupgo.app`).

No user chat data or cryptographic secrets are ever shared with or accessible by these infrastructure vendors.

---

## 10. User Control & Data Rights

You possess complete sovereignty over your data:

1. **Delete for Everyone:** Senders can retract messages at any time. When deleted, a tombstone signal instructs the recipient client to delete the message from their local database.
2. **Instant Account Deletion:** You can delete your account at any time from within the app (**Settings → Account → Delete Account**). Deletion permanently purges your profile, prekey bundles, and registration records from our cloud database.
3. **Data Export:** Chat histories can be exported locally into clean, printable PDFs directly from the conversation menu.

---

## 11. Security Audit & Contact

We welcome inquiries, audits, and scrutiny from the global cryptography and privacy community.

* **Privacy Questions & Inquiries:** `privacy@gupshupgo.app`
* **Security & Vulnerability Reports:** `security@gupshupgo.app` (See [`SECURITY.md`](SECURITY.md))
* **Official Website:** [https://gupshupgo.app](https://gupshupgo.app)
* **GitHub Issues:** [https://github.com/vansh-121/GupShupGo/issues](https://github.com/vansh-121/GupShupGo/issues)
