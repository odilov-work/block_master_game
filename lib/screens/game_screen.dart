import 'dart:async';
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
import 'package:block_master_game/widgets/game_over_overlay.dart';
import 'package:block_master_game/services/move_analysis_service.dart';
import 'package:block_master_game/services/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  int? draggingPieceIndex;
  Offset? dragPosition;
  Offset? gridHoverPosition;
  Offset? snappedPosition;
  bool canPlace = false;
  late GameState gameState;
  bool _showOverlay = false;
  Timer? _gameOverTimer;

  // Move Analysis Feedback State
  late AnimationController _feedbackController;
  Timer? _feedbackTimer;
  MoveAnalysisResult? _currentFeedback;
  MoveAnalysisResult? _lastSeenAnalysis;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // O'yin boshlanganda saqlangan o'yinni yuklashga urinib ko'ramiz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      gameState = context.read<GameState>();
      if (!gameState.loadGame()) {
        // Agar saqlangan o'yin bo'lmasa yoki yuklashda xatolik bo'lsa, yangi o'yin
        gameState.restartGame();
      }
    });

    // Listen for Game Over state changes
    gameState = context.read<GameState>();
    gameState.addListener(_onGameStateChanged);
  }

  void _onGameStateChanged() {
    if (gameState.isGameOver && !_showOverlay && _gameOverTimer == null) {
      // Game Over detected, start 3s timer
      _gameOverTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showOverlay = true;
          });
        }
      });
    } else if (!gameState.isGameOver) {
      // Game restarted
      _gameOverTimer?.cancel();
      _gameOverTimer = null;
      if (_showOverlay) {
        setState(() {
          _showOverlay = false;
        });
      }
    }

    // Check for new move analysis
    if (gameState.lastMoveAnalysis != _lastSeenAnalysis) {
      _lastSeenAnalysis = gameState.lastMoveAnalysis;

      // Check if tips are enabled
      bool tipsEnabled = LocalStorageService.getMoveAnalysisEnabled();

      if (tipsEnabled &&
          _lastSeenAnalysis != null &&
          _lastSeenAnalysis!.quality != MoveQuality.neutral) {
        _showFeedback(_lastSeenAnalysis!);
      }
    }
  }

  void _showFeedback(MoveAnalysisResult result) {
    _feedbackTimer?.cancel();
    _feedbackController.reset();

    setState(() {
      _currentFeedback = result;
    });

    _feedbackController.forward();

    _feedbackTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _feedbackController.reverse();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // O'yin yopilganda saqlash
    gameState.saveGame();
    gameState.removeListener(_onGameStateChanged);
    _gameOverTimer?.cancel();
    _feedbackTimer?.cancel();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      gameState.saveGame();
    }
  }

  void _onDragStart(int pieceIndex, Offset globalPosition) {
    if (gameState.isGameOver) return; // Disable interaction
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

    return Scaffold(
      backgroundColor: GameConstants.backgroundColor,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: BackgroundPainter()),
                ),
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
                      blockStyle: gameState.blockStyle,
                    ),
                    SizedBox(height: 40.h),
                  ],
                ),
              ],
            ),
          ),

          // Dragging Piece (Floating above UI)
          if (draggingPieceIndex != null && dragPosition != null)
            _buildDraggingPiece(),

          // Game Over Overlay (Topmost)
          if (_showOverlay)
            GameOverOverlay(
              score: gameState.score,
              highScore: gameState.highScore,
              onRestart: () {
                gameState.restartGame();
              },
              onHome: () {
                Navigator.of(context).pop();
              },
            ),

          // Move Analysis Feedback
          if (_currentFeedback != null) _buildMoveFeedback(_currentFeedback!),
        ],
      ),
    );
  }

  Widget _buildMoveFeedback(MoveAnalysisResult result) {
    Color color;
    IconData icon;

    switch (result.quality) {
      case MoveQuality.best:
        color = const Color(0xFF00FFFF); // Cyan
        icon = Icons.star_rounded;
        break;
      case MoveQuality.good:
        color = const Color(0xFF00FF00); // Green
        icon = Icons.thumb_up_rounded;
        break;
      case MoveQuality.neutral:
        return const SizedBox(); // Don't show anything for neutral moves
      case MoveQuality.bad:
        color = const Color(0xFFFFAA00); // Orange
        icon = Icons.warning_rounded;
        break;
      case MoveQuality.blunder:
        color = const Color(0xFFFF0055); // Red
        icon = Icons.error_outline_rounded;
        break;
    }

    return Positioned(
      top: 100.h,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedBuilder(
          animation: _feedbackController,
          builder: (context, child) {
            final value = CurvedAnimation(
              parent: _feedbackController,
              curve: Curves.elasticOut,
            ).value;

            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacityX(0.8),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: color, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacityX(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: color, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        result.message,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
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
                blockStyle: gameState.blockStyle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
