import 'package:flutter/material.dart';

class GestureBar extends StatelessWidget {
  const GestureBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: "Gesture guide: Tap once to scan or confirm, double tap to repeat last result, swipe right to go back",
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF111827), // Deep charcoal/black for highest contrast
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(38),
              blurRadius: 16,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD97706), width: 1.5),
              ),
              child: const Icon(Icons.volume_up, color: Color(0xFFEAB308), size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGestureIndicator("Tap", "Scan"),
                  _buildDivider(),
                  _buildGestureIndicator("Double", "Repeat"),
                  _buildDivider(),
                  _buildGestureIndicator("Swipe", "Back"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1.5,
      height: 32,
      color: const Color(0xFF374151),
    );
  }

  Widget _buildGestureIndicator(String gesture, String action) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          gesture,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9CA3AF), // Muted grey
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          action,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
