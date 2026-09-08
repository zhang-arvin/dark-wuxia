// =============================================================================
// models/combatant.dart — 战斗参与者运行时状态（从 battle_engine 平移，批次1）
//
// 纯数据模型：零引擎依赖。战斗中从 Character/Enemy 提取的属性快照。
// =============================================================================

import 'enums.dart';

/// 状态效果类型（DESIGN.md 3.2.2 — buff/debuff）
///
/// 战斗中临时施加的增益/减益效果，有持续时间。
enum StatusEffectType {
  /// 攻击力+
  attackUp,
  /// 防御力+
  defenseUp,
  /// 攻击力-
  attackDown,
  /// 防御力-
  defenseDown,
  /// 中毒（每回合损血）
  poison,
  /// 冰寒（降低先手值和闪避率）
  chill,
  /// 嗜血（攻击时回复生命）
  lifesteal,
  /// 狂暴（攻击力+但防御力-）
  enrage,
  /// 护体罡气（减免下次受到伤害）
  shield,
  /// 蓄力（每回合叠层，满后爆发）
  qiAccumulation,
  /// 连击递增（每次命中同一目标伤害+）
  comboEscalation,
  /// 持续回血（每回合恢复生命）
  regeneration,
  /// 反伤（受伤时按百分比反弹给攻击者）
  reflect,
  /// 闪避下降（每层扣闪避率）
  dodgeDown,
}

/// 战斗中的状态效果实例
class StatusEffect {
  final StatusEffectType type;
  final int stacks;
  final int remainingTurns;
  final int value; // 数值参数（如攻击力+10, 每回合毒伤5等）
  final bool isPlayer; // 施加于玩家还是敌人

  const StatusEffect({
    required this.type,
    this.stacks = 1,
    this.remainingTurns = 1,
    this.value = 0,
    this.isPlayer = true,
  });

  StatusEffect copyWith({
    StatusEffectType? type,
    int? stacks,
    int? remainingTurns,
    int? value,
    bool? isPlayer,
  }) =>
      StatusEffect(
        type: type ?? this.type,
        stacks: stacks ?? this.stacks,
        remainingTurns: remainingTurns ?? this.remainingTurns,
        value: value ?? this.value,
        isPlayer: isPlayer ?? this.isPlayer,
      );

  @override
  String toString() =>
      'StatusEffect($type stacks=$stacks turns=$remainingTurns val=$value player=$isPlayer)';
}


// =============================================================================
// 战斗参与者（运行时属性快照）
// =============================================================================

/// 战斗参与者的运行时属性
///
/// 从 Character 或 Enemy 提取战斗所需的属性快照，
/// 战斗中修改这些值不影响原始对象。
class Combatant {
  final String id;
  final String name;
  final bool isPlayer;

  // 基础属性
  int health;
  int maxHealth;
  int innerEnergy;
  int maxInnerEnergy;

  // 战斗属性
  int externalAttack; // 外功攻击力
  int internalAttack; // 内功攻击力
  int defense; // 防御力
  int initiative; // 先手值
  int dodgeRate; // 闪避率 0-100
  int critRate; // 暴击率 0-100

  // 元素亲和性（用于真气逆行检测）
  ElementAffinity elementAffinity;

  // 状态效果列表
  final List<StatusEffect> statusEffects = [];

  // 连击计数（暗金断魂鞭效果）
  int comboCount = 0;

  // 蓄力层数（暗金太玄残卷效果）
  int qiAccumulationStacks = 0;

  // 杀意叠加（心法"杀意"效果）
  int killStacks = 0;

  // 是否已触发免死（心法"守拙"）
  bool deathWardUsed = false;

  /// 每回合抽取对手内力值（敌人 innerDrain 机制）
  int innerDrainPerTurn = 0;

  // --- 会话修正（模块 3：秘境模组+Buff 在 initRuntime 落位，纯乘数无新RNG） ---

  /// 受伤乘数（铁骨 buff：0.85）
  double damageTakenMultiplier = 1.0;

  /// 对精英敌人的伤害加成（破煞 buff：1.2；敌人侧默认 1.0）
  double damageBonusVsElite = 1.0;

  /// 内力恢复乘数（气盈 buff：1.2）
  double energyRegenMultiplier = 1.0;

  /// 气血恢复乘数（灵泉涌动 mod：1.5）
  double hpRegenMultiplier = 1.0;

  /// 是否为精英（用于破煞 buff 判定）
  bool isElite = false;

  Combatant({
    required this.id,
    required this.name,
    required this.isPlayer,
    required this.health,
    required this.maxHealth,
    required this.innerEnergy,
    required this.maxInnerEnergy,
    required this.externalAttack,
    required this.internalAttack,
    required this.defense,
    required this.initiative,
    required this.dodgeRate,
    required this.critRate,
    this.elementAffinity = ElementAffinity.neutral,
  });

  /// 是否存活
  bool get isAlive => health > 0;

  /// 生命百分比
  double get healthPct => maxHealth > 0 ? health / maxHealth : 0;

  /// 获取当前攻击力（含buff/debuff）
  int get effectiveAttack {
    var atk = externalAttack;
    for (final e in statusEffects) {
      switch (e.type) {
        case StatusEffectType.attackUp:
          atk += e.value * e.stacks;
          break;
        case StatusEffectType.attackDown:
          atk -= e.value * e.stacks;
          break;
        case StatusEffectType.enrage:
          atk += (atk * 0.3 * e.stacks).round();
          break;
        default:
          break;
      }
    }
    return atk < 0 ? 0 : atk;
  }

  /// 获取当前防御力（含buff/debuff）
  int get effectiveDefense {
    var def = defense;
    for (final e in statusEffects) {
      switch (e.type) {
        case StatusEffectType.defenseUp:
          def += e.value * e.stacks;
          break;
        case StatusEffectType.defenseDown:
          def -= e.value * e.stacks;
          break;
        case StatusEffectType.enrage:
          def -= (def * 0.2 * e.stacks).round();
          break;
        default:
          break;
      }
    }
    return def < 0 ? 0 : def;
  }

  /// 获取当前闪避率（含冰寒效果、禁轻功效果）
  int get effectiveDodgeRate {
    var dodge = dodgeRate;
    for (final e in statusEffects) {
      if (e.type == StatusEffectType.chill) {
        dodge -= 5 * e.stacks;
      }
      if (e.type == StatusEffectType.dodgeDown) {
        dodge = (dodge * (100 - e.value) / 100).round(); // 按百分比削减
      }
    }
    return dodge < 0 ? 0 : (dodge > 75 ? 75 : dodge);
  }

  /// 获取当前先手值（含冰寒效果）
  int get effectiveInitiative {
    var init = initiative;
    for (final e in statusEffects) {
      if (e.type == StatusEffectType.chill) {
        init -= 5 * e.stacks;
      }
    }
    return init < 0 ? 0 : init;
  }

  /// 获取当前暴击率
  int get effectiveCritRate {
    var crit = critRate;
    for (final e in statusEffects) {
      if (e.type == StatusEffectType.chill) {
        crit -= 3 * e.stacks;
      }
    }
    return crit < 0 ? 0 : (crit > 50 ? 50 : crit);
  }

  /// 添加状态效果
  void addStatusEffect(StatusEffect effect) {
    // 检查是否已有同类型效果，叠层或刷新
    final existing = statusEffects.where((e) => e.type == effect.type).toList();
    if (existing.isNotEmpty) {
      for (final e in existing) {
        // 叠层（不超过最大层数）
        final maxStacks = effect.type == StatusEffectType.chill ? 3 : 10;
        final newStacks = (e.stacks + 1).clamp(1, maxStacks);
        final idx = statusEffects.indexOf(e);
        statusEffects[idx] = e.copyWith(
          stacks: newStacks,
          remainingTurns: effect.remainingTurns > e.remainingTurns
              ? effect.remainingTurns
              : e.remainingTurns,
        );
        return;
      }
    }
    statusEffects.add(effect);
  }

  /// 回合结束处理：减少持续时间，移除过期效果
  void processStatusEffects() {
    statusEffects.removeWhere((e) {
      // 中毒每回合损血
      if (e.type == StatusEffectType.poison) {
        health -= e.value * e.stacks;
        if (health < 0) health = 0;
        return e.remainingTurns <= 1;
      }
      // 持续回血每回合恢复生命
      if (e.type == StatusEffectType.regeneration) {
        health = (health + e.value * e.stacks).clamp(0, maxHealth);
      }
      // 蓄力每回合+1层
      if (e.type == StatusEffectType.qiAccumulation) {
        qiAccumulationStacks = (qiAccumulationStacks + 1).clamp(0, 5);
      }
      return e.remainingTurns <= 1;
    });

    // 减少持续时间
    for (var i = 0; i < statusEffects.length; i++) {
      final e = statusEffects[i];
      final remaining = e.remainingTurns - 1;
      if (remaining <= 0) {
        statusEffects.removeAt(i);
        i--;
      } else {
        statusEffects[i] = e.copyWith(remainingTurns: remaining);
      }
    }
  }

  @override
  String toString() =>
      'Combatant($name hp=$health/$maxHealth ie=$innerEnergy atk=$effectiveAttack def=$effectiveDefense)';
}

