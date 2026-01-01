import 'package:block_master_game/providers/game_provider.dart';
import 'package:block_master_game/piece_generator.dart';
import 'package:block_master_game/widgets/background_painter.dart';
import 'package:block_master_game/widgets/game_grid.dart';
import 'package:block_master_game/widgets/piece_painter.dart';
import 'package:block_master_game/widgets/piece_selector.dart';
import 'package:block_master_game/widgets/score_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  int? draggingPieceIndex;
  Offset? dragPosition;
  Offset? gridHoverPosition;
  Offset? snappedPosition;
  bool canPlace = false;

  void _onDragStart(int pieceIndex, Offset globalPosition) {
    HapticFeedback.lightImpact();
    setState(() {
      draggingPieceIndex = pieceIndex;
      dragPosition = globalPosition;
    });
  }

  void _onDragUpdate(Offset globalPosition) {
    setState(() {
      dragPosition = globalPosition;
    });
  }

  void _onDragEnd() {
    // --- O'ZGARTIRILGAN QISM: Joylash yoki Bekor qilish ---
    if (draggingPieceIndex != null) {
      if (snappedPosition != null && canPlace) {
        // Agar yaroqli joy topilgan bo'lsa, joylashtiramiz
        final gameState = context.read<GameState>();
        final piece = gameState.availablePieces[draggingPieceIndex!];
        if (piece != null) {
          int gridX = snappedPosition!.dx.toInt();
          int gridY = snappedPosition!.dy.toInt();

          if (gameState.placePiece(draggingPieceIndex!, gridX, gridY)) {
            HapticFeedback.mediumImpact();
          }
        }
      }
      // Agar snappedPosition == null bo'lsa (yaroqsiz joy),
      // biz shunchaki draggingPieceIndex ni null qilamiz.
      // Shakl availablePieces ro'yxatidan o'chirilmagani uchun
      // u avtomatik ravishda pastdagi joyiga "qaytadi".
    }

    setState(() {
      draggingPieceIndex = null;
      dragPosition = null;
      gridHoverPosition = null;
      snappedPosition = null;
      canPlace = false;
    });
  }

  void _updateGridHover(Offset? gridPos, Offset? snapped, bool canPlaceHere) {
    gridHoverPosition = gridPos;
    snappedPosition = snapped;
    canPlace = canPlaceHere;
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final size = MediaQuery.of(context).size;
    final gridSize = (size.width - 32).clamp(280.0, 400.0);

    if (gameState.isGameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGameOverDialog();
      });
    }

    return Scaffold(
      backgroundColor: GameConstants.backgroundColor,
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: BackgroundPainter())),
            Column(
              children: [
                const SizedBox(height: 16),
                ScoreBoard(
                  score: gameState.score,
                  highScore: gameState.highScore,
                  combo: gameState.combo,
                ),
                const Spacer(),
                Center(
                  child: GameGrid(
                    grid: gameState.grid,
                    gridSize: gridSize,
                    draggingPiece: draggingPieceIndex != null
                        ? gameState.availablePieces[draggingPieceIndex!]
                        : null,
                    dragPosition: dragPosition,
                    onGridHover: _updateGridHover,
                    gameState: gameState,
                  ),
                ),
                const Spacer(),
                PieceSelector(
                  pieces: gameState.availablePieces,
                  onDragStart: _onDragStart,
                  onDragUpdate: _onDragUpdate,
                  onDragEnd: _onDragEnd,
                  draggingIndex: draggingPieceIndex,
                ),
                SizedBox(height: 40),
              ],
            ),
            if (draggingPieceIndex != null && dragPosition != null)
              _buildDraggingPiece(),
          ],
        ),
      ),
    );
  }

  void _showGameOverDialog() {}

  Widget _buildDraggingPiece() {
    final gameState = context.read<GameState>();
    final piece = gameState.availablePieces[draggingPieceIndex!];
    if (piece == null) return const SizedBox();

    final cellSize = GameConstants
        .cellSize; // Asl o'lcham emas, hisoblangan bo'lishi kerak aslida
    // Eslatma: To'g'ri o'lcham GameGrid ichida hisoblanyapti, lekin drag paytida
    // vizual effekt uchun standart o'lcham ishlatsa bo'ladi.
    // Aniqroq bo'lishi uchun GameGrid o'lchamini olish kerak, lekin hozircha constant.

    final pieceWidth = piece.width * cellSize;
    final pieceHeight = piece.height * cellSize;

    return Positioned(
      left: dragPosition!.dx - pieceWidth / 2,
      top: dragPosition!.dy - pieceHeight - 50,
      child: IgnorePointer(
        child: Transform.scale(
          scale: 1.1,
          child: Opacity(
            opacity: 0.9,
            child: CustomPaint(
              size: Size(pieceWidth, pieceHeight),
              painter: PiecePainter(
                piece: piece,
                cellSize: cellSize,
                isValid: canPlace,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PAINTERS & WIDGETS
// ============================================================================
