import 'package:block_master_game/core/extensions.dart';
import 'package:block_master_game/providers/game_provider.dart';
import 'package:block_master_game/styles/block_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class StyleSelectorDialog extends StatelessWidget {
  const StyleSelectorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final currentStyle = gameState.blockStyle;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E).withOpacityX(0.95),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: const Color(0xFF6C5CE7).withOpacityX(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C5CE7).withOpacityX(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'BLOCK STYLE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            SizedBox(height: 20.h),

            // Style Grid (3 ustun, 6 stil)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10.w,
                crossAxisSpacing: 10.w,
                childAspectRatio: 0.85,
              ),
              itemCount: BlockStyle.values.length,
              itemBuilder: (context, index) {
                final style = BlockStyle.values[index];
                final isSelected = style == currentStyle;

                return _StylePreviewItem(
                  style: style,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    gameState.setBlockStyle(style);
                  },
                );
              },
            ),

            SizedBox(height: 20.h),

            // Close Button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 12.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFF00FFFF)],
                  ),
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Text(
                  'DONE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StylePreviewItem extends StatelessWidget {
  final BlockStyle style;
  final bool isSelected;
  final VoidCallback onTap;

  const _StylePreviewItem({
    required this.style,
    required this.isSelected,
    required this.onTap,
  });

  // Yorqin neon ranglar
  static const List<Color> _previewColors = [
    Color(0xFF00FFFF), // Cyan
    Color(0xFFFF00FF), // Magenta
    Color(0xFF00FF00), // Green
    Color(0xFFFFFF00), // Yellow
    Color(0xFFFF6600), // Orange
    Color(0xFF6C5CE7), // Purple
  ];

  // 4x4 grid uchun qaysi kataklar to'ldirilgan
  // 1 = to'ldirilgan, 0 = bo'sh
  static const List<List<int>> _gridPattern = [
    [1, 1, 0, 1],
    [0, 1, 1, 1],
    [1, 1, 1, 0],
    [1, 0, 1, 1],
  ];

  // Har bir to'ldirilgan katak uchun rang indeksi
  static const List<List<int>> _colorPattern = [
    [0, 0, -1, 1],
    [-1, 2, 2, 1],
    [3, 3, 2, -1],
    [4, -1, 5, 5],
  ];

  @override
  Widget build(BuildContext context) {
    final cellSize = 14.w;
    final gridSize = cellSize * 4;
    final stylePainter = getBlockStylePainter(style);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6C5CE7).withOpacityX(0.3)
              : const Color(0xFF16213E).withOpacityX(0.8),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00FFFF)
                : const Color(0xFF6C5CE7).withOpacityX(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00FFFF).withOpacityX(0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 4x4 Mini Grid Preview
            Container(
              width: gridSize,
              height: gridSize,
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(4.r),
                border: Border.all(
                  color: const Color(0xFF6C5CE7).withOpacityX(0.3),
                  width: 1,
                ),
              ),
              child: CustomPaint(
                size: Size(gridSize, gridSize),
                painter: _MiniGridPainter(
                  stylePainter: stylePainter,
                  cellSize: cellSize,
                  gridPattern: _gridPattern,
                  colorPattern: _colorPattern,
                  colors: _previewColors,
                ),
              ),
            ),

            // SizedBox(height: 10.h),

            // Style Name
            // Text(
            //   style.displayName.toUpperCase(),
            //   style: TextStyle(
            //     color: isSelected ? const Color(0xFF00FFFF) : Colors.white70,
            //     fontSize: 12.sp,
            //     fontWeight: FontWeight.bold,
            //     letterSpacing: 1,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

/// Mini grid chizish uchun CustomPainter
class _MiniGridPainter extends CustomPainter {
  final BlockStylePainter stylePainter;
  final double cellSize;
  final List<List<int>> gridPattern;
  final List<List<int>> colorPattern;
  final List<Color> colors;

  _MiniGridPainter({
    required this.stylePainter,
    required this.cellSize,
    required this.gridPattern,
    required this.colorPattern,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const gridLines = 4;

    // Grid lines
    final linePaint = Paint()
      ..color = const Color(0xFF6C5CE7).withOpacityX(0.2)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= gridLines; i++) {
      final pos = i * cellSize;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), linePaint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), linePaint);
    }

    // Blocks
    for (int y = 0; y < gridLines; y++) {
      for (int x = 0; x < gridLines; x++) {
        if (gridPattern[y][x] == 1) {
          final colorIndex = colorPattern[y][x];
          if (colorIndex >= 0 && colorIndex < colors.length) {
            final rect = Rect.fromLTWH(
              x * cellSize + 1.5,
              y * cellSize + 1.5,
              cellSize - 3,
              cellSize - 3,
            );
            stylePainter.drawBlock(canvas, rect, colors[colorIndex]);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniGridPainter oldDelegate) {
    return oldDelegate.stylePainter != stylePainter;
  }
}
