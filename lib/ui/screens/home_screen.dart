import 'package:flutter/material.dart';
import '../../models/game_models.dart';
import '../../services/localization_service.dart';
import '../../services/sound_service.dart';
import '../../services/storage_service.dart';
import 'adventure_map_screen.dart';
import 'game_screen.dart';
import 'kingdom_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  PlayerProfile _profile = PlayerProfile();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await _storage.loadProfile();
    SoundService.instance.soundEnabled = loaded.soundEnabled;
    SoundService.instance.hapticsEnabled = loaded.hapticsEnabled;
    if (mounted) {
      setState(() {
        _profile = loaded;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    await _storage.saveProfile(_profile);
    if (mounted) setState(() {});
  }

  void _openClassic() {
    SoundService.instance.playEffect('click.wav');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          profile: _profile,
          mode: GameMode.classic,
          onSaveProfile: _save,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _openAdventureLevel(int level) {
    SoundService.instance.playEffect('click.wav');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          profile: _profile,
          mode: GameMode.adventure,
          levelNumber: level,
          onSaveProfile: _save,
          onOpenNextLevel: _openAdventureLevel,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _openAdventureMap() {
    SoundService.instance.playEffect('click.wav');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdventureMapScreen(
          profile: _profile,
          onSelectLevel: _openAdventureLevel,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _openKingdom() {
    SoundService.instance.playEffect('click.wav');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KingdomScreen(
          profile: _profile,
          onSave: _save,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _showQuestsSheet() {
    final isAr = _profile.isArabic;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131C35),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    L10n.tr('daily_quests', isAr),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ..._profile.dailyQuests.map((q) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr ? q.titleAr : q.titleEn,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${q.progress}/${q.target}',
                                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: (q.isCompleted && !q.claimed)
                                ? () async {
                                    SoundService.instance.playEffect('combo.wav');
                                    _profile.gems += q.rewardGems;
                                    q.claimed = true;
                                    await _save();
                                    setSheetState(() {});
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                            ),
                            child: Text(
                              q.claimed
                                  ? L10n.tr('claimed', isAr)
                                  : '+${q.rewardGems} 💎',
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131C35),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isAr = _profile.isArabic;
          return Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    L10n.tr('settings', isAr),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SwitchListTile(
                    title: Text(L10n.tr('sound', isAr), style: const TextStyle(color: Colors.white)),
                    value: _profile.soundEnabled,
                    onChanged: (v) async {
                      _profile.soundEnabled = v;
                      SoundService.instance.soundEnabled = v;
                      await _save();
                      setSheetState(() {});
                    },
                  ),
                  SwitchListTile(
                    title: Text(L10n.tr('haptics', isAr), style: const TextStyle(color: Colors.white)),
                    value: _profile.hapticsEnabled,
                    onChanged: (v) async {
                      _profile.hapticsEnabled = v;
                      SoundService.instance.hapticsEnabled = v;
                      await _save();
                      setSheetState(() {});
                    },
                  ),
                  SwitchListTile(
                    title: Text(L10n.tr('language', isAr), style: const TextStyle(color: Colors.white)),
                    subtitle: Text(isAr ? 'العربية' : 'English', style: const TextStyle(color: Colors.cyanAccent)),
                    value: _profile.isArabic,
                    onChanged: (v) async {
                      _profile.isArabic = v;
                      await _save();
                      setSheetState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    L10n.tr('privacy', isAr),
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    L10n.tr('privacy_body', isAr),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _profile.isArabic;
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B1120),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1120),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _PillStat(icon: Icons.diamond, color: const Color(0xFF38BDF8), value: '${_profile.gems}'),
                      _PillStat(icon: Icons.star, color: const Color(0xFFFACC15), value: '${_profile.stars}'),
                      _PillStat(icon: Icons.emoji_events, color: const Color(0xFFF59E0B), value: '${_profile.highScoreClassic}'),
                      IconButton(
                        onPressed: _showSettingsSheet,
                        icon: const Icon(Icons.settings, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(Icons.grid_view_rounded, color: Color(0xFF38BDF8), size: 46),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          L10n.tr('app_title', isAr),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          L10n.tr('app_subtitle', isAr),
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _MenuCard(
                    title: L10n.tr('classic_mode', isAr),
                    subtitle: L10n.tr('classic_desc', isAr),
                    icon: Icons.play_arrow_rounded,
                    colors: const [Color(0xFF06B6D4), Color(0xFF0284C7)],
                    onTap: _openClassic,
                  ),
                  const SizedBox(height: 14),
                  _MenuCard(
                    title: L10n.tr('adventure_mode', isAr),
                    subtitle: '${L10n.tr('adventure_desc', isAr)} (${_profile.unlockedLevel}/${AdventureLevels.totalLevels})',
                    icon: Icons.map_rounded,
                    colors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                    onTap: _openAdventureMap,
                  ),
                  const SizedBox(height: 14),
                  _MenuCard(
                    title: L10n.tr('kingdom_builder', isAr),
                    subtitle: L10n.tr('kingdom_desc', isAr),
                    icon: Icons.fort_rounded,
                    colors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                    onTap: _openKingdom,
                  ),
                  const SizedBox(height: 14),
                  _MenuCard(
                    title: L10n.tr('daily_quests', isAr),
                    subtitle: '${_profile.dailyQuests.where((q) => q.isCompleted && !q.claimed).length} ready',
                    icon: Icons.task_alt_rounded,
                    colors: const [Color(0xFF10B981), Color(0xFF059669)],
                    onTap: _showQuestsSheet,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  const _PillStat({required this.icon, required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF131C35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 5),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
