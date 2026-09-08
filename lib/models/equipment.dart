// =============================================================================
// 对应 DESIGN.md 章节：3.3 装备系统
//   3.3.1 品质分级 → Quality (在 enums.dart 中)
//   3.3.3 词缀系统 → Affix, AffixRange
//   3.3.4 装备槽位 → EquipmentSlot (在 enums.dart 中)
//   3.3.5 暗金设计原则 → 见 unique_effect.dart
//   3.3.6 套装系统 → SetBonus
//
// 以及 DESIGN.md 5.1/5.2 中的 Equipment / EquipmentBase 定义。
// =============================================================================

import 'enums.dart';

/// 词缀定义（DESIGN.md 3.3.3）
///
/// 前缀: "锋利的" → 外功伤害+10-20%
/// 后缀: "of 力量" → 臂力+3-8
/// 每个词缀有名称、位置、效果参数、数值范围。
class Affix {
  /// 词缀唯一ID
  final String id;

  /// 词缀名称（如"锋利的" / "of 力量"）
  final String name;

  /// 词缀位置（前缀/后缀）
  final AffixPosition position;

  /// 效果参数（属性名 → 数值）
  ///
  /// 例如: {'externalDamagePct': 15} 表示外功伤害+15%
  ///       {'body': 5} 表示臂力+5
  final Map<String, int> effects;

  /// 生成时随机出的最终数值（基于 AffixRange 滚动后固定）
  final Map<String, int> rolledValues;

  const Affix({
    required this.id,
    required this.name,
    required this.position,
    required this.effects,
    required this.rolledValues,
  });

  factory Affix.fromJson(Map<String, dynamic> json) => Affix(
        id: json['id'] as String,
        name: json['name'] as String,
        position: AffixPosition.fromJson(json['position'] as String),
        effects: Map<String, int>.from(json['effects'] as Map),
        rolledValues: Map<String, int>.from(json['rolledValues'] as Map),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'position': position.toJson(),
        'effects': effects,
        'rolledValues': rolledValues,
      };

  Affix copyWith({
    String? id,
    String? name,
    AffixPosition? position,
    Map<String, int>? effects,
    Map<String, int>? rolledValues,
  }) =>
      Affix(
        id: id ?? this.id,
        name: name ?? this.name,
        position: position ?? this.position,
        effects: effects ?? this.effects,
        rolledValues: rolledValues ?? this.rolledValues,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Affix &&
          id == other.id &&
          name == other.name &&
          position == other.position &&
          _mapEquals(effects, other.effects) &&
          _mapEquals(rolledValues, other.rolledValues);

  @override
  int get hashCode => Object.hash(id, name, position, Object.hashAll(effects.values), Object.hashAll(rolledValues.values));

  @override
  String toString() => 'Affix($id: $name ${position.displayName})';
}

/// 词缀数值范围（用于随机滚动，DESIGN.md 3.3.3）
///
/// 例如 "锋利的" 外功伤害+10-20%，则 min=10, max=20
class AffixRange {
  /// 词缀ID（对应 Affix.id）
  final String affixId;

  /// 词缀名称
  final String name;

  /// 词缀位置
  final AffixPosition position;

  /// 效果键 → (最小值, 最大值)
  ///
  /// 例如: {'externalDamagePct': (10, 20)}
  final Map<String, (int, int)> ranges;

  const AffixRange({
    required this.affixId,
    required this.name,
    required this.position,
    required this.ranges,
  });

  factory AffixRange.fromJson(Map<String, dynamic> json) {
    // 兼容两种格式：
    // 格式1: {affixId, minVal, maxVal} — 简化格式
    // 格式2: {affixId, name, position, ranges} — 完整格式
    final ranges = <String, (int, int)>{};
    if (json.containsKey('ranges')) {
      final rangesRaw = json['ranges'] as Map<String, dynamic>?;
      if (rangesRaw != null) {
        for (final entry in rangesRaw.entries) {
          final list = entry.value as List;
          ranges[entry.key] = (list[0] as int, list[1] as int);
        }
      }
    } else if (json.containsKey('minVal')) {
      // 简化格式：默认用 externalDamagePct 作为效果键
      ranges['externalDamagePct'] = (json['minVal'] as int, json['maxVal'] as int);
    }
    return AffixRange(
      affixId: (json['affixId'] ?? json['id'] ?? '') as String,
      name: (json['name'] ?? json['affixId'] ?? '') as String,
      position: json.containsKey('position')
          ? AffixPosition.fromJson(json['position'] as String)
          : AffixPosition.prefix,
      ranges: ranges,
    );
  }

  Map<String, dynamic> toJson() => {
        'affixId': affixId,
        'name': name,
        'position': position.toJson(),
        'ranges': ranges.map((k, v) => MapEntry(k, [v.$1, v.$2])),
      };

  /// 滚动随机数值，生成具体的 Affix 实例
  Affix roll(int seed) {
    final rolled = <String, int>{};
    var hash = seed;
    for (final entry in ranges.entries) {
      final min = entry.value.$1;
      final max = entry.value.$2;
      // 简单线性同余随机
      hash = (hash * 1103515245 + 12345) & 0x7FFFFFFF;
      final value = min + (hash % (max - min + 1));
      rolled[entry.key] = value;
    }
    return Affix(
      id: affixId,
      name: name,
      position: position,
      effects: rolled.map((k, v) => MapEntry(k, v)),
      rolledValues: rolled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AffixRange &&
          affixId == other.affixId &&
          name == other.name &&
          position == other.position &&
          _mapEqualsRanges(ranges, other.ranges);

  @override
  int get hashCode => Object.hash(affixId, name, position);

  @override
  String toString() => 'AffixRange($affixId: $name)';
}

/// 装备实例（玩家背包中的具体装备，DESIGN.md 5.1）
///
/// 每件装备由基础配置 + 品质 + 随机词缀 + 强化等级组成。
class Equipment {
  /// 装备唯一实例ID
  final String id;

  /// 基础装备ID（指向 config/equipment_base.json）
  final String baseId;

  /// 品质
  final Quality quality;

  /// 生成名（含词缀组合后的显示名）
  final String name;

  /// 词缀列表
  final List<Affix> affixes;

  /// 强化等级
  final int reinforceLevel;

  /// 镶嵌的真气种子ID（DESIGN.md 3.5.2）
  final String? meridianSeedId;

  /// 物品等级
  final int itemLevel;

  /// 所属套装ID（如有）
  final String? setId;

  /// 暗金配置ID（如品质为暗金及以上，指向暗金配置）
  final String? uniqueId;

  const Equipment({
    required this.id,
    required this.baseId,
    required this.quality,
    required this.name,
    required this.affixes,
    this.reinforceLevel = 0,
    this.meridianSeedId,
    required this.itemLevel,
    this.setId,
    this.uniqueId,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) => Equipment(
        id: json['id'] as String,
        baseId: json['baseId'] as String,
        quality: Quality.fromJson(json['quality'] as String),
        name: json['name'] as String,
        affixes: (json['affixes'] as List).map((e) => Affix.fromJson(e as Map<String, dynamic>)).toList(),
        reinforceLevel: json['reinforceLevel'] as int? ?? 0,
        meridianSeedId: json['meridianSeedId'] as String?,
        itemLevel: json['itemLevel'] as int,
        setId: json['setId'] as String?,
        uniqueId: json['uniqueId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'baseId': baseId,
        'quality': quality.toJson(),
        'name': name,
        'affixes': affixes.map((e) => e.toJson()).toList(),
        'reinforceLevel': reinforceLevel,
        'meridianSeedId': meridianSeedId,
        'itemLevel': itemLevel,
        'setId': setId,
        'uniqueId': uniqueId,
      };

  Equipment copyWith({
    String? id,
    String? baseId,
    Quality? quality,
    String? name,
    List<Affix>? affixes,
    int? reinforceLevel,
    String? meridianSeedId,
    int? itemLevel,
    String? setId,
    String? uniqueId,
  }) =>
      Equipment(
        id: id ?? this.id,
        baseId: baseId ?? this.baseId,
        quality: quality ?? this.quality,
        name: name ?? this.name,
        affixes: affixes ?? this.affixes,
        reinforceLevel: reinforceLevel ?? this.reinforceLevel,
        meridianSeedId: meridianSeedId ?? this.meridianSeedId,
        itemLevel: itemLevel ?? this.itemLevel,
        setId: setId ?? this.setId,
        uniqueId: uniqueId ?? this.uniqueId,
      );

  /// 计算强化后的伤害/防御倍率
  double get reinforceMultiplier => 1.0 + reinforceLevel * 0.1;

  /// 是否为暗金及以上
  bool get isUniqueOrAbove => quality.isUniqueOrAbove;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Equipment &&
          id == other.id &&
          baseId == other.baseId &&
          quality == other.quality &&
          name == other.name &&
          _listEquals(affixes, other.affixes) &&
          reinforceLevel == other.reinforceLevel &&
          meridianSeedId == other.meridianSeedId &&
          itemLevel == other.itemLevel &&
          setId == other.setId &&
          uniqueId == other.uniqueId;

  @override
  int get hashCode => Object.hash(id, baseId, quality, name, reinforceLevel, itemLevel);

  @override
  String toString() => 'Equipment($id: [$quality] $name ilvl=$itemLevel +$reinforceLevel)';
}

/// 装备基础配置（DESIGN.md 5.2 — JSON配置数据）
///
/// 对应 /config/equipment_base.json 中的条目
class EquipmentBase {
  /// 基础装备ID
  final String id;

  /// 基础名称
  final String name;

  /// 槽位
  final EquipmentSlot slot;

  /// 基础伤害/防御
  final int baseDamage;

  /// 物品等级
  final int itemLevel;

  /// 可用词缀池ID列表
  final List<String> affixPool;

  /// 所属套装ID
  final String? setImage;

  /// 武器子类型（剑/刀/枪/鞭/扇/珠），仅 weapon 槽位有效
  final String? weaponType;

  const EquipmentBase({
    required this.id,
    required this.name,
    required this.slot,
    required this.baseDamage,
    required this.itemLevel,
    this.affixPool = const [],
    this.setImage,
    this.weaponType,
  });

  factory EquipmentBase.fromJson(Map<String, dynamic> json) => EquipmentBase(
        id: json['id'] as String,
        name: json['name'] as String,
        slot: EquipmentSlot.fromJson(json['slot'] as String),
        baseDamage: json['baseDamage'] as int,
        itemLevel: json['itemLevel'] as int,
        affixPool: (json['affixPool'] as List?)?.cast<String>() ?? const [],
        setImage: json['setImage'] as String?,
        weaponType: json['weaponType'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slot': slot.toJson(),
        'baseDamage': baseDamage,
        'itemLevel': itemLevel,
        'affixPool': affixPool,
        'setImage': setImage,
        'weaponType': weaponType,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquipmentBase &&
          id == other.id &&
          name == other.name &&
          slot == other.slot &&
          baseDamage == other.baseDamage &&
          itemLevel == other.itemLevel;

  @override
  int get hashCode => Object.hash(id, name, slot, baseDamage, itemLevel);

  @override
  String toString() => 'EquipmentBase($id: $name [${slot.displayName}] ilvl=$itemLevel)';
}

/// 套装加成配置（DESIGN.md 3.3.6 — 分层加成）
///
/// 分层加成:
///   2件: 小数值加成
///   4件: 机制改变
///   6件: 大幅机制改变
class SetBonus {
  /// 套装ID
  final String setId;

  /// 套装名称
  final String setName;

  /// 各件数对应的加成效果
  ///
  /// key = 需要的件数(2/4/6), value = 效果描述
  final Map<int, String> bonusDescriptions;

  /// 各件数对应的属性加成
  ///
  /// key = 需要的件数, value = 属性名 → 数值
  final Map<int, Map<String, int>> bonusStats;

  /// 套装总件数
  final int totalPieces;

  const SetBonus({
    required this.setId,
    required this.setName,
    required this.bonusDescriptions,
    required this.bonusStats,
    required this.totalPieces,
  });

  factory SetBonus.fromJson(Map<String, dynamic> json) => SetBonus(
        setId: json['setId'] as String,
        setName: json['setName'] as String,
        bonusDescriptions: Map<String, String>.from(json['bonusDescriptions'] as Map)
            .map((k, v) => MapEntry(int.parse(k), v)),
        bonusStats: (json['bonusStats'] as Map<String, dynamic>).map((k, v) => MapEntry(
              int.parse(k),
              Map<String, int>.from(v as Map),
            )),
        totalPieces: json['totalPieces'] as int,
      );

  Map<String, dynamic> toJson() => {
        'setId': setId,
        'setName': setName,
        'bonusDescriptions': bonusDescriptions.map((k, v) => MapEntry(k.toString(), v)),
        'bonusStats': bonusStats.map((k, v) => MapEntry(k.toString(), v)),
        'totalPieces': totalPieces,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetBonus &&
          setId == other.setId &&
          setName == other.setName &&
          totalPieces == other.totalPieces;

  @override
  int get hashCode => Object.hash(setId, setName, totalPieces);

  @override
  String toString() => 'SetBonus($setId: $setName ($totalPieces件))';
}

// =============================================================================
// 内部辅助方法
// =============================================================================

bool _mapEquals(Map a, Map b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}

bool _mapEqualsRanges(Map<String, (int, int)> a, Map<String, (int, int)> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key)) return false;
    final av = a[key]!;
    final bv = b[key]!;
    if (av.$1 != bv.$1 || av.$2 != bv.$2) return false;
  }
  return true;
}

bool _listEquals(List a, List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
