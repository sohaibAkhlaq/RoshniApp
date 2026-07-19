import 'package:flutter/material.dart';
import 'camera_base_screen.dart';
import '../widgets/primary_button.dart';

class PhotoDescriptionScreen extends StatefulWidget {
  const PhotoDescriptionScreen({super.key});

  @override
  State<PhotoDescriptionScreen> createState() => _PhotoDescriptionScreenState();
}

class _PhotoDescriptionScreenState extends State<PhotoDescriptionScreen> {
  String _status = 'Live camera preview';
  String _detectedText = '';
  Color _statusColor = Colors.white;

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

  @override
  Widget build(BuildContext context) {
    return CameraBaseScreen(
      title: 'Photo Description',
      statusText: _status,
      statusTextColor: _statusColor,
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
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF3E8FF), // Light purple
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.wb_sunny_rounded, color: Color(0xFFA855F7), size: 24),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Photo Scene Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _detectedText,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Speaking...',
                      style: TextStyle(
                        fontSize: 15,
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
          if (_status.contains('Live camera'))
            PrimaryButton(
              label: 'Capture Photo',
              onPressed: () {
                setState(() {
                  _status = 'captured photo\nCloud AI model — requires internet';
                });
              },
            ),
          if (_status.contains('Cloud AI model'))
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Simulate online',
                    onPressed: _simulateOnline,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton(
                    label: 'Simulate no internet',
                    onPressed: _simulateNoInternet,
                  ),
                ),
              ],
            ),
          if (_detectedText.isNotEmpty || _status.contains('No internet'))
            PrimaryButton(
              label: _detectedText.isNotEmpty ? 'Scan another photo' : 'Try Again',
              onPressed: () {
                setState(() {
                  _status = 'captured photo\nCloud AI model — requires internet';
                  _detectedText = '';
                  _statusColor = Colors.white;
                });
              },
            ),
        ],
      ),
    );
  }
}
