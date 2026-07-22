# Document Reader Feature — Architecture

**Project:** Roshni — AI Vision Assistant for Blind and Low-Vision Users
**Module:** Document Reader
**Version:** 1.0

---

## 1. Overview

This document describes the internal structure of Document Reader, matching the approved prototype flow exactly: live camera → continuous edge-detection guidance ("Align all 4 corners," directional hints, "Positioned correctly — hold still") → user-triggered capture → OCR → line-by-line reading with a highlighted current line → success or the existing "not fully visible" error state.

---

## 2. High-Level Data Flow

```
[User taps "Document Reader" on Home]
      │
      ▼
[CameraService (existing, reused)] ──► live preview shown in CameraBaseScreen viewfinder
      │
      ▼
[DocumentEdgeDetector] → continuously analyzes live frames for document edges/corners
      │
      ├── Edges not fully visible/aligned ──► directional guidance message
      │        ("Move camera up slightly", "Move back", "Tilt down", etc.)
      │        → loop back to continuous analysis
      │
      └── All 4 edges detected & aligned ──► "Positioned correctly — hold still"
             │
             │  user taps shutter (explicit confirmation, per BR-2)
             ▼
      [Capture frame] → still image
             │
             ▼
      [Perspective correction] → warp/crop image to a flat, front-facing rectangle
             using the detected corner points
             │
             ▼
      [DocumentOCRService] → runs OCR (reusing existing Tesseract engine from
             Urdu OCR Reader) on the corrected image
             │
             ├── No usable text extracted ──► existing "Document not fully visible"
             │        error UI → Retry → back to edge-detection loop
             │
             └── Text extracted successfully
                    │
                    ▼
             [LineSequencer] → splits result into ordered lines, preserving
                    original top-to-bottom order (per BR-3)
                    │
                    ▼
             [Sequential read-aloud] → speaks one line at a time, highlighting
                    the current line in the UI (matching "▶ Doodh — 150 rupay")
                    │
                    ▼
             [User taps "Scan another document"] → back to live camera / edge detection
```

---

## 3. Component Responsibilities

### 3.1 `DocumentEdgeDetector` (new)
Responsible for continuous, lightweight analysis of live camera frames to find document boundaries. Responsibilities:
- Run edge/contour detection (via OpenCV) on a throttled stream of frames — using the same busy-flag frame-dropping pattern already established for Object Detection's continuous mode (never queue up backlogged frames)
- Determine whether four corner points can be confidently identified, and whether they roughly form a full, centered rectangle within the frame
- If not fully visible/aligned, compute which direction is most likely to help (e.g., top edge missing → "move up" or "move back"; document too small in frame → "move closer") and return that as a structured result, not a hardcoded single message
- If aligned, return a "ready to capture" state along with the four detected corner coordinates (needed later for perspective correction)
- This service does **not** run OCR — it only handles positioning/alignment detection

### 3.2 `PerspectiveCorrector` (new, small utility)
Responsible for taking the captured frame plus the four corner coordinates detected by `DocumentEdgeDetector` and applying a perspective warp (via OpenCV) so the final image is a flat, front-on rectangle rather than a skewed photo taken at an angle. This step significantly improves OCR accuracy compared to feeding OCR a raw, angled photo — it exists specifically to raise text-recognition reliability, not for cosmetic reasons.

### 3.3 `DocumentOCRService` (new, thin wrapper)
Responsible for calling into the **existing** Tesseract OCR engine already integrated for Urdu OCR Reader (per NFR-3/BR-5 in the constraints doc) — this is not a second OCR engine, it's a focused entry point that:
- Accepts the perspective-corrected image
- Runs OCR once (not continuously, per TC-2 in the constraints doc)
- Returns raw extracted text with per-line structure preserved (not one flattened blob), since line order matters for FR-6/BR-3

### 3.4 `LineSequencer` (new, small utility)
Responsible for taking raw OCR output and preparing it for the sequential read-aloud experience:
- Splits into individual lines in original top-to-bottom order
- Filters out lines that are empty or clearly OCR noise (e.g., single stray characters with very low confidence), without fabricating replacement text (per BR-4)
- Exposes a simple ordered list that the screen can step through one at a time, highlighting each as it's spoken

### 3.5 `DocumentReaderScreen` (existing, modified)
Already exists as a `StatefulWidget` using `CameraBaseScreen`, currently driven by two simulate methods. The real implementation:
- Replaces the static viewfinder placeholder with the live feed from `CameraService`
- Continuously calls `DocumentEdgeDetector` and updates the on-screen/spoken guidance caption in real time
- On "Positioned correctly," enables the shutter button (previously always active in the simulated version)
- On capture, runs `PerspectiveCorrector` → `DocumentOCRService` → `LineSequencer`, then updates the same `_status` / `_hasResult` / `_receiptItems`-style state the current simulated version already uses, so the result-overlay UI needs no visual changes
- Routes to the existing "Document not fully visible" error state when OCR yields no usable lines
- Keeps the two existing simulate buttons in place until the real flow is confirmed working end-to-end, then removes them in a final cleanup pass — same phased approach used for every other feature in this project

### 3.6 Existing, reused, unchanged components
- `CameraBaseScreen` — shared viewfinder/result UI shell; unchanged
- `CameraService` — reused as-is
- The Tesseract OCR engine/config already built for Urdu OCR Reader — reused, not duplicated
- `GestureBar`, `PrimaryButton` — unchanged

---

## 4. Where This Fits in the Whole App

```
lib/
 ├── core/
 │    ├── camera_service.dart              (existing — reused)
 │    ├── object_detection_service.dart    (existing, separate feature)
 │    ├── ocr_service.dart                 (existing, from Urdu OCR Reader — reused here)
 │    ├── document_edge_detector.dart      (new)
 │    ├── perspective_corrector.dart       (new)
 │    ├── document_ocr_service.dart        (new — thin wrapper around existing ocr_service.dart)
 │    └── line_sequencer.dart              (new)
 ├── screens/
 │    ├── document_screen.dart             (existing — internal logic replaced)
 │    └── camera_base_screen.dart          (existing — unchanged)
```

---

## 5. Why This Structure

Splitting edge detection, perspective correction, OCR, and line sequencing into four small, focused pieces (rather than one large "DocumentReaderService" doing everything) mirrors the same pattern already established for Object Detection (`CameraService` / `ObjectDetectionService` / `DetectionSentenceBuilder`) and Photo Description (`ConnectivityService` / `PhotoDescriptionService` / `ImagePreprocessor`). Each piece has one clear job, is independently testable, and — importantly — the OCR engine itself is explicitly reused rather than reimplemented, keeping Urdu text recognition consistent across both features that need it.
