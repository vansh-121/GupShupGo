# Firebase Firestore Setup Instructions

## Required Firestore Security Rules

Copy and paste these rules into Firebase Console:

**Firebase Console → Firestore Database → Rules**

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection - allows authenticated users to read all profiles
    // but only write their own
    match /users/{userId} {
      // Anyone authenticated can read user profiles
      allow read: if request.auth != null;
      
      // Users can only update their own profile
      allow write: if request.auth != null && request.auth.uid == userId;
      
      // Allow creating new user profiles during signup
      allow create: if request.auth != null && request.auth.uid == userId;
    }
    
    // Optional: Messages collection for chat functionality
    match /messages/{messageId} {
      allow read, write: if request.auth != null;
    }
    
    // Optional: Call logs collection
    match /callLogs/{logId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Firestore Database Structure

Your app will create this structure automatically:

```
Firestore Database
│
└── users (collection)
    │
    ├── {userId_1} (document)
    │   ├── id: "userId_1"
    │   ├── name: "Alice"
    │   ├── phoneNumber: "+1234567890"
    │   ├── email: "alice@example.com" (optional)
    │   ├── photoUrl: "https://..." (optional)
    │   ├── fcmToken: "fcm_token_here"
    │   ├── isOnline: true
    │   ├── lastSeen: 1234567890 (timestamp)
    │   └── createdAt: 1234567890 (timestamp)
    │
    ├── {userId_2} (document)
    │   ├── id: "userId_2"
    │   ├── name: "Bob"
    │   └── ... (same fields)
    │
    └── ... (more users)
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
