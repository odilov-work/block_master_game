import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:block_master_game/piece_generator.dart';
import 'package:block_master_game/widgets/piece_painter.dart';
import 'package:block_master_game/styles/block_style.dart';

class PieceSelector extends StatelessWidget {
  final List<PieceShape?> pieces;
  final Function(int, Offset) onDragStart;
  final Function(Offset) onDragUpdate;
  final VoidCallback onDragEnd;
  final int? draggingIndex;
  final BlockStyle blockStyle;

  const PieceSelector({
    super.key,
    required this.pieces,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    this.draggingIndex,
    this.blockStyle = BlockStyle.neon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: const EdgeInsets.all(0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return _PieceSlot(
            piece: pieces[index],
            index: index,
            onDragStart: onDragStart,
            onDragUpdate: onDragUpdate,
            onDragEnd: onDragEnd,
            isDragging: draggingIndex == index,
            blockStyle: blockStyle,
          );
        }),
      ),
    );
  }
}

class _PieceSlot extends StatelessWidget {
  final PieceShape? piece;
  final int index;
  final Function(int, Offset) onDragStart;
  final Function(Offset) onDragUpdate;
  final VoidCallback onDragEnd;
  final bool isDragging;
  final BlockStyle blockStyle;

  const _PieceSlot({
    required this.piece,
    required this.index,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.isDragging,
    required this.blockStyle,
  });

  @override
  Widget build(BuildContext context) {
    final double slotSize = 120.w;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,

      onPanStart: (details) {
        if (piece != null) {
          onDragStart(index, details.globalPosition);
        }
      },
      onPanUpdate: (details) {
        onDragUpdate(details.globalPosition);
      },
      onPanEnd: (_) {
        onDragEnd();
      },
      onPanCancel: () {
        onDragEnd();
      },
      child: Container(
        width: slotSize,
        height: slotSize,
        color: Colors.transparent,
        child: (piece != null && !isDragging)
            ? Center(child: _buildPiecePreview(piece!))
            : null,
      ),
    );
  }

  Widget _buildPiecePreview(PieceShape piece) {
    final cellSize = 35.w * GameConstants.piecePreviewScale;
    final width = piece.width * cellSize;
    final height = piece.height * cellSize;

    return IgnorePointer(
      child: CustomPaint(
        size: Size(width, height),
        painter: PiecePainter(
          piece: piece,
          cellSize: cellSize,
          blockStyle: blockStyle,
        ),
      ),
    );
  }
}
