import 'package:flutter/material.dart';
import '../widgets/gesture_bar.dart';

class CameraBaseScreen extends StatelessWidget {
  final String title;
  final String statusText;
  final Widget? overlayWidget;
  final Widget? bottomWidget;
  final Widget? cameraPreviewWidget;
  final Color statusTextColor;

  const CameraBaseScreen({
    super.key,
    required this.title,
    required this.statusText,
    this.overlayWidget,
    this.bottomWidget,
    this.cameraPreviewWidget,
    this.statusTextColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.primaryColor.withAlpha(26),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.primaryColor.withAlpha(77), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.volume_up_rounded, color: theme.primaryColor, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'Voice On',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B), // Modern Slate-900 for simulated viewfinder
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF475569), width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(21),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Live camera preview (when available)
                      if (cameraPreviewWidget != null)
                        Positioned.fill(
                          child: cameraPreviewWidget!,
                        ),
                      // Subtly simulated camera grid / scanlines
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.03,
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                            ),
                            itemBuilder: (context, index) => Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white, width: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (statusText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusTextColor,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                              shadows: const [
                                Shadow(
                                  blurRadius: 8.0,
                                  color: Colors.black54,
                                  offset: Offset(0.0, 2.0),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ?overlayWidget,
                    ],
                  ),
                ),
              ),
            ),
            if (bottomWidget != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: bottomWidget!,
              ),
            const GestureBar(),
          ],
        ),
      ),
    );
  }
}
