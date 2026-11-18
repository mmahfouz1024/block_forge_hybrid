import 'dart:math';
import '../models/game_models.dart';

class MoveResult {
  final bool placed;
  final int pointsEarned;
  final int linesCleared;
  final int gemsEarned;
  final int iceCracked;
  final int comboStreak;
  final List<int> clearedRows;
  final List<int> clearedCols;
  final List<(int, int)> clearedCoords;

  const MoveResult({
    required this.placed,
    this.pointsEarned = 0,
    this.linesCleared = 0,
    this.gemsEarned = 0,
    this.iceCracked = 0,
    this.comboStreak = 0,
    this.clearedRows = const [],
    this.clearedCols = const [],
    this.clearedCoords = const [],
  });
}

class PreviewClear {
  final Set<int> rows;
  final Set<int> cols;
  const PreviewClear(this.rows, this.cols);

  bool get hasClears => rows.isNotEmpty || cols.isNotEmpty;
}

class BoardEngine {
  static const int gridSize = 8;

  late List<List<BoardCell>> grid;
  List<BlockShape?> tray = [null, null, null];

  int score = 0;
  int combo = 0;
  int maxCombo = 0;
  int linesClearedTotal = 0;
  int gemsCollectedInRun = 0;
  int iceCrackedInRun = 0;

  final GameMode mode;
  final AdventureLevel? level;
  final double scoreMultiplier;
  final double gemSpawnChance;
  final int extraComboPoints;
  final Random _rng;

  BoardEngine({
    this.mode = GameMode.classic,
    this.level,
    this.scoreMultiplier = 1.0,
    this.gemSpawnChance = 0.14,
    this.extraComboPoints = 0,
    Random? rng,
  }) : _rng = rng ?? Random() {
    reset();
  }

  void reset() {
    grid = List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => BoardCell()),
    );
    score = 0;
    combo = 0;
    maxCombo = 0;
    linesClearedTotal = 0;
    gemsCollectedInRun = 0;
    iceCrackedInRun = 0;

    if (mode == GameMode.adventure && level != null) {
      AdventureLevels.seedBoardForLevel(grid, level!.levelNumber);
    }

    generateTray();
  }

  bool canPlace(BlockShape shape, int startRow, int startCol) {
    for (var r = 0; r < shape.rows; r++) {
      for (var c = 0; c < shape.cols; c++) {
        if (shape.matrix[r][c] == 1) {
          final targetR = startRow + r;
          final targetC = startCol + c;
          if (targetR < 0 ||
              targetR >= gridSize ||
              targetC < 0 ||
              targetC >= gridSize) {
            return false;
          }
          if (grid[targetR][targetC].occupied) {
            return false;
          }
        }
      }
    }
    return true;
  }

  bool canPlaceAnywhere(BlockShape shape) {
    for (var r = 0; r <= gridSize - shape.rows; r++) {
      for (var c = 0; c <= gridSize - shape.cols; c++) {
        if (canPlace(shape, r, c)) return true;
      }
    }
    return false;
  }

  bool get hasAnyValidMove {
    for (final shape in tray) {
      if (shape != null && canPlaceAnywhere(shape)) {
        return true;
      }
    }
    return false;
  }

  bool get isTrayEmpty => tray.every((s) => s == null);

  bool get isAdventureLevelWon {
    if (mode != GameMode.adventure || level == null) return false;
    return score >= level!.targetScore &&
        gemsCollectedInRun >= level!.targetGems &&
        iceCrackedInRun >= level!.targetIce;
  }

  PreviewClear findPreviewClears(BlockShape shape, int startRow, int startCol) {
    if (!canPlace(shape, startRow, startCol)) {
      return const PreviewClear({}, {});
    }

    final occupiedAfter = <(int, int)>{};
    for (var r = 0; r < shape.rows; r++) {
      for (var c = 0; c < shape.cols; c++) {
        if (shape.matrix[r][c] == 1) {
          occupiedAfter.add((startRow + r, startCol + c));
        }
      }
    }

    final fullRows = <int>{};
    final fullCols = <int>{};

    for (var r = 0; r < gridSize; r++) {
      var full = true;
      for (var c = 0; c < gridSize; c++) {
        if (!grid[r][c].occupied && !occupiedAfter.contains((r, c))) {
          full = false;
          break;
        }
      }
      if (full) fullRows.add(r);
    }

    for (var c = 0; c < gridSize; c++) {
      var full = true;
      for (var r = 0; r < gridSize; r++) {
        if (!grid[r][c].occupied && !occupiedAfter.contains((r, c))) {
          full = false;
          break;
        }
      }
      if (full) fullCols.add(c);
    }

    return PreviewClear(fullRows, fullCols);
  }

  MoveResult placeFromTray(int trayIndex, int startRow, int startCol) {
    if (trayIndex < 0 || trayIndex >= tray.length) {
      return const MoveResult(placed: false);
    }
    final shape = tray[trayIndex];
    if (shape == null || !canPlace(shape, startRow, startCol)) {
      return const MoveResult(placed: false);
    }

    // Place cells onto board.
    final placedCoords = <(int, int)>[];
    for (var r = 0; r < shape.rows; r++) {
      for (var c = 0; c < shape.cols; c++) {
        if (shape.matrix[r][c] == 1) {
          final tr = startRow + r;
          final tc = startCol + c;
          grid[tr][tc].occupied = true;
          grid[tr][tc].color = shape.color;
          placedCoords.add((tr, tc));
        }
      }
    }

    // Occasionally spawn a Forge Gem on one of the placed cells.
    if (placedCoords.isNotEmpty && _rng.nextDouble() < gemSpawnChance) {
      final pick = placedCoords[_rng.nextInt(placedCoords.length)];
      grid[pick.$1][pick.$2].hasGem = true;
    }

    tray[trayIndex] = null;

    // Detect full rows and columns.
    final fullRows = <int>[];
    final fullCols = <int>[];

    for (var r = 0; r < gridSize; r++) {
      if (grid[r].every((cell) => cell.occupied)) {
        fullRows.add(r);
      }
    }

    for (var c = 0; c < gridSize; c++) {
      var full = true;
      for (var r = 0; r < gridSize; r++) {
        if (!grid[r][c].occupied) {
          full = false;
          break;
        }
      }
      if (full) fullCols.add(c);
    }

    final linesCount = fullRows.length + fullCols.length;
    var gemsEarned = 0;
    var iceCracked = 0;
    final clearedSet = <(int, int)>{};

    if (linesCount > 0) {
      for (final r in fullRows) {
        for (var c = 0; c < gridSize; c++) {
          clearedSet.add((r, c));
        }
      }
      for (final c in fullCols) {
        for (var r = 0; r < gridSize; r++) {
          clearedSet.add((r, c));
        }
      }

      for (final (r, c) in clearedSet) {
        final cell = grid[r][c];
        if (cell.hasGem) {
          gemsEarned++;
          cell.hasGem = false;
        }
        if (cell.iceHits > 0) {
          cell.iceHits--;
          if (cell.iceHits == 0) {
            iceCracked++;
            cell.occupied = false;
            cell.color = null;
          }
        } else {
          cell.occupied = false;
          cell.color = null;
        }
      }

      combo += 1;
      if (combo > maxCombo) maxCombo = combo;
      linesClearedTotal += linesCount;
      gemsCollectedInRun += gemsEarned;
      iceCrackedInRun += iceCracked;
    } else {
      combo = 0;
    }

    final basePlacePoints = shape.cellCount * 10;
    final clearPoints = linesCount > 0
        ? (linesCount * 100 * combo) +
            (linesCount > 1 ? (linesCount - 1) * 60 : 0) +
            (combo > 1 ? extraComboPoints : 0)
        : 0;
    final totalEarned = ((basePlacePoints + clearPoints) * scoreMultiplier).round();
    score += totalEarned;

    if (isTrayEmpty) {
      generateTray();
    }

    return MoveResult(
      placed: true,
      pointsEarned: totalEarned,
      linesCleared: linesCount,
      gemsEarned: gemsEarned,
      iceCracked: iceCracked,
      comboStreak: combo,
      clearedRows: fullRows,
      clearedCols: fullCols,
      clearedCoords: clearedSet.toList(),
    );
  }

  /// Generates 3 fresh tray shapes, guaranteeing at least 1 fits if possible.
  void generateTray() {
    final next = <BlockShape>[
      BlockShapes.randomWeighted(_rng),
      BlockShapes.randomWeighted(_rng),
      BlockShapes.randomWeighted(_rng),
    ];

    if (!next.any(canPlaceAnywhere)) {
      // Find a playable template so the player gets a fair chance when space remains.
      final fitting = BlockShapes.templates.where(canPlaceAnywhere).toList();
      if (fitting.isNotEmpty) {
        final pick = fitting[_rng.nextInt(fitting.length)];
        final color = BlockColor.values[_rng.nextInt(BlockColor.values.length)];
        next[0] = pick.withColor(color);
      }
    }

    tray = [next[0], next[1], next[2]];
  }

  /// Clears a 3x3 area around (centerRow, centerCol). Returns cleared cell count.
  int applyBomb(int centerRow, int centerCol) {
    var cleared = 0;
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        final r = centerRow + dr;
        final c = centerCol + dc;
        if (r >= 0 && r < gridSize && c >= 0 && c < gridSize) {
          final cell = grid[r][c];
          if (cell.occupied) {
            if (cell.hasGem) gemsCollectedInRun++;
            if (cell.iceHits > 0) iceCrackedInRun++;
            cell.occupied = false;
            cell.color = null;
            cell.iceHits = 0;
            cell.hasGem = false;
            cleared++;
          }
        }
      }
    }
    score += cleared * 15;
    return cleared;
  }

  /// Smashes a single occupied cell at (row, col).
  bool applyHammer(int row, int col) {
    if (row < 0 || row >= gridSize || col < 0 || col >= gridSize) return false;
    final cell = grid[row][col];
    if (!cell.occupied) return false;
    if (cell.hasGem) gemsCollectedInRun++;
    if (cell.iceHits > 0) iceCrackedInRun++;
    cell.occupied = false;
    cell.color = null;
    cell.iceHits = 0;
    cell.hasGem = false;
    score += 20;
    return true;
  }

  /// Clears the central 4x4 region to revive a player on Game Over.
  void reviveClearCenter() {
    for (var r = 2; r <= 5; r++) {
      for (var c = 2; c <= 5; c++) {
        final cell = grid[r][c];
        if (cell.iceHits == 0) {
          cell.occupied = false;
          cell.color = null;
          cell.hasGem = false;
        }
      }
    }
    if (!hasAnyValidMove) {
      generateTray();
    }
  }
}
