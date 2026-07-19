import 'package:flutter/material.dart';
import 'camera_base_screen.dart';
import '../widgets/primary_button.dart';

class UrduOCRScreen extends StatefulWidget {
  const UrduOCRScreen({super.key});

  @override
  State<UrduOCRScreen> createState() => _UrduOCRScreenState();
}

class _UrduOCRScreenState extends State<UrduOCRScreen> {
  String _status = 'Initializing camera\nPoint at signboard - hold steady';
  String _detectedText = '';
  Color _statusColor = Colors.white;

  void _simulateTextFound() {
    setState(() {
      _status = '';
      _detectedText = 'بینک آف پنجاب\nکیش کاؤنٹر نمبر 3\nصبح 9 سے شام 5 بجے تک کھلا';
      _statusColor = Colors.white;
    });
  }

  void _simulateBlur() {
    setState(() {
      _status = 'No readable text found\n\nقریب جا کر دوبارہ کوشش کریں';
      _detectedText = '';
      _statusColor = const Color(0xFFEF4444);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CameraBaseScreen(
      title: 'Urdu OCR Reader',
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
          if (_status.contains('Initializing'))
            PrimaryButton(
              label: 'Continue',
              onPressed: () {
                setState(() {
                  _status = 'Detecting text\nRunning Tesseract OCR — Urdu model';
                });
              },
            ),
          if (_status.contains('Detecting text'))
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Simulate text found',
                    onPressed: _simulateTextFound,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton(
                    label: 'Simulate blur text',
                    onPressed: _simulateBlur,
                  ),
                ),
              ],
            ),
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
                        _status = 'Detecting text\nRunning Tesseract OCR — Urdu model';
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
