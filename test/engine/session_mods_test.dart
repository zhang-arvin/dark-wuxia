// =============================================================================
// test/engine/session_mods_test.dart — 模块3 会话修正纯模型测试
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:dark_wuxia/models/session_mods.dart';

void main() {
  group('SessionMods 纯模型', () {
    test('默认空 mods：所有乘数为 1.0，isEmpty=true', () {
      const mods = SessionMods();
      expect(mods.isEmpty, isTrue);
      expect(mods.enemyPowerMultiplier, 1.0);
      expect(mods.dropQualityMultiplier, 1.0);
      expect(mods.damageReduction, 1.0);
      expect(mods.critBonus, 0);
      expect(mods.dodgeBonus, 0);
      expect(mods.hpRegenMultiplier, 1.0);
      expect(mods.energyRegenBonus, 1.0);
      expect(mods.affixWeightMultiplier, 1.0);
      expect(mods.treasureWeightMultiplier, 1.0);
    });

    test('withBuff 叠加：buffs 增长且 modifier 保留', () {
      final m1 = const SessionMods(modifier: RealmModifierType.bloodMoon)
          .withBuff(SessionBuffType.bloodfury);
      expect(m1.buffs, contains(SessionBuffType.bloodfury));
      expect(m1.modifier, RealmModifierType.bloodMoon);

      final m2 = m1.withBuff(SessionBuffType.ironbone);
      expect(m2.buffs.length, 2);
      expect(m2.modifier, RealmModifierType.bloodMoon);
      // 原实例不可变
      expect(m1.buffs.length, 1);
    });

    test('dropQualityMultiplier 组合：greed + bloodMoon = 1.35', () {
      final mods = SessionMods(
        modifier: RealmModifierType.bloodMoon,
        buffs: {SessionBuffType.greed},
      );
      expect(mods.dropQualityMultiplier, closeTo(1.35, 1e-9));
      // 单独 bloodMoon = 1.25
      const bloodMoonOnly = SessionMods(modifier: RealmModifierType.bloodMoon);
      expect(bloodMoonOnly.dropQualityMultiplier, closeTo(1.25, 1e-9));
      // 单独 greed = 1.10
      final greedOnly = SessionMods(buffs: {SessionBuffType.greed});
      expect(greedOnly.dropQualityMultiplier, closeTo(1.10, 1e-9));
    });

    test('enemyPowerMultiplier：bloodMoon 1.2，其余 1.0', () {
      const bloodMoon = SessionMods(modifier: RealmModifierType.bloodMoon);
      expect(bloodMoon.enemyPowerMultiplier, closeTo(1.2, 1e-9));

      const spiritSpring = SessionMods(modifier: RealmModifierType.spiritSpring);
      expect(spiritSpring.enemyPowerMultiplier, 1.0);
      expect(spiritSpring.hpRegenMultiplier, closeTo(1.5, 1e-9));
    });

    test('treasureHunt / affixResonance 专属乘数', () {
      const treasure = SessionMods(modifier: RealmModifierType.treasureHunt);
      expect(treasure.treasureWeightMultiplier, closeTo(2.0, 1e-9));

      const affix = SessionMods(modifier: RealmModifierType.affixResonance);
      expect(affix.affixWeightMultiplier, closeTo(1.5, 1e-9));
    });

    test('copyWith / clearModifier', () {
      const mods = SessionMods(modifier: RealmModifierType.bloodMoon);
      final kept = mods.copyWith(buffs: {SessionBuffType.swift});
      expect(kept.modifier, RealmModifierType.bloodMoon);
      expect(kept.buffs, contains(SessionBuffType.swift));

      final cleared = mods.copyWith(clearModifier: true);
      expect(cleared.modifier, isNull);
    });

    test('战斗侧 buff getter', () {
      final mods = SessionMods(buffs: {
        SessionBuffType.bloodfury,
        SessionBuffType.ironbone,
        SessionBuffType.armorBreak,
        SessionBuffType.qiFlow,
        SessionBuffType.swift,
      });
      expect(mods.critBonus, 15);
      expect(mods.damageReduction, closeTo(0.85, 1e-9));
      expect(mods.eliteDamageBonus, closeTo(1.2, 1e-9));
      expect(mods.energyRegenBonus, closeTo(1.2, 1e-9));
      expect(mods.dodgeBonus, 10);
    });

    test('summary 顺序：modifier 在前，buff 在后', () {
      final mods = SessionMods(
        modifier: RealmModifierType.bloodMoon,
        buffs: {SessionBuffType.greed},
      );
      expect(mods.summary.first, '血月之夜');
      expect(mods.summary, contains('贪婪'));
    });
  });
}