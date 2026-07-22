import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../core/camera_service.dart';
import '../core/detection_result_formatter.dart';
import '../core/object_detection_service.dart';
import 'camera_base_screen.dart';

class ObjectDetectionScreen extends StatefulWidget {
  const ObjectDetectionScreen({super.key});

  @override
  State<ObjectDetectionScreen> createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen>
    with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  final ObjectDetectionService _objectDetectionService =
      ObjectDetectionService();
  final DetectionResultFormatter _resultFormatter =
      const DetectionResultFormatter();

  static const int _persistenceFrames = 2;
  static const int _maxMissedFrames = 4;
  static const double _trackMergeIou = 0.18;
  static const double _sameObjectDistance = 0.42;
  static const Duration _announcementCooldown = Duration(milliseconds: 1800);

  final List<_TrackedDetection> _tracks = [];
  List<ObjectDetection> _liveDetections = const [];

  bool _cameraReady = false;
  bool _isInitializing = true;
  bool _isProcessingFrame = false;
  bool _isDisposed = false;

  String _status = 'Initializing camera...';
  String _lastAnnouncedSignature = '';
  DateTime _lastAnnouncedAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeLiveDetection());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_releaseCamera());
    } else if (state == AppLifecycleState.resumed && !_isDisposed) {
      unawaited(_initializeLiveDetection());
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_releaseCamera());
    unawaited(_objectDetectionService.dispose());
    super.dispose();
  }

  Future<void> _initializeLiveDetection() async {
    if (_cameraReady || !_isInitializing && _cameraService.controller != null) {
      return;
    }

    setState(() {
      _isInitializing = true;
      _status = 'Initializing camera...';
      _liveDetections = const [];
      _tracks.clear();
      _lastAnnouncedSignature = '';
      _lastAnnouncedAt = DateTime.fromMillisecondsSinceEpoch(0);
    });

    try {
      final results = await Future.wait([
        _cameraService.initialize(),
        _objectDetectionService.initialize().then((_) => true),
      ]);
      if (!mounted || _isDisposed) return;

      if (!results.first) {
        setState(() {
          _isInitializing = false;
          _status = _cameraService.errorMessage ?? 'Camera initialization failed';
        });
        return;
      }

      setState(() {
        _cameraReady = true;
        _isInitializing = false;
        _status = 'Looking for objects...';
      });
      await _startImageStream();
    } catch (e) {
      if (!mounted || _isDisposed) return;
      setState(() {
        _isInitializing = false;
        _status = 'Object detection failed to start: $e';
      });
    }
  }

  Future<void> _startImageStream() async {
    final controller = _cameraService.controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isStreamingImages) {
      return;
    }

    await controller.startImageStream((frame) {
      if (_isProcessingFrame || !_objectDetectionService.isInitialized) {
        return;
      }
      unawaited(_processLatestFrame(frame));
    });
  }

  Future<void> _processLatestFrame(CameraImage frame) async {
    final controller = _cameraService.controller;
    if (controller == null || !controller.value.isInitialized) return;

    _isProcessingFrame = true;
    try {
      final detections = await _objectDetectionService.detect(
        frame,
        controller.description.sensorOrientation,
      );
      if (!mounted || _isDisposed || !_cameraReady) return;

      final stableDetections = _updateTracks(detections);
      setState(() {
        _liveDetections = stableDetections;
      });

      if (stableDetections.isNotEmpty) {
        _maybeUpdateDisplayedResult(stableDetections);
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
      setState(() {
        _status = 'Object detection error: $e';
      });
    } finally {
      _isProcessingFrame = false;
    }
  }

  void _maybeUpdateDisplayedResult(List<ObjectDetection> detections) {
    final signature = _dominantSignature(detections);
    final now = DateTime.now();
    final cooldownPassed =
        now.difference(_lastAnnouncedAt) >= _announcementCooldown;
    if (signature == _lastAnnouncedSignature && !cooldownPassed) {
      return;
    }

    _lastAnnouncedSignature = signature;
    _lastAnnouncedAt = now;
    final sentence = _resultFormatter.format(detections);
    setState(() {
      _status = sentence;
    });
  }

  String _dominantSignature(List<ObjectDetection> detections) {
    final sorted = [...detections]
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    final dominant = sorted.first;
    final count = detections
        .where((detection) => detection.classIndex == dominant.classIndex)
        .length;
    return '${dominant.classIndex}:$count';
  }

  List<ObjectDetection> _updateTracks(List<ObjectDetection> detections) {
    final updatedTrackIndexes = <int>{};

    for (final detection in _deduplicateFrameDetections(detections)) {
      final matchIndex = _bestTrackIndexFor(detection, updatedTrackIndexes);
      if (matchIndex == null) {
        _tracks.add(_TrackedDetection.fromDetection(detection));
        updatedTrackIndexes.add(_tracks.length - 1);
        continue;
      }

      _tracks[matchIndex].update(detection);
      updatedTrackIndexes.add(matchIndex);
    }

    for (var i = 0; i < _tracks.length; i++) {
      if (!updatedTrackIndexes.contains(i)) {
        _tracks[i].markMissed();
      }
    }

    _tracks.removeWhere((track) => track.missedFrames > _maxMissedFrames);

    return _tracks
        .where((track) => track.consecutiveFrames >= _persistenceFrames)
        .map((track) => track.toDetection())
        .toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
  }

  List<ObjectDetection> _deduplicateFrameDetections(
    List<ObjectDetection> detections,
  ) {
    final sorted = [...detections]
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    final merged = <ObjectDetection>[];

    for (final detection in sorted) {
      final existingIndex = merged.indexWhere(
        (existing) =>
            existing.classIndex == detection.classIndex &&
            _isSameObject(existing.boundingBox, detection.boundingBox),
      );

      if (existingIndex == -1) {
        merged.add(detection);
        continue;
      }

      final existing = merged[existingIndex];
      merged[existingIndex] = ObjectDetection(
        classIndex: existing.classIndex,
        label: existing.label,
        confidence: math.max(existing.confidence, detection.confidence),
        boundingBox: _averageBox(existing.boundingBox, detection.boundingBox),
        occurrenceCount: math.max(
          existing.occurrenceCount,
          detection.occurrenceCount,
        ),
      );
    }

    return merged;
  }

  int? _bestTrackIndexFor(
    ObjectDetection detection,
    Set<int> alreadyUpdatedIndexes,
  ) {
    var bestSimilarity = 0.0;
    int? bestIndex;

    for (var i = 0; i < _tracks.length; i++) {
      if (alreadyUpdatedIndexes.contains(i)) continue;
      final track = _tracks[i];
      if (track.classIndex != detection.classIndex) continue;

      final similarity = _objectSimilarity(
        track.boundingBox,
        detection.boundingBox,
      );
      if (similarity > bestSimilarity) {
        bestSimilarity = similarity;
        bestIndex = i;
      }
    }

    return bestIndex;
  }

  DetectionBox _averageBox(DetectionBox a, DetectionBox b) {
    return DetectionBox(
      left: (a.left + b.left) / 2,
      top: (a.top + b.top) / 2,
      width: (a.width + b.width) / 2,
      height: (a.height + b.height) / 2,
    );
  }

  bool _isSameObject(DetectionBox a, DetectionBox b) {
    return _objectSimilarity(a, b) > 0;
  }

  double _objectSimilarity(DetectionBox a, DetectionBox b) {
    final overlap = _iou(a, b);
    if (overlap >= _trackMergeIou) return overlap;

    final aCenterX = a.left + a.width / 2;
    final aCenterY = a.top + a.height / 2;
    final bCenterX = b.left + b.width / 2;
    final bCenterY = b.top + b.height / 2;
    final centerDistance = math.sqrt(
      math.pow(aCenterX - bCenterX, 2) + math.pow(aCenterY - bCenterY, 2),
    );
    final verticalOverlap =
        math.max(0.0, math.min(a.bottom, b.bottom) - math.max(a.top, b.top)) /
        math.max(0.01, math.min(a.height, b.height));
    final horizontalGap = math.max(
      0.0,
      math.max(a.left, b.left) - math.min(a.right, b.right),
    );

    if (centerDistance <= _sameObjectDistance &&
        verticalOverlap >= 0.35 &&
        horizontalGap <= 0.18) {
      return 0.01;
    }

    return 0;
  }

  double _iou(DetectionBox a, DetectionBox b) {
    final left = math.max(a.left, b.left);
    final top = math.max(a.top, b.top);
    final right = math.min(a.right, b.right);
    final bottom = math.min(a.bottom, b.bottom);
    final intersection =
        math.max(0.0, right - left) * math.max(0.0, bottom - top);
    final union = a.area + b.area - intersection;
    return union <= 0 ? 0 : intersection / union;
  }

  Future<void> _releaseCamera() async {
    _cameraReady = false;
    await _stopImageStream();
    await _cameraService.dispose();
    if (!_isDisposed && mounted) {
      setState(() {
        _liveDetections = const [];
      });
    }
  }

  Future<void> _stopImageStream() async {
    final controller = _cameraService.controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        !controller.value.isStreamingImages) {
      return;
    }
    await controller.stopImageStream();
  }

  @override
  Widget build(BuildContext context) {
    return CameraBaseScreen(
      title: 'Object Detection',
      statusText: _status,
      statusTextColor: Colors.white,
      cameraPreviewWidget: _cameraReady
          ? _cameraService.buildPreview()
          : _buildPlaceholder(),
      overlayWidget: _cameraReady
          ? Positioned.fill(
              child: CustomPaint(
                painter: _DetectionBoxPainter(_liveDetections),
                size: Size.infinite,
              ),
            )
          : null,
      bottomWidget: null,
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF111827),
      alignment: Alignment.center,
      child: _isInitializing
          ? const CircularProgressIndicator(color: Colors.white)
          : const Icon(
              Icons.center_focus_strong_rounded,
              size: 72,
              color: Colors.white70,
            ),
    );
  }
}

class _TrackedDetection {
  final int classIndex;
  final String label;
  DetectionBox boundingBox;
  double confidence;
  int consecutiveFrames;
  int seenFrames;
  int missedFrames;

  _TrackedDetection({
    required this.classIndex,
    required this.label,
    required this.boundingBox,
    required this.confidence,
    required this.consecutiveFrames,
    required this.seenFrames,
    required this.missedFrames,
  });

  factory _TrackedDetection.fromDetection(ObjectDetection detection) {
    return _TrackedDetection(
      classIndex: detection.classIndex,
      label: detection.label,
      boundingBox: detection.boundingBox,
      confidence: detection.confidence,
      consecutiveFrames: 1,
      seenFrames: 1,
      missedFrames: 0,
    );
  }

  void update(ObjectDetection detection) {
    boundingBox = DetectionBox(
      left: boundingBox.left * 0.7 + detection.boundingBox.left * 0.3,
      top: boundingBox.top * 0.7 + detection.boundingBox.top * 0.3,
      width: boundingBox.width * 0.7 + detection.boundingBox.width * 0.3,
      height: boundingBox.height * 0.7 + detection.boundingBox.height * 0.3,
    );
    confidence = math.max(confidence, detection.confidence);
    consecutiveFrames += 1;
    seenFrames += 1;
    missedFrames = 0;
  }

  void markMissed() {
    missedFrames += 1;
    consecutiveFrames = 0;
  }

  ObjectDetection toDetection() {
    return ObjectDetection(
      classIndex: classIndex,
      label: label,
      confidence: confidence,
      boundingBox: boundingBox,
      occurrenceCount: seenFrames,
    );
  }
}

class _DetectionBoxPainter extends CustomPainter {
  final List<ObjectDetection> detections;

  _DetectionBoxPainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..color = const Color(0xFF34D399)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final fillPaint = Paint()
      ..color = const Color(0xFF34D399).withAlpha(38)
      ..style = PaintingStyle.fill;

    for (final detection in detections) {
      final rect = Rect.fromLTWH(
        detection.boundingBox.left * size.width,
        detection.boundingBox.top * size.height,
        detection.boundingBox.width * size.width,
        detection.boundingBox.height * size.height,
      );
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, boxPaint);
      _drawLabel(canvas, rect, detection);
    }
  }

  void _drawLabel(Canvas canvas, Rect rect, ObjectDetection detection) {
    final text = '${detection.label} ${(detection.confidence * 100).round()}%';
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 180);
    final labelRect = Rect.fromLTWH(
      rect.left,
      (rect.top - painter.height - 8).clamp(0, double.infinity),
      painter.width + 12,
      painter.height + 8,
    );
    final labelPaint = Paint()..color = const Color(0xFF34D399);
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(6)),
      labelPaint,
    );
    painter.paint(canvas, labelRect.topLeft + const Offset(6, 4));
  }

  @override
  bool shouldRepaint(covariant _DetectionBoxPainter oldDelegate) {
    return oldDelegate.detections != detections;
  }
}
