// =============================================================================
// test/engine/elite_mechanics_test.dart — 精英机制状态效果验证
// =============================================================================

import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:dark_wuxia/engine/battle_engine.dart';
import 'package:dark_wuxia/engine/config_loader.dart';
import 'package:dark_wuxia/engine/narration_engine.dart';
import 'package:dark_wuxia/models/attributes.dart';
import 'package:dark_wuxia/models/character.dart';
import 'package:dark_wuxia/models/enemy.dart';
import 'package:dark_wuxia/models/enums.dart';

Future<ConfigLoader> _loadConfig() async {
  final enemiesJson = await rootBundle.loadString('assets/config/enemies.json');
  final loader = ConfigLoader.forTesting();
  loader.loadFromJsonMap({ConfigType.enemies: enemiesJson});
  return loader;
}

Character _makeCharacter({int level = 30, int health = 5000}) {
  return Character(
    name: '测试侠客',
    origin: '无名山村',
    age: 18,
    level: level,
    attributes: const Attributes(body: 20, agi: 20, wis: 20, con: 20, luck: 5),
    health: health,
    innerEnergy: 500,
    powerIndex: 3000,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('精英机制落位（initRuntime）', () {
    test('elite_cj_001 shield → 敌人获得 shield 状态效果', () async {
      final loader = await _loadConfig();
      final enemy = loader.getEnemy('elite_cj_001')!.toEnemy();
      final engine = BattleEngine(loader, NarrationEngine(Random(1)), Random(1));
      final st = engine.initRuntime(
        player: _makeCharacter(),
        enemy: enemy,
        realmId: 'realm_gumu',
        layer: 1,
        difficulty: Difficulty.normal,
      );
      final shield = st.enemyCombatant.statusEffects
          .where((e) => e.type == StatusEffectType.shield);
      expect(shield, isNotEmpty, reason: 'shield 机制应挂 shield 状态效果');
      expect(shield.first.value, 50, reason: 'damageReductionPct=50');
    });

    test('elite_xm_002 reflectDamage → 敌人获得 reflect 状态效果', () async {
      final loader = await _loadConfig();
      final enemy = loader.getEnemy('elite_xm_002')!.toEnemy();
      final engine = BattleEngine(loader, NarrationEngine(Random(2)), Random(2));
      final st = engine.initRuntime(
        player: _makeCharacter(),
        enemy: enemy,
        realmId: 'realm_gumu',
        layer: 1,
        difficulty: Difficulty.normal,
      );
      final reflect = st.enemyCombatant.statusEffects
          .where((e) => e.type == StatusEffectType.reflect);
      expect(reflect, isNotEmpty, reason: 'reflectDamage 应挂 reflect 状态效果');
      expect(reflect.first.value, 20, reason: 'pct=20');
    });

    test('elite_gm_002 counterMelee → reflect 状态效果（counterDamage=0.3→30%）', () async {
      final loader = await _loadConfig();
      final enemy = loader.getEnemy('elite_gm_002')!.toEnemy();
      final engine = BattleEngine(loader, NarrationEngine(Random(3)), Random(3));
      final st = engine.initRuntime(
        player: _makeCharacter(),
        enemy: enemy,
        realmId: 'realm_gumu',
        layer: 1,
        difficulty: Difficulty.normal,
      );
      final reflect = st.enemyCombatant.statusEffects
          .where((e) => e.type == StatusEffectType.reflect);
      expect(reflect, isNotEmpty, reason: 'counterMelee 应挂 reflect 状态效果');
      expect(reflect.first.value, 30, reason: 'counterDamage=0.3 → 30%');
    });

    test('elite_cj_002 innerDrain → enemyCombatant.innerDrainPerTurn=15', () async {
      final loader = await _loadConfig();
      final enemy = loader.getEnemy('elite_cj_002')!.toEnemy();
      final engine = BattleEngine(loader, NarrationEngine(Random(4)), Random(4));
      final st = engine.initRuntime(
        player: _makeCharacter(),
        enemy: enemy,
        realmId: 'realm_gumu',
        layer: 1,
        difficulty: Difficulty.normal,
      );
      expect(st.enemyCombatant.innerDrainPerTurn, 15,
          reason: 'perTurn=15');
    });

    test('elite_tj_001 disableLightness → 玩家侧 dodgeDown 状态效果', () async {
      final loader = await _loadConfig();
      final enemy = loader.getEnemy('elite_tj_001')!.toEnemy();
      final engine = BattleEngine(loader, NarrationEngine(Random(5)), Random(5));
      final st = engine.initRuntime(
        player: _makeCharacter(),
        enemy: enemy,
        realmId: 'realm_gumu',
        layer: 1,
        difficulty: Difficulty.normal,
      );
      final dodgeDown = st.playerCombatant.statusEffects
          .where((e) => e.type == StatusEffectType.dodgeDown);
      expect(dodgeDown, isNotEmpty, reason: 'disableLightness 应给玩家挂 dodgeDown');
      // 闪避减半：20 agi 原始 dodgeRate=10 → 5
      expect(st.playerCombatant.effectiveDodgeRate, 5);
    });
  });

  group('精英战斗流程稳定性', () {
    test('3 只精英 × 5 个 seed 跑通不抛异常', () async {
      final loader = await _loadConfig();
      const eliteIds = ['elite_gm_001', 'elite_cj_002', 'elite_xm_002'];
      for (final id in eliteIds) {
        final enemy = loader.getEnemy(id)!.toEnemy();
        for (var seed = 1; seed <= 5; seed++) {
          final engine =
              BattleEngine(loader, NarrationEngine(Random(seed)), Random(seed));
          final result = engine.executeBattle(
            player: _makeCharacter(),
            enemy: enemy,
            realmId: 'realm_gumu',
            layer: 1,
            difficulty: Difficulty.normal,
          );
          expect(result.enemyId, id);
          expect(result.turnsUsed, greaterThan(0));
        }
      }
    });
  });
}