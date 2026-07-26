# Currency Classifier Feature — Dependency & Environment Setup

**Project:** Roshni — AI Vision Assistant for Blind and Low-Vision Users
**Module:** Currency Classifier
**Version:** 1.0

---

## 1. Purpose

This document covers dependencies for BOTH phases: the Python/Colab training environment (Phase A) and the Flutter app integration (Phase B), building on the app's already-confirmed working environment (Flutter 3.44.6, Gradle 9.1.0, AGP 9.0.1, Kotlin 2.3.20, JVM 17).

---

## 2. Phase A — Training Environment (Google Colab)

No local Python installation is required — consistent with how the YOLO TFLite export was done earlier in this project, avoiding local Windows Python/TensorFlow setup headaches.

In a fresh Colab notebook:

```python
!pip install tensorflow==2.17.0
!pip install scikit-learn matplotlib
```

**Why these specifically:**
- `tensorflow` — provides Keras for building/training the CNN and the TFLite converter for export. Pin a specific recent stable version rather than "latest," and verify it against Colab's current default before running, since Colab's pre-installed package versions shift over time.
- `scikit-learn` — used for generating the confusion matrix and computing per-class metrics (per BR-3 in the constraints doc)
- `matplotlib` — used to visualize training/validation accuracy curves and the confusion matrix, so the reported results are inspectable, not just raw numbers in a log

**Uploading the dataset to Colab:**
Since the `pakistan` dataset folder is on the local Desktop, it needs to be uploaded to Colab (via Google Drive mount, or direct zip upload) before training — do not attempt to reference the local Windows file path directly, since Colab runs on a remote machine with no access to the local filesystem.

---

## 3. Phase B — Flutter App Integration

No new Flutter package dependencies are required beyond what's already installed for Object Detection — Currency Classifier reuses:
- `camera` (already installed, reused via `CameraService`)
- `tflite_flutter` (already installed for YOLO — reused for loading `currency_classifier.tflite` via the same interpreter pattern)

**Only new addition:** the trained model file itself.

```yaml
flutter:
  assets:
    - assets/models/yolov8n.tflite            # existing
    - assets/models/coco_labels.txt            # existing
    - assets/models/currency_classifier.tflite # new
```

No new pubspec.yaml package dependencies means no new Gradle/Kotlin/JVM compatibility risk for this feature specifically — the model file is just a data asset, not a native plugin, so it does not carry the same class of build-conflict risk that adding `camera`, `tflite_flutter`, or `opencv_dart` did earlier in this project.

---

## 4. Verification-before-integration discipline

1. Complete Phase A training and export entirely in Colab first.
2. Verify the exported `.tflite` file works correctly **in Python, inside Colab**, before ever copying it into the Flutter project (per TC-4 in the architecture/constraints docs) — this isolates "is the model itself correct" from "is it wired correctly into the app," exactly the same debugging discipline already established for Object Detection and Document Reader in this project.
3. Only after that Python-side verification passes, copy `currency_classifier.tflite` into `assets/models/` and begin `CurrencyClassifierService` integration.
4. After integration, run the same full clean rebuild sequence used for every previous feature:
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

---

## 5. Manual test checklist before considering this "done"

- [ ] Training notebook runs in Colab with the pinned package versions, no dependency errors
- [ ] Validation accuracy and confusion matrix are both computed and visually inspected (not just a single accuracy number)
- [ ] The exported `.tflite` file is verified to produce matching predictions to the pre-export model on a handful of validation images, tested in Python before ever touching Flutter code
- [ ] The app builds and runs with the new model asset added, no new Gradle/dependency conflicts (expected to be low-risk per Section 3, but still verify)
- [ ] A real Pakistani note (physical, real-world test — not a screen photo) held up to the camera produces a spoken, correct denomination result within a responsive time
- [ ] A deliberately blurry/poorly-lit capture correctly routes to the existing error/retry state rather than announcing a wrong guess
