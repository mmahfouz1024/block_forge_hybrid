import 'dart:math';
import 'package:flutter/material.dart';

enum BlockColor {
  cyan,
  amber,
  rose,
  emerald,
  violet,
  blue,
}

extension BlockColorPalette on BlockColor {
  Color get base {
    switch (this) {
      case BlockColor.cyan:
        return const Color(0xFF06B6D4);
      case BlockColor.amber:
        return const Color(0xFFF59E0B);
      case BlockColor.rose:
        return const Color(0xFFF43F5E);
      case BlockColor.emerald:
        return const Color(0xFF10B981);
      case BlockColor.violet:
        return const Color(0xFF8B5CF6);
      case BlockColor.blue:
        return const Color(0xFF3B82F6);
    }
  }

  Color get highlight {
    switch (this) {
      case BlockColor.cyan:
        return const Color(0xFF67E8F9);
      case BlockColor.amber:
        return const Color(0xFFFDE047);
      case BlockColor.rose:
        return const Color(0xFFFDA4AF);
      case BlockColor.emerald:
        return const Color(0xFF6EE7B7);
      case BlockColor.violet:
        return const Color(0xFFC4B5FD);
      case BlockColor.blue:
        return const Color(0xFF93C5FD);
    }
  }

  Color get shadow {
    switch (this) {
      case BlockColor.cyan:
        return const Color(0xFF0E7490);
      case BlockColor.amber:
        return const Color(0xFFB45309);
      case BlockColor.rose:
        return const Color(0xFFBE123C);
      case BlockColor.emerald:
        return const Color(0xFF047857);
      case BlockColor.violet:
        return const Color(0xFF5B21B6);
      case BlockColor.blue:
        return const Color(0xFF1D4ED8);
    }
  }
}

class BlockShape {
  final String id;
  final List<List<int>> matrix;
  final BlockColor color;
  final int weight;

  const BlockShape({
    required this.id,
    required this.matrix,
    required this.color,
    this.weight = 10,
  });

  int get rows => matrix.length;
  int get cols => matrix[0].length;

  int get cellCount {
    var count = 0;
    for (final row in matrix) {
      for (final cell in row) {
        if (cell == 1) count++;
      }
    }
    return count;
  }

  BlockShape withColor(BlockColor newColor) => BlockShape(
        id: id,
        matrix: matrix,
        color: newColor,
        weight: weight,
      );
}

class BlockShapes {
  static const List<BlockShape> templates = [
    BlockShape(id: 'dot_1', matrix: [[1]], color: BlockColor.cyan, weight: 8),
    BlockShape(id: 'bar_2h', matrix: [[1, 1]], color: BlockColor.blue, weight: 12),
    BlockShape(id: 'bar_2v', matrix: [[1], [1]], color: BlockColor.blue, weight: 12),
    BlockShape(id: 'bar_3h', matrix: [[1, 1, 1]], color: BlockColor.emerald, weight: 14),
    BlockShape(id: 'bar_3v', matrix: [[1], [1], [1]], color: BlockColor.emerald, weight: 14),
    BlockShape(id: 'bar_4h', matrix: [[1, 1, 1, 1]], color: BlockColor.amber, weight: 9),
    BlockShape(id: 'bar_4v', matrix: [[1], [1], [1], [1]], color: BlockColor.amber, weight: 9),
    BlockShape(id: 'bar_5h', matrix: [[1, 1, 1, 1, 1]], color: BlockColor.rose, weight: 5),
    BlockShape(id: 'bar_5v', matrix: [[1], [1], [1], [1], [1]], color: BlockColor.rose, weight: 5),
    BlockShape(
      id: 'sq_2',
      matrix: [
        [1, 1],
        [1, 1],
      ],
      color: BlockColor.amber,
      weight: 16,
    ),
    BlockShape(
      id: 'sq_3',
      matrix: [
        [1, 1, 1],
        [1, 1, 1],
        [1, 1, 1],
      ],
      color: BlockColor.violet,
      weight: 6,
    ),
    BlockShape(
      id: 'l_small_1',
      matrix: [
        [1, 0],
        [1, 1],
      ],
      color: BlockColor.rose,
      weight: 13,
    ),
    BlockShape(
      id: 'l_small_2',
      matrix: [
        [0, 1],
        [1, 1],
      ],
      color: BlockColor.rose,
      weight: 13,
    ),
    BlockShape(
      id: 'l_small_3',
      matrix: [
        [1, 1],
        [1, 0],
      ],
      color: BlockColor.cyan,
      weight: 13,
    ),
    BlockShape(
      id: 'l_small_4',
      matrix: [
        [1, 1],
        [0, 1],
      ],
      color: BlockColor.cyan,
      weight: 13,
    ),
    BlockShape(
      id: 'l_big_1',
      matrix: [
        [1, 0, 0],
        [1, 0, 0],
        [1, 1, 1],
      ],
      color: BlockColor.violet,
      weight: 7,
    ),
    BlockShape(
      id: 'l_big_2',
      matrix: [
        [0, 0, 1],
        [0, 0, 1],
        [1, 1, 1],
      ],
      color: BlockColor.violet,
      weight: 7,
    ),
    BlockShape(
      id: 'l_big_3',
      matrix: [
        [1, 1, 1],
        [1, 0, 0],
        [1, 0, 0],
      ],
      color: BlockColor.blue,
      weight: 7,
    ),
    BlockShape(
      id: 'l_big_4',
      matrix: [
        [1, 1, 1],
        [0, 0, 1],
        [0, 0, 1],
      ],
      color: BlockColor.blue,
      weight: 7,
    ),
    BlockShape(
      id: 't_up',
      matrix: [
        [0, 1, 0],
        [1, 1, 1],
      ],
      color: BlockColor.emerald,
      weight: 10,
    ),
    BlockShape(
      id: 't_down',
      matrix: [
        [1, 1, 1],
        [0, 1, 0],
      ],
      color: BlockColor.emerald,
      weight: 10,
    ),
    BlockShape(
      id: 'z_1',
      matrix: [
        [1, 1, 0],
        [0, 1, 1],
      ],
      color: BlockColor.amber,
      weight: 8,
    ),
    BlockShape(
      id: 's_1',
      matrix: [
        [0, 1, 1],
        [1, 1, 0],
      ],
      color: BlockColor.cyan,
      weight: 8,
    ),
  ];

  static BlockShape randomWeighted(Random rng) {
    final totalWeight = templates.fold<int>(0, (sum, s) => sum + s.weight);
    var roll = rng.nextInt(totalWeight);
    for (final shape in templates) {
      roll -= shape.weight;
      if (roll < 0) {
        final randomColor = BlockColor.values[rng.nextInt(BlockColor.values.length)];
        return shape.withColor(randomColor);
      }
    }
    return templates.first;
  }
}

class BoardCell {
  bool occupied;
  BlockColor? color;
  int iceHits;
  bool hasGem;

  BoardCell({
    this.occupied = false,
    this.color,
    this.iceHits = 0,
    this.hasGem = false,
  });

  bool get isIce => iceHits > 0;

  BoardCell copy() => BoardCell(
        occupied: occupied,
        color: color,
        iceHits: iceHits,
        hasGem: hasGem,
      );
}

enum GameMode { classic, adventure }

enum BoosterType { none, bomb, hammer }

class AdventureLevel {
  final int levelNumber;
  final int targetScore;
  final int targetGems;
  final int targetIce;
  final int rewardGems;
  final String titleEn;
  final String titleAr;

  const AdventureLevel({
    required this.levelNumber,
    required this.targetScore,
    required this.targetGems,
    required this.targetIce,
    required this.rewardGems,
    required this.titleEn,
    required this.titleAr,
  });
}

class AdventureLevels {
  static const int totalLevels = 30;

  static AdventureLevel getLevel(int level) {
    final clamped = level.clamp(1, totalLevels);
    final chapter = ((clamped - 1) ~/ 6) + 1;
    final chapterTitlesEn = [
      'Sunlit Courtyard',
      'Crystal Cavern',
      'Frost Citadel',
      'Skyward Spire',
      'Royal Sanctum',
    ];
    final chapterTitlesAr = [
      'ساحة القلعة المشمسة',
      'كهف الكريستال',
      'حصن الجليد',
      'برج السماء',
      'العرش الملكي',
    ];

    final targetScore = 350 + (clamped - 1) * 180;
    final targetGems = clamped >= 2 ? (2 + (clamped ~/ 4)).clamp(2, 10) : 0;
    final targetIce = clamped >= 3 ? (2 + ((clamped - 2) ~/ 2)).clamp(2, 16) : 0;
    final rewardGems = 15 + clamped * 3;

    return AdventureLevel(
      levelNumber: clamped,
      targetScore: targetScore,
      targetGems: targetGems,
      targetIce: targetIce,
      rewardGems: rewardGems,
      titleEn: '${chapterTitlesEn[chapter - 1]} #$clamped',
      titleAr: '${chapterTitlesAr[chapter - 1]} #$clamped',
    );
  }

  /// Populates deterministic starter ice blocks and gems for a given level.
  static void seedBoardForLevel(List<List<BoardCell>> grid, int levelNumber) {
    final level = getLevel(levelNumber);
    final rng = Random(levelNumber * 7919);

    // Symmetric preset ice blocks in middle rows so the player starts with puzzle tension.
    var icePlaced = 0;
    final candidateCoords = <(int, int)>[];
    for (var r = 1; r <= 6; r++) {
      for (var c = 1; c <= 6; c++) {
        candidateCoords.add((r, c));
      }
    }
    candidateCoords.shuffle(rng);

    for (final (r, c) in candidateCoords) {
      if (icePlaced >= level.targetIce) break;
      final cell = grid[r][c];
      if (!cell.occupied) {
        cell.occupied = true;
        cell.color = BlockColor.cyan;
        cell.iceHits = levelNumber >= 12 ? 2 : 1;
        icePlaced++;
      }
    }

    // Place initial gems on some free or iced cells (prefer empty or pre-filled blocks).
    var gemsToSeed = (level.targetGems / 2).ceil().clamp(0, 4);
    for (final (r, c) in candidateCoords.reversed) {
      if (gemsToSeed <= 0) break;
      final cell = grid[r][c];
      if (!cell.occupied) {
        cell.occupied = true;
        cell.color = BlockColor.amber;
        cell.hasGem = true;
        gemsToSeed--;
      }
    }
  }
}

class KingdomBuilding {
  final String id;
  final String nameEn;
  final String nameAr;
  final String descEn;
  final String descAr;
  final int maxLevel;
  final int baseCost;
  final IconData icon;
  final Color accentColor;

  const KingdomBuilding({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.descEn,
    required this.descAr,
    this.maxLevel = 5,
    required this.baseCost,
    required this.icon,
    required this.accentColor,
  });

  int costForNextLevel(int currentLevel) => baseCost * (currentLevel + 1);
}

class KingdomCatalog {
  static const List<KingdomBuilding> buildings = [
    KingdomBuilding(
      id: 'forge_keep',
      nameEn: 'Forge Keep',
      nameAr: 'قلعة الحدادة',
      descEn: '+5% Score Bonus per level',
      descAr: 'زيادة +5% في النقاط لكل مستوى',
      baseCost: 25,
      icon: Icons.fort,
      accentColor: Color(0xFFF59E0B),
    ),
    KingdomBuilding(
      id: 'crystal_mine',
      nameEn: 'Crystal Mine',
      nameAr: 'منجم الجواهر',
      descEn: 'Higher gem spawn rate on board',
      descAr: 'زيادة فرصة ظهور الجواهر على الرقعة',
      baseCost: 30,
      icon: Icons.diamond,
      accentColor: Color(0xFF06B6D4),
    ),
    KingdomBuilding(
      id: 'sky_tower',
      nameEn: 'Sky Watchtower',
      nameAr: 'برج المراقبة',
      descEn: 'Extra Combo Streak bonus points',
      descAr: 'نقاط إضافية عند تحقيق سلاسل الكومبو',
      baseCost: 35,
      icon: Icons.castle,
      accentColor: Color(0xFF8B5CF6),
    ),
    KingdomBuilding(
      id: 'arcane_hall',
      nameEn: 'Arcane Workshop',
      nameAr: 'ورشة التعزيزات',
      descEn: 'Bonus starting boosters & daily gems',
      descAr: 'مكافآت يومية أكبر وخصم على الأدوات',
      baseCost: 40,
      icon: Icons.auto_awesome,
      accentColor: Color(0xFF10B981),
    ),
  ];
}

enum QuestType { clearLines, reachCombo, playGames, collectGems }

class DailyQuest {
  final String id;
  final String titleEn;
  final String titleAr;
  final QuestType type;
  final int target;
  int progress;
  final int rewardGems;
  bool claimed;

  DailyQuest({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.type,
    required this.target,
    this.progress = 0,
    required this.rewardGems,
    this.claimed = false,
  });

  bool get isCompleted => progress >= target;

  Map<String, dynamic> toJson() => {
        'id': id,
        'titleEn': titleEn,
        'titleAr': titleAr,
        'type': type.name,
        'target': target,
        'progress': progress,
        'rewardGems': rewardGems,
        'claimed': claimed,
      };

  factory DailyQuest.fromJson(Map<String, dynamic> json) => DailyQuest(
        id: json['id'] as String,
        titleEn: json['titleEn'] as String,
        titleAr: json['titleAr'] as String,
        type: QuestType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => QuestType.clearLines,
        ),
        target: json['target'] as int,
        progress: json['progress'] as int? ?? 0,
        rewardGems: json['rewardGems'] as int,
        claimed: json['claimed'] as bool? ?? false,
      );
}

class PlayerProfile {
  int gems;
  int stars;
  int highScoreClassic;
  int highestCombo;
  int totalLinesCleared;
  int unlockedLevel;
  Map<int, int> levelStars;
  Map<String, int> buildingLevels;
  int bombCount;
  int hammerCount;
  int refreshCount;
  bool soundEnabled;
  bool hapticsEnabled;
  bool isArabic;
  String lastQuestDate;
  List<DailyQuest> dailyQuests;

  PlayerProfile({
    this.gems = 60,
    this.stars = 0,
    this.highScoreClassic = 0,
    this.highestCombo = 0,
    this.totalLinesCleared = 0,
    this.unlockedLevel = 1,
    Map<int, int>? levelStars,
    Map<String, int>? buildingLevels,
    this.bombCount = 2,
    this.hammerCount = 2,
    this.refreshCount = 3,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.isArabic = true,
    this.lastQuestDate = '',
    List<DailyQuest>? dailyQuests,
  })  : levelStars = levelStars ?? {},
        buildingLevels = buildingLevels ??
            {
              'forge_keep': 1,
              'crystal_mine': 0,
              'sky_tower': 0,
              'arcane_hall': 0,
            },
        dailyQuests = dailyQuests ?? defaultQuests();

  static List<DailyQuest> defaultQuests() => [
        DailyQuest(
          id: 'q_lines',
          titleEn: 'Clear 12 lines',
          titleAr: 'امسح 12 صفاً أو عموداً',
          type: QuestType.clearLines,
          target: 12,
          rewardGems: 25,
        ),
        DailyQuest(
          id: 'q_combo',
          titleEn: 'Reach a 3x Combo',
          titleAr: 'حقق كومبو 3x أو أعلى',
          type: QuestType.reachCombo,
          target: 3,
          rewardGems: 30,
        ),
        DailyQuest(
          id: 'q_games',
          titleEn: 'Complete 2 rounds',
          titleAr: 'العب جولتين كاملتين',
          type: QuestType.playGames,
          target: 2,
          rewardGems: 20,
        ),
      ];

  double get scoreMultiplier {
    final keepLv = buildingLevels['forge_keep'] ?? 0;
    return 1.0 + keepLv * 0.05;
  }

  double get gemSpawnChance {
    final mineLv = buildingLevels['crystal_mine'] ?? 0;
    return 0.14 + mineLv * 0.04;
  }

  int get extraComboPoints => (buildingLevels['sky_tower'] ?? 0) * 15;

  int get totalKingdomLevel => buildingLevels.values.fold(0, (a, b) => a + b);

  Map<String, dynamic> toJson() => {
        'gems': gems,
        'stars': stars,
        'highScoreClassic': highScoreClassic,
        'highestCombo': highestCombo,
        'totalLinesCleared': totalLinesCleared,
        'unlockedLevel': unlockedLevel,
        'levelStars': levelStars.map((k, v) => MapEntry(k.toString(), v)),
        'buildingLevels': buildingLevels,
        'bombCount': bombCount,
        'hammerCount': hammerCount,
        'refreshCount': refreshCount,
        'soundEnabled': soundEnabled,
        'hapticsEnabled': hapticsEnabled,
        'isArabic': isArabic,
        'lastQuestDate': lastQuestDate,
        'dailyQuests': dailyQuests.map((q) => q.toJson()).toList(),
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final rawStars = (json['levelStars'] as Map<String, dynamic>?) ?? {};
    final parsedStars = <int, int>{};
    rawStars.forEach((k, v) {
      final parsedKey = int.tryParse(k);
      if (parsedKey != null && v is int) parsedStars[parsedKey] = v;
    });

    final rawBuildings = (json['buildingLevels'] as Map<String, dynamic>?) ?? {};
    final parsedBuildings = <String, int>{
      'forge_keep': 1,
      'crystal_mine': 0,
      'sky_tower': 0,
      'arcane_hall': 0,
    };
    rawBuildings.forEach((k, v) {
      if (v is int) parsedBuildings[k] = v;
    });

    final rawQuests = json['dailyQuests'] as List<dynamic>?;
    final parsedQuests = rawQuests != null
        ? rawQuests.map((e) => DailyQuest.fromJson(e as Map<String, dynamic>)).toList()
        : defaultQuests();

    return PlayerProfile(
      gems: json['gems'] as int? ?? 60,
      stars: json['stars'] as int? ?? 0,
      highScoreClassic: json['highScoreClassic'] as int? ?? 0,
      highestCombo: json['highestCombo'] as int? ?? 0,
      totalLinesCleared: json['totalLinesCleared'] as int? ?? 0,
      unlockedLevel: json['unlockedLevel'] as int? ?? 1,
      levelStars: parsedStars,
      buildingLevels: parsedBuildings,
      bombCount: json['bombCount'] as int? ?? 2,
      hammerCount: json['hammerCount'] as int? ?? 2,
      refreshCount: json['refreshCount'] as int? ?? 3,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      isArabic: json['isArabic'] as bool? ?? true,
      lastQuestDate: json['lastQuestDate'] as String? ?? '',
      dailyQuests: parsedQuests,
    );
  }
}
