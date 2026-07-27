import 'dart:isolate';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'dart:developer' as developer;

/// Represents a normalized 4-point quadrilateral found in the image.
/// Coordinates are 0.0 to 1.0.
class NormalizedQuad {
  final double topLeftX;
  final double topLeftY;
  final double topRightX;
  final double topRightY;
  final double bottomRightX;
  final double bottomRightY;
  final double bottomLeftX;
  final double bottomLeftY;

  const NormalizedQuad({
    required this.topLeftX,
    required this.topLeftY,
    required this.topRightX,
    required this.topRightY,
    required this.bottomRightX,
    required this.bottomRightY,
    required this.bottomLeftX,
    required this.bottomLeftY,
  });

  /// The center X of the quad.
  double get centerX => (topLeftX + topRightX + bottomRightX + bottomLeftX) / 4;

  /// The center Y of the quad.
  double get centerY => (topLeftY + topRightY + bottomRightY + bottomLeftY) / 4;

  /// The approximate area of the quad in normalized space (0.0 to 1.0).
  double get area {
    // Simple Shoelace formula for area
    final double x1 = topLeftX, y1 = topLeftY;
    final double x2 = topRightX, y2 = topRightY;
    final double x3 = bottomRightX, y3 = bottomRightY;
    final double x4 = bottomLeftX, y4 = bottomLeftY;
    return 0.5 * ((x1 * y2 + x2 * y3 + x3 * y4 + x4 * y1) -
            (y1 * x2 + y2 * x3 + y3 * x4 + y4 * x1))
        .abs();
  }
}

class LiveQuadDetector {
  /// Analyzes a [CameraImage] to find the largest document-like quad.
  /// This runs in an isolate to prevent UI stutter.
  Future<NormalizedQuad?> detectQuad(CameraImage image) async {
    // For performance, we only process the Y plane (grayscale) from YUV420
    if (image.format.group != ImageFormatGroup.yuv420 && image.format.group != ImageFormatGroup.nv21) {
      developer.log('Unsupported image format for live quad detection: \${image.format.group}');
      return null;
    }

    // Send the Y-plane data to the isolate
    final yPlaneBytes = image.planes[0].bytes;
    final width = image.width;
    final height = image.height;

    return await Isolate.run(() => _processFrame(yPlaneBytes, width, height));
  }

  static NormalizedQuad? _processFrame(List<int> yBytes, int width, int height) {
    try {
      // 1. Create a grayscale Mat directly from the Y plane bytes
      final grayMat = cv.Mat.fromList(height, width, cv.MatType.CV_8UC1, yBytes);

      // STEP 1 - Downscale before processing
      const targetWidth = 500.0;
      final scaleRatio = width / targetWidth;
      final targetHeight = (height / scaleRatio).round();
      final resizedMat = cv.resize(grayMat, (targetWidth.toInt(), targetHeight), interpolation: cv.INTER_AREA);

      // STEP 2 - Grayscale + blur
      // Already grayscale (from Y-plane). Apply Gaussian Blur to reduce noise.
      final blurred = cv.gaussianBlur(resizedMat, (5, 5), 0, sigmaY: 0);

      // STEP 3 - Adaptive ("auto") Canny edge detection
      final meanStdDev = cv.meanStdDev(blurred);
      final meanVal = meanStdDev.$1.val[0];
      final lowerThresh = math.max(0.0, meanVal * 0.66);
      final upperThresh = math.min(255.0, meanVal * 1.33);
      final edges = cv.canny(blurred, lowerThresh, upperThresh);

      // STEP 4 - Morphological closing/dilation (CRITICAL)
      // Bridge small gaps in the detected edges caused by shadows or uneven lighting
      final kernel = cv.getStructuringElement(cv.MORPH_RECT, (3, 3));
      final dilated = cv.dilate(edges, kernel, iterations: 2);

      // STEP 5 - Find contours
      final contours = cv.findContours(dilated, cv.RETR_LIST, cv.CHAIN_APPROX_SIMPLE).$1;

      // STEP 6 - Filter and rank candidates
      final frameArea = targetWidth * targetHeight;
      final minArea = frameArea * 0.05;
      final maxArea = frameArea * 0.95;

      final validContours = <(double, cv.VecPoint)>[];
      for (var i = 0; i < contours.length; i++) {
        final contour = contours[i];
        final area = cv.contourArea(contour);
        if (area > minArea && area < maxArea) {
          validContours.add((area, contour));
        }
      }

      // Sort remaining contours by area, largest first
      validContours.sort((a, b) => b.$1.compareTo(a.$1));

      List<cv.Point>? bestQuadPoints;
      // STEP 7 - Convex hull + multi-epsilon polygon approximation with extreme corners fallback
      for (final item in validContours) {
        final contour = item.$2;
        final hullMat = cv.convexHull(contour);
        final hullPoints = cv.VecPoint.fromMat(hullMat);
        final perimeter = cv.arcLength(hullPoints, true);

        // Try multiple epsilon tolerances to find a 4-point approximation
        for (double eps = 0.015; eps <= 0.05; eps += 0.005) {
          final approx = cv.approxPolyDP(hullPoints, eps * perimeter, true);
          if (approx.length == 4) {
            final rect = cv.boundingRect(approx);
            final aspectRatio = rect.width / rect.height;
            if (aspectRatio > 0.2 && aspectRatio < 5.0) {
              bestQuadPoints = approx.toList();
              break;
            }
          }
        }

        // If exact 4-point approximation failed, fallback to 4 extreme corners of the largest contour
        if (bestQuadPoints == null && hullPoints.length >= 4) {
          final pts = hullPoints.toList();
          pts.sort((a, b) => (a.x + a.y).compareTo(b.x + b.y));
          final tl = pts.first;
          final br = pts.last;

          pts.sort((a, b) => (a.x - a.y).compareTo(b.x - b.y));
          final bl = pts.first;
          final tr = pts.last;

          final w = (tr.x - tl.x).abs();
          final h = (bl.y - tl.y).abs();
          if (w > 0 && h > 0) {
            final aspectRatio = w / h;
            if (aspectRatio > 0.2 && aspectRatio < 5.0) {
              bestQuadPoints = [tl, tr, br, bl];
            }
          }
        }

        if (bestQuadPoints != null) break;
      }

      if (bestQuadPoints != null) {
        // STEP 8 - Corner ordering
        final points = bestQuadPoints;
        
        points.sort((a, b) => (a.x + a.y).compareTo(b.x + b.y));
        final topLeft = points[0];
        final bottomRight = points[3];

        final remaining = [points[1], points[2]];
        remaining.sort((a, b) => (a.x - a.y).compareTo(b.x - b.y));
        final bottomLeft = remaining[0];
        final topRight = remaining[1];

        // STEP 9 - Scale corners back to full resolution
        // Since we are outputting a NormalizedQuad (0.0 to 1.0 coordinates), 
        // the scale ratio mathematically cancels out when we divide by target width/height!
        // X_target / targetWidth == X_orig / origWidth
        return NormalizedQuad(
          topLeftX: topLeft.x / targetWidth,
          topLeftY: topLeft.y / targetHeight,
          topRightX: topRight.x / targetWidth,
          topRightY: topRight.y / targetHeight,
          bottomRightX: bottomRight.x / targetWidth,
          bottomRightY: bottomRight.y / targetHeight,
          bottomLeftX: bottomLeft.x / targetWidth,
          bottomLeftY: bottomLeft.y / targetHeight,
        );
      }

      return null;
    } catch (e) {
      developer.log('Error in live quad detector: $e');
      return null;
    }
  }
}
