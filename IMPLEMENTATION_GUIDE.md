# WhatsApp-Like Calling System Implementation

## Overview
Your GupShupGo app now supports calling **any user** who has the app installed, just like WhatsApp! No more limitations to just "user_a" and "user_b".

## 🎯 Key Features Implemented

### 1. **User Authentication**
- Phone number authentication with OTP verification
- Anonymous login option for testing
- Automatic user profile creation in Firestore

### 2. **Real-time User Management**
- All users stored in Firestore database
- Real-time online/offline status tracking
- Last seen timestamps
- User profile with name, phone, photo

### 3. **Contacts Discovery**
- View all users who have the app installed
- Search users by name or phone number
- See who's currently online
- Online users shown with green indicator

### 4. **Call Anyone Feature**
- Call any user from contacts list
- Push notifications for incoming calls
- Call history tracking
- Video/audio calling support

### 5. **Presence System**
- Automatic online status when app opens
- Automatic offline status when app closes
- Last seen time for offline users
- Real-time presence updates

## 📁 New Files Created

### Models
- `lib/models/user_model.dart` - User data model

### Services
- `lib/services/auth_service.dart` - Authentication logic
- `lib/services/user_service.dart` - User management & Firestore operations

### Screens
- `lib/screens/auth/phone_auth_screen.dart` - Login screen
- `lib/screens/contacts_screen.dart` - Browse and call users

### Updated Files
- `lib/main.dart` - Added authentication flow
- `lib/screens/home_screen.dart` - Real-time users instead of hardcoded
- `lib/screens/call_screen.dart` - Display caller/callee information

## 🚀 How It Works

### User Flow

1. **First Time User**
   ```
   Open App → Phone Auth Screen → Enter Phone & Name → Verify OTP → Home Screen
   ```

2. **Making a Call**
   ```
   Home Screen → Tap Search/Contact Icon → Browse Users → Tap Video Icon → Call Initiated
   ```

3. **Receiving a Call**
   ```
   Push Notification Received → Call Screen Opens Automatically → Accept/Decline
   ```

### Database Structure (Firestore)

```
users (collection)
  ├── {userId}
  │   ├── id: string
  │   ├── name: string
  │   ├── phoneNumber: string
  │   ├── email: string (optional)
  │   ├── photoUrl: string (optional)
  │   ├── fcmToken: string
  │   ├── isOnline: boolean
  │   ├── lastSeen: timestamp
  │   └── createdAt: timestamp
```

## 🔧 Setup Instructions

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Firebase Configuration
Ensure your Firebase project has:
- ✅ Firebase Authentication enabled
- ✅ Cloud Firestore enabled
- ✅ Firebase Cloud Messaging enabled
- ✅ Phone authentication enabled in Firebase Console

### 3. Firestore Security Rules
Add these rules to your Firestore:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      // Allow users to read any user profile
      allow read: if request.auth != null;
      
      // Allow users to write only their own profile
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 4. Run the App
```bash
flutter run
```

## 📱 Usage Guide

### For Testing Without Phone Auth
You can use **Anonymous Login** option on the auth screen:
1. Enter your name
2. Click "Continue as Guest"
3. You'll be assigned a unique ID

### Making Your First Call
1. **Create multiple test accounts** (use different devices or emulators)
2. Login on each device with different names
3. On Device 1: Tap search icon → See Device 2's user
4. Tap video camera icon next to their name
5. Device 2 receives push notification and call screen opens

### Contacts Screen Features
- **Search Bar**: Find users by name or phone
- **Online Indicator**: Green dot for online users
- **Video Icon**: Start video call
- **Message Icon**: Open chat
- **Sort**: Online users appear first

## 🔑 Key Code Components

### Authentication Service
```dart
// Sign in with phone
await authService.verifyPhoneNumber(phoneNumber: '+1234567890');
await authService.signInWithPhoneOTP(verificationId, otp, name);

// Sign in anonymously (testing)
await authService.signInAnonymously('Test User');
```

### User Service
```dart
// Get all users except current user
Stream<List<UserModel>> users = userService.getAllUsers(currentUserId);

// Search users
List<UserModel> results = await userService.searchUsers('John', currentUserId);

// Update online status
await userService.updateOnlineStatus(userId, true);
```

### Making a Call
```dart
String channelId = '${currentUserId}_${calleeId}_${timestamp}';

// Send notification
await fcmService.sendCallNotification(calleeId, currentUserId, channelId);

// Navigate to call screen
Navigator.push(context, MaterialPageRoute(
  builder: (_) => CallScreen(
    channelId: channelId,
    isCaller: true,
    calleeId: calleeId,
    calleeName: calleeName,
  ),
));
```

## 🎨 UI Components

### Home Screen Tabs
1. **Chats** - Recent conversations with users
2. **Status** - Coming soon
3. **Calls** - Call history with all users

### Contacts Screen
- Search bar at top
- Real-time user list with online status
- Quick call and message actions
- Automatic sorting (online first)

### Call Screen
- Full-screen remote video
- Picture-in-picture local video
- Mute, camera switch, video toggle controls
- End call button
- Caller name display

## 🔐 Security Features

- Firebase Authentication for user identity
- Firestore security rules prevent unauthorized access
- FCM tokens securely stored per user
- Channel IDs use unique timestamps to prevent collisions

## 🐛 Troubleshooting

### Issue: "No users appear in contacts"
**Solution**: Ensure multiple users are signed in from different devices/emulators

### Issue: "Call notification not received"
**Solution**: 
- Check FCM token is saved in Firestore
- Verify `service-account.json` is in assets folder
- Ensure both devices have internet connection

### Issue: "User shows as offline when they're online"
**Solution**: 
- App lifecycle observer automatically updates status
- Check Firestore rules allow status updates

### Issue: "Phone auth not working"
**Solution**:
- Enable Phone Authentication in Firebase Console
- Add SHA-1 certificate to Firebase project (Android)
- For iOS, enable push notifications

## 📊 Monitoring & Analytics

### Firestore Console
Monitor user registrations and online status:
```
Firebase Console → Firestore → users collection
```

### FCM Tokens
Check if FCM tokens are being saved:
```dart
users/{userId}/fcmToken
```

## 🚀 Production Considerations

### Before Releasing

1. **Token Server**: Implement Agora token generation server
   ```dart
   // Currently using empty token (testing only)
   // In production, generate tokens server-side
   ```

2. **Phone Auth Costs**: Firebase charges for phone authentication
   - Consider email auth as alternative
   - Implement rate limiting

3. **Scalability**:
   - Add pagination for user lists
   - Implement recent contacts vs all users
   - Cache user data locally

4. **Privacy**:
   - Add privacy settings (who can call me)
   - Block user functionality
   - Report user feature

## 🎯 Next Steps

### Recommended Enhancements

1. **Contact Sync** - Sync phone contacts who have the app
2. **User Profiles** - Add profile pictures, status messages
3. **Group Calls** - Support for multi-person video calls
4. **Call History** - Store and display past calls
5. **Favorite Contacts** - Pin frequently called users
6. **Do Not Disturb** - Mute notifications during certain times

## 📞 Support

For issues or questions:
1. Check Firestore for user data
2. Verify FCM setup in Firebase Console
3. Check device logs for error messages
4. Test with multiple devices/emulators

## ✅ Testing Checklist

- [ ] User registration works
- [ ] Multiple users can sign in
- [ ] Users appear in contacts list
- [ ] Online status updates correctly
- [ ] Search finds users by name
- [ ] Video call initiates
- [ ] Push notification received
- [ ] Call connects successfully
- [ ] Audio/video works both ways
- [ ] End call works properly
- [ ] Offline status updates when app closes

---

**Congratulations!** 🎉 Your app now has WhatsApp-like calling functionality where users can call anyone who has the app installed!
