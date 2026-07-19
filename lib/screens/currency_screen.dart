import 'package:flutter/material.dart';
import 'camera_base_screen.dart';
import '../widgets/primary_button.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  String _status = 'Initializing camera\nHold the note flat inside the frame';
  String _detectedUrdu = '';
  String _detectedEnglish = '';
  Color _statusColor = Colors.white;

  void _simulateClear() {
    setState(() {
      _status = '';
      _detectedUrdu = 'یہ دس روپے کا نوٹ ہے';
      _detectedEnglish = 'Detected note: Rs 10';
      _statusColor = Colors.white;
    });
  }

  void _simulateBlurry() {
    setState(() {
      _status = "Couldn't identify note clearly\n\nنوٹ صاف نظر نہیں آ رہا،\nدوبارہ کوشش کریں";
      _detectedUrdu = '';
      _detectedEnglish = '';
      _statusColor = const Color(0xFFEF4444);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CameraBaseScreen(
      title: 'Currency Classifier',
      statusText: _status,
      statusTextColor: _statusColor,
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
          if (_status.contains('Initializing'))
            PrimaryButton(
              label: 'Continue',
              onPressed: () {
                setState(() {
                  _status = 'captured frame\nCNN · TensorFlow Lite';
                });
              },
            ),
          if (_status.contains('captured frame'))
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Simulate clear',
                    onPressed: _simulateClear,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton(
                    label: 'Simulate blurry',
                    onPressed: _simulateBlurry,
                  ),
                ),
              ],
            ),
          if (_detectedUrdu.isNotEmpty || _status.contains('Couldn\'t identify'))
            PrimaryButton(
              label: _detectedUrdu.isNotEmpty ? 'Scan next note' : 'Retry',
              onPressed: () {
                setState(() {
                  _status = 'captured frame\nCNN · TensorFlow Lite';
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
