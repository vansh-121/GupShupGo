# Independent Verification & Audit Guide

**Document Status:** Public Security Reference  
**Scope:** Client Verification, Cryptographic Inspection & Network Auditing  
**Applies to:** GupShupGo v1.2.0+

---

## 🎯 Verification Philosophy

> *"Don't trust, verify."*

At GupShupGo, we do not expect you to accept our privacy promises on faith. Modern software architecture allows independent verification of cryptographic claims.

This document outlines practical, step-by-step procedures for security researchers, privacy advocates, and technical users to independently audit and verify that:
1. All private messages, photos, videos, and files are encrypted end-to-end using the Signal Protocol before leaving your phone.
2. Network transmissions contain zero plaintext or extractable message contents.
3. Cryptographic identity keys can be verified out-of-band to prevent Man-in-the-Middle (MITM) attacks.
4. Local secret vaults and database stores are cryptographically locked using memory-hard Argon2id KDF and AES-256-GCM.
5. Ephemeral and View-Once media keys are wiped permanently from device memory upon consumption.

---

## 1. Out-of-Band Safety Number Verification

Every 1-on-1 chat in GupShupGo generates a unique, deterministic **Safety Number** computed from the concatenated, sorted public identity keys of both participants.

### Verification Procedure:
1. Open any private chat conversation.
2. Tap the contact's header at the top to open their Profile.
3. Select **"Verify Safety Number"**.
4. You will see a 60-digit number broken into twelve 5-digit groups, along with a scannable QR code.
5. **Physical / In-Person Audit:**
   * Have the other party open their corresponding Safety Number screen.
   * Tap **"Scan QR Code"** and scan the contact's screen.
   * A green verification badge will confirm that both identity keys match byte-for-byte.
6. **Remote / Out-of-Band Audit:**
   * Read the numeric block to your contact over a verified secondary channel (such as a voice call or PGP-signed email).
   * Confirm that all 12 blocks match.

**Mathematical Assurance:** If an attacker, rogue ISP, or compromised server attempted to intercept or decrypt your communication, they would have had to replace the recipient's public key with their own. This would result in an immediate Safety Number mismatch.

---

## 2. Network Traffic & Packet Inspection

You can inspect the actual bytes transmitted by the GupShupGo Android application over the internet using an SSL-decrypting proxy like `mitmproxy` or `Charles Proxy`.

### Required Environment:
* An Android device running Android 7.0+ (or Android Emulator) configured with user root or an unlocked bootloader to trust custom User CA certificates.
* A workstation running [mitmproxy](https://mitmproxy.org/).

### Setup Steps:
1. Start `mitmweb` on your workstation:
   ```bash
   mitmweb --listen-host 0.0.0.0 --listen-port 8080
   ```
2. Configure your Android device's Wi-Fi proxy settings to point to your workstation's IP on port `8080`.
3. Browse to `http://mitm.it` on the Android browser and install the mitmproxy CA certificate into Android's trusted credentials.
4. Launch GupShupGo and send a message (e.g., `"Top secret test message 12345"`).

### What You Will Observe:
1. **Firestore & Cloud Relay Requests:**
   * Locate the POST/REST or WebSocket frame dispatching the message payload to the cloud relay.
   * Inspect the JSON structure. You will observe fields resembling:
     ```json
     {
       "senderId": "uid_alice",
       "recipientId": "uid_bob",
       "type": "e2ee_signal_envelope",
       "timestamp": 1798718291000,
       "ciphertext": "3a8f9b1c70e2d45a901f4c7b8e119d65a2f8b9...",
       "registrationId": 14092,
       "preKeyId": 482
     }
     ```
2. **Analysis:**
   * The text `"Top secret test message 12345"` is **nowhere** in the payload or query parameters.
   * The ciphertext is a binary protobuf representation of an AES-256-GCM envelope authenticated by the Signal Double Ratchet.
   * Decrypting this payload requires Alice's or Bob's private Curve25519 identity and ratchet keys, which never leave their respective physical devices.

### Media & Attachment Inspection:
* Send a photograph or document.
* Inspect the upload request to Firebase Storage:
  * The file uploaded to `chat_documents/` or `chat_media/` is an encrypted binary blob.
  * Downloading the raw bytes directly from the storage URL outside of the app yields pseudorandom bytes that cannot be opened as an image, PDF, or document without the decryption key exchanged over the E2EE ratchet channel.

---

## 3. Local SQLite Database Inspection (Drift)

GupShupGo stores conversation records on-device using a reactive SQLite database powered by `drift`.

### Verification Procedure (Rooted Device or Emulator):
1. Connect via ADB:
   ```bash
   adb shell
   su
   ```
2. Navigate to the app's private sandboxed data directory:
   ```bash
   cd /data/data/com.gupshupgo.app/databases/
   ls -la
   ```
3. Inspect `app_database.sqlite`:
   ```bash
   sqlite3 app_database.sqlite "SELECT message_id, content, is_encrypted FROM messages LIMIT 5;"
   ```
4. **Observations:**
   * Direct message records are flagged with `is_encrypted = 1`.
   * The content field holds encrypted envelope structures or locally secured tokens.
   * Private key entries in `crypto_keys.sqlite` are secured by hardware-backed encryption keys retrieved via Android Keystore (`KeyStore` provider `AndroidKeyStore`), which refuses extraction across process boundaries.

---

## 4. Secret Vault PIN & Argon2id Verification

To verify that Vault PINs cannot be brute-forced:
1. Examine the vault initialization mechanism:
   * When setting a 4-to-6 digit PIN, the application executes `Argon2id` using memory-hard cost factors (memory: 64 MB, iterations: 3, parallelism: 4).
   * The salt is cryptographically generated using a CSPRNG (`Random.secure()`).
2. If an attacker extracts the database file, standard MD5/SHA-256 dictionary attacks fail:
   * Each guess requires calculating the full 64 MB memory matrix of Argon2id.
   * Testing 1,000,000 candidate PINs on standard GPU hardware would require tens of gigabytes of RAM allocation per thread, rendering mass offline cracking attempts unfeasible.

---

## 5. Ephemeral Media & View-Once Wiping

To verify that View-Once media does not persist:
1. Have a contact send you a photo marked with the **"View Once" (1)** badge.
2. Monitor the device cache directory via ADB:
   ```bash
   adb shell "run-as com.gupshupgo.app ls -la /data/data/com.gupshupgo.app/cache/"
   ```
3. Tap to view the image in GupShupGo.
4. Exit the View-Once screen back to the conversation.
5. Re-check the cache directory:
   * The ephemeral file is immediately unlinked and removed.
   * Attempting to reopen the message in the UI displays `"Opened"`, and the decryption key has been deleted from memory.

---

## 6. Official Binary Verification (APK Checksums)

To ensure that the application binary running on your device is authentic and has not been altered or repacked:

### Official Release Hashes (Google Play Store Builds):

* **Package Name:** `com.gupshupgo.app`
* **Release Version:** `1.2.3` (Build `61`)

You can inspect the signing certificate of an installed APK using the Android SDK `apksigner`:
```bash
apksigner verify --verbose --print-certs GupShupGo-1.2.3.apk
```

**Expected Signer Details:**
* **Certificate SHA-256:** Verified Google Play App Signing key.
* **Target SDK:** 36 (Android 15+ / 16 KB page-size compliant).

