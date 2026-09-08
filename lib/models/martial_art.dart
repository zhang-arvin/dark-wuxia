// =============================================================================
// 对应 DESIGN.md 章节：3.4 BD流派系统 — 3.4.1 四维定义
//   五、数据结构 5.1 — MartialArt 定义
//
// 武功类型：内功 / 外功 / 轻功
// 熟练度等级：初窥 → 入门 → 小成 → 大成 → 化境
// 元素亲和性：阳刚 / 阴柔 / 中和（影响兼容性，DESIGN.md 3.4.2）
// =============================================================================

import 'enums.dart';

/// 武功模型（DESIGN.md 5.1）
///
/// 四维BD中的「外功」维度（含轻功）。
/// 内功另由内功系统处理，但此模型也可表示内功招式。
class MartialArt {
  /// 武功唯一ID
  final String id;

  /// 武功名称
  final String name;

  /// 武功类型（内功/外功/轻功）
  final MartialType type;

  /// 熟练度 0-100
  final int proficiency;

  /// 熟练度等级（初窥/入门/小成/大成/化境）
  final ProficiencyLevel proficiencyLevel;

  /// 元素亲和性（阳刚/阴柔/中和）
  ///
  /// 用于判断内功外功兼容性（DESIGN.md 3.4.2）
  final ElementAffinity elementAffinity;

  /// 伤害倍率（外功/内功招式的伤害系数）
  final double damageMultiplier;

  /// 内力消耗
  final int energyCost;

  /// 所属门派（可选）
  final String? faction;

  /// 前置武功ID（学习此武功需要先掌握的前置）
  final String? prerequisite;

  /// 所需最小悟性（学习要求）
  final int requiredWis;

  /// 所需最小等级（学习要求）
  final int requiredLevel;

  /// 是否为主动招式（true=战斗中可选择使用, false=被动）
  final bool isActive;

  /// 招式描述
  final String description;

  const MartialArt({
    required this.id,
    required this.name,
    required this.type,
    required this.proficiency,
    required this.proficiencyLevel,
    required this.elementAffinity,
    this.damageMultiplier = 1.0,
    this.energyCost = 0,
    this.faction,
    this.prerequisite,
    this.requiredWis = 0,
    this.requiredLevel = 1,
    this.isActive = true,
    this.description = '',
  });

  factory MartialArt.fromJson(Map<String, dynamic> json) => MartialArt(
        id: json['id'] as String,
        name: json['name'] as String,
        type: MartialType.fromJson(json['type'] as String),
        proficiency: json['proficiency'] as int,
        proficiencyLevel: ProficiencyLevel.fromJson(json['proficiencyLevel'] as String),
        elementAffinity: ElementAffinity.fromJson(json['elementAffinity'] as String),
        damageMultiplier: (json['damageMultiplier'] as num?)?.toDouble() ?? 1.0,
        energyCost: json['energyCost'] as int? ?? 0,
        faction: json['faction'] as String?,
        prerequisite: json['prerequisite'] as String?,
        requiredWis: json['requiredWis'] as int? ?? 0,
        requiredLevel: json['requiredLevel'] as int? ?? 1,
        isActive: json['isActive'] as bool? ?? true,
        description: json['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.toJson(),
        'proficiency': proficiency,
        'proficiencyLevel': proficiencyLevel.toJson(),
        'elementAffinity': elementAffinity.toJson(),
        'damageMultiplier': damageMultiplier,
        'energyCost': energyCost,
        'faction': faction,
        'prerequisite': prerequisite,
        'requiredWis': requiredWis,
        'requiredLevel': requiredLevel,
        'isActive': isActive,
        'description': description,
      };

  MartialArt copyWith({
    String? id,
    String? name,
    MartialType? type,
    int? proficiency,
    ProficiencyLevel? proficiencyLevel,
    ElementAffinity? elementAffinity,
    double? damageMultiplier,
    int? energyCost,
    String? faction,
    String? prerequisite,
    int? requiredWis,
    int? requiredLevel,
    bool? isActive,
    String? description,
  }) =>
      MartialArt(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        proficiency: proficiency ?? this.proficiency,
        proficiencyLevel: proficiencyLevel ?? this.proficiencyLevel,
        elementAffinity: elementAffinity ?? this.elementAffinity,
        damageMultiplier: damageMultiplier ?? this.damageMultiplier,
        energyCost: energyCost ?? this.energyCost,
        faction: faction ?? this.faction,
        prerequisite: prerequisite ?? this.prerequisite,
        requiredWis: requiredWis ?? this.requiredWis,
        requiredLevel: requiredLevel ?? this.requiredLevel,
        isActive: isActive ?? this.isActive,
        description: description ?? this.description,
      );

  /// 增加熟练度，自动更新等级
  MartialArt addProficiency(int amount) {
    final newProf = (proficiency + amount).clamp(0, 100);
    return copyWith(
      proficiency: newProf,
      proficiencyLevel: ProficiencyLevel.fromProficiency(newProf),
    );
  }

  /// 判断是否与另一武功的属性方向兼容（DESIGN.md 3.4.2）
  bool isCompatibleWith(MartialArt other) =>
      !elementAffinity.conflictsWith(other.elementAffinity);

  /// 是否满足学习条件
  bool meetsRequirements(int wis, int level) =>
      wis >= requiredWis && level >= requiredLevel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MartialArt &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          proficiency == other.proficiency &&
          proficiencyLevel == other.proficiencyLevel &&
          elementAffinity == other.elementAffinity &&
          damageMultiplier == other.damageMultiplier &&
          energyCost == other.energyCost &&
          faction == other.faction &&
          prerequisite == other.prerequisite &&
          requiredWis == other.requiredWis &&
          requiredLevel == other.requiredLevel &&
          isActive == other.isActive &&
          description == other.description;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        type,
        proficiency,
        proficiencyLevel,
        elementAffinity,
        damageMultiplier,
        energyCost,
      );

  @override
  String toString() =>
      'MartialArt($id: $name [${type.displayName}] ${proficiencyLevel.displayName} proficiency=$proficiency)';
}
