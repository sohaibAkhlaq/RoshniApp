import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../core/camera_service.dart';
import '../core/connectivity_service.dart';
import '../core/image_preprocessor.dart';
import '../core/photo_description_service.dart';
import 'camera_base_screen.dart';
import '../widgets/primary_button.dart';

class PhotoDescriptionScreen extends StatefulWidget {
  const PhotoDescriptionScreen({super.key});

  @override
  State<PhotoDescriptionScreen> createState() => _PhotoDescriptionScreenState();
}

class _PhotoDescriptionScreenState extends State<PhotoDescriptionScreen>
    with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final PhotoDescriptionService _photoDescriptionService =
      PhotoDescriptionService();
  final ImagePreprocessor _imagePreprocessor = ImagePreprocessor();
  final FlutterTts _tts = FlutterTts();

  String _status = 'لائیو کیمرہ، تصویر کے لیے ٹیپ کریں';
  String _detectedText = '';
  Color _statusColor = Colors.white;

  Uint8List? _capturedImageBytes;
  bool _isShowingDetail = false;
  bool _cameraReady = false;
  bool _isInitializing = true;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initTts());
    unawaited(_initializeCamera());
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ur-PK');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.stop();
    await _tts.speak('فوٹو ڈسکرپشن کھل گیا ہے۔ تصویر لینے کے لیے سکرین پر ایک بار ٹیپ کریں');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_releaseCamera());
    } else if (state == AppLifecycleState.resumed && !_isDisposed) {
      unawaited(_initializeCamera());
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_tts.stop());
    unawaited(_releaseCamera());
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (_cameraReady || (!_isInitializing && _cameraService.controller != null)) {
      return;
    }

    setState(() {
      _isInitializing = true;
      _status = 'کیمرہ کھل رہا ہے...';
    });

    try {
      final success = await _cameraService.initialize();
      if (!mounted || _isDisposed) return;

      if (!success) {
        setState(() {
          _isInitializing = false;
          _status = _cameraService.errorMessage ?? 'کیمرہ نہیں کھل سکا';
        });
        return;
      }

      setState(() {
        _cameraReady = true;
        _isInitializing = false;
        _status = 'لائیو کیمرہ، تصویر کے لیے ٹیپ کریں';
      });
    } catch (e) {
      if (!mounted || _isDisposed) return;
      setState(() {
        _isInitializing = false;
        _status = 'کیمرہ نہیں کھل سکا: $e';
      });
    }
  }

  Future<void> _releaseCamera() async {
    _cameraReady = false;
    await _cameraService.dispose();
    if (!_isDisposed && mounted) {
      setState(() {});
    }
  }

  void _simulateOnline() {
    setState(() {
      _status = '';
      _detectedText = 'ایک پرسکون پارک کا منظر جس میں دو بڑے درختوں کے نیچے لکڑی کا بنچ رکھا ہے۔ پتوں سے دھوپ چھن کر آ رہی ہے اور گھاس کے ساتھ ایک پکا راستہ گزر رہا ہے۔';
      _statusColor = Colors.white;
    });
    unawaited(_tts.stop());
    unawaited(_tts.speak(_detectedText));
  }

  void _simulateNoInternet() {
    _showNoInternetError();
  }

  Future<void> _capturePhoto() async {
    final controller = _cameraService.controller;
    if (controller == null || !controller.value.isInitialized) {
      setState(() {
        _status = 'Camera not ready';
      });
      return;
    }

    setState(() {
      _status = 'تصویر لی جا رہی ہے...';
    });
    HapticFeedback.mediumImpact();
    unawaited(_tts.stop());
    unawaited(_tts.speak('تصویر لی جا رہی ہے، انتظار کریں'));

    try {
      final xfile = await controller.takePicture();
      final imageBytes = await xfile.readAsBytes();

      if (!mounted || _isDisposed) return;

      _capturedImageBytes = imageBytes;

      await _processCapturedImage(imageBytes);
    } catch (e) {
      if (!mounted || _isDisposed) return;
      _showError('تصویر لینے میں مسئلہ: $e');
    }
  }

  Future<void> _processCapturedImage(Uint8List imageBytes) async {
    setState(() {
      _status = 'انٹرنیٹ چیک کیا جا رہا ہے...';
    });

    final hasInternet = await _connectivityService.hasInternet();
    if (!mounted || _isDisposed) return;

    if (!hasInternet) {
      _showNoInternetError();
      return;
    }

    setState(() {
      _status = 'تصویر کی وضاحت کی جا رہی ہے، انتظار کریں...';
    });
    unawaited(_tts.stop());
    unawaited(_tts.speak('تصویر کی وضاحت کی جا رہی ہے، انتظار کریں'));

    try {
      final preprocessed = _imagePreprocessor.preprocess(imageBytes);
      final result = await _photoDescriptionService.getShortDescription(preprocessed);

      if (!mounted || _isDisposed) return;

      if (result.success && result.caption != null) {
        HapticFeedback.lightImpact();
        setState(() {
          _status = '';
          _detectedText = result.caption!;
          _statusColor = Colors.white;
          _isShowingDetail = false;
        });
        unawaited(_tts.stop());
        unawaited(_tts.speak(_detectedText));
      } else {
        _showError(result.error ?? 'نامعلوم خرابی');
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
      _showError('وضاحت معلوم کرنے میں مسئلہ: $e');
    }
  }

  Future<void> _getDetailedDescription() async {
    if (_capturedImageBytes == null) return;

    setState(() {
      _status = 'انٹرنیٹ چیک کیا جا رہا ہے...';
    });

    final hasInternet = await _connectivityService.hasInternet();
    if (!mounted || _isDisposed) return;

    if (!hasInternet) {
      _showNoInternetError();
      return;
    }

    setState(() {
      _status = 'مزید تفصیل معلوم کی جا رہی ہے...';
    });
    HapticFeedback.lightImpact();
    unawaited(_tts.stop());
    unawaited(_tts.speak('مزید تفصیل معلوم کی جا رہی ہے'));

    try {
      final preprocessed = _imagePreprocessor.preprocess(_capturedImageBytes!);
      final result =
          await _photoDescriptionService.getDetailedDescription(preprocessed);

      if (!mounted || _isDisposed) return;

      if (result.success && result.caption != null) {
        HapticFeedback.lightImpact();
        setState(() {
          _status = '';
          _detectedText = result.caption!;
          _statusColor = Colors.white;
          _isShowingDetail = true;
        });
        unawaited(_tts.stop());
        unawaited(_tts.speak(_detectedText));
      } else {
        _showError(result.error ?? 'نامعلوم خرابی');
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
      _showError('تفصیلی وضاحت معلوم کرنے میں مسئلہ: $e');
    }
  }

  void _showNoInternetError() {
    HapticFeedback.mediumImpact();
    setState(() {
      _status = "انٹرنیٹ کنکشن موجود نہیں ہے\n\nفوٹو ڈسکرپشن کے لیے انٹرنیٹ درکار ہے";
      _detectedText = '';
      _statusColor = const Color(0xFFEF4444);
    });
    unawaited(_tts.stop());
    unawaited(_tts.speak('انٹرنیٹ کنکشن موجود نہیں ہے۔ فوٹو ڈسکرپشن کے لیے انٹرنیٹ درکار ہے'));
  }

  void _showError(String message) {
    if (message.toLowerCase().contains('internet') ||
        message.toLowerCase().contains('network')) {
      _showNoInternetError();
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _status = "تصویر کی وضاحت نہیں ہو سکی\n\n$message";
      _detectedText = '';
      _statusColor = const Color(0xFFEF4444);
    });
    unawaited(_tts.stop());
    unawaited(_tts.speak('تصویر کی وضاحت نہیں ہو سکی، دوبارہ کوشش کریں'));
  }

  void _retrySamePhoto() {
    if (_capturedImageBytes != null) {
      _processCapturedImage(_capturedImageBytes!);
    } else {
      setState(() {
        _status = 'لائیو کیمرہ، تصویر کے لیے ٹیپ کریں';
        _detectedText = '';
        _statusColor = Colors.white;
      });
    }
  }

  void _scanAnotherPhoto() {
    HapticFeedback.lightImpact();
    setState(() {
      _status = 'لائیو کیمرہ، تصویر کے لیے ٹیپ کریں';
      _detectedText = '';
      _statusColor = Colors.white;
      _capturedImageBytes = null;
      _isShowingDetail = false;
    });
    unawaited(_tts.stop());
    unawaited(_tts.speak('لائیو کیمرہ، تصویر لینے کے لیے سکرین پر ٹیپ کریں'));
  }

  void _useOfflineFeature() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        if (_capturedImageBytes == null) {
          _capturePhoto();
        } else if (_detectedText.isNotEmpty) {
          unawaited(_tts.stop());
          unawaited(_tts.speak(_detectedText));
        } else if (_statusColor == const Color(0xFFEF4444)) {
          _retrySamePhoto();
        }
      },
      onDoubleTap: () {
        if (_detectedText.isNotEmpty && !_isShowingDetail) {
          _getDetailedDescription();
        } else if (_capturedImageBytes != null || _statusColor == const Color(0xFFEF4444)) {
          _scanAnotherPhoto();
        }
      },
      onHorizontalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 200 || (details.primaryVelocity ?? 0) < -200) {
          HapticFeedback.mediumImpact();
          unawaited(_tts.stop());
          unawaited(_tts.speak('واپس جا رہے ہیں'));
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      },
      child: CameraBaseScreen(
        title: 'فوٹو ڈسکرپشن',
        statusText: _status,
        statusTextColor: _statusColor,
        cameraPreviewWidget: _cameraReady
            ? _cameraService.buildPreview()
            : _buildPlaceholder(),
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
                      border:
                          Border.all(color: const Color(0xFFD97706), width: 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF3E8FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.wb_sunny_rounded,
                                  color: Color(0xFFA855F7), size: 20),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isShowingDetail ? 'تصویر کی تفصیلی وضاحت' : 'تصویر کی مختصر وضاحت',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Scrollable description text
                        Flexible(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Text(
                              _detectedText,
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // "Speaking..." label
                        const Text(
                          'سنایا جا رہا ہے...',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        // "Tap for more detail" link
                        if (!_isShowingDetail) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _getDetailedDescription,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF2563EB).withAlpha(77)),
                              ),
                              child: const Text(
                                'مزید تفصیل کے لیے ڈبل ٹیپ کریں',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
            : null,
        bottomWidget: Column(
          children: [
            if (_status.contains('لائیو کیمرہ') || _status.contains('Live camera'))
              PrimaryButton(
                label: 'تصویر لیں (یا سکرین پر ٹیپ کریں)',
                onPressed: _capturePhoto,
              ),
            if (_detectedText.isNotEmpty)
              PrimaryButton(
                label: 'دوسری تصویر (یا ڈبل ٹیپ کریں)',
                onPressed: _scanAnotherPhoto,
              ),
            if (_status.contains('انٹرنیٹ') || _status.contains('No internet'))
              Column(
                children: [
                  PrimaryButton(
                    label: 'دوبارہ کوشش کریں',
                    onPressed: _retrySamePhoto,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'آف لائن فیچر استعمال کریں',
                    isSecondary: true,
                    onPressed: _useOfflineFeature,
                  ),
                ],
              ),
            if (_status.contains('وضاحت نہیں ہو سکی') || _status.contains('Unable to describe'))
              Column(
                children: [
                  PrimaryButton(
                    label: 'دوبارہ کوشش کریں',
                    onPressed: _retrySamePhoto,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'دوسری تصویر لیں',
                    onPressed: _scanAnotherPhoto,
                  ),
                ],
              ),
          ],
        ),
      ),
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
