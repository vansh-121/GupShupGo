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

## 📲 CallKit Integration

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

## 🔄 In-App Update Flow

```
App starts → HomeScreen.initState
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

**This architecture supports:**
- ✅ Unlimited concurrent users
- ✅ Real-time presence updates
- ✅ Secure server-side notification delivery
- ✅ Native call UI via CallKit
- ✅ Cold-start call handling
- ✅ Instant chat list rendering via local cache
- ✅ Per-user privacy controls
- ✅ Mandatory in-app updates
- ✅ Offline capability
- ✅ Scalable to millions of users
