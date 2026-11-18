import 'dart:ui';
import 'package:flutter/material.dart';
import '../../logic/board_engine.dart';
import '../../models/game_models.dart';
import '../../services/localization_service.dart';
import '../../services/sound_service.dart';
import '../widgets/block_visuals.dart';

class GameScreen extends StatefulWidget {
  final PlayerProfile profile;
  final GameMode mode;
  final int levelNumber;
  final Future<void> Function() onSaveProfile;
  final void Function(int nextLevel)? onOpenNextLevel;

  const GameScreen({
    super.key,
    required this.profile,
    required this.mode,
    this.levelNumber = 1,
    required this.onSaveProfile,
    this.onOpenNextLevel,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late BoardEngine _engine;
  final GlobalKey _boardKey = GlobalKey();

  int? _draggingTrayIndex;
  int? _selectedTrayIndex;
  Offset? _dragGlobalPos;
  PointerDeviceKind _dragDeviceKind = PointerDeviceKind.touch;
  int? _hoverRow;
  int? _hoverCol;
  double _boardCellSize = 40;

  BoosterType _activeBooster = BoosterType.none;
  bool _isGameOver = false;
  bool _isLevelWon = false;
  bool _isNewRecord = false;
  bool _revivedUsed = false;

  String? _bannerText;
  int _bannerKey = 0;
  Set<(int, int)> _flashingCells = {};

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  void _initEngine() {
    final levelData = widget.mode == GameMode.adventure
        ? AdventureLevels.getLevel(widget.levelNumber)
        : null;
    _engine = BoardEngine(
      mode: widget.mode,
      level: levelData,
      scoreMultiplier: widget.profile.scoreMultiplier,
      gemSpawnChance: widget.profile.gemSpawnChance,
      extraComboPoints: widget.profile.extraComboPoints,
    );
    _isGameOver = false;
    _isLevelWon = false;
    _isNewRecord = false;
    _revivedUsed = false;
    _activeBooster = BoosterType.none;
    _selectedTrayIndex = null;
    _draggingTrayIndex = null;
    _bannerText = null;
  }

  double get _dragLiftY => _dragDeviceKind == PointerDeviceKind.mouse ? 0.0 : -56.0;

  void _updateHoverFromGlobal(Offset globalPos) {
    if (_draggingTrayIndex == null) return;
    final shape = _engine.tray[_draggingTrayIndex!];
    if (shape == null) return;

    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final boardSize = box.size.width;
    final cellSize = boardSize / BoardEngine.gridSize;
    _boardCellSize = cellSize;

    final liftedGlobal = globalPos + Offset(0, _dragLiftY);
    final shapeWidth = shape.cols * cellSize;
    final shapeHeight = shape.rows * cellSize;
    final topLeftGlobal = liftedGlobal - Offset(shapeWidth / 2, shapeHeight / 2);
    final localTopLeft = box.globalToLocal(topLeftGlobal);

    final col = ((localTopLeft.dx + cellSize * 0.5) / cellSize).floor();
    final row = ((localTopLeft.dy + cellSize * 0.5) / cellSize).floor();

    if (row >= 0 &&
        col >= 0 &&
        row + shape.rows <= BoardEngine.gridSize &&
        col + shape.cols <= BoardEngine.gridSize &&
        _engine.canPlace(shape, row, col)) {
      if (_hoverRow != row || _hoverCol != col) {
        setState(() {
          _hoverRow = row;
          _hoverCol = col;
        });
      }
    } else if (_hoverRow != null || _hoverCol != null) {
      setState(() {
        _hoverRow = null;
        _hoverCol = null;
      });
    }
  }

  Future<void> _commitMove(int trayIndex, int row, int col) async {
    final result = _engine.placeFromTray(trayIndex, row, col);
    if (!result.placed) return;

    _selectedTrayIndex = null;
    if (result.linesCleared > 0) {
      if (result.comboStreak >= 2) {
        SoundService.instance.playEffect('combo.wav');
        SoundService.instance.heavyHaptic();
      } else {
        SoundService.instance.playEffect('clear.wav');
        SoundService.instance.mediumHaptic();
      }
      _triggerFlash(result.clearedCoords, result);
    } else {
      SoundService.instance.playEffect('place.wav');
      SoundService.instance.lightHaptic();
    }

    await _updateProfileAfterMove(result);
    _checkEndConditions();
    if (mounted) setState(() {});
  }

  void _triggerFlash(List<(int, int)> coords, MoveResult result) {
    final isAr = widget.profile.isArabic;
    final comboLabel = result.comboStreak > 1
        ? '${L10n.tr('combo', isAr)} x${result.comboStreak}! '
        : '';
    setState(() {
      _flashingCells = coords.toSet();
      _bannerText = '$comboLabel+${result.pointsEarned}';
      _bannerKey++;
    });

    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) {
        setState(() {
          _flashingCells = {};
        });
      }
    });
  }

  Future<void> _updateProfileAfterMove(MoveResult result) async {
    widget.profile.gems += result.gemsEarned;
    widget.profile.totalLinesCleared += result.linesCleared;
    if (_engine.maxCombo > widget.profile.highestCombo) {
      widget.profile.highestCombo = _engine.maxCombo;
    }

    if (widget.mode == GameMode.classic && _engine.score > widget.profile.highScoreClassic) {
      widget.profile.highScoreClassic = _engine.score;
      _isNewRecord = true;
    }

    for (final q in widget.profile.dailyQuests) {
      if (q.type == QuestType.clearLines && result.linesCleared > 0) {
        q.progress = (q.progress + result.linesCleared).clamp(0, q.target);
      } else if (q.type == QuestType.reachCombo && result.comboStreak > q.progress) {
        q.progress = result.comboStreak.clamp(0, q.target);
      }
    }

    await widget.onSaveProfile();
  }

  Future<void> _checkEndConditions() async {
    if (_engine.isAdventureLevelWon && !_isLevelWon) {
      _isLevelWon = true;
      SoundService.instance.playEffect('combo.wav');
      SoundService.instance.heavyHaptic();

      final lvl = _engine.level!;
      final earnedStars = _engine.score >= (lvl.targetScore * 1.45)
          ? 3
          : (_engine.score >= (lvl.targetScore * 1.15) ? 2 : 1);
      final prevStars = widget.profile.levelStars[lvl.levelNumber] ?? 0;
      if (earnedStars > prevStars) {
        widget.profile.stars += (earnedStars - prevStars);
        widget.profile.levelStars[lvl.levelNumber] = earnedStars;
      }
      if (lvl.levelNumber >= widget.profile.unlockedLevel &&
          lvl.levelNumber < AdventureLevels.totalLevels) {
        widget.profile.unlockedLevel = lvl.levelNumber + 1;
      }
      widget.profile.gems += lvl.rewardGems;
      _incrementGamesQuest();
      await widget.onSaveProfile();
      if (mounted) setState(() {});
      return;
    }

    if (!_engine.hasAnyValidMove && !_isGameOver) {
      _isGameOver = true;
      SoundService.instance.playEffect('gameover.wav');
      SoundService.instance.heavyHaptic();
      _incrementGamesQuest();
      await widget.onSaveProfile();
      if (mounted) setState(() {});
    }
  }

  void _incrementGamesQuest() {
    for (final q in widget.profile.dailyQuests) {
      if (q.type == QuestType.playGames) {
        q.progress = (q.progress + 1).clamp(0, q.target);
      }
    }
  }

  Future<void> _onBoardTapCell(int r, int c) async {
    if (_isGameOver || _isLevelWon) return;

    if (_activeBooster == BoosterType.bomb) {
      if (widget.profile.bombCount <= 0) return;
      final cleared = _engine.applyBomb(r, c);
      if (cleared > 0) {
        widget.profile.bombCount--;
        SoundService.instance.playEffect('clear.wav');
        SoundService.instance.heavyHaptic();
        _activeBooster = BoosterType.none;
        await widget.onSaveProfile();
        _checkEndConditions();
        setState(() {});
      }
      return;
    }

    if (_activeBooster == BoosterType.hammer) {
      if (widget.profile.hammerCount <= 0) return;
      if (_engine.applyHammer(r, c)) {
        widget.profile.hammerCount--;
        SoundService.instance.playEffect('clear.wav');
        SoundService.instance.mediumHaptic();
        _activeBooster = BoosterType.none;
        await widget.onSaveProfile();
        _checkEndConditions();
        setState(() {});
      }
      return;
    }

    if (_selectedTrayIndex != null) {
      final shape = _engine.tray[_selectedTrayIndex!];
      if (shape != null && _engine.canPlace(shape, r, c)) {
        await _commitMove(_selectedTrayIndex!, r, c);
      }
    }
  }

  Future<void> _handleBoosterTap(BoosterType type) async {
    final isAr = widget.profile.isArabic;
    final count = type == BoosterType.bomb ? widget.profile.bombCount : widget.profile.hammerCount;
    if (count > 0) {
      SoundService.instance.playEffect('click.wav');
      setState(() {
        _activeBooster = _activeBooster == type ? BoosterType.none : type;
      });
      return;
    }
    await _offerBuyBooster(
      isAr: isAr,
      onBuy: () {
        if (type == BoosterType.bomb) widget.profile.bombCount++;
        if (type == BoosterType.hammer) widget.profile.hammerCount++;
      },
    );
  }

  Future<void> _handleRefreshTap() async {
    final isAr = widget.profile.isArabic;
    if (widget.profile.refreshCount > 0) {
      SoundService.instance.playEffect('click.wav');
      widget.profile.refreshCount--;
      _engine.generateTray();
      _selectedTrayIndex = null;
      await widget.onSaveProfile();
      setState(() {});
      return;
    }
    await _offerBuyBooster(
      isAr: isAr,
      onBuy: () {
        widget.profile.refreshCount++;
      },
    );
  }

  Future<void> _offerBuyBooster({required bool isAr, required VoidCallback onBuy}) async {
    if (widget.profile.gems < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.tr('not_enough_gems', isAr)),
          backgroundColor: const Color(0xFFBE123C),
        ),
      );
      return;
    }
    final buy = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131C35),
        title: Text(L10n.tr('buy_booster', isAr), style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(L10n.tr('cancel', isAr)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06B6D4)),
            child: const Text('20 💎', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (buy == true) {
      setState(() {
        widget.profile.gems -= 20;
        onBuy();
      });
      await widget.onSaveProfile();
    }
  }

  Future<void> _reviveWithGems() async {
    final isAr = widget.profile.isArabic;
    if (widget.profile.gems < 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.tr('not_enough_gems', isAr)),
          backgroundColor: const Color(0xFFBE123C),
        ),
      );
      return;
    }
    setState(() {
      widget.profile.gems -= 30;
      _engine.reviveClearCenter();
      _isGameOver = false;
      _revivedUsed = true;
    });
    await widget.onSaveProfile();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.profile.isArabic;
    final draggingShape = _draggingTrayIndex != null ? _engine.tray[_draggingTrayIndex!] : null;

    final previewClear = (draggingShape != null && _hoverRow != null && _hoverCol != null)
        ? _engine.findPreviewClears(draggingShape, _hoverRow!, _hoverCol!)
        : const PreviewClear({}, {});

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1120),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildTopBar(isAr),
                  if (widget.mode == GameMode.adventure && _engine.level != null)
                    _buildAdventureGoalBar(_engine.level!, isAr),
                  if (_activeBooster != BoosterType.none)
                    _buildBoosterPromptBanner(isAr),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _buildBoardGrid(draggingShape, previewClear),
                        ),
                      ),
                    ),
                  ),
                  if (_bannerText != null)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        _bannerText!,
                        key: ValueKey(_bannerKey),
                        style: const TextStyle(
                          color: Color(0xFFFACC15),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        L10n.tr('drag_hint', isAr),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ),
                  const SizedBox(height: 6),
                  _buildTrayRow(),
                  const SizedBox(height: 8),
                  _buildBoosterBar(isAr),
                  const SizedBox(height: 10),
                ],
              ),
              if (draggingShape != null && _dragGlobalPos != null)
                _buildFloatingDragPiece(draggingShape),
              if (_isLevelWon) _buildLevelWonOverlay(isAr),
              if (_isGameOver && !_isLevelWon) _buildGameOverOverlay(isAr),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isAr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ScoreBadge(
                  label: L10n.tr('score', isAr),
                  value: '${_engine.score}',
                  color: const Color(0xFF38BDF8),
                ),
                const SizedBox(width: 10),
                _ScoreBadge(
                  label: L10n.tr('best_score', isAr),
                  value: '${widget.profile.highScoreClassic}',
                  color: const Color(0xFFFACC15),
                ),
                const SizedBox(width: 10),
                _ScoreBadge(
                  label: '💎',
                  value: '${widget.profile.gems}',
                  color: const Color(0xFF34D399),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _initEngine();
              });
            },
            icon: const Icon(Icons.refresh, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildAdventureGoalBar(AdventureLevel lvl, bool isAr) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131C35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            '#${lvl.levelNumber}',
            style: const TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.w900),
          ),
          _GoalChip(
            icon: Icons.star,
            color: const Color(0xFFFACC15),
            text: '${_engine.score}/${lvl.targetScore}',
            done: _engine.score >= lvl.targetScore,
          ),
          if (lvl.targetGems > 0)
            _GoalChip(
              icon: Icons.diamond,
              color: const Color(0xFF38BDF8),
              text: '${_engine.gemsCollectedInRun}/${lvl.targetGems}',
              done: _engine.gemsCollectedInRun >= lvl.targetGems,
            ),
          if (lvl.targetIce > 0)
            _GoalChip(
              icon: Icons.ac_unit,
              color: const Color(0xFFBAE6FD),
              text: '${_engine.iceCrackedInRun}/${lvl.targetIce}',
              done: _engine.iceCrackedInRun >= lvl.targetIce,
            ),
        ],
      ),
    );
  }

  Widget _buildBoosterPromptBanner(bool isAr) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _activeBooster == BoosterType.bomb
                  ? L10n.tr('tap_board_bomb', isAr)
                  : L10n.tr('tap_board_hammer', isAr),
              style: const TextStyle(color: Color(0xFFFDE047), fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _activeBooster = BoosterType.none),
            child: Text(L10n.tr('cancel', isAr)),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardGrid(BlockShape? draggingShape, PreviewClear previewClear) {
    return Container(
      key: _boardKey,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF131C35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellSize = constraints.maxWidth / BoardEngine.gridSize;
          _boardCellSize = cellSize;

          return Column(
            children: List.generate(BoardEngine.gridSize, (r) {
              return Expanded(
                child: Row(
                  children: List.generate(BoardEngine.gridSize, (c) {
                    final cell = _engine.grid[r][c];
                    var isGhost = false;
                    if (draggingShape != null && _hoverRow != null && _hoverCol != null) {
                      final dr = r - _hoverRow!;
                      final dc = c - _hoverCol!;
                      if (dr >= 0 &&
                          dr < draggingShape.rows &&
                          dc >= 0 &&
                          dc < draggingShape.cols &&
                          draggingShape.matrix[dr][dc] == 1) {
                        isGhost = true;
                      }
                    }

                    final willClear =
                        previewClear.rows.contains(r) || previewClear.cols.contains(c);
                    final isFlashing = _flashingCells.contains((r, c));

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _onBoardTapCell(r, c),
                        child: Padding(
                          padding: const EdgeInsets.all(1.8),
                          child: isFlashing
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                )
                              : cell.occupied
                                  ? GlossBlockTile(
                                      color: cell.color ?? BlockColor.cyan,
                                      size: cellSize - 3.6,
                                      iceHits: cell.iceHits,
                                      hasGem: cell.hasGem,
                                      isHighlightClear: willClear,
                                    )
                                  : isGhost && draggingShape != null
                                      ? GlossBlockTile(
                                          color: draggingShape.color,
                                          size: cellSize - 3.6,
                                          isGhost: true,
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            color: ((r + c) % 2 == 0)
                                                ? const Color(0xFF1A2544)
                                                : const Color(0xFF17203B),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildTrayRow() {
    return SizedBox(
      height: 98,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: List.generate(3, (index) {
            final shape = _engine.tray[index];
            final isDragging = _draggingTrayIndex == index;
            final isSelected = _selectedTrayIndex == index;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Listener(
                  onPointerDown: shape == null
                      ? null
                      : (event) {
                          _dragDeviceKind = event.kind;
                        },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: shape == null
                        ? null
                        : () {
                            SoundService.instance.playEffect('click.wav');
                            setState(() {
                              _selectedTrayIndex =
                                  _selectedTrayIndex == index ? null : index;
                            });
                          },
                    onPanStart: shape == null
                        ? null
                        : (details) {
                            SoundService.instance.lightHaptic();
                            setState(() {
                              _draggingTrayIndex = index;
                              _selectedTrayIndex = null;
                              _dragGlobalPos = details.globalPosition;
                            });
                            _updateHoverFromGlobal(details.globalPosition);
                          },
                    onPanUpdate: shape == null
                        ? null
                        : (details) {
                            setState(() {
                              _dragGlobalPos = details.globalPosition;
                            });
                            _updateHoverFromGlobal(details.globalPosition);
                          },
                    onPanEnd: shape == null
                        ? null
                        : (_) async {
                            final targetR = _hoverRow;
                            final targetC = _hoverCol;
                            final idx = _draggingTrayIndex;
                            setState(() {
                              _draggingTrayIndex = null;
                              _dragGlobalPos = null;
                              _hoverRow = null;
                              _hoverCol = null;
                            });
                            if (idx != null && targetR != null && targetC != null) {
                              await _commitMove(idx, targetR, targetC);
                            }
                          },
                    onPanCancel: () {
                      setState(() {
                        _draggingTrayIndex = null;
                        _dragGlobalPos = null;
                        _hoverRow = null;
                        _hoverCol = null;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF131C35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFACC15)
                              : Colors.white10,
                          width: isSelected ? 2.2 : 1.0,
                        ),
                      ),
                      child: Center(
                        child: shape == null || isDragging
                            ? const SizedBox.shrink()
                            : ShapePreviewWidget(
                                shape: shape,
                                cellSize: 17,
                                spacing: 2,
                                opacity: _engine.canPlaceAnywhere(shape) ? 1.0 : 0.35,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildFloatingDragPiece(BlockShape shape) {
    final cell = _boardCellSize > 10 ? _boardCellSize - 3.6 : 36.0;
    final w = shape.cols * (cell + 2.5);
    final h = shape.rows * (cell + 2.5);
    final pos = _dragGlobalPos! + Offset(0, _dragLiftY);
    return Positioned(
      left: pos.dx - w / 2,
      top: pos.dy - h / 2,
      child: IgnorePointer(
        child: ShapePreviewWidget(
          shape: shape,
          cellSize: cell,
          spacing: 2.5,
          opacity: 0.92,
        ),
      ),
    );
  }

  Widget _buildBoosterBar(bool isAr) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BoosterButton(
            icon: Icons.flare,
            label: L10n.tr('bomb', isAr),
            count: widget.profile.bombCount,
            active: _activeBooster == BoosterType.bomb,
            color: const Color(0xFFF43F5E),
            onTap: () => _handleBoosterTap(BoosterType.bomb),
          ),
          _BoosterButton(
            icon: Icons.gavel,
            label: L10n.tr('hammer', isAr),
            count: widget.profile.hammerCount,
            active: _activeBooster == BoosterType.hammer,
            color: const Color(0xFFF59E0B),
            onTap: () => _handleBoosterTap(BoosterType.hammer),
          ),
          _BoosterButton(
            icon: Icons.autorenew,
            label: L10n.tr('refresh', isAr),
            count: widget.profile.refreshCount,
            active: false,
            color: const Color(0xFF06B6D4),
            onTap: _handleRefreshTap,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelWonOverlay(bool isAr) {
    final lvl = _engine.level!;
    final stars = widget.profile.levelStars[lvl.levelNumber] ?? 1;
    final hasNext = lvl.levelNumber < AdventureLevels.totalLevels;
    return _OverlayModal(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, color: Color(0xFFFACC15), size: 58),
          const SizedBox(height: 8),
          Text(
            L10n.tr('level_complete', isAr),
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return Icon(
                i < stars ? Icons.star : Icons.star_border,
                color: const Color(0xFFFACC15),
                size: 36,
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            '+${lvl.rewardGems} 💎',
            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          if (hasNext && widget.onOpenNextLevel != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onOpenNextLevel!(lvl.levelNumber + 1);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(L10n.tr('next_level', isAr), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(L10n.tr('back_home', isAr)),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverOverlay(bool isAr) {
    return _OverlayModal(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sentiment_dissatisfied, color: Color(0xFFF43F5E), size: 52),
          const SizedBox(height: 8),
          Text(
            L10n.tr('game_over', isAr),
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
          ),
          if (_isNewRecord)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                L10n.tr('new_record', isAr),
                style: const TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(height: 10),
          Text(
            '${L10n.tr('score', isAr)}: ${_engine.score}',
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 16),
          if (!_revivedUsed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _reviveWithGems,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.diamond),
                label: Text('${L10n.tr('revive', isAr)} (30 💎)'),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _initEngine();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(L10n.tr('play_again', isAr), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(L10n.tr('back_home', isAr)),
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ScoreBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF131C35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final bool done;

  const _GoalChip({
    required this.icon,
    required this.color,
    required this.text,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(done ? Icons.check_circle : icon, color: done ? const Color(0xFF10B981) : color, size: 17),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: done ? const Color(0xFF6EE7B7) : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _BoosterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _BoosterButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.3) : const Color(0xFF131C35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? color : Colors.white12, width: active ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              '$label ($count)',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayModal extends StatelessWidget {
  final Widget child;
  const _OverlayModal({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: Container(
          width: 310,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF131C35),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white24),
          ),
          child: child,
        ),
      ),
    );
  }
}
