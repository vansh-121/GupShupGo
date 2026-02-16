# 🚀 Deployment Checklist

## Before You Test

### ✅ Step 1: Firebase Configuration (5 minutes)

**1.1 Firestore Security Rules**
- [ ] Go to [Firebase Console](https://console.firebase.google.com)
- [ ] Select your project
- [ ] Navigate to: **Firestore Database → Rules**
- [ ] Copy rules from `FIRESTORE_SETUP.md`
- [ ] Click **Publish**
- [ ] Wait 1-2 minutes for rules to propagate

**1.2 Firebase Storage Security Rules**
- [ ] Navigate to: **Storage → Rules**
- [ ] Copy storage rules from `storage.rules` or `FIRESTORE_SETUP.md`
- [ ] Click **Publish**
- [ ] Verify storage bucket is active

**1.3 Phone Authentication (Optional - for production)**
- [ ] Go to: **Authentication → Sign-in method**
- [ ] Enable **Phone** provider
- [ ] Add authorized domains if needed
- [ ] For Android: Add SHA-1 certificate fingerprint
- [ ] For iOS: Enable push notifications in Xcode

**1.4 Anonymous Authentication (For testing)**
- [ ] Go to: **Authentication → Sign-in method**
- [ ] Enable **Anonymous** provider
- [ ] This allows guest login without phone

### ✅ Step 2: Verify Dependencies (1 minute)
- [x] Run `flutter pub get` ✅ (Already done!)
- [ ] Check for any errors in terminal
- [ ] Verify no version conflicts

### ✅ Step 3: Test on Devices (10 minutes)

**You need 2 devices/emulators to test calling**

**Device 1 (Alice):**
- [ ] Connect device or start emulator
- [ ] Run: `flutter run`
- [ ] App opens to login screen
- [ ] Click "Continue as Guest"
- [ ] Enter name: "Alice"
- [ ] Home screen appears
- [ ] Verify no errors in console

**Device 2 (Bob):**
- [ ] Connect second device or start second emulator
- [ ] Run: `flutter run` on second device
- [ ] App opens to login screen
- [ ] Click "Continue as Guest"
- [ ] Enter name: "Bob"
- [ ] Home screen appears
- [ ] Verify no errors in console

## Testing Features

### ✅ Test 1: User Registration & Presence

**On Device 1 (Alice):**
- [ ] Tap search icon (top right)
- [ ] See "Bob" in contacts list
- [ ] Verify green dot next to Bob (online)
- [ ] Verify Bob's name appears correctly

**On Device 2 (Bob):**
- [ ] Tap search icon (top right)
- [ ] See "Alice" in contacts list
- [ ] Verify green dot next to Alice (online)
- [ ] Verify Alice's name appears correctly

**✅ If you see each other with green dots → SUCCESS!**

### ✅ Test 2: Making a Call

**On Device 1 (Alice):**
- [ ] In contacts screen, find Bob
- [ ] Tap video camera icon next to Bob's name
- [ ] Call screen should open
- [ ] Loading indicator appears
- [ ] Status shows "Calling..."

**On Device 2 (Bob):**
- [ ] Push notification should appear (or call screen opens)
- [ ] Call screen opens automatically
- [ ] Caller name shows "Alice"
- [ ] Status shows "Incoming Call"

**Both Devices:**
- [ ] Wait 2-5 seconds
- [ ] Status changes to "Connected"
- [ ] Both video streams appear
- [ ] Can see remote user's video
- [ ] Can see own video (small preview)

**✅ If both videos are visible → SUCCESS!**

### ✅ Test 3: Call Controls

**Test each button:**
- [ ] **Mute button** - Audio mutes/unmutes
- [ ] **Video button** - Camera turns off/on
- [ ] **Switch camera** - Front/back camera toggle
- [ ] **End call button** - Call ends, returns to home

**✅ If all controls work → SUCCESS!**

### ✅ Test 4: Online/Offline Status

**On Device 1 (Alice):**
- [ ] Close app (swipe away or press back)
- [ ] Wait 5 seconds

**On Device 2 (Bob):**
- [ ] Refresh contacts (pull down or re-open)
- [ ] Alice should show "Last seen" instead of green dot
- [ ] Time should be recent (just now, 1m ago, etc.)

**On Device 1 (Alice):**
- [ ] Re-open app
- [ ] Login again as "Alice"

**On Device 2 (Bob):**
- [ ] Alice should show green dot again (online)

**✅ If status updates correctly → SUCCESS!**

### ✅ Test 5: Search Functionality

**On either device:**
- [ ] Open contacts screen
- [ ] Type user's name in search bar
- [ ] Results filter in real-time
- [ ] Can still call from search results

**✅ If search works → SUCCESS!**

### ✅ Test 6: Messaging Feature

**On Device 1 (Alice):**
- [ ] Tap search icon → Select "Bob"
- [ ] Chat screen opens
- [ ] Type a message: "Hello Bob!"
- [ ] Press send button
- [ ] Message appears in chat

**On Device 2 (Bob):**
- [ ] Message appears instantly in real-time
- [ ] Tap on Alice's chat in Chats tab
- [ ] Reply with: "Hi Alice!"
- [ ] Message shows ✓✓ (read receipt)

**Test media messages:**
- [ ] Send an image from gallery
- [ ] Image displays in chat with thumbnail
- [ ] Tap image to view full-screen

**✅ If messaging works with read receipts → SUCCESS!**

### ✅ Test 7: Status Feature (WhatsApp-like)

**On Device 1 (Alice) - Upload Text Status:**
- [ ] Go to Status tab (middle tab)
- [ ] Tap pencil FAB (small floating button)
- [ ] Type: "My first status!"
- [ ] Select a background color
- [ ] Tap send (bottom right)
- [ ] Status appears in "My Status" section

**On Device 1 (Alice) - Upload Image Status:**
- [ ] Tap camera FAB (larger floating button)
- [ ] Select "Gallery Photo"
- [ ] Choose an image from gallery
- [ ] Add caption: "Beautiful view 🌄"
- [ ] Tap send button (blue circle)
- [ ] Status uploads with progress indicator

**On Device 1 (Alice) - Upload Video Status:**
- [ ] Tap camera FAB
- [ ] Select "Gallery Video" or "Record Video"
- [ ] Choose/record a short video (max 30s)
- [ ] Add caption: "Check this out! 🎥"
- [ ] Tap send
- [ ] Video uploads (may take longer than image)

**On Device 2 (Bob) - View Statuses:**
- [ ] Go to Status tab
- [ ] See Alice's status in "Recent updates"
- [ ] Notice blue ring around Alice's avatar (unviewed)
- [ ] Tap on Alice's status
- [ ] Full-screen viewer opens with first status
- [ ] Progress bars at top show 3 statuses
- [ ] Tap right side or wait → Next status plays
- [ ] Tap left side → Previous status
- [ ] Long press → Pauses status
- [ ] Swipe down → Exits viewer
- [ ] Alice's ring turns grey (all viewed)

**On Device 1 (Alice) - Check Viewers:**
- [ ] Tap "My Status"
- [ ] See "1 view" or "Bob viewed"
- [ ] Swipe up or tap to see viewer list
- [ ] Bob's name appears in viewers

**Test Auto-Expiry:**
- [ ] Wait 24 hours (or manually test by changing device time)
- [ ] Status should auto-disappear
- [ ] Or check Firebase Firestore console for expiry logic

**✅ If all status types work with viewer → SUCCESS!**

## Common Issues & Fixes

### Issue 1: "Can't see other users"

**Checklist:**
- [ ] Both devices connected to internet
- [ ] Both users logged in successfully
- [ ] Check Firebase Console → Firestore → users collection
- [ ] Should see 2 documents (Alice and Bob)
- [ ] Each document should have `isOnline: true`

**Fix:**
```dart
// Check console logs for:
"User created/updated: [userId]"
"Online status updated for [userId]: true"
```

### Issue 2: "No push notification received"

**Checklist:**
- [ ] Check `service-account.json` is in `assets/` folder
- [ ] Verify FCM is enabled in Firebase
- [ ] Check both devices have internet
- [ ] Look for FCM token in Firestore

**Fix:**
```dart
// Check console logs for:
"FCM Token: [token]"
"Notification sent: 200" (HTTP status)
```

### Issue 3: "Call screen doesn't open"

**Checklist:**
- [ ] Agora App ID is correct in `agora_services.dart`
- [ ] Camera and microphone permissions granted
- [ ] Both devices on same Wi-Fi or have internet

**Fix:**
```dart
// Check console logs for:
"Local user joined channel: [channelId]"
"Remote user joined: [uid]"
```

### Issue 4: "Authentication failed"

**For Phone Auth:**
- [ ] Phone auth enabled in Firebase Console
- [ ] SHA-1 certificate added (Android)
- [ ] Push notifications enabled (iOS)

**For Guest Auth:**
- [ ] Anonymous auth enabled in Firebase Console
- [ ] Should work immediately

### Issue 5: "Black screen during call"

**Checklist:**
- [ ] Camera permission granted
- [ ] Check Settings → App → Permissions
- [ ] Try switching camera during call

**Fix:**
```dart
// Manually request permissions
Settings → Apps → GupShupGo → Permissions → 
  ✓ Camera
  ✓ Microphone
```

## Verification Commands

### Check Firebase Project
```bash
# In terminal
firebase projects:list

# Should show your project
```

### Check Firestore Users
```javascript
// In Firebase Console → Firestore
users collection should have:
- 2+ documents
- Each with isOnline field
- Each with fcmToken field
```

### Check Console Logs
```bash
# Look for these in Flutter console:
✓ "App initialized for user: [name]"
✓ "FCM Token: [token]"
✓ "Online status updated"
✓ "Local user joined channel"
✓ "Remote user joined: [uid]"
```

## Performance Check

### Expected Behavior
- [ ] App launches < 3 seconds
- [ ] Login completes < 2 seconds
- [ ] Contacts load < 1 second
- [ ] Call connects < 5 seconds
- [ ] Video smooth (>15 FPS)
- [ ] Audio clear (no echo/lag)

### If Performance Poor
- [ ] Check internet speed (need >1 Mbps)
- [ ] Close other apps
- [ ] Restart devices
- [ ] Try different Wi-Fi network

## Production Readiness

### Before Publishing

**Required:**
- [ ] Test on real devices (not just emulators)
- [ ] Test with poor network conditions
- [ ] Test with multiple users (3+)
- [ ] Verify Firestore rules are restrictive
- [ ] Enable Agora token authentication
- [ ] Add privacy policy
- [ ] Add terms of service

**Recommended:**
- [ ] Add crash reporting (Firebase Crashlytics)
- [ ] Add analytics (Firebase Analytics)
- [ ] Add rate limiting
- [ ] Implement user blocking
- [ ] Add report user feature
- [ ] Create app icon
- [ ] Create splash screen

## Final Verification

### Everything Working If:

✅ **Registration:**
- Users can sign up (phone or guest)
- User appears in Firestore
- FCM token saved

✅ **Discovery:**
- Users can see each other
- Online status updates
- Search works

✅ **Calling:**
- Can initiate call
- Notification received
- Video connects
- Audio works
- Controls work

✅ **Stability:**
- No crashes
- No memory leaks
- Good performance
- Handles errors gracefully

## Success! 🎉

If all checks pass:
- ✅ Your app is ready for testing
- ✅ Can demo to others
- ✅ Ready for beta release

## Next Steps

1. **Test with real users**
   - Share APK with friends
   - Get feedback
   - Fix issues

2. **Add features**
   - Group calls
   - Chat messages
   - Status updates
   - Profile pictures

3. **Optimize**
   - Improve performance
   - Reduce bandwidth
   - Better error handling

4. **Publish**
   - Google Play Store
   - Apple App Store

---

## Quick Test Script

**Run this exact sequence to verify everything:**

```
1. Device 1: Open app → Guest login → Name: "Test1" → ✓
2. Device 2: Open app → Guest login → Name: "Test2" → ✓
3. Device 1: Tap search → See "Test2" with green dot → ✓
4. Device 1: Tap video icon next to Test2 → ✓
5. Device 2: Call screen opens → See "Test1" calling → ✓
6. Wait 5 seconds → Both videos visible → ✓
7. Test all call controls → All work → ✓
8. End call → Returns to home → ✓
9. Device 1: Close app → ✓
10. Device 2: Refresh → Test1 shows "Last seen" → ✓
```

**If all 10 steps work → YOU'RE DONE! 🎊**

---

Need help? Check the other documentation files:
- **QUICK_START.md** - Getting started guide
- **IMPLEMENTATION_GUIDE.md** - Technical details
- **TROUBLESHOOTING.md** - Common issues
- **ARCHITECTURE.md** - System design

**Happy calling! 📞**
