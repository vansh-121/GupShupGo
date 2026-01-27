# Quick Start Guide - WhatsApp-Like Calling

## What Changed?

Your app now works like WhatsApp - users can call **ANYONE** who has the app installed, not just hardcoded "user_a" and "user_b"!

## 🎯 Quick Overview

**Before:** Only 2 users (user_a & user_b) could call each other
**After:** Unlimited users, real authentication, call anyone who's online!

## ⚡ Quick Setup (5 minutes)

### Step 1: Install dependencies
```bash
cd e:\GupShupGo\gupshupgo
flutter pub get
```

### Step 2: Update Firestore Rules
Go to Firebase Console → Firestore → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Step 3: Enable Phone Auth (Optional)
If using phone authentication:
1. Firebase Console → Authentication → Sign-in method
2. Enable "Phone" provider

### Step 4: Run the App
```bash
flutter run
```

## 📱 How to Test

### Option 1: Guest Login (Easiest)
1. Open app → Enter your name → Click "Continue as Guest"
2. Repeat on another device/emulator with different name
3. Click search icon → See other users → Call them!

### Option 2: Phone Auth (Production Ready)
1. Enter phone number with country code (e.g., +1234567890)
2. Enter name
3. Click "Send OTP"
4. Enter the 6-digit code
5. You're in!

## 🎨 New Features You'll See

### 1. Login Screen (New!)
- Phone authentication with OTP
- Guest login option for testing
- Beautiful welcome screen

### 2. Home Screen (Updated!)
- Shows real users from database
- Online status indicators (green dot)
- Tap search to browse all users
- Logout option in menu

### 3. Contacts Screen (New!)
- Search users by name or phone
- See who's online in real-time
- Call any user instantly
- Send messages to anyone

### 4. Call Screen (Updated!)
- Shows caller/callee name
- Connection status
- Better UI

## 🔄 What Happens Behind the Scenes

1. **User Registration**
   - User signs up → Saved to Firestore
   - FCM token generated → Saved for push notifications
   - Online status set to true

2. **Making a Call**
   - You select a user → Channel ID generated
   - Push notification sent to recipient
   - Both join Agora channel
   - Video call starts!

3. **Online/Offline Status**
   - App opens → Set online
   - App closes → Set offline
   - Real-time updates for all users

## 📂 Project Structure Changes

```
lib/
├── models/
│   └── user_model.dart          [NEW] User data structure
├── services/
│   ├── auth_service.dart        [NEW] Login/logout logic
│   ├── user_service.dart        [NEW] User management
│   ├── agora_services.dart      [Existing]
│   └── fcm_service.dart         [Existing]
├── screens/
│   ├── auth/
│   │   └── phone_auth_screen.dart  [NEW] Login screen
│   ├── contacts_screen.dart     [NEW] Browse users
│   ├── home_screen.dart         [UPDATED] Real users
│   ├── call_screen.dart         [UPDATED] Show caller name
│   └── chat_screen.dart         [Existing]
└── main.dart                    [UPDATED] Auth flow
```

## 🎯 Test Scenarios

### Scenario 1: Two Users Calling
1. **Device 1**: Login as "Alice" (guest)
2. **Device 2**: Login as "Bob" (guest)
3. **Device 1**: Tap search → See "Bob" → Tap video icon
4. **Device 2**: Receives notification → Call screen opens
5. **Both**: Video call connected!

### Scenario 2: Online Status
1. **Device 1**: Login as "Alice"
2. **Device 2**: Login as "Bob"
3. **Device 2**: Browse contacts → See "Alice" with green dot (online)
4. **Device 1**: Close app
5. **Device 2**: Alice shows "Last seen" instead of green dot

### Scenario 3: Search Users
1. Login with multiple users
2. Go to contacts screen
3. Type name in search bar
4. See filtered results
5. Call or message directly

## ❓ Common Questions

### Q: Do I need to configure anything special?
**A:** No! If your Firebase is already set up, just run `flutter pub get` and you're good to go.

### Q: Can I use email instead of phone?
**A:** Yes! You can modify auth_service.dart to support email/password authentication.

### Q: How many users can I have?
**A:** Unlimited! It's only limited by your Firebase plan.

### Q: Do users need to be in each other's contacts?
**A:** No! Anyone with the app can call anyone else (like WhatsApp).

### Q: What about privacy?
**A:** Currently anyone can call anyone. You can add privacy settings later (see IMPLEMENTATION_GUIDE.md).

## 🐛 Quick Fixes

### "No users showing up"
- Make sure you have multiple users logged in on different devices
- Check Firestore console to verify users are being created

### "Can't receive calls"
- Verify FCM is working (check console logs)
- Make sure service-account.json is in assets folder
- Check both devices have internet

### "Authentication not working"
- Enable Phone Auth in Firebase Console
- For guest login, no setup needed!

## 🚀 Next Steps

1. **Test it now**: Run the app and create 2 users
2. **Read full guide**: Check IMPLEMENTATION_GUIDE.md for details
3. **Customize**: Add your own features!

## 📞 Making Your First Call

**Step-by-step:**

```
1. Open app on Device 1
   └─→ Login as "Alice" (Guest)
   
2. Open app on Device 2  
   └─→ Login as "Bob" (Guest)
   
3. On Alice's device:
   └─→ Tap search icon (top right)
   └─→ See "Bob" in the list
   └─→ Tap video camera icon next to Bob's name
   
4. On Bob's device:
   └─→ Call screen automatically opens
   └─→ See "Alice" calling
   └─→ Accept or decline
   
5. Success! 🎉
   └─→ Both users in video call
```

## ✅ Verification Checklist

After setup, verify:
- [ ] App opens to login screen (not home)
- [ ] Can login as guest with just a name
- [ ] Home screen shows "Messages" 
- [ ] Tapping search shows contacts screen
- [ ] Can see other logged-in users
- [ ] Green dot appears for online users
- [ ] Can initiate video call
- [ ] Other device receives notification
- [ ] Video call works both ways

---

**You're all set!** 🎉 Your app now has professional-grade calling like WhatsApp!

Need help? Check `IMPLEMENTATION_GUIDE.md` for detailed documentation.
