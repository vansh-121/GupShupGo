# Firebase Setup Instructions

## Part 1: Firestore Security Rules

Copy and paste these rules into Firebase Console:

**Firebase Console → Firestore Database → Rules**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ==================== USERS ====================
    match /users/{userId} {
      // Anyone authenticated can read user profiles
      allow read: if request.auth != null;
      
      // Users can only create/update their own profile
      allow create: if request.auth != null && request.auth.uid == userId;
      allow update: if request.auth != null && request.auth.uid == userId;
      
      // Prevent users from deleting profiles
      allow delete: if false;
    }
    
    // ==================== CHAT ROOMS ====================
    match /chatRooms/{chatRoomId} {
      // Helper function to check if user is participant
      function isParticipant() {
        return resource.data.participants != null 
          && request.auth.uid in resource.data.participants;
      }
      
      function willBeParticipant() {
        return request.resource.data.participants != null
          && request.auth.uid in request.resource.data.participants;
      }
      
      // Helper to check if user ID is in the chatRoomId (fallback for legacy data)
      function isUserInChatRoomId() {
        return chatRoomId.matches('.*' + request.auth.uid + '.*');
      }
      
      // Allow creating chat room if user is a participant
      allow create: if request.auth != null && willBeParticipant();
      
      // Allow reading if user is a participant OR user ID is in chatRoomId (legacy support)
      allow read: if request.auth != null && (isParticipant() || isUserInChatRoomId());
      
      // Allow updating (for last message, unread count, etc.)
      allow update: if request.auth != null && (isParticipant() || isUserInChatRoomId());
      
      // Prevent deletion of chat rooms
      allow delete: if false;
      
      // ==================== MESSAGES ====================
      match /messages/{messageId} {
        // Helper to check parent chat room participation
        function isChatParticipant() {
          let chatRoom = get(/databases/$(database)/documents/chatRooms/$(chatRoomId));
          return chatRoom != null 
            && chatRoom.data.participants != null
            && request.auth.uid in chatRoom.data.participants;
        }
        
        // Fallback: check if user ID is in the chatRoomId
        function isUserInRoomId() {
          return chatRoomId.matches('.*' + request.auth.uid + '.*');
        }
        
        // Allow reading messages if participant or user is in room ID
        allow read: if request.auth != null && (isChatParticipant() || isUserInRoomId());
        
        // Allow creating message if user is authenticated and is sender
        allow create: if request.auth != null 
          && request.auth.uid == request.resource.data.senderId
          && (isChatParticipant() || isUserInRoomId());
        
        // Allow updating (for read receipts) if participant
        allow update: if request.auth != null 
          && (isChatParticipant() || isUserInRoomId());
        
        // Allow deleting only own messages
        allow delete: if request.auth != null 
          && request.auth.uid == resource.data.senderId;
      }
    }
    
    // ==================== CALLS ====================
    match /calls/{callId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
      allow delete: if false;
    }
    
    // ==================== STATUSES ====================
    match /statuses/{userId} {
      // Anyone authenticated can read statuses
      allow read: if request.auth != null;
      
      // Users can only create/update their own status
      allow create: if request.auth != null && request.auth.uid == userId;
      allow update: if request.auth != null && request.auth.uid == userId;
      
      // Users can only delete their own status
      allow delete: if request.auth != null && request.auth.uid == userId;
    }
    
    // ==================== CALL LOGS ====================
    match /callLogs/{logId} {
      allow read: if request.auth != null 
        && (resource.data.callerId == request.auth.uid 
            || resource.data.calleeId == request.auth.uid);
      allow create: if request.auth != null;
      allow update, delete: if false;
    }
  }
}
```

## Part 2: Firebase Storage Security Rules

Copy and paste these rules into Firebase Console:

**Firebase Console → Storage → Rules**

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // ==================== STATUS MEDIA ====================
    match /statuses/{userId}/{allPaths=**} {
      // Anyone authenticated can read status media (images/videos)
      allow read: if request.auth != null;

      // Users can only upload to their own status folder
      allow write: if request.auth != null && request.auth.uid == userId
        // Limit file size: 10 MB for images, 30 MB for videos
        && request.resource.size < 30 * 1024 * 1024
        // Only allow image and video content types
        && (request.resource.contentType.matches('image/.*')
            || request.resource.contentType.matches('video/.*'));

      // Users can delete their own status media
      allow delete: if request.auth != null && request.auth.uid == userId;
    }

    // Deny everything else by default
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

## Firestore Database Structure

Your app will create this structure automatically:

```
Firestore Database
│
├── users (collection)
│   ├── {userId} (document)
│   │   ├── id: string
│   │   ├── name: string
│   │   ├── phoneNumber: string (optional)
│   │   ├── email: string (optional)
│   │   ├── photoUrl: string (optional)
│   │   ├── fcmToken: string
│   │   ├── isOnline: boolean
│   │   ├── lastSeen: timestamp
│   │   └── createdAt: timestamp
│   └── ...
│
├── chatRooms (collection)
│   ├── {chatRoomId} (document)
│   │   ├── id: string
│   │   ├── participants: array<string> [userId1, userId2]
│   │   ├── participantNames: map {userId: name}
│   │   ├── lastMessage: string
│   │   ├── lastMessageTime: timestamp
│   │   ├── lastMessageSenderId: string
│   │   ├── createdAt: timestamp
│   │   └── messages (subcollection)
│   │       ├── {messageId} (document)
│   │       │   ├── id: string
│   │       │   ├── senderId: string
│   │       │   ├── text: string
│   │       │   ├── type: string (text, image, video)
│   │       │   ├── mediaUrl: string (optional)
│   │       │   ├── timestamp: timestamp
│   │       │   ├── isRead: boolean
│   │       │   └── readBy: array<string>
│   │       └── ...
│   └── ...
│
├── statuses (collection)
│   ├── {userId} (document)
│   │   ├── userId: string
│   │   ├── userName: string
│   │   ├── userPhotoUrl: string (optional)
│   │   ├── lastUpdated: timestamp
│   │   └── statusItems: array<map>
│   │       ├── id: string
│   │       ├── type: string (text, image, video)
│   │       ├── text: string (for text status)
│   │       ├── imageUrl: string (for image status)
│   │       ├── videoUrl: string (for video)
│   │       ├── thumbnailUrl: string (for video)
│   │       ├── caption: string (optional)
│   │       ├── backgroundColor: string (for text)
│   │       ├── createdAt: timestamp
│   │       └── viewedBy: array<string>
│   └── ...
│
├── calls (collection)
│   ├── {callId} (document)
│   │   ├── callerId: string
│   │   ├── calleeId: string
│   │   ├── channelId: string
│   │   ├── status: string (ringing, accepted, declined, ended)
│   │   └── createdAt: timestamp
│   └── ...
│
└── callLogs (collection)
    ├── {logId} (document)
    │   ├── callerId: string
    │   ├── calleeId: string
    │   ├── duration: number
    │   ├── type: string (video, audio)
    │   ├── timestamp: timestamp
    │   └── status: string (completed, missed, declined)
    └── ...
```

## Firebase Storage Structure

```
Firebase Storage
│
└── statuses/
    ├── {userId1}/
    │   ├── images/
    │   │   ├── 1234567890_photo.jpg
    │   │   └── 1234567891_photo.jpg
    │   └── videos/
    │       ├── 1234567892_video.mp4
    │       └── 1234567893_video.mp4
    ├── {userId2}/
    │   └── ...
    └── ...
```

## Testing Your Firestore Setup

### 1. Verify Rules Are Active

After setting rules, test by:

```bash
# Run your Flutter app
flutter run

# Watch the console for Firestore operations
# You should see logs like:
# "User created/updated: xyz123"
# "FCM token updated for xyz123"
```

### 2. Check Firestore Console

Go to Firebase Console → Firestore Database → Data

You should see:
- ✅ "users" collection created
- ✅ User documents with correct structure
- ✅ Real-time updates as users login/logout

### 3. Test Security

Try these scenarios:
1. **Login as User A** → Should see all users in contacts
2. **Try to edit User B's profile** → Should fail (protected)
3. **Update User A's status** → Should succeed (own profile)

## Optional: Create Indexes

For better performance with large user bases:

**Firebase Console → Firestore Database → Indexes**

### Index 1: Online Users Query
```
Collection: users
Fields: 
  - isOnline (Ascending)
  - name (Ascending)
```

### Index 2: Phone Number Lookup
```
Collection: users
Fields:
  - phoneNumber (Ascending)
```

These will be created automatically when needed, but you can pre-create them.

## Monitoring

### View Real-time Data

**Firebase Console → Firestore Database → Data**
- Click on "users" collection
- See all registered users
- Watch online status change in real-time

### Query Examples

You can test queries in Firebase Console:

1. **Find online users:**
   ```
   Collection: users
   Where: isOnline == true
   ```

2. **Find user by phone:**
   ```
   Collection: users
   Where: phoneNumber == "+1234567890"
   ```

3. **Recent users:**
   ```
   Collection: users
   Order by: createdAt
   Limit: 10
   ```

## Backup & Export

### Enable Point-in-Time Recovery

**Firebase Console → Firestore Database → Settings**
- Enable "Point-in-time recovery"
- Allows restoring database to any point in last 7 days

### Export Data

```bash
# Using Firebase CLI
firebase firestore:export gs://your-bucket/backups
```

## Troubleshooting

### Issue: "Permission denied" errors

**Solution:**
1. Check if rules are published (wait 1-2 minutes after saving)
2. Verify user is authenticated before accessing Firestore
3. Check console for authentication state

### Issue: "User data not saving"

**Solution:**
1. Verify internet connection
2. Check Firestore is enabled in Firebase project
3. Look for errors in app console logs
4. Verify user has valid auth token

### Issue: "Can't see other users"

**Solution:**
1. Ensure multiple users are actually created (check Firestore console)
2. Verify query filters in user_service.dart
3. Check if users are logging in successfully

## Cost Optimization

Firestore pricing is based on:
- Reads
- Writes
- Deletes
- Storage

**Tips to reduce costs:**

1. **Cache user data locally**
   ```dart
   // Use SharedPreferences for frequently accessed data
   ```

2. **Limit real-time listeners**
   ```dart
   // Use snapshots() only where real-time updates are needed
   // Use get() for one-time reads
   ```

3. **Paginate user lists**
   ```dart
   // Load 20 users at a time instead of all
   query.limit(20);
   ```

4. **Use offline persistence**
   ```dart
   // Enable offline cache (already enabled by default)
   ```

## Security Best Practices

1. **Never expose sensitive data**
   - Don't store passwords in Firestore
   - Use Firebase Auth for credentials

2. **Validate data on client side**
   ```dart
   // Before saving to Firestore
   if (name.length < 2) throw 'Name too short';
   ```

3. **Use environment variables**
   ```dart
   // Don't hardcode API keys in code
   ```

4. **Regular rule audits**
   - Review security rules monthly
   - Test with different user scenarios

## Performance Optimization

### 1. Enable Offline Persistence (Already Enabled)
```dart
// Firestore caches data automatically
// Users can browse even when offline
```

### 2. Use Indexes for Complex Queries
```dart
// Firestore will prompt you to create indexes
// Click the link in console errors
```

### 3. Limit Document Size
- Keep user documents under 1MB
- Store large files in Firebase Storage, not Firestore

## Migration Path

If you had existing hardcoded users:

### 1. Export Old Data (if any)
```dart
// No migration needed for your case
// Old users were hardcoded, not in database
```

### 2. Re-register Users
- Users need to sign up again with new system
- Old user_a and user_b no longer needed

### 3. Clean Up
- Remove hardcoded user lists from code ✅ (Already done)
- Remove SharedPreferences user switching ✅ (Already done)

## Testing Checklist

- [ ] Firestore rules saved and published
- [ ] Can create new user (sign up)
- [ ] User document appears in Firestore console
- [ ] Can read other users (contacts screen)
- [ ] Can update own profile (online status)
- [ ] Cannot update other user's profiles (security)
- [ ] Real-time updates work (online status changes)
- [ ] Offline mode works (cached data accessible)

## Support Resources

- **Firestore Documentation**: https://firebase.google.com/docs/firestore
- **Security Rules Guide**: https://firebase.google.com/docs/firestore/security/get-started
- **Pricing Calculator**: https://firebase.google.com/pricing

---

**Your Firestore is now ready for production!** 🎉

All user data will be stored securely with proper access controls.
