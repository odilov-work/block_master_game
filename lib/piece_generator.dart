import 'dart:math';

import 'package:flutter/material.dart';

class GameConstants {
  static const int gridSize = 8;
  static const double cellSize = 32.0;
  static const double piecePreviewScale = 0.7;

  // Colors
  static const Color backgroundColor = Color(0xFF1A1A2E);
  static const Color gridColor = Color(0xFF16213E);
  static const Color gridLineColor = Color(0xFF2D3A5A);
  static const Color accentColor = Color(0xFF6C5CE7);

  static const List<Color> pieceColors = [
    Color(0xFFFF0055), // Neon Red
    Color(0xFF00FFFF), // Cyan
    Color(0xFFFFDD00), // Bright Yellow
    Color(0xFF00FF99), // Neon Green
    Color(0xFFFF6600), // Bright Orange
    Color(0xFFCC00FF), // Neon Purple
    Color(0xFF0066FF), // Bright Blue
    Color(0xFFFF00CC), // Hot Pink
  ];
}

// ============================================================================
// GRID CELL
// ============================================================================

class GridCell {
  bool occupied;
  Color? color;

  GridCell({this.occupied = false, this.color});

  void clear() {
    occupied = false;
    color = null;
  }

  void fill(Color c) {
    occupied = true;
    color = c;
  }
}

// ============================================================================
// PIECE SHAPE
// ============================================================================

class PieceShape {
  final List<List<int>> shape;
  final Color color;
  final String name;

  const PieceShape({
    required this.shape,
    required this.color,
    required this.name,
  });

  int get width {
    int maxWidth = 0;
    for (var row in shape) {
      int rowWidth = 0;
      for (int i = row.length - 1; i >= 0; i--) {
        if (row[i] == 1) {
          rowWidth = i + 1;
          break;
        }
      }
      if (rowWidth > maxWidth) maxWidth = rowWidth;
    }
    return maxWidth;
  }

  int get height {
    int h = 0;
    for (int i = shape.length - 1; i >= 0; i--) {
      if (shape[i].any((cell) => cell == 1)) {
        h = i + 1;
        break;
      }
    }
    return h;
  }

  int get cellCount {
    int count = 0;
    for (var row in shape) {
      for (var cell in row) {
        if (cell == 1) count++;
      }
    }
    return count;
  }

  List<Offset> get cells {
    List<Offset> result = [];
    for (int y = 0; y < shape.length; y++) {
      for (int x = 0; x < shape[y].length; x++) {
        if (shape[y][x] == 1) {
          result.add(Offset(x.toDouble(), y.toDouble()));
        }
      }
    }
    return result;
  }

  /// Shaklning markazini (centroid) hisoblash
  /// Bu barcha to'ldirilgan kataklarning o'rtacha pozitsiyasi
  Offset get centroid {
    final c = cells;
    if (c.isEmpty) return Offset.zero;

    double sumX = 0, sumY = 0;
    for (var cell in c) {
      sumX += cell.dx + 0.5; // Katak markaziga
      sumY += cell.dy + 0.5;
    }
    return Offset(sumX / c.length, sumY / c.length);
  }
}

// ============================================================================
// PIECE SHAPES COLLECTION
// ============================================================================

class PieceShapes {
  static List<PieceShape> getAllShapes() {
    return [
      // Single block
      PieceShape(
        name: 'single',
        shape: [
          [1],
        ],
        color: GameConstants.pieceColors[0],
      ),
      PieceShape(
        name: 'diagonal1',
        shape: [
          [1, 0],
          [0, 1],
        ],
        color: GameConstants.pieceColors[0],
      ),

      PieceShape(
        name: 'diagonal2',
        shape: [
          [0, 1],
          [1, 0],
        ],
        color: GameConstants.pieceColors[0],
      ),
      // 2-block horizontal
      PieceShape(
        name: 'h2',
        shape: [
          [1, 1],
        ],
        color: GameConstants.pieceColors[1],
      ),
      // 2-block vertical
      PieceShape(
        name: 'v2',
        shape: [
          [1],
          [1],
        ],
        color: GameConstants.pieceColors[2],
      ),
      // 3-block horizontal
      PieceShape(
        name: 'h3',
        shape: [
          [1, 1, 1],
        ],
        color: GameConstants.pieceColors[3],
      ),
      // 3-block vertical
      PieceShape(
        name: 'v3',
        shape: [
          [1],
          [1],
          [1],
        ],
        color: GameConstants.pieceColors[4],
      ),
      // L shape
      PieceShape(
        name: 'L',
        shape: [
          [1, 0],
          [1, 0],
          [1, 1],
        ],
        color: GameConstants.pieceColors[5],
      ),
      // Reverse L
      PieceShape(
        name: 'reverseL',
        shape: [
          [0, 1],
          [0, 1],
          [1, 1],
        ],
        color: GameConstants.pieceColors[6],
      ),
      // T shape
      PieceShape(
        name: 'T',
        shape: [
          [1, 1, 1],
          [0, 1, 0],
        ],
        color: GameConstants.pieceColors[7],
      ),
      // T shape
      PieceShape(
        name: 'T',
        shape: [
          [0, 1, 0],
          [1, 1, 1],
        ],
        color: GameConstants.pieceColors[7],
      ),
      // Square 2x2
      PieceShape(
        name: 'square2',
        shape: [
          [1, 1],
          [1, 1],
        ],
        color: GameConstants.pieceColors[0],
      ),
      // Square 3x3
      PieceShape(
        name: 'square3',
        shape: [
          [1, 1, 1],
          [1, 1, 1],
          [1, 1, 1],
        ],
        color: GameConstants.pieceColors[1],
      ),
      // 4-block horizontal
      PieceShape(
        name: 'h4',
        shape: [
          [1, 1, 1, 1],
        ],
        color: GameConstants.pieceColors[2],
      ),
      // 4-block vertical
      PieceShape(
        name: 'v4',
        shape: [
          [1],
          [1],
          [1],
          [1],
        ],
        color: GameConstants.pieceColors[3],
      ),
      // S shape
      PieceShape(
        name: 'S',
        shape: [
          [0, 1, 1],
          [1, 1, 0],
        ],
        color: GameConstants.pieceColors[6],
      ),
      // Z shape
      PieceShape(
        name: 'Z',
        shape: [
          [1, 1, 0],
          [0, 1, 1],
        ],
        color: GameConstants.pieceColors[7],
      ),
      // Z shape
      PieceShape(
        name: 'rectangleH',
        shape: [
          [1, 1, 1],
          [1, 1, 1],
        ],
        color: GameConstants.pieceColors[7],
      ),

      PieceShape(
        name: 'rectangleV',
        shape: [
          [1, 1],
          [1, 1],
          [1, 1],
        ],
        color: GameConstants.pieceColors[7],
      ),
      // Corner shape
      PieceShape(
        name: 'corner',
        shape: [
          [1, 1],
          [1, 0],
        ],
        color: GameConstants.pieceColors[0],
      ),
      // Big L
      PieceShape(
        name: 'bigL',
        shape: [
          [1, 0, 0],
          [1, 0, 0],
          [1, 1, 1],
        ],
        color: GameConstants.pieceColors[1],
      ),
      // Plus shape
      PieceShape(
        name: 'plus',
        shape: [
          [0, 1, 0],
          [1, 1, 1],
          [0, 1, 0],
        ],
        color: GameConstants.pieceColors[2],
      ),
    ];
  }

  static const List<String> rarePieces = [
    'single',
    'diagonal1',
    'diagonal2',
    'h2',
    'v2',
  ];
}

// ============================================================================
// SMART PIECE GENERATOR - AQLLI SHAKL GENERATORI
// ============================================================================

/// O'yin taxtasining holati haqida ma'lumot
class BoardAnalysis {
  final int emptyCount;
  final int occupiedCount;
  final double fillPercentage;
  final List<int> rowFillCounts;
  final List<int> colFillCounts;
  final List<int> almostCompleteRows;
  final List<int> almostCompleteCols;
  final int largestEmptyArea;
  final int maxConsecutiveEmpty;
  final List<Point<int>> criticalEmptySpots;

  BoardAnalysis({
    required this.emptyCount,
    required this.occupiedCount,
    required this.fillPercentage,
    required this.rowFillCounts,
    required this.colFillCounts,
    required this.almostCompleteRows,
    required this.almostCompleteCols,
    required this.largestEmptyArea,
    required this.maxConsecutiveEmpty,
    required this.criticalEmptySpots,
  });

  /// Taxta qanchalik xavfli holatda
  bool get isCritical => fillPercentage >= 0.75;
  bool get isDangerous => fillPercentage >= 0.6;
  bool get isComfortable => fillPercentage <= 0.4;
}

/// Generatsiya strategiyasi
enum GenerationStrategy {
  helpful, // Yordam beruvchi shakllar (qator/ustun to'ldirishga)
  balanced, // Muvozanatli (o'rtacha hajm)
  challenging, // Qiyinlashtiruvchi (katta yoki noqulay)
  critical, // O'yin tugash arafasida - faqat sig'adigan shakllar
  rewarding, // Mukofot - juda yaxshi shakllar (combo uchun)
}

/// Aqlli shakl generatori
class SmartPieceGenerator {
  final Random _random = Random();

  // Statistika va tracking
  int _helpfulPiecesGiven = 0;
  int _challengingPiecesGiven = 0;
  int _totalPiecesGenerated = 0;
  int _consecutiveHelpful = 0;
  int _linesCleared = 0;
  int _currentCombo = 0;

  // Konfiguratsiya
  final int challengeAfterHelpful;
  final double baseChallengeChance;
  final double criticalThreshold;
  final int rewardAfterLines;

  SmartPieceGenerator({
    this.challengeAfterHelpful = 5,
    this.baseChallengeChance = 0.18,
    this.criticalThreshold = 0.75,
    this.rewardAfterLines = 3,
  });

  /// O'yinni yangilash (har safar shakl qo'yilganda chaqirish)
  void onPiecePlaced({int linesCleared = 0, int combo = 0}) {
    _linesCleared += linesCleared;
    _currentCombo = combo;
  }

  /// Taxtani tahlil qilish
  BoardAnalysis analyzeBoard(List<List<GridCell>> grid) {
    int gridSize = GameConstants.gridSize;
    int emptyCount = 0;
    int occupiedCount = 0;
    List<int> rowFillCounts = List.filled(gridSize, 0);
    List<int> colFillCounts = List.filled(gridSize, 0);
    List<int> almostCompleteRows = [];
    List<int> almostCompleteCols = [];
    List<Point<int>> criticalSpots = [];

    // Har bir katakni tekshirish
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (grid[y][x].occupied) {
          occupiedCount++;
          rowFillCounts[y]++;
          colFillCounts[x]++;
        } else {
          emptyCount++;
        }
      }
    }

    // Deyarli to'lgan qator/ustunlarni topish
    for (int i = 0; i < gridSize; i++) {
      if (rowFillCounts[i] >= gridSize - 2 && rowFillCounts[i] < gridSize) {
        almostCompleteRows.add(i);
        // Bu qatordagi bo'sh joylarni topish
        for (int x = 0; x < gridSize; x++) {
          if (!grid[i][x].occupied) {
            criticalSpots.add(Point(x, i));
          }
        }
      }
      if (colFillCounts[i] >= gridSize - 2 && colFillCounts[i] < gridSize) {
        almostCompleteCols.add(i);
        // Bu ustundagi bo'sh joylarni topish
        for (int y = 0; y < gridSize; y++) {
          if (!grid[y][i].occupied) {
            criticalSpots.add(Point(i, y));
          }
        }
      }
    }

    // Eng uzun bo'sh ketma-ketlik
    int maxConsecutive = _findMaxConsecutiveEmpty(grid, gridSize);

    // Eng katta bo'sh hudud
    int largestArea = _findLargestEmptyArea(grid, gridSize);

    return BoardAnalysis(
      emptyCount: emptyCount,
      occupiedCount: occupiedCount,
      fillPercentage: occupiedCount / (gridSize * gridSize),
      rowFillCounts: rowFillCounts,
      colFillCounts: colFillCounts,
      almostCompleteRows: almostCompleteRows,
      almostCompleteCols: almostCompleteCols,
      largestEmptyArea: largestArea,
      maxConsecutiveEmpty: maxConsecutive,
      criticalEmptySpots: criticalSpots,
    );
  }

  int _findMaxConsecutiveEmpty(List<List<GridCell>> grid, int gridSize) {
    int maxConsecutive = 0;

    // Gorizontal
    for (int y = 0; y < gridSize; y++) {
      int current = 0;
      for (int x = 0; x < gridSize; x++) {
        if (!grid[y][x].occupied) {
          current++;
          maxConsecutive = max(maxConsecutive, current);
        } else {
          current = 0;
        }
      }
    }

    // Vertikal
    for (int x = 0; x < gridSize; x++) {
      int current = 0;
      for (int y = 0; y < gridSize; y++) {
        if (!grid[y][x].occupied) {
          current++;
          maxConsecutive = max(maxConsecutive, current);
        } else {
          current = 0;
        }
      }
    }

    return maxConsecutive;
  }

  int _findLargestEmptyArea(List<List<GridCell>> grid, int gridSize) {
    int largestArea = 0;

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (!grid[y][x].occupied) {
          // Bu nuqtadan boshlab eng katta to'rtburchak
          int maxWidth = 0;
          for (int w = x; w < gridSize; w++) {
            if (grid[y][w].occupied) break;
            maxWidth = w - x + 1;
          }

          int maxHeight = 0;
          for (int h = y; h < gridSize; h++) {
            bool rowClear = true;
            for (int w = x; w < x + maxWidth && w < gridSize; w++) {
              if (grid[h][w].occupied) {
                rowClear = false;
                break;
              }
            }
            if (!rowClear) break;
            maxHeight = h - y + 1;
          }

          int area = maxWidth * maxHeight;
          if (area > largestArea) largestArea = area;
        }
      }
    }

    return largestArea;
  }

  /// Strategiyani aniqlash
  GenerationStrategy _determineStrategy(BoardAnalysis analysis) {
    // Critical holat - taxta juda to'lgan
    if (analysis.isCritical) {
      return GenerationStrategy.critical;
    }

    // Mukofot - ko'p qator tozalangan
    if (_linesCleared >= rewardAfterLines && _random.nextDouble() < 0.6) {
      _linesCleared = 0; // Reset
      return GenerationStrategy.rewarding;
    }

    // Combo davom etmoqda - yordam berish
    if (_currentCombo >= 2) {
      return GenerationStrategy.helpful;
    }

    // Agar ketma-ket ko'p yordam berilgan bo'lsa - challenge vaqti
    if (_consecutiveHelpful >= challengeAfterHelpful) {
      return GenerationStrategy.challenging;
    }

    // Xavfli holat - yordam kerak
    if (analysis.isDangerous) {
      return _random.nextDouble() < 0.7
          ? GenerationStrategy.helpful
          : GenerationStrategy.balanced;
    }

    // Qulay holat - challenge berish mumkin
    if (analysis.isComfortable) {
      return _random.nextDouble() < baseChallengeChance + 0.1
          ? GenerationStrategy.challenging
          : GenerationStrategy.balanced;
    }

    // Deyarli to'lgan qatorlar bor - yordam berish
    if (analysis.almostCompleteRows.isNotEmpty ||
        analysis.almostCompleteCols.isNotEmpty) {
      return _random.nextDouble() < 0.7
          ? GenerationStrategy.helpful
          : GenerationStrategy.balanced;
    }

    // Tasodifiy challenge
    if (_random.nextDouble() < baseChallengeChance) {
      return GenerationStrategy.challenging;
    }

    return GenerationStrategy.balanced;
  }

  /// Yordam beruvchi shakllarni tanlash
  List<PieceShape> _getHelpfulPieces(
    BoardAnalysis analysis,
    List<PieceShape> allShapes,
  ) {
    List<PieceShape> helpful = [];

    // Deyarli to'lgan qatorlar uchun gorizontal shakllar
    for (int row in analysis.almostCompleteRows) {
      int needed = GameConstants.gridSize - analysis.rowFillCounts[row];

      helpful.addAll(
        allShapes.where(
          (s) =>
              s.height == 1 &&
              s.width <= needed &&
              s.width >= max(1, needed - 1),
        ),
      );
    }

    // Deyarli to'lgan ustunlar uchun vertikal shakllar
    for (int col in analysis.almostCompleteCols) {
      int needed = GameConstants.gridSize - analysis.colFillCounts[col];

      helpful.addAll(
        allShapes.where(
          (s) =>
              s.width == 1 &&
              s.height <= needed &&
              s.height >= max(1, needed - 1),
        ),
      );
    }

    // Kichik shakllar ham foydali
    // LEKIN: Agar xavfli holat bo'lmasa, juda oson shakllarni (single, h2, v2) bermaymiz
    if (analysis.isDangerous || analysis.isCritical) {
      helpful.addAll(allShapes.where((s) => s.cellCount <= 3));
      // Single block har doim foydali (faqat xavfli paytda)
      helpful.addAll(allShapes.where((s) => s.name == 'single'));
    } else {
      // Xavfsiz holatda faqat "rare" bo'lmagan kichik shakllarni qo'shamiz
      helpful.addAll(
        allShapes.where(
          (s) => s.cellCount <= 3 && !PieceShapes.rarePieces.contains(s.name),
        ),
      );
    }

    return helpful.toSet().toList();
  }

  /// Qiyinlashtiruvchi shakllarni tanlash
  List<PieceShape> _getChallengingPieces(
    BoardAnalysis analysis,
    List<PieceShape> allShapes,
  ) {
    List<PieceShape> challenging = [];

    // Katta shakllar qiyin
    challenging.addAll(allShapes.where((s) => s.cellCount >= 5));

    // Noqulay shakllar
    challenging.addAll(
      allShapes.where(
        (s) =>
            ['L', 'reverseL', 'T', 'S', 'Z', 'bigL', 'plus'].contains(s.name),
      ),
    );

    // Agar bo'sh joy kam bo'lsa, uzun shakllar qiyin
    if (analysis.maxConsecutiveEmpty < 4) {
      challenging.addAll(allShapes.where((s) => s.width >= 4 || s.height >= 4));
    }

    // 3x3 kvadrat har doim qiyin
    challenging.addAll(allShapes.where((s) => s.name == 'square3'));

    return challenging.toSet().toList();
  }

  /// Muvozanatli shakllarni tanlash
  List<PieceShape> _getBalancedPieces(List<PieceShape> allShapes) {
    return allShapes
        .where(
          (s) =>
              s.cellCount >= 2 &&
              s.cellCount <= 4 &&
              !PieceShapes.rarePieces.contains(s.name),
        )
        .toList();
  }

  /// Critical holatda shakllarni tanlash
  List<PieceShape> _getCriticalPieces(
    BoardAnalysis analysis,
    List<PieceShape> allShapes,
  ) {
    List<PieceShape> critical = [];

    int maxSize = analysis.maxConsecutiveEmpty;

    // Faqat sig'adigan kichik shakllar
    critical.addAll(
      allShapes.where(
        (s) => s.width <= maxSize && s.height <= maxSize && s.cellCount <= 3,
      ),
    );

    // Agar hech narsa sig'masa, faqat single
    if (critical.isEmpty) {
      critical.addAll(allShapes.where((s) => s.cellCount == 1));
    }

    return critical;
  }

  /// Mukofot shakllarini tanlash
  List<PieceShape> _getRewardingPieces(
    BoardAnalysis analysis,
    List<PieceShape> allShapes,
  ) {
    List<PieceShape> rewarding = [];

    // Eng kerakli shakllar - qator/ustun to'ldirish uchun
    for (int row in analysis.almostCompleteRows) {
      int needed = GameConstants.gridSize - analysis.rowFillCounts[row];
      rewarding.addAll(
        allShapes.where((s) => s.height == 1 && s.width == needed),
      );
    }

    for (int col in analysis.almostCompleteCols) {
      int needed = GameConstants.gridSize - analysis.colFillCounts[col];
      rewarding.addAll(
        allShapes.where((s) => s.width == 1 && s.height == needed),
      );
    }

    // Agar aniq shakl topilmasa, kichik shakllar
    if (rewarding.isEmpty) {
      rewarding.addAll(allShapes.where((s) => s.cellCount <= 2));
    }

    return rewarding.toSet().toList();
  }

  /// Asosiy generatsiya funksiyasi
  PieceShape generateSmartPiece(
    List<List<GridCell>> grid,
    List<PieceShape> allShapes,
  ) {
    _totalPiecesGenerated++;

    BoardAnalysis analysis = analyzeBoard(grid);
    GenerationStrategy strategy = _determineStrategy(analysis);

    List<PieceShape> candidates;

    switch (strategy) {
      case GenerationStrategy.helpful:
        candidates = _getHelpfulPieces(analysis, allShapes);
        if (candidates.isNotEmpty) {
          _consecutiveHelpful++;
          _helpfulPiecesGiven++;
        }
        break;

      case GenerationStrategy.challenging:
        candidates = _getChallengingPieces(analysis, allShapes);
        _consecutiveHelpful = 0;
        _challengingPiecesGiven++;
        break;

      case GenerationStrategy.critical:
        candidates = _getCriticalPieces(analysis, allShapes);
        _consecutiveHelpful = 0;
        _helpfulPiecesGiven++;
        break;

      case GenerationStrategy.rewarding:
        candidates = _getRewardingPieces(analysis, allShapes);
        _consecutiveHelpful++;
        _helpfulPiecesGiven++;
        break;

      case GenerationStrategy.balanced:
        candidates = _getBalancedPieces(allShapes);
        break;
    }

    if (candidates.isEmpty) {
      candidates = allShapes;
    }

    // Tasodifiy rang berish
    PieceShape selected = candidates[_random.nextInt(candidates.length)];
    Color randomColor = GameConstants
        .pieceColors[_random.nextInt(GameConstants.pieceColors.length)];

    return PieceShape(
      name: selected.name,
      shape: selected.shape,
      color: randomColor,
    );
  }

  /// Statistika
  Map<String, dynamic> getStatistics() {
    return {
      'totalGenerated': _totalPiecesGenerated,
      'helpfulPieces': _helpfulPiecesGiven,
      'challengingPieces': _challengingPiecesGiven,
      'consecutiveHelpful': _consecutiveHelpful,
      'linesCleared': _linesCleared,
    };
  }

  void reset() {
    _helpfulPiecesGiven = 0;
    _challengingPiecesGiven = 0;
    _totalPiecesGenerated = 0;
    _consecutiveHelpful = 0;
    _linesCleared = 0;
    _currentCombo = 0;
  }
}
