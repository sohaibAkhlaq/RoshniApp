import 'document_ocr_service.dart';

/// A single line prepared for sequential read-aloud display.
class ReadableLine {
  /// The text to display and speak.
  final String text;

  /// Whether this line's OCR confidence was above the threshold.
  final bool isHighConfidence;

  /// Original confidence score for diagnostic purposes.
  final double confidence;

  const ReadableLine({
    required this.text,
    required this.isHighConfidence,
    required this.confidence,
  });
}

/// Prepares OCR output for sequential read-aloud display.
///
/// Responsibilities:
/// - Sorts lines top-to-bottom by vertical position (BR-3).
/// - Filters out noise, non-alphanumeric garbage, and low-confidence text (BR-4, US-1).
/// - Guarantees that only meaningful text is presented to the blind user.
class LineSequencer {
  final double confidenceThreshold;

  /// Minimum number of alphanumeric characters required per line.
  static const int _minAlphaNumChars = 3;

  LineSequencer({
    this.confidenceThreshold = DocumentOCRService.confidenceThreshold,
  });

  /// Process raw OCR results into an ordered list of readable lines.
  ///
  /// Returns an empty list if no valid meaningful text passes filtering,
  /// triggering the "Document not fully visible" error state.
  List<ReadableLine> sequenceLines(OcrResult ocrResult) {
    if (!ocrResult.hasUsableText) return const [];

    final readableLines = <ReadableLine>[];

    // Sort lines top-to-bottom by vertical position (yPosition)
    final sortedLines = List<OcrLine>.from(ocrResult.lines)
      ..sort((a, b) => a.yPosition.compareTo(b.yPosition));

    for (final line in sortedLines) {
      final trimmed = line.text.trim();

      // Check 1: Minimum character length
      if (trimmed.length < _minAlphaNumChars) continue;

      // Check 2: Verify line contains meaningful alphanumeric text
      if (!_isMeaningfulText(trimmed)) continue;

      // Check 3: Confidence threshold check (per BR-4 & US-1)
      final isHighConf = line.confidence < 0 || line.confidence >= confidenceThreshold;
      if (!isHighConf) continue;

      readableLines.add(ReadableLine(
        text: trimmed,
        isHighConfidence: isHighConf,
        confidence: line.confidence,
      ));
    }

    return readableLines;
  }

  /// Verifies that a text line contains meaningful language content
  /// rather than stray symbols, noise, or barcode/border artifacts.
  bool _isMeaningfulText(String text) {
    // Count alphanumeric runes (Latin + Urdu/Unicode letters + Digits)
    final alphaNumCount = text.runes.where((r) {
      final isDigit = r >= 48 && r <= 57;
      final isUpper = r >= 65 && r <= 90;
      final isLower = r >= 97 && r <= 122;
      final isExtendedUnicode = r > 127;
      return isDigit || isUpper || isLower || isExtendedUnicode;
    }).length;

    if (alphaNumCount < _minAlphaNumChars) return false;

    // Must be at least 40% alphanumeric characters
    final ratio = alphaNumCount / text.length;
    return ratio >= 0.40;
  }
}
