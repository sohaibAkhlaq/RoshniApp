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
  int _missedFrames = 0;
  GuidanceInstruction _lastInstruction = GuidanceInstruction.searching;

  GuidanceEngine({this.requiredStableFrames = 4});

  /// Evaluates the quad and returns the appropriate guidance instruction.
  GuidanceInstruction evaluate(NormalizedQuad? quad) {
    if (quad == null) {
      _missedFrames++;
      if (_missedFrames > 2) {
        _stableCounter = 0;
      }
      return _updateInstruction(_lastInstruction == GuidanceInstruction.holdSteady ? GuidanceInstruction.holdSteady : GuidanceInstruction.searching);
    }

    _missedFrames = 0;

    // 1. Check if the document is clipped (corners too close to the image edges)
    // Using a relaxed 1.5% margin for blind hand-holding
    const double edgeMargin = 0.015;
    final isClipped = quad.topLeftX < edgeMargin || quad.topLeftY < edgeMargin ||
        quad.topRightX > (1.0 - edgeMargin) || quad.topRightY < edgeMargin ||
        quad.bottomRightX > (1.0 - edgeMargin) || quad.bottomRightY > (1.0 - edgeMargin) ||
        quad.bottomLeftX < edgeMargin || quad.bottomLeftY > (1.0 - edgeMargin);

    if (isClipped) {
      _stableCounter = 0;
      return _updateInstruction(GuidanceInstruction.moveBack);
    }

    // 2. Check if the document is too small
    // Area of normalized quad is between 0.0 and 1.0. Relaxed to 15% for blind accessibility.
    if (quad.area < 0.15) {
      _stableCounter = 0;
      return _updateInstruction(GuidanceInstruction.moveCloser);
    }

    // 3. Check centering
    // Centroid should be near 0.5, 0.5. Relaxed 25% tolerance for one-handed blind usage.
    final cx = quad.centerX;
    final cy = quad.centerY;
    const centerTolerance = 0.25;

    if (cx < (0.5 - centerTolerance)) {
      _stableCounter = 0;
      return _updateInstruction(GuidanceInstruction.moveRight);
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
    // Relaxed skew check to 45% difference
    final topWidth = (quad.topRightX - quad.topLeftX).abs();
    final bottomWidth = (quad.bottomRightX - quad.bottomLeftX).abs();
    final leftHeight = (quad.bottomLeftY - quad.topLeftY).abs();
    final rightHeight = (quad.bottomRightY - quad.topRightY).abs();

    if ((topWidth - bottomWidth).abs() / topWidth > 0.45 || 
        (leftHeight - rightHeight).abs() / leftHeight > 0.45) {
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

  /// Helper to get a user-friendly spoken message for an instruction in Urdu.
  /// These conversational prompts provide real-time audio guidance to blind users
  /// on how to frame all 4 corners of the document.
  String getSpokenMessage(GuidanceInstruction instruction) {
    switch (instruction) {
      case GuidanceInstruction.searching:
        return "دستاویز تلاش کی جا رہی ہے";
      case GuidanceInstruction.moveBack:
        return "فون کو تھوڑا پیچھے کریں، تاکہ چاروں کونے نظر آئیں";
      case GuidanceInstruction.moveCloser:
        return "فون کو دستاویز کے تھوڑا قریب کریں";
      case GuidanceInstruction.moveLeft:
        return "فون کو بائیں طرف کریں";
      case GuidanceInstruction.moveRight:
        return "فون کو دائیں طرف کریں";
      case GuidanceInstruction.moveUp:
        return "فون کو تھوڑا اوپر کریں";
      case GuidanceInstruction.moveDown:
        return "فون کو تھوڑا نیچے کریں";
      case GuidanceInstruction.straighten:
        return "فون کو دستاویز کے اوپر سیدھا کریں";
      case GuidanceInstruction.holdSteady:
        return "بالکل ٹھیک، فون کو اسی جگہ سیدھا پکڑے رکھیں";
      case GuidanceInstruction.stable:
        return "چاروں کونے مل گئے ہیں، تصویر لی جا رہی ہے";
    }
  }
}
