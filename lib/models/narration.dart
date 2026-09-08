// =============================================================================
// 对应 DESIGN.md 章节：3.2 战斗系统 — 3.2.4 掉落闪光
//   四、技术架构 4.4 战斗描写模板（预生成）
//
// 200-500条预写模板，分类:
//   - 碾压档: "你一招{skill}，{enemy}应声倒地" (50条)
//   - 正常档: 分招式类型×场景 (200条)
//   - Boss档: 分Boss×阶段 (50条×变量)
// 运行时: 随机选取 + 变量填充({skill}/{enemy}/{damage})
// =============================================================================

import 'enums.dart';

/// 战斗描写模板（DESIGN.md 4.4 / 5.2）
///
/// 运行时从模板池中随机选取，填充变量后生成战斗描写文本。
/// LLM只用于后台批量生成模板，不在运行时调用。
class NarrationTemplate {
  /// 模板唯一ID
  final String id;

  /// 战斗档位（碾压/正常/Boss）
  final BattleTier tier;

  /// 模板文本（含变量占位符）
  ///
  /// 示例: "你一招{skill}，{enemy}应声倒地"
  ///       "{player}运起{internal}，一掌击向{enemy}，{enemy}连退三步"
  final String template;

  /// 所需变量名列表
  ///
  /// 示例: ["skill", "enemy", "damage"]
  final List<String> requiredVars;

  /// 抽取权重（值越大被选中概率越高）
  final int weight;

  /// 适用武功类型（空=通用，非空=仅该类型武功可用）
  final List<MartialType> applicableTypes;

  /// 适用敌人ID（空=通用，Boss档通常指定BossID）
  final List<String> applicableEnemies;

  /// Boss阶段（仅Boss档有效，指定哪个阶段的描写）
  final int? bossPhase;

  /// 战力区间（仅当玩家战力在此区间时使用此模板，DESIGN.md 3.10.4）
  final int? minPower;
  final int? maxPower;

  const NarrationTemplate({
    required this.id,
    required this.tier,
    required this.template,
    this.requiredVars = const [],
    this.weight = 1,
    this.applicableTypes = const [],
    this.applicableEnemies = const [],
    this.bossPhase,
    this.minPower,
    this.maxPower,
  });

  factory NarrationTemplate.fromJson(Map<String, dynamic> json) => NarrationTemplate(
        id: json['id'] as String,
        tier: BattleTier.fromJson(json['tier'] as String),
        template: json['template'] as String,
        requiredVars: (json['requiredVars'] as List?)?.cast<String>() ?? const [],
        weight: json['weight'] as int? ?? 1,
        applicableTypes: (json['applicableTypes'] as List?)
                ?.map((e) => MartialType.fromJson(e as String))
                .toList() ??
            const [],
        applicableEnemies: (json['applicableEnemies'] as List?)?.cast<String>() ?? const [],
        bossPhase: json['bossPhase'] as int?,
        minPower: json['minPower'] as int?,
        maxPower: json['maxPower'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tier': tier.toJson(),
        'template': template,
        'requiredVars': requiredVars,
        'weight': weight,
        'applicableTypes': applicableTypes.map((e) => e.toJson()).toList(),
        'applicableEnemies': applicableEnemies,
        'bossPhase': bossPhase,
        'minPower': minPower,
        'maxPower': maxPower,
      };

  NarrationTemplate copyWith({
    String? id,
    BattleTier? tier,
    String? template,
    List<String>? requiredVars,
    int? weight,
    List<MartialType>? applicableTypes,
    List<String>? applicableEnemies,
    int? bossPhase,
    int? minPower,
    int? maxPower,
  }) =>
      NarrationTemplate(
        id: id ?? this.id,
        tier: tier ?? this.tier,
        template: template ?? this.template,
        requiredVars: requiredVars ?? this.requiredVars,
        weight: weight ?? this.weight,
        applicableTypes: applicableTypes ?? this.applicableTypes,
        applicableEnemies: applicableEnemies ?? this.applicableEnemies,
        bossPhase: bossPhase ?? this.bossPhase,
        minPower: minPower ?? this.minPower,
        maxPower: maxPower ?? this.maxPower,
      );

  /// 填充模板变量，生成最终描写文本
  ///
  /// [variables] 包含所有 requiredVars 对应的值
  /// 示例: fill({"skill": "降龙掌", "enemy": "山贼", "damage": "150"})
  /// → "你一招降龙掌，山贼应声倒地"
  String fill(Map<String, String> variables) {
    String result = template;
    for (final varName in requiredVars) {
      final value = variables[varName] ?? '???';
      result = result.replaceAll('{$varName}', value);
    }
    return result;
  }

  /// 检查此模板是否适用于当前战斗场景
  bool isApplicable({
    MartialType? martialType,
    String? enemyId,
    int? bossPhase,
    int? playerPower,
  }) {
    // 武功类型检查
    if (applicableTypes.isNotEmpty && martialType != null) {
      if (!applicableTypes.contains(martialType)) return false;
    }
    // 敌人检查
    if (applicableEnemies.isNotEmpty && enemyId != null) {
      if (!applicableEnemies.contains(enemyId)) return false;
    }
    // Boss阶段检查
    if (this.bossPhase != null && bossPhase != null) {
      if (this.bossPhase != bossPhase) return false;
    }
    // 战力区间检查（DESIGN.md 3.10.4）
    if (minPower != null && playerPower != null) {
      if (playerPower < minPower!) return false;
    }
    if (maxPower != null && playerPower != null) {
      if (playerPower > maxPower!) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrationTemplate &&
          id == other.id &&
          tier == other.tier &&
          template == other.template &&
          weight == other.weight &&
          _listEquals(requiredVars, other.requiredVars) &&
          _listEquals(applicableTypes, other.applicableTypes) &&
          _listEquals(applicableEnemies, other.applicableEnemies) &&
          bossPhase == other.bossPhase &&
          minPower == other.minPower &&
          maxPower == other.maxPower;

  @override
  int get hashCode => Object.hash(id, tier, template, weight, bossPhase);

  @override
  String toString() =>
      'NarrationTemplate($id [${tier.displayName}] w=$weight vars=${requiredVars.join(",")})';
}

bool _listEquals(List a, List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
