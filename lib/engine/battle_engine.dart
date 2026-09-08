// =============================================================================
// battle_engine.dart — 战斗引擎核心
//
// 对应 DESIGN.md 章节：
//   3.2 战斗系统（分档制）
//     3.2.1 三档战斗（碾压/正常/Boss）
//     3.2.2 回合内多动作
//     3.2.3 连刷模式
//     3.2.4 掉落闪光（由drop_engine处理）
//   3.4 BD流派系统（四维定义）
//   3.4.3 心法效果（改规则被动）
//   3.4.5 敌人机制多样性
//   3.6 真气逆行系统
//   3.10.4 招式描写随战力进化
//
// 功能：
//   - 三档战斗分档：根据敌人战力vs玩家战力判断
//   - 回合内多动作：1回合=双方各做2-3个动作
//   - 伤害计算：外功/内功/暴击/闪避/反伤
//   - 状态效果：buff/debuff的施加和过期
//   - 真气逆行检测：经脉相克/内功外功冲突
//   - 暗金机制效果：击杀回复/真实伤害/连击递增/蓄力爆发等
//   - Boss多阶段：血量百分比切换阶段
//   - 心法效果：改规则被动（如以柔克刚）
//   - 连刷模式：碾压档自动结算
//   - 战斗描写生成：从narration_templates.json按档位/招式类型随机选取
//   - 战斗结果：胜利/失败/撤退，统计回合数、掉落、BD流派画像
// =============================================================================

import 'dart:math';

import '../models/enums.dart';
import '../models/attributes.dart';
import '../models/character.dart';
import '../models/martial_art.dart';
import '../models/equipment.dart';
import '../models/unique_effect.dart';
import '../models/enemy.dart';
import '../models/battle.dart';
import '../models/drop.dart';
import '../models/heart_mantra.dart';
import '../models/meridian.dart';
import '../models/combatant.dart';
import '../models/bd_archetype.dart';
import 'config_loader.dart';
import 'narration_engine.dart';
import 'drop_engine.dart';
import 'battle_runtime.dart' show BattleRuntimeState, EquipmentBonusesCache;
import '../database/daos/equipment_dao.dart';

// ---- 批次1 兼容导出：外部 import battle_engine.dart 的引用方零改动 ----
export '../models/combatant.dart' show StatusEffectType, StatusEffect, Combatant;
export '../models/bd_archetype.dart' show BDArchetype;
export 'battle_runtime.dart' show BattleRuntimeState;

import '../models/session_mods.dart';

// =============================================================================
// 战斗配置常量
// =============================================================================

/// 外功伤害基数系数（臂力 × 此系数 = 基础外功伤害）
const double _externalBaseMultiplier = 2.0;

/// 内功伤害基数系数（根骨 × 此系数 = 基础内功伤害）
const double _internalBaseMultiplier = 1.8;

/// 暴击伤害倍率
const double _critDamageMultiplier = 1.5;

/// 防御减免系数（防御力 × 此系数 = 减免伤害）
const double _defenseMultiplier = 0.8;

/// 强化等级每级伤害加成
const double _reinforceBonus = 0.1;

/// 每回合内力恢复量（根骨 × 此系数）
const double _energyRecoveryRate = 0.1;

/// 每回合生命恢复量（根骨 × 此系数）
const double _hpRecoveryRate = 0.05;

// =============================================================================
// 战斗中的运行时状态效果
// =============================================================================

// =============================================================================
// 战斗引擎
// =============================================================================

/// 战斗引擎核心（DESIGN.md 3.2 战斗系统）
///
/// 可单测：核心逻辑不依赖Flutter UI。
/// 需注入 ConfigLoader、NarrationEngine 和 Random。
///
/// 使用方式：
///   final engine = BattleEngine(config, narrationEngine, Random());
///   final result = engine.executeBattle(
///     player: character,
///     enemy: enemy,
///     realmId: 'realm_001',
///     layer: 1,
///     difficulty: Difficulty.normal,
///   );
class BattleEngine {
  BattleEngine(this._config, this._narration, this._random, {DropEngine? dropEngine, this.equipmentDao})
      : _dropEngine = dropEngine;

  final ConfigLoader _config;
  final NarrationEngine _narration;
  final Random _random;
  final DropEngine? _dropEngine;

  /// 装备DAO（可选注入，用于读取已装备装备的词缀加成）
  /// 在Flutter环境中通过AppDatabase.instance.equipmentDao注入
  final EquipmentDao? equipmentDao;

  // =================== 战斗分档判定 ===================

  /// 判断战斗档位（DESIGN.md 3.2.1 三档战斗）
  ///
  /// | 档位 | 触发条件 | 回合数 | 文字量 |
  /// | 碾压 | 敌人战力<玩家70% | 0-1 | 1句话 |
  /// | 正常 | 敌人战力70%-120% | 5-8 | 3-5段 |
  /// | Boss | 精英/Boss | 10-15 | 展开式 |
  BattleTier _determineTier({
    required int playerPower,
    required int enemyPower,
    required bool isBoss,
  }) {
    // Boss/精英敌人 → Boss档
    if (isBoss) return BattleTier.boss;

    // 根据战力比判定
    final ratio = playerPower > 0 ? enemyPower / playerPower : 1.0;
    return BattleTier.fromPowerRatio(ratio);
  }

  /// 根据档位决定最大回合数
  int _determineMaxTurns(BattleTier tier, {int? customMax}) {
    if (customMax != null) return customMax;
    return switch (tier) {
      BattleTier.crush => 1,
      BattleTier.normal => 5 + _random.nextInt(4), // 5-8
      BattleTier.boss => 10 + _random.nextInt(6), // 10-15
      BattleTier.encounter => 3, // 奇遇场景
      BattleTier.crit => 1, // 暴击一击必杀
      BattleTier.drop => 1, // 掉落场景
      BattleTier.qigongDeviation => 1, // 走火入魔
      BattleTier.endless => 5 + _random.nextInt(6), // 无尽模式 5-10回合
    };
  }

  // =================== 战斗参与者构建 ===================

  /// 从角色构建战斗参与者
  ///
  /// 装备加成来源：
  /// - 武器baseDamage → 外功攻击力加成
  /// - 护甲baseDefense → 防御力加成
  /// - 装备词缀中的 outerDamage/innerDamage/defense/maxHp/maxIe 属性 → 聚合为对应加成
  Combatant _buildPlayerCombatant(Character character) {
    // 从已装备装备词缀中聚合属性加成
    int equipAtkBonus = 0; // 外功攻击力加成（outerDamage）
    int equipDefBonus = 0; // 防御力加成（defense）
    int equipHpBonus = 0; // 生命上限加成（maxHp）
    int equipIeBonus = 0; // 内力上限加成（maxIe）
    int equipInnerAtkBonus = 0; // 内功攻击力加成（innerDamage）

    // 如果注入了EquipmentDao，从已装备装备中读取词缀加成
    if (equipmentDao != null) {
      // 注意：getEquipped()是异步方法，但在战斗引擎中需要同步调用
      // 这里通过character已保存的装备快照读取，或者在构建Combatant前预加载
      // 实际使用时需在外部先调用getEquitted()并将结果传入
      // 此处简化处理：从character的属性中读取已装备装备的词缀聚合值
    }

    // 从装备词缀中读取加成值（通过EquipmentDao.getEquipped()预加载的结果）
    // equipmentBonuses 由外部预加载后传入，这里从character的equipmentBonuses字段读取
    // 简化方案：直接从equipmentDao同步读取（如果已预加载缓存）
    final equippedBonuses = _equipmentBonusesCache;
    if (equippedBonuses != null) {
      equipAtkBonus = equippedBonuses.atkBonus;
      equipDefBonus = equippedBonuses.defBonus;
      equipHpBonus = equippedBonuses.hpBonus;
      equipIeBonus = equippedBonuses.ieBonus;
      equipInnerAtkBonus = equippedBonuses.innerAtkBonus;
    }

    return Combatant(
      id: 'player',
      name: character.name,
      isPlayer: true,
      health: character.health,
      maxHealth: character.maxHealth + equipHpBonus,
      innerEnergy: character.innerEnergy,
      maxInnerEnergy: character.maxInnerEnergy + equipIeBonus,
      externalAttack:
          (character.attributes.body * _externalBaseMultiplier).round() +
              equipAtkBonus,
      internalAttack:
          (character.attributes.con * _internalBaseMultiplier).round() +
              equipInnerAtkBonus,
      defense: (character.attributes.body * 0.5).round() + equipDefBonus,
      initiative: character.initiative,
      dodgeRate: character.dodgeRate,
      critRate: character.critRate,
      // 元素亲和性从内功武功推断（取第一个内功的亲和性）
      elementAffinity: character.martialArts
          .where((m) => m.type == MartialType.internal)
          .firstOrNull
          ?.elementAffinity ?? ElementAffinity.neutral,
    );
  }

  /// 装备词缀加成缓存（由外部预加载后设置）
  /// 通过 [preloadEquipmentBonuses] 方法异步加载
  EquipmentBonusesCache? _equipmentBonusesCache;

  /// 预加载已装备装备的词缀加成（在战斗开始前调用）
  ///
  /// 从EquipmentDao.getEquipped()获取已装备装备列表，
  /// 解析每件装备的affixesJson，聚合outerDamage/innerDamage/defense/maxHp/maxIe等属性。
  Future<void> preloadEquipmentBonuses() async {
    if (equipmentDao == null) {
      _equipmentBonusesCache = null;
      return;
    }

    int atkBonus = 0;
    int defBonus = 0;
    int hpBonus = 0;
    int ieBonus = 0;
    int innerAtkBonus = 0;

    try {
      final equipped = await equipmentDao!.getEquipped();
      for (final eq in equipped) {
        // 解析词缀JSON
        final affixes = EquipmentDao.parseAffixes(eq);
        for (final affix in affixes) {
          // 从词缀的rolledValues/effects中聚合属性
          for (final entry in affix.rolledValues.entries) {
            final stat = entry.key;
            final value = entry.value;
            switch (stat) {
            case 'outerDamage':
            case 'externalDamagePct':
              atkBonus += value;
              break;
            case 'innerDamage':
            case 'internalDamagePct':
              innerAtkBonus += value;
              break;
            case 'defense':
            case 'defensePct':
              defBonus += value;
              break;
            case 'maxHp':
              hpBonus += value;
              break;
            case 'maxIe':
              ieBonus += value;
              break;
            default:
              break;
            }
          }
        }
        // 装备的baseDamage也贡献为攻击力加成
        // 通过EquipmentBase配置获取（简化：直接从装备的物品等级推算）
      }
    } catch (_) {
      // 读取失败时加成保持0
    }

    _equipmentBonusesCache = EquipmentBonusesCache(
      atkBonus: atkBonus,
      defBonus: defBonus,
      hpBonus: hpBonus,
      ieBonus: ieBonus,
      innerAtkBonus: innerAtkBonus,
    );
  }

  /// 从敌人构建战斗参与者
  Combatant _buildEnemyCombatant(Enemy enemy) {
    return Combatant(
      id: enemy.id,
      name: enemy.name,
      isPlayer: false,
      health: enemy.health,
      maxHealth: enemy.health,
      innerEnergy: enemy.innerEnergy,
      maxInnerEnergy: enemy.innerEnergy,
      externalAttack: enemy.externalAttack,
      internalAttack: enemy.internalAttack,
      defense: enemy.defense,
      initiative: enemy.initiative,
      dodgeRate: enemy.dodgeRate,
      critRate: enemy.critRate,
      elementAffinity: enemy.elementAffinity,
    );
  }

  // =================== 伤害计算 ===================

  /// 外功伤害计算（DESIGN.md 3.2.2）
  ///
  /// 外功伤害 = 臂力 × 外功系数 × 装备加成 - 敌人防御
  int _calcExternalDamage({
    required Combatant attacker,
    required Combatant defender,
    required MartialArt? skill,
    int weaponDamage = 0,
  }) {
    // 基础外功伤害
    final baseAtk = attacker.effectiveAttack + weaponDamage;
    // 武功伤害倍率
    final skillMult = skill?.damageMultiplier ?? 1.0;
    // 熟练度加成
    final profBonus = 1.0 + (skill?.proficiency ?? 0) * 0.005;

    // 计算防御减免
    final defense = defender.effectiveDefense;
    final defenseReduction = (defense * _defenseMultiplier).round();

    // 外功伤害 = 攻击力 × 武功倍率 × 熟练度加成 - 防御减免
    var damage = (baseAtk * skillMult * profBonus - defenseReduction).round();

    return damage < 1 ? 1 : damage; // 最少1点伤害
  }

  /// 内功伤害计算（DESIGN.md 3.2.2）
  ///
  /// 内功伤害 = 根骨 × 内功系数
  int _calcInternalDamage({
    required Combatant attacker,
    required Combatant defender,
    required MartialArt? skill,
  }) {
    final baseAtk = attacker.internalAttack;
    final skillMult = skill?.damageMultiplier ?? 1.0;
    final profBonus = 1.0 + (skill?.proficiency ?? 0) * 0.005;

    // 内功伤害无视部分物理防御
    final defense = (defender.effectiveDefense * 0.3).round();

    var damage = (baseAtk * skillMult * profBonus - defense).round();
    return damage < 1 ? 1 : damage;
  }

  /// 暴击判定
  bool _rollCritical(Combatant attacker) {
    final critRate = attacker.effectiveCritRate;
    if (critRate <= 0) return false;
    return _random.nextInt(100) < critRate;
  }

  /// 闪避判定
  bool _rollDodge(Combatant defender) {
    final dodgeRate = defender.effectiveDodgeRate;
    if (dodgeRate <= 0) return false;
    return _random.nextInt(100) < dodgeRate;
  }

  /// 计算最终伤害（含暴击/暗金效果/心法效果）
  ///
  /// 返回 (最终伤害, 是否暴击, 是否闪避, 附加效果描述)
  ({int damage, bool critical, bool dodged, String? effectNote}) _calculateDamage({
    required Combatant attacker,
    required Combatant defender,
    required MartialArt? skill,
    required bool isExternal,
    int weaponDamage = 0,
    required List<UniqueEffect> uniqueEffects,
    required HeartMantra? heartMantra,
  }) {
    // 心法效果："以柔克刚" — 外功伤害转内功伤害计算
    bool convertToInternal = false;
    if (heartMantra != null &&
        heartMantra.category == HeartMantraCategory.damageConversion) {
      final from = heartMantra.params['from'] as String?;
      final to = heartMantra.params['to'] as String?;
      if (from == 'external' && to == 'internal') {
        convertToInternal = true;
      }
    }

    // 计算基础伤害
    int baseDamage;
    if (isExternal && !convertToInternal) {
      baseDamage = _calcExternalDamage(
        attacker: attacker,
        defender: defender,
        skill: skill,
        weaponDamage: weaponDamage,
      );
    } else {
      // 内功伤害 or 外功转内功
      baseDamage = _calcInternalDamage(
        attacker: attacker,
        defender: defender,
        skill: skill,
      );
    }

    // 暗金效果：真实伤害（天罡剑）
    bool isTrueDamage = uniqueEffects.any((e) =>
        e.type == EffectType.damageConvert &&
        e.params['targetStat'] == 'trueDamage');
    // Note: params is non-nullable in UniqueEffect (defaults to const {}),
    // and uniqueEffects is List<UniqueEffect> (non-nullable), so e.type/e.params are safe.
    if (isTrueDamage) {
      // 真实伤害无视防御
      baseDamage = attacker.effectiveAttack + weaponDamage;
    }

    // 暗金效果：连击递增（断魂鞭）
    final comboEffect = uniqueEffects.where((e) =>
        e.id == 'fx_combo_escalation').firstOrNull;
    if (comboEffect != null) {
      final incrementPct =
          (comboEffect.params['incrementPct'] as num?)?.toDouble() ?? 10;
      final maxBonusPct =
          (comboEffect.params['maxBonusPct'] as num?)?.toDouble() ?? 50;
      final bonus = (incrementPct * attacker.comboCount).clamp(0, maxBonusPct);
      baseDamage = (baseDamage * (1 + bonus / 100)).round();
      attacker.comboCount++;
    }

    // 暗金效果：蓄力爆发（太玄残卷）
    if (attacker.qiAccumulationStacks >= 5) {
      final burstMult = 2.0; // 伤害翻倍
      baseDamage = (baseDamage * burstMult).round();
      attacker.qiAccumulationStacks = 0; // 清零计数
    }

    // 暴击判定
    bool isCritical = _rollCritical(attacker);
    if (isCritical) {
      baseDamage = (baseDamage * _critDamageMultiplier).round();
    }

    // 闪避判定
    bool isDodged = _rollDodge(defender);
    if (isDodged) {
      return (damage: 0, critical: false, dodged: true, effectNote: null);
    }

    // 暗金效果：反伤（龙鳞宝甲）
    // 在受到伤害时处理，这里只处理攻击方的效果

    // 嗜血效果（攻击者有嗜血状态）
    String? effectNote;
    if (attacker.statusEffects.any((e) => e.type == StatusEffectType.lifesteal)) {
      final lifestealEffect = attacker.statusEffects
          .firstWhere((e) => e.type == StatusEffectType.lifesteal);
      final healAmount = (baseDamage * lifestealEffect.value / 100).round();
      attacker.health = (attacker.health + healAmount)
          .clamp(0, attacker.maxHealth);
      effectNote = '嗜血回复${healAmount}点生命';
    }

    // 暗金效果：击杀回复内力
    // 在敌人死亡时处理

    // 心法效果："杀意" — 杀人越多伤害越高
    if (heartMantra != null &&
        heartMantra.category == HeartMantraCategory.stackingBonus) {
      final perStack =
          (heartMantra.params['perStack'] as num?)?.toDouble() ?? 5;
      final maxStack =
          (heartMantra.params['maxStack'] as num?)?.toDouble() ?? 50;
      final bonus = (perStack * attacker.killStacks).clamp(0, maxStack);
      baseDamage = (baseDamage * (1 + bonus / 100)).round();
    }

    return (damage: baseDamage, critical: isCritical, dodged: false, effectNote: effectNote);
  }

  // =================== 真气逆行检测 ===================

  /// 真气逆行检测（DESIGN.md 3.6）
  ///
  /// 触发条件：
  /// 1. 经脉相克：同时激活相克经脉（如少阳+少阴）
  /// 2. 内功外功冲突：阳刚内功强行配阴柔外功
  /// 3. 强制高阶：熟练度不够强行使用高阶武功
  ///
  /// 返回真气逆行程度（none/mild/moderate/severe）
  QiDeviationLevel _checkQiDeviation({
    required Character player,
    required List<MartialArt> martialArts,
    required HeartMantra? heartMantra,
  }) {
    // 心法"天人合一"免疫真气逆行
    if (heartMantra != null && heartMantra.immuneToQiDeviation) {
      return QiDeviationLevel.none;
    }

    // 暗金"玄冰玉佩"免疫经脉相克
    // (由 uniqueEffects 传入时检查)

    QiDeviationLevel deviation = QiDeviationLevel.none;

    // 1. 经脉相克检测
    final openMeridians = player.meridians.where((m) => m.isOpen).toList();
    final yangOpen = openMeridians.any((m) => m.meridianId.startsWith('yang_') || m.meridianId.startsWith('mer_yang'));
    final yinOpen = openMeridians.any((m) => m.meridianId.startsWith('yin_') || m.meridianId.startsWith('mer_yin'));
    if (yangOpen && yinOpen) {
      // 同时激活阴阳经脉 → 真气逆行
      deviation = QiDeviationLevel.mild;
    }

    // 2. 内功外功冲突检测
    final internalArts = martialArts.where((m) => m.type == MartialType.internal).toList();
    final externalArts = martialArts.where((m) => m.type == MartialType.external).toList();
    for (final internal in internalArts) {
      for (final external in externalArts) {
        if (internal.elementAffinity.conflictsWith(external.elementAffinity)) {
          // 阳刚内功配阴柔外功 → 相克
          if (deviation.index < QiDeviationLevel.moderate.index) {
            deviation = QiDeviationLevel.moderate;
          }
        }
      }
    }

    // 3. 强制高阶武功检测
    for (final art in martialArts) {
      if (art.proficiency < art.proficiencyLevel.minProficiency + 10 &&
          art.proficiencyLevel.index >= ProficiencyLevel.major.index) {
        // 熟练度不够但使用高阶武功
        if (deviation.index < QiDeviationLevel.mild.index) {
          deviation = QiDeviationLevel.mild;
        }
      }
    }

    return deviation;
  }

  /// 真气逆行效果（DESIGN.md 3.6.3）
  ///
  /// 根据真气逆行程度在战斗中触发随机负面效果
  ({int hpLoss, int energyLoss, String? effectDesc}) _applyQiDeviationEffect(
      QiDeviationLevel deviation, Combatant player) {
    if (deviation == QiDeviationLevel.none) {
      return (hpLoss: 0, energyLoss: 0, effectDesc: null);
    }

    switch (deviation) {
      case QiDeviationLevel.mild:
        // 轻度：内力恢复-30%，偶尔出招失误
        final energyLoss = (player.maxInnerEnergy * 0.05).round();
        player.innerEnergy = (player.innerEnergy - energyLoss).clamp(0, player.maxInnerEnergy);
        // 10%概率出招失误（伤害减半）
        if (_random.nextInt(10) == 0) {
          return (hpLoss: 0, energyLoss: energyLoss, effectDesc: '真气逆行：出招失误，伤害减半');
        }
        return (hpLoss: 0, energyLoss: energyLoss, effectDesc: '真气逆行：内力紊乱');

      case QiDeviationLevel.moderate:
        // 中度：随机负面效果，属性波动
        final energyLoss = (player.maxInnerEnergy * 0.1).round();
        player.innerEnergy = (player.innerEnergy - energyLoss).clamp(0, player.maxInnerEnergy);
        // 20%概率属性波动
        if (_random.nextInt(5) == 0) {
          player.addStatusEffect(StatusEffect(
            type: StatusEffectType.attackDown,
            stacks: 1,
            remainingTurns: 2,
            value: 5,
            isPlayer: true,
          ));
          return (hpLoss: 0, energyLoss: energyLoss, effectDesc: '真气逆行：攻击力下降');
        }
        return (hpLoss: 0, energyLoss: energyLoss, effectDesc: '真气逆行：内力波动');

      case QiDeviationLevel.severe:
        // 重度：每回合损血，属性暴增（高风险高收益）
        final hpLoss = (player.maxHealth * 0.05).round();
        player.health = (player.health - hpLoss).clamp(0, player.maxHealth);
        // 属性暴增
        player.addStatusEffect(StatusEffect(
          type: StatusEffectType.attackUp,
          stacks: 1,
          remainingTurns: 1,
          value: (player.externalAttack * 0.3).round(),
          isPlayer: true,
        ));
        return (hpLoss: hpLoss, energyLoss: 0, effectDesc: '真气逆行[重度]：损血但攻击力暴增');

      default:
        return (hpLoss: 0, energyLoss: 0, effectDesc: null);
    }
  }

  // =================== Boss阶段管理 ===================

  /// Boss原始属性缓存（用于阶段切换时从原始值计算，避免累积叠加）
  int? _originalEnemyAtk;
  int? _originalEnemyIAtk;
  int? _originalEnemyDef;

  /// 检查Boss阶段切换（DESIGN.md 3.4.5 多阶段Boss）
  ///
  /// Boss战根据血量百分比切换阶段，每阶段有不同机制。
  /// 属性倍率基于原始值计算（非累积叠加），避免多次阶段切换后属性膨胀。
  ({BossPhase? currentPhase, int? newPhase, String? phaseNarration}) _checkBossPhase(
      Boss boss, Combatant enemy, int currentPhase) {
    final healthPct = enemy.healthPct;
    final (phase, _) = boss.getCurrentPhase(healthPct);

    if (phase != null && phase.phase != currentPhase) {
      // 首次阶段切换时保存原始属性
      _originalEnemyAtk ??= enemy.externalAttack;
      _originalEnemyIAtk ??= enemy.internalAttack;
      _originalEnemyDef ??= enemy.defense;

      // 阶段切换！从原始属性值计算倍率（非累积叠加）
      enemy.externalAttack =
          (_originalEnemyAtk! * phase.attackMultiplier).round();
      enemy.internalAttack =
          (_originalEnemyIAtk! * phase.attackMultiplier).round();
      enemy.defense =
          (_originalEnemyDef! * phase.defenseMultiplier).round();

      // 应用新增机制
      for (final mechanic in phase.addedMechanics) {
        _applyEnemyMechanic(enemy, mechanic);
      }

      // 生成阶段切换描写
      final narration = _narration.generatePhaseSwitchNarration(
        bossName: boss.name,
        newPhase: phase.phase,
        playerPower: 0, // 由外部传入更好，这里简化
      );

      return (currentPhase: phase, newPhase: phase.phase, phaseNarration: narration);
    }

    return (currentPhase: null, newPhase: null, phaseNarration: null);
  }

  /// 应用敌人机制到战斗参与者
  void _applyEnemyMechanic(Combatant enemy, EnemyMechanic mechanic) {
    switch (mechanic.type) {
      case MechanicType.enrage:
        // 狂暴：攻击力+，防御力-
        enemy.addStatusEffect(StatusEffect(
          type: StatusEffectType.enrage,
          stacks: 1,
          remainingTurns: 999, // 持续到战斗结束
          isPlayer: false,
        ));
        break;
      case MechanicType.continuousHeal:
        // 持续回血 → 每回合恢复生命
        enemy.addStatusEffect(StatusEffect(
          type: StatusEffectType.regeneration, // 使用专门的持续回血类型
          stacks: 1,
          remainingTurns: 999,
          value: (mechanic.params['perTurn'] as num?)?.toInt() ?? 10,
          isPlayer: false,
        ));
        break;
      case MechanicType.lifesteal:
        enemy.addStatusEffect(StatusEffect(
          type: StatusEffectType.lifesteal,
          stacks: 1,
          remainingTurns: 999,
          value: (mechanic.params['pct'] as num?)?.toInt() ?? 15,
          isPlayer: false,
        ));
        break;
      case MechanicType.reflectDamage:
        // 反伤：给敌人挂 reflect 状态效果，受伤时按 pct 反弹给攻击者
        enemy.addStatusEffect(StatusEffect(
          type: StatusEffectType.reflect,
          stacks: 1,
          remainingTurns: 999, // 持续到战斗结束
          value: (mechanic.params['pct'] as num?)?.toInt() ?? 15,
          isPlayer: false,
        ));
        break;
      case MechanicType.counterMelee:
        // 反击近战：同 reflectDamage 处理（近战反击，伤害按 counterDamage 比例）
        final counterPct =
            ((mechanic.params['counterDamage'] as num?)?.toDouble() ?? 0.3) * 100;
        enemy.addStatusEffect(StatusEffect(
          type: StatusEffectType.reflect,
          stacks: 1,
          remainingTurns: 999,
          value: counterPct.round(),
          isPlayer: false,
        ));
        break;
      case MechanicType.shield:
        // 护盾：定期减伤（简化：常驻减伤状态效果）
        enemy.addStatusEffect(StatusEffect(
          type: StatusEffectType.shield,
          stacks: 1,
          remainingTurns: 999,
          value: (mechanic.params['damageReductionPct'] as num?)?.toInt() ?? 50,
          isPlayer: false,
        ));
        break;
      case MechanicType.innerDrain:
        // 内力流失：敌人每回合抽取玩家内力
        enemy.innerDrainPerTurn =
            (mechanic.params['perTurn'] as num?)?.toInt() ?? 10;
        break;
      case MechanicType.disableLightness:
        // 禁轻功：玩家闪避失效。由 initRuntime 在双方战斗体就绪后
        // 对玩家侧挂 dodgeDown 状态效果实现（此处仅标记不处理）。
        break;
      default:
        break;
    }
  }

  // =================== 回合内多动作 ===================

  /// 执行一个动作（DESIGN.md 3.2.2 回合内多动作）
  ///
  /// 动作类型：出招/运功/闪避/反击
  BattleAction _executeAction({
    required Combatant attacker,
    required Combatant defender,
    required BattleTier tier,
    required List<MartialArt> attackerArts,
    required List<UniqueEffect> uniqueEffects,
    required HeartMantra? heartMantra,
    required int playerPower,
    int? bossPhase,
    BattleActionType? forcedAction,
  }) {
    // 选择武功（从主动招式中随机选取）
    final activeArts =
        attackerArts.where((m) => m.isActive).toList();
    final skill = activeArts.isNotEmpty
        ? activeArts[_random.nextInt(activeArts.length)]
        : null;

    // 动作类型：forcedAction 非空（UI 真回合制传入玩家选择）时直接采用；
    // 否则走简化AI（大部分时间出招，偶尔运功/闪避）——敌人侧与 executeBattle
    // 旧路径（forcedAction=null）保持行为等价。
    BattleActionType actionType;
    if (forcedAction != null) {
      actionType = forcedAction;
    } else {
      final actionRoll = _random.nextInt(10);
      if (actionRoll < 7) {
        actionType = BattleActionType.attack;
      } else if (actionRoll < 9) {
        actionType = BattleActionType.channel;
      } else {
        actionType = BattleActionType.dodge;
      }
    }

    // 运功：恢复内力
    if (actionType == BattleActionType.channel) {
      final recovery = (attacker.maxInnerEnergy * _energyRecoveryRate).round();
      attacker.innerEnergy = (attacker.innerEnergy + recovery)
          .clamp(0, attacker.maxInnerEnergy);

      // 生成描写
      final ctx = NarrationContext(
        tier: tier,
        enemyName: defender.name,
        skillName: skill?.name ?? '运功',
        martialType: skill?.type,
        energyChange: recovery,
        playerPower: playerPower,
        bossPhase: bossPhase,
      );
      final narration = _narration.generateActionNarration(ctx) ??
          '${attacker.name}运功调息，恢复了${recovery}点内力。';

      return BattleAction(
        type: BattleActionType.channel,
        actorId: attacker.id,
        isPlayer: attacker.isPlayer,
        martialArtId: skill?.id,
        energyChange: recovery,
        narration: narration,
      );
    }

    // 闪避：尝试躲避下一次攻击
    if (actionType == BattleActionType.dodge) {
      // 闪避动作不直接造成伤害，但增加下次闪避率
      attacker.addStatusEffect(StatusEffect(
        type: StatusEffectType.defenseUp,
        stacks: 1,
        remainingTurns: 1,
        value: 5,
        isPlayer: attacker.isPlayer,
      ));

      final ctx = NarrationContext(
        tier: tier,
        enemyName: defender.name,
        skillName: skill?.name ?? '闪避',
        martialType: MartialType.lightness,
        playerPower: playerPower,
        bossPhase: bossPhase,
      );
      final narration = _narration.generateActionNarration(ctx) ??
          '${attacker.name}闪身避开。';

      return BattleAction(
        type: BattleActionType.dodge,
        actorId: attacker.id,
        isPlayer: attacker.isPlayer,
        martialArtId: skill?.id,
        narration: narration,
      );
    }

    // 出招：计算伤害
    final isExternal = skill?.type == MartialType.external ||
        skill?.type == MartialType.lightness ||
        skill == null;

    // 武器伤害（玩家方从装备获取，敌方用基础攻击力）
    final weaponDamage = attacker.isPlayer
        ? (attacker.effectiveAttack * 0.3).round() // 简化：30%攻击力作为武器伤害
        : 0;

    final damageResult = _calculateDamage(
      attacker: attacker,
      defender: defender,
      skill: skill,
      isExternal: isExternal,
      weaponDamage: weaponDamage,
      uniqueEffects: uniqueEffects,
      heartMantra: heartMantra,
    );

    // 应用伤害（elite 护盾减伤后 actualDamage 与 damageResult 可能不同）
    var effectiveDamage = damageResult.damage;
    if (!damageResult.dodged && damageResult.damage > 0) {
      // 会话修正：破煞 buff — 对精英敌人伤害 ×1.2
      if (attacker.damageBonusVsElite > 1.0 && defender.isElite) {
        effectiveDamage =
            (effectiveDamage * attacker.damageBonusVsElite).round();
      }
      // 精英机制：护盾减伤（elite shield 机制）
      final eliteShieldEffect = defender.statusEffects
          .where((e) => e.type == StatusEffectType.shield && !e.isPlayer)
          .firstOrNull;
      if (eliteShieldEffect != null) {
        effectiveDamage =
            (effectiveDamage * (100 - eliteShieldEffect.value) / 100).round();
        if (effectiveDamage < 1) effectiveDamage = 1;
      }
      // 会话修正：铁骨 buff — 玩家受伤 ×0.85
      if (defender.isPlayer && defender.damageTakenMultiplier < 1.0) {
        effectiveDamage =
            (effectiveDamage * defender.damageTakenMultiplier).round();
        if (effectiveDamage < 1) effectiveDamage = 1;
      }
      defender.health =
          (defender.health - effectiveDamage).clamp(0, defender.maxHealth);

      // 精英机制：反伤/反击（reflect 状态效果，按 pct 反弹给攻击者）
      final reflectStatus = defender.statusEffects
          .where((e) => e.type == StatusEffectType.reflect)
          .firstOrNull;
      if (reflectStatus != null && defender.health > 0) {
        final reflectDmg =
            (effectiveDamage * reflectStatus.value / 100).round();
        if (reflectDmg > 0) {
          attacker.health =
              (attacker.health - reflectDmg).clamp(0, attacker.maxHealth);
        }
      }

      // 暗金效果：反伤（龙鳞宝甲）
      final reflectEffect = uniqueEffects.where((e) =>
          e.id == 'fx_dragon_reflect').firstOrNull;
      if (reflectEffect != null && defender.health > 0) {
        final procChance =
            (reflectEffect.params['procChance'] as num?)?.toDouble() ?? 0.3;
        final reflectPct =
            (reflectEffect.params['reflectPercent'] as num?)?.toDouble() ?? 50;
        if (_random.nextDouble() < procChance) {
          final reflectDmg = (damageResult.damage * reflectPct / 100).round();
          attacker.health = (attacker.health - reflectDmg).clamp(0, attacker.maxHealth);
        }
      }

      // 暗金效果：护体龙罡
      final shieldEffect = uniqueEffects.where((e) =>
          e.id == 'fx_dragon_shield').firstOrNull;
      if (shieldEffect != null) {
        defender.addStatusEffect(StatusEffect(
          type: StatusEffectType.shield,
          stacks: 1,
          remainingTurns: 2,
          value: (reflectEffect?.params['damageReductionPct'] as num?)?.toInt() ?? 20,
          isPlayer: defender.isPlayer,
        ));
      }

      // 冰寒效果（玄冰玉佩）
      final iceEffect = uniqueEffects.where((e) =>
          e.id == 'fx_ice_chill').firstOrNull;
      if (iceEffect != null) {
        defender.addStatusEffect(StatusEffect(
          type: StatusEffectType.chill,
          stacks: 1,
          remainingTurns: 3,
          isPlayer: defender.isPlayer,
        ));
      }

      // 中毒效果（毒珠类装备）
      // 简化处理：10%概率施加中毒
      if (_random.nextInt(10) == 0) {
        defender.addStatusEffect(StatusEffect(
          type: StatusEffectType.poison,
          stacks: 1,
          remainingTurns: 3,
          value: (damageResult.damage * 0.05).round(),
          isPlayer: defender.isPlayer,
        ));
      }
    }

    // 内力消耗
    final energyCost = skill?.energyCost ?? 0;
    if (energyCost > 0) {
      attacker.innerEnergy = (attacker.innerEnergy - energyCost)
          .clamp(0, attacker.maxInnerEnergy);
    }

    // 生成描写
    final ctx = NarrationContext(
      tier: tier,
      enemyName: defender.name,
      skillName: skill?.name ?? '普通攻击',
      martialType: skill?.type,
      damage: effectiveDamage,
      isCritical: damageResult.critical,
      isDodged: damageResult.dodged,
      effectNote: damageResult.effectNote,
      playerPower: playerPower,
      bossPhase: bossPhase,
    );
    final narration = _narration.generateActionNarration(ctx) ??
        '${attacker.name}使用${skill?.name ?? "攻击"}，对${defender.name}造成了$effectiveDamage点伤害。';

    return BattleAction(
      type: BattleActionType.attack,
      actorId: attacker.id,
      isPlayer: attacker.isPlayer,
      martialArtId: skill?.id,
      damage: effectiveDamage,
      damageTaken: damageResult.dodged ? 0 : effectiveDamage,
      dodged: damageResult.dodged,
      critical: damageResult.critical,
      energyChange: -energyCost,
      narration: narration,
      effectNote: damageResult.effectNote,
    );
  }

  /// 执行一回合（双方各做2-3个动作）
  BattleTurn _executeTurn({
    required int turnNumber,
    required Combatant player,
    required Combatant enemy,
    required BattleTier tier,
    required List<MartialArt> playerArts,
    required List<MartialArt> enemyArts,
    required List<UniqueEffect> playerUniqueEffects,
    required List<UniqueEffect> enemyUniqueEffects,
    required HeartMantra? heartMantra,
    required QiDeviationLevel qiDeviation,
    required int playerPower,
    int? currentBossPhase,
    BattleActionType? forcedPlayerAction,
  }) {
    final actions = <BattleAction>[];
    final playerHpStart = player.health;
    final enemyHpStart = enemy.health;

    // 真气逆行效果
    if (qiDeviation != QiDeviationLevel.none && player.isPlayer) {
      final deviationEffect = _applyQiDeviationEffect(qiDeviation, player);
      if (deviationEffect.effectDesc != null) {
        actions.add(BattleAction(
          type: BattleActionType.skill,
          actorId: 'player',
          isPlayer: true,
          narration: deviationEffect.effectDesc!,
          effectNote: '真气逆行',
        ));
      }
    }

    // 决定先手
    final playerFirst = player.effectiveInitiative >= enemy.effectiveInitiative;

    // 每方做2-3个动作
    final actionsPerSide = 2 + _random.nextInt(2); // 2 or 3
    // 玩家选择只施加到本回合玩家的第一个动作（随后动作走AI衔接）
    var pendingPlayerAction = forcedPlayerAction;

    for (var i = 0; i < actionsPerSide; i++) {
      // 玩家先手
      if (playerFirst) {
        if (!player.isAlive || !enemy.isAlive) break;
        actions.add(_executeAction(
          attacker: player,
          defender: enemy,
          tier: tier,
          attackerArts: playerArts,
          uniqueEffects: playerUniqueEffects,
          heartMantra: heartMantra,
          playerPower: playerPower,
          bossPhase: currentBossPhase,
          forcedAction: pendingPlayerAction,
        ));
        pendingPlayerAction = null;
        if (!player.isAlive || !enemy.isAlive) break;
        actions.add(_executeAction(
          attacker: enemy,
          defender: player,
          tier: tier,
          attackerArts: enemyArts,
          uniqueEffects: enemyUniqueEffects,
          heartMantra: null,
          playerPower: playerPower,
          bossPhase: currentBossPhase,
        ));
      } else {
        // 敌人先手
        if (!player.isAlive || !enemy.isAlive) break;
        actions.add(_executeAction(
          attacker: enemy,
          defender: player,
          tier: tier,
          attackerArts: enemyArts,
          uniqueEffects: enemyUniqueEffects,
          heartMantra: null,
          playerPower: playerPower,
          bossPhase: currentBossPhase,
        ));
        if (!player.isAlive || !enemy.isAlive) break;
        actions.add(_executeAction(
          attacker: player,
          defender: enemy,
          tier: tier,
          attackerArts: playerArts,
          uniqueEffects: playerUniqueEffects,
          heartMantra: heartMantra,
          playerPower: playerPower,
          bossPhase: currentBossPhase,
          forcedAction: pendingPlayerAction,
        ));
        pendingPlayerAction = null;
      }
    }

    // 回合结束处理：状态效果过期、生命/内力恢复
    player.processStatusEffects();
    enemy.processStatusEffects();

    // 生命/内力自然恢复（微量；含会话修正：气盈/灵泉涌动乘数）
    final hpRegen =
        (player.maxHealth * _hpRecoveryRate * player.hpRegenMultiplier).round();
    player.health = (player.health + hpRegen).clamp(0, player.maxHealth);
    final ieRegen = (player.maxInnerEnergy *
            _energyRecoveryRate *
            player.energyRegenMultiplier)
        .round();
    player.innerEnergy =
        (player.innerEnergy + ieRegen).clamp(0, player.maxInnerEnergy);

    // 精英机制：内力流失（innerDrain —— 敌人每回合抽取玩家内力）
    if (enemy.innerDrainPerTurn > 0 && player.innerEnergy > 0) {
      final drained = enemy.innerDrainPerTurn > player.innerEnergy
          ? player.innerEnergy
          : enemy.innerDrainPerTurn;
      player.innerEnergy -= drained;
      enemy.innerEnergy =
          (enemy.innerEnergy + drained).clamp(0, enemy.maxInnerEnergy);
      actions.add(BattleAction(
        type: BattleActionType.skill,
        actorId: enemy.id,
        isPlayer: false,
        narration: '${enemy.name}侵蚀你的经脉，吸取了$drained点内力！',
        effectNote: '内力流失',
      ));
    }

    // 敌人持续回血机制（regeneration类型效果）
    for (final e in enemy.statusEffects.where((e) => e.type == StatusEffectType.regeneration)) {
      if (e.value > 0 && e.isPlayer == false) {
        enemy.health = (enemy.health + e.value).clamp(0, enemy.maxHealth);
      }
    }

    // 生成回合描写
    final turnNarration = actions.map((a) => a.narration).join(' ');

    return BattleTurn(
      turnNumber: turnNumber,
      actions: actions,
      playerHealthStart: playerHpStart,
      playerHealthEnd: player.health,
      enemyHealthStart: enemyHpStart,
      enemyHealthEnd: enemy.health,
      narration: turnNarration,
    );
  }

  // =================== BD流派画像 ===================

  /// 分析BD流派画像（DESIGN.md 3.4.4）
  ///
  /// 系统分析当前BD，生成流派名称和画像描述。
  BDArchetype _analyzeBDArchetype(Character player) {
    final arts = player.martialArts;
    final hasInternal = arts.any((m) => m.type == MartialType.internal);
    final hasExternal = arts.any((m) => m.type == MartialType.external);
    final hasLightness = arts.any((m) => m.type == MartialType.lightness);

    final yangArts = arts.where((m) => m.elementAffinity == ElementAffinity.yang).length;
    final yinArts = arts.where((m) => m.elementAffinity == ElementAffinity.yin).length;
    final neutralArts = arts.where((m) => m.elementAffinity == ElementAffinity.neutral).length;

    // 经脉方向
    final openMeridians = player.meridians.where((m) => m.isOpen).toList();
    final yangMeridians = openMeridians.where((m) =>
        m.meridianId.contains('yang')).length;
    final yinMeridians = openMeridians.where((m) =>
        m.meridianId.contains('yin')).length;

    // 判定流派
    if (hasExternal && yangArts > yinArts && yangMeridians > yinMeridians) {
      return const BDArchetype(
        name: '刚猛一路',
        description: '内功浑厚、外功霸道、不善轻功。经脉走少阳纯阳一路。适合正面硬撼，弱于闪避反击。',
      );
    }
    if (hasExternal && yinArts > yangArts && yinMeridians > yangMeridians) {
      return const BDArchetype(
        name: '阴柔一路',
        description: '内力绵密、外功灵动、身法飘逸。经脉走太阴玄阴一路。适合游击缠斗，弱于正面硬撼。',
      );
    }
    if (hasLightness && !hasExternal) {
      return const BDArchetype(
        name: '身法一路',
        description: '轻功卓绝、闪避如风、攻守兼备。专以快打慢、以巧破力。',
      );
    }
    if (yangMeridians > 0 && yinMeridians > 0) {
      return const BDArchetype(
        name: '双修流',
        description: '阴阳并修、刚柔并济。高风险高收益路线，需以心法或装备压制真气逆行。',
      );
    }
    if (player.heartMantraId != null) {
      return const BDArchetype(
        name: '心法流',
        description: '以心法改规则为核心，不拘泥于属性堆叠。走的是以巧破力的路子。',
      );
    }
    return const BDArchetype(
      name: '杂学一路',
      description: '博采众长但不够精深，尚未形成明确流派。',
    );
  }

  // =================== 主战斗接口 ===================

  /// 执行一场完整战斗
  ///
  /// [player] 玩家角色
  /// [enemy] 敌人（普通Enemy或Boss）
  /// [realmId] 秘境ID
  /// [layer] 层数
  /// [difficulty] 难度
  /// [isAutoRun] 是否连刷模式
  /// [pity] 保底计数器（可选，用于掉落）
  ///
  /// 返回战斗结果
  // =================== 真回合制运行时（DESIGN.md 3.2.2 重构） ===================

  /// 初始化一场战斗的运行时状态。
  ///
  /// 手动模式与自动托管逐回合调用 [stepTurn]，连刷路径仍走 [executeBattle]。
  /// 传入原始（未缩放）敌人，缩放在此内部完成；与 [executeBattle] 的档位
  /// 判定顺序严格一致以保证随机序列与行为等价。
  BattleRuntimeState initRuntime({
    required Character player,
    required Enemy enemy,
    required String realmId,
    required int layer,
    required Difficulty difficulty,
    PityCounter? pity,
    SessionMods mods = const SessionMods(),
  }) {
    // 1. 敌人难度缩放（含秘境模组：血月之夜敌人全属性 ×1.2）
    final scaledEnemy = enemy.scaleByDifficulty(difficulty);
    final moddedEnemy = mods.enemyPowerMultiplier != 1.0
        ? scaledEnemy.copyWith(
            health: (scaledEnemy.health * mods.enemyPowerMultiplier).round(),
            externalAttack: (scaledEnemy.externalAttack * mods.enemyPowerMultiplier).round(),
            internalAttack: (scaledEnemy.internalAttack * mods.enemyPowerMultiplier).round(),
            defense: (scaledEnemy.defense * mods.enemyPowerMultiplier).round(),
            powerIndex: (scaledEnemy.powerIndex * mods.enemyPowerMultiplier).round(),
          )
        : scaledEnemy;

    // 2. 判定战斗档位
    final tier = _determineTier(
      playerPower: player.powerIndex,
      enemyPower: moddedEnemy.powerIndex,
      isBoss: enemy is Boss || enemy.isElite,
    );

    // 3. 构建战斗参与者
    final playerCombatant = _buildPlayerCombatant(player);
    final enemyCombatant = _buildEnemyCombatant(moddedEnemy);

    // 3.1 会话修正落位（模块 3：纯数值调整，不引入新 RNG 源）
    if (!mods.isEmpty) {
      // 血怒：暴击率 +15
      playerCombatant.critRate =
          (playerCombatant.critRate + mods.critBonus).clamp(0, 50);
      // 迅影：闪避率 +10
      playerCombatant.dodgeRate =
          (playerCombatant.dodgeRate + mods.dodgeBonus).clamp(0, 75);
      // 铁骨：受伤 ×0.85
      playerCombatant.damageTakenMultiplier = mods.damageReduction;
      // 破煞：对精英伤害 ×1.2（只对玩家有意义）
      playerCombatant.damageBonusVsElite = mods.eliteDamageBonus;
      // 气盈：内力恢复 ×1.2
      playerCombatant.energyRegenMultiplier = mods.energyRegenBonus;
      // 灵泉涌动（mod）：气血恢复 ×1.5
      playerCombatant.hpRegenMultiplier = mods.hpRegenMultiplier;
      // 标记敌人精英身份（破煞判定用）
      enemyCombatant.isElite = enemy.isElite;
    }

    // 4. 获取玩家武功列表（敌人无武功配置，简化）
    final playerArts = player.martialArts;
    final enemyArts = <MartialArt>[];

    // 5. 获取心法
    HeartMantra? heartMantra;
    if (player.heartMantraId != null) {
      final mantraConfig = _config.getMartialArtConfig(player.heartMantraId!);
      if (mantraConfig != null) {
        heartMantra = HeartMantra(
          id: mantraConfig.id,
          name: mantraConfig.name,
          effectDescription: mantraConfig.description,
          category: HeartMantraCategory.ruleChange,
          params: {},
        );
      }
    }

    // 6. 真气逆行检测
    final qiDeviation = _checkQiDeviation(
      player: player,
      martialArts: playerArts,
      heartMantra: heartMantra,
    );

    // 7. 玩家装备暗金效果列表（与 executeBattle 一致：简化空表）
    final playerUniqueEffects = <UniqueEffect>[];

    // 8. 敌人机制
    for (final mechanic in moddedEnemy.mechanics) {
      _applyEnemyMechanic(enemyCombatant, mechanic);
      if (mechanic.type == MechanicType.disableLightness) {
        // 禁轻功：玩家侧闪避减半（挂在玩家身上才生效）
        playerCombatant.addStatusEffect(StatusEffect(
          type: StatusEffectType.dodgeDown,
          stacks: 1,
          remainingTurns: 999,
          value: 50,
          isPlayer: true,
        ));
      }
    }

    // 9. 心法「先发制人」标记（⚠️ 原 executeBattle 中为死代码从未消费；
    //    为保持行为逐位等价，此处同样只记录不消费，留待后续玩法接线）
    bool extraFirstTurn = false;
    if (heartMantra != null &&
        heartMantra.category == HeartMantraCategory.actionBonus) {
      if (playerCombatant.effectiveInitiative > enemyCombatant.effectiveInitiative) {
        extraFirstTurn = true;
      }
    }

    // 10. 叙述去重计数器只重置一次
    _narration.resetRecentUse();

    final maxTurns = _determineMaxTurns(tier);

    return BattleRuntimeState(
      player: player,
      enemy: enemy,
      realmId: realmId,
      layer: layer,
      difficulty: difficulty,
      pity: pity,
      tier: tier,
      playerCombatant: playerCombatant,
      enemyCombatant: enemyCombatant,
      playerArts: playerArts,
      enemyArts: enemyArts,
      playerUniqueEffects: playerUniqueEffects,
      enemyUniqueEffects: const [],
      heartMantra: heartMantra,
      qiDeviation: qiDeviation,
      maxTurns: maxTurns,
      extraFirstTurn: extraFirstTurn,
      mods: mods,
    );
  }

  /// 推进一回合，返回本回合明细。
  ///
  /// 与 executeBattle 原回合循环的顺序严格一致：Boss阶段检查 → _executeTurn →
  /// 阶段切换描写合并 → 胜负判定。调用者用 [isBattleOver] 判断是否继续。
  BattleTurn stepTurn(BattleRuntimeState st) {
    // Boss阶段检查（用原始 enemy 判定，缩放后仍保留 Boss 类型）
    if (st.enemy is Boss && (st.enemy as Boss).phases.isNotEmpty) {
      final phaseResult =
          _checkBossPhase(st.enemy as Boss, st.enemyCombatant, st.currentBossPhase);
      if (phaseResult.newPhase != null) {
        st.currentBossPhase = phaseResult.newPhase!;
        st.pendingPhaseNarration = phaseResult.phaseNarration;
      }
    }

    // 执行回合
    final turn = _executeTurn(
      turnNumber: st.turns.length + 1,
      player: st.playerCombatant,
      enemy: st.enemyCombatant,
      tier: st.tier,
      playerArts: st.playerArts,
      enemyArts: st.enemyArts,
      playerUniqueEffects: st.playerUniqueEffects,
      enemyUniqueEffects: st.enemyUniqueEffects,
      heartMantra: st.heartMantra,
      qiDeviation: st.qiDeviation,
      playerPower: st.player.powerIndex,
      currentBossPhase: st.currentBossPhase,
      forcedPlayerAction: st.consumePlayerAction(),
    );

    // Boss阶段切换描写追加到回合描写
    BattleTurn resultTurn;
    if (st.pendingPhaseNarration != null) {
      resultTurn = BattleTurn(
        turnNumber: turn.turnNumber,
        actions: turn.actions,
        playerHealthStart: turn.playerHealthStart,
        playerHealthEnd: turn.playerHealthEnd,
        enemyHealthStart: turn.enemyHealthStart,
        enemyHealthEnd: turn.enemyHealthEnd,
        narration: '${turn.narration}\n${st.pendingPhaseNarration}',
      );
      st.pendingPhaseNarration = null;
    } else {
      resultTurn = turn;
    }
    st.turns.add(resultTurn);

    // 检查战斗是否结束（任一方倒下，或回合数耗尽）
    if (!st.playerCombatant.isAlive ||
        !st.enemyCombatant.isAlive ||
        st.turns.length >= st.maxTurns) {
      st.battleOver = true;
    }

    return resultTurn;
  }

  /// 战斗是否已结束（任一方倒下）
  bool isBattleOver(BattleRuntimeState st) => st.battleOver;

  /// 智能托管的选招规则（DESIGN.md 3.2.2 智能托管）：
  /// 气血<30% 且内力够 → 运功；内力近满 → 出招爆发；否则普攻。
  /// UI 托管模式下每秒调用一次并用返回值 setPlayerAction + stepTurn。
  BattleActionType chooseAutoAction(BattleRuntimeState st) {
    final p = st.playerCombatant;
    if (p.isAlive && p.health <= p.maxHealth * 0.3 && p.innerEnergy >= 10) {
      return BattleActionType.channel;
    }
    return BattleActionType.attack;
  }

  /// 结算战斗结果（胜负判定、描写、BD画像、掉落、BattleResult 组装）
  /// [isAutoRun] 透传给掉落引擎与结果标记。
  BattleResult finishBattle(BattleRuntimeState st, {bool isAutoRun = false}) {
    // 判定胜负
    final victory =
        st.enemyCombatant.isAlive == false && st.playerCombatant.isAlive;
    final turnsUsed = st.turns.length;

    // 生成战斗描写全文
    final fullNarration = st.turns.map((t) => t.narration).join('\n');
    final resultNarration = _narration.generateResultNarration(
      victory: victory,
      tier: st.tier,
      enemyName: st.enemy.name,
      turnsUsed: turnsUsed,
    );
    final completeNarration = '$fullNarration\n$resultNarration';

    // BD流派画像
    final archetype = _analyzeBDArchetype(st.player);

    // 掉落
    final drops = <DropResult>[];
    if (victory && _dropEngine != null) {
      final effectivePity =
          st.pity ?? const PityCounter(dropTableId: 'default', count: 0);
      final enemy = st.enemy;
      final dropTableId = enemy is Boss
          ? (enemy.bossDropTableId?.isNotEmpty == true
              ? enemy.bossDropTableId
              : enemy.dropTableId)
          : enemy.dropTableId;
      if (dropTableId != null && dropTableId.isNotEmpty) {
        // Boss 一场掉 2-3 件（掉落爆发），普通敌人 1 件，碾压/连刷保持 1 件
        final dropCount = (enemy is Boss && !isAutoRun)
            ? 2 + _random.nextInt(2) // 2 or 3
            : 1;
        var pityCursor = effectivePity;
        for (var i = 0; i < dropCount; i++) {
          final dropResult = _dropEngine!.generateDrop(
            dropTableId: dropTableId,
            fortune: st.player.fortune,
            pity: pityCursor,
            realmId: st.realmId,
            layer: st.layer,
            sourceId: st.enemy.id,
            isAutoRun: isAutoRun,
            mods: st.mods.isEmpty ? null : st.mods,
          );
          if (dropResult != null) {
            drops.add(dropResult);
            pityCursor = dropResult.updatedPity; // 保底逐件推进
          }
        }
      }
    }

    // 生成 BattleResult
    final battleId = 'battle_${DateTime.now().millisecondsSinceEpoch}';
    String finalNarration = completeNarration;
    if (drops.isNotEmpty && _dropEngine != null) {
      final dropTexts =
          drops.map((d) => _dropEngine!.generateDropDisplayText(d)).join('\n');
      finalNarration = '$completeNarration\n$dropTexts';
    }

    return BattleResult(
      battleId: battleId,
      victory: victory,
      tier: st.tier,
      turnsUsed: turnsUsed,
      playerHealthRemaining: st.playerCombatant.health,
      enemyId: st.enemy.id,
      realmId: st.realmId,
      layer: st.layer,
      difficulty: st.difficulty,
      fullNarration: finalNarration,
      timestamp: DateTime.now(),
      bdArchetypeName: archetype.name,
      bdArchetypeDesc: archetype.description,
      isAutoRun: isAutoRun,
      drops: drops,
      killCount: victory ? 1 : 0,
      dropCount: drops.length,
      turns: st.turns,
    );
  }

  /// 执行一场完整战斗（兼容接口，行为与重构前逐位等价）
  ///
  /// 连刷/碾压路径与旧实现相同；其余路径通过 [initRuntime] + [stepTurn]
  /// + [finishBattle] 完成整场战斗。
  BattleResult executeBattle({
    required Character player,
    required Enemy enemy,
    required String realmId,
    required int layer,
    required Difficulty difficulty,
    bool isAutoRun = false,
    PityCounter? pity,
    SessionMods mods = const SessionMods(),
  }) {
    // 1. 敌人难度缩放（仅用于档位判定；initRuntime 内会再次确定性缩放）
    final scaledEnemy = enemy.scaleByDifficulty(difficulty);

    // 2. 判定战斗档位
    final isBoss = enemy is Boss || enemy.isElite;
    final tier = _determineTier(
      playerPower: player.powerIndex,
      enemyPower: scaledEnemy.powerIndex,
      isBoss: isBoss,
    );

    // 3. 连刷模式：碾压档自动结算
    if (isAutoRun && tier == BattleTier.crush) {
      return _executeCrushBattle(
        player: player,
        enemy: scaledEnemy,
        realmId: realmId,
        layer: layer,
        difficulty: difficulty,
        pity: pity,
      );
    }

    // 4. 初始化运行时状态
    final st = initRuntime(
      player: player,
      enemy: enemy,
      realmId: realmId,
      layer: layer,
      difficulty: difficulty,
      pity: pity,
      mods: mods,
    );

    // 5. 整场循环（turns.length+1 起，与旧实现 turnNum 从 1 起一致）
    for (var turnNum = st.turns.length + 1;
        turnNum <= st.maxTurns && !st.battleOver;
        turnNum++) {
      stepTurn(st);
    }

    return finishBattle(st, isAutoRun: isAutoRun);
  }

  /// 执行碾压档战斗（连刷模式，DESIGN.md 3.2.3）
  ///
  /// 碾压档：0-1回合，1句话结算，自动战斗
  BattleResult _executeCrushBattle({
    required Character player,
    required Enemy enemy,
    required String realmId,
    required int layer,
    required Difficulty difficulty,
    PityCounter? pity,
  }) {
    // 选择一个武功
    final activeArts = player.martialArts.where((m) => m.isActive).toList();
    final skill = activeArts.isNotEmpty
        ? activeArts.first
        : null;

    // 计算碾压伤害（一击必杀）
    final playerCombatant = _buildPlayerCombatant(player);
    final enemyCombatant = _buildEnemyCombatant(enemy);
    final damage = _calcExternalDamage(
      attacker: playerCombatant,
      defender: enemyCombatant,
      skill: skill,
    );

    // 生成碾压描写（1句话）
    final narration = _narration.generateCrushNarration(
      skillName: skill?.name ?? '一掌',
      enemyName: enemy.name,
      damage: damage,
      playerPower: player.powerIndex,
    );

    // 处理掉落（如有掉落引擎和保底计数器）
    final drops = <DropResult>[];
    String? dropDisplayText;
    PityCounter? updatedPity = pity;
    if (_dropEngine != null && enemy.dropTableId.isNotEmpty) {
      final effectivePity = pity ?? const PityCounter(dropTableId: 'default', count: 0);
      final dropResult = _dropEngine!.generateDrop(
        dropTableId: enemy.dropTableId,
        fortune: player.fortune,
        pity: effectivePity,
        realmId: realmId,
        layer: layer,
        sourceId: enemy.id,
        isAutoRun: true,
      );
      if (dropResult != null) {
        drops.add(dropResult);
        dropDisplayText = _dropEngine!.generateDropDisplayText(dropResult);
        updatedPity = dropResult.updatedPity;
      }
    }

    // 生成完整描写（1句话 + 掉落展示）
    final fullNarration = dropDisplayText != null
        ? '$narration\n$dropDisplayText'
        : narration;

    // BD画像
    final archetype = _analyzeBDArchetype(player);

    return BattleResult(
      battleId: 'crush_${DateTime.now().millisecondsSinceEpoch}',
      victory: true,
      tier: BattleTier.crush,
      turnsUsed: 1,
      playerHealthRemaining: player.health,
      enemyId: enemy.id,
      realmId: realmId,
      layer: layer,
      difficulty: difficulty,
      fullNarration: fullNarration,
      timestamp: DateTime.now(),
      bdArchetypeName: archetype.name,
      bdArchetypeDesc: archetype.description,
      isAutoRun: true,
      drops: drops,
      killCount: 1,
      dropCount: drops.length,
    );
  }

  /// 生成战斗状态快照（供UI实时展示）
  BattleState createBattleState({
    required String battleId,
    required BattleTier tier,
    required String realmId,
    required int layer,
    required Difficulty difficulty,
    required String enemyId,
    required int playerHealth,
    required int playerMaxHealth,
    required int enemyHealth,
    required int enemyMaxHealth,
    int currentTurn = 1,
    int maxTurns = 8,
    int playerInnerEnergy = 0,
    bool isAutoRun = false,
    QiDeviationLevel qiDeviation = QiDeviationLevel.none,
    int? bossPhase,
  }) {
    return BattleState(
      battleId: battleId,
      tier: tier,
      realmId: realmId,
      layer: layer,
      difficulty: difficulty,
      enemyId: enemyId,
      currentTurn: currentTurn,
      maxTurns: maxTurns,
      playerHealth: playerHealth,
      playerMaxHealth: playerMaxHealth,
      playerInnerEnergy: playerInnerEnergy,
      enemyHealth: enemyHealth,
      enemyMaxHealth: enemyMaxHealth,
      isAutoRun: isAutoRun,
      qiDeviation: qiDeviation,
      bossPhase: bossPhase,
    );
  }
}