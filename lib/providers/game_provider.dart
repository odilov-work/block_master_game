import 'dart:math';
import 'package:flutter/material.dart';
import 'package:block_master_game/piece_generator.dart';

import 'package:block_master_game/services/audio_service.dart';
import 'package:block_master_game/services/local_storage_service.dart';

class GameState extends ChangeNotifier {
  late List<List<GridCell>> grid;
  List<PieceShape?> availablePieces = [null, null, null];
  int score = 0;
  int highScore = 0;
  int combo = 0;
  bool isGameOver = false;

  Set<Point<int>> clearingCells = {};
  bool isClearing = false;

  final List<PieceShape> _allShapes = PieceShapes.getAllShapes();
  late SmartPieceGenerator _smartGenerator;

  GameState() {
    _smartGenerator = SmartPieceGenerator(
      challengeAfterHelpful: 4, // More helpful pieces before challenge (was 2)
      baseChallengeChance: 0.05, // Less random hard pieces (was 0.15)
      criticalThreshold: 0.85, // Critical mode triggers later (was 0.75)
      rewardAfterLines: 2, // Get helpful pieces sooner (was 3)
    );
    _initializeGrid();
    _loadHighScore();
    _generateNewPieces();
  }

  void _loadHighScore() {
    highScore = LocalStorageService.getHighScore();
  }

  void _initializeGrid() {
    grid = List.generate(
      GameConstants.gridSize,
      (y) => List.generate(GameConstants.gridSize, (x) => GridCell()),
    );
  }

  void _generateNewPieces() {
    for (int i = 0; i < 3; i++) {
      if (availablePieces[i] == null) {
        availablePieces[i] = _smartGenerator.generateSmartPiece(
          grid,
          _allShapes,
        );
      }
    }
    notifyListeners();
  }

  bool canPlacePiece(PieceShape piece, int gridX, int gridY) {
    for (var cell in piece.cells) {
      int x = gridX + cell.dx.toInt();
      int y = gridY + cell.dy.toInt();

      if (x < 0 ||
          x >= GameConstants.gridSize ||
          y < 0 ||
          y >= GameConstants.gridSize) {
        return false;
      }

      if (grid[y][x].occupied) {
        return false;
      }
    }
    return true;
  }

  // --- O'ZGARTIRILGAN QISM: Qat'iy joylashuvni aniqlash ---
  Offset? findStrictValidPosition(PieceShape piece, int gridX, int gridY) {
    // 1. Agar aynan ko'rsatilgan joy bo'sh bo'lsa, o'shani qaytaramiz
    if (canPlacePiece(piece, gridX, gridY)) {
      return Offset(gridX.toDouble(), gridY.toDouble());
    }

    // 2. Agar aynan o'zi to'g'ri kelmasa, faqat 1 katak radiusda qaraymiz.
    // Bu "magnit" effektini beradi lekin uzoqqa sakrab ketmaydi.
    // Avvalgi kodda maxDistance = 3 edi, bu juda uzoq.
    int strictMaxDistance = 1;

    double? nearestDist;
    Offset? nearestPos;

    for (int dy = -strictMaxDistance; dy <= strictMaxDistance; dy++) {
      for (int dx = -strictMaxDistance; dx <= strictMaxDistance; dx++) {
        // 0,0 ni tepadagi if tekshirib bo'ldi
        if (dx == 0 && dy == 0) continue;

        int nx = gridX + dx;
        int ny = gridY + dy;

        if (canPlacePiece(piece, nx, ny)) {
          // Pifagor teoremasi bo'yicha masofa
          double dist = sqrt((dx * dx + dy * dy).toDouble());
          if (nearestDist == null || dist < nearestDist) {
            nearestDist = dist;
            nearestPos = Offset(nx.toDouble(), ny.toDouble());
          }
        }
      }
    }

    return nearestPos;
  }

  Offset? findNearestValidPosition(PieceShape piece, int targetX, int targetY) {
    // 1. Check strict position first (optimization)
    if (canPlacePiece(piece, targetX, targetY)) {
      return Offset(targetX.toDouble(), targetY.toDouble());
    }

    Offset? bestPos;
    double minDistanceSq = double.infinity;

    // Grid bo'ylab barcha mumkin bo'lgan joylarni tekshiramiz
    // Grid kichkina (8x8 yoki 10x10) bo'lgani uchun bu juda tez ishlaydi
    for (int y = 0; y < GameConstants.gridSize; y++) {
      for (int x = 0; x < GameConstants.gridSize; x++) {
        if (canPlacePiece(piece, x, y)) {
          // Masofani hisoblash (Euclidean distance squared)
          double dx = (x - targetX).toDouble();
          double dy = (y - targetY).toDouble();
          double distSq = dx * dx + dy * dy;

          if (distSq < minDistanceSq) {
            minDistanceSq = distSq;
            bestPos = Offset(x.toDouble(), y.toDouble());
          }
        }
      }
    }

    return bestPos;
  }

  Set<Point<int>> getPotentialClears(PieceShape piece, int gridX, int gridY) {
    if (!canPlacePiece(piece, gridX, gridY)) return {};
    var result = getPotentialClearLines(piece, gridX, gridY);

    Set<Point<int>> clears = {};
    for (int y in result.rows) {
      for (int x = 0; x < GameConstants.gridSize; x++) {
        clears.add(Point(x, y));
      }
    }
    for (int x in result.cols) {
      for (int y = 0; y < GameConstants.gridSize; y++) {
        clears.add(Point(x, y));
      }
    }
    return clears;
  }

  ({Set<int> rows, Set<int> cols}) getPotentialClearLines(
    PieceShape piece,
    int gridX,
    int gridY,
  ) {
    if (!canPlacePiece(piece, gridX, gridY)) return (rows: {}, cols: {});

    Set<Point<int>> pieceCells = {};
    for (var cell in piece.cells) {
      pieceCells.add(Point(gridX + cell.dx.toInt(), gridY + cell.dy.toInt()));
    }

    Set<int> rowsToClear = {};
    Set<int> colsToClear = {};

    // Check rows
    for (int y = 0; y < GameConstants.gridSize; y++) {
      bool complete = true;
      for (int x = 0; x < GameConstants.gridSize; x++) {
        if (!grid[y][x].occupied && !pieceCells.contains(Point(x, y))) {
          complete = false;
          break;
        }
      }
      if (complete) rowsToClear.add(y);
    }

    // Check cols
    for (int x = 0; x < GameConstants.gridSize; x++) {
      bool complete = true;
      for (int y = 0; y < GameConstants.gridSize; y++) {
        if (!grid[y][x].occupied && !pieceCells.contains(Point(x, y))) {
          complete = false;
          break;
        }
      }
      if (complete) colsToClear.add(x);
    }

    return (rows: rowsToClear, cols: colsToClear);
  }

  bool placePiece(int pieceIndex, int gridX, int gridY) {
    final piece = availablePieces[pieceIndex];
    if (piece == null) return false;

    if (!canPlacePiece(piece, gridX, gridY)) return false;

    // Place
    for (var cell in piece.cells) {
      int x = gridX + cell.dx.toInt();
      int y = gridY + cell.dy.toInt();
      grid[y][x].fill(piece.color);
    }

    score += piece.cells.length;

    // Generate new for that slot
    availablePieces[pieceIndex] = _smartGenerator.generateSmartPiece(
      grid,
      _allShapes,
    );

    // Clear lines
    int linesCleared = _clearCompleteLines();

    if (linesCleared > 0) {
      combo++;

      // Calculate total cleared cells
      // To be precise according to "o'chib ketgan kvadratlar soni" (number of cleared squares):
      // If a row and col intersect, that square is cleared once.
      // So we should count unique cleared cells.
      // We can use the `clearingCells` set which is populated in _clearCompleteLines before this.
      int totalClearedCells = clearingCells.length;

      int multiplier = 1;
      if (linesCleared == 1) {
        multiplier = 2;
      } else if (linesCleared == 2) {
        multiplier = 4;
      } else if (linesCleared == 3) {
        multiplier = 10;
      } else if (linesCleared >= 4) {
        multiplier = 20;
      }

      score += totalClearedCells * multiplier;

      // GameAudioService.playClear(); // This is handled in _performClear after delay
    } else {
      combo = 0;
    }

    _smartGenerator.onPiecePlaced(linesCleared: linesCleared, combo: combo);

    if (score > highScore) {
      highScore = score;
      LocalStorageService.saveHighScore(highScore);
    }

    if (linesCleared == 0) {
      GameAudioService.playPlace();
      _checkGameOver();
    }
    notifyListeners();

    return true;
  }

  int _clearCompleteLines() {
    Set<int> rowsToClear = {};
    Set<int> colsToClear = {};

    for (int y = 0; y < GameConstants.gridSize; y++) {
      bool complete = true;
      for (int x = 0; x < GameConstants.gridSize; x++) {
        if (!grid[y][x].occupied) {
          complete = false;
          break;
        }
      }
      if (complete) rowsToClear.add(y);
    }

    for (int x = 0; x < GameConstants.gridSize; x++) {
      bool complete = true;
      for (int y = 0; y < GameConstants.gridSize; y++) {
        if (!grid[y][x].occupied) {
          complete = false;
          break;
        }
      }
      if (complete) colsToClear.add(x);
    }

    clearingCells = {};
    for (int y in rowsToClear) {
      for (int x = 0; x < GameConstants.gridSize; x++) {
        clearingCells.add(Point(x, y));
      }
    }
    for (int x in colsToClear) {
      for (int y = 0; y < GameConstants.gridSize; y++) {
        clearingCells.add(Point(x, y));
      }
    }

    if (clearingCells.isNotEmpty) {
      isClearing = true;
      notifyListeners();

      Future.delayed(const Duration(milliseconds: 350), () {
        _performClear(rowsToClear, colsToClear);
      });
    }

    return rowsToClear.length + colsToClear.length;
  }

  void _performClear(Set<int> rowsToClear, Set<int> colsToClear) {
    for (int y in rowsToClear) {
      for (int x = 0; x < GameConstants.gridSize; x++) {
        grid[y][x].clear();
      }
    }
    for (int x in colsToClear) {
      for (int y = 0; y < GameConstants.gridSize; y++) {
        grid[y][x].clear();
      }
    }
    clearingCells = {};
    isClearing = false;
    GameAudioService.playClear();
    _checkGameOver();
    notifyListeners();
  }

  void _checkGameOver() {
    for (var piece in availablePieces) {
      if (piece == null) continue;

      for (int y = 0; y < GameConstants.gridSize; y++) {
        for (int x = 0; x < GameConstants.gridSize; x++) {
          if (canPlacePiece(piece, x, y)) {
            return;
          }
        }
      }
    }

    if (availablePieces.any((p) => p != null)) {
      isGameOver = true;
      GameAudioService.playGameOver();
    }
  }

  void restart() {
    _initializeGrid();
    availablePieces = [null, null, null];
    score = 0;
    combo = 0;
    isGameOver = false;
    _smartGenerator.reset();
    _generateNewPieces();
    notifyListeners();
  }

  void restartGame() {
    score = 0;
    combo = 0;
    isGameOver = false;
    clearingCells.clear();
    isClearing = false;
    availablePieces = [null, null, null];
    _initializeGrid();
    _generateNewPieces();
    notifyListeners();
  }

  // --- Game State Persistence ---

  Future<void> saveGame() async {
    if (isGameOver) {
      debugPrint('GameState: Game over, skipping save.');
      return;
    }

    debugPrint('GameState: Saving game...');
    final gridData = grid
        .map((row) => row.map((cell) => cell.toJson()).toList())
        .toList();

    final piecesData = availablePieces.map((p) => p?.name).toList();

    final state = {
      'score': score,
      'combo': combo,
      'grid': gridData,
      'pieces': piecesData,
    };

    await LocalStorageService.saveGameState(state);
    debugPrint('GameState: Game saved successfully.');
  }

  bool loadGame() {
    debugPrint('GameState: Loading game...');
    final state = LocalStorageService.getGameState();
    if (state == null) {
      debugPrint('GameState: No saved game found.');
      return false;
    }

    try {
      score = state['score'] as int;
      combo = state['combo'] as int;

      // Restore Grid
      final gridData = state['grid'] as List;
      grid = gridData.map((row) {
        return (row as List).map((cell) {
          return GridCell.fromJson(Map<String, dynamic>.from(cell));
        }).toList();
      }).toList();

      // Restore Pieces
      final piecesData = state['pieces'] as List;
      availablePieces = piecesData.map((name) {
        if (name == null) return null;
        return _allShapes.firstWhere(
          (s) => s.name == name,
          orElse: () => _allShapes[0], // Fallback
        );
      }).toList();

      notifyListeners();
      debugPrint('GameState: Game loaded successfully.');
      return true;
    } catch (e) {
      debugPrint('GameState: Error loading game: $e');
      return false;
    }
  }

  Future<void> clearSavedGame() async {
    debugPrint('GameState: Clearing saved game...');
    await LocalStorageService.clearGameState();
  }
}
