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

## 📎 Encrypted Document Sharing

Documents take a **different upload path from chat photos and videos**, and the
difference is deliberate:

| Path | Used by | What the server holds |
|---|---|---|
| `ref.putFile()` → `chat_images/`, `chat_videos/` | photo / video bubbles | the **plaintext** bytes; only the URL is inside the Signal envelope |
| `EncryptedMediaService` → `chat_documents/` | documents, view-once media, status | AES-256-GCM ciphertext; the key is inside the Signal envelope |

`allow read: if request.auth != null` means any authenticated GupShupGo user
holding a URL can fetch a chat image. That is a known gap in the older path.
Documents are resumes, tickets and bank statements, so the gap is not repeated
for them — and because the blob is encrypted, documents also get the
key-destruction mechanism view-once depends on for free.

### Send pipeline

```
_pickAndSendDocument()                       lib/screens/chat_screen.dart
  │
  ├─ online guard          no mesh document transport — checked before the picker
  ├─ FilePicker(withData: false)             path only; a 64 MB pick is not
  │                                          copied into the Dart heap twice
  ├─ size guard  > 64 MB → reject            encrypt-then-upload holds ~3× the
  │                                          file in memory at peak
  ├─ NO compression                          the whole point of the feature, and
  │                                          the workaround for original-quality photos
  │
  ├─ EncryptedMediaService.encryptAndUpload(
  │     storagePath: 'chat_documents/$chatRoomId/$uuid')
  │       AES-256-GCM · random key + IV · SHA-256 of the ciphertext
  │       → MediaKeyBundle { k, i, h, u, s, c }
  │
  └─ sendMessage(type: document,
                 fileName: <real name>,    ← encrypted payload
                 mediaKey: bundle.toMap(), ← encrypted payload
                 text:     <real name>)    ← plaintext fallback, see below
```

**The storage object name is a UUID, never the filename.** `severance_letter.pdf`
in a bucket listing is a disclosure on its own. The real name travels only
inside the encrypted `fileName` payload key, and the service forces
`contentType: application/octet-stream`, so the server cannot tell a PDF from a
ZIP from a photo.

**Why `text` carries the filename in the clear.** A v2 message's Firestore
`text` is `''`, and `MessageModel._parseMessageType` falls back to
`MessageType.text` on an unknown type — so a 1.1.9 client would render a
document as a *blank bubble*. Setting the payload `text` to the filename (and
`📍 Location` for a pin) makes old clients show something sensible, and the
same string doubles as the reply-quote snippet and the notification preview. It
is metadata the sender chose to reveal, not a leak of the file.

### Receive pipeline

`ChatService.downloadAndCacheMedia` is plaintext-only (`http.get` straight to
disk) and cannot be reused. Documents use its sibling:

```
DocumentBubble tap
  → ChatService.downloadAndCacheEncryptedMedia(message)
      ├─ MediaKeyBundle.fromMap(message.mediaKey)
      ├─ EncryptedMediaService.downloadAndDecrypt(bundle)
      │     constant-time SHA-256 verify → StateError if tampered
      │     isolate-offloaded above 32 KB
      └─ write gsg_chat_media/<msgId>_<sanitised fileName>
  → open_filex  (falls back to share_plus if no handler app exists)
```

The cache file keeps the sender's real name and extension — that is what lets
the OS pick a handler — and is prefixed with the message id, which is both the
uniqueness guarantee and the reason two sends of `invoice.pdf` don't collide.

**Size display.** `bundle.sizeBytes` is the **ciphertext** length: plaintext
plus the 16-byte GCM tag. The bubble subtracts 16 before formatting, so a
1.00 MB file doesn't read as 1.000016 MB.

### Storage rule

```
match /chat_documents/{chatRoomId}/{fileName} {
  allow read: if request.auth != null;
  allow write: if request.auth != null
    && request.resource.size < 100 * 1024 * 1024
    && request.resource.contentType == 'application/octet-stream';
}
```

100 MB is headroom above the 64 MB client cap: it fires only against a tampered
client, which is the only thing a server-side ceiling can usefully catch.

> ⚠️ **`storage.rules` in this repo is ahead of what is deployed.** Both the
> `chat_documents` block above and the existing `chat_videos` block are
> unpublished, so document and chat-video sends fail with a permission error
> until `firebase deploy --only storage` runs. This is a release prerequisite,
> not a code change.

---

## 🔍 In-Chat Search (SQLite FTS5)

Search used to be `messages.where((m) => m.text.contains(q))` over the paged-in
window — it could only find what was already on screen, which is the opposite of
what search is for. It is now a real FTS5 index over the local Drift store.

**Why this is possible at all:** messages reach `local_messages` via
`PlaintextStore.saveMessage` *after* `ChatService.decryptForRendering`, so the
stored `message_json` holds **decrypted** text. Indexing it needs no new
plaintext anywhere, and the index never leaves the device — no query, no term
and no result is ever sent to a server.

### Schema (`schemaVersion` 5)

Drift's `Migrator` cannot model a virtual table, so this uses the same
`customStatement` escape hatch the file already uses for indexes:

```sql
CREATE VIRTUAL TABLE IF NOT EXISTS message_fts USING fts5(
  body,
  message_id   UNINDEXED,
  chat_room_id UNINDEXED,
  tokenize='unicode61 remove_diacritics 2'
);
```

A plain (non-external-content) FTS5 table, deliberately: an external-content
table would have to stay in lockstep with `local_messages` through triggers, and
a single missed trigger corrupts the index silently. Four explicit writes are
easier to audit than four triggers. `remove_diacritics 2` is what makes `cafe`
find `café`.

### The four sync points

Every write path that touches `local_messages` touches the index in the same
method — `lib/services/crypto/plaintext_store.dart`:

| # | Method | Index action |
|---|---|---|
| 1 | `wipe` | `DELETE FROM message_fts`, inside the existing transaction |
| 2 | `saveMessage` | delete-then-insert the row (mirrors `insertOrReplace`) |
| 3 | `saveMessagesBatch` | same, as a separate pass after the Drift batch |
| 4 | `deleteMessage` | delete the row |

Point 3 runs *outside* the `batch`: Drift's `batch` only accepts its own
generated statements, and `message_fts` has no generated class.

Routing everything through these four keeps the hard cases correct for free —
an **edited** message re-saves and so re-indexes (old text gone, new text
found), and a **deleted** message goes through `asTombstone()` → `saveMessage`,
so its text leaves the index without a separate code path.

### Query escaping is load-bearing

FTS5 treats `"`, `*`, `^`, `:`, `(`, `-`, `OR`, `AND`, `NOT` and `NEAR` as
syntax. Typing `NEAR(` in a search box must not throw, and typing `OR` must not
silently widen the search. `PlaintextStore.buildFtsQuery` splits on whitespace,
doubles any `"` FTS5-style, wraps each token in quotes, and appends `*` outside
the closing quote:

```
hello world   →   "hello"* "world"*
say "hi"      →   "say"* """hi"""*
```

Quoted tokens are literals, so every operator arrives as text. The `*` sits
outside the quotes because inside them FTS5 reads it as a literal asterisk
rather than the prefix operator. Space-separated tokens are an implicit **AND**
— searching two words narrows, which is what users expect and the opposite of
what a bare `OR` would do. 18 hostile inputs are pinned in
`test/services/database/fts_search_test.dart`.

### v4 → v5 migration

`onUpgrade`'s `from < 5` rung calls `createFtsTable()` **and** `backfillFts()`.
Without the backfill, search on an upgraded install would only ever find
messages received *after* the update, and every older conversation would look
empty — a failure indistinguishable from "search is broken" and unfixable
without another migration.

`backfillFts()` reads `message_json` directly rather than going through
`MessageModel`: it runs inside the migration, before `PlaintextStore` exists,
and a row that fails to parse must cost its own indexing and **nothing else** —
throwing there would leave the database stuck below v5 and the app unable to
open at all. It opens with a `DELETE`, so an interrupted migration that runs
again does not double every message.

**Deliberately out of scope:** cross-conversation search and server-side search.
Both are real features; neither is this one. A hit outside the loaded page
window reuses the existing "message not loaded" path rather than inventing a
second paging mechanism.

---

## 📍 Location Pin Sharing

A pin is two doubles — `latitude` / `longitude` in the encrypted payload — and
no media at all, which is why it travels over the **mesh transport for free**
while documents cannot.

**There is no inline map image, deliberately.** Rendering a static map tile
would send the exact coordinate to Google's or OSM's servers on every render, on
*both* devices — handing a third party the one thing the message exists to
encrypt. The bubble is a styled card instead: pin glyph, coordinates to 5
decimal places, and an **Open in Maps** action that fires `geo:$lat,$lng?q=…`
via `url_launcher`, falling back to `https://maps.google.com/?q=…`. Zero render
dependencies, zero metadata leak, and it works offline.

The send path always shows the fetched coordinates and accuracy in a
confirmation sheet first — a location is never sent silently.

**Out of scope:** live location (the 15 min / 1 h / 8 h tiers) and map-based pin
picking. Both need a real map widget, and live location additionally needs a
background-location foreground service and an expiry sweeper.

---

## 👁️ View Once — deletion by key destruction

There is no "delete the file" step in this feature, because there is nothing the
receiver could be granted permission to delete: the receiver is not the blob's
uploader, and no `allow delete` rule could be written for them cleanly.

Instead, **destroying the key is the deletion.** The blob is AES-256-GCM
ciphertext whose only key reached the device inside a Signal envelope that
decrypts exactly once. Erase every copy of that key and the object left in
Storage is permanently unrecoverable — by the receiver, by the sender, by us.

This is also why view-once media goes through `EncryptedMediaService` rather
than the plaintext `chat_images/` path: the mechanism only exists if the blob
was encrypted in the first place. Both rule blocks already accept
`application/octet-stream`, so this feature needs **no storage-rules change**.

### The four key tiers

`ChatService.markViewOnceConsumed` clears all four:

```
1-3.  forgetCachedPayload(messageId)
        ├─ the in-memory decrypted-payload memo
        ├─ any in-flight decrypt future
        └─ the SQLite payload row holding mediaKey
 4.   _deleteFromVault(uid, messageId)
        └─ users/{uid}/msgVault/{messageId}   ← the cross-install Firestore copy
                                                the other three can't reach
then  delete the decrypted file from gsg_chat_media/
then  saveMessage(message.asViewOnceConsumed(uid))   ← stripped marker:
                                                        no key, no URL,
                                                        no thumbnail
then  Firestore viewOnceOpenedBy: arrayUnion([uid])
```

Tier 4 is the one that is easy to miss and the only one that survives a
reinstall, which is exactly why it matters.

### Consumption happens *before* the first pixel

`ViewOnceViewerScreen` decrypts into memory with
`EncryptedMediaService().downloadAndDecrypt(bundle)` — **not**
`downloadAndCacheEncryptedMedia`, which would leave a decrypted copy in the
ordinary chat-media cache that nothing later deletes — and then awaits
`markViewOnceConsumed` *before* rendering anything:

```
open → decrypt to memory → markViewOnceConsumed → THEN render
```

Consuming on viewer *close* would leave a window in which force-stopping the app
while the photo is on screen preserves the media for a second viewing.
Consuming immediately after decrypt, with the bytes already in hand, closes it.

**Video is the one compromise.** `video_player` cannot play from a byte buffer,
so the clip is written to a temp file, played, and deleted in `dispose`. The key
is already destroyed by then, so that file is the only plaintext copy in
existence and it is scoped to the viewer's lifetime.

### `viewOnceOpenedBy` is cleartext, deliberately

It sits **outside** `kMessageContentKeys` and must never gain a
`schemaVersion == 2 ? null : …` guard — the same precedent `deletedFor` and
`deletedForEveryone` already follow. It has to be server-visible to reach the
sender's devices at all, and it reveals nothing the server didn't already know
(that A sent B a message, and when).

It is also the belt-and-braces guarantee: a reinstalled client refuses to render
a view-once message whose id it already contains, even in the impossible case
that a key copy somehow survived.

### Screenshot blocking, and what it can't promise

A fourth MethodChannel on `MainActivity.kt` (`com.gupshupgo.app/secure_screen`,
following the three already there) toggles `FLAG_SECURE` from the viewer's
`initState` / `dispose`. **iOS has no FLAG_SECURE equivalent**, so
`SecureScreenService.isEnforceable` is false there and the viewer's footer says
so outright rather than implying a protection that isn't present.

Nothing here stops a second camera pointed at the screen, and the UI copy is
worded to promise only what the mechanism delivers: *"the key is destroyed when
they open it"*, never *"it can't be saved"*.

### Sender side

`markViewOnceConsumed` is receiver-only — a call where `currentUserId` is the
sender returns immediately. The sender keeps its own vault copy because that is
what backs the resend protocol, and the media was theirs to begin with. The
sender therefore **cannot re-open their own view-once media**, and the guard for
that lives at the render (`ViewOnceBubble` is never tappable for `isMe`), not at
the key.

---

**This architecture supports:**
- ✅ Unlimited concurrent users
- ✅ Real-time presence updates
- ✅ Secure server-side notification delivery
- ✅ Native call UI via CallKit
- ✅ Cold-start call handling
- ✅ Instant chat list rendering via local cache
- ✅ Per-user privacy controls
- ✅ End-to-end encrypted document sharing, with filenames hidden from the server
- ✅ Full-history on-device message search that never reaches a server
- ✅ Location pins with no third-party map request
- ✅ View-once media enforced by key destruction, not by a delete permission
- ✅ Non-blocking in-app updates, with a configurable support lifecycle
- ✅ Offline capability
- ✅ Scalable to millions of users
