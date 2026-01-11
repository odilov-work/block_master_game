import 'dart:math';
import 'package:block_master_game/core/extensions.dart';
import 'package:flutter/material.dart';
import 'package:block_master_game/piece_generator.dart';
import 'package:block_master_game/widgets/game_grid.dart'; // For ClearAnimationType
import 'package:block_master_game/styles/block_style.dart';

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
  final BlockStyle blockStyle;

  late final BlockStylePainter _stylePainter;

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
    this.blockStyle = BlockStyle.neon,
  }) {
    _stylePainter = getBlockStylePainter(blockStyle);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid lines using style painter
    _stylePainter.drawGridLines(
      canvas,
      size,
      cellSize,
      GameConstants.gridSize,
      const Color(0xFF6C5CE7),
    );

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

    // --- Faqat yaroqli joy bo'lsa chiziladi ---
    if (hoverPosition != null && hoverPiece != null && canPlace) {
      for (var cell in hoverPiece!.cells) {
        int x = hoverPosition!.dx.toInt() + cell.dx.toInt();
        int y = hoverPosition!.dy.toInt() + cell.dy.toInt();

        if (x >= 0 &&
            x < GameConstants.gridSize &&
            y >= 0 &&
            y < GameConstants.gridSize) {
          final rect = Rect.fromLTWH(
            x * cellSize + 3,
            y * cellSize + 3,
            cellSize - 6,
            cellSize - 6,
          );
          _stylePainter.drawPreviewBlock(canvas, rect, canPlace);
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
          scale = 1.0 + (0.1 * progress);
          opacity = (1.0 - progress).clamp(0.0, 1.0);
          break;
        case ClearAnimationType.scale:
          scale = (1.0 - progress).clamp(0.0, 1.0);
          opacity = 1.0;
          break;
        case ClearAnimationType.explosion:
          scale = 1.0 + (0.5 * progress);
          opacity = (1.0 - progress).clamp(0.0, 1.0);
          break;
      }

      canvas.translate(centerX, centerY);
      canvas.scale(scale);
      canvas.translate(-centerX, -centerY);
    }

    final rect = Rect.fromLTWH(
      x * cellSize + 3,
      y * cellSize + 3,
      cellSize - 6,
      cellSize - 6,
    );

    // Use BlockStylePainter for drawing
    _stylePainter.drawBlock(
      canvas,
      rect,
      color,
      isClearing: isClearing,
      opacity: opacity,
    );

    // Special Effects for clearing (Explosion Ring)
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

    // White Flash Overlay for clearing
    if (isClearing) {
      final rRect = RRect.fromRectAndRadius(rect, Radius.zero);
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

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return true;
  }
}
