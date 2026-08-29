# ZeroLink

Flutter + Firebase real-time chat app.

## Setup

1. **Create the Flutter project shell** (if you don't have one yet):
   ```
   flutter create chatx
   ```
   Then copy the contents of this `lib/` folder over yours, and merge `pubspec.yaml`.

2. **Install dependencies**
   ```
   flutter pub get
   ```

3. **Connect Firebase** — this repo's `lib/firebase_options.dart` is a placeholder.
   Generate the real one:
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   Pick/create your Firebase project and select the platforms you need (Android/iOS/Web).

4. **Enable Firebase products** in the Firebase console:
   - Authentication → Email/Password provider
   - Firestore Database (start in production mode)
   - Storage
   - Cloud Messaging (for push notifications)

5. **Deploy security rules**
   ```
   firebase deploy --only firestore:rules,storage:rules
   ```
   (Requires `firebase-tools` and `firebase init` pointed at this project.)

6. **Run it**
   ```
   flutter run
   ```

## What's implemented (MVP)

- Email/password register + login (`auth_service.dart`)
- User profile doc created on signup, editable bio + photo
- Firestore-backed real-time 1:1 messaging (`chat_service.dart`)
- Deterministic `chatId` so both users always land in the same thread
- Image messages: gallery pick → compress → upload to Storage → URL saved in Firestore
- Online/offline presence tied to app lifecycle (`main.dart`)
- User search by name prefix
- Sent/read message status ticks
- Firestore + Storage security rules restricting access to chat participants only

## Not yet implemented (see "Version 2" in the original spec)

Group chat, typing indicators, reactions, message edit/delete/forward, voice
messages, stories, blocking, and WebRTC calling. The service layer
(`ChatService`, `AuthService`) is structured so these can be added without
restructuring the data model — e.g. group chat mainly needs `participants`
to support >2 uids, which the rules and chat list stream already tolerate
at the querying level (message sending itself will need a small rewrite
for fan-out).

## Push notifications

Cloud Functions aren't included here since they deploy separately (Node.js,
not Dart). You'll want a function that triggers on new message document
creation and sends an FCM push to the receiver if they're not currently
in the chat — happy to write that as a follow-up.
