import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Resizes and compresses a captured image before upload (per TC-3 /
/// NFR-3), reducing data usage for users on metered connections and
/// staying within the captioning API's payload size limits.
///
/// Kept as a small, standalone utility so it can be reused by any
/// future feature that needs to prepare a captured image before upload
/// or storage.
class ImagePreprocessor {
  /// Maximum dimension (width or height) of the resized image.
  /// The longest side is scaled to this value; the other side is
  /// calculated to preserve aspect ratio.
  static const int _maxDimension = 512;

  /// JPEG quality (0-100).  80 is a good balance between file size
  /// and visual quality for captioning models.
  static const int _jpegQuality = 80;

  /// Decodes, resizes, and re-encodes [imageBytes] as a compressed
  /// JPEG.  Returns the processed bytes ready for network upload.
  ///
  /// Throws [StateError] if the image cannot be decoded.
  Uint8List preprocess(Uint8List imageBytes) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw StateError('Failed to decode image for preprocessing.');
    }

    final resized = decoded.width >= decoded.height
        ? img.copyResize(
            decoded,
            width: _maxDimension,
            interpolation: img.Interpolation.linear,
          )
        : img.copyResize(
            decoded,
            height: _maxDimension,
            interpolation: img.Interpolation.linear,
          );

    final jpgBytes = img.encodeJpg(resized, quality: _jpegQuality);
    return Uint8List.fromList(jpgBytes);
  }
}
