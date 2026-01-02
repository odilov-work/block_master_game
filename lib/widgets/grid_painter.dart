import 'dart:math';
import 'package:block_master_game/core/extensions.dart';
import 'package:flutter/material.dart';
import 'package:block_master_game/piece_generator.dart';

class GridPainter extends CustomPainter {
  final List<List<GridCell>> grid;
  final double cellSize;
  final Offset? hoverPosition;
  final PieceShape? hoverPiece;
  final bool canPlace;
  final Set<Point<int>> clearingCells;
  final bool isClearing;
  final double clearProgress;
  final Set<int> previewRows;
  final Set<int> previewCols;
  final Color? previewColor;

  GridPainter({
    required this.grid,
    required this.cellSize,
    this.hoverPosition,
    this.hoverPiece,
    this.canPlace = false,
    this.clearingCells = const {},
    this.isClearing = false,
    this.clearProgress = 0.0,
    this.previewRows = const {},
    this.previewCols = const {},
    this.previewColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Neon glow grid lines
    final glowPaint = Paint()
      ..color = const Color(0xFF6C5CE7).withOpacityX(0.15)
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final linePaint = Paint()
      ..color = const Color(0xFF6C5CE7).withOpacityX(0.4)
      ..strokeWidth = 1;

    for (int i = 0; i <= GameConstants.gridSize; i++) {
      final pos = i * cellSize;
      // Glow
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), glowPaint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), glowPaint);
      // Line
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), linePaint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), linePaint);
    }

    for (int y = 0; y < GameConstants.gridSize; y++) {
      for (int x = 0; x < GameConstants.gridSize; x++) {
        if (grid[y][x].occupied && grid[y][x].color != null) {
          bool isBeingCleared = clearingCells.contains(Point(x, y));
          _drawBlock(
            canvas,
            x,
            y,
            grid[y][x].color!,
            isClearing: isBeingCleared,
            progress: clearProgress,
          );
        }
      }
    }

    // Draw unified preview clears
    if ((previewRows.isNotEmpty || previewCols.isNotEmpty) &&
        previewColor != null) {
      _drawUnifiedPreview(
        canvas,
        size,
        previewRows,
        previewCols,
        previewColor!,
      );
    }

    // --- O'ZGARTIRILGAN QISM: Faqat yaroqli joy bo'lsa chiziladi ---
    if (hoverPosition != null && hoverPiece != null && canPlace) {
      for (var cell in hoverPiece!.cells) {
        int x = hoverPosition!.dx.toInt() + cell.dx.toInt();
        int y = hoverPosition!.dy.toInt() + cell.dy.toInt();

        if (x >= 0 &&
            x < GameConstants.gridSize &&
            y >= 0 &&
            y < GameConstants.gridSize) {
          _drawPreviewBlock(canvas, x, y, canPlace);
        }
      }
    }
  }

  void _drawBlock(
    Canvas canvas,
    int x,
    int y,
    Color color, {
    bool isClearing = false,
    double progress = 0.0,
  }) {
    final centerX = x * cellSize + cellSize / 2;
    final centerY = y * cellSize + cellSize / 2;

    canvas.save();

    if (isClearing) {
      final scale = 1.0 + (0.3 * progress);
      final opacity = 1.0 - progress;

      canvas.translate(centerX, centerY);
      canvas.scale(scale);
      canvas.translate(-centerX, -centerY);

      canvas.saveLayer(
        Rect.fromLTWH(
          x * cellSize - 10,
          y * cellSize - 10,
          cellSize + 20,
          cellSize + 20,
        ),
        Paint()..color = Colors.white.withOpacityX(opacity),
      );
    }

    final rect = Rect.fromLTWH(
      x * cellSize + 2,
      y * cellSize + 2,
      cellSize - 4,
      cellSize - 4,
    );
    final rRect = RRect.fromRectAndRadius(rect, Radius.zero);

    // Neon outer glow
    if (!isClearing) {
      canvas.drawRRect(
        rRect.inflate(3),
        Paint()
          ..color = color.withOpacityX(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    if (isClearing) {
      final glowIntensity = 8.0 + (12.0 * progress);
      final glowPaint = Paint()
        ..color = Colors.white.withOpacityX(0.9)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowIntensity);
      canvas.drawRRect(rRect, glowPaint);
    }

    final blockColor = isClearing
        ? Color.lerp(color, Colors.white, progress)!
        : color;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [blockColor, Color.lerp(blockColor, Colors.black, 0.25)!],
    );

    canvas.drawRRect(rRect, Paint()..shader = gradient.createShader(rect));

    // Top highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x * cellSize + 4,
          y * cellSize + 4,
          cellSize - 10,
          cellSize / 4,
        ),
        Radius.zero,
      ),
      Paint()..color = Colors.white.withOpacityX(isClearing ? 0.6 : 0.35),
    );

    // Neon border
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = color.withOpacityX(isClearing ? 0.9 : 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isClearing ? 2 : 1,
    );

    if (isClearing) {
      canvas.restore();
    }

    canvas.restore();
  }

  void _drawUnifiedPreview(
    Canvas canvas,
    Size size,
    Set<int> rows,
    Set<int> cols,
    Color color,
  ) {
    final path = Path();

    // Add rows
    for (int y in rows) {
      path.addRect(
        Rect.fromLTWH(0, y * cellSize + 2, size.width, cellSize - 4),
      );
    }

    // Add cols
    for (int x in cols) {
      path.addRect(
        Rect.fromLTWH(x * cellSize + 2, 0, cellSize - 4, size.height),
      );
    }

    // Draw fill
    canvas.drawPath(path, Paint()..color = color.withOpacityX(0.5));

    // Draw stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawPreviewBlock(Canvas canvas, int x, int y, bool valid) {
    if (!valid) {
      return;
    }

    final rect = Rect.fromLTWH(
      x * cellSize + 2,
      y * cellSize + 2,
      cellSize - 4,
      cellSize - 4,
    );
    final rRect = RRect.fromRectAndRadius(rect, Radius.zero);

    // Neon glow for preview
    canvas.drawRRect(
      rRect.inflate(2),
      Paint()
        ..color = const Color(0xFF00FFFF).withOpacityX(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawRRect(
      rRect,
      Paint()..color = const Color(0xFF00FFFF).withOpacityX(0.2),
    );

    canvas.drawRRect(
      rRect,
      Paint()
        ..color = const Color(0xFF00FFFF).withOpacityX(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return true;
  }
}
