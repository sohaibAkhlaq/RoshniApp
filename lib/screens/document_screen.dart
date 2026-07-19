import 'package:flutter/material.dart';
import 'camera_base_screen.dart';
import '../widgets/primary_button.dart';

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

class _DocumentScreenContentState extends State<_DocumentScreenContent> {
  String _status = 'Align all 4 corners of the page\nMove camera up slightly';
  bool _hasResult = false;
  List<Map<String, String>> _receiptItems = [];
  String _totalPrice = '';
  Color _statusColor = Colors.white;

  void _simulateReadable() {
    setState(() {
      _status = '';
      _hasResult = true;
      _receiptItems = [
        {'name': 'Doodh (Milk)', 'price': '150 rupay'},
        {'name': 'Cheeni (Sugar)', 'price': '80 rupay'},
      ];
      _totalPrice = '230 rupay';
      _statusColor = Colors.white;
    });
  }

  void _simulateNotVisible() {
    setState(() {
      _status = "Document not fully visible\n\nPlease include all edges of the page";
      _hasResult = false;
      _receiptItems = [];
      _totalPrice = '';
      _statusColor = const Color(0xFFEF4444);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CameraBaseScreen(
      title: 'Document Reader',
      statusText: _status,
      statusTextColor: _statusColor,
      overlayWidget: _hasResult
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE0F2FE), // Light blue
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF0284C7), size: 24),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Document Detected',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Simulated receipt item lines
                    ..._receiptItems.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item['name']!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              Text(
                                item['price']!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 10),
                    Divider(color: Colors.grey.shade200, thickness: 1.5),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Text(
                          _totalPrice,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Reading line by line...',
                      style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD97706),
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
          if (_status.contains('Align'))
            PrimaryButton(
              label: 'Continue',
              onPressed: () {
                setState(() {
                  _status = 'Reading document...\nTesseract OCR + OpenCV edge detection';
                });
              },
            ),
          if (_status.contains('Reading document'))
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Simulate readable',
                    onPressed: _simulateReadable,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton(
                    label: 'Simulate not visible',
                    onPressed: _simulateNotVisible,
                  ),
                ),
              ],
            ),
          if (_hasResult || _status.contains('Document not fully'))
            PrimaryButton(
              label: _hasResult ? 'Scan another document' : 'Retry',
              onPressed: () {
                setState(() {
                  _status = 'Reading document...\nTesseract OCR + OpenCV edge detection';
                  _hasResult = false;
                  _receiptItems = [];
                  _totalPrice = '';
                  _statusColor = Colors.white;
                });
              },
            ),
        ],
      ),
    );
  }
}
