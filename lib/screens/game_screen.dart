import 'package:block_master_game/providers/game_provider.dart';
import 'package:block_master_game/piece_generator.dart';
import 'package:block_master_game/widgets/background_painter.dart';
import 'package:block_master_game/core/extensions.dart';
import 'package:block_master_game/widgets/game_grid.dart';
import 'package:block_master_game/widgets/piece_painter.dart';
import 'package:block_master_game/widgets/piece_selector.dart';
import 'package:block_master_game/widgets/score_board.dart';
import 'package:block_master_game/widgets/game_menu_dialog.dart';
import 'package:block_master_game/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  int? draggingPieceIndex;
  Offset? dragPosition;
  Offset? gridHoverPosition;
  Offset? snappedPosition;
  bool canPlace = false;
  late GameState gameState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // O'yin boshlanganda saqlangan o'yinni yuklashga urinib ko'ramiz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      gameState = context.read<GameState>();
      debugPrint('GameScreen: Attempting to load game...');
      if (!gameState.loadGame()) {
        debugPrint('GameScreen: No saved game found, restarting...');
        // Agar saqlangan o'yin bo'lmasa yoki yuklashda xatolik bo'lsa, yangi o'yin
        gameState.restartGame();
      } else {
        debugPrint('GameScreen: Game loaded successfully!');
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // O'yin yopilganda saqlash
    debugPrint('GameScreen: Disposing, saving game...');
    gameState.saveGame();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      debugPrint('GameScreen: App paused/inactive, saving game...');
      gameState.saveGame();
    }
  }

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
    final gridSize = 350.w.clamp(280.0, 400.0);

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
                SizedBox(height: 16.h),
                GameHeader(
                  score: gameState.score,
                  highScore: gameState.highScore,
                  combo: gameState.combo,
                  onMenuPressed: _showMenuDialog,
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
                SizedBox(height: 40.h),
              ],
            ),
            if (draggingPieceIndex != null && dragPosition != null)
              _buildDraggingPiece(),
          ],
        ),
      ),
    );
  }

  void _showGameOverDialog() {
    // O'yin tugaganda saqlangan o'yinni o'chirish
    gameState.clearSavedGame();
    // ... dialog logic (hozircha bo'sh)
  }

  void _showMenuDialog() {
    // Menu ochilganda saqlash
    gameState.saveGame();

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacityX(0.8),
      builder: (context) => GameMenuDialog(
        onResume: () => Navigator.pop(context),
        onRestart: () {
          Navigator.pop(context);
          gameState.clearSavedGame();
          gameState.restartGame();
        },
        onHome: () {
          Navigator.pop(context);
          gameState.saveGame();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        },
      ),
    );
  }

  Widget _buildDraggingPiece() {
    final gameState = context.read<GameState>();
    final piece = gameState.availablePieces[draggingPieceIndex!];
    if (piece == null) return const SizedBox();

    final gridSize = 350.w.clamp(280.0, 400.0);
    final cellSize = gridSize / GameConstants.gridSize;

    final pieceWidth = piece.width * cellSize;
    final pieceHeight = piece.height * cellSize;

    return Positioned(
      left: dragPosition!.dx - pieceWidth / 2,
      top: dragPosition!.dy - pieceHeight - 100.h,
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
