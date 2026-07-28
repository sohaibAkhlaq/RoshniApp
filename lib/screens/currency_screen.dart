import 'dart:async';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'camera_base_screen.dart';

import '../core/camera_service.dart';
import '../core/currency_classifier_service.dart';
import '../core/currency_result_formatter.dart';
import '../core/history_service.dart';
import '../widgets/primary_button.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  final CameraService _cameraService = CameraService();
  final CurrencyClassifierService _classifierService = CurrencyClassifierService();
  final FlutterTts _tts = FlutterTts();
  bool _isExiting = false;

  String _status = 'Initializing camera\nHold the note flat inside the frame';
  String _detectedUrdu = '';
  String _detectedEnglish = '';
  Color _statusColor = Colors.white;

  bool _cameraReady = false;
  bool _isProcessing = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initializeServices();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ur-PK');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.stop();
    await _tts.speak('پاکستانی نوٹ پہچاننے کا نظام کھل گیا ہے۔ نوٹ کو فون کے سامنے سیدھا پکڑیں، اور سکرین پر کہیں بھی ٹیپ کریں');
  }

  Future<void> _initializeServices() async {
    try {
      final results = await Future.wait([
        _cameraService.initialize(),
        _classifierService.loadModel().then((_) => true).catchError((e) {
          debugPrint('CurrencyClassifierService load error: $e');
          return false;
        }),
      ]);

      if (!mounted || _isDisposed) return;

      final cameraSuccess = results[0] == true;
      if (cameraSuccess) {
        setState(() {
          _cameraReady = true;
          _status = 'Hold the note flat inside the frame';
        });
      } else {
        setState(() {
          _status = _cameraService.errorMessage ?? 'Camera initialization failed';
        });
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
      setState(() {
        _status = 'Initialization error: $e';
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (!_isExiting) {
      unawaited(_tts.stop());
    }
    unawaited(_cleanupAndDispose());
    super.dispose();
  }

  Future<void> _cleanupAndDispose() async {
    _cameraService.dispose();
    await _classifierService.dispose();
  }



  Uint8List? _debugPreprocessedBytes;
  String _confidenceDebugText = '';

  Future<void> _runRealInference() async {
    if (_isProcessing || !_cameraReady) return;

    final controller = _cameraService.controller;
    if (controller == null || !controller.value.isInitialized) {
      setState(() {
        _status = 'Camera not ready';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _status = 'Detecting note... hold steady';
    });

    unawaited(_tts.stop());
    unawaited(_tts.speak('نوٹ دیکھا جا رہا ہے، انتظار کریں'));

    try {
      final xfile = await controller.takePicture();
      final imageBytes = await xfile.readAsBytes();

      developer.log(
        'Captured frame: ${imageBytes.length} bytes (${(imageBytes.length / 1024).toStringAsFixed(1)} KB)',
        name: 'CurrencyScreen',
      );

      if (!mounted || _isDisposed) return;

      developer.log('Passing frame directly to classifier (no double-decode delay)', name: 'CurrencyScreen');
      final result = await _classifierService.classify(imageBytes);


      if (!mounted || _isDisposed) return;

      final preprocessedBytes = _classifierService.lastPreprocessedDebugBytes;

      developer.log(
        'Classifier result: label="${result.classLabel}" '
        'confidence=${result.confidence.toStringAsFixed(4)} '
        'isConfident=${result.isConfident} '
        'threshold=${CurrencyClassifierService.confidenceThreshold}',
        name: 'CurrencyScreen',
      );

      final pct = (result.confidence * 100).toStringAsFixed(1);

      if (result.isConfident) {
        final englishLabel = CurrencyResultFormatter.toEnglishLabel(result.classLabel);
        final urduSentence = CurrencyResultFormatter.toUrduSentence(result.classLabel);

        setState(() {
          _status = '';
          _detectedUrdu = urduSentence;
          _detectedEnglish = 'Detected note: $englishLabel ($pct%)';
          _statusColor = Colors.white;
          _isProcessing = false;
          _debugPreprocessedBytes = preprocessedBytes;
          _confidenceDebugText = 'Class: ${result.classLabel} | Conf: $pct%';
        });

        HapticFeedback.lightImpact();
        unawaited(_tts.stop());
        unawaited(_tts.speak(urduSentence));
        unawaited(HistoryService.saveScan(type: 'Currency Classifier', result: 'Detected: $englishLabel'));
        developer.log('TTS Speaking: $urduSentence', name: 'CurrencyScreen');
      } else {
        developer.log(
          'Below threshold (${result.confidence.toStringAsFixed(4)} < '
          '${CurrencyClassifierService.confidenceThreshold}) — showing retry state',
          name: 'CurrencyScreen',
        );
        setState(() {
          _debugPreprocessedBytes = preprocessedBytes;
          _confidenceDebugText = 'Top-1: ${result.classLabel} ($pct% < 70%)';
        });
        _showErrorState();
      }
    } catch (e, stack) {
      developer.log('Currency inference error: $e\n$stack', name: 'CurrencyScreen');
      if (!mounted || _isDisposed) return;
      _showErrorState();
    }
  }

  void _showErrorState() {
    HapticFeedback.mediumImpact();
    setState(() {
      _status = "Couldn't identify note clearly\n\n${CurrencyResultFormatter.urduRetryMessage}";
      _detectedUrdu = '';
      _detectedEnglish = '';
      _statusColor = const Color(0xFFEF4444);
      _isProcessing = false;
    });

    unawaited(_tts.stop());
    unawaited(_tts.speak(CurrencyResultFormatter.urduRetryMessage));
    debugPrint('TTS Speaking: ${CurrencyResultFormatter.urduRetryMessage}');
  }

  void _resetToScanState() {
    HapticFeedback.lightImpact();
    setState(() {
      _status = 'Hold the note flat inside the frame';
      _detectedUrdu = '';
      _detectedEnglish = '';
      _statusColor = Colors.white;
      _isProcessing = false;
    });

    unawaited(_tts.stop());
    unawaited(_tts.speak('دوبارہ نوٹ چیک کرنے کے لیے تیار۔ سکرین پر ٹیپ کریں'));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_isProcessing) return;
        HapticFeedback.selectionClick();
        if (_detectedUrdu.isNotEmpty) {
          unawaited(_tts.stop());
          unawaited(_tts.speak(_detectedUrdu));
        } else if (_status.contains("Couldn't identify")) {
          _resetToScanState();
        } else {
          _runRealInference();
        }
      },
      onDoubleTap: () {
        if (_isProcessing) return;
        if (_detectedUrdu.isNotEmpty || _status.contains("Couldn't identify")) {
          _resetToScanState();
        }
      },
      onHorizontalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 200 || (details.primaryVelocity ?? 0) < -200) {
          HapticFeedback.mediumImpact();
          _isExiting = true;
          unawaited(_tts.stop());
          unawaited(_tts.speak('واپس جا رہے ہیں'));
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      },
      child: CameraBaseScreen(
        title: 'Currency Classifier',
        statusText: _status,
        statusTextColor: _statusColor,
        cameraPreviewWidget: _cameraReady
            ? Stack(
                children: [
                  _cameraService.buildPreview(),
                  if (_debugPreprocessedBytes != null)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(204),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber, width: 1.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Model Input (224x224)',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.memory(
                                _debugPreprocessedBytes!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _confidenceDebugText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              )
            : null,
        overlayWidget: (_detectedUrdu.isNotEmpty || _detectedEnglish.isNotEmpty)
            ? Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.center,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(38),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFD97706), width: 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFEF3C7), // Light amber
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.payments_rounded, color: Color(0xFFD97706), size: 24),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Currency Result',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _detectedUrdu,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 10),
                      Divider(color: Colors.grey.shade200, thickness: 1.5),
                      const SizedBox(height: 10),
                      Text(
                        _detectedEnglish,
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Speaking...',
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,

        bottomWidget: Column(
          children: [
            if (_detectedUrdu.isEmpty && !_status.contains('Couldn\'t identify'))
              PrimaryButton(
                label: _isProcessing ? 'Processing...' : 'Scan Note',
                onPressed: _isProcessing ? null : _runRealInference,
              ),
            if (_detectedUrdu.isNotEmpty || _status.contains('Couldn\'t identify'))
              PrimaryButton(
                label: _detectedUrdu.isNotEmpty ? 'Scan next note' : 'Retry',
                onPressed: _resetToScanState,
              ),
          ],
        ),
      ),
    );
  }
}
