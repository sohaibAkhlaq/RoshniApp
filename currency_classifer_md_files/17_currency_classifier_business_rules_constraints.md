# Currency Classifier Feature — Business Rules & Constraints

**Project:** Roshni — AI Vision Assistant for Blind and Low-Vision Users
**Module:** Currency Classifier
**Version:** 1.0

---

## 1. Purpose

This document lists the rules and constraints specific to Currency Classifier — the feature with the highest real-world financial stakes in the app. A wrong denomination announcement here has a direct, immediate financial consequence for a blind user (accepting the wrong change, misjudging a payment) in a way most other features' errors do not. These rules exist to keep that risk taken seriously throughout training and integration.

---

## 2. Business Rules

**BR-1 — Never announce a denomination below the confidence threshold.**
This is the strictest version of the app's general "never guess out loud" principle, because the consequence of being wrong here is financial, not just informational. If the model is not confident, the app must say so and ask for a retry — it must never pick its "best guess" and announce it as fact just because some answer needs to be given.

**BR-2 — Validation accuracy must be measured on data the model never saw during training.**
Reporting training accuracy alone is not acceptable and would be misleading — the mandatory reported number is validation accuracy on the held-out split (per FR-2/FR-4 in the requirements doc). A model that memorizes its training images but fails on new photos would look good on paper and fail in real use; this rule exists specifically to prevent that false confidence.

**BR-3 — Report per-class accuracy/confusion, not just one overall number.**
An overall "92% accurate" figure can hide a real problem (e.g., Rs 100 confidently confused with Rs 500 specifically) that matters enormously given the financial stakes. The confusion matrix (per FR-4) must be reviewed, and any denomination pair with high confusion must be explicitly flagged to the supervisor, not buried in an average.

**BR-4 — Do not silently substitute a different/foreign dataset if the Pakistani dataset seems too small.**
If the local `pakistan` dataset turns out to have too few images per class for reliable training, the correct response is to flag this honestly (and consider data augmentation techniques, per TC-3 below) — not to quietly blend in a different country's currency images, which would corrupt what the model is actually supposed to recognize.

**BR-5 — The existing UI shell is final.**
`CameraBaseScreen`'s layout, the result-card style, the error-state design, and the gesture bar are already approved (matching the prototype exactly). This work replaces the two simulate methods' internal logic with the real trained model, not a redesign.

**BR-6 — Retry must not force a fresh camera restart.**
Matching the prototype's "Retry" and "Tap here to scan next note" actions, both must return directly to the capture-ready state, not force the user back through Home or a permissions re-check.

---

## 3. Technical Constraints

**TC-1 — Model architecture: CNN via transfer learning, not training from scratch.**
Per the project's established Currency Classifier tech choice, use a CNN built via transfer learning (e.g., starting from a pretrained lightweight base like MobileNetV2 and fine-tuning on the Pakistani notes dataset) rather than training a full architecture from random initialization — this produces better accuracy with a smaller dataset and less training time, which matters given this is a custom, from-scratch-for-this-project dataset rather than a massive public one.

**TC-2 — Training environment: Google Colab (or equivalent), not the local Windows machine.**
Consistent with how the YOLO/TFLite export work was done earlier in this project, model training should happen in an environment with proper GPU access and pre-installed ML libraries (Colab), not attempted directly on the local Windows development machine, to avoid the exact class of Python/TensorFlow dependency headaches already encountered earlier in this project.

**TC-3 — Data augmentation should be used given a realistically limited dataset size.**
A custom, locally-collected currency dataset is very unlikely to be as large as a massive public dataset. Standard image augmentation (rotation, brightness/contrast variation, slight blur, slight perspective changes) during training should be used to make the model more robust to real-world phone-camera conditions (varying lighting, slight angle, etc.), not just trained on the raw dataset as-is.

**TC-4 — Export format must be TensorFlow Lite, verified to load correctly in the app before considering training "done."**
Training is not complete when the `.h5`/native model file is produced — it is complete once the `.tflite` export has been verified to actually load and run inference correctly via `tflite_flutter` in the app (matching how the YOLO model's input/output shape was required to be verified at runtime rather than assumed, per the Object Detection integration guide's established precedent in this project).

**TC-5 — Reuse the existing TFLite interpreter setup, don't duplicate it.**
Since Object Detection already integrates `tflite_flutter` for running YOLO, the Currency Classifier's in-app inference should reuse the same interpreter-loading pattern/service structure already established, rather than introducing a second, differently-structured TFLite integration.

**TC-6 — Reuse `CameraService`, do not duplicate camera-handling code.**
Same constraint as every other camera-based feature in this app.

---

## 4. User-Safety / Financial-Stakes Constraint

**US-1 — This feature carries real financial risk if wrong; treat its error-handling with the highest rigor in the app.**
Unlike a wrong object-detection label (annoying but rarely harmful) or a wrong photo description (misleading but not usually financially consequential), an incorrect currency classification could directly cause a blind user to misjudge a real payment or accept incorrect change. The confidence threshold (BR-1) should be set conservatively — biased toward more "please retry" prompts rather than more wrong answers — and this tradeoff should be explicitly discussed with the supervisor as a deliberate design decision, not an incidental side effect of whatever threshold number happened to be picked.
