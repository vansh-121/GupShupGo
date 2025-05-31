# 📞 GupShupGo — One-to-One Video Calling App

> ⚠️ **Status: Under Development**  
> This Flutter app is actively being built as part of a developer assignment. Features like background call handling, real-time video streaming, and notification actions are under construction.

---

A Flutter-based one-on-one **video calling app** using **Agora RTC Engine** and **Firebase Cloud Messaging (FCM)**. It demonstrates smooth video communication, WhatsApp-style incoming call notifications, and user-friendly call controls — even when the app is closed or in the background.

---

## 🚀 Features (Planned & In Progress)

- ✅ One-on-one real-time video calling
- 📲 Incoming call notification when app is in **background or terminated**
- 🎥 Video + audio support using Agora
- 🔔 Accept/Reject calls via full-screen notification
- 📞 Dynamic call states: Idle, Calling, Ringing, Connected, Ended
- 🎚️ In-call features: Mute/Unmute, End Call, Switch Camera
- 📶 Graceful reconnection on network loss
- 🧾 (Bonus) In-app call logs

---

## 🧑‍💻 Simulated Users

To simplify testing, the app simulates two users:

- **User A** – ID: `user_a`
- **User B** – ID: `user_b`

You can switch between the two to test call initiation and reception.

---

## 🛠️ Tech Stack

| Tool                  | Purpose                                  |
|-----------------------|------------------------------------------|
| Flutter               | UI & cross-platform app development      |
| Agora RTC Engine      | Real-time video/audio communication      |
| Firebase Cloud Messaging (FCM) | Push notifications           |
| flutter_callkit_incoming / awesome_notifications | Full-screen call UI |
| Shared Preferences    | Local user session storage               |

---
