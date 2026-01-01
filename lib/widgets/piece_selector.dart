import 'package:flutter/material.dart';
import 'package:block_master_game/piece_generator.dart';
import 'package:block_master_game/widgets/piece_painter.dart';

class PieceSelector extends StatelessWidget {
  final List<PieceShape?> pieces;
  final Function(int, Offset) onDragStart;
  final Function(Offset) onDragUpdate;
  final VoidCallback onDragEnd;
  final int? draggingIndex;

  const PieceSelector({
    super.key,
    required this.pieces,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    this.draggingIndex,
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

  const _PieceSlot({
    required this.piece,
    required this.index,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.isDragging,
  });

  @override
  Widget build(BuildContext context) {
    // 1-O'ZGARISH: Bosish maydoni o'lchamini kattalashtiramiz (masalan 120.0)
    // Avval kichikroq edi, bu barmoq sig'ishini osonlashtiradi.
    const double slotSize = 120.0;

    return GestureDetector(
      // 2-O'ZGARISH: Bu juda muhim!
      // Bu foydalanuvchi shaklning aniq chizig'iga emas, balki
      // atrofidagi bo'sh katakka bossa ham ushlaydi.
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
        // 3-O'ZGARISH: Shaffof rang. Ba'zan rangsiz Container
        // touch hodisalarini o'tkazib yuborishi mumkin.
        color: Colors.transparent,
        child: (piece != null && !isDragging)
            ? Center(child: _buildPiecePreview(piece!))
            : null,
      ),
    );
  }

  Widget _buildPiecePreview(PieceShape piece) {
    // Preview o'lchami o'zgarmaydi, faqat konteyner kattalashdi
    final cellSize = GameConstants.cellSize * GameConstants.piecePreviewScale;
    final width = piece.width * cellSize;
    final height = piece.height * cellSize;

    return IgnorePointer(
      child: CustomPaint(
        size: Size(width, height),
        painter: PiecePainter(piece: piece, cellSize: cellSize),
      ),
    );
  }
}
