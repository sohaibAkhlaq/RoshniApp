# Roshni — آپ کی روشنی، ہر وقت ساتھ

> **Your light, always with you.**  
> An intelligent assistive application designed for visually impaired users, powered by Flutter and Firebase.

[![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

---

## Overview

Roshni is a mobile application that empowers visually impaired individuals by providing real-time **object detection**, **Urdu OCR reading**, **currency classification**, **document scanning**, and **photo description** — all through an intuitive, accessible interface with screen-reader support.

The app features a **complete authentication system** with Firebase, supporting email/password signup, login, and an intelligent skip-flow that remembers user preferences across sessions.

---

## Features

### Core Modules

| Module | Description |
|--------|-------------|
| 🎯 **Object Detection** | Real-time detection of surroundings using device camera |
| 📖 **Urdu OCR Reader** | Read Urdu text aloud from captured images |
| 💵 **Currency Classifier** | Identify Pakistani rupee notes |
| 📄 **Document Reader** | Scan and read bills, slips, and documents |
| 🖼️ **Photo Description** | AI-powered description of any captured scene |

### Authentication & User Experience

- **Email/Password Authentication** via Firebase Auth (phone-based email mapping)
- **Persistent Skip Mode** — Users can skip signup and be remembered across sessions
- **Settings-based Login** — Login/SignUp accessible from Settings any time
- **Firestore Profiles** — User data (name, phone, language) stored securely
- **Offline-ready** — Firestore persistence enabled with unlimited cache
- **Accessibility-first** — Full `Semantics` widget support for screen readers
- **Material 3 Design** — Modern UI with high-contrast amber/navy palette

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| **Framework** | Flutter 3.44 + Dart 3.12 |
| **Authentication** | Firebase Authentication (Email/Password) |
| **Database** | Cloud Firestore |
| **State Management** | Built-in `setState` + callback-based navigation |
| **Permissions** | `permission_handler` (Camera, Microphone) |
| **Persistence** | `shared_preferences` (skip-login flag, permission state) |
| **Navigation** | Custom screen-index manager + `Navigator` pushes |
| **Design** | Material 3, custom amber-gold theme |

---

## Project Structure

```
lib/
├── core/
│   ├── auth_service.dart          # Firebase Auth + Firestore + SharedPreferences
│   ├── permission_service.dart    # Camera/Mic permission handling
│   └── theme.dart                 # App theme, colors, typography
├── screens/
│   ├── splash_screen.dart         # Splash + Firestore config + permission gate
│   ├── permissions_screen.dart    # Camera/Mic permission request UI
│   ├── login_screen.dart          # Phone + password login
│   ├── create_account_screen.dart # Full name, phone, password signup
│   ├── home_screen.dart           # Feature grid launcher
│   ├── profile_screen.dart        # User profile with real Firestore data
│   ├── settings_screen.dart       # Dynamic settings (auth-aware)
│   ├── camera_base_screen.dart    # Reusable camera UI template
│   ├── gesture_guide_screen.dart  # Touch gesture instructions
│   ├── scan_history_screen.dart   # Past scans list
│   └── (feature screens)          # Object detection, OCR, currency, etc.
├── widgets/
│   ├── custom_textfield.dart      # Reusable text input
│   ├── primary_button.dart        # Styled action button
│   ├── feature_card.dart          # Home feature card
│   └── gesture_bar.dart           # Bottom gesture indicator
└── firebase_options.dart          # FlutterFire-generated config
```

---

## Authentication Flow

```
App Launch → Splash → Permissions Check
                            │
               ┌────────────┴────────────┐
               │                         │
          Logged In                  Not Logged In
          or Skipped?                and Not Skipped?
               │                         │
            Home ─────┐              Login Screen
                      │              ├── Login (phone + password)
                      │              ├── Skip for now ──→ Home (persisted)
                      │              └── Sign Up ──→ CreateAccount ──→ Login
                      │
              Settings → Login/Sign Up
                (only if not logged in)
```

- **Skip Flow:** Once a user taps "Skip for now", the app never shows the login screen again unless the user manually navigates to **Settings > Login / Sign Up**.
- **Signup:** Creates Firebase Auth user (phone@roshni.app) + Firestore document (`name`, `phone`, `language`, `createdAt`, `lastLoginAt`).
- **Login:** Validates credentials against Firebase Auth, updates `lastLoginAt`, navigates to home.

---

## Getting Started

### Prerequisites

- Flutter SDK **3.44+** ([install guide](https://docs.flutter.dev/get-started/install))
- Dart SDK **3.12+** (included with Flutter)
- Firebase project with **Authentication** and **Firestore** enabled
- Android Emulator or physical device (API 21+)
- (Optional) iOS device with `GoogleService-Info.plist`

### Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create or select project → **roshniapp**
3. Enable **Authentication → Sign-in method → Email/Password**
4. Create **Firestore Database** with test rules:
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```
5. Register Android app with package name `com.example.roshni`
6. Download `google-services.json` → place in `android/app/`
7. (Optional) Run `flutterfire configure` to regenerate `lib/firebase_options.dart`

### Installation

```bash
# Clone the repository
git clone https://github.com/sohaibAkhlaq/RoshniApp.git
cd RoshniApp

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

### Build & Deploy

```bash
flutter build apk --release    # Android APK
flutter build appbundle        # Android App Bundle
flutter build ios              # iOS (requires macOS + Xcode)
```

---

## Permissions

The app requests the following permissions at runtime:

| Permission | Purpose |
|------------|---------|
| **Camera** | Object detection, document scanning, currency classification, photo description |
| **Microphone** | Voice commands (future) |
| **Internet** | Firebase Auth & Firestore communication |

---

## Configuration Files

| File | Purpose |
|------|---------|
| `android/app/google-services.json` | Firebase Android config |
| `lib/firebase_options.dart` | Dart-side Firebase options (generated by FlutterFire CLI) |
| `firebase.json` | FlutterFire project metadata |
| `android/app/build.gradle.kts` | Android build config with Google Services plugin |

---

## Commit History

```
feat(auth): implement Firebase authentication with signup, login, and skip-flow
feat(ui): add accessibility-first permission screen with camera/mic handling
feat(profile): display real Firestore user data with dynamic logout
feat(settings): auth-aware settings screen with login/user-info toggle
refactor(navigation): separate login-from-settings from logout flow
fix(auth): add try-catch error handling with SnackBar feedback
fix(auth): handle null onPressed states during loading
chore: update google-services plugin for AGP 9 compatibility
docs: add comprehensive project structure and setup documentation
```

---

## Roadmap

- [ ] Google Sign-In integration
- [ ] Real ML model integration (TensorFlow Lite)
- [ ] Voice guidance & navigation
- [ ] Urdu TTS (text-to-speech)
- [ ] Multi-language support
- [ ] Offline mode with local caching
- [ ] Watch companion app
- [ ] Accessibility shortcut (triple-press power button)

---

## License

```
MIT License

Copyright (c) 2024 Sohaib Akhlaq

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

---

## Contact & Support

- **Developer:** Sohaib Akhlaq
- **GitHub:** [@sohaibAkhlaq](https://github.com/sohaibAkhlaq)
- **Project Link:** [RoshniApp](https://github.com/sohaibAkhlaq/RoshniApp)

---

<div align="center">
  <strong>Roshni</strong> — Making the world accessible, one feature at a time.
</div>
