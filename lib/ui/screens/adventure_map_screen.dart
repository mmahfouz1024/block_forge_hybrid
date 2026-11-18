import 'package:flutter/material.dart';
import '../../models/game_models.dart';
import '../../services/localization_service.dart';

class AdventureMapScreen extends StatelessWidget {
  final PlayerProfile profile;
  final ValueChanged<int> onSelectLevel;

  const AdventureMapScreen({
    super.key,
    required this.profile,
    required this.onSelectLevel,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = profile.isArabic;
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1120),
        appBar: AppBar(
          backgroundColor: const Color(0xFF131C35),
          foregroundColor: Colors.white,
          title: Text(L10n.tr('adventure_mode', isAr)),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFFACC15), size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${profile.stars}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 130,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.88,
          ),
          itemCount: AdventureLevels.totalLevels,
          itemBuilder: (context, index) {
            final levelNum = index + 1;
            final unlocked = levelNum <= profile.unlockedLevel;
            final stars = profile.levelStars[levelNum] ?? 0;
            final levelData = AdventureLevels.getLevel(levelNum);

            return InkWell(
              onTap: unlocked ? () => onSelectLevel(levelNum) : null,
              borderRadius: BorderRadius.circular(18),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: unlocked
                      ? const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF172554)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: unlocked ? null : const Color(0xFF1E293B).withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: levelNum == profile.unlockedLevel
                        ? const Color(0xFFF59E0B)
                        : (unlocked ? const Color(0xFF3B82F6) : Colors.white12),
                    width: levelNum == profile.unlockedLevel ? 2.5 : 1.2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!unlocked)
                        const Icon(Icons.lock, color: Colors.white38, size: 28)
                      else
                        Text(
                          '$levelNum',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (s) {
                          return Icon(
                            s < stars ? Icons.star : Icons.star_border,
                            size: 17,
                            color: s < stars ? const Color(0xFFFACC15) : Colors.white24,
                          );
                        }),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${levelData.targetScore}',
                        style: TextStyle(
                          color: unlocked ? Colors.cyanAccent : Colors.white30,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
}
