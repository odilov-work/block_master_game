import 'dart:math';
import 'package:block_master_game/core/extensions.dart';
import 'package:flutter/material.dart';
import 'package:block_master_game/piece_generator.dart';
import 'package:block_master_game/widgets/game_grid.dart'; // For ClearAnimationType

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
  final ClearAnimationType animationType;

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
    this.animationType = ClearAnimationType.fade,
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

    double scale = 1.0;
    double opacity = 1.0;

    if (isClearing) {
      switch (animationType) {
        case ClearAnimationType.fade:
          // Simple fade out, slight scale up
          scale = 1.0 + (0.1 * progress);
          opacity = (1.0 - progress).clamp(0.0, 1.0);
          break;
        case ClearAnimationType.scale:
          // Shrink down
          scale = (1.0 - progress).clamp(0.0, 1.0);
          opacity = 1.0;
          break;
        case ClearAnimationType.explosion:
          // Expand and fade
          scale = 1.0 + (0.5 * progress);
          opacity = (1.0 - progress).clamp(0.0, 1.0);
          break;
      }

      canvas.translate(centerX, centerY);
      canvas.scale(scale);
      canvas.translate(-centerX, -centerY);
    }

    final rect = Rect.fromLTWH(
      x * cellSize + 2,
      y * cellSize + 2,
      cellSize - 4,
      cellSize - 4,
    );
    final rRect = RRect.fromRectAndRadius(rect, Radius.zero);

    // 1. Draw Shadow/Glow (Simplified)
    if (!isClearing) {
      // Static glow for normal blocks
      canvas.drawRRect(
        rRect.inflate(2),
        Paint()
          ..color = color.withOpacityX(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    } else {
      // Simplified glow for clearing blocks (no dynamic blur radius)
      if (opacity > 0.1) {
        canvas.drawRRect(
          rRect.inflate(4 * progress),
          Paint()
            ..color = color.withOpacityX(0.4 * opacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }
    }

    // 2. Draw Main Block Body
    final blockColor = color.withOpacityX(opacity);

    // Optimization: Skip gradient for clearing blocks if they are very transparent
    if (isClearing && opacity < 0.5) {
      canvas.drawRRect(rRect, Paint()..color = blockColor);
    } else {
      final gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          blockColor,
          Color.lerp(blockColor, Colors.black, 0.25)!.withOpacityX(opacity),
        ],
      );
      canvas.drawRRect(rRect, Paint()..shader = gradient.createShader(rect));
    }

    // 3. Top Highlight (Reflection)
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
      Paint()
        ..color = Colors.white.withOpacityX(isClearing ? 0.4 * opacity : 0.35),
    );

    // 4. Border
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = color.withOpacityX(isClearing ? 0.8 * opacity : 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // 5. Special Effects (Explosion Ring)
    if (isClearing && animationType == ClearAnimationType.explosion) {
      canvas.drawCircle(
        Offset(centerX, centerY),
        (cellSize / 1.8) * scale,
        Paint()
          ..color = color.withOpacityX(opacity * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // 6. White Flash Overlay (Instead of saveLayer)
    if (isClearing) {
      canvas.drawRRect(
        rRect,
        Paint()..color = Colors.white.withOpacityX(0.3 * opacity),
      );
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
