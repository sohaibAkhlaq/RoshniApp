import 'package:flutter/foundation.dart';
import 'live_quad_detector.dart';

enum GuidanceInstruction {
  searching,
  moveBack,
  moveCloser,
  moveLeft,
  moveRight,
  moveUp,
  moveDown,
  straighten,
  holdSteady,
  stable,
}

class GuidanceEngine {
  /// Number of consecutive 'holdSteady' frames required to transition to 'stable'.
  final int requiredStableFrames;
  
  int _stableCounter = 0;
  GuidanceInstruction _lastInstruction = GuidanceInstruction.searching;

  GuidanceEngine({this.requiredStableFrames = 10});

  /// Evaluates the quad and returns the appropriate guidance instruction.
  GuidanceInstruction evaluate(NormalizedQuad? quad) {
    if (quad == null) {
      _stableCounter = 0;
      return _updateInstruction(GuidanceInstruction.searching);
    }

    // 1. Check if the document is clipped (corners too close to the image edges)
    // Using a 5% margin
    const double edgeMargin = 0.05;
    final isClipped = quad.topLeftX < edgeMargin || quad.topLeftY < edgeMargin ||
        quad.topRightX > (1.0 - edgeMargin) || quad.topRightY < edgeMargin ||
        quad.bottomRightX > (1.0 - edgeMargin) || quad.bottomRightY > (1.0 - edgeMargin) ||
        quad.bottomLeftX < edgeMargin || quad.bottomLeftY > (1.0 - edgeMargin);

    if (isClipped) {
      _stableCounter = 0;
      return _updateInstruction(GuidanceInstruction.moveBack);
    }

    // 2. Check if the document is too small
    // Area of normalized quad is between 0.0 and 1.0. We want it to fill a good portion of the screen.
    if (quad.area < 0.25) {
      _stableCounter = 0;
      return _updateInstruction(GuidanceInstruction.moveCloser);
    }

    // 3. Check centering
    // Centroid should be near 0.5, 0.5
    final cx = quad.centerX;
    final cy = quad.centerY;
    const centerTolerance = 0.15; // 15% tolerance from center

    if (cx < (0.5 - centerTolerance)) {
      _stableCounter = 0;
      // In raw buffer, depending on rotation, X and Y might map to screen differently.
      // But assuming standard mapping:
      return _updateInstruction(GuidanceInstruction.moveRight); // Document is too far left, move camera right
    }
    if (cx > (0.5 + centerTolerance)) {
      _stableCounter = 0;
      return _updateInstruction(GuidanceInstruction.moveLeft);
    }
    if (cy < (0.5 - centerTolerance)) {
      _stableCounter = 0;
      return _updateInstruction(GuidanceInstruction.moveDown);
    }
    if (cy > (0.5 + centerTolerance)) {
      _stableCounter = 0;
      return _updateInstruction(GuidanceInstruction.moveUp);
    }

    // 4. Check for severe skew/rotation
    // If the top edge width is drastically different from bottom edge width
    final topWidth = (quad.topRightX - quad.topLeftX).abs();
    final bottomWidth = (quad.bottomRightX - quad.bottomLeftX).abs();
    final leftHeight = (quad.bottomLeftY - quad.topLeftY).abs();
    final rightHeight = (quad.bottomRightY - quad.topRightY).abs();

    // If one side is more than 30% larger than the opposite side, it's skewed
    if ((topWidth - bottomWidth).abs() / topWidth > 0.3 || 
        (leftHeight - rightHeight).abs() / leftHeight > 0.3) {
      _stableCounter = 0;
      return _updateInstruction(GuidanceInstruction.straighten);
    }

    // 5. Well positioned! Check stability
    _stableCounter++;
    
    if (_stableCounter >= requiredStableFrames) {
      return _updateInstruction(GuidanceInstruction.stable);
    }

    return _updateInstruction(GuidanceInstruction.holdSteady);
  }

  GuidanceInstruction _updateInstruction(GuidanceInstruction newInstruction) {
    _lastInstruction = newInstruction;
    return newInstruction;
  }

  /// Helper to get a user-friendly spoken message for an instruction.
  String getSpokenMessage(GuidanceInstruction instruction) {
    switch (instruction) {
      case GuidanceInstruction.searching:
        return "Looking for document";
      case GuidanceInstruction.moveBack:
        return "Move camera back";
      case GuidanceInstruction.moveCloser:
        return "Move closer";
      case GuidanceInstruction.moveLeft:
        return "Move left";
      case GuidanceInstruction.moveRight:
        return "Move right";
      case GuidanceInstruction.moveUp:
        return "Move up";
      case GuidanceInstruction.moveDown:
        return "Move down";
      case GuidanceInstruction.straighten:
        return "Straighten the camera";
      case GuidanceInstruction.holdSteady:
        return "Positioned correctly, hold steady";
      case GuidanceInstruction.stable:
        return "Stable, launching scanner";
    }
  }
}
