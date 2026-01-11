import 'package:block_master_game/core/extensions.dart';
import 'package:flutter/material.dart';
import 'package:block_master_game/piece_generator.dart';
import 'package:block_master_game/styles/block_style.dart';

class PiecePainter extends CustomPainter {
  final PieceShape piece;
  final double cellSize;
  final bool isValid;
  final BlockStyle blockStyle;

  late final BlockStylePainter _stylePainter;

  PiecePainter({
    required this.piece,
    required this.cellSize,
    this.isValid = true,
    this.blockStyle = BlockStyle.neon,
  }) {
    _stylePainter = getBlockStylePainter(blockStyle);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var cell in piece.cells) {
      final rect = Rect.fromLTWH(
        cell.dx * cellSize + 3,
        cell.dy * cellSize + 3,
        cellSize - 6,
        cellSize - 6,
      );

      final color = isValid ? piece.color : piece.color.withOpacityX(0.5);

      _stylePainter.drawBlock(
        canvas,
        rect,
        color,
        opacity: isValid ? 1.0 : 0.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PiecePainter oldDelegate) {
    return oldDelegate.piece != piece ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.isValid != isValid ||
        oldDelegate.blockStyle != blockStyle;
  }
}
