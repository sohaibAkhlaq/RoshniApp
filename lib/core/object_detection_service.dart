import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ObjectDetection {
  final int classIndex;
  final String label;
  final double confidence;
  final DetectionBox boundingBox;
  final int occurrenceCount;

  const ObjectDetection({
    required this.classIndex,
    required this.label,
    required this.confidence,
    required this.boundingBox,
    this.occurrenceCount = 1,
  });
}

class DetectionBox {
  final double left;
  final double top;
  final double width;
  final double height;

  const DetectionBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  double get right => left + width;
  double get bottom => top + height;
  double get area => math.max(0, width) * math.max(0, height);
}

class ObjectDetectionService {
  static const String _modelAsset = 'assets/models/yolov8n.tflite';
  static const String _labelsAsset = 'assets/models/coco_labels.txt';

  final double confidenceThreshold;
  final double iouThreshold;

  Interpreter? _interpreter;
  IsolateInterpreter? _isolateInterpreter;
  Delegate? _delegate;
  List<String> _labels = const [];
  List<int> _inputShape = const [];
  List<int> _outputShape = const [];
  bool _isNchwInput = false;
  String _accelerationMode = 'CPU';
  int? _lastInferenceMs;

  ObjectDetectionService({
    this.confidenceThreshold = 0.5,
    this.iouThreshold = 0.4,
  });

  bool get isInitialized => _interpreter != null;
  List<int> get inputShape => List.unmodifiable(_inputShape);
  List<int> get outputShape => List.unmodifiable(_outputShape);
  String get accelerationMode => _accelerationMode;
  int? get lastInferenceMs => _lastInferenceMs;

  Future<void> initialize() async {
    if (_interpreter != null) return;

    _labels = (await rootBundle.loadString(_labelsAsset))
        .split('\n')
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList(growable: false);

    final interpreter = await _createInterpreterWithAcceleration();

    _interpreter = interpreter;
    _inputShape = interpreter.getInputTensor(0).shape;
    _outputShape = interpreter.getOutputTensor(0).shape;
    _isNchwInput = _inputShape.length == 4 && _inputShape[1] == 3;

    if (_labels.length != 80) {
      throw StateError('Expected 80 COCO labels, found ${_labels.length}.');
    }
    if (_inputShape.length != 4) {
      throw StateError('Unsupported YOLO input shape: $_inputShape');
    }
    if (_outputShape.length != 3) {
      throw StateError('Unsupported YOLO output shape: $_outputShape');
    }

    _isolateInterpreter = await IsolateInterpreter.create(
      address: interpreter.address,
      debugName: 'RoshniObjectDetectionIsolate',
    );
    developer.log(
      'ObjectDetectionService initialized with $_accelerationMode; '
      'input=$_inputShape output=$_outputShape',
      name: 'ObjectDetectionService',
    );
  }

  Future<Interpreter> _createInterpreterWithAcceleration() async {
    try {
      final options = InterpreterOptions()..threads = 2;
      _configureGpuAcceleration(options);
      final interpreter = await Interpreter.fromAsset(
        _modelAsset,
        options: options,
      );
      interpreter.allocateTensors();
      return interpreter;
    } catch (e) {
      developer.log(
        'GPU delegate failed; falling back. $e',
        name: 'ObjectDetectionService',
      );
      _delegate?.delete();
      _delegate = null;
    }

    try {
      final options = InterpreterOptions()
        ..threads = 2
        ..useNnApiForAndroid = true;
      final interpreter = await Interpreter.fromAsset(
        _modelAsset,
        options: options,
      );
      interpreter.allocateTensors();
      _accelerationMode = 'NNAPI';
      developer.log(
        'Using TensorFlow Lite NNAPI acceleration.',
        name: 'ObjectDetectionService',
      );
      return interpreter;
    } catch (e) {
      developer.log(
        'NNAPI failed; falling back to CPU. $e',
        name: 'ObjectDetectionService',
      );
    }

    final options = InterpreterOptions()..threads = 2;
    final interpreter = await Interpreter.fromAsset(
      _modelAsset,
      options: options,
    );
    interpreter.allocateTensors();
    _accelerationMode = 'CPU';
    developer.log('Using TensorFlow Lite CPU.', name: 'ObjectDetectionService');
    return interpreter;
  }

  void _configureGpuAcceleration(InterpreterOptions options) {
    try {
      final gpuDelegate = GpuDelegateV2();
      options.addDelegate(gpuDelegate);
      _delegate = gpuDelegate;
      _accelerationMode = 'GPU delegate';
      developer.log(
        'Using TensorFlow Lite GPU delegate.',
        name: 'ObjectDetectionService',
      );
      return;
    } catch (e) {
      developer.log(
        'GPU delegate unavailable. $e',
        name: 'ObjectDetectionService',
      );
      _accelerationMode = 'CPU';
    }
  }

  Future<List<ObjectDetection>> detect(
    CameraImage frame,
    int rotationDegrees,
  ) async {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError(
        'ObjectDetectionService.initialize() must be called first.',
      );
    }

    final source = _cameraImageToRgb(frame);
    final oriented = rotationDegrees == 0
        ? source
        : img.copyRotate(source, angle: rotationDegrees);
    final inputHeight = _isNchwInput ? _inputShape[2] : _inputShape[1];
    final inputWidth = _isNchwInput ? _inputShape[3] : _inputShape[2];
    final resized = img.copyResize(
      oriented,
      width: inputWidth,
      height: inputHeight,
      interpolation: img.Interpolation.linear,
    );

    final input = _buildInputTensor(resized, inputWidth, inputHeight);
    final output = _zerosForShape(_outputShape);
    final stopwatch = Stopwatch()..start();
    final isolateInterpreter = _isolateInterpreter;
    if (isolateInterpreter != null) {
      await isolateInterpreter.run(input, output);
    } else {
      interpreter.run(input, output);
    }
    stopwatch.stop();
    _lastInferenceMs = stopwatch.elapsedMilliseconds;
    developer.log(
      'Inference ${_lastInferenceMs}ms ($_accelerationMode)',
      name: 'ObjectDetectionService',
    );

    final rawOutput = _flattenNumbers(output);
    final detections = _decodeOutput(rawOutput, inputWidth, inputHeight);
    return _nonMaxSuppression(detections);
  }

  Future<void> dispose() async {
    await _isolateInterpreter?.close();
    _isolateInterpreter = null;
    _interpreter?.close();
    _interpreter = null;
    _delegate?.delete();
    _delegate = null;
  }

  Object _buildInputTensor(img.Image image, int width, int height) {
    if (_isNchwInput) {
      final channels = List.generate(
        3,
        (_) => List.generate(height, (_) => List<double>.filled(width, 0)),
      );
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final pixel = image.getPixel(x, y);
          channels[0][y][x] = pixel.r / 255.0;
          channels[1][y][x] = pixel.g / 255.0;
          channels[2][y][x] = pixel.b / 255.0;
        }
      }
      return [channels];
    }

    final rows = List.generate(
      height,
      (_) => List.generate(width, (_) => List<double>.filled(3, 0)),
    );
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        rows[y][x][0] = pixel.r / 255.0;
        rows[y][x][1] = pixel.g / 255.0;
        rows[y][x][2] = pixel.b / 255.0;
      }
    }
    return [rows];
  }

  List<ObjectDetection> _decodeOutput(
    List<double> output,
    int inputWidth,
    int inputHeight,
  ) {
    final dim1 = _outputShape[1];
    final dim2 = _outputShape[2];
    final attributesFirst = dim1 < dim2;
    final attributeCount = attributesFirst ? dim1 : dim2;
    final boxCount = attributesFirst ? dim2 : dim1;

    if (attributeCount < 5) {
      throw StateError('YOLO output has too few attributes: $_outputShape');
    }

    final detections = <ObjectDetection>[];
    for (var boxIndex = 0; boxIndex < boxCount; boxIndex++) {
      double valueAt(int attributeIndex) {
        final flatIndex = attributesFirst
            ? attributeIndex * boxCount + boxIndex
            : boxIndex * attributeCount + attributeIndex;
        return output[flatIndex];
      }

      var bestClass = 0;
      var bestScore = 0.0;
      for (var classIndex = 0; classIndex < attributeCount - 4; classIndex++) {
        final score = valueAt(classIndex + 4);
        if (score > bestScore) {
          bestScore = score;
          bestClass = classIndex;
        }
      }

      if (bestScore < confidenceThreshold || bestClass >= _labels.length) {
        continue;
      }

      final cx = valueAt(0);
      final cy = valueAt(1);
      final width = valueAt(2);
      final height = valueAt(3);
      final normalizedBox = _normalizeYoloBox(
        cx: cx,
        cy: cy,
        width: width,
        height: height,
        inputWidth: inputWidth,
        inputHeight: inputHeight,
      );

      if (normalizedBox.area <= 0) continue;

      detections.add(
        ObjectDetection(
          classIndex: bestClass,
          label: _labels[bestClass],
          confidence: bestScore,
          boundingBox: normalizedBox,
        ),
      );
    }
    return detections;
  }

  DetectionBox _normalizeYoloBox({
    required double cx,
    required double cy,
    required double width,
    required double height,
    required int inputWidth,
    required int inputHeight,
  }) {
    final divisorX = cx > 2 || width > 2 ? inputWidth.toDouble() : 1.0;
    final divisorY = cy > 2 || height > 2 ? inputHeight.toDouble() : 1.0;

    final normalizedCx = cx / divisorX;
    final normalizedCy = cy / divisorY;
    final normalizedWidth = width / divisorX;
    final normalizedHeight = height / divisorY;

    final left = (normalizedCx - normalizedWidth / 2).clamp(0.0, 1.0);
    final top = (normalizedCy - normalizedHeight / 2).clamp(0.0, 1.0);
    final right = (normalizedCx + normalizedWidth / 2).clamp(0.0, 1.0);
    final bottom = (normalizedCy + normalizedHeight / 2).clamp(0.0, 1.0);

    return DetectionBox(
      left: left,
      top: top,
      width: math.max(0, right - left),
      height: math.max(0, bottom - top),
    );
  }

  List<ObjectDetection> _nonMaxSuppression(List<ObjectDetection> detections) {
    final sorted = [...detections]
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    final selected = <ObjectDetection>[];

    for (final candidate in sorted) {
      final overlapsExisting = selected.any(
        (existing) =>
            existing.classIndex == candidate.classIndex &&
            _iou(existing.boundingBox, candidate.boundingBox) > iouThreshold,
      );
      if (!overlapsExisting) {
        selected.add(candidate);
      }
    }

    return selected;
  }

  double _iou(DetectionBox a, DetectionBox b) {
    final left = math.max(a.left, b.left);
    final top = math.max(a.top, b.top);
    final right = math.min(a.right, b.right);
    final bottom = math.min(a.bottom, b.bottom);
    final intersection = math.max(0, right - left) * math.max(0, bottom - top);
    final union = a.area + b.area - intersection;
    return union <= 0 ? 0 : intersection / union;
  }

  Object _zerosForShape(List<int> shape) {
    if (shape.length == 1) {
      return List<double>.filled(shape.first, 0);
    }
    return List.generate(
      shape.first,
      (_) => _zerosForShape(shape.sublist(1)),
      growable: false,
    );
  }

  List<double> _flattenNumbers(Object value) {
    final numbers = <double>[];
    void visit(Object? node) {
      if (node is num) {
        numbers.add(node.toDouble());
      } else if (node is Iterable) {
        for (final item in node) {
          visit(item);
        }
      }
    }

    visit(value);
    return numbers;
  }

  img.Image _cameraImageToRgb(CameraImage image) {
    if (image.format.group == ImageFormatGroup.bgra8888) {
      return _bgra8888ToRgb(image);
    }
    return _yuv420ToRgb(image);
  }

  img.Image _bgra8888ToRgb(CameraImage image) {
    final plane = image.planes.first;
    final out = img.Image(width: image.width, height: image.height);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final index = y * plane.bytesPerRow + x * 4;
        final b = plane.bytes[index];
        final g = plane.bytes[index + 1];
        final r = plane.bytes[index + 2];
        out.setPixelRgb(x, y, r, g, b);
      }
    }
    return out;
  }

  img.Image _yuv420ToRgb(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final out = img.Image(width: width, height: height);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final yValue = yPlane.bytes[y * yPlane.bytesPerRow + x];
        final uvRow = (y / 2).floor();
        final uvCol = (x / 2).floor();
        final uvIndex =
            uvRow * uPlane.bytesPerRow + uvCol * (uPlane.bytesPerPixel ?? 1);
        final uValue = uPlane.bytes[uvIndex];
        final vValue = vPlane.bytes[uvIndex];

        final yf = yValue.toDouble();
        final uf = uValue.toDouble() - 128.0;
        final vf = vValue.toDouble() - 128.0;

        final r = (yf + 1.402 * vf).round().clamp(0, 255);
        final g = (yf - 0.344136 * uf - 0.714136 * vf).round().clamp(0, 255);
        final b = (yf + 1.772 * uf).round().clamp(0, 255);
        out.setPixelRgb(x, y, r, g, b);
      }
    }
    return out;
  }
}
