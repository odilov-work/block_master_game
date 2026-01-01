import 'package:block_master_game/core/extensions.dart';
import 'package:flutter/material.dart';
import 'package:block_master_game/piece_generator.dart';

class PiecePainter extends CustomPainter {
  final PieceShape piece;
  final double cellSize;
  final bool isValid;

  PiecePainter({
    required this.piece,
    required this.cellSize,
    this.isValid = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var cell in piece.cells) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cell.dx * cellSize + 2,
          cell.dy * cellSize + 2,
          cellSize - 4,
          cellSize - 4,
        ),
        Radius.zero,
      );

      canvas.drawRRect(
        rect.shift(const Offset(2, 2)),
        Paint()..color = Colors.black.withOpacityX(0.3),
      );

      final color = isValid ? piece.color : piece.color.withOpacityX(0.5);
      canvas.drawRRect(rect, Paint()..color = color);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            cell.dx * cellSize + 4,
            cell.dy * cellSize + 4,
            cellSize - 12,
            cellSize / 3,
          ),
          const Radius.circular(0),
        ),
        Paint()..color = Colors.white.withOpacityX(0.3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant PiecePainter oldDelegate) {
    return oldDelegate.piece != piece ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.isValid != isValid;
  }
}
