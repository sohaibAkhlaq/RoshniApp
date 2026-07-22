# Document Reader Feature — Requirements Specification

**Project:** Roshni — AI Vision Assistant for Blind and Low-Vision Users
**Module:** Document Reader
**Version:** 1.0

---

## 1. Purpose

This document defines what the Document Reader feature must do, based on the already-approved UI prototype (`document_screen.dart`). Document Reader lets a blind or low-vision user point their camera at a printed document — a bill, receipt, or medicine slip — and have the app guide them to position it correctly, then read its contents aloud line by line.

---

## 2. Current State (baseline before backend implementation)

The existing `DocumentScreen` is a **UI-only simulation** built on the shared `CameraBaseScreen` widget. It currently shows: a camera placeholder with the caption "Align all 4 corners of the page / Move camera up slightly," a "Continue" button, then two simulate buttons ("Simulate readable" / "Simulate not visible") that swap in hardcoded receipt-style result text (item lines, a total, and a "Reading line by line..." indicator). This document defines what must be built to make this real, without changing the already-approved screen.

---

## 3. Functional Requirements (FR)

**FR-1 — Live camera preview**
The screen must show a real live camera feed (reusing the existing `CameraService`), matching FR-1-style requirements already established for Object Detection and Photo Description.

**FR-2 — Corner/edge detection for positioning guidance**
Before capturing, the app must continuously analyze the live frame using edge detection (via OpenCV) to determine whether all four corners/edges of a document are visible and reasonably aligned within the frame. This is the feature's signature behavior shown in the prototype ("Align all 4 corners of the page," "Move camera up slightly").

**FR-3 — Directional guidance messages**
While the document is not yet well-positioned, the app must give the user a short, specific spoken/displayed instruction to help them adjust (e.g., "Move camera up slightly," "Move camera back," "Tilt camera down") based on which edge(s) are missing or which direction the document is off-center — not a single generic "can't see it" message every time, since specific directional guidance is what actually helps a blind user correct their aim.

**FR-4 — Positioned-correctly confirmation**
Once all four edges are detected as reasonably aligned, the app must show/speak the existing "Positioned correctly — hold still" state (already in the prototype) and prompt the user to capture (tap the shutter).

**FR-5 — OCR text extraction after capture**
On capture, the app must run OCR (reusing the same Tesseract engine already integrated for the Urdu OCR Reader feature) across the captured document image to extract all readable text lines.

**FR-6 — Line-by-line reading with progress highlight**
Extracted text must be read aloud **line by line**, not as one large block all at once. The currently-being-spoken line must be visually highlighted in the result UI (matching the prototype's "▶ Doodh — 150 rupay" highlighted-first-line pattern), so a low-vision user who can see some contrast can follow along visually while it's spoken.

**FR-7 — Structured total handling (where applicable)**
For receipt/bill-style documents where a "Total" line is present, the app should still read it as part of the line-by-line sequence, matching the prototype exactly (item lines, then total, in order) — no special-casing that skips or reorders it.

**FR-8 — No-detection / not-fully-visible error state (already designed)**
If the document cannot be reliably read (missing edges even after capture, or OCR produces no usable text), the app must show the existing "Document not fully visible — Please include all edges of the page" error screen with a Retry action, matching the prototype exactly.

**FR-9 — Retry returns to positioning guidance, not force a totally fresh start**
"Retry" (per FR-8) must return the user to the corner-alignment guidance step (FR-2/FR-3), not require navigating back to Home and re-entering the feature.

**FR-10 — "Scan another document"**
On a successful read, the existing "Tap here to scan another document" action must return the user to the camera/positioning step (FR-1/FR-2) to read a new document.

**FR-11 — Voice output**
All spoken output (positioning guidance, line-by-line reading, error messages) must play automatically without requiring an extra tap, consistent with every other feature in the app.

---

## 4. Non-Functional Requirements (NFR)

**NFR-1 — Positioning check must run continuously and responsively**
The edge-detection check must re-evaluate frequently enough that a user actively adjusting their phone gets timely feedback (not a multi-second lag between moving the phone and hearing updated guidance) — this matters because a blind user has no visual confirmation and is relying entirely on this feedback loop to aim the camera.

**NFR-2 — Offline operation**
Document Reader must work fully offline, identical to Object Detection, Urdu OCR, and Currency Classifier — Tesseract OCR and OpenCV edge detection both run on-device, no network dependency (unlike Photo Description, which is the one deliberately online feature).

**NFR-3 — Reuse, don't duplicate, the existing Tesseract OCR integration**
Since Urdu OCR Reader already integrates Tesseract, Document Reader must reuse that same underlying OCR engine/service rather than bundling or initializing a second separate instance.

**NFR-4 — Device performance**
Edge-detection frame analysis must be lightweight enough to run continuously on low-end Android devices without freezing the camera preview — same performance discipline already established for Object Detection's continuous mode (background processing, no UI-thread blocking).

**NFR-5 — Accessibility consistency**
Same tap/double-tap/swipe gesture rules as every other screen — no new gesture pattern introduced for this feature.

---

## 5. Explicitly Out of Scope (for this iteration)

- Structured/itemized parsing of receipts into a database or categorized format (e.g., separating "groceries" vs. "utilities") — this feature reads text aloud in order, it does not categorize or interpret meaning beyond that.
- Multi-page document scanning in one session — one document/page per capture, matching the prototype exactly.
- Handwriting recognition — this reuses the same printed-text-oriented Tesseract configuration as Urdu OCR Reader; handwritten prescriptions or notes are a known, accepted limitation (same honesty principle as the Object Detection requirements doc's COCO-class limitation).

---

## 6. Acceptance Criteria

- Opening Document Reader shows a real live camera feed with real-time positioning guidance as the user moves the phone.
- The app gives specific directional feedback (not just "can't see it") while the document is misaligned, and clearly confirms "Positioned correctly — hold still" once aligned.
- After capture, extracted text is read aloud strictly line by line with the current line visually highlighted, matching the prototype's result layout.
- A document with missing/unclear edges or unreadable text correctly routes to the existing error screen with Retry, which returns to the positioning step rather than Home.
- The entire feature functions identically with the phone in airplane mode.
