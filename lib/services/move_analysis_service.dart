import 'dart:math';

// Sizning GridCell classingiz bor deb faraz qilamiz
// Agar yo'q bo'lsa, oddiy class ochib oling:
// class GridCell { bool occupied; GridCell({this.occupied = false}); }
import 'package:block_master_game/piece_generator.dart';

enum MoveQuality {
  best, // Brilliant (Multiple lines cleared or very clean board)
  good, // Good (Safe move)
  neutral, // Neutral (No harm done)
  bad, // Bad (Holes created or space narrowed)
  blunder, // Blunder (No 3x3 space left, risk of game over)
}

class MoveAnalysisResult {
  final MoveQuality quality;
  final String message;
  final double scoreDelta;
  final List<String> reasons; // Why this rating?

  MoveAnalysisResult({
    required this.quality,
    required this.message,
    required this.scoreDelta,
    this.reasons = const [],
  });
}

class SmartMoveAnalysisService {
  // --- SETTINGS (Weights) ---
  static const double _wLines = 150.0; // Line clear bonus
  static const double _wHoles = -60.0; // Holes penalty (stronger)
  static const double _wBumpiness = -5.0; // Bumpiness
  static const double _wFragmentation = -10.0; // Scattered cells
  static const double _wCenterControl = 5.0; // Keep center clean

  MoveAnalysisResult analyzeMove({
    required List<List<GridCell>> oldGrid,
    required List<List<GridCell>> newGrid,
    required int linesCleared,
  }) {
    List<String> reasons = [];

    // 1. Dynamic grid size
    int rows = newGrid.length;
    int cols = newGrid[0].length;

    // 2. Evaluation (Heuristics)
    double oldScore = _evaluateGrid(oldGrid, rows, cols);
    double newScore = _evaluateGrid(newGrid, rows, cols);

    // 3. Line Bonus (Exponential: 1->100, 2->300, 3->600...)
    double clearBonus = 0;
    if (linesCleared > 0) {
      clearBonus = pow(linesCleared, 1.6) * _wLines;
      reasons.add("$linesCleared lines cleared! 🔥");
    }

    // 4. Survival Check (Most critical)
    // Could 3x3 fit before? Can it fit now?
    bool couldFit3x3Old = _canFitShape(oldGrid, 3, 3);
    bool canFit3x3New = _canFitShape(newGrid, 3, 3);

    // If there was space for big blocks before, but not now -> Big penalty
    double survivalPenalty = 0;
    if (couldFit3x3Old && !canFit3x3New && linesCleared == 0) {
      survivalPenalty = -300.0;
      reasons.add("No space for large blocks! ⚠️");
    }

    // Final score change
    double scoreDiff = (newScore - oldScore) + clearBonus + survivalPenalty;

    // 5. Determine Quality
    MoveQuality quality;
    String message;

    if (scoreDiff >= 150) {
      quality = MoveQuality.best;
    } else if (scoreDiff >= 30) {
      quality = MoveQuality.good;
    } else if (scoreDiff >= -30) {
      quality = MoveQuality.neutral;
    } else if (scoreDiff >= -150) {
      quality = MoveQuality.bad;
    } else {
      quality = MoveQuality.blunder;
    }

    // If "Survival" check fails, force downgrade
    if (!canFit3x3New && quality != MoveQuality.blunder && linesCleared == 0) {
      quality = MoveQuality.bad; // At least bad
      message = "Dangerous Situation!";
    } else {
      message = _getMessage(quality, linesCleared);
    }

    return MoveAnalysisResult(
      quality: quality,
      message: message,
      scoreDelta: scoreDiff,
      reasons: reasons,
    );
  }

  // --- GRID ANALYSIS LOGIC ---

  double _evaluateGrid(List<List<GridCell>> grid, int rows, int cols) {
    int holes = 0;
    int bumpiness = 0;
    int fragments = 0;
    double centerBonus = 0;

    List<int> colHeights = List.filled(cols, 0);

    // 1. Column Heights and Holes
    for (int x = 0; x < cols; x++) {
      bool blockFound = false;
      for (int y = 0; y < rows; y++) {
        if (grid[y][x].occupied) {
          if (!blockFound) {
            colHeights[x] = rows - y;
            blockFound = true;
          }
        } else if (blockFound) {
          // Empty cell below a block = Hole
          holes++;
        }
      }
    }

    // 2. Bumpiness
    // Difference between adjacent columns
    for (int x = 0; x < cols - 1; x++) {
      bumpiness += (colHeights[x] - colHeights[x + 1]).abs();
    }

    // 3. Fragmentation (Checkerboard effect)
    // Isolated empty cells or isolated blocks
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        if (!grid[y][x].occupied) {
          // Is this empty cell surrounded?
          int occupiedNeighbors = 0;
          if (x > 0 && grid[y][x - 1].occupied) occupiedNeighbors++;
          if (x < cols - 1 && grid[y][x + 1].occupied) occupiedNeighbors++;
          if (y > 0 && grid[y - 1][x].occupied) occupiedNeighbors++;
          if (y < rows - 1 && grid[y + 1][x].occupied) occupiedNeighbors++;

          if (occupiedNeighbors >= 3) {
            fragments++; // Hard to access cell
          }
        }
      }
    }

    // 4. Center Control
    // Good to keep center empty for big blocks
    // Check 3x3 center zone
    int centerStartR = (rows / 2).floor() - 1;
    int centerStartC = (cols / 2).floor() - 1;
    for (int r = centerStartR; r < centerStartR + 3; r++) {
      for (int c = centerStartC; c < centerStartC + 3; c++) {
        if (r >= 0 && r < rows && c >= 0 && c < cols) {
          if (!grid[r][c].occupied) centerBonus += 1.0;
        }
      }
    }

    return (holes * _wHoles) +
        (bumpiness * _wBumpiness) +
        (fragments * _wFragmentation) +
        (centerBonus * _wCenterControl);
  }

  // --- SURVIVAL CHECK ---

  // Can a shape of size (w x h) fit on the board?
  bool _canFitShape(List<List<GridCell>> grid, int width, int height) {
    int rows = grid.length;
    int cols = grid[0].length;

    for (int r = 0; r <= rows - height; r++) {
      for (int c = 0; c <= cols - width; c++) {
        // Check from this point
        bool fits = true;
        for (int i = 0; i < height; i++) {
          for (int j = 0; j < width; j++) {
            if (grid[r + i][c + j].occupied) {
              fits = false;
              break;
            }
          }
          if (!fits) break;
        }
        if (fits) return true; // Found at least one spot
      }
    }
    return false;
  }

  String _getMessage(MoveQuality quality, int lines) {
    final random = Random();

    switch (quality) {
      case MoveQuality.best:
        if (lines > 1) {
          final comboMessages = [
            "Combo Master! 🔥",
            "Incredible Combo! 💥",
            "Amazing Chain! ⚡",
            "Legendary Move! 🌟",
            "Multi-Clear! 🎯",
            "Perfect Combo! ✨",
            "Unstoppable! 🚀",
          ];
          return comboMessages[random.nextInt(comboMessages.length)];
        } else {
          final perfectMessages = [
            "Perfect Placement! ⭐",
            "Brilliant Move! 💎",
            "Flawless! ✨",
            "Masterpiece! 🎨",
            "Genius! 🧠",
            "Spectacular! 🌟",
          ];
          return perfectMessages[random.nextInt(perfectMessages.length)];
        }

      case MoveQuality.good:
        final goodMessages = [
          "Good Move ✅",
          "Nice Play! 👍",
          "Well Done! 💪",
          "Smart Choice! 🎯",
          "Solid Move! ⚡",
          "Great Job! 🌟",
          "Keep It Up! 🔥",
        ];
        return goodMessages[random.nextInt(goodMessages.length)];

      case MoveQuality.neutral:
        final neutralMessages = [
          "Not Bad 😐",
          "Acceptable 👌",
          "Decent Move 🙂",
          "Fair Enough 😌",
          "Could Be Better 🤔",
        ];
        return neutralMessages[random.nextInt(neutralMessages.length)];

      case MoveQuality.bad:
        final badMessages = [
          "Holes Created 📉",
          "Risky Move ⚠️",
          "Be Careful! 😬",
          "Watch Out! 👀",
          "Tricky Spot 🤨",
          "Not Ideal 😕",
        ];
        return badMessages[random.nextInt(badMessages.length)];

      case MoveQuality.blunder:
        final blunderMessages = [
          "Game Over Risk! 🚫",
          "Danger Zone! ⛔",
          "Critical Error! 🆘",
          "Very Risky! ❌",
          "Watch Out! 🚨",
          "Bad Situation! ⚠️",
        ];
        return blunderMessages[random.nextInt(blunderMessages.length)];
    }
  }
}
