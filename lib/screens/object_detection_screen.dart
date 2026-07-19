import 'package:flutter/material.dart';
import 'camera_base_screen.dart';
import '../widgets/primary_button.dart';

class ObjectDetectionScreen extends StatefulWidget {
  const ObjectDetectionScreen({super.key});

  @override
  State<ObjectDetectionScreen> createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  String _status = 'Initializing camera';
  String _detectedUrdu = '';
  String _detectedEnglish = '';
  Color _statusColor = Colors.white;

  void _simulateDetection() {
    setState(() {
      _status = '';
      _detectedUrdu = 'دو کرسیاں آگے ہیں';
      _detectedEnglish = 'Two wooden chairs are positioned about 2 meters ahead, slightly to your left. Clear walking space to your right.';
      _statusColor = Colors.white;
    });
  }

  void _simulateBlurry() {
    setState(() {
      _status = 'Too dark to detect clearly\n\nروشنی کم ہے، براہ کرم روشن جگہ پر جائیں';
      _detectedUrdu = '';
      _detectedEnglish = '';
      _statusColor = const Color(0xFFEF4444); // Bright red warning
    });
  }

  @override
  Widget build(BuildContext context) {
    return CameraBaseScreen(
      title: 'Object Detection',
      statusText: _status,
      statusTextColor: _statusColor,
      overlayWidget: (_detectedUrdu.isNotEmpty || _detectedEnglish.isNotEmpty)
          ? Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.bottomCenter,
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
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD1FAE5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 24),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Scan Result',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
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
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey.shade200, thickness: 1.5),
                    const SizedBox(height: 12),
                    Text(
                      _detectedEnglish,
                      style: const TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : null,
      bottomWidget: Column(
        children: [
          if (_status == 'Initializing camera')
            PrimaryButton(
              label: 'Continue',
              onPressed: () {
                setState(() {
                  _status = 'detecting objects...\nRunning YOLOv8 on-device';
                });
              },
            ),
          if (_status.contains('detecting objects'))
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Simulate detected',
                    onPressed: _simulateDetection,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton(
                    label: 'Simulate too blurry',
                    onPressed: _simulateBlurry,
                  ),
                ),
              ],
            ),
          if (_detectedUrdu.isNotEmpty || _status.contains('Too dark'))
            PrimaryButton(
              label: _detectedUrdu.isNotEmpty ? 'Scan Again' : 'Retry',
              onPressed: () {
                setState(() {
                  _status = 'detecting objects...\nRunning YOLOv8 on-device';
                  _detectedUrdu = '';
                  _detectedEnglish = '';
                  _statusColor = Colors.white;
                });
              },
            ),
        ],
      ),
    );
  }
}
