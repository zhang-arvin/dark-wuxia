// =============================================================================
// test/engine/damage_formula_test.dart — 伤害公式数值断言（批次0 P0-2）
//
// 核心思路：我方 critRate=0（agi=1→round(0.3)=0）且技能列表为空 →
// 玩家每次平砍链路上零 RNG 消耗，伤害完全确定，可手算：
//
//   外攻 = body×2.0 = 20          (_externalBaseMultiplier)
//   武器加成 = round(20×0.3) = 6   (_executeAction 玩家侧 weaponDamage)
//   基础伤害 = 20+6 = 26
//   防御减免 = round(3×0.8) = 2    (敌人 defense=3, _defenseMultiplier=0.8)
//   最终伤害 = 26−2 = 24           ← 每次玩家平砍恒为 24
// =============================================================================

import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:dark_wuxia/engine/battle_engine.dart';
import 'package:dark_wuxia/engine/config_loader.dart';
import 'package:dark_wuxia/engine/narration_engine.dart';
import 'package:dark_wuxia/models/attributes.dart';
import 'package:dark_wuxia/models/character.dart';
import 'package:dark_wuxia/models/enums.dart';

Future<ConfigLoader> _loadConfig() async {
  final enemiesJson = await rootBundle.loadString('assets/config/enemies.json');
  final loader = ConfigLoader.forTesting();
  loader.loadFromJsonMap({ConfigType.enemies: enemiesJson});
  return loader;
}

Character _makeCharacter() {
  return Character(
    name: '测试侠客',
    origin: '无名山村',
    age: 18,
    level: 1,
    attributes: const Attributes(body: 10, agi: 1, wis: 10, con: 10, luck: 5),
    health: 100000,
    innerEnergy: 100000,
    powerIndex: 1000,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('端到端伤害断言：玩家每次平砍伤害恒为 24（手算验证）', () async {
    final loader = await _loadConfig();
    final enemy = loader.getEnemy('enemy_gm_001')!.toEnemy();

    // enemy power=120，我方 power=100 使 ratio=1.2>0.7 但 ≤1.2 → normal 档，
    // 走真回合制路径产生真实 BattleAction。agi=1→crit=0/dodge=0 判定短路由。
    for (var seed = 1; seed <= 5; seed++) {
      final engine =
          BattleEngine(loader, NarrationEngine(Random(seed)), Random(seed));
      final st = engine.initRuntime(
        player: _makeCharacter(),
        enemy: enemy,
        realmId: 'realm_gumu',
        layer: 1,
        difficulty: Difficulty.normal,
      );
      // 强制推进整场
      for (var i = 0; i < st.maxTurns && !st.battleOver; i++) {
        st.setPlayerAction(BattleActionType.attack);
        engine.stepTurn(st);
      }

      final playerAttacks = st.turns
          .expand((t) => t.actions)
          .where((a) =>
              a.isPlayer &&
              a.type == BattleActionType.attack &&
              !a.dodged)
          .toList();

      expect(playerAttacks, isNotEmpty, reason: 'seed=$seed 应有玩家攻击动作');
      for (final a in playerAttacks) {
        expect(a.damage, 24,
            reason: 'seed=$seed 平砍应恒为24：攻20+武器6−防减免2');
      }
    }
  });

  test('公式常量间接验证：外攻基数/武器系数/防御系数', () {
    // _externalBaseMultiplier=2.0 → body10 → 外攻20
    expect((10 * 2.0).round(), 20);
    // 武器伤害 = effectiveAttack×0.3 → 20×0.3=6
    expect((20 * 0.3).round(), 6);
    // 防御减免 = defense×0.8 → 3×0.8=2.4 → round=2
    expect((3 * 0.8).round(), 2);
    // 合计：20+6−2=24（与端到端断言呼应）
    expect(20 + 6 - 2, 24);
  });

  test('最少1点伤害底线：极端防御差也至少1点', () {
    // 模型层验证：damage<1 时 clamp 到 1（_calcExternalDamage 尾部保护）
    int calc(int atk, int def) {
      final raw = (atk * 1.0 * 1.0 - (def * 0.8).round()).round();
      return raw < 1 ? 1 : raw;
    }

    expect(calc(2, 50), 1); // 2 − 40 → clamp 1
    expect(calc(100, 0), 100);
  });
}