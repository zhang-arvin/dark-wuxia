// =============================================================================
// 对应 DESIGN.md 章节：
//   五、数据结构（5.1 核心数据模型 / 5.2 配置数据）
//   三、核心系统设计（3.2 战斗系统 / 3.3 装备系统 / 3.4 BD流派系统 /
//                       3.5 经脉系统 / 3.6 真气逆行 / 3.7 秘境系统 / 3.9 辅助系统）
//
// 本文件集中定义所有共用枚举，使用 Dart 3 enhanced enum 语法。
// 每个枚举携带显示名称等元数据，并提供 toJson / fromJson 序列化方法。
// =============================================================================

/// 装备品质分级（DESIGN.md 3.3.1）
///
/// | 品质 | 掉率 | 词缀数 | 特殊 | 颜色标记 |
/// |------|------|--------|------|---------|
/// | 凡品 | 55% | 1-2 | - | 白 |
/// | 良品 | 28% | 2-3 | 1附加 | 蓝 |
/// | 上品 | 12% | 3-4 | 套装属性 | 黄 |
/// | 暗金 | 3% | 固定独特+2-4随机 | 改机制 | 橙★ |
/// | 神品 | 0.5% | 多条改机制 | 主题词缀 | 红★★ |
/// | 传说 | 0.1% | 改变玩法规则 | - | 金★★★ |
enum Quality {
  normal('凡品', '白', 0.55, 1, 2, false),
  magic('良品', '蓝', 0.28, 2, 3, false),
  rare('上品', '黄', 0.12, 3, 4, false),
  unique('暗金', '橙★', 0.03, 4, 6, true),
  divine('神品', '红★★', 0.005, 5, 8, true),
  legendary('传说', '金★★★', 0.001, 6, 10, true);

  const Quality(
    this.displayName,
    this.colorTag,
    this.baseDropRate,
    this.minAffixes,
    this.maxAffixes,
    this.hasUniqueEffect,
  );

  /// 显示名称
  final String displayName;

  /// 颜色标记（UI 用）
  final String colorTag;

  /// 基础掉率
  final double baseDropRate;

  /// 最小词缀数
  final int minAffixes;

  /// 最大词缀数
  final int maxAffixes;

  /// 是否拥有改机制独特词条（暗金及以上）
  final bool hasUniqueEffect;

  /// 序列化
  String toJson() => name;

  /// 反序列化
  static Quality fromJson(String value) => Quality.values.byName(value);

  /// 是否为暗金及以上品质
  bool get isUniqueOrAbove => index >= Quality.unique.index;
}

/// 装备槽位（DESIGN.md 3.3.4）
///
/// - weapon    兵器（剑/刀/枪/鞭/扇/珠）
/// - armor     护体（布衣/软甲/金丝甲/天蚕丝衣）
/// - accessory 饰品（玉佩/毒珠/暗器匣/护心镜）
/// - treasure  奇物（丹药/卷轴，消耗品）
enum EquipmentSlot {
  weapon('兵器'),
  armor('护体'),
  accessory('饰品'),
  treasure('奇物'),
  boots('靴子'),
  offhand('副手');

  const EquipmentSlot(this.displayName);

  /// 显示名称
  final String displayName;

  String toJson() => name;
  static EquipmentSlot fromJson(String value) => EquipmentSlot.values.byName(value);
}

/// 武功类型（DESIGN.md 3.4.1 四维定义）
///
/// - internal 内功 — 根基，决定基础数值和属性方向，影响外功兼容性
/// - external 外功 — 招式，主动行为选择（含主动攻击招式）
/// - lightness 轻功 — 身法招式，影响先手值/闪避率
/// - mantra 心法 — 改规则被动，非数值加成（DESIGN.md 3.4.3）
enum MartialType {
  internal('内功'),
  external('外功'),
  lightness('轻功'),
  mantra('心法');

  const MartialType(this.displayName);

  final String displayName;

  String toJson() => name;
  static MartialType fromJson(String value) => MartialType.values.byName(value);
}

/// 武功熟练度等级（DESIGN.md 5.1）
///
/// 初窥 → 入门 → 小成 → 大成 → 化境
enum ProficiencyLevel {
  novice('初窥', 0, 20),
  beginner('入门', 20, 40),
  minor('小成', 40, 60),
  major('大成', 60, 80),
  mastery('化境', 80, 100);

  const ProficiencyLevel(this.displayName, this.minProficiency, this.maxProficiency);

  /// 显示名称
  final String displayName;

  /// 该等级所需最低熟练度
  final int minProficiency;

  /// 该等级熟练度上限
  final int maxProficiency;

  String toJson() => name;
  static ProficiencyLevel fromJson(String value) => ProficiencyLevel.values.byName(value);

  /// 根据熟练度数值推断等级
  static ProficiencyLevel fromProficiency(int proficiency) {
    for (final level in ProficiencyLevel.values.reversed) {
      if (proficiency >= level.minProficiency) return level;
    }
    return ProficiencyLevel.novice;
  }
}

/// 战斗档位（DESIGN.md 3.2.1 三档战斗）
///
/// | 档位 | 触发条件 | 回合数 | 文字量 | 说明 |
/// |------|---------|--------|--------|------|
/// | 碾压 | 敌人战力<玩家70% | 0-1 | 1句话 | 连刷模式自动结算 |
/// | 正常 | 敌人战力70%-120% | 5-8 | 3-5段 | 标准回合制 |
/// | Boss | 精英/Boss | 10-15 | 展开式 | 完整招式交锋描写 |
enum BattleTier {
  crush('碾压', 0, 1),
  normal('正常', 5, 8),
  boss('Boss', 10, 15),
  encounter('奇遇', 0, 0),
  crit('暴击', 0, 0),
  drop('掉落', 0, 0),
  qigongDeviation('走火入魔', 0, 0),
  endless('无尽', 0, 0);

  const BattleTier(this.displayName, this.minTurns, this.maxTurns);

  /// 显示名称
  final String displayName;

  /// 最小回合数
  final int minTurns;

  /// 最大回合数
  final int maxTurns;

  String toJson() => name;
  static BattleTier fromJson(String value) => BattleTier.values.byName(value);

  /// 根据敌我战力比判定战斗档位
  static BattleTier fromPowerRatio(double ratio) {
    if (ratio < 0.7) return BattleTier.crush;
    if (ratio <= 1.2) return BattleTier.normal;
    return BattleTier.boss;
  }
}

/// 暗金/神品独特效果类型（DESIGN.md 3.3.5 暗金设计原则）
///
/// 每件暗金有改机制独特词条，不是简单数值。
enum EffectType {
  /// 伤害转换（如外功转内功计算）
  damageConvert('伤害转换'),
  /// 属性加成
  statBonus('属性加成'),
  /// 规则改变（改变游戏机制）
  ruleChange('规则改变'),
  /// 触发效果（击杀回复/暴击触发等）
  trigger('触发效果'),
  /// 免疫/抗性
  immunity('免疫/抗性'),
  /// 特殊招式解锁
  skillUnlock('招式解锁'),
  /// 经脉相关（如免疫真气逆行）
  meridianRelated('经脉相关'),
  /// 条件加成（如杀人越多伤害越高）
  conditional('条件加成');

  const EffectType(this.displayName);

  final String displayName;

  String toJson() => name;
  static EffectType fromJson(String value) => EffectType.values.byName(value);
}

/// 秘境类型（DESIGN.md 3.7.1）
///
/// | 类型 | 结构 | 适合 |
/// |------|------|------|
/// | 线性秘境 | 4层递进，Boss在最后 | 叙事 |
/// | 开放秘境 | 1大区域，多个房间随机，Boss随机 | 刷装(类似牛关) |
/// | 挑战秘境 | 1层1个超强Boss | BD验证 |
/// | 迷宫秘境 | 多层分支路径，选择影响掉落 | 策略性 |
enum RealmType {
  linear('线性秘境', 4),
  open('开放秘境', 1),
  challenge('挑战秘境', 1),
  maze('迷宫秘境', 5);

  const RealmType(this.displayName, this.defaultLayers);

  /// 显示名称
  final String displayName;

  /// 默认层数
  final int defaultLayers;

  String toJson() => name;
  static RealmType fromJson(String value) => RealmType.values.byName(value);
}

/// 秘境难度分级（DESIGN.md 3.7.2 难度分级 — 改规则非纯数值）
///
/// | 难度 | 改变 |
/// |------|------|
/// | 普通 | 标准体验 |
/// | 困难 | 敌人有额外词条(反伤/嗜血) |
/// | 地狱 | 敌人机制改变(Boss新增二阶段) |
/// | 炼狱 | 规则改变(禁轻功/内力持续流失) |
enum Difficulty {
  normal('普通'),
  hard('困难'),
  hell('地狱'),
  inferno('炼狱');

  const Difficulty(this.displayName);

  final String displayName;

  String toJson() => name;
  static Difficulty fromJson(String value) => Difficulty.values.byName(value);

  /// 难度系数（用于敌人属性缩放）
  double get multiplier => switch (this) {
        Difficulty.normal => 1.0,
        Difficulty.hard => 1.5,
        Difficulty.hell => 2.0,
        Difficulty.inferno => 3.0,
      };
}

/// 元素亲和性 / 属性方向（DESIGN.md 3.4.2 内功兼容性）
///
/// - yang   阳刚型 → 兼容刚猛外功，不兼容阴柔外功(相克→真气逆行风险)
/// - yin    阴柔型 → 兼容快剑/暗器，不兼容阳刚拳法
/// - neutral 中和型 → 全兼容(极稀有)
enum ElementAffinity {
  yang('阳刚'),
  yin('阴柔'),
  neutral('中和');

  const ElementAffinity(this.displayName);

  final String displayName;

  String toJson() => name;
  static ElementAffinity fromJson(String value) => ElementAffinity.values.byName(value);

  /// 判断两个属性方向是否相克（DESIGN.md 3.4.2）
  bool conflictsWith(ElementAffinity other) {
    if (this == ElementAffinity.neutral || other == ElementAffinity.neutral) {
      return false; // 中和型与任何都不冲突
    }
    return this != other; // 阳刚 vs 阴柔 → 相克
  }
}

/// 真气逆行程度（DESIGN.md 3.6.3 效果）
///
/// - 轻度: 内力恢复-30%，偶尔出招失误
/// - 中度: 随机负面效果，属性波动
/// - 重度: 每回合损血，但有属性暴增(高风险高收益路线)
enum QiDeviationLevel {
  none('正常', 0),
  mild('轻度', 1),
  moderate('中度', 2),
  severe('重度', 3);

  const QiDeviationLevel(this.displayName, this.severity);

  /// 显示名称
  final String displayName;

  /// 严重程度（0-3）
  final int severity;

  String toJson() => name;
  static QiDeviationLevel fromJson(String value) => QiDeviationLevel.values.byName(value);
}

/// 秘境变体类型（DESIGN.md 3.7.3 秘境变体）
enum RealmVariant {
  normal('普通'),
  cursed('被诅咒的'),
  ancient('古老的');

  const RealmVariant(this.displayName);

  final String displayName;

  String toJson() => name;
  static RealmVariant fromJson(String value) => RealmVariant.values.byName(value);
}

/// 战斗动作类型（DESIGN.md 3.2.2 回合内多动作）
///
/// 1轮 = 双方各做 2-3 个动作（出招/运功/闪避/反击）
enum BattleActionType {
  attack('出招'),
  channel('运功'),
  dodge('闪避'),
  counter('反击'),
  skill('施展武功'),
  item('使用物品');

  const BattleActionType(this.displayName);

  final String displayName;

  String toJson() => name;
  static BattleActionType fromJson(String value) => BattleActionType.values.byName(value);
}

/// 敌人机制类型（DESIGN.md 3.4.5 敌人机制多样性）
///
/// 防BD趋同：不同Boss需要不同BD流派应对
enum MechanicType {
  immunePhysical('免疫物理'),
  counterMelee('反击近战'),
  continuousHeal('持续回血'),
  multiPhase('多阶段'),
  enrage('狂暴'),
  shield('护盾'),
  summon('召唤'),
  reflectDamage('反伤'),
  lifesteal('嗜血'),
  disableLightness('禁轻功'),
  innerDrain('内力流失'),
  // 扩展机制类型（来自 enemies.json）
  groupAttack('群体攻击'),
  heavyStomp('重击'),
  blindAttack('致盲攻击'),
  phaseShift('虚实转换'),
  counterStance('反击架势'),
  defenseBoost('防御提升'),
  poisonNeedle('毒针封穴'),
  formationAura('阵法共鸣'),
  bloodlust('搏命打法'),
  bloodParasite('噬血蛊'),
  ironSkin('铁石皮肉'),
  jointWeakPoint('关节弱点'),
  aerialBombard('空袭'),
  dualLink('双狮互援'),
  layTrap('布设陷阱'),
  sixPathShift('六道转换'),
  mindAssault('精神冲击'),
  crushingBlow('粉碎重击'),
  formationHeal('阵法回复');

  const MechanicType(this.displayName);

  final String displayName;

  String toJson() => name;
  static MechanicType fromJson(String value) => MechanicType.values.byName(value);
}

/// 词缀位置（DESIGN.md 3.3.3 词缀系统）
///
/// 前缀: "锋利的" / "嗜血的" / "破甲的" ...
/// 后缀: "of 力量" / "of 悟性" / "of 福缘" ...
enum AffixPosition {
  prefix('前缀'),
  suffix('后缀');

  const AffixPosition(this.displayName);

  final String displayName;

  String toJson() => name;
  static AffixPosition fromJson(String value) => AffixPosition.values.byName(value);
}

/// 排行榜类型（DESIGN.md 3.9.5 排行榜）
enum LeaderboardType {
  realmClear('秘境通关'),
  endlessDepth('无尽模式层数'),
  dailySeed('每日种子');

  const LeaderboardType(this.displayName);

  final String displayName;

  String toJson() => name;
  static LeaderboardType fromJson(String value) => LeaderboardType.values.byName(value);
}

/// 掉落闪光等级（DESIGN.md 3.2.4 掉落闪光）
enum DropFlashLevel {
  /// 凡品/良品: 简短文字
  plain('简短文字', 0),
  /// 上品: 带词条
  detailed('带词条', 1),
  /// 暗金: 仪式感停顿 + 完整描述 + 配图
  ceremonial('仪式感停顿', 2),
  /// 神品/传说: 全屏文字特效 + 故事化掉落叙事 + 配图
  legendary('全屏特效', 3);

  const DropFlashLevel(this.displayName, this.priority);

  final String displayName;

  /// 展示优先级（越高越隆重）
  final int priority;

  String toJson() => name;
  static DropFlashLevel fromJson(String value) => DropFlashLevel.values.byName(value);

  /// 根据品质推断闪光等级
  static DropFlashLevel fromQuality(Quality quality) => switch (quality) {
        Quality.normal || Quality.magic => DropFlashLevel.plain,
        Quality.rare => DropFlashLevel.detailed,
        Quality.unique => DropFlashLevel.ceremonial,
        Quality.divine || Quality.legendary => DropFlashLevel.legendary,
      };
}

/// 心法效果类别（DESIGN.md 3.4.3 心法示例）
///
/// 心法是改规则的被动，非数值加成
enum HeartMantraCategory {
  /// 伤害转化（如"以柔克刚"：外功伤害转内功伤害计算）
  damageConversion('伤害转化'),
  /// 先手/行动（如"先发制人"：先手值高的角色第一回合额外行动）
  actionBonus('先手/行动'),
  /// 堆叠加成（如"杀意"：杀人越多伤害越高）
  stackingBonus('堆叠加成'),
  /// 经脉免疫（如"天人合一"：经脉相克不再触发真气逆行）
  meridianImmunity('经脉免疫'),
  /// 其他规则改变
  ruleChange('规则改变');

  const HeartMantraCategory(this.displayName);

  final String displayName;

  String toJson() => name;
  static HeartMantraCategory fromJson(String value) => HeartMantraCategory.values.byName(value);
}

/// 经脉阴阳属性（DESIGN.md 3.5.1 — 6条经脉，3阳3阴）
enum MeridianYinYang {
  yang('阳脉'),
  yin('阴脉');

  const MeridianYinYang(this.displayName);

  final String displayName;

  String toJson() => name;
  static MeridianYinYang fromJson(String value) => MeridianYinYang.values.byName(value);
}
