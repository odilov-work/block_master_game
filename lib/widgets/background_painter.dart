import 'package:block_master_game/core/extensions.dart';
import 'package:flutter/material.dart';

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Deep dark background with subtle neon gradient
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 1.5,
        colors: [
          const Color(0xFF1A0A2E), // Deep purple
          const Color(0xFF0D1117), // Almost black
          const Color(0xFF0A0A0F), // Pure dark
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Subtle neon grid pattern in background
    final gridPaint = Paint()
      ..color = const Color(0xFF6C5CE7).withOpacityX(0.03)
      ..strokeWidth = 1;

    const gridSpacing = 40.0;
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Subtle neon glow at top
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 150),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF6C5CE7).withOpacityX(0.1),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, 150)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
