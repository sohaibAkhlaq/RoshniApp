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
  static const double confidenceThreshold = 60.0;

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
        'Running ML Kit Text Recognition with Key-Value Row Merging',
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

  /// Shared processing logic: extracts text elements from ML Kit's
  /// RecognizedText, clusters them into horizontal rows (receipt-style
  /// key-value merging), and returns them as ordered OcrLines.
  OcrResult _processRecognizedText(RecognizedText recognizedText) {
    // Collect all text elements across all blocks & lines
    final allElements = <_TextElementItem>[];

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final lineText = line.text.trim();
        if (lineText.isEmpty) continue;

        if (line.elements.isNotEmpty) {
          for (final elem in line.elements) {
            final elemText = elem.text.trim();
            if (elemText.isEmpty) continue;

            final box = elem.boundingBox;
            final centerY = box.top + (box.height / 2.0);
            final conf = elem.confidence != null
                ? (elem.confidence! <= 1.0 ? elem.confidence! * 100.0 : elem.confidence!)
                : 90.0;

            allElements.add(_TextElementItem(
              text: elemText,
              left: box.left.toDouble(),
              top: box.top.toDouble(),
              centerY: centerY,
              confidence: conf,
            ));
          }
        } else {
          // Fallback for lines without elements
          final box = line.boundingBox;
          final centerY = box.top + (box.height / 2.0);
          allElements.add(_TextElementItem(
            text: lineText,
            left: box.left.toDouble(),
            top: box.top.toDouble(),
            centerY: centerY,
            confidence: 90.0,
          ));
        }
      }
    }

    if (allElements.isEmpty) {
      return const OcrResult(
        lines: [],
        hasUsableText: false,
        averageConfidence: -1,
      );
    }

    // Step 1: Cluster elements into horizontal rows (Y-center within _rowYDelta)
    final rowClusters = <List<_TextElementItem>>[];

    // Sort elements vertically first to seed row clustering cleanly
    allElements.sort((a, b) => a.centerY.compareTo(b.centerY));

    for (final elem in allElements) {
      bool addedToCluster = false;
      for (final cluster in rowClusters) {
        final clusterAvgY =
            cluster.fold<double>(0, (sum, item) => sum + item.centerY) / cluster.length;
        if ((elem.centerY - clusterAvgY).abs() <= _rowYDelta) {
          cluster.add(elem);
          addedToCluster = true;
          break;
        }
      }
      if (!addedToCluster) {
        rowClusters.add([elem]);
      }
    }

    // Step 2: For each row cluster, sort left-to-right by X-coordinate & merge text
    final lines = <OcrLine>[];

    for (final cluster in rowClusters) {
      // Sort items strictly left-to-right
      cluster.sort((a, b) => a.left.compareTo(b.left));

      final mergedText = cluster.map((e) => e.text).join(' ');
      if (mergedText.trim().isEmpty) continue;

      final avgY =
          cluster.fold<double>(0, (sum, item) => sum + item.centerY) / cluster.length;
      final avgConf =
          cluster.fold<double>(0, (sum, item) => sum + item.confidence) / cluster.length;

      lines.add(OcrLine(
        text: mergedText,
        confidence: avgConf,
        yPosition: avgY,
      ));
    }

    // Step 3: Sort merged lines top-to-bottom
    lines.sort((a, b) => a.yPosition.compareTo(b.yPosition));

    final overallAvgConf = lines.isEmpty
        ? -1.0
        : lines.fold<double>(0, (sum, l) => sum + l.confidence) / lines.length;

    developer.log(
      'ML Kit merged ${lines.length} key-value receipt rows',
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
