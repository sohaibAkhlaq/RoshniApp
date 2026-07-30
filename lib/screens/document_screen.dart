import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../core/camera_service.dart';
import '../core/document_edge_detector.dart';
import '../core/document_ocr_service.dart';
import '../core/guidance_engine.dart';
import '../core/live_quad_detector.dart';
import '../core/line_sequencer.dart';
import '../core/history_service.dart';
import '../widgets/primary_button.dart';
import 'camera_base_screen.dart';

class DocumentScreen extends StatelessWidget {
  const DocumentScreen({super.key});

  @override
  Widget build(BuildContext context) => const _DocumentScreenContent();
}

class _DocumentScreenContent extends StatefulWidget {
  const _DocumentScreenContent();

  @override
  State<_DocumentScreenContent> createState() => _DocumentScreenContentState();
}

class _DocumentScreenContentState extends State<_DocumentScreenContent>
    with WidgetsBindingObserver {
  // --- Services ---
  final CameraService _cameraService = CameraService();
  final DocumentEdgeDetector _edgeDetector = DocumentEdgeDetector();
  final DocumentOCRService _ocrService = DocumentOCRService();
  final LineSequencer _lineSequencer = LineSequencer();
  final LiveQuadDetector _liveQuadDetector = LiveQuadDetector();
  final GuidanceEngine _guidanceEngine = GuidanceEngine(requiredStableFrames: 4);
  final ScrollController _resultScrollController = ScrollController();
  final FlutterTts _tts = FlutterTts();

  // --- State ---
  _DocumentPhase _phase = _DocumentPhase.initializing;
  String _status = 'Initializing camera...';
  Color _statusColor = Colors.white;

  bool _isDisposed = false;
  bool _isExiting = false;
  bool _isScanning = false;
  bool _isProcessingFrame = false;

  GuidanceInstruction? _lastSpokenInstruction;
  DateTime _lastSpokenTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// OCR result lines.
  List<ReadableLine> _readableLines = [];
  int _currentReadingLine = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initTts();
    _initializeCamera();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ur-PK');
    await _tts.setSpeechRate(0.40);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.stop();
    await _tts.speak('دستاویز پڑھنے کا نظام کھل گیا ہے۔ فون کو کاغذ کے اوپر سیدھا پکڑیں تاکہ چاروں کونے نظر آئیں۔ سکرین پر ٹیپ کر کے بھی سکین کر سکتے ہیں');
  }

  @override
  void dispose() {
    _isDisposed = true;
    _resultScrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    if (!_isExiting) {
      unawaited(_tts.stop());
    }
    unawaited(_cleanupAndDispose());
    super.dispose();
  }

  Future<void> _cleanupAndDispose() async {
    try {
      await _cameraService.controller?.stopImageStream();
    } catch (_) {}
    await _cameraService.dispose();
    _edgeDetector.close();
    _ocrService.dispose();
  }

  Future<void> _initializeCamera() async {
    final success = await _cameraService.initialize();
    if (!mounted || _isDisposed) return;

    if (success && _cameraService.controller != null) {
      setState(() {
        _phase = _DocumentPhase.guidance;
        _status = 'Looking for document';
      });

      // Start the lightweight quad detection loop
      await _cameraService.controller!.startImageStream((image) async {
        if (_isProcessingFrame || _phase != _DocumentPhase.guidance) return;
        _isProcessingFrame = true;

        try {
          final quad = await _liveQuadDetector.detectQuad(image);
          final instruction = _guidanceEngine.evaluate(quad);

          if (!mounted || _isDisposed || _phase != _DocumentPhase.guidance) return;

          setState(() {
            _status = _guidanceEngine.getSpokenMessage(instruction);
            _statusColor = instruction == GuidanceInstruction.stable
                ? const Color(0xFF34D399) // Green when stable
                : Colors.white;
          });

          final now = DateTime.now();
          if (instruction == GuidanceInstruction.stable || now.difference(_lastSpokenTime).inMilliseconds > 4000) {
            if (instruction != _lastSpokenInstruction || now.difference(_lastSpokenTime).inMilliseconds > 5000) {
              _lastSpokenInstruction = instruction;
              _lastSpokenTime = now;
              unawaited(_tts.stop());
              unawaited(_tts.speak(_status));
            }
          }

          if (instruction == GuidanceInstruction.stable) {
            // Document is stable. Stop stream and hand off to ML Kit.
            await _cameraService.controller!.stopImageStream();
            _launchScanner();
          }
        } catch (e) {
          developer.log('Live detection error: $e');
        } finally {
          _isProcessingFrame = false;
        }
      });
    } else {
      setState(() {
        _phase = _DocumentPhase.error;
        _status = _cameraService.errorMessage ?? 'Camera initialization failed';
        _statusColor = const Color(0xFFEF4444);
      });
    }
  }

  // =======================================================================
  // ML Kit Document Scanner Flow
  // =======================================================================

  Future<void> _launchScanner() async {
    if (_isScanning) return;
    _isScanning = true;

    setState(() {
      _phase = _DocumentPhase.scanning;
      _status = 'توجہ رکھیں، تصویر لی جا رہی ہے...';
      _statusColor = Colors.white;
    });

    try {
      HapticFeedback.mediumImpact();
      unawaited(_tts.stop());
      unawaited(_tts.speak('تصویر لی جا رہی ہے، فون کو اسی جگہ رکھیں'));

      if (_cameraService.controller != null && _cameraService.controller!.value.isStreamingImages) {
        await _cameraService.controller!.stopImageStream();
      }

      // Small delay to allow camera auto-focus to settle
      await Future.delayed(const Duration(milliseconds: 600));

      final xfile = await _cameraService.controller!.takePicture();
      if (!mounted || _isDisposed) return;

      // Process the captured image directly through OCR, bypassing ML Kit's native review screen!
      await _processScannedImage(xfile.path);
    } catch (e) {
      developer.log('Direct camera capture error: $e', name: 'DocumentScreen');
      if (!mounted || _isDisposed) return;
      _returnToReady();
    }
  }

  Future<void> _processScannedImage(String imagePath) async {
    setState(() {
      _phase = _DocumentPhase.processing;
      _status = 'Reading document...';
      _statusColor = Colors.white;
    });

    try {
      final ocrResult = await _ocrService.extractTextFromFile(imagePath);
      final lines = _lineSequencer.sequenceLines(ocrResult);

      if (!mounted || _isDisposed) return;

      if (lines.isEmpty) {
        _showNotVisibleError();
        return;
      }

      setState(() {
        _phase = _DocumentPhase.result;
        _readableLines = lines;
        _currentReadingLine = 0;
        _status = '';
        _isScanning = false;
      });

      HapticFeedback.lightImpact();
      final fullText = lines.map((l) => l.text).join('. ');
      unawaited(_tts.stop());
      unawaited(_tts.speak(fullText));
      unawaited(HistoryService.saveScan(type: 'Document Reader', result: fullText));

      _startLineByLineReading();
    } catch (e) {
      developer.log('OCR processing error: $e', name: 'DocumentScreen');
      if (!mounted || _isDisposed) return;
      _showNotVisibleError();
    }
  }

  void _showNotVisibleError() {
    HapticFeedback.mediumImpact();
    setState(() {
      _phase = _DocumentPhase.notVisible;
      _status = 'Document not fully visible\n\nPlease include all 4 corners of the page';
      _statusColor = const Color(0xFFEF4444);
      _isScanning = false;
    });

    unawaited(_tts.stop());
    unawaited(_tts.speak('دستاویز مکمل نظر نہیں آ رہی، فون کو تھوڑا پیچھے کریں اور دوبارہ کوشش کریں'));
  }

  void _startLineByLineReading() {
    if (_readableLines.isEmpty) return;

    Future<void> readNext(int index) async {
      if (!mounted || _isDisposed || _phase != _DocumentPhase.result) return;
      if (index >= _readableLines.length) return;

      setState(() {
        _currentReadingLine = index;
      });

      if (_resultScrollController.hasClients) {
        final targetOffset = index * 48.0;
        _resultScrollController.animateTo(
          targetOffset.clamp(0.0, _resultScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      final wordCount = _readableLines[index].text.split(' ').length;
      final delayMillis = math.max(2500, wordCount * 380);
      await Future.delayed(Duration(milliseconds: delayMillis));

      if (!mounted || _isDisposed || _phase != _DocumentPhase.result) return;
      await readNext(index + 1);
    }

    unawaited(readNext(0));
  }

  void _returnToReady() {
    HapticFeedback.lightImpact();
    setState(() {
      _phase = _DocumentPhase.guidance;
      _status = 'Looking for document';
      _statusColor = Colors.white;
      _readableLines = [];
      _currentReadingLine = 0;
      _isScanning = false;
      _isProcessingFrame = false;
      _lastSpokenInstruction = null;
    });

    unawaited(_tts.stop());
    unawaited(_tts.speak('دستاویز تلاش کی جا رہی ہے'));
    
    // Restart image stream
    if (_cameraService.controller != null && !_cameraService.controller!.value.isStreamingImages) {
      _cameraService.controller!.startImageStream((image) async {
        if (_isProcessingFrame || _phase != _DocumentPhase.guidance) return;
        _isProcessingFrame = true;

        try {
          final quad = await _liveQuadDetector.detectQuad(image);
          final instruction = _guidanceEngine.evaluate(quad);

          if (!mounted || _isDisposed || _phase != _DocumentPhase.guidance) return;

          setState(() {
            _status = _guidanceEngine.getSpokenMessage(instruction);
            _statusColor = instruction == GuidanceInstruction.stable
                ? const Color(0xFF34D399) // Green when stable
                : Colors.white;
          });

          final now = DateTime.now();
          if (instruction == GuidanceInstruction.stable || now.difference(_lastSpokenTime).inMilliseconds > 4000) {
            if (instruction != _lastSpokenInstruction || now.difference(_lastSpokenTime).inMilliseconds > 5000) {
              _lastSpokenInstruction = instruction;
              _lastSpokenTime = now;
              unawaited(_tts.stop());
              unawaited(_tts.speak(_status));
            }
          }

          if (instruction == GuidanceInstruction.stable) {
            await _cameraService.controller!.stopImageStream();
            _launchScanner();
          }
        } catch (e) {
          developer.log('Live detection error: $e');
        } finally {
          _isProcessingFrame = false;
        }
      });
    }
  }

  // =======================================================================
  // BUILD — UI Shell
  // =======================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        if (_phase == _DocumentPhase.guidance) {
          if (_cameraService.controller != null && _cameraService.controller!.value.isStreamingImages) {
            unawaited(_cameraService.controller!.stopImageStream());
          }
          _launchScanner();
        } else if (_phase == _DocumentPhase.result && _readableLines.isNotEmpty) {
          final fullText = _readableLines.map((l) => l.text).join('. ');
          unawaited(_tts.stop());
          unawaited(_tts.speak(fullText));
        } else if (_phase == _DocumentPhase.notVisible || _phase == _DocumentPhase.error) {
          _returnToReady();
        }
      },
      onDoubleTap: () {
        if (_phase == _DocumentPhase.result || _phase == _DocumentPhase.notVisible || _phase == _DocumentPhase.error) {
          _returnToReady();
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
        title: 'Document Reader',
        statusText: _status,
        statusTextColor: _statusColor,
        cameraPreviewWidget: _buildViewfinderContent(),
        overlayWidget: _phase == _DocumentPhase.result && _readableLines.isNotEmpty
            ? _buildResultOverlay(theme)
            : null,
        bottomWidget: _buildBottomWidget(),
      ),
    );
  }

  Widget _buildViewfinderContent() {
    switch (_phase) {
      case _DocumentPhase.initializing:
        return const Center(child: CircularProgressIndicator(color: Color(0xFFD97706)));

      case _DocumentPhase.guidance:
        return _cameraService.buildPreview();

      case _DocumentPhase.scanning:
      case _DocumentPhase.processing:
        return Container(
          color: const Color(0xFF111827),
          alignment: Alignment.center,
          child: const CircularProgressIndicator(color: Color(0xFFD97706)),
        );

      case _DocumentPhase.result:
      case _DocumentPhase.notVisible:
      case _DocumentPhase.error:
        return Container(
          color: const Color(0xFF111827),
          alignment: Alignment.center,
          child: Icon(
            _phase == _DocumentPhase.notVisible
                ? Icons.visibility_off_rounded
                : _phase == _DocumentPhase.error
                    ? Icons.error_outline_rounded
                    : Icons.document_scanner_rounded,
            size: 72,
            color: Colors.white70,
          ),
        );
    }
  }

  Widget _buildResultOverlay(ThemeData theme) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.65,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0F2FE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFF0284C7),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Document Read',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  controller: _resultScrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: _readableLines.asMap().entries.map((entry) {
                      final index = entry.key;
                      final line = entry.value;
                      final isCurrentLine = index == _currentReadingLine;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrentLine
                                ? const Color(0xFFFEF3C7)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isCurrentLine
                                ? Border.all(
                                    color: const Color(0xFFD97706),
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isCurrentLine)
                                const Text(
                                  '▶ ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  line.text,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isCurrentLine
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _currentReadingLine < _readableLines.length
                    ? 'Reading line ${_currentReadingLine + 1} of ${_readableLines.length}...'
                    : 'Reading complete',
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD97706),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildBottomWidget() {
    switch (_phase) {
      case _DocumentPhase.initializing:
        return null;

      case _DocumentPhase.guidance:
        // Manual override button
        return PrimaryButton(
          label: 'Tap to Scan Now',
          onPressed: () {
            _cameraService.controller?.stopImageStream();
            _launchScanner();
          },
        );

      case _DocumentPhase.scanning:
      case _DocumentPhase.processing:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(color: Color(0xFFD97706)),
          ),
        );

      case _DocumentPhase.result:
        return PrimaryButton(
          label: 'Scan another document',
          onPressed: _returnToReady,
        );

      case _DocumentPhase.notVisible:
        return PrimaryButton(
          label: 'Scan again',
          onPressed: _returnToReady,
        );

      case _DocumentPhase.error:
        return PrimaryButton(
          label: 'Retry',
          onPressed: _initializeCamera,
        );
    }
  }
}

enum _DocumentPhase {
  initializing,
  guidance,
  scanning,
  processing,
  result,
  notVisible,
  error,
}
