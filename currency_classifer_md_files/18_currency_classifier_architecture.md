# Currency Classifier Feature — Architecture

**Project:** Roshni — AI Vision Assistant for Blind and Low-Vision Users
**Module:** Currency Classifier
**Version:** 1.0

---

## 1. Overview

This feature has two distinct phases with different architectures: **Phase A — Training** (happens once, offline, in Python/Colab, producing a `.tflite` file) and **Phase B — In-App Integration** (happens in the Flutter app, using the trained model for real-time inference). This document covers both, since "architecture" here isn't just the app's code structure — it's also the training pipeline that produces the artifact the app depends on.

---

## 2. Phase A — Training Pipeline Architecture (Python / Google Colab)

```
[pakistan/ dataset folder, organized by denomination subfolders]
      │
      ▼
[Data loading & inspection] → count images per class, check for class imbalance
      │
      ▼
[Train/Validation split] → e.g. 80/20, stratified by class so each denomination
      is proportionally represented in both sets
      │
      ▼
[Data augmentation pipeline] → applied only to training data (rotation,
      brightness/contrast jitter, slight blur, minor perspective warps) —
      NEVER applied to validation data, since validation must reflect real,
      unmodified conditions
      │
      ▼
[Base model] → pretrained lightweight CNN (e.g. MobileNetV2), loaded with
      ImageNet weights, top classification layer replaced with a new dense
      layer sized to the actual number of denomination classes found in the
      dataset
      │
      ▼
[Training loop] → fine-tune on the Pakistani notes training set, monitor
      validation accuracy/loss each epoch, use early stopping if validation
      performance stops improving (to avoid overfitting to the training set)
      │
      ▼
[Evaluation] → compute final validation accuracy AND a confusion matrix
      across all denomination classes — both must be reported, not just
      overall accuracy (per BR-3)
      │
      ▼
[Export to TensorFlow Lite] → convert the trained Keras model to .tflite
      │
      ▼
[Verify the exported .tflite] → reload it with the TFLite interpreter
      (Python-side, in the same Colab session) and run a test inference on
      a few validation images to confirm the exported file behaves
      identically to the pre-export model — catches export-time bugs before
      the file ever reaches the Flutter app
      │
      ▼
[Deliverable] → currency_classifier.tflite + a labels file listing the
      denomination classes in the exact index order the model outputs them
```

---

## 3. Phase B — In-App Integration Architecture (Flutter)

```
[User taps "Currency Classifier" on Home]
      │
      ▼
[CameraService (existing, reused)] → live preview in CameraBaseScreen
      │
      ▼
[Simple note-presence check] → lightweight check that something is
      reasonably filling the frame (not empty/black) before allowing
      capture — does not need Document Reader's rigorous 4-corner geometry,
      per FR-7 in the requirements doc
      │
      │  user taps shutter
      ▼
[Capture frame] → still image
      │
      ▼
[Preprocessing] → resize/normalize to the exact input shape the trained
      model expects (confirm this shape from the model itself at runtime,
      per TC-4 — do not hardcode an assumed size)
      │
      ▼
[CurrencyClassifierService] → runs the .tflite model via the same
      tflite_flutter interpreter pattern already used for Object Detection
      (per TC-5) → returns a class label + confidence score
      │
      ├── confidence below threshold ──► existing "Couldn't identify note
      │        clearly" error UI → Retry → back to capture step
      │
      └── confidence above threshold
             │
             ▼
      [Result formatting] → map the model's class index to the denomination
             label + the pre-written Urdu sentence for that denomination
             (e.g., "یہ دس روپے کا نوٹ ہے" for Rs 10) — matching the
             prototype's exact result-card format
             │
             ▼
      [Speak result] → TTS reads the Urdu sentence aloud automatically
             │
             ▼
      [User taps "Tap here to scan next note"] → back to capture step
```

---

## 4. Component Responsibilities (In-App)

### 4.1 `CurrencyClassifierService` (new)
Responsible only for running the trained model — no UI code, no camera code. Responsibilities:
- Load `currency_classifier.tflite` once (not per-tap)
- Read the model's actual input tensor shape at runtime and preprocess captured frames to match it exactly
- Run inference and return the top predicted class index plus its confidence score
- Apply the confidence threshold (per BR-1) and return a clear success/failure result type to the caller — mirrors the same pattern already used in `ObjectDetectionService`

### 4.2 `CurrencyResultFormatter` (new, small utility)
Responsible for mapping a class index to:
- The English denomination label ("Rs 10")
- The corresponding pre-written Urdu sentence (one fixed sentence per denomination, not AI-generated — these are known, fixed strings since there are only a handful of real denominations, unlike open-ended object descriptions)

### 4.3 `CurrencyScreen` (existing, modified)
Already exists as a `StatefulWidget` using `CameraBaseScreen`, currently driven by `_simulateClear()` / `_simulateBlurry()`. The real implementation replaces these with calls into `CurrencyClassifierService` + `CurrencyResultFormatter`, updating the exact same `_detectedUrdu` / `_detectedEnglish` / `_status` state variables the simulated version already uses — so the result-overlay UI needs zero visual changes.

### 4.4 Existing, reused, unchanged components
- `CameraBaseScreen` — unchanged
- `CameraService` — reused as-is
- The `tflite_flutter` interpreter-loading pattern already established for Object Detection — reused, not reimplemented separately

---

## 5. Where This Fits in the Whole App

```
training/                              (Python/Colab work, not shipped in the app)
 ├── pakistan/                         (existing dataset folder)
 ├── train_currency_classifier.ipynb   (new — training notebook)
 └── currency_classifier.tflite        (new — output, copied into the Flutter project)

lib/
 ├── core/
 │    ├── camera_service.dart              (existing — reused)
 │    ├── object_detection_service.dart     (existing, separate feature)
 │    ├── currency_classifier_service.dart  (new)
 │    └── currency_result_formatter.dart    (new)
 ├── screens/
 │    ├── currency_screen.dart              (existing — internal logic replaced)
 │    └── camera_base_screen.dart           (existing — unchanged)
 └── assets/
      └── models/
           ├── yolov8n.tflite                 (existing)
           └── currency_classifier.tflite     (new)
```

---

## 6. Why This Structure

Splitting Phase A (training) from Phase B (integration) as clearly separate, sequential phases — rather than trying to train and integrate simultaneously — mirrors how the YOLO/TFLite work was done earlier in this project (train/export in Colab first, verify the export, then integrate into Flutter). The in-app service split (`CurrencyClassifierService` for inference, `CurrencyResultFormatter` for presentation) mirrors the exact same single-responsibility pattern already used for Object Detection (`ObjectDetectionService` / `DetectionSentenceBuilder`), keeping the codebase consistent across every AI feature rather than each one inventing its own structure.
