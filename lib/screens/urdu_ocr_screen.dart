import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'camera_base_screen.dart';
import '../widgets/primary_button.dart';
import '../core/camera_service.dart';
import '../core/ocr_service.dart';
import '../core/history_service.dart';

class UrduOCRScreen extends StatefulWidget {
  const UrduOCRScreen({super.key});

  @override
  State<UrduOCRScreen> createState() => _UrduOCRScreenState();
}

class _UrduOCRScreenState extends State<UrduOCRScreen> {
  final CameraService _cameraService = CameraService();
  final OcrService _ocrService = OcrService();
  final FlutterTts _tts = FlutterTts();

  String _status = 'Initializing camera\nPoint at signboard - hold steady';
  bool _isExiting = false;
  String _detectedText = '';
  Color _statusColor = Colors.white;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initializeCamera();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ur-PK');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    if (mounted) {
      _tts.speak("اردو لکھائی اور تحریر پڑھنے کا نظام کھل گیا ہے۔ کتاب، سائن بورڈ یا پرچی کے سامنے فون پکڑیں، اور تصویر لینے کے لیے سکرین پر کہیں بھی ٹیپ کریں");
    }
  }

  Future<void> _initializeCamera() async {
    // Tesseract desperately needs high resolution for complex cursive scripts like Urdu.
    final success = await _cameraService.initialize(
      resolutionPreset: ResolutionPreset.veryHigh,
    );
    if (!mounted) return;
    
    if (!success) {
      setState(() {
        _status = _cameraService.errorMessage ?? 'Failed to initialize camera.';
        _statusColor = const Color(0xFFEF4444);
      });
    } else {
      setState(() {
        _status = 'Point at signboard - hold steady';
        _statusColor = Colors.white;
      });
    }
  }

  @override
  void dispose() {
    if (!_isExiting) {
      _tts.stop();
    }
    _cameraService.dispose();
    super.dispose();
  }

  Future<void> _captureAndRecognize() async {
    if (!_cameraService.isInitialized || _cameraService.controller == null || _isProcessing) return;

    _tts.stop();
    _tts.speak("تصویر لے لی گئی ہے، اردو تحریر پڑھی جا رہی ہے، انتظار کریں");

    setState(() {
      _isProcessing = true;
      _status = 'Detecting text\nRunning Tesseract OCR — Urdu model';
      _statusColor = Colors.white;
    });

    try {
      final image = await _cameraService.controller!.takePicture();
      final result = await _ocrService.recognizeText(image.path);

      if (!mounted) return;

      if (result.success && result.text.isNotEmpty) {
        setState(() {
          _status = '';
          _detectedText = result.text;
          _statusColor = Colors.white;
          _isProcessing = false;
        });
        HapticFeedback.lightImpact();
        _tts.stop();
        _tts.speak(result.text);
        HistoryService.saveScan(type: 'Urdu OCR Reader', result: result.text);
      } else {
        setState(() {
          _status = 'No readable text found\n\nقریب جا کر دوبارہ کوشش کریں';
          _detectedText = '';
          _statusColor = const Color(0xFFEF4444);
          _isProcessing = false;
        });
        HapticFeedback.mediumImpact();
        _tts.stop();
        _tts.speak("کوئی واضح اردو تحریر نہیں ملی۔ فون کو تھوڑا قریب یا سیدھا کر کے دوبارہ کوشش کریں");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'No readable text found\n\nقریب جا کر دوبارہ کوشش کریں';
        _detectedText = '';
        _statusColor = const Color(0xFFEF4444);
        _isProcessing = false;
      });
      HapticFeedback.mediumImpact();
      _tts.stop();
      _tts.speak("کوئی واضح اردو تحریر نہیں ملی۔ فون کو تھوڑا قریب یا سیدھا کر کے دوبارہ کوشش کریں");
    }
  }

  void _repeatSpeech() {
    if (_detectedText.isNotEmpty) {
      HapticFeedback.selectionClick();
      _tts.stop();
      _tts.speak(_detectedText);
    }
  }

  void _resetToScan() {
    HapticFeedback.mediumImpact();
    _tts.stop();
    _tts.speak("دوبارہ تصویر لینے کے لیے تیار۔ سکرین پر ٹیپ کریں");
    setState(() {
      _status = 'Point at signboard - hold steady';
      _detectedText = '';
      _statusColor = Colors.white;
    });
  }

  void _onSwipeBack() {
    HapticFeedback.mediumImpact();
    _isExiting = true;
    _tts.stop();
    _tts.speak("واپس جا رہے ہیں");
    Navigator.of(context).pop();
  }

  void _onScreenTap() {
    if (_isProcessing) return;
    if (_detectedText.isNotEmpty || _status.contains('No readable text')) {
      if (_detectedText.isNotEmpty) {
        _repeatSpeech();
      } else {
        _resetToScan();
      }
    } else {
      HapticFeedback.selectionClick();
      _captureAndRecognize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onScreenTap,
      onDoubleTap: () {
        if (_detectedText.isNotEmpty || _status.contains('No readable text')) {
          _resetToScan();
        }
      },
      onHorizontalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 250) {
          _onSwipeBack();
        }
      },
      child: CameraBaseScreen(
        title: 'Urdu OCR Reader',
      statusText: _status,
      statusTextColor: _statusColor,
      cameraPreviewWidget: _cameraService.buildPreview(),
      overlayWidget: _detectedText.isNotEmpty
          ? Positioned.fill(
              child: Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: double.infinity),
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
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Expanded(
                            child: Text(
                              'پڑھنے کا نتیجہ (Urdu OCR Result)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4B5563),
                              ),
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFD1FAE5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.description_rounded, color: Color(0xFF10B981), size: 22),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Flexible(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            _detectedText,
                            style: TextStyle(
                              color: const Color(0xFF111827),
                              fontSize: _detectedText.length > 150
                                  ? 20
                                  : (_detectedText.length > 60 ? 22 : 26),
                              fontWeight: FontWeight.bold,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Speaking...',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
      bottomWidget: Column(
        children: [
          if (_status.contains('Point at signboard'))
            PrimaryButton(
              label: 'Continue',
              onPressed: _isProcessing ? null : _captureAndRecognize,
            ),
          if (_status.contains('Detecting text') && _isProcessing)
            const CircularProgressIndicator(color: Colors.white),
          if (_detectedText.isNotEmpty || _status.contains('No readable text'))
            Row(
              children: [
                if (_detectedText.isNotEmpty) ...[
                  Expanded(
                    child: PrimaryButton(
                      label: 'Read Again',
                      isSecondary: true,
                      onPressed: _repeatSpeech,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: PrimaryButton(
                    label: _detectedText.isNotEmpty ? 'Scan Again' : 'Retry',
                    onPressed: _resetToScan,
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
    );
  }
}
