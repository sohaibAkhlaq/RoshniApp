import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'permission_service.dart';

/// A focused camera service that manages camera lifecycle.
///
/// - Uses the existing [PermissionService] for permission checks
/// - Initializes [CameraController] on the device's back camera
/// - Exposes a live preview widget via [buildPreview]
/// - Must be disposed via [dispose] when no longer needed
class CameraService {
  final PermissionService _permissionService = PermissionService();

  CameraController? _controller;
  bool _isInitialized = false;
  String? _errorMessage;

  /// Whether the camera has been successfully initialized.
  bool get isInitialized => _isInitialized;

  /// A human-readable error message, if initialization failed.
  String? get errorMessage => _errorMessage;

  /// The underlying controller, if initialized.
  CameraController? get controller => _controller;

  /// Initializes the camera.
  ///
  /// 1. Checks/requests camera permission via [PermissionService].
  /// 2. Enumerates available cameras and selects the back-facing one.
  /// 3. Creates and initializes a [CameraController].
  ///
  /// Returns `true` on success, `false` on failure (check [errorMessage]).
  Future<bool> initialize() async {
    try {
      // Step 1: Check permissions using the existing PermissionService
      final granted = await _permissionService.areAllGranted();
      if (!granted) {
        // Try requesting permissions
        final results = await _permissionService.requestAll();
        final allGranted = results.values.every(
          (s) => s == PermissionStatus.granted || s == PermissionStatus.limited,
        );
        if (!allGranted) {
          _errorMessage =
              'Camera permission not granted.\n'
              'Please enable camera access in Settings.';
          return false;
        }
      }

      // Step 2: Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _errorMessage = 'No cameras found on this device.';
        return false;
      }

      // Select the back camera (fallback to first available)
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // Step 3: Create and initialize the controller
      _controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false, // No audio needed for object detection preview
      );

      await _controller!.initialize();
      _isInitialized = true;
      _errorMessage = null;
      return true;
    } on CameraException catch (e) {
      _errorMessage = 'Camera error: ${e.description ?? e.code}';
      _isInitialized = false;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to initialize camera: $e';
      _isInitialized = false;
      return false;
    }
  }

  /// Returns a widget that shows the live camera preview.
  ///
  /// Returns a [CameraPreview] if initialized, or an error/loading placeholder.
  Widget buildPreview() {
    if (!_isInitialized || _controller == null) {
      return Center(
        child: Text(
          _errorMessage ?? 'Camera not initialized',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }
    final controller = _controller!;
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.previewSize?.height ?? 1,
        height: controller.value.previewSize?.width ?? 1,
        child: CameraPreview(controller),
      ),
    );
  }

  /// Disposes the camera controller and releases resources.
  Future<void> dispose() async {
    if (_controller != null) {
      if (_controller!.value.isInitialized) {
        await _controller!.dispose();
      }
      _controller = null;
      _isInitialized = false;
    }
  }
}
