// =============================================================================
// session_mods.dart — 会话修正参数（模块 3：秘境随机模组 + Buff 三选）
//
// 贯穿「探索→战斗→掉落」三层的局内临时修正。不进存档（每局开局生成）。
//
// 设计要点：
//   - 所有加成都是纯乘数/加数，不引入新 RNG 源（不扰动战斗 RNG 序列）
//   - Modifier：开局 1 个全局规则（影响整局）
//   - Buff：每 5 步三选一（叠加，最多 3 层）
// =============================================================================

/// 秘境模组（开局随机全局规则）
enum RealmModifierType {
  /// 血月之夜：敌人全属性 +20%，掉落 +25%
  bloodMoon('血月之夜', '血月当空，妖邪横行。敌人强 20%，但掉落 +25%。'),
  /// 灵泉涌动：气血回复 +50%
  spiritSpring('灵泉涌动', '山间灵泉涌动。气血恢复速度 +50%。'),
  /// 藏宝迷窟：宝箱节点出现率翻倍
  treasureHunt('藏宝迷窟', '传闻此境宝库无数。宝箱出现率翻倍。'),
  /// 词缀共鸣：所有词缀掉率权重 +50%
  affixResonance('词缀共鸣', '天地灵机充沛。装备词缀生成率 +50%。');

  const RealmModifierType(this.displayName, this.description);
  final String displayName;
  final String description;
}

/// 局内 Buff（每 5 步三选一）
enum SessionBuffType {
  bloodfury('血怒', '暴击率 +15%'),
  ironbone('铁骨', '受到伤害 -15%'),
  greed('贪婪', '掉落品质 +10%'),
  qiFlow('气盈', '内力恢复 +20%'),
  armorBreak('破煞', '对精英敌人伤害 +20%'),
  swift('迅影', '闪避率 +10');

  const SessionBuffType(this.displayName, this.description);
  final String displayName;
  final String description;
}

/// 会话修正集合（引擎与 UI 共用的叠加层）
class SessionMods {
  final Set<SessionBuffType> buffs;
  final RealmModifierType? modifier;

  const SessionMods({this.buffs = const {}, this.modifier});

  SessionMods copyWith({
    Set<SessionBuffType>? buffs,
    RealmModifierType? modifier,
    bool clearModifier = false,
  }) =>
      SessionMods(
        buffs: buffs ?? this.buffs,
        modifier: clearModifier ? null : (modifier ?? this.modifier),
      );

  SessionMods withBuff(SessionBuffType buff) =>
      SessionMods(buffs: {...buffs, buff}, modifier: modifier);

  // ---------- 战斗侧加成 ----------

  /// 暴击率加成（百分点）
  int get critBonus => buffs.contains(SessionBuffType.bloodfury) ? 15 : 0;

  /// 受伤减免（1.0 = 无减免）
  double get damageReduction =>
      buffs.contains(SessionBuffType.ironbone) ? 0.85 : 1.0;

  /// 对精英敌人伤害加成（1.0 = 无加成）
  double get eliteDamageBonus =>
      buffs.contains(SessionBuffType.armorBreak) ? 1.2 : 1.0;

  /// 内力恢复加成（1.0 = 无加成）
  double get energyRegenBonus =>
      buffs.contains(SessionBuffType.qiFlow) ? 1.2 : 1.0;

  /// 闪避率加成（百分点）
  int get dodgeBonus => buffs.contains(SessionBuffType.swift) ? 10 : 0;

  /// 敌人全属性乘数（bloodMoon）
  double get enemyPowerMultiplier =>
      modifier == RealmModifierType.bloodMoon ? 1.2 : 1.0;

  // ---------- 掉落侧加成 ----------

  /// 掉落品质乘数（greed + bloodMoon）
  double get dropQualityMultiplier {
    var mult = 1.0;
    if (buffs.contains(SessionBuffType.greed)) mult += 0.10;
    if (modifier == RealmModifierType.bloodMoon) mult += 0.25;
    return mult;
  }

  /// 词缀生成权重乘数（affixResonance）
  double get affixWeightMultiplier =>
      modifier == RealmModifierType.affixResonance ? 1.5 : 1.0;

  // ---------- 探索侧加成 ----------

  /// 气血回复乘数（spiritSpring）
  double get hpRegenMultiplier =>
      modifier == RealmModifierType.spiritSpring ? 1.5 : 1.0;

  /// 宝箱节点权重乘数（treasureHunt）
  double get treasureWeightMultiplier =>
      modifier == RealmModifierType.treasureHunt ? 2.0 : 1.0;

  /// 简述（用于战斗页 tag / 日志）
  List<String> get summary {
    final lines = <String>[];
    if (modifier != null) lines.add(modifier!.displayName);
    lines.addAll(buffs.map((b) => b.displayName));
    return lines;
  }

  bool get isEmpty => buffs.isEmpty && modifier == null;
}

/// 从 3 个候选中随机挑选 Buff 的轮盘结果
class BuffChoice {
  final List<SessionBuffType> candidates;
  BuffChoice(this.candidates);
}