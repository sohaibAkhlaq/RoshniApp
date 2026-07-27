import 'dart:typed_data';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Result from a single currency classification inference.
class CurrencyClassificationResult {
  final bool isConfident;
  final String classLabel; // e.g. "100Rs", "100Rsback"
  final double confidence; // 0.0 to 1.0

  const CurrencyClassificationResult({
    required this.isConfident,
    required this.classLabel,
    required this.confidence,
  });
}

/// On-device currency denomination classifier backed by a fine-tuned
/// MobileNetV2 TFLite model.
///
/// Design mirrors [ObjectDetectionService]:
/// - Interpreter loaded once (not per-tap).
/// - Input shape read at runtime from the loaded interpreter tensor.
/// - Normalization matches MobileNetV2 training preprocessing: [-1, 1].
/// - Returns a structured result — never throws for a low-confidence case.
class CurrencyClassifierService {
  static const String _modelPath = 'assets/models/currency_classifier.tflite';
  static const String _labelsPath = 'assets/models/currency_labels.txt';

  /// Confidence below this threshold routes to the error/retry state (BR-1).
  /// Set conservatively to bias toward retry rather than a wrong financial answer.
  /// Per BR-1 / US-1: wrong denomination = real financial harm for a blind user.
  static const double confidenceThreshold = 0.70;

  Interpreter? _interpreter;
  List<String> _labels = [];
  List<int> _inputShape = [];
  int _inputHeight = 224;
  int _inputWidth = 224;
  bool _isLoaded = false;
  bool _isDisposed = false;
  bool _isProcessing = false;

  bool get isLoaded => _isLoaded;

  /// Call once at screen init. Loads the interpreter and labels, then reads
  /// the actual input tensor shape from the loaded model rather than assuming.
  Future<void> loadModel() async {
    if (_isLoaded) return;

    try {
      // ── 1. Load labels ─────────────────────────────────────────────────────
      final labelsData = await rootBundle.loadString(_labelsPath);
      _labels = labelsData
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      developer.log(
        'Loaded ${_labels.length} labels: $_labels',
        name: 'CurrencyClassifierService',
      );

      // ── 2. Load interpreter ────────────────────────────────────────────────
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(_modelPath, options: options);
      _interpreter!.allocateTensors();

      // ── 3. Read ACTUAL input shape at runtime (do not assume) ──────────────
      _inputShape = _interpreter!.getInputTensor(0).shape;
      developer.log(
        'Input tensor shape (runtime verified): $_inputShape',
        name: 'CurrencyClassifierService',
      );
      developer.log(
        'Output tensor shape: ${_interpreter!.getOutputTensor(0).shape}',
        name: 'CurrencyClassifierService',
      );

      // Derive H/W from shape: expected [1, H, W, 3] for NHWC
      if (_inputShape.length == 4) {
        _inputHeight = _inputShape[1];
        _inputWidth = _inputShape[2];
      } else {
        developer.log(
          'WARNING: Unexpected input shape $_inputShape — defaulting to 224x224',
          name: 'CurrencyClassifierService',
        );
        _inputHeight = 224;
        _inputWidth = 224;
      }

      developer.log(
        'Using input size: ${_inputHeight}x$_inputWidth',
        name: 'CurrencyClassifierService',
      );

      _isLoaded = true;
    } catch (e, stack) {
      _isLoaded = false;
      developer.log(
        'loadModel() failed: $e\n$stack',
        name: 'CurrencyClassifierService',
      );
      rethrow;
    }
  }

  Uint8List? _lastPreprocessedDebugBytes;
  Uint8List? get lastPreprocessedDebugBytes => _lastPreprocessedDebugBytes;

  /// Run inference on a raw image byte buffer (JPEG/PNG from camera capture).
  ///
  /// Returns [CurrencyClassificationResult.isConfident] == false for any
  /// below-threshold result — never throws for that case; the calling screen
  /// handles it as the error/retry state.
  Future<CurrencyClassificationResult> classify(Uint8List imageBytes) async {
    if (_isDisposed || !_isLoaded || _interpreter == null) {
      return const CurrencyClassificationResult(
        isConfident: false,
        classLabel: 'Unknown',
        confidence: 0.0,
      );
    }

    _isProcessing = true;
    try {
      // ── 1. Decode & fix camera orientation ──────────────────────────────────
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        throw ArgumentError('Could not decode image bytes');
      }

      if (_isDisposed) {
        return const CurrencyClassificationResult(
          isConfident: false,
          classLabel: 'Unknown',
          confidence: 0.0,
        );
      }

      // Correct Android sensor landscape rotation (EXIF orientation bake)
      final orientedImage = img.bakeOrientation(decodedImage);

      // ── 2. Center square crop to preserve aspect ratio ──────────────────────
      final minDim = orientedImage.width < orientedImage.height
          ? orientedImage.width
          : orientedImage.height;
      final cropX = (orientedImage.width - minDim) ~/ 2;
      final cropY = (orientedImage.height - minDim) ~/ 2;

      final croppedImage = img.copyCrop(
        orientedImage,
        x: cropX,
        y: cropY,
        width: minDim,
        height: minDim,
      );

      // ── 3. Resize to 224x224 input tensor size ─────────────────────────────
      final resized = img.copyResize(
        croppedImage,
        width: _inputWidth,
        height: _inputHeight,
        interpolation: img.Interpolation.linear,
      );

      // Store encoded JPEG bytes of the exact image sent to the model for Step 1 debug overlay
      _lastPreprocessedDebugBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 90));

      // Fast 1ms lens-covered check on 224x224 image (avoids processing pitch black frames)
      double sumLuma = 0.0;
      for (int y = 0; y < _inputHeight; y += 4) {
        for (int x = 0; x < _inputWidth; x += 4) {
          final p = resized.getPixel(x, y);
          sumLuma += (0.299 * p.r + 0.587 * p.g + 0.114 * p.b);
        }
      }
      final avgLuma = sumLuma / (56 * 56);
      if (avgLuma < 8.0) {
        return const CurrencyClassificationResult(
          isConfident: false,
          classLabel: 'Lens Covered / Pitch Black',
          confidence: 0.0,
        );
      }

      if (_isDisposed) {
        return const CurrencyClassificationResult(
          isConfident: false,
          classLabel: 'Unknown',
          confidence: 0.0,
        );
      }

      // ── 4. Apply PyTorch ImageNet Normalization ──────────────────────────────
      final numClasses = _labels.isEmpty ? 6 : _labels.length;
      final inputBuffer = Float32List(_inputHeight * _inputWidth * 3);
      
      int idx = 0;
      for (int y = 0; y < _inputHeight; y++) {
        for (int x = 0; x < _inputWidth; x++) {
          final pixel = resized.getPixel(x, y);
          inputBuffer[idx++] = ((pixel.r.toDouble() / 255.0) - 0.485) / 0.229;
          inputBuffer[idx++] = ((pixel.g.toDouble() / 255.0) - 0.456) / 0.224;
          inputBuffer[idx++] = ((pixel.b.toDouble() / 255.0) - 0.406) / 0.225;
        }
      }

      if (_isDisposed) {
        return const CurrencyClassificationResult(
          isConfident: false,
          classLabel: 'Unknown',
          confidence: 0.0,
        );
      }

      final stopwatch = Stopwatch()..start();
      final input = inputBuffer.reshape([1, _inputHeight, _inputWidth, 3]);
      final output = List.generate(1, (_) => List.filled(numClasses, 0.0));
      
      _interpreter!.run(input, output);

      final rawScores = output[0];
      final probs = _computeSoftmax(rawScores);

      int bestTopIndex = 0;
      double bestTopScore = probs[0];
      for (int i = 1; i < probs.length; i++) {
        if (probs[i] > bestTopScore) {
          bestTopScore = probs[i];
          bestTopIndex = i;
        }
      }
      final bestScores = probs;
      final bestModeName = 'PyTorch ImageNet';

      stopwatch.stop();

      // ── 5. Log inference results ─────────────────────────────────────────────
      final allScores = StringBuffer();
      for (int i = 0; i < bestScores.length; i++) {
        final label = i < _labels.length ? _labels[i] : 'class_$i';
        allScores.write('$label=${bestScores[i].toStringAsFixed(4)} ');
      }

      developer.log(
        'Inference ${stopwatch.elapsedMilliseconds}ms | Mode: $bestModeName | '
        'Scores: $allScores',
        name: 'CurrencyClassifierService',
      );

      final topLabel = bestTopIndex < _labels.length
          ? _labels[bestTopIndex]
          : 'class_$bestTopIndex';
      final isConfident = bestTopScore >= confidenceThreshold;

      return CurrencyClassificationResult(
        isConfident: isConfident,
        classLabel: topLabel,
        confidence: bestTopScore,
      );
    } finally {
      _isProcessing = false;
    }
  }

  /// Helper to convert raw model logits to Softmax probabilities [0, 1].
  List<double> _computeSoftmax(List<double> logits) {
    double maxLogit = logits[0];
    for (int i = 1; i < logits.length; i++) {
      if (logits[i] > maxLogit) maxLogit = logits[i];
    }

    double sumExp = 0.0;
    final exps = List<double>.filled(logits.length, 0.0);
    for (int i = 0; i < logits.length; i++) {
      exps[i] = math.exp(logits[i] - maxLogit);
      sumExp += exps[i];
    }

    if (sumExp == 0.0) sumExp = 1.0;
    return exps.map((e) => e / sumExp).toList();
  }

  /// Release native interpreter memory. Call in screen's dispose().
  Future<void> dispose() async {
    _isDisposed = true;
    while (_isProcessing) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
    developer.log('Disposed.', name: 'CurrencyClassifierService');
  }
}

