import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_base_screen.dart';
import '../widgets/primary_button.dart';
import '../core/camera_service.dart';
import '../core/ocr_service.dart';

class UrduOCRScreen extends StatefulWidget {
  const UrduOCRScreen({super.key});

  @override
  State<UrduOCRScreen> createState() => _UrduOCRScreenState();
}

class _UrduOCRScreenState extends State<UrduOCRScreen> {
  final CameraService _cameraService = CameraService();
  final OcrService _ocrService = OcrService();

  String _status = 'Initializing camera\nPoint at signboard - hold steady';
  String _detectedText = '';
  Color _statusColor = Colors.white;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
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
    _cameraService.dispose();
    super.dispose();
  }

  Future<void> _captureAndRecognize() async {
    if (!_cameraService.isInitialized || _cameraService.controller == null || _isProcessing) return;

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
      } else {
        setState(() {
          _status = 'No readable text found\n\nقریب جا کر دوبارہ کوشش کریں';
          _detectedText = '';
          _statusColor = const Color(0xFFEF4444);
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'No readable text found\n\nقریب جا کر دوبارہ کوشش کریں';
        _detectedText = '';
        _statusColor = const Color(0xFFEF4444);
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CameraBaseScreen(
      title: 'Urdu OCR Reader',
      statusText: _status,
      statusTextColor: _statusColor,
      cameraPreviewWidget: _cameraService.buildPreview(),
      overlayWidget: _detectedText.isNotEmpty
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
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'پڑھنے کا نتیجہ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD1FAE5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.description_rounded, color: Color(0xFF10B981), size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _detectedText,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 14),
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
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: PrimaryButton(
                    label: _detectedText.isNotEmpty ? 'Scan Again' : 'Retry',
                    onPressed: () {
                      setState(() {
                        _status = 'Point at signboard - hold steady';
                        _detectedText = '';
                        _statusColor = Colors.white;
                      });
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
