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
      bool canPlace = false;

      if (gridPos != null) {
        rawSnappedPos = widget.gameState.findSmartValidPosition(
          widget.draggingPiece!,
          gridPos.dx.toInt(),
          gridPos.dy.toInt(),
        );
        canPlace = rawSnappedPos != null;
      }

      // Debounce logic
      if (rawSnappedPos != _pendingSnappedPos) {
        _pendingSnappedPos = rawSnappedPos;
        _debounceTimer?.cancel();

        _debounceTimer = Timer(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              _displayedSnappedPos = rawSnappedPos;
            });
            widget.onGridHover(gridPos, _displayedSnappedPos, canPlace);
          }
        });
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

    // --- Shaklni centroid pozitsiyasidan foydalanish ---
    // GameScreen:
    //   piece top-left = (dragPosition.dx - pieceWidth/2, dragPosition.dy - pieceHeight - 200)
    //
    // Shaklni centroid (o'z markaziga nisbatan) - masalan L-shakl uchun bu burchakdan emas

    final piece = widget.draggingPiece!;
    final centroid =
        piece.centroid; // Shaklning o'z markazi (kataklar birligida)

    // Vizual piece top-left (screen koordinatalarida)
    final pieceWidth = piece.width * cellSize;
    final pieceHeight = piece.height * cellSize;
    final visualLeft = globalPosition.dx - pieceWidth / 2;
    final visualTop = globalPosition.dy - pieceHeight - 200.h;

    // Centroid pozitsiyasini screen ga o'tkazish
    final centroidScreenX = visualLeft + centroid.dx * cellSize;
    final centroidScreenY = visualTop + centroid.dy * cellSize;

    // Grid lokal koordinatasi
    final localCentroid = box.globalToLocal(
      Offset(centroidScreenX, centroidScreenY),
    );

    // Grid chegarasidan chiqib ketsa null qaytarish
    if (localCentroid.dx < -cellSize ||
        localCentroid.dx > box.size.width + cellSize ||
        localCentroid.dy < -cellSize ||
        localCentroid.dy > box.size.height + cellSize) {
      return null;
    }

    // Centroid qaysi grid katagiga tushadi
    final centroidGridX = (localCentroid.dx / cellSize).floor();
    final centroidGridY = (localCentroid.dy / cellSize).floor();

    // Top-left pozitsiyani hisoblash (centroid - centroid offset)
    int gridX = centroidGridX - centroid.dx.floor();
    int gridY = centroidGridY - centroid.dy.floor();

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
