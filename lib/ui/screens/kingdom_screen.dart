import 'package:flutter/material.dart';
import '../../models/game_models.dart';
import '../../services/localization_service.dart';
import '../../services/sound_service.dart';

class KingdomScreen extends StatefulWidget {
  final PlayerProfile profile;
  final Future<void> Function() onSave;

  const KingdomScreen({
    super.key,
    required this.profile,
    required this.onSave,
  });

  @override
  State<KingdomScreen> createState() => _KingdomScreenState();
}

class _KingdomScreenState extends State<KingdomScreen> {
  Future<void> _upgradeBuilding(KingdomBuilding b) async {
    final isAr = widget.profile.isArabic;
    final currentLv = widget.profile.buildingLevels[b.id] ?? 0;
    if (currentLv >= b.maxLevel) return;

    final cost = b.costForNextLevel(currentLv);
    if (widget.profile.gems < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.tr('not_enough_gems', isAr)),
          backgroundColor: const Color(0xFFBE123C),
        ),
      );
      return;
    }

    SoundService.instance.playEffect('combo.wav');
    SoundService.instance.mediumHaptic();

    setState(() {
      widget.profile.gems -= cost;
      widget.profile.buildingLevels[b.id] = currentLv + 1;
    });
    await widget.onSave();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.profile.isArabic;
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1120),
        appBar: AppBar(
          backgroundColor: const Color(0xFF131C35),
          foregroundColor: Colors.white,
          title: Text(L10n.tr('kingdom_builder', isAr)),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(Icons.diamond, color: Color(0xFF38BDF8), size: 20),
                  const SizedBox(width: 5),
                  Text(
                    '${widget.profile.gems}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance, color: Color(0xFFFACC15), size: 34),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr
                              ? 'مستوى المملكة: ${widget.profile.totalKingdomLevel}'
                              : 'Kingdom Level: ${widget.profile.totalKingdomLevel}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAr
                              ? 'مضاعف النقاط الحالي: x${widget.profile.scoreMultiplier.toStringAsFixed(2)}'
                              : 'Active Score Multiplier: x${widget.profile.scoreMultiplier.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...KingdomCatalog.buildings.map((b) {
              final lv = widget.profile.buildingLevels[b.id] ?? 0;
              final isMax = lv >= b.maxLevel;
              final cost = b.costForNextLevel(lv);
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF131C35),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: b.accentColor.withValues(alpha: 0.35)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: b.accentColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(b.icon, color: b.accentColor, size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    isAr ? b.nameAr : b.nameEn,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: b.accentColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${L10n.tr('level_short', isAr)} $lv/${b.maxLevel}',
                                      style: TextStyle(
                                        color: b.accentColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isAr ? b.descAr : b.descEn,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: lv / b.maxLevel,
                              minHeight: 8,
                              backgroundColor: Colors.white10,
                              valueColor: AlwaysStoppedAnimation(b.accentColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        ElevatedButton.icon(
                          onPressed: isMax ? null : () => _upgradeBuilding(b),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isMax ? Colors.white12 : b.accentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(isMax ? Icons.check : Icons.diamond, size: 16),
                          label: Text(
                            isMax ? L10n.tr('max_level', isAr) : '${L10n.tr('upgrade', isAr)} ($cost)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
