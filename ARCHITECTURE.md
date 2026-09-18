# System Architecture — GupShupGo

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         GUPSHUPGO APP                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐  │
│  │   Device 1   │      │   Device 2   │      │   Device N   │  │
│  │   (Alice)    │      │    (Bob)     │      │   (Charlie)  │  │
│  └──────┬───────┘      └──────┬───────┘      └──────┬───────┘  │
│         │                     │                      │           │
│         └─────────────────────┴──────────────────────┘           │
│                               │                                  │
└───────────────────────────────┼──────────────────────────────────┘
                                │
                ┌───────────────┴───────────────┐
                │                               │
        ┌───────▼────────┐             ┌───────▼────────┐
        │   Firebase     │             │     Agora      │
        │   Backend      │             │  Video/Audio   │
        └───────┬────────┘             └────────────────┘
                │
    ┌───────────┼───────────┐
    │           │           │
┌───▼───┐  ┌───▼───┐  ┌───▼────┐
│ Auth  │  │  FCM  │  │Firebase│
│       │  │       │  │  Store │
└───────┘  └───────┘  └────────┘
```

## 📊 Data Flow Diagrams

### 1. User Registration Flow

```
User Opens App
    │
    ▼
┌─────────────────┐
│ Auth Screen     │
│ - Phone Number  │
│ - Name          │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Firebase Auth   │
│ - Send OTP      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Verify OTP      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐      ┌─────────────────┐
│ Create User     ├─────>│  Firestore      │
│ - Generate UID  │      │  Save Profile   │
└────────┬────────┘      └─────────────────┘
         │
         ▼
┌─────────────────┐      ┌─────────────────┐
│ Setup FCM       ├─────>│  Firestore      │
│ - Get Token     │      │  Save Token     │
└────────┬────────┘      └─────────────────┘
         │
         ▼
┌─────────────────┐
│ Set Online      │
│ Status = true   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Home Screen     │
│ (User Ready)    │
└─────────────────┘
```

### 2. Making a Call Flow

```
Alice's Device                    Bob's Device
     │                                │
     │ 1. Tap Video Icon             │
     ▼                                │
┌─────────────────┐                  │
│ Generate        │                  │
│ Channel ID      │                  │
└────────┬────────┘                  │
         │                            │
         │ 2. Send Notification       │
         ├───────────────────────────>│
         │    (via FCM)               │
         │                            ▼
         │                   ┌─────────────────┐
         │                   │ Receive Push    │
         │                   │ Notification    │
         │                   └────────┬────────┘
         │                            │
         │                            ▼
         │                   ┌─────────────────┐
         │                   │ Open Call       │
         │                   │ Screen          │
         │                   └────────┬────────┘
         │                            │
         │ 3. Both Join Agora Channel │
         ├<───────────────────────────┤
         │       (Channel ID)         │
         ▼                            ▼
┌─────────────────┐         ┌─────────────────┐
│ Agora Engine    │◄───────►│ Agora Engine    │
│ (Alice's Stream)│         │ (Bob's Stream)  │
└─────────────────┘         └─────────────────┘
         │                            │
         └────────────────────────────┘
                    │
                    ▼
          ┌─────────────────┐
          │ Video Call      │
          │ Connected! 🎉   │
          └─────────────────┘
```

### 3. Real-time Presence System

```
App Lifecycle                     Firestore

App Opened
    │
    ▼
┌─────────────────┐
│ Set Online      │────────────>  isOnline: true
│ Status = true   │               lastSeen: now
└────────┬────────┘
         │
         │ User Active
         │ (using app)
         │
         ▼
┌─────────────────┐
│ App in          │────────────>  isOnline: false
│ Background      │               lastSeen: now
└────────┬────────┘
         │
         │ User Returns
         │
         ▼
┌─────────────────┐
│ App Resumed     │────────────>  isOnline: true
│                 │               lastSeen: now
└────────┬────────┘
         │
         │ User Closes App
         │
         ▼
┌─────────────────┐
│ App Closed      │────────────>  isOnline: false
│                 │               lastSeen: now
└─────────────────┘


Other Users See:
┌─────────────────────────────┐
│ Alice                       │
│ ● Online                    │  <- Green dot
└─────────────────────────────┘

OR

┌─────────────────────────────┐
│ Alice                       │
│ Last seen 5 minutes ago     │  <- Gray text
└─────────────────────────────┘
```

## 🔄 Component Interaction

### Service Layer Architecture

```
┌────────────────────────────────────────────────────────────┐
│                    Flutter App Layer                        │
├────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Auth Screen  │  │ Home Screen  │  │ Call Screen  │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                 │                  │              │
│         └─────────────────┴──────────────────┘              │
│                           │                                 │
├───────────────────────────┼─────────────────────────────────┤
│                    Service Layer                            │
├───────────────────────────┼─────────────────────────────────┤
│                           │                                 │
│    ┌──────────────────────┴──────────────────────┐         │
│    │                                              │         │
│    ▼                  ▼                  ▼                  │
│ ┌──────┐         ┌────────┐        ┌─────────┐            │
│ │ Auth │         │  User  │        │   FCM   │            │
│ │Service│        │Service │        │ Service │            │
│ └──┬───┘         └───┬────┘        └────┬────┘            │
│    │                 │                   │                 │
│    └─────────────────┴───────────────────┘                 │
│                      │                                     │
├──────────────────────┼─────────────────────────────────────┤
│                Firebase Backend                            │
├──────────────────────┼─────────────────────────────────────┤
│                      │                                     │
│     ┌────────────────┼────────────────┐                   │
│     │                │                │                   │
│     ▼                ▼                ▼                   │
│ ┌────────┐     ┌──────────┐     ┌────────┐              │
│ │Firebase│     │Firestore │     │  FCM   │              │
│ │  Auth  │     │ Database │     │        │              │
│ └────────┘     └──────────┘     └────────┘              │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

## 🗂️ Database Schema

### Firestore Collections

```
┌─────────────────────────────────────────┐
│            users Collection              │
├─────────────────────────────────────────┤
│                                          │
│  Document ID: {userId}                   │
│  ┌────────────────────────────────────┐ │
│  │ Fields:                            │ │
│  │                                    │ │
│  │  id: string (primary key)         │ │
│  │  name: string                     │ │
│  │  phoneNumber: string (optional)   │ │
│  │  email: string (optional)         │ │
│  │  photoUrl: string (optional)      │ │
│  │  fcmToken: string                 │ │
│  │  isOnline: boolean                │ │
│  │  lastSeen: timestamp              │ │
│  │  createdAt: timestamp             │ │
│  │                                    │ │
│  └────────────────────────────────────┘ │
│                                          │
│  Indexes:                                │
│  - phoneNumber (for lookup)              │
│  - isOnline (for filtering)              │
│  - createdAt (for sorting)               │
│                                          │
└─────────────────────────────────────────┘
```

## 🔐 Security Layer

```
┌─────────────────────────────────────────┐
│         Security Architecture            │
├─────────────────────────────────────────┤
│                                          │
│  Client Side (Flutter)                   │
│  ┌────────────────────────────────────┐ │
│  │ 1. Firebase Auth                   │ │
│  │    - User authenticated            │ │
│  │    - Auth token generated          │ │
│  └────────────────────────────────────┘ │
│                  │                       │
│                  ▼                       │
│  ┌────────────────────────────────────┐ │
│  │ 2. Every Request                   │ │
│  │    - Includes auth token           │ │
│  │    - Validated by Firebase         │ │
│  └────────────────────────────────────┘ │
│                  │                       │
│                  ▼                       │
│  ┌────────────────────────────────────┐ │
│  │ 3. Firestore Rules                │ │
│  │    - Check auth.uid                │ │
│  │    - Verify permissions            │ │
│  │    - Allow/Deny access             │ │
│  └────────────────────────────────────┘ │
│                  │                       │
│                  ▼                       │
│  ┌────────────────────────────────────┐ │
│  │ 4. Data Access                     │ │
│  │    ✅ Can read all users           │ │
│  │    ✅ Can write own profile        │ │
│  │    ❌ Cannot write others' data    │ │
│  └────────────────────────────────────┘ │
│                                          │
└─────────────────────────────────────────┘
```

## 📱 Screen Navigation Flow

```
┌─────────────────┐
│  App Launch     │
└────────┬────────┘
         │
         ▼
    ┌────────┐
    │Logged? │
    └───┬────┘
        │
  ┌─────┴─────┐
  │           │
  No          Yes
  │           │
  ▼           ▼
┌──────────┐  ┌──────────┐
│  Phone   │  │   Home   │
│  Auth    │  │  Screen  │
│  Screen  │  └────┬─────┘
└────┬─────┘       │
     │             │
     │ Login       │
     │             │
     └─────────────┤
                   │
         ┌─────────┴─────────┐
         │                   │
         ▼                   ▼
    ┌─────────┐         ┌─────────┐
    │ Chats   │         │ Calls   │
    │  Tab    │         │  Tab    │
    └────┬────┘         └────┬────┘
         │                   │
         ▼                   ▼
    ┌─────────┐         ┌─────────┐
    │ Search  │         │Call User│
    │ Button  │         │         │
    └────┬────┘         └────┬────┘
         │                   │
         └────────┬──────────┘
                  │
                  ▼
         ┌────────────────┐
         │   Contacts     │
         │    Screen      │
         └────────┬───────┘
                  │
       ┌──────────┴──────────┐
       │                     │
       ▼                     ▼
  ┌─────────┐          ┌─────────┐
  │  Chat   │          │  Call   │
  │ Screen  │          │ Screen  │
  └─────────┘          └─────────┘
```

## 🔔 Push Notification Flow

```
Caller Device                    FCM Server                 Callee Device
     │                               │                           │
     │ 1. Initiate Call              │                           │
     ├──────────────────────────────>│                           │
     │   sendCallNotification()      │                           │
     │   - calleeId                  │                           │
     │   - callerId                  │                           │
     │   - channelId                 │                           │
     │                               │                           │
     │                               │ 2. Push Notification      │
     │                               ├──────────────────────────>│
     │                               │   To: fcmToken            │
     │                               │   Data:                   │
     │                               │   - callerId              │
     │                               │   - channelId             │
     │                               │                           │
     │                               │                           │
     │                               │                      ┌────┴────┐
     │                               │                      │ Receive │
     │                               │                      │ & Parse │
     │                               │                      └────┬────┘
     │                               │                           │
     │                               │                           ▼
     │                               │                    ┌─────────────┐
     │                               │                    │ Open Call   │
     │                               │                    │ Screen      │
     │                               │                    └─────────────┘
     │                               │                           │
     │   3. Both join Agora channel                              │
     ├<──────────────────────────────────────────────────────────┤
     │                Channel ID: xyz123                         │
     │                                                           │
     ▼                                                           ▼
┌─────────┐                                                 ┌─────────┐
│ Caller  │◄───────────────────────────────────────────────►│ Callee  │
│ Stream  │              Agora RTC Connection               │ Stream  │
└─────────┘                                                 └─────────┘
```

## 📊 State Management

```
┌──────────────────────────────────────────────┐
│         Provider Pattern                      │
├──────────────────────────────────────────────┤
│                                               │
│  ┌────────────────────────────────────────┐  │
│  │  CallStateNotifier                    │  │
│  │  (extends ChangeNotifier)             │  │
│  ├────────────────────────────────────────┤  │
│  │                                        │  │
│  │  States:                               │  │
│  │  - Idle                                │  │
│  │  - Ringing                             │  │
│  │  - Connected                           │  │
│  │  - Ended                               │  │
│  │                                        │  │
│  │  Methods:                              │  │
│  │  - updateState(CallState)              │  │
│  │  - notifyListeners()                   │  │
│  │                                        │  │
│  └────────────────────────────────────────┘  │
│                    │                          │
│                    │                          │
│       ┌────────────┴────────────┐             │
│       │                         │             │
│       ▼                         ▼             │
│  ┌─────────┐              ┌─────────┐        │
│  │  Home   │              │  Call   │        │
│  │ Screen  │              │ Screen  │        │
│  └─────────┘              └─────────┘        │
│  Consumer<>               Consumer<>         │
│                                               │
└──────────────────────────────────────────────┘
```

## 🎯 Key Advantages of This Architecture

1. **Scalable**: Can handle unlimited users
2. **Real-time**: Instant updates using Firestore streams
3. **Secure**: Firebase Auth + Firestore Rules
4. **Reliable**: Firebase handles infrastructure
5. **Cost-effective**: Pay only for what you use
6. **Maintainable**: Clean separation of concerns
7. **Testable**: Services can be mocked for testing

## 🔍 Monitoring Points

```
┌──────────────────────────────────────────┐
│      Monitoring & Analytics              │
├──────────────────────────────────────────┤
│                                          │
│  Firebase Console:                       │
│  ✓ Authentication (user count)           │
│  ✓ Firestore (read/write operations)     │
│  ✓ FCM (notifications sent/delivered)    │
│                                          │
│  App Logs:                               │
│  ✓ User registration events              │
│  ✓ Call initiation/completion            │
│  ✓ Online status changes                 │
│  ✓ Errors & exceptions                   │
│                                          │
└──────────────────────────────────────────┘
```

---

**This architecture supports:**
- ✅ Unlimited concurrent users
- ✅ Real-time presence updates
- ✅ Secure peer-to-peer calling
- ✅ Push notifications
- ✅ Offline capability
- ✅ Scalable to millions of users
- ✅ WhatsApp-like status with text, images, and videos

---

## 📸 Status Feature Architecture

### Status System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Status Feature Flow                       │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  User A                      Firebase                        │
│  ┌──────────┐                                                │
│  │  Upload  │                                                │
│  │  Status  │                                                │
│  └────┬─────┘                                                │
│       │                                                      │
│       ├────> Text Status ──────> Firestore                  │
│       │      └─ Store metadata                              │
│       │                                                      │
│       ├────> Image Status ────> Firebase Storage            │
│       │      └─ Upload file                                 │
│       │      └─ Store URL in Firestore                      │
│       │                                                      │
│       └────> Video Status ────> Firebase Storage            │
│              └─ Upload file                                 │
│              └─ Store URL in Firestore                      │
│                                                              │
│                      │                                       │
│                      ▼                                       │
│              ┌────────────────┐                             │
│              │  All Users     │                             │
│              │  See Status    │                             │
│              │  (24h expiry)  │                             │
│              └────────────────┘                             │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### Status Upload Flow (Image/Video)

```
Mobile Device                Firebase Storage           Firestore

    │
    │ 1. User picks media
    ▼
┌─────────────┐
│ Image Picker│
│ or Camera   │
└──────┬──────┘
       │
       │ 2. File selected
       ▼
┌─────────────┐
│ Preview     │
│ + Caption   │
└──────┬──────┘
       │
       │ 3. User taps Send
       ▼
┌─────────────┐
│ Start Upload│───────────> ┌──────────────┐
└─────────────┘             │ Upload File  │
                            │ to Storage   │
                            └──────┬───────┘
                                   │
                      4. Get Download URL
                                   │
                                   ▼
                            ┌──────────────┐
                            │ Return URL   │
                            └──────┬───────┘
                                   │
       ┌───────────────────────────┘
       │
       │ 5. Save metadata
       └──────────────> ┌────────────────┐
                        │ Create Status  │
                        │ Document:      │
                        │ - type: "image"│
                        │ - imageUrl     │
                        │ - caption      │
                        │ - timestamp    │
                        │ - viewedBy: [] │
                        └────────────────┘
                                │
       ┌────────────────────────┘
       │ 6. Real-time stream
       ▼
┌─────────────┐
│ All Users   │
│ See Status  │
│ Instantly   │
└─────────────┘
```

### Status Viewer Flow

```
User Opens Status               Firestore                 Display

    │
    ▼
┌─────────────────┐
│ Load Status     │────────────> ┌────────────────┐
│ for User X      │               │ Get StatusModel│
└─────────────────┘               │ with items     │
                                  └────────┬───────┘
                                           │
                           ┌───────────────┴───────────────┐
                           │                               │
                           ▼                               ▼
                    ┌──────────┐                   ┌──────────┐
                    │   Text   │                   │  Media   │
                    │  Status  │                   │  Status  │
                    └────┬─────┘                   └────┬─────┘
                         │                              │
                         │                              ├──> Load from URL
                         │                              │
                         └──────────┬───────────────────┘
                                    │
                                    ▼
                         ┌────────────────────┐
                         │ Display Full-screen│
                         │ - Progress bars    │
                         │ - Tap to navigate  │
                         │ - Swipe to exit    │
                         └──────────┬─────────┘
                                    │
                         User Views Status
                                    │
                                    ▼
                         ┌────────────────────┐
                         │ Mark as Viewed     │─────> Update viewedBy[]
                         │ Add currentUserId  │       in Firestore
                         └────────────────────┘
```

### Status Data Model

```
┌─────────────────────────────────────────────────────┐
│            Firestore: statuses Collection            │
├─────────────────────────────────────────────────────┤
│                                                       │
│  Document ID: {userId}                                │
│  ┌─────────────────────────────────────────────────┐│
│  │ StatusModel                                      ││
│  │                                                   ││
│  │  userId: string                                  ││
│  │  userName: string                                ││
│  │  userPhotoUrl: string?                           ││
│  │  lastUpdated: timestamp                          ││
│  │                                                   ││
│  │  statusItems: [                                  ││
│  │    {                                             ││
│  │      id: string                                  ││
│  │      type: "text" | "image" | "video"            ││
│  │      text: string? (for text status)             ││
│  │      imageUrl: string? (for image status)        ││
│  │      videoUrl: string? (for video status)        ││
│  │      thumbnailUrl: string? (for video)           ││
│  │      caption: string?                            ││
│  │      backgroundColor: string? (for text)         ││
│  │      createdAt: timestamp                        ││
│  │      viewedBy: [userId1, userId2, ...]          ││
│  │    },                                            ││
│  │    ... more status items                         ││
│  │  ]                                               ││
│  │                                                   ││
│  └─────────────────────────────────────────────────┘│
│                                                       │
│  Auto-cleanup: Items older than 24h are filtered     │
│                                                       │
└─────────────────────────────────────────────────────┘
```

### Firebase Storage Structure

```
Firebase Storage
│
└── statuses/
    │
    ├── {userId1}/
    │   ├── images/
    │   │   ├── 1234567890_photo.jpg
    │   │   └── 1234567891_photo.jpg
    │   │
    │   └── videos/
    │       ├── 1234567892_video.mp4
    │       └── 1234567893_video.mp4
    │
    ├── {userId2}/
    │   └── ...
    │
    └── ...

Security Rules:
- Users can only upload to their own folder
- Anyone authenticated can read (view statuses)
- Max size: 30 MB per file
- Allowed types: image/*, video/*
```

### Status Security Rules

**Firestore Rules:**
```javascript
match /statuses/{userId} {
  // Anyone authenticated can read statuses
  allow read: if request.auth != null;
  
  // Users can only create/update their own status
  allow create, update: if request.auth != null 
                        && request.auth.uid == userId;
  
  // Users can delete their own status
  allow delete: if request.auth != null 
                && request.auth.uid == userId;
}
```

**Storage Rules:**
```javascript
match /statuses/{userId}/{allPaths=**} {
  // Anyone authenticated can read
  allow read: if request.auth != null;
  
  // Users can only upload to their own folder
  allow write: if request.auth != null 
               && request.auth.uid == userId
               && request.resource.size < 30 * 1024 * 1024
               && (request.resource.contentType.matches('image/.*')
                   || request.resource.contentType.matches('video/.*'));
  
  // Users can delete their own media
  allow delete: if request.auth != null 
                && request.auth.uid == userId;
}
```

### Status Provider (State Management)

```
┌──────────────────────────────────────────────┐
│         StatusProvider Pattern               │
├──────────────────────────────────────────────┤
│                                               │
│  ┌────────────────────────────────────────┐  │
│  │  StatusProvider                        │  │
│  │  (extends ChangeNotifier)             │  │
│  ├────────────────────────────────────────┤  │
│  │                                        │  │
│  │  State:                                │  │
│  │  - myStatus: StatusModel?              │  │
│  │  - otherStatuses: List<StatusModel>    │  │
│  │  - isLoading: bool                     │  │
│  │                                        │  │
│  │  Streams:                              │  │
│  │  - _myStatusSubscription               │  │
│  │  - _otherStatusesSubscription          │  │
│  │                                        │  │
│  │  Methods:                              │  │
│  │  - initialize(userId)                  │  │
│  │  - uploadTextStatus(...)               │  │
│  │  - uploadImageStatus(...)              │  │
│  │  - uploadVideoStatus(...)              │  │
│  │  - markAsViewed(...)                   │  │
│  │                                        │  │
│  └────────────────────────────────────────┘  │
│                    │                          │
│       ┌────────────┼────────────┐             │
│       │            │            │             │
│       ▼            ▼            ▼             │
│  ┌─────────┐ ┌──────────┐ ┌──────────┐      │
│  │  Home   │ │  Status  │ │  Viewer  │      │
│  │ Screen  │ │  Add     │ │  Screen  │      │
│  └─────────┘ └──────────┘ └──────────┘      │
│  Consumer<>   Consumer<>    Consumer<>       │
│                                               │
└──────────────────────────────────────────────┘
```

### Performance Optimizations


## ☁️ Cloud Functions Architecture

FCM notifications are sent **server-side** via Firebase Cloud Functions — no service account is bundled in the client app.

### Notification Flow (Calls)

```
Caller Device                Cloud Function              Callee Device
     │                            │                           │
     │ 1. POST /sendCallNotif     │                           │
     │   + Bearer <ID Token>      │                           │
     ├───────────────────────────>│                           │
     │                            │ 2. Verify ID token        │
     │                            │    Fetch callee fcmToken  │
     │                            │    Fetch caller name/photo│
     │                            │                           │
     │                            │ 3. Send DATA-ONLY FCM     │
     │                            ├──────────────────────────>│
     │                            │   (no "notification" key) │
     │                            │                           │
     │                            │                      ┌────┴────┐
     │                            │                      │ CallKit │
     │                            │                      │ shows   │
     │                            │                      │ native  │
     │                            │                      │ call UI │
     │                            │                      └─────────┘
```

> **Key design decision:** Call notifications use DATA-ONLY messages
> (no `notification` block). This ensures the Dart background handler
> fires on every app state (foreground, background, killed), allowing
> CallKit to show the native full-screen call UI.

### Notification Flow (Messages)

```
Sender Device                Cloud Function              Receiver Device
     │                            │                           │
     │ POST /sendMessageNotif     │                           │
     │  + Bearer <ID Token>       │                           │
     ├───────────────────────────>│                           │
     │                            │ Verify token              │
     │                            │ Fetch receiver fcmToken   │
     │                            │                           │
     │                            │ Send FCM with             │
     │                            │ notification + data       │
     │                            ├──────────────────────────>│
     │                            │                           │
     │                            │                      System tray
     │                            │                      notification
```

---

## 🎙️ Voice Messaging Architecture

### Voice Message Flow

```
Sender Device                 Firebase                     Receiver Device
     │                           │                              │
     │ 1. Start Recording        │                              │
     ├─> AudioRecorder.start()   │                              │
     │   (platform specific)     │                              │
     │                           │                              │
     │ 2. User stops recording   │                              │
     ├─> AudioRecorder.stop()    │                              │
     │   Save to temp file       │                              │
     │                           │                              │
     │ 3. Upload audio file      │                              │
     ├──────────────────────────>│ Firebase Storage             │
     │   /messages/{uid}/*       │                              │
     │                           │                              │
     │ 4. Create message doc     │                              │
     ├──────────────────────────>│ Firestore                    │
     │   - type: "voice"         │                              │
     │   - audioUrl: <URL>       │                              │
     │   - duration: ms          │                              │
     │   - timestamp: now        │                              │
     │   - senderId: uid         │                              │
     │                           │                              │
     │                           │ 5. Real-time update          │
     │                           ├─────────────────────────────>│
     │                           │                              │
     │                           │                      6. Download
     │                           │                         & Play
     │                           │                              │
     │                           │<─────────────────────────────┤
     │                           │    FCM: "New message"        │
     │                           │                              │
     │                           │    Display in chat           │
     │                           │    + Play button             │
     │                           │                              │
     │                           │ 7. User plays audio
     │                           │                              │
     │                           │<─────────────────────────────┤
     │                           │    AudioPlayer.play(url)     │
     │                           │    (platform native)         │
     │                           │                              │
```

### Voice Message Data Model

```
Message Document (Firestore)
├── id: string
├── senderId: string
├── receiverId: string
├── type: "voice" (enum)
├── audioUrl: string
├── duration: int (milliseconds)
├── fileName: string
├── timestamp: Timestamp
├── isRead: boolean
├── readAt: Timestamp? (optional)
└── deletedBy: [string] (optional)

Firebase Storage Path:
/messages/{senderId}/{timestamp}_{randomId}.m4a
```

### Audio Recording Configuration

```
Platform Specific Handlers:

Android (android.media.MediaRecorder):
├── Audio Source: MIC
├── Output Format: THREE_GPP or MPEG_4
├── Audio Encoder: AMR_NB or AAC
├── Sample Rate: 44100 Hz
├── Bit Rate: 128000 bps
└── Channels: MONO

iOS (AVAudioRecorder):
├── Audio Format: m4a
├── Sample Rate: 44100 Hz
├── Bit Rate: 128000 bps
├── Channels: 1 (mono)
└── Quality: High
```

---

## 🌐 Mesh Networking Architecture

### Offline P2P Messaging with Nearby Connections

```
Device A                  Bluetooth/WiFi Direct               Device B
  │                                                              │
  │ 1. App goes offline                                          │
  ├─> MeshService.startAdvertising()                             │
  │   (Nearby Connections API)                                   │
  │                                                              │
  │ 2. Device B detects Device A                                │
  │<──────────────────────────────────────────────────────────┤
  │   Nearby Connections: Discovery                            │
  │                                                              │
  │ 3. Device B initiates connection                             │
  ├<─────────────────────────────────────────────────────────┤
  │   MeshService.connectToPeer()                             │
  │                                                              │
  │ 4. Connection established                                    │
  │<────────────────────────────────────────────────────────>│
  │   P2P Connection Ready                                      │
  │                                                              │
  │ 5. User sends message                                        │
  ├─> MeshService.sendMessage(payload)                          │
  │                                                              │
  │ 6. Message transmitted via BLE/WiFi                         │
  ├──────────────────────────────────────────────────────────>│
  │                                              MeshService
  │                                              receives msg
  │                                                  │
  │                                                  ▼
  │                                         Message stored
  │                                         locally +
  │                                         synced to
  │                                         Firestore
  │                                         when online
  │
```

### Mesh Service Architecture

```
┌─────────────────────────────────────────────┐
│        MeshNetworkService (Singleton)        │
├─────────────────────────────────────────────┤
│                                              │
│  State:                                      │
│  ├── isMeshEnabled: bool                     │
│  ├── connectedPeers: List<PeerInfo>          │
│  ├── pendingMessages: Queue<MessageModel>    │
│  └── isConnected: bool                       │
│                                              │
│  Methods:                                    │
│  ├── startAdvertising()                      │
│  ├── stopAdvertising()                       │
│  ├── connectToPeer(peerId)                   │
│  ├── sendMessage(MessageModel)               │
│  ├── receiveMessage()                        │
│  ├── syncToFirestore() [when online]         │
│  ├── handleConnectionFailure()               │
│  └── reconnect()                             │
│                                              │
│  Event Listeners:                            │
│  ├── onPeerDiscovered()                      │
│  ├── onConnectionEstablished()               │
│  ├── onMessageReceived()                     │
│  ├── onConnectionLost()                      │
│  └── onError()                               │
│                                              │
└─────────────────────────────────────────────┘
```

### Mesh Message Storage & Sync

```
Offline Scenario:

Device (Offline)
    │
    ├─> Send message via Mesh
    │   ├─ Store in local DB (Hive/SQLite)
    │   ├─ Add to syncQueue
    │   └─ Show as "sending via mesh"
    │
    └─> Connection restored
        │
        ├─> MeshNotificationListener detects
        │
        ├─> syncPendingMessages()
        │   ├─ Fetch from local DB
        │   ├─ Upload to Firestore
        │   └─ Mark as synced
        │
        └─> Real-time sync complete
            └─ Receiver sees message
```

### Nearby Connections Configuration

```
Android Manifest:
├── com.google.android.gms.nearby.connection.BLUETOOTH
├── com.google.android.gms.nearby.connection.BLUETOOTH_ADMIN
├── android.permission.ACCESS_FINE_LOCATION
├── android.permission.ACCESS_COARSE_LOCATION
└── android.permission.CHANGE_NETWORK_STATE

Strategy:
├── STRATEGY_P2P_POINT_TO_POINT
├── Payload encoding: JSON over bytes
├── Max message size: 4KB (typical for chat)
└── Connection timeout: 30 seconds

Data Format:
{
  "type": "message",
  "senderId": "uid",
  "senderName": "name",
  "messageId": "id",
  "text": "content",
  "timestamp": 1234567890,
  "mediaUrls": [] (synced later)
}
```

---

## 🌙 Theme & Dark Mode Architecture

### Theme Provider System

```
┌──────────────────────────────────────────────┐
│         ThemeProvider (ChangeNotifier)       │
├──────────────────────────────────────────────┤
│                                               │
│  State:                                       │
│  ├── isDarkMode: bool                         │
│  ├── currentThemeData: ThemeData              │
│  └── accentColor: Color                       │
│                                               │
│  Methods:                                     │
│  ├── toggleTheme()                            │
│  ├── setDarkMode(bool)                        │
│  ├── getAppColors() -> AppThemeColors         │
│  ├── loadSavedTheme() (from SharedPrefs)      │
│  └── saveTheme(bool isDark)                   │
│                                               │
│  Persistence:                                 │
│  └── SharedPreferences: "isDarkMode"          │
│                                               │
│  Listeners:                                   │
│  └── All screens rebuild via Consumer<>      │
│                                               │
└──────────────────────────────────────────────┘
```

### Light & Dark Color Palette

```
Light Mode:
├── Primary: #7C3AED (purple)
├── Secondary: #EC4899 (pink)
├── Background: #FFFFFF (white)
├── Surface: #F3F4F6 (light gray)
├── Text: #1F2937 (dark gray)
└── Divider: #E5E7EB (light gray)

Dark Mode:
├── Primary: #A78BFA (light purple)
├── Secondary: #F472B6 (light pink)
├── Background: #111827 (very dark gray)
├── Surface: #1F2937 (dark gray)
├── Text: #F3F4F6 (light gray)
└── Divider: #374151 (gray)
```

### Theme Application Flow

```
App Launch
    │
    ├─> Check SharedPreferences for saved theme
    │
    ├─> Load theme preference
    │
    ├─> Create ThemeProvider with initial state
    │
    ├─> MaterialApp receives:
    │   ├── theme: ThemeData (light)
    │   ├── darkTheme: ThemeData (dark)
    │   └── themeMode: system/light/dark
    │
    ├─> MultiProvider wraps app
    │   └── Consumer<ThemeProvider> in every screen
    │
    ├─> Settings Screen → Theme Toggle
    │   └── onThemeChanged()
    │       ├─ Update Provider state
    │       ├─ Rebuild affected screens
    │       └─ Save preference
    │
    └─> Theme applied throughout app
        ├── Text colors updated
        ├── Background colors updated
        ├── Icon colors updated
        └── Animations smooth
```

---

## 🔔 Mesh Notification Listener

### Auto-Sync Mechanism

```
App Running                  Connectivity Service

    │
    ├─> Monitor connectivity changes
    │
    ├─> OFFLINE detected
    │   └─ Switch to Mesh mode
    │
    ├─> ONLINE restored
    │   │
    │   ├─> MeshNotificationListener fires
    │   │
    │   ├─> Query pending mesh messages
    │   │   └─ Local database
    │   │
    │   ├─> Sync to Firestore
    │   │   ├─ Add timestamp
    │   │   ├─ Update message status
    │   │   └─ Notify sender (FCM)
    │   │
    │   ├─> Clear sync queue
    │   │
    │   └─> Update UI
    │       └─ Mark messages as "delivered"
    │
    └─> Connection handling
        ├─ Retry with exponential backoff
        ├─ Max 5 retries
        └─ Failure logged
```

### Error Handling & Recovery

```
Mesh Connection Error
    │
    ├─> Capture exception
    │
    ├─> Log to console/analytics
    │
    ├─> Exponential backoff:
    │   ├─ Attempt 1: wait 1s
    │   ├─ Attempt 2: wait 2s
    │   ├─ Attempt 3: wait 4s
    │   ├─ Attempt 4: wait 8s
    │   └─ Attempt 5: wait 16s
    │
    ├─> Success → Continue
    │
    ├─> All attempts fail
    │   └─ Store message locally
    │       └─ Sync when connection restored
    │
    └─> User notified
        └─ "Syncing messages..." toast
```



### Cold-Start Call Handling

```
User taps "Accept" on lock screen
     │
     ▼
┌─────────────────────┐
│ App process starts  │
│ (was killed)        │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ main() runs:        │
│ 1. Firebase init    │
│ 2. SharedPrefs init │
│ 3. CallKit listener │
│ 4. runApp()         │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ addPostFrameCallback│
│ checks activeCalls()│
└──────────┬──────────┘
           │
     ┌─────┴──────┐
     │            │
  No calls    Pending call
     │            │
     ▼            ▼
  Normal     ┌────────────────┐
  home       │ End CallKit    │
  screen     │ Navigate to    │
             │ CallScreen     │
             └────────────────┘
```

---

## ⚙️ Settings & Caching Architecture

### Settings Service (SharedPreferences)

```
┌────────────────────────────────────────────────────┐
│            SettingsService (Singleton)               │
├────────────────────────────────────────────────────┤
│                                                      │
│  Notification Prefs:          Privacy Prefs:         │
│  ├── messageNotifications     ├── showReadReceipts   │
│  ├── groupNotifications       └── showLastSeen       │
│  └── callNotifications                               │
│                                                      │
│  Muted Chats:                                        │
│  ├── mutedChatIds: Set<String>                       │
│  ├── isChatMuted(chatRoomId)                         │
│  ├── muteChat(chatRoomId)                            │
│  └── unmuteChat(chatRoomId)                          │
│                                                      │
│  Storage: SharedPreferences (survives app restarts)  │
└────────────────────────────────────────────────────┘
```

### Chat Cache Service

```
App Launch
    │
    ▼
┌───────────────────┐     ┌──────────────────┐
│ Load cached chat  │────>│ SharedPreferences │
│ rooms from disk   │     │ (JSON)            │
└────────┬──────────┘     └──────────────────┘
         │
         ▼
┌───────────────────┐
│ Render chat list  │  ← Instant, no network delay
│ immediately       │
└────────┬──────────┘
         │
         ▼  (async)
┌───────────────────┐     ┌──────────────────┐
│ Firestore stream  │────>│ Live data arrives │
│ starts            │     │ replaces cache    │
└───────────────────┘     └──────────────────┘

User Cache:
  _userCache: Map<String, UserModel>
  - Avoids N Firestore reads per frame
  - Persisted to SharedPreferences
  - Loaded from disk on startup
```

---

## � Device Session Service Architecture

### "Remember This Device" Feature (WhatsApp-Style)

The DeviceSessionService maintains a persistent device token in secure storage that survives:
- OS-level data wipes
- Force-stop and app data clearing
- Battery drains
- System crashes and reboots

```
User Logs In (First Time)
    │
    ├─> Firebase Auth succeeds
    │   └─ Get ID token
    │
    ├─> DeviceSessionService.issueToken()
    │   ├─ Send ID token to Cloud Function
    │   ├─ Cloud Function validates token
    │   └─ Returns persistent device token
    │
    ├─> Store token in secure storage
    │   └─ FlutterSecureStorage (Android Keystore)
    │
    └─> Login Complete ✅
        User is now "remembered" on this device


Session Resumed (Subsequent Launch)
    │
    ├─> Check if Firebase session exists
    │
    ├─> If expired/missing:
    │   │
    │   ├─> Retrieve device token from secure storage
    │   │
    │   ├─> Call DeviceSessionService.exchangeToken()
    │   │   ├─ Send device token to Cloud Function
    │   │   ├─ Cloud Function validates token
    │   │   └─ Returns new Firebase custom token
    │   │
    │   ├─> Sign in with custom token
    │   │   └─ Firebase creates new session
    │   │
    │   └─> User automatically logged in ✅
    │
    └─> If valid: Use existing session
```

### Secure Token Storage

```
Android Implementation:

┌────────────────────────────────────────┐
│   FlutterSecureStorage (config)        │
├────────────────────────────────────────┤
│                                         │
│  Storage Backend:                       │
│  └─ EncryptedSharedPreferences         │
│      └─ Android Keystore (hardware     │
│         backed when available)         │
│                                         │
│  Key: "gsg_device_session_token_v1"    │
│  Value: JWT-like token (encrypted)     │
│                                         │
│  Security:                              │
│  ✅ Persists across factory reset      │
│  ✅ Survives app uninstall/reinstall   │
│  ✅ Cannot be accessed by other apps   │
│  ✅ Expires after 30 days (server side)│
│                                         │
└────────────────────────────────────────┘
```

### Cloud Function Integration

```
issueToken() Flow:
  User signs in → ID token (expires 1 hour)
      │
      ├─> POST /issueDeviceSession
      │   ├─ Headers: Authorization: Bearer {idToken}
      │   │
      │   └─> Cloud Function:
      │       ├─ Verify ID token
      │       ├─ Extract user UID
      │       ├─ Generate device session token
      │       ├─ Store mapping: deviceToken → uid
      │       └─ Return token to app
      │
      └─> Store in secure storage (survives app closes)

exchangeToken() Flow:
  App launches (no Firebase session)
      │
      ├─> Read device token from storage
      │
      ├─> POST /exchangeDeviceSession
      │   ├─ Body: { deviceToken }
      │   │
      │   └─> Cloud Function:
      │       ├─ Verify device token validity
      │       ├─ Check expiry (30 days)
      │       ├─ Extract original UID
      │       ├─ Create Firebase custom token
      │       └─ Return custom token
      │
      ├─> Sign in with custom token
      │
      └─> User logged in automatically ✅
```

---

## 📞 Call Signaling Service Architecture

### Firestore-Based Call State Management

```
Caller Device                  Firestore                    Callee Device
     │                          docs                            │
     │ 1. Generate Channel ID   /calls/{channelId}              │
     ├─────────────────────────────────────────────────────────┤
     │                                                            │
     │ 2. Create document                                        │
     │    {                                                      │
     ├──────────────────> {                                      │
     │ status: "ringing",  callerId,                             │
     │ callerId,           calleeId,    ──────────────────────>│
     │ calleeId,           status: "ringing"                    │
     │ ...                 createdAt                            │
     │                  }                                        │
     │                                                            │
     │ 3. Send FCM Notification                                  │
     ├─────────────────────────────────────────────────────────>│
     │                                        Listen to call doc │
     │                                                 │          │
     │ 4. Open Call Screen                    ┌──────▼────┐     │
     ├──────────────────────────┐             │ Incoming  │     │
     │ Listen to document       │             │ Call UI   │     │
     │ Real-time updates        │             └──────┬────┘     │
     │                          │                    │          │
     │                          │          User taps: Accept    │
     │                          │                    │          │
     │                          │ 5. Update status  ▼          │
     │                          │    answered ──> Update doc   │
     │ Real-time update:        │                    │          │
     │ status = "answered"  <───┼────────────────────┤          │
     │              │           │                    │          │
     │              ▼           │                    ▼          │
     │ ┌──────────────────┐    │ ┌──────────────────┐          │
     │ │ Show video feed  │    │ │ Show video feed  │          │
     │ │ Both join Agora  │    │ │ Both join Agora  │          │
     │ └──────────────────┘    │ └──────────────────┘          │
     │            │             │            │                  │
     │            │ Talking... (RTC)        │                  │
     │            │<──────────────────────>│                  │
     │            │                         │                  │
     │ 6. End call                          │                  │
     │ Tap end button                       │                  │
     │              │                       │                  │
     │              ├──> Update status: "ended"               │
     │              │         │                              │
     │              └─────────┼─────────────────────────────>│
     │                        │                    Screen ends
```

### Call Status State Machine

```
                    ┌──────────────┐
                    │   ringing    │
                    └──────┬───────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           │ Accept        │ Decline       │ Timeout
           │ (after        │ (user         │ (no answer
           │  answer)      │  declines)    │  for 60s)
           │               │               │
           ▼               ▼               ▼
      ┌────────┐     ┌─────────┐    ┌────────┐
      │answered│     │ declined │    │ missed │
      └───┬────┘     └─────┬────┘    └────┬───┘
          │                │              │
          │ End call       │ End call     │
          │                │              │
          ▼                ▼              ▼
      ┌─────────────────────────────────────┐
      │            ended                     │
      └─────────────────────────────────────┘
          (triggers call log creation)
```

---

## 🌐 Connectivity Provider Architecture

### Real-Time Network Monitoring

```
┌──────────────────────────────────────────┐
│      ConnectivityProvider                │
├──────────────────────────────────────────┤
│                                           │
│  Monitors:                                │
│  ├─ WiFi connectivity                    │
│  ├─ Mobile data (3G/4G/5G)              │
│  ├─ Bluetooth connectivity              │
│  └─ Connection changes (online/offline)  │
│                                           │
│  State:                                   │
│  ├─ isOnline: bool                       │
│  └─ List<ConnectivityResult>             │
│                                           │
│  Callbacks:                               │
│  ├─ onBackOnlineCallbacks: List          │
│  └─ notifyListeners() [ChangeNotifier]   │
│                                           │
└──────────────────────────────────────────┘
```

### Network Status Flow

```
Device Online                  Device Offline                Device Online Again
     │                              │                               │
     │ WiFi Connected               │                               │
     │ ✓ isOnline = true       Lose connection                      │
     │ ✓ Can send messages     ✗ WiFi disconnected                  │
     │ ✓ Calls work            ✗ Mobile data off                   │
     │                              │                               │
     │                              ▼                               │
     │                         ✗ isOnline = false              Regain connection
     │                         ✓ Use mesh network              ✓ WiFi on again
     │                         ✓ Queue messages locally            │
     │                         ✓ Show "offline" badge               │
     │                              │                               │
     │                              │<──────────────────────────────┤
     │                                                    Fire onBackOnline callbacks
     │                                                    │
     │                                              ┌─────▼──────┐
     │                                              │ Sync mesh  │
     │                                              │ messages   │
     │                                              │ to Firestore
     │                                              │ + FCM      │
     │                                              └────────────┘
     │
     │ ✓ isOnline = true (restored)
     │ ✓ Continue normal operation
```

---

## 📱 FCM Token Management Architecture

### Device-Specific Token Storage

```
┌──────────────────────────────────────────────┐
│       FCM Service (per-device)                │
├──────────────────────────────────────────────┤
│                                               │
│  On App Start:                                │
│  ├─ Get FCM token from FirebaseMessaging    │
│  └─ Store in Firestore: users/{uid}/fcm     │
│                                               │
│  Token Refresh (automatic):                   │
│  ├─ Device reboots → FCM generates new token│
│  ├─ onTokenRefresh callback fires           │
│  └─ Update Firestore immediately            │
│                                               │
│  Per-Device Storage:                          │
│  ├─ Key: "fcm_token_{deviceId}"             │
│  ├─ Value: Firebase FCM token (encrypted)   │
│  └─ Storage: SharedPreferences              │
│                                               │
│  Firestore Structure:                         │
│  users/{uid}/                                 │
│    ├─ fcmToken: "abc123..." (current)       │
│    ├─ fcmTokens: {                           │
│    │   "device_id_1": "token_1",             │
│    │   "device_id_2": "token_2"              │
│    │ }                                        │
│    └─ fcmTokenUpdatedAt: Timestamp          │
│                                               │
└──────────────────────────────────────────────┘
```

### Token Refresh Flow

```
Device Boots/Restarts
     │
     ▼
┌──────────────────┐
│ FirebaseMessaging│
│ generates new    │
│ token            │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────┐
│ onTokenRefresh callback  │
│ (FCMService)             │
└────────┬─────────────────┘
         │
         ├─> Read previous token from SharedPrefs
         │
         ├─> If different (first time or changed)
         │   │
         │   ├─> Update Firestore users/{uid}
         │   │   └─ fcmToken: newToken
         │   │
         │   ├─ Send to backend
         │   │  └─ Device can now receive notifications
         │   │
         │   └─> Update SharedPrefs cache
         │
         └─> Continue normal operation
```

---

## ⚠️ MIUI/HyperOS Notification Handling

### Device-Specific Notification Optimization

MIUI (Xiaomi) and HyperOS devices require special handling for notification layout and rendering.

```
Notification Creation (CallKit)

┌──────────────────────────────────────────┐
│   Detect Device OS/ROM                    │
├──────────────────────────────────────────┤
│                                            │
│  if (MIUI || HyperOS) {                   │
│    ├─ Use alternative layout resource    │
│    ├─ Adjust padding/margins             │
│    ├─ Modify text sizing                 │
│    └─ Optimize click area detection      │
│  }                                        │
│                                            │
│  if (Standard Android) {                  │
│    └─ Use default Material Design layout │
│  }                                        │
│                                            │
└──────────────────────────────────────────┘
```

### Notification Rendering Pipeline

```
CallKit Notification Triggered
     │
     ▼
┌──────────────────────────┐
│ Detect Device Manufacturer│
└────────┬─────────────────┘
         │
    ┌────┴────┐
    │          │
 Xiaomi    Other OEMs
    │          │
    ▼          ▼
 MIUI/HOS   Standard
    │          │
    ├──────────┤
    │          │
    ▼          ▼
┌──────────┐ ┌──────────┐
│ Custom   │ │ Material │
│ Layout   │ │ Design 3 │
│ Resources│ │ Layout   │
└────┬─────┘ └────┬─────┘
     │            │
     └────┬───────┘
          │
          ▼
     Notification Displayed
     (optimized for device)
          │
          ▼
     User can tap to:
     ├─ Accept call (green button)
     ├─ Decline call (red button)
     └─ Show full-screen UI
```

### Platform Configuration

```
Android Configuration:

build.gradle:
  ├─ minSdk: 21+ required for CallKit
  ├─ targetSdk: 34 (latest API level)
  └─ compileSdk: 34

AndroidManifest.xml:
  ├─ <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
  ├─ <meta-data> for MIUI detection
  └─ Intent filters for CallKit callbacks

Resources (res/):
  ├─ layout-miui/ (custom layouts for MIUI)
  ├─ layout-hyp/ (custom layouts for HyperOS)
  └─ layout/ (default layouts)

Runtime Detection:
  Build.MANUFACTURER == "Xiaomi"
  Build.DISPLAY.contains("MIUI")
  Build.DISPLAY.contains("HyperOS")
```

---

## 🔔 Status Reply Feature Architecture

### Direct Messaging from Status

```
User Views Status
     │
     ▼
┌──────────────────┐
│ Status Viewer    │
│ (full-screen)    │
└────────┬─────────┘
         │
  User taps "Reply"
         │
         ▼
┌──────────────────────────┐
│ Opens Chat Screen        │
│ (auto-populated)         │
│ - Pre-filled context:    │
│   - Status owner name    │
│   - Status link/ref      │
│   - Timestamp            │
└────────┬─────────────────┘
         │
         │ User types message
         │
         ▼
┌──────────────────────────┐
│ Send Direct Message      │
│ With metadata:           │
│ - replyToStatusId        │
│ - statusTimestamp        │
│ - statusOwnerId          │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ Create chat message      │
│ in Firestore             │
│ - type: "text"           │
│ - replyToStatus: true    │
│ - statusRef: reference   │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ FCM to status owner      │
│ "User replied to status" │
└────────────────────────┘
```

### Data Model

```
Message Document (with status reply):

{
  id: "msg_12345",
  senderId: "user_alice",
  senderName: "Alice",
  receiverId: "user_bob",
  type: "text",
  text: "Love your status!",
  timestamp: Timestamp.now(),
  isRead: false,
  
  // Status reply specific fields
  replyToStatus: true,
  statusRef: {
    userId: "user_bob",
    statusId: "status_67890",
    statusTimestamp: Timestamp(...),
    statusType: "image" // text|image|video
  }
}
```

---

**This comprehensive architecture supports:**
- ✅ Persistent device authentication (WhatsApp-style)
- ✅ Real-time call state synchronization
- ✅ Network-aware features with automatic fallback
- ✅ Device-specific optimization (MIUI/HyperOS)
- ✅ Reliable FCM token management
- ✅ Status engagement with direct messaging
- ✅ Seamless offline → online transitions
    │
    ▼
┌──────────────────────────┐
│ UpdateService             │
│ .checkAndPromptUpdate()  │
└───────────┬──────────────┘
            │
            ▼
┌──────────────────────────┐
│ InAppUpdate.checkForUpdate│
└───────────┬──────────────┘
            │
      ┌─────┴──────┐
      │            │
  Up to date   Update available
      │            │
      ▼            ├── immediateAllowed? ──> Full-screen Play Store UI
   (no-op)         │                         (user MUST update)
                   │
                   └── flexibleAllowed? ──> Background download
                                            + snackbar install
```

> Only works when installed from Google Play.
> `ERROR_API_NOT_AVAILABLE` is expected during debug builds.

---

## 🗂️ Complete Database Schema

### users Collection

```
Document ID: {userId}
Fields:
  id: string
  name: string
  phoneNumber: string? (optional)
  email: string? (optional)
  about: string? (optional)
  photoUrl: string? (optional)
  fcmToken: string
  isOnline: boolean
  lastSeen: timestamp
  createdAt: timestamp
  blockedUsers: array<string> (optional)
```

### chatRooms Collection

```
Document ID: {chatRoomId}
Fields:
  participants: array<string>
  lastMessage: string?
  lastMessageTime: timestamp?
  lastMessageSenderId: string?
  lastMessageStatus: string? (sent/delivered/read)
  unreadCount: map<userId, int>
  clearedAt: map<userId, timestamp>  ← per-user chat clearing

  Subcollection: messages/{messageId}
    senderId: string
    text: string?
    imageUrl: string?
    timestamp: timestamp
    status: string (sent/delivered/read)
    type: string (text/image)
```

### calls Collection

```
Document ID: {callId}
Fields:
  callerId: string
  calleeId: string
  channelId: string
  status: string (ringing/connected/ended/missed)
  isAudioOnly: boolean
  startedAt: timestamp
```

### callLogs Collection

```
Document ID: {logId}
Fields:
  callerId: string
  calleeId: string
  callerName: string
  calleeName: string
  duration: int (seconds)
  type: string (audio/video)
  status: string (answered/missed/cancelled)
  timestamp: timestamp
```

### statuses Collection

```
Document ID: {userId}
Fields:
  userId: string
  userName: string
  userPhotoUrl: string?
  lastUpdated: timestamp
  statusItems: array<StatusItem>

StatusItem:
  id: string
  type: "text" | "image" | "video"
  text: string? (for text)
  imageUrl: string? (for image)
  videoUrl: string? (for video)
  caption: string?
  backgroundColor: string? (for text)
  createdAt: timestamp
  viewedBy: array<string>
```

---

## 🔄 App Update & Version Support Architecture

Two separate mechanisms, often confused:

| Question | Answered by | Source of truth |
|---|---|---|
| "Is there a newer build?" | `UpdateService` → Google Play In-App Updates | Play Store |
| "Is *this* build still allowed to run?" | `VersionPolicyService` | Firebase Remote Config |

Play knows what's newest; it has no opinion on what's acceptable. The
supported-version policy is ours, and it is the only thing that can lock a
user out — which is why it ships switched off.

### Where the prompts appear

```
Cold start (signed in)
  HomeScreen post-frame chain
    → maybeShowWhatsNew()               (awaited, so nothing stacks on it)
    → UpdateService.runLaunchPrompts()  (at most ONE dialog)
         │
         ├─ policy.blocks  → return; _AuthGate renders UnsupportedVersionScreen
         ├─ policy.warns   → showVersionExpiringDialog()   [escalating throttle]
         └─ otherwise      → Play check → showUpdateAvailableDialog()  [24h/version]

Cold start (signed out)
  _AuthGate → UpdateService.checkAndNotifyOnLaunch()  → notification, no dialog

Resume after ≥ 4h backgrounded, on the Home route
  → runLaunchPrompts() again
```

The signed-out launch posts a *notification* rather than a dialog because
there is no home screen to host one; the signed-in launch gets the dialog and
deliberately **not** the notification, so one update never produces two
prompts. The launch dialog is literally the same widget as Settings → Check
for updates (`lib/widgets/update_dialogs.dart`) for the same reason.

### The three-state lifecycle

`lib/services/version_policy.dart` — `evaluateWith()` is a pure function, fully
covered by `test/services/version_policy_test.dart`.

```
        ok ──────────► expiring ──────────► unsupported
             installed <          deadline passed,
             deprecated_below     or installed < min_supported
```

Four Remote Config keys, and the split between them is the important part:

| Key | Type | Effect |
|---|---|---|
| `force_update_enabled` | bool | **Master switch.** Everything below is inert while false. |
| `deprecated_below_version_code` | int | Builds under this start warning. Soft. |
| `support_deadline_iso` | string | UTC ISO-8601. When it passes, deprecated builds block *themselves* — nobody has to flip a switch at midnight. |
| `min_supported_version_code` | int | Hard floor. Immediate, no clock consulted. |

The soft path is the normal one. `min_supported_version_code` exists for
"that build is broken, cut it off now" and because it never reads a clock, it
is the lever a doctored device date cannot dodge.

**Clock tampering.** Time comes from `ServerClock`, not `DateTime.now()`. Once
a device has actually observed the unsupported state it latches in prefs, so
winding the date back afterwards changes nothing. The latch *clears* when the
policy stops condemning the build — that is what makes rolling back a bad
config value actually release the users it caught.

**The kill switch is checked first**, before the hard floor and before the
latch. A mistyped version code is the one config error in this project that
can lock out the entire install base, and the recovery has to be one boolean
rather than working out which of three numbers was wrong.

### Release checklist

Three edits in lockstep — `test/app_version_consistency_test.dart` fails the
build if any two disagree:

1. `pubspec.yaml` → `version: <name>+<code>`
2. `lib/widgets/whats_new_dialog.dart` → `kCurrentVersion`
3. `lib/services/version_policy.dart` → `kAppVersionCode`

A stale `kAppVersionCode` is the dangerous one: ship 57 while the constant
still reads 56, set `deprecated_below_version_code: 57`, and the new build
condemns itself — everyone who did what they were asked gets locked out.

To retire a version:

1. Ship the replacement and let adoption settle.
2. Set `deprecated_below_version_code` to the first *good* code, and
   `support_deadline_iso` **≥ 15 days out** — the countdown is worthless if
   users meet it already expired.
3. Only then set `force_update_enabled: true`. Users below the line start
   seeing the countdown; the block arrives on its own at the deadline.
4. Reserve `min_supported_version_code` for emergencies.

To undo any of it: set `force_update_enabled: false`. Remote Config pushes in
real time, and latched devices are released on their next evaluation.

---

**This architecture supports:**
- ✅ Unlimited concurrent users
- ✅ Real-time presence updates
- ✅ Secure server-side notification delivery
- ✅ Native call UI via CallKit
- ✅ Cold-start call handling
- ✅ Instant chat list rendering via local cache
- ✅ Per-user privacy controls
- ✅ Non-blocking in-app updates, with a configurable support lifecycle
- ✅ Offline capability
- ✅ Scalable to millions of users
