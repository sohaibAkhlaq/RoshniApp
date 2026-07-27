import 'dart:developer' as developer;
import 'dart:io';

import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

/// Result returned after the ML Kit Document Scanner completes.
class DocumentScanResult {
  /// Whether scanning was successful.
  final bool success;

  /// File paths to the scanned document images (already perspective-corrected
  /// and cropped by Google's native engine).
  final List<String> imagePaths;

  /// User-facing message describing what happened.
  final String message;

  const DocumentScanResult({
    required this.success,
    required this.imagePaths,
    required this.message,
  });
}

/// Thin wrapper around Google ML Kit Document Scanner.
///
/// Replaces the previous hand-rolled OpenCV Canny+contour approach which
/// could not reliably distinguish documents from real-world backgrounds.
/// Google's native scanner provides production-grade edge detection,
/// auto-capture, perspective correction, and a polished scanning UI — all
/// via Google Play Services.
class DocumentEdgeDetector {
  DocumentScanner? _scanner;

  /// Launch Google's native document scanner.
  ///
  /// Opens a full-screen native scanning activity with:
  /// - Automatic document edge detection
  /// - Auto-capture when the document is stable
  /// - Manual capture fallback (user can tap)
  /// - Built-in perspective correction and cropping
  ///
  /// Returns a [DocumentScanResult] with the captured image paths on success,
  /// or a failure result if the user cancelled or an error occurred.
  Future<DocumentScanResult> scanDocument() async {
    try {
      // Configure the scanner for single-page document capture in base mode
      // to bypass manual filter/enhance editing screens that trap blind users.
      final options = DocumentScannerOptions(
        documentFormats: const {DocumentFormat.jpeg},
        mode: ScannerMode.base, // Base mode without manual editing/filter UI
        pageLimit: 1, // Single page per scan (matches prototype)
        isGalleryImport: false, // Camera-only, no gallery import
      );

      _scanner = DocumentScanner(options: options);
      final result = await _scanner!.scanDocument();

      // Extract image paths from the result
      final images = result.images;

      if (images == null || images.isEmpty) {
        return const DocumentScanResult(
          success: false,
          imagePaths: [],
          message: 'No document images captured',
        );
      }

      // Verify captured files actually exist
      final validPaths = <String>[];
      for (final path in images) {
        if (await File(path).exists()) {
          validPaths.add(path);
          developer.log(
            'Scanned document image: $path',
            name: 'DocumentEdgeDetector',
          );
        }
      }

      if (validPaths.isEmpty) {
        return const DocumentScanResult(
          success: false,
          imagePaths: [],
          message: 'Captured images not found on disk',
        );
      }

      return DocumentScanResult(
        success: true,
        imagePaths: validPaths,
        message: 'Document scanned successfully',
      );
    } catch (e) {
      developer.log(
        'Document scanner error: $e',
        name: 'DocumentEdgeDetector',
      );

      // Handle user cancellation (PlatformException with "canceled")
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('cancel')) {
        return const DocumentScanResult(
          success: false,
          imagePaths: [],
          message: 'Scanning cancelled',
        );
      }

      return DocumentScanResult(
        success: false,
        imagePaths: [],
        message: 'Scanner error: $e',
      );
    }
  }

  /// Release scanner resources.
  void close() {
    _scanner?.close();
    _scanner = null;
  }

  // Legacy API stubs — kept temporarily so existing code compiles during
  // migration, but these are no-ops now. Will be removed in cleanup.
  void resetState() {}
}
