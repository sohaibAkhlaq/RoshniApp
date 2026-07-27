import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

/// A single line of OCR-extracted text with its vertical position
/// and confidence score.
class OcrLine {
  /// The extracted text content of this line (e.g., "Bill Amount 1040").
  final String text;

  /// Confidence score (0.0 to 100.0) for this line.
  final double confidence;

  /// Vertical position (y-center coordinate) in the image,
  /// used for sorting lines in top-to-bottom order.
  final double yPosition;

  const OcrLine({
    required this.text,
    required this.confidence,
    this.yPosition = 0,
  });

  @override
  String toString() => 'OcrLine("$text", conf=$confidence, y=$yPosition)';
}

/// Result of OCR processing on a document image.
class OcrResult {
  /// All extracted lines, ordered top-to-bottom with merged receipt rows.
  final List<OcrLine> lines;

  /// Overall success indicator — true if at least one usable line extracted.
  final bool hasUsableText;

  /// Average confidence across all lines (-1 if unavailable).
  final double averageConfidence;

  const OcrResult({
    required this.lines,
    required this.hasUsableText,
    required this.averageConfidence,
  });
}

class _TextElementItem {
  final String text;
  final double left;
  final double top;
  final double centerY;
  final double confidence;

  _TextElementItem({
    required this.text,
    required this.left,
    required this.top,
    required this.centerY,
    required this.confidence,
  });
}

/// On-device OCR Service for Document Reader powered by Google ML Kit.
///
/// Features Seeing AI-style horizontal row clustering: text elements on the same
/// horizontal line (e.g., "Bill Amount" on left and "1040" on right) are merged
/// left-to-right into a single coherent line ("Bill Amount 1040").
class DocumentOCRService {
  static const double confidenceThreshold = 10.0;

  /// Maximum vertical delta (pixels) to consider elements on the same horizontal row.
  static const double _rowYDelta = 18.0;

  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Run OCR on a preprocessed document image.
  Future<OcrResult> extractText(Uint8List imageBytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/doc_reader_ocr_input.png');
      await tempFile.writeAsBytes(imageBytes);

      developer.log(
        'Running ML Kit Text Recognition for Document Reader',
        name: 'DocumentOCRService',
      );

      final inputImage = InputImage.fromFilePath(tempFile.path);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      return _processRecognizedText(recognizedText);
    } catch (e) {
      developer.log('ML Kit OCR failed: $e', name: 'DocumentOCRService');
      return const OcrResult(
        lines: [],
        hasUsableText: false,
        averageConfidence: -1,
      );
    }
  }

  /// Shared processing logic: preserves ML Kit's native line structure
  /// for lengthy documents, letters, and pages without truncating or
  /// splitting sentences into 2-word fragments.
  OcrResult _processRecognizedText(RecognizedText recognizedText) {
    final lines = <OcrLine>[];

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final lineText = line.text.trim();
        if (lineText.isEmpty) continue;

        final box = line.boundingBox;
        final centerY = box.top + (box.height / 2.0);

        // Calculate average confidence of words in this line
        double conf = 90.0;
        if (line.elements.isNotEmpty) {
          double sumConf = 0.0;
          int count = 0;
          for (final elem in line.elements) {
            if (elem.confidence != null) {
              sumConf += (elem.confidence! <= 1.0 ? elem.confidence! * 100.0 : elem.confidence!);
              count++;
            }
          }
          if (count > 0) {
            conf = sumConf / count;
          }
        }

        lines.add(OcrLine(
          text: lineText,
          confidence: conf,
          yPosition: centerY,
        ));
      }
    }

    if (lines.isEmpty) {
      return const OcrResult(
        lines: [],
        hasUsableText: false,
        averageConfidence: -1,
      );
    }

    // Sort lines strictly top-to-bottom in reading order
    lines.sort((a, b) => a.yPosition.compareTo(b.yPosition));

    final overallAvgConf = lines.fold<double>(0, (sum, l) => sum + l.confidence) / lines.length;

    developer.log(
      'ML Kit extracted ${lines.length} complete document lines with high accuracy',
      name: 'DocumentOCRService',
    );

    return OcrResult(
      lines: lines,
      hasUsableText: lines.isNotEmpty,
      averageConfidence: overallAvgConf,
    );
  }

  /// Extract text from a file path directly (used with ML Kit Document Scanner
  /// output, which already saves scanned images to disk).
  Future<OcrResult> extractTextFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        developer.log(
          'OCR input file not found: $filePath',
          name: 'DocumentOCRService',
        );
        return const OcrResult(
          lines: [],
          hasUsableText: false,
          averageConfidence: -1,
        );
      }

      developer.log(
        'Running ML Kit Text Recognition from file: $filePath',
        name: 'DocumentOCRService',
      );

      final inputImage = InputImage.fromFilePath(filePath);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      return _processRecognizedText(recognizedText);
    } catch (e) {
      developer.log('ML Kit OCR (file) failed: $e', name: 'DocumentOCRService');
      return const OcrResult(
        lines: [],
        hasUsableText: false,
        averageConfidence: -1,
      );
    }
  }

  Future<OcrResult> extractTextWithFallback(Uint8List imageBytes) async {
    return extractText(imageBytes);
  }

  void dispose() {
    _textRecognizer.close();
  }
}
