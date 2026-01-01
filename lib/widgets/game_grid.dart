import 'dart:async';
import 'package:block_master_game/core/extensions.dart';
import 'package:flutter/material.dart';
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
        rawSnappedPos = widget.gameState.findStrictValidPosition(
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

        _debounceTimer = Timer(const Duration(milliseconds: 75), () {
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

    final localPos = box.globalToLocal(globalPosition);

    // Grid chegarasidan chiqib ketsa null qaytarish
    // Bu taklifni yo'qotadi
    if (localPos.dx < 0 ||
        localPos.dx > box.size.width ||
        localPos.dy < 0 ||
        localPos.dy > box.size.height) {
      return null;
    }

    final cellSize = widget.gridSize / GameConstants.gridSize;

    int gridX = (localPos.dx / cellSize).floor();
    int gridY = (localPos.dy / cellSize).floor();

    // Shakl markazini sichqoncha/barmoq ostiga to'g'irlash
    if (widget.draggingPiece != null) {
      gridX -= (widget.draggingPiece!.width / 2).floor();
      gridY -= (widget.draggingPiece!.height / 2).floor();
    }

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
