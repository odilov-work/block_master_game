import 'dart:async';
import 'package:block_master_game/core/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:block_master_game/piece_generator.dart';
import 'package:block_master_game/providers/game_provider.dart';
import 'package:block_master_game/widgets/grid_painter.dart';

class GameGrid extends StatefulWidget {
  final List<List<GridCell>> grid;
  final double gridSize;
  final PieceShape? draggingPiece;
  final Offset? dragPosition;
  final Function(Offset?, Offset?, bool) onGridHover;
  final GameState gameState;

  const GameGrid({
    super.key,
    required this.grid,
    required this.gridSize,
    this.draggingPiece,
    this.dragPosition,
    required this.onGridHover,
    required this.gameState,
  });

  @override
  State<GameGrid> createState() => _GameGridState();
}

class _GameGridState extends State<GameGrid>
    with SingleTickerProviderStateMixin {
  final GlobalKey _gridKey = GlobalKey();
  late AnimationController _clearAnimationController;
  late Animation<double> _clearAnimation;

  Timer? _debounceTimer;
  Offset? _displayedSnappedPos;
  Offset? _pendingSnappedPos;

  @override
  void initState() {
    super.initState();
    _clearAnimationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _clearAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _clearAnimationController, curve: Curves.easeOut),
    );
    _clearAnimationController.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(GameGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.gameState.isClearing &&
        widget.gameState.clearingCells.isNotEmpty) {
      if (!_clearAnimationController.isAnimating) {
        _clearAnimationController.forward(from: 0);
      }
    }

    if (widget.dragPosition != null && widget.draggingPiece != null) {
      final gridPos = _getGridPosition(widget.dragPosition!);
      Offset? rawSnappedPos;

      if (gridPos != null) {
        // Strict check - faqat aniq hisoblangan joyga sig'adimi?
        if (widget.gameState.canPlacePiece(
          widget.draggingPiece!,
          gridPos.dx.toInt(),
          gridPos.dy.toInt(),
        )) {
          rawSnappedPos = gridPos;
        }
      }

      // Debounce logic - faqat vizual va joylash uchun
      // Yangi pozitsiya faqat debounce tugagandan keyin qabul qilinadi
      if (rawSnappedPos != _pendingSnappedPos) {
        _pendingSnappedPos = rawSnappedPos;
        _debounceTimer?.cancel();

        _debounceTimer = Timer(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              _displayedSnappedPos = rawSnappedPos;
            });
            // Faqat debounce tugagandan keyin callback chaqiriladi
            // Bu drop paytida "sakrash" muammosini hal qiladi
            widget.onGridHover(
              gridPos,
              _displayedSnappedPos,
              _displayedSnappedPos != null,
            );
          }
        });
      } else if (_displayedSnappedPos != null) {
        // Agar pozitsiya o'zgarmagan bo'lsa, lekin dragging davom etayotgan bo'lsa
        // joriy holatni yuborish (bu canPlace ni to'g'ri saqlaydi)
        widget.onGridHover(gridPos, _displayedSnappedPos, true);
      }
    } else {
      // Drag tugadi yoki yo'q
      if (_debounceTimer != null) {
        _debounceTimer!.cancel();
        _debounceTimer = null;
      }
      _pendingSnappedPos = null;
      _displayedSnappedPos = null;

      if (oldWidget.dragPosition != null) {
        widget.onGridHover(null, null, false);
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _clearAnimationController.dispose();
    super.dispose();
  }

  Offset? _getGridPosition(Offset globalPosition) {
    final RenderBox? box =
        _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;

    final cellSize = widget.gridSize / GameConstants.gridSize;

    if (widget.draggingPiece == null) return null;

    final piece = widget.draggingPiece!;

    // --- Pixel Perfect Logic ---
    // Vizual piece top-left pozitsiyasi (GameScreen dan):
    //   left = dragPosition.dx - pieceWidth/2
    //   top = dragPosition.dy - pieceHeight - 100.h

    final pieceWidth = piece.width * cellSize;
    final pieceHeight = piece.height * cellSize;

    final topLeftX = globalPosition.dx - pieceWidth / 2;
    final topLeftY = globalPosition.dy - pieceHeight - 50.h;

    final localTopLeft = box.globalToLocal(Offset(topLeftX, topLeftY));

    // To'g'ridan-to'g'ri rounding (Flame kodidagi kabi)
    final gridX = (localTopLeft.dx / cellSize).round();
    final gridY = (localTopLeft.dy / cellSize).round();

    return Offset(gridX.toDouble(), gridY.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final cellSize = widget.gridSize / GameConstants.gridSize;

    Offset? snappedPos;
    bool canPlace = false;
    Set<int> previewRows = {};
    Set<int> previewCols = {};

    if (widget.dragPosition != null && widget.draggingPiece != null) {
      // Build methodida faqat vizualizatsiya uchun _displayedSnappedPos ishlatamiz
      // Hisob-kitoblar didUpdateWidget da bajariladi
      snappedPos = _displayedSnappedPos;
      canPlace = snappedPos != null;

      if (canPlace) {
        final clears = widget.gameState.getPotentialClearLines(
          widget.draggingPiece!,
          snappedPos.dx.toInt(),
          snappedPos.dy.toInt(),
        );
        previewRows = clears.rows;
        previewCols = clears.cols;
      }
    }

    return Container(
      key: _gridKey,
      width: widget.gridSize,
      height: widget.gridSize,
      decoration: BoxDecoration(
        color: GameConstants.gridColor,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: GameConstants.gridLineColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: GameConstants.accentColor.withOpacityX(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacityX(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: CustomPaint(
          painter: GridPainter(
            grid: widget.grid,
            cellSize: cellSize,
            hoverPosition: snappedPos,
            hoverPiece: widget.draggingPiece,
            canPlace: canPlace,
            clearingCells: widget.gameState.clearingCells,
            isClearing: widget.gameState.isClearing,
            clearProgress: _clearAnimation.value,
            previewRows: previewRows,
            previewCols: previewCols,
            previewColor: widget.draggingPiece?.color,
          ),
        ),
      ),
    );
  }
}
