// =============================================================================
// 对应 DESIGN.md 章节：3.4.3 心法示例（改规则被动，非数值加成）
//   3.6.5 双修流（心法"天人合一"可完全免疫真气逆行）
//
// 心法是BD四维中的「改规则」维度。
// 不是数值加成，而是改变游戏规则的被动。
// =============================================================================

import 'enums.dart';

/// 心法模型（DESIGN.md 3.4.3）
///
/// 心法示例：
/// - "以柔克刚"：外功伤害转化为内功伤害计算（改规则！）
/// - "先发制人"：先手值高的角色第一回合额外行动
/// - "杀意"：杀人越多伤害越高(每击杀+5%伤害，上限+50%)
/// - "天人合一"：经脉相克不再触发真气逆行(解锁双修流)
class HeartMantra {
  /// 心法唯一ID
  final String id;

  /// 心法名称
  final String name;

  /// 效果描述（玩家可见）
  final String effectDescription;

  /// 心法效果类别
  final HeartMantraCategory category;

  /// 效果参数（不同类别有不同参数结构）
  ///
  /// 示例:
  /// - damageConversion: {"from": "external", "to": "internal"}
  /// - actionBonus: {"condition": "highInit", "bonus": "extraAction", "turn": 1}
  /// - stackingBonus: {"trigger": "onKill", "perStack": 5, "maxStack": 50, "stat": "damagePct"}
  /// - meridianImmunity: {"target": "qiDeviation"} 免疫真气逆行
  final Map<String, dynamic> params;

  /// 学习所需最小悟性
  final int requiredWis;

  /// 学习所需最小等级
  final int requiredLevel;

  /// 正邪值要求（正值=正道心法，负值=邪道心法，0=中立）
  final int requiredAlignment;

  /// 前置心法ID（如有）
  final String? prerequisite;

  /// 是否为唯一（同一角色只能同时装备一个心法）
  final bool isUnique;

  /// 心法来源（门派/秘境奖励/奇遇）
  final String? source;

  /// 详细描述（故事化背景）
  final String lore;

  const HeartMantra({
    required this.id,
    required this.name,
    required this.effectDescription,
    required this.category,
    this.params = const {},
    this.requiredWis = 0,
    this.requiredLevel = 1,
    this.requiredAlignment = 0,
    this.prerequisite,
    this.isUnique = true,
    this.source,
    this.lore = '',
  });

  factory HeartMantra.fromJson(Map<String, dynamic> json) => HeartMantra(
        id: json['id'] as String,
        name: json['name'] as String,
        effectDescription: json['effectDescription'] as String,
        category: HeartMantraCategory.fromJson(json['category'] as String),
        params: Map<String, dynamic>.from(json['params'] as Map? ?? {}),
        requiredWis: _parseInt(json['requiredWis']) ?? 0,
        requiredLevel: _parseInt(json['requiredLevel']) ?? 1,
        requiredAlignment: _parseAlignment(json['requiredAlignment']),
        prerequisite: json['prerequisite'] as String?,
        isUnique: json['isUnique'] as bool? ?? true,
        source: json['source'] as String?,
        lore: json['lore'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'effectDescription': effectDescription,
        'category': category.toJson(),
        'params': params,
        'requiredWis': requiredWis,
        'requiredLevel': requiredLevel,
        'requiredAlignment': requiredAlignment,
        'prerequisite': prerequisite,
        'isUnique': isUnique,
        'source': source,
        'lore': lore,
      };

  HeartMantra copyWith({
    String? id,
    String? name,
    String? effectDescription,
    HeartMantraCategory? category,
    Map<String, dynamic>? params,
    int? requiredWis,
    int? requiredLevel,
    int? requiredAlignment,
    String? prerequisite,
    bool? isUnique,
    String? source,
    String? lore,
  }) =>
      HeartMantra(
        id: id ?? this.id,
        name: name ?? this.name,
        effectDescription: effectDescription ?? this.effectDescription,
        category: category ?? this.category,
        params: params ?? this.params,
        requiredWis: requiredWis ?? this.requiredWis,
        requiredLevel: requiredLevel ?? this.requiredLevel,
        requiredAlignment: requiredAlignment ?? this.requiredAlignment,
        prerequisite: prerequisite ?? this.prerequisite,
        isUnique: isUnique ?? this.isUnique,
        source: source ?? this.source,
        lore: lore ?? this.lore,
      );

  /// 检查角色是否满足学习/装备条件
  bool meetsRequirements({
    required int wis,
    required int level,
    required int alignment,
  }) {
    if (wis < requiredWis) return false;
    if (level < requiredLevel) return false;
    // 正邪值检查
    if (requiredAlignment > 0 && alignment < requiredAlignment) return false;
    if (requiredAlignment < 0 && alignment > requiredAlignment) return false;
    return true;
  }

  /// 是否免疫真气逆行（DESIGN.md 3.6.5 — "天人合一"解锁双修流）
  bool get immuneToQiDeviation =>
      category == HeartMantraCategory.meridianImmunity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeartMantra &&
          id == other.id &&
          name == other.name &&
          effectDescription == other.effectDescription &&
          category == other.category &&
          _mapEquals(params, other.params) &&
          requiredWis == other.requiredWis &&
          requiredLevel == other.requiredLevel &&
          requiredAlignment == other.requiredAlignment &&
          prerequisite == other.prerequisite &&
          isUnique == other.isUnique &&
          source == other.source &&
          lore == other.lore;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        category,
        requiredWis,
        requiredLevel,
        requiredAlignment,
      );

  @override
  String toString() => 'HeartMantra($id: $name [${category.displayName}] $effectDescription)';
}

bool _mapEquals(Map a, Map b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}

/// 兼容 JSON 中 String 类型的 int 字段
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

/// 兼容 JSON 中 String 类型的 alignment 字段
/// "neutral" → 0, "yang" → 1, "yin" → -1
int _parseAlignment(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) {
    return switch (value) {
      'neutral' => 0,
      'yang' => 1,
      'yin' => -1,
      _ => 0,
    };
  }
  return 0;
}
