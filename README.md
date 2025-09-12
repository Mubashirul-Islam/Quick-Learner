# Quick Learner

A Flutter app that connects students and tutors with authentication, user roles, Firestore profiles, and real‑time video calls powered by Agora. Built with GetX for routing/state and Material 3 theming.

## Features

- Email/password authentication (Firebase Auth)
- User roles: Student or Tutor (stored in Firestore)
- Profile documents in Firestore:
	- students/{uid}: sid, email, name?, edu?
	- tutors/{uid}: tid, email, name?, edu?, fee?, rating?
- Theming with light/dark modes (Material 3)
- Screens (navigated via GetX routes):
	- /login, /register
	- /home
	- /post-query, /query-responses, /notifications
	- /call (video calling via Agora)
- Permissions handling (camera/microphone)
- Local storage with Shared Preferences (for simple client state)

## Tech Stack

- Flutter (Dart) — Material 3
- State management and routing: GetX
- Firebase: Core, Auth, Cloud Firestore
- Real‑time video: Agora RTC Engine
- permission_handler, shared_preferences

## Project Structure (high level)

```
lib/
	main.dart                 # App entry; initializes Firebase, wires GetX & theme
	firebase_options.dart     # FlutterFire generated Firebase config
	controllers/
		auth_controller.dart    # Auth flow, role-aware profile load/save, password ops
		theme_controller.dart   # Theme mode (light/dark)
	models/
		user_model.dart         # Student & Tutor models
	views/
		auth/                   # Login & Register screens
		home/                   # Home, Post Query, Query Responses, Notifications
		call/                   # VideoCallView (Agora)
```

## Data Model

- Student: { sid, email, name?, edu? }
- Tutor: { tid, email, name?, edu?, fee?, rating? }
- Firestore collections use the Firebase Auth UID as the document ID.

## Prerequisites

- Flutter SDK installed
- Firebase project (Web, Android, iOS as needed)
- Agora account and App ID (and a token service if you use tokens)

## Setup

1) Install dependencies

```powershell
flutter pub get
```

2) Configure Firebase via FlutterFire CLI (recommended)

- Create a Firebase project and enable Email/Password auth.
- Create apps for each platform you target (Android/iOS/Web).
- Run the FlutterFire CLI to generate `lib/firebase_options.dart` (already present in this repo, but you should re-generate for your own Firebase project):

```powershell
flutterfire configure
```

- Android: Place `google-services.json` in `android/app/` (present in this repo for the sample project; replace with yours).
- iOS: When using FlutterFire with `DefaultFirebaseOptions`, `GoogleService-Info.plist` is not strictly required, but adding it to the iOS Runner target is recommended.

3) Configure Agora

- Obtain an Agora App ID from the Agora Console.
- In your call flow (see `views/call/VideoCallView`), ensure the engine is created with your App ID and (optionally) a token.
- For production, use a token server to generate temporary tokens.

4) Platform permissions

- Android: add to `android/app/src/main/AndroidManifest.xml`:
	- android.permission.CAMERA
	- android.permission.RECORD_AUDIO
	- android.permission.INTERNET
- iOS: add to `ios/Runner/Info.plist`:
	- NSCameraUsageDescription
	- NSMicrophoneUsageDescription

5) Run the app

```powershell
flutter run
```

## Navigation & Usage

- The app boots into an auth gate (`_AuthGate`).
	- If signed in, shows `HomeView`; otherwise `LoginView`.
- Register: choose role (Student/Tutor). The controller saves your profile in the corresponding Firestore collection using your UID.
- Calls: navigate to `/call` with a channel name argument (e.g., via GetX: `Get.toNamed('/call', arguments: 'myChannel')`).

## Development Notes

- Routing is declared in `main.dart` via `getPages`.
- `AuthController` handles:
	- Registration/login/logout
	- Firestore profile load (students/{uid} or tutors/{uid})
	- Change password & delete account (requires recent login for delete)
- Theme is reactive (GetX + `Obx`) and can switch light/dark.

## Testing

```powershell
flutter test
```

## Troubleshooting

- Firebase initialize error: re-run `flutterfire configure` to regenerate `firebase_options.dart` for your own project.
- Android build issues with Firebase: verify `google-services.json` path and that `com.google.gms.google-services` plugin is applied in `android` gradle files.
- Camera/mic not working: confirm runtime permissions (Android 6+), and Info.plist keys on iOS.
- Agora connection fails: check App ID/token, network permissions, and that your channel name matches on both ends.
