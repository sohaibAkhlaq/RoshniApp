# Document Reader Feature — Dependency & Environment Setup

**Project:** Roshni — AI Vision Assistant for Blind and Low-Vision Users
**Module:** Document Reader
**Version:** 1.0

---

## 1. Purpose

This document lists exactly what needs to be installed for Document Reader, built on top of the app's already-confirmed working environment: Flutter 3.44.6, Gradle 9.1.0, AGP 9.0.1, Kotlin Gradle Plugin 2.3.20, JVM target 17. Existing dependencies already in the project (camera 0.12.0+2 with camera_android_camerax, permission_handler 12.0.3, firebase_core 4.12.1, firebase_auth 6.5.6, cloud_firestore 6.7.1, shared_preferences 2.3.4, plus whatever Tesseract OCR package was added for Urdu OCR Reader) must not be changed by this work.

---

## 2. New dependency required: OpenCV for edge detection

```yaml
dependencies:
  opencv_dart: ^1.3.4
```

**Why `opencv_dart` specifically:** it is the actively maintained, current Flutter/Dart binding for OpenCV (unlike older, now-unmaintained OpenCV Flutter plugins), and it exposes the contour/edge-detection and perspective-warp functions needed for `DocumentEdgeDetector` and `PerspectiveCorrector`. Before adding it, verify its current published version against pub.dev directly (package versions shift over time) and confirm its Android native build requirements are compatible with Gradle 9.1.0/AGP 9.0.1/Kotlin 2.3.20 — apply the same verification discipline used for every previous native plugin addition in this project (camera, tflite_flutter) rather than assuming compatibility.

**No new OCR package needed.** Document Reader reuses the exact Tesseract OCR package and configuration already installed for Urdu OCR Reader (per NFR-3/BR-5 in the requirements/constraints docs) — do not add a second OCR dependency.

---

## 3. Verification-before-commit discipline (same process as every prior feature)

1. Add `opencv_dart` to `pubspec.yaml`
2. Run `flutter pub get`
3. Run `flutter pub outdated` and review for any flagged conflicts with existing dependencies (especially anything touching native Android build tooling)
4. Do a full clean rebuild:
```
flutter clean
cd android
./gradlew --stop
cd ..
flutter pub get
flutter pub outdated
cd android
./gradlew clean
cd ..
flutter run --enable-impeller
```
5. Only once this completes with zero new errors should implementation of `DocumentEdgeDetector`/`PerspectiveCorrector` begin — confirming the dependency builds cleanly is a separate, checkable step from writing the feature's logic, consistent with how camera and TFLite were added earlier in this project.

---

## 4. Manual test checklist before considering setup "done"

- [ ] App builds and runs with `opencv_dart` added, no Gradle/Kotlin/JVM conflicts (the exact class of error hit earlier in this project with `tflite_flutter` and `camera_android_camerax`)
- [ ] A basic OpenCV function call (e.g., loading a test image and running a simple edge-detection pass) succeeds in isolation before wiring it into the live camera pipeline, so any OpenCV-specific setup issue is caught early and separately from camera-integration issues
- [ ] Confirm the existing Tesseract OCR service (from Urdu OCR Reader) can be called from `DocumentOCRService`'s new thin wrapper without needing any reinitialization or duplicate model loading
