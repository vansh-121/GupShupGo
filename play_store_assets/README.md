# 📱 GupShupGo - Play Store Official Assets & Store Listing Suite

This directory contains the complete Google Play Store submission package for **GupShupGo**, including:
1. **[STORE_LISTING_DESCRIPTION.md](./STORE_LISTING_DESCRIPTION.md)**: Full Google Play Store app copy (Short & 4,000 char Full Description with all features: Anonymous Chat, Gup Arcade, Moments, End-to-End Encryption, Offline Mesh Chat, HD Calls & Privacy controls).
2. **Interactive Assets Studio (`index.html`)**: High-resolution Play Store screenshot assets generator.

---

## 📐 Specs & Dimensions
- **Dimensions**: `1240 px × 2480 px` (Standard Google Play Store 9:19.5 modern phone aspect ratio)
- **Format**: High-Resolution PNGs & Interactive HTML Studio
- **Design Aesthetic**: Deep Violet Radial Gradient (`#2E1065` -> `#130B29` -> `#05020B`), Slim iPhone 16 Pro Mockup Frame, Cyber Grid Overlay, Glowing Orbs, Bold Poppins ExtraBold & Plus Jakarta Sans typography.

---

## 🎨 Asset Collection (8 Portrait Assets)

| # | File Name | Headline | Feature Highlight | Highlight Badge |
|---|-----------|----------|-------------------|-----------------|
| **0** | `screenshot_0_main_hero_promo.png` | **GUPSHUPGO HERO COVER** | Main Promotional Showcase | ⭐ OFFICIAL GUPSHUPGO APP |
| **1** | `screenshot_1_offline_chat.png` | **OFFLINE CHAT MODE** | Peer-to-peer 100m Bluetooth & Wi-Fi Direct Mesh Chat | 📡 NO INTERNET REQUIRED |
| **2** | `screenshot_2_anonymous_chat.png` | **ANONYMOUS CHATTING** | Instant random matching with cool pseudonyms & avatars | 🦅 INSTANT RANDOM MATCHING |
| **3** | `screenshot_3_chats_list.png` | **PRIVATE & SECURE CHATS** | Encrypted chats list with real-time streaks & online status | 💬 END-TO-END ENCRYPTED |
| **4** | `screenshot_4_hd_calls.png` | **HD VOICE & VIDEO CALLS** | Crystal-clear video & voice calling with in-call controls | ⚡ ULTRA LOW LATENCY |
| **5** | `screenshot_5_gup_arcade.png` | **GUP ARCADE & REWARDS** | Gup Points, XP progress, level titles & leaderboard podiums | 🏆 GAMIFIED CHATTING |
| **6** | `screenshot_6_chat_detail.png` | **REAL-TIME MESSAGING** | Fast direct chat with read receipts, media & local caching | ⚡ INSTANT MESSAGING |
| **7** | `screenshot_7_e2ee_security.png` | **SIGNAL CRYPTOGRAPHY** | Signal Protocol 6x4 cryptographic Safety Numbers verification | 🔒 SIGNAL PROTOCOL PRIVACY |

---

## 🛠️ How to Generate / Export PNGs

### Option 1: Using the Visual Studio Web App (Easiest)
1. Open `play_store_assets/index.html` in any web browser.
2. Click **"Download All PNG Assets"** at the top right, or **"Download PNG"** under any screenshot card.
3. High-resolution 1240 × 2480 px PNG files will be exported directly!

### Option 2: Using Automated Command Line
Run the following script to render all PNGs directly into `play_store_assets/output/`:
```bash
node play_store_assets/generate_pngs.js
```
All 8 images will be saved in `play_store_assets/output/`.
