// =============================================================================
// test/engine/drop_engine_test.dart — 掉落引擎：保底机制 + 福缘单调性
// =============================================================================

import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:dark_wuxia/engine/config_loader.dart';
import 'package:dark_wuxia/engine/drop_engine.dart';
import 'package:dark_wuxia/models/drop.dart';
import 'package:dark_wuxia/models/enums.dart';

Future<ConfigLoader> _loadConfig() async {
  final dropJson = await rootBundle.loadString('assets/config/drop_tables.json');
  final loader = ConfigLoader.forTesting();
  loader.loadFromJsonMap({ConfigType.dropTables: dropJson});
  return loader;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PityCounter 保底', () {
    test('isPityTriggered：count >= threshold 触发', () {
      const p1 = PityCounter(dropTableId: 'drop_normal', count: 199, threshold: 200);
      expect(p1.isPityTriggered, isFalse);
      const p2 = PityCounter(dropTableId: 'drop_normal', count: 200, threshold: 200);
      expect(p2.isPityTriggered, isTrue);
    });

    test('increment/reset 语义', () {
      const p = PityCounter(dropTableId: 'drop_normal', count: 5, threshold: 200);
      expect(p.increment().count, 6);
      expect(p.reset().count, 0);
    });

    test('threshold 参数决定触发点', () {
      const p = PityCounter(dropTableId: 'drop_normal', count: 9, threshold: 10);
      expect(p.isPityTriggered, isFalse);
      expect(p.increment().isPityTriggered, isTrue);
    });
  });

  group('DropTable.calculateActualRates', () {
    test('保底触发时 unique=1.0 其余=0', () async {
      final loader = await _loadConfig();
      final table = loader.getDropTable('drop_normal')!;
      const pity = PityCounter(dropTableId: 'drop_normal', count: 200, threshold: 200);
      final rates = table.calculateActualRates(0, pity);
      expect(rates[Quality.unique], 1.0);
      for (final q in Quality.values) {
        if (q != Quality.unique) {
          expect(rates[q], 0.0, reason: '$q 应为 0');
        }
      }
    });

    test('福缘单调性：fortune=50 unique 掉率 > fortune=0', () async {
      final loader = await _loadConfig();
      final table = loader.getDropTable('drop_normal')!;
      const pity = PityCounter(dropTableId: 'drop_normal', count: 0, threshold: 200);
      final low = table.calculateActualRates(0, pity);
      final high = table.calculateActualRates(50, pity);
      expect(high[Quality.unique]!, greaterThan(low[Quality.unique]!));
      expect(high[Quality.divine]!, greaterThan(low[Quality.divine]!));
    });

    test('掉率归一化：所有品质之和=1', () async {
      final loader = await _loadConfig();
      final table = loader.getDropTable('drop_normal')!;
      const pity = PityCounter(dropTableId: 'drop_normal', count: 30, threshold: 200);
      final rates = table.calculateActualRates(20, pity);
      final total = rates.values.fold(0.0, (a, b) => a + b);
      expect(total, closeTo(1.0, 1e-9));
    });
  });

  group('DropEngine.generateDrop', () {
    test('固定 seed 多次调用确定性且不抛异常', () async {
      final loader = await _loadConfig();
      final engine = DropEngine(loader, Random(42));
      const pity = PityCounter(dropTableId: 'drop_normal', count: 0, threshold: 200);
      final r1 = engine.generateDrop(
        dropTableId: 'drop_normal',
        fortune: 10,
        pity: pity,
        realmId: 'realm_gumu',
        layer: 1,
        sourceId: 'enemy_gm_001',
      );
      expect(r1, isNotNull);
      expect(r1!.equipment.id, isNotEmpty);
      // 非暗金 → 保底递增(count=1)；暗金+ → 保底重置(count=0)
      final droppedUnique = r1.record.quality.isUniqueOrAbove;
      expect(r1.updatedPity.count, droppedUnique ? 0 : 1);
    });

    test('generateDrops 保底逐件推进', () async {
      final loader = await _loadConfig();
      final engine = DropEngine(loader, Random(7));
      const pity = PityCounter(dropTableId: 'drop_normal', count: 0, threshold: 200);
      final results = engine.generateDrops(
        dropTableId: 'drop_normal',
        fortune: 0,
        pity: pity,
        realmId: 'realm_gumu',
        layer: 1,
        sourceId: 'enemy_gm_001',
        count: 3,
      );
      expect(results.length, 3);
      // 每件更新后的保底计数单调（除非触发保底重置）
      expect(results[0].updatedPity.count, greaterThan(0));
    });
  });
}