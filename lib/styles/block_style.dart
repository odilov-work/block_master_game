import 'package:block_master_game/core/extensions.dart';
import 'package:flutter/material.dart';

/// Block va grid uchun turli vizual stillar
enum BlockStyle {
  neon, // Neon glow effekti
  outline, // Faqat kontur (stroke)
  flat, // Oddiy flat dizayn
  circle, // Dumaloq neon stil
  dark, // Qorong'u monoxrom stil
  retro, // Retro piksel uslubi
}

/// Block Style nomi va tavsifi
extension BlockStyleExtension on BlockStyle {
  String get displayName {
    switch (this) {
      case BlockStyle.neon:
        return 'Neon';
      case BlockStyle.outline:
        return 'Outline';
      case BlockStyle.flat:
        return 'Flat';
      case BlockStyle.circle:
        return 'Circle';
      case BlockStyle.dark:
        return 'Dark';
      case BlockStyle.retro:
        return 'Retro';
    }
  }

  String get description {
    switch (this) {
      case BlockStyle.neon:
        return 'Neon glow effekti bilan';
      case BlockStyle.outline:
        return 'Faqat konturli';
      case BlockStyle.flat:
        return 'Oddiy flat dizayn';
      case BlockStyle.circle:
        return 'Dumaloq neon stil';
      case BlockStyle.dark:
        return 'Qorong\'u monoxrom stil';
      case BlockStyle.retro:
        return 'Retro piksel uslubi';
    }
  }
}

/// Block chizish uchun abstract class
abstract class BlockStylePainter {
  void drawBlock(
    Canvas canvas,
    Rect rect,
    Color color, {
    bool isClearing = false,
    double opacity = 1.0,
  });

  void drawPreviewBlock(Canvas canvas, Rect rect, bool valid);

  void drawGridLines(
    Canvas canvas,
    Size size,
    double cellSize,
    int gridSize,
    Color lineColor,
  );
}

/// Neon Style Painter - Glow effekti bilan
class NeonStylePainter extends BlockStylePainter {
  @override
  void drawBlock(
    Canvas canvas,
    Rect rect,
    Color color, {
    bool isClearing = false,
    double opacity = 1.0,
  }) {
    final rRect = RRect.fromRectAndRadius(rect, Radius.zero);
    final blockColor = color.withOpacityX(opacity);

    // 1. Outer Glow
    canvas.drawRRect(
      rRect.inflate(4),
      Paint()
        ..color = blockColor.withOpacityX(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // 2. Inner Glow
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = blockColor.withOpacityX(0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // 3. Main Block with gradient
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [blockColor, Color.lerp(blockColor, Colors.black, 0.3)!],
    );
    canvas.drawRRect(rRect, Paint()..shader = gradient.createShader(rect));

    // 4. Top highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rect.left + 2,
          rect.top + 2,
          rect.width - 6,
          rect.height / 4,
        ),
        Radius.zero,
      ),
      Paint()..color = Colors.white.withOpacityX(0.4 * opacity),
    );

    // 5. Neon Border
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = blockColor.withOpacityX(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  void drawPreviewBlock(Canvas canvas, Rect rect, bool valid) {
    final rRect = RRect.fromRectAndRadius(rect, Radius.zero);
    const color = Color(0xFF00FFFF);

    // Neon glow for preview
    canvas.drawRRect(
      rRect.inflate(2),
      Paint()
        ..color = color.withOpacityX(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawRRect(rRect, Paint()..color = color.withOpacityX(0.2));

    canvas.drawRRect(
      rRect,
      Paint()
        ..color = color.withOpacityX(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  void drawGridLines(
    Canvas canvas,
    Size size,
    double cellSize,
    int gridSize,
    Color lineColor,
  ) {
    final glowPaint = Paint()
      ..color = lineColor.withOpacityX(0.15)
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final linePaint = Paint()
      ..color = lineColor.withOpacityX(0.4)
      ..strokeWidth = 1;

    for (int i = 0; i <= gridSize; i++) {
      final pos = i * cellSize;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), glowPaint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), glowPaint);
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), linePaint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), linePaint);
    }
  }
}

/// Outline Style Painter - Faqat kontur
class OutlineStylePainter extends BlockStylePainter {
  @override
  void drawBlock(
    Canvas canvas,
    Rect rect,
    Color color, {
    bool isClearing = false,
    double opacity = 1.0,
  }) {
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    final blockColor = color.withOpacityX(opacity);

    // 1. Fill with very transparent color
    canvas.drawRRect(rRect, Paint()..color = blockColor.withOpacityX(0.15));

    // 2. Thick border
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = blockColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // 3. Inner border for depth
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(3), const Radius.circular(2)),
      Paint()
        ..color = blockColor.withOpacityX(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  void drawPreviewBlock(Canvas canvas, Rect rect, bool valid) {
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    const color = Color(0xFF00FFFF);

    canvas.drawRRect(
      rRect,
      Paint()
        ..color = color.withOpacityX(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Dashed inner effect
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(4), const Radius.circular(2)),
      Paint()
        ..color = color.withOpacityX(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  void drawGridLines(
    Canvas canvas,
    Size size,
    double cellSize,
    int gridSize,
    Color lineColor,
  ) {
    final linePaint = Paint()
      ..color = lineColor.withOpacityX(0.3)
      ..strokeWidth = 1;

    for (int i = 0; i <= gridSize; i++) {
      final pos = i * cellSize;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), linePaint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), linePaint);
    }
  }
}

/// Flat Style Painter - Oddiy flat dizayn
class FlatStylePainter extends BlockStylePainter {
  @override
  void drawBlock(
    Canvas canvas,
    Rect rect,
    Color color, {
    bool isClearing = false,
    double opacity = 1.0,
  }) {
    final rRect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.width * 0.2),
    );
    final blockColor = color.withOpacityX(opacity);

    // 1. Simple solid fill
    canvas.drawRRect(rRect, Paint()..color = blockColor);

    // 2. Subtle border (darker shade)
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = Color.lerp(blockColor, Colors.black, 0.3)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  void drawPreviewBlock(Canvas canvas, Rect rect, bool valid) {
    final rRect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.width * 0.2),
    );
    const color = Color(0xFF00FFFF);

    canvas.drawRRect(rRect, Paint()..color = color.withOpacityX(0.3));

    canvas.drawRRect(
      rRect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  void drawGridLines(
    Canvas canvas,
    Size size,
    double cellSize,
    int gridSize,
    Color lineColor,
  ) {
    final linePaint = Paint()
      ..color = lineColor.withOpacityX(0.2)
      ..strokeWidth = 1;

    for (int i = 0; i <= gridSize; i++) {
      final pos = i * cellSize;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), linePaint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), linePaint);
    }
  }
}

/// Circle Style Painter - Dumaloq neon stil
class CircleStylePainter extends BlockStylePainter {
  @override
  void drawBlock(
    Canvas canvas,
    Rect rect,
    Color color, {
    bool isClearing = false,
    double opacity = 1.0,
  }) {
    final center = rect.center;
    final radius = rect.width / 2 - 1;
    final blockColor = color.withOpacityX(opacity);

    // 1. Outer Neon Glow
    canvas.drawCircle(
      center,
      radius + 4,
      Paint()
        ..color = blockColor.withOpacityX(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // 2. Inner Glow
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = blockColor.withOpacityX(0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // 3. Main Circle with radial gradient
    final gradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [
        Color.lerp(blockColor, Colors.white, 0.3)!,
        blockColor,
        Color.lerp(blockColor, Colors.black, 0.3)!,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..shader = gradient.createShader(rect),
    );

    // 4. Top-left highlight (shine effect)
    canvas.drawCircle(
      Offset(center.dx - radius * 0.35, center.dy - radius * 0.35),
      radius * 0.3,
      Paint()..color = Colors.white.withOpacityX(0.5 * opacity),
    );

    // 5. Neon Border
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = blockColor.withOpacityX(0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  void drawPreviewBlock(Canvas canvas, Rect rect, bool valid) {
    final center = rect.center;
    final radius = rect.width / 2 - 1;
    const color = Color(0xFF00FFFF);

    // Neon glow
    canvas.drawCircle(
      center,
      radius + 2,
      Paint()
        ..color = color.withOpacityX(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Fill
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = color.withOpacityX(0.25),
    );

    // Border
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withOpacityX(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  void drawGridLines(
    Canvas canvas,
    Size size,
    double cellSize,
    int gridSize,
    Color lineColor,
  ) {
    final glowPaint = Paint()
      ..color = lineColor.withOpacityX(0.15)
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final linePaint = Paint()
      ..color = lineColor.withOpacityX(0.3)
      ..strokeWidth = 1;

    for (int i = 0; i <= gridSize; i++) {
      final pos = i * cellSize;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), glowPaint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), glowPaint);
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), linePaint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), linePaint);
    }
  }
}

/// Dark Style Painter - Qorong'u monoxrom stil (barcha bloklar bir xil qorong'u rangda)
class DarkStylePainter extends BlockStylePainter {
  // Monoxrom qorong'u rang
  static const Color _darkColor = Color(0xFF3D3D3D);
  static const Color _darkHighlight = Color(0xFF5A5A5A);
  static const Color _darkShadow = Color(0xFF1A1A1A);

  @override
  void drawBlock(
    Canvas canvas,
    Rect rect,
    Color color, { // color parametri e'tiborga olinmaydi
    bool isClearing = false,
    double opacity = 1.0,
  }) {
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(2));

    // 1. Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.translate(1, 1), const Radius.circular(2)),
      Paint()..color = _darkShadow.withOpacityX(0.5 * opacity),
    );

    // 2. Main block - solid dark
    canvas.drawRRect(rRect, Paint()..color = _darkColor.withOpacityX(opacity));

    // 3. Top-left highlight edge
    final highlightPath = Path()
      ..moveTo(rect.left + 2, rect.bottom - 2)
      ..lineTo(rect.left + 2, rect.top + 2)
      ..lineTo(rect.right - 2, rect.top + 2);
    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = _darkHighlight.withOpacityX(0.6 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // 4. Bottom-right shadow edge
    final shadowPath = Path()
      ..moveTo(rect.right - 2, rect.top + 2)
      ..lineTo(rect.right - 2, rect.bottom - 2)
      ..lineTo(rect.left + 2, rect.bottom - 2);
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = _darkShadow.withOpacityX(0.8 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // 5. Thin border
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = _darkShadow.withOpacityX(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  @override
  void drawPreviewBlock(Canvas canvas, Rect rect, bool valid) {
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(2));
    const previewColor = Color(0xFF6C6C6C);

    canvas.drawRRect(rRect, Paint()..color = previewColor.withOpacityX(0.4));
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = previewColor.withOpacityX(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  void drawGridLines(
    Canvas canvas,
    Size size,
    double cellSize,
    int gridSize,
    Color lineColor, // lineColor e'tiborga olinmaydi
  ) {
    final linePaint = Paint()
      ..color = const Color(0xFF2A2A2A).withOpacityX(0.6)
      ..strokeWidth = 1;

    for (int i = 0; i <= gridSize; i++) {
      final pos = i * cellSize;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), linePaint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), linePaint);
    }
  }
}

/// Retro Style Painter - Piksel uslubi, nostalgia
class RetroStylePainter extends BlockStylePainter {
  @override
  void drawBlock(
    Canvas canvas,
    Rect rect,
    Color color, {
    bool isClearing = false,
    double opacity = 1.0,
  }) {
    final blockColor = color.withOpacityX(opacity);

    // Yorqinroq va tiniqroq ranglar (kamroq qora aralashtirish)
    final topColor = Color.lerp(blockColor, Colors.white, 0.4)!;
    final leftColor = Color.lerp(blockColor, Colors.white, 0.2)!;
    final rightColor = Color.lerp(
      blockColor,
      Colors.black,
      0.1,
    )!; // Juda oz qora
    final bottomColor = Color.lerp(
      blockColor,
      Colors.black,
      0.25,
    )!; // Ozroq qora

    // Relyef chuqurligi (sezilarli bo'lishi uchun)
    final double depth = rect.width * 0.25; // ~25% o'lcham

    // 1. Top Trapezoid
    final topPath = Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right - depth, rect.top + depth)
      ..lineTo(rect.left + depth, rect.top + depth)
      ..close();
    canvas.drawPath(topPath, Paint()..color = topColor);

    // 2. Left Trapezoid
    final leftPath = Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left + depth, rect.bottom - depth)
      ..lineTo(rect.left + depth, rect.top + depth)
      ..close();
    canvas.drawPath(leftPath, Paint()..color = leftColor);

    // 3. Right Trapezoid
    final rightPath = Path()
      ..moveTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.right - depth, rect.bottom - depth)
      ..lineTo(rect.right - depth, rect.top + depth)
      ..close();
    canvas.drawPath(rightPath, Paint()..color = rightColor);

    // 4. Bottom Trapezoid
    final bottomPath = Path()
      ..moveTo(rect.left, rect.bottom)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.right - depth, rect.bottom - depth)
      ..lineTo(rect.left + depth, rect.bottom - depth)
      ..close();
    canvas.drawPath(bottomPath, Paint()..color = bottomColor);

    // 5. Center Face (Flat top)
    final centerRect = Rect.fromLTRB(
      rect.left + depth,
      rect.top + depth,
      rect.right - depth,
      rect.bottom - depth,
    );
    canvas.drawRect(centerRect, Paint()..color = blockColor);
  }

  @override
  void drawPreviewBlock(Canvas canvas, Rect rect, bool valid) {
    // Preview uchun ham shunga o'xshash lekin soddaroq stil
    const color = Color(0xFF81ECEC);
    final double depth = rect.width * 0.20;

    // Faqat kontur va yengil to'ldirish
    canvas.drawRect(rect, Paint()..color = color.withOpacityX(0.2));

    // 3D ramka chizish
    final paint = Paint()
      ..color = color.withOpacityX(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(rect, paint);

    // Ichki to'rtburchak (frustum usti)
    final innerRect = Rect.fromLTRB(
      rect.left + depth,
      rect.top + depth,
      rect.right - depth,
      rect.bottom - depth,
    );
    canvas.drawRect(innerRect, paint);

    // Burchaklarni ulash
    canvas.drawLine(rect.topLeft, innerRect.topLeft, paint);
    canvas.drawLine(rect.topRight, innerRect.topRight, paint);
    canvas.drawLine(rect.bottomLeft, innerRect.bottomLeft, paint);
    canvas.drawLine(rect.bottomRight, innerRect.bottomRight, paint);
  }

  @override
  void drawGridLines(
    Canvas canvas,
    Size size,
    double cellSize,
    int gridSize,
    Color lineColor,
  ) {
    final linePaint = Paint()
      ..color = lineColor.withOpacityX(0.2)
      ..strokeWidth = 1;

    for (int i = 0; i <= gridSize; i++) {
      final pos = i * cellSize;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), linePaint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), linePaint);
    }
  }
}

/// Factory method to get painter for a style
BlockStylePainter getBlockStylePainter(BlockStyle style) {
  switch (style) {
    case BlockStyle.neon:
      return NeonStylePainter();
    case BlockStyle.outline:
      return OutlineStylePainter();
    case BlockStyle.flat:
      return FlatStylePainter();
    case BlockStyle.circle:
      return CircleStylePainter();
    case BlockStyle.dark:
      return DarkStylePainter();
    case BlockStyle.retro:
      return RetroStylePainter();
  }
}
