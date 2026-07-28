import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class GestureGuideScreen extends StatefulWidget {
  const GestureGuideScreen({super.key});

  @override
  State<GestureGuideScreen> createState() => _GestureGuideScreenState();
}

class _GestureGuideScreenState extends State<GestureGuideScreen> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("ur-PK");
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  void _speakInstruction(String urduText) async {
    await _tts.stop();
    await _tts.speak(urduText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gesture and Guide'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 20.0, left: 4.0),
            child: Text(
              'Interactive shortcuts guide (Tap to listen)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
          _buildGestureItem(
            context,
            '1',
            'TAP = SCAN / CONFIRM',
            'Single press anywhere on the screen to capture a frame or confirm selection.',
            Icons.touch_app_rounded,
            'سکرین پر ایک دفعہ دبانے سے تصویر لی جاتی ہے یا انتخاب کی تصدیق ہوتی ہے',
          ),
          _buildGestureItem(
            context,
            '2',
            'DOUBLE TAP = REPEAT',
            'Double tap quickly to repeat the last voice read-out result.',
            Icons.history_toggle_off_rounded,
            'سکرین پر جلدی سے دو دفعہ دبانے سے آخری پڑھی گئی آواز دہرائی جاتی ہے',
          ),
          _buildGestureItem(
            context,
            '3',
            'SWIPE RIGHT = GO BACK',
            'Swipe right from the left screen boundary to navigate back to the previous screen.',
            Icons.swipe_right_rounded,
            'سکرین پر دائیں طرف سوائپ کرنے سے آپ پچھلی سکرین پر واپس جا سکتے ہیں',
          ),
        ],
      ),
    );
  }

  Widget _buildGestureItem(
    BuildContext context,
    String number,
    String gestureTitle,
    String description,
    IconData gestureIcon,
    String urduSpokenText,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _speakInstruction(urduSpokenText),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.primaryColor,
                        theme.primaryColor.withAlpha(204),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withAlpha(51),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    gestureIcon,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gestureTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF4B5563),
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
