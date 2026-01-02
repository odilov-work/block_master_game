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
      final rect = Rect.fromLTWH(
        cell.dx * cellSize + 2,
        cell.dy * cellSize + 2,
        cellSize - 4,
        cellSize - 4,
      );
      final rRect = RRect.fromRectAndRadius(rect, Radius.zero);

      final color = isValid ? piece.color : piece.color.withOpacityX(0.5);

      // Neon outer glow
      canvas.drawRRect(
        rRect.inflate(4),
        Paint()
          ..color = color.withOpacityX(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // Neon inner glow
      canvas.drawRRect(
        rRect,
        Paint()
          ..color = color.withOpacityX(0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Main block with gradient
      final gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color, Color.lerp(color, Colors.black, 0.3)!],
      );
      canvas.drawRRect(rRect, Paint()..shader = gradient.createShader(rect));

      // Top highlight
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            cell.dx * cellSize + 4,
            cell.dy * cellSize + 4,
            cellSize - 12,
            cellSize / 4,
          ),
          Radius.zero,
        ),
        Paint()..color = Colors.white.withOpacityX(0.4),
      );

      // Neon border
      canvas.drawRRect(
        rRect,
        Paint()
          ..color = color.withOpacityX(0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
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
