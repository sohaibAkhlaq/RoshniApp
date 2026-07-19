import 'package:flutter/material.dart';

class GestureGuideScreen extends StatelessWidget {
  const GestureGuideScreen({super.key});

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
              'Interactive shortcuts guide',
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
          ),
          _buildGestureItem(
            context,
            '2',
            'DOUBLE TAP = REPEAT',
            'Double tap quickly to repeat the last voice read-out result.',
            Icons.history_toggle_off_rounded,
          ),
          _buildGestureItem(
            context,
            '3',
            'SWIPE RIGHT = GO BACK',
            'Swipe right from the left screen boundary to navigate back to the previous screen.',
            Icons.swipe_right_rounded,
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
  ) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
    );
  }
}
