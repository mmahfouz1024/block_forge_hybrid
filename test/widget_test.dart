import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:block_forge_hybrid/logic/board_engine.dart';
import 'package:block_forge_hybrid/main.dart';
import 'package:block_forge_hybrid/models/game_models.dart';

void main() {
  group('BoardEngine', () {
    test('clears full row and awards combo points', () {
      final engine = BoardEngine(rng: Random(42));
      for (var c = 0; c < 7; c++) {
        engine.grid[0][c].occupied = true;
        engine.grid[0][c].color = BlockColor.blue;
      }
      engine.tray[0] = const BlockShape(
        id: 'dot',
        matrix: [[1]],
        color: BlockColor.cyan,
      );

      final result = engine.placeFromTray(0, 0, 7);
      expect(result.placed, isTrue);
      expect(result.linesCleared, 1);
      expect(result.comboStreak, 1);
      expect(result.pointsEarned, greaterThan(100));
      for (var c = 0; c < 8; c++) {
        expect(engine.grid[0][c].occupied, isFalse);
      }
    });

    test('clears simultaneous row and column', () {
      final engine = BoardEngine(rng: Random(42));
      for (var i = 0; i < 8; i++) {
        if (i != 3) engine.grid[2][i].occupied = true;
        if (i != 2) engine.grid[i][3].occupied = true;
      }
      engine.tray[0] = const BlockShape(
        id: 'dot',
        matrix: [[1]],
        color: BlockColor.amber,
      );

      final result = engine.placeFromTray(0, 2, 3);
      expect(result.placed, isTrue);
      expect(result.linesCleared, 2);
      expect(engine.grid[2].every((c) => !c.occupied), isTrue);
      expect(engine.grid.every((r) => !r[3].occupied), isTrue);
    });

    test('cracks ice obstacle and collects gem on clear', () {
      final engine = BoardEngine(rng: Random(7), gemSpawnChance: 0.0);
      for (var c = 0; c < 7; c++) {
        engine.grid[1][c].occupied = true;
      }
      engine.grid[1][2].iceHits = 1;
      engine.grid[1][4].hasGem = true;
      engine.tray[0] = const BlockShape(
        id: 'dot',
        matrix: [[1]],
        color: BlockColor.emerald,
      );

      final result = engine.placeFromTray(0, 1, 7);
      expect(result.iceCracked, 1);
      expect(result.gemsEarned, 1);
      expect(engine.grid[1][2].occupied, isFalse);
      expect(engine.grid[1][2].iceHits, 0);
    });

    test('bomb clears 3x3 region and hammer clears 1 cell', () {
      final engine = BoardEngine(rng: Random(1));
      for (var r = 3; r <= 5; r++) {
        for (var c = 3; c <= 5; c++) {
          engine.grid[r][c].occupied = true;
        }
      }
      final cleared = engine.applyBomb(4, 4);
      expect(cleared, 9);

      engine.grid[0][0].occupied = true;
      expect(engine.applyHammer(0, 0), isTrue);
      expect(engine.grid[0][0].occupied, isFalse);
    });

    test('detects game over when no tray shapes fit', () {
      final engine = BoardEngine(rng: Random(9));
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          engine.grid[r][c].occupied = true;
        }
      }
      engine.tray = [
        const BlockShape(id: 'bar2', matrix: [[1, 1]], color: BlockColor.blue),
        null,
        null,
      ];
      expect(engine.hasAnyValidMove, isFalse);
      engine.grid[0][0].occupied = false;
      engine.grid[0][1].occupied = false;
      expect(engine.hasAnyValidMove, isTrue);
    });
  });

  testWidgets('BlockForgeApp renders home menu cleanly', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BlockForgeApp());
    await tester.pumpAndSettle();
    expect(find.text('قلعة البلوكات'), findsOneWidget);
  });
}
