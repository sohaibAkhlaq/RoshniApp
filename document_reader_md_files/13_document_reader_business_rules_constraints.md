# Document Reader Feature — Business Rules & Constraints

**Project:** Roshni — AI Vision Assistant for Blind and Low-Vision Users
**Module:** Document Reader
**Version:** 1.0

---

## 1. Purpose

This document lists the rules and constraints specific to Document Reader — the feature most dependent on precise, real-time visual guidance for a user who cannot see the camera preview themselves. These rules exist to keep that guidance loop honest and genuinely usable, not just technically functional.

---

## 2. Business Rules

**BR-1 — Guidance messages must be specific and directional, never vague.**
"Can't see the document" or "try again" is not acceptable as ongoing positioning feedback. The app must tell the user *which direction* to adjust (up, down, left, right, closer, further back) based on what the edge-detection actually observed missing or misaligned — because a blind user's only feedback loop for aiming a camera is what the app tells them, unlike a sighted user who can just look at the screen.

**BR-2 — Never auto-capture without explicit confirmation from the user.**
Even once "Positioned correctly — hold still" is detected, the app must not automatically snap the photo. The user must still tap to capture (matching the prototype's shutter-button pattern). This avoids capturing at an unintended moment and keeps the user in control of the action, consistent with the app's global "tap = confirm" gesture rule.

**BR-3 — Reading order must exactly follow the document's natural line order.**
The app must not reorder, summarize, or skip lines when reading a bill/receipt/slip aloud (per FR-6/FR-7 in the requirements doc) — a blind user relying on this to know their exact bill total or medicine dosage instructions needs the actual order preserved, not an AI-reorganized version.

**BR-4 — Never guess or fabricate text that OCR could not confidently read.**
If Tesseract OCR fails to extract usable text from part of a line, the app must not fill in a guessed word to make the sentence sound complete. It is better to skip an unclear word/line or route to the "not fully visible" error state than to state something the app is not actually confident about — this mirrors Object Detection's BR-1 ("never guess out loud") applied to text instead of objects.

**BR-5 — Reuse the existing OCR engine; do not introduce a second, different one.**
Since Urdu OCR Reader already integrates Tesseract OCR, Document Reader must call into that same underlying service/engine (per NFR-3 in the requirements doc). Introducing a second, separately-configured OCR engine for this feature would create inconsistent behavior between two features that should read text the same way.

**BR-6 — The existing UI shell is final; this work adds real logic behind it, not a redesign.**
The `CameraBaseScreen` layout, the positioning-guidance caption placement, the highlighted-line result card, and the gesture bar are already approved. Implementation replaces the two simulate methods' internals, not the visual design.

---

## 3. Technical Constraints

**TC-1 — Edge detection via OpenCV, running continuously on the live feed.**
Corner/edge detection must run as a lightweight, continuous analysis of camera frames (similar in spirit to Object Detection's continuous frame processing) — it is a classical image-processing technique (contour/edge detection), not a machine-learning model, and should be correspondingly fast and low-resource.

**TC-2 — OCR only runs once, on the final captured frame — not continuously.**
Unlike edge detection (which must run continuously for positioning feedback per NFR-1), OCR text extraction is comparatively heavier and only needs to run once, after the user taps to capture a well-positioned frame. Running full OCR continuously on every frame would be wasteful and unnecessarily slow.

**TC-3 — Reuse `CameraService`, do not duplicate camera-handling code.**
Same constraint as every other camera-based feature in this app — Document Reader must use the existing `CameraService` for camera lifecycle and permission handling, not implement its own.

**TC-4 — Hardware ceiling: low-end Android devices.**
Same target device profile as the rest of the app. OpenCV's edge-detection operations must be chosen/tuned to run smoothly on budget hardware, not assume flagship-level processing power.

**TC-5 — Printed text only, same limitation already accepted for Urdu OCR Reader.**
Since this feature reuses the same Tesseract configuration, it inherits the same known limitation: reliable for clean printed text (bills, medicine box labels), less reliable for handwritten prescriptions or messy handwriting. This must be documented, not silently papered over with a guess (per BR-4).

---

## 4. User-Safety Constraint

**US-1 — Medicine slip content carries higher real-world stakes than a shop receipt.**
Because this feature is explicitly intended to read medicine slips (per the requirements doc's scope) in addition to bills, a misread dosage or medicine name is a more serious error than a misread grocery item price. This reinforces BR-4 especially strongly for this feature: when OCR confidence is low on a document that appears to be a medicine slip, the app should prefer the "not fully visible, please retry" error path over reading aloud a low-confidence guess about medication instructions.
