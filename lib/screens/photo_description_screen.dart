import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

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

  String _status = 'Live camera preview';
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
    unawaited(_initializeCamera());
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
    unawaited(_releaseCamera());
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (_cameraReady || (!_isInitializing && _cameraService.controller != null)) {
      return;
    }

    setState(() {
      _isInitializing = true;
      _status = 'Initializing camera...';
    });

    try {
      final success = await _cameraService.initialize();
      if (!mounted || _isDisposed) return;

      if (!success) {
        setState(() {
          _isInitializing = false;
          _status = _cameraService.errorMessage ?? 'Camera initialization failed';
        });
        return;
      }

      setState(() {
        _cameraReady = true;
        _isInitializing = false;
        _status = 'Live camera preview';
      });
    } catch (e) {
      if (!mounted || _isDisposed) return;
      setState(() {
        _isInitializing = false;
        _status = 'Camera initialization failed: $e';
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
      _detectedText = 'A quiet park scene with a wooden bench under two large trees. Sunlight filters through the leaves, and a paved path runs alongside the grass.';
      _statusColor = Colors.white;
    });
  }

  void _simulateNoInternet() {
    setState(() {
      _status = "No internet connection\n\nPhoto Description needs internet for detailed results.\nObject Detection, OCR, and Currency still work offline.";
      _detectedText = '';
      _statusColor = const Color(0xFFEF4444);
    });
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
      _status = 'captured photo\nCloud AI model — requires internet';
    });

    try {
      final xfile = await controller.takePicture();
      final imageBytes = await xfile.readAsBytes();

      if (!mounted || _isDisposed) return;

      _capturedImageBytes = imageBytes;

      await _processCapturedImage(imageBytes);
    } catch (e) {
      if (!mounted || _isDisposed) return;
      _showError('Failed to capture photo: $e');
    }
  }

  Future<void> _processCapturedImage(Uint8List imageBytes) async {
    setState(() {
      _status = 'Checking connection...';
    });

    final hasInternet = await _connectivityService.hasInternet();
    if (!mounted || _isDisposed) return;

    if (!hasInternet) {
      _showNoInternetError();
      return;
    }

    setState(() {
      _status = 'Describing scene...';
    });

    try {
      final preprocessed = _imagePreprocessor.preprocess(imageBytes);
      final result = await _photoDescriptionService.getShortDescription(preprocessed);

      if (!mounted || _isDisposed) return;

      if (result.success && result.caption != null) {
        setState(() {
          _status = '';
          _detectedText = result.caption!;
          _statusColor = Colors.white;
          _isShowingDetail = false;
        });
      } else {
        _showError(result.error ?? 'Unknown error');
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
      _showError('Failed to get description: $e');
    }
  }

  Future<void> _getDetailedDescription() async {
    if (_capturedImageBytes == null) return;

    setState(() {
      _status = 'Checking connection...';
    });

    final hasInternet = await _connectivityService.hasInternet();
    if (!mounted || _isDisposed) return;

    if (!hasInternet) {
      _showNoInternetError();
      return;
    }

    setState(() {
      _status = 'Getting more detail...';
    });

    try {
      final preprocessed = _imagePreprocessor.preprocess(_capturedImageBytes!);
      final result =
          await _photoDescriptionService.getDetailedDescription(preprocessed);

      if (!mounted || _isDisposed) return;

      if (result.success && result.caption != null) {
        setState(() {
          _status = '';
          _detectedText = result.caption!;
          _statusColor = Colors.white;
          _isShowingDetail = true;
        });
      } else {
        _showError(result.error ?? 'Unknown error');
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
      _showError('Failed to get detailed description: $e');
    }
  }

  void _showNoInternetError() {
    setState(() {
      _status = "No internet connection\n\nPhoto Description needs internet for detailed results.\nObject Detection, OCR, and Currency still work offline.";
      _detectedText = '';
      _statusColor = const Color(0xFFEF4444);
    });
  }

  void _showError(String message) {
    if (message.toLowerCase().contains('internet') ||
        message.toLowerCase().contains('network')) {
      _showNoInternetError();
      return;
    }

    setState(() {
      _status = "Unable to describe photo\n\n$message";
      _detectedText = '';
      _statusColor = const Color(0xFFEF4444);
    });
  }

  void _retrySamePhoto() {
    if (_capturedImageBytes != null) {
      _processCapturedImage(_capturedImageBytes!);
    } else {
      setState(() {
        _status = 'Live camera preview';
        _detectedText = '';
        _statusColor = Colors.white;
      });
    }
  }

  void _scanAnotherPhoto() {
    setState(() {
      _status = 'Live camera preview';
      _detectedText = '';
      _statusColor = Colors.white;
      _capturedImageBytes = null;
      _isShowingDetail = false;
    });
  }

  void _useOfflineFeature() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return CameraBaseScreen(
      title: 'Photo Description',
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
                              _isShowingDetail ? 'Detailed Description' : 'Scene Description',
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
                        'Speaking...',
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
                              'Tap for more detail',
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
          if (_status.contains('Live camera'))
            PrimaryButton(
              label: 'Capture Photo',
              onPressed: _capturePhoto,
            ),
          if (_detectedText.isNotEmpty)
            PrimaryButton(
              label: 'Scan another photo',
              onPressed: _scanAnotherPhoto,
            ),
          if (_status.contains('No internet'))
            Column(
              children: [
                PrimaryButton(
                  label: 'Try Again',
                  onPressed: _retrySamePhoto,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Use an offline feature instead',
                  isSecondary: true,
                  onPressed: _useOfflineFeature,
                ),
              ],
            ),
          if (_status.contains('Unable to describe photo'))
            Column(
              children: [
                PrimaryButton(
                  label: 'Try Again',
                  onPressed: _retrySamePhoto,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Scan another photo',
                  onPressed: _scanAnotherPhoto,
                ),
              ],
            ),
        ],
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
