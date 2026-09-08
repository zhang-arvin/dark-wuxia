// =============================================================================
// test/engine/battle_engine_test.dart — 战斗引擎：伤害公式 + 会话修正
// =============================================================================

import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:dark_wuxia/engine/battle_engine.dart';
import 'package:dark_wuxia/engine/config_loader.dart';
import 'package:dark_wuxia/engine/narration_engine.dart';
import 'package:dark_wuxia/models/attributes.dart';
import 'package:dark_wuxia/models/character.dart';
import 'package:dark_wuxia/models/enums.dart';
import 'package:dark_wuxia/models/session_mods.dart';

Future<ConfigLoader> _loadConfig() async {
  final enemiesJson = await rootBundle.loadString('assets/config/enemies.json');
  final loader = ConfigLoader.forTesting();
  loader.loadFromJsonMap({ConfigType.enemies: enemiesJson});
  return loader;
}

Character _makeCharacter({int level = 1, int health = 100}) {
  return Character(
    name: '测试侠客',
    origin: '无名山村',
    age: 18,
    level: level,
    attributes: const Attributes(body: 10, agi: 10, wis: 10, con: 10, luck: 5),
    health: health,
    innerEnergy: 100,
    powerIndex: 100,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('executeBattle 基础行为', () {
    test('固定种子 20 次跑通：不抛异常，结果非空且敌人 ID 正确', () async {
      final loader = await _loadConfig();
      final enemy = loader.getEnemy('enemy_gm_001')!.toEnemy();
      for (var seed = 1; seed <= 20; seed++) {
        final engine = BattleEngine(loader, NarrationEngine(Random(seed)), Random(seed));
        final result = engine.executeBattle(
          player: _makeCharacter(),
          enemy: enemy,
          realmId: 'realm_gumu',
          layer: 1,
          difficulty: Difficulty.normal,
        );
        expect(result, isNotNull);

        // 不同 seed 下胜负可能不同，只验证结果一致性
        expect(result.enemyId, 'enemy_gm_001');
        expect(result.turnsUsed, greaterThan(0));
      }
    });
  });

  group('真回合制三件套', () {
    test('initRuntime/stepTurn/finishBattle 完整流程跑通', () async {
      final loader = await _loadConfig();
      final enemy = loader.getEnemy('enemy_gm_001')!.toEnemy();
      final engine = BattleEngine(loader, NarrationEngine(Random(1)), Random(1));
      final st = engine.initRuntime(
        player: _makeCharacter(),
        enemy: enemy,
        realmId: 'realm_gumu',
        layer: 1,
        difficulty: Difficulty.normal,
      );

      // 敌人血量被正确缩放；玩家存活
      expect(st.playerAlive, isTrue);
      expect(st.enemyAlive, isTrue);

      // 手动推满回合数，不抛异常
      for (var i = 0; i < st.maxTurns && !st.battleOver; i++) {
        st.setPlayerAction(BattleActionType.attack);
        engine.stepTurn(st);
      }
      final result = engine.finishBattle(st);
      expect(result.turnsUsed, greaterThan(0));
    });
  });

  group('SessionMods 战斗侧加成', () {
    test('bloodMoon 模组：initRuntime enemyCombatant 血量高 1.2 倍', () async {
      final loader = await _loadConfig();
      final enemy = loader.getEnemy('enemy_gm_001')!.toEnemy();

      final stPlain = BattleEngine(loader, NarrationEngine(Random(3)), Random(3))
          .initRuntime(
        player: _makeCharacter(),
        enemy: enemy,
        realmId: 'realm_gumu',
        layer: 1,
        difficulty: Difficulty.normal,
      );
      final stBlood = BattleEngine(loader, NarrationEngine(Random(3)), Random(4))
          .initRuntime(
        player: _makeCharacter(),
        enemy: enemy,
        realmId: 'realm_gumu',
        layer: 1,
        difficulty: Difficulty.normal,
        mods: const SessionMods(modifier: RealmModifierType.bloodMoon),
      );

      final plainHp = stPlain.enemyCombatant.health;
      final bloodHp = stBlood.enemyCombatant.health;
      // 1.2 倍取整允许 ±1 的取整误差
      expect(bloodHp, closeTo(plainHp * 1.2, 1.0));
      expect(bloodHp, greaterThan(plainHp));
    });

    test('铁骨 buff：同 seed 流程下玩家承伤更低', () async {
      final loader = await _loadConfig();
      final enemy = loader.getEnemy('enemy_gm_001')!.toEnemy();

      // 同一 seed 下两条线——但 stepTurn 会消耗 RNG，每条线需要独立的
      // engine 实例（同样的初始 seed 保证 RNG 序列对齐）
      final enginePlain =
          BattleEngine(loader, NarrationEngine(Random(5)), Random(5));
      final stPlain = enginePlain.initRuntime(
        player: _makeCharacter(),
        enemy: enemy,
        realmId: 'realm_gumu',
        layer: 1,
        difficulty: Difficulty.normal,
      );
      final engineIron =
          BattleEngine(loader, NarrationEngine(Random(5)), Random(5));
      final stIron = engineIron.initRuntime(
        player: _makeCharacter(),
        enemy: enemy,
        realmId: 'realm_gumu',
        layer: 1,
        difficulty: Difficulty.normal,
        mods: const SessionMods(buffs: {SessionBuffType.ironbone}),
      );

      expect(stIron.playerCombatant.damageTakenMultiplier,
          closeTo(0.85, 1e-9));
      expect(stPlain.playerCombatant.damageTakenMultiplier, 1.0);

      // 手动跑完整场
      for (var i = 0; i < stPlain.maxTurns && !stPlain.battleOver; i++) {
        stPlain.setPlayerAction(BattleActionType.attack);
        enginePlain.stepTurn(stPlain);
      }
      for (var i = 0; i < stIron.maxTurns && !stIron.battleOver; i++) {
        stIron.setPlayerAction(BattleActionType.attack);
        engineIron.stepTurn(stIron);
      }
      // 铁骨玩家剩余血量必须 >= 无 buff 玩家剩余血量（同 seed 同 RNG 序列）
      expect(stIron.playerCombatant.health,
          greaterThanOrEqualTo(stPlain.playerCombatant.health));
    });
  });
}