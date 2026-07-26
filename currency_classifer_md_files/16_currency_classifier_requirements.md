# Currency Classifier Feature — Requirements Specification

**Project:** Roshni — AI Vision Assistant for Blind and Low-Vision Users
**Module:** Currency Classifier
**Version:** 1.0

---

## 1. Purpose

This document defines what the Currency Classifier feature must do, based on the already-approved UI prototype (`currency_screen.dart`). This feature lets a blind or low-vision user hold a Pakistani Rupee note up to their camera and hear the denomination spoken aloud in Urdu, using a custom-trained CNN model — this is the one feature in the app requiring an actual model **we train ourselves**, rather than a pretrained model used as-is (unlike Object Detection's pretrained YOLO or Urdu OCR's pretrained Tesseract).

---

## 2. Current State (baseline before backend implementation)

The existing `CurrencyScreen` is a **UI-only simulation** built on `CameraBaseScreen`. It currently shows: a live-camera-style placeholder with "Hold the note flat inside the frame," a shutter button, then "Note detected - hold steady," then "captured frame / CNN · TensorFlow Lite" with two simulate buttons ("Simulate clear" / "Simulate blurry") producing hardcoded results ("Rs 10" / "یہ دس روپے کا نوٹ ہے" or the error state "Couldn't identify note clearly"). This document defines what must be built to make this real — both the model training work and the in-app integration.

---

## 3. Functional Requirements (FR) — split into Training and In-App Integration

### 3.1 Model Training Requirements

**FR-1 — Train on the local Pakistani currency dataset**
A CNN model must be trained on the dataset located in the `pakistan` folder (organized by denomination), not a generic/foreign currency dataset, since Pakistani Rupee notes have unique designs not covered by any pretrained general-purpose model.

**FR-2 — Proper train/validation split**
The dataset must be split into a training set and a separate validation set (the model must never be validated on images it was trained on) — a standard split such as 80% train / 20% validation, unless the dataset's actual size/class balance requires adjustment (documented if so).

**FR-3 — Cover all real denominations present in the dataset**
The model must classify every denomination folder actually present in the dataset (e.g., Rs 10, 20, 50, 100, 500, 1000, 5000 — whichever are actually present as labeled classes) — the requirements doc does not assume a fixed list; it must match what the dataset actually contains.

**FR-4 — Report real, honest validation accuracy**
Training must produce and report an actual validation accuracy number and a confusion matrix (which denominations get confused with which) — training is not "done" just because it completes; it is done once real accuracy has been measured and reported honestly, including which denominations (if any) are harder to distinguish.

**FR-5 — Export to TFLite for on-device use**
The trained model must be exported to TensorFlow Lite format for on-device inference, consistent with the app's offline-first design (per the project's established Currency Classifier tech choice: "Custom CNN with TensorFlow Lite").

### 3.2 In-App Integration Requirements (matching the prototype exactly)

**FR-6 — Live camera preview**
Reuse the existing `CameraService` for a live camera feed, shown in the existing viewfinder, matching "Hold the note flat inside the frame."

**FR-7 — Note-in-frame guidance**
Before capture, the app should give simple positioning feedback so the user knows a note is reasonably present/framed (matching the prototype's "Note detected - hold steady" state) — this does not need the same rigorous 4-corner perspective-correction rigor as Document Reader, since a currency note's classification is more tolerant of moderate framing than reading fine print, but a completely absent/empty frame should not proceed to classification.

**FR-8 — Manual capture (tap to scan)**
Matching the prototype, capture is tap-triggered (shutter button), not fully automatic — the user taps once a note is reasonably positioned.

**FR-9 — On-device CNN inference**
Run the trained, exported TFLite model on the captured frame to classify the denomination — entirely on-device, no network call (per the project's established offline-first principle for this feature).

**FR-10 — Confidence threshold before announcing a result**
Only announce a denomination if the model's confidence for its top prediction is above a defined threshold (e.g., 70-80%, tuned based on real validation results from FR-4) — matching Object Detection's established principle ("never guess out loud").

**FR-11 — Success state (matching prototype exactly)**
On a confident classification, display and speak: the denomination in large text ("Rs 10"), the Urdu sentence ("یہ دس روپے کا نوٹ ہے"), and show "Speaking..." — then offer "Tap here to scan next note" to return to capture.

**FR-12 — Low-confidence/blurry error state (matching prototype exactly)**
On a low-confidence result, show "Couldn't identify note clearly" in red, the Urdu retry message ("نوٹ صاف نظر نہیں آ رہا، دوبارہ کوشش کریں"), and a "Retry" button that returns to the capture step — not force the user back to Home.

**FR-13 — Voice output automatic**
Both the success and error messages must be spoken automatically without requiring an extra tap, consistent with every other feature.

---

## 4. Non-Functional Requirements (NFR)

**NFR-1 — Offline operation**
The entire in-app inference pipeline (capture → classify → speak) must work with no internet connection, identical to Object Detection, Urdu OCR, and Document Reader.

**NFR-2 — Device performance**
Inference must run fast enough on low-end Android devices to feel responsive after a single tap (not multiple seconds of visible delay) — the model architecture/size choice during training must account for this target hardware, not just training-time accuracy in isolation.

**NFR-3 — Model size**
The exported `.tflite` file should be reasonably small for a low-end phone's storage constraints — favor a lightweight CNN architecture (e.g., a MobileNet-based transfer-learning approach) over a very large custom architecture, unless real accuracy testing shows a lightweight model is insufficient.

**NFR-4 — Honest accuracy reporting to supervisor**
Whatever real validation accuracy is achieved must be reported honestly (per FR-4) — this feature must not be presented as "99% accurate" without the actual measured number to back it up, consistent with the project's established honesty principle used for every other feature.

**NFR-5 — Accessibility consistency**
Same tap/double-tap/swipe gesture rules as every other screen.

---

## 5. Explicitly Out of Scope (for this iteration)

- Detecting counterfeit/fake notes — this feature classifies genuine note denominations only; counterfeit detection is a fundamentally different, much harder problem and is not part of this scope.
- Recognizing damaged, heavily worn, or partially torn notes reliably — the training dataset's real-world image quality determines what's realistically achievable here; this is a known limitation to document honestly, not silently promise around.
- Coin recognition — Pakistani coins are not in scope; this feature is for paper currency notes only, matching the dataset available.

---

## 6. Acceptance Criteria

- The trained model achieves and reports a real, measured validation accuracy (not an assumed or estimated one) on a held-out validation set it was never trained on.
- A user can open Currency Classifier, see a live camera feed, position a real Pakistani note, tap to capture, and hear the correct denomination spoken in Urdu within a responsive time frame, entirely offline.
- A blurry, unclear, or low-confidence capture correctly routes to the existing error/retry state rather than announcing a guessed denomination.
- No existing screen layout or navigation pattern is changed — only the simulated logic is replaced with the real trained-model pipeline.
