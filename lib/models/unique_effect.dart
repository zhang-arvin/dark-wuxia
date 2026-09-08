// =============================================================================
// 对应 DESIGN.md 章节：3.3.5 暗金设计原则
//   五、数据结构 5.2 — UniqueEquipment / UniqueEffect 定义
//
// 每件暗金有改机制独特词条，不是简单数值。
// 数量目标：首发30-50件，后续扩充至100+。
// 低级暗金也有长期价值（改机制不依赖数值）。
// =============================================================================

import 'enums.dart';
import 'equipment.dart';

/// 暗金独特效果（DESIGN.md 5.2 — UniqueEffect）
///
/// 改机制词条，不是简单数值加成。
/// 例: "无视内功防御" / "外功伤害转内功计算" / "杀人越多伤害越高"
class UniqueEffect {
  /// 效果唯一ID
  final String id;

  /// 效果描述（玩家可见）
  ///
  /// 例: "无视内功防御" / "击杀回复生命5%" / "经脉相克不再触发真气逆行"
  final String description;

  /// 效果类型
  final EffectType type;

  /// 效果参数（不同效果类型有不同参数结构）
  ///
  /// 示例:
  /// - damageConvert: {"from": "external", "to": "internal"} 外功转内功
  /// - trigger: {"trigger": "onKill", "effect": "heal", "value": 5} 击杀回复5%生命
  /// - conditional: {"condition": "perKill", "bonus": "damagePct", "perStack": 5, "maxStack": 50} 杀意
  /// - immunity: {"target": "qiDeviation"} 免疫真气逆行
  final Map<String, dynamic> params;

  const UniqueEffect({
    required this.id,
    required this.description,
    required this.type,
    this.params = const {},
  });

  factory UniqueEffect.fromJson(Map<String, dynamic> json) => UniqueEffect(
        id: json['id'] as String,
        description: json['description'] as String,
        type: EffectType.fromJson(json['type'] as String),
        params: Map<String, dynamic>.from(json['params'] as Map? ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'type': type.toJson(),
        'params': params,
      };

  UniqueEffect copyWith({
    String? id,
    String? description,
    EffectType? type,
    Map<String, dynamic>? params,
  }) =>
      UniqueEffect(
        id: id ?? this.id,
        description: description ?? this.description,
        type: type ?? this.type,
        params: params ?? this.params,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UniqueEffect &&
          id == other.id &&
          description == other.description &&
          type == other.type &&
          _mapEquals(params, other.params);

  @override
  int get hashCode => Object.hash(id, description, type);

  @override
  String toString() => 'UniqueEffect($id [${type.displayName}] $description)';
}

/// 暗金装备配置（DESIGN.md 5.2 — UniqueEquipment）
///
/// 暗金 = 固定独特词条 + 2-4随机词缀 + 改机制
class UniqueEquipment {
  /// 暗金唯一ID
  final String id;

  /// 暗金名称
  final String name;

  /// 故事化描述（仪式感掉落展示用）
  final String description;

  /// 物品等级
  final int itemLevel;

  /// 槽位
  final EquipmentSlot slot;

  /// 基础伤害/防御（暗金通常比同ilvl普通装备高）
  final int baseDamage;

  /// 改机制独特词条列表（固定效果）
  final List<UniqueEffect> uniqueEffects;

  /// 随机词缀范围（2-4条随机词缀）
  final List<AffixRange> randomAffixes;

  /// 装备要求
  ///
  /// key = 要求类型(如 "body"臂力 / "alignment"正邪值 / "level"等级)
  /// value = 最小值
  final Map<String, int> requirements;

  /// 所属套装ID（如有）
  final String? setId;

  /// 排他性：同一角色只能装备一件同ID暗金
  final bool isExclusive;

  /// 掉落来源秘境ID列表（DESIGN.md 3.7.5 定向掉落）
  final List<String> dropRealmIds;

  /// 配图URL（暗金及以上配图，DESIGN.md 3.2.4）
  final String? imageUrl;

  const UniqueEquipment({
    required this.id,
    required this.name,
    required this.description,
    required this.itemLevel,
    required this.slot,
    required this.baseDamage,
    required this.uniqueEffects,
    this.randomAffixes = const [],
    this.requirements = const {},
    this.setId,
    this.isExclusive = true,
    this.dropRealmIds = const [],
    this.imageUrl,
  });

  factory UniqueEquipment.fromJson(Map<String, dynamic> json) => UniqueEquipment(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        itemLevel: json['itemLevel'] as int,
        slot: EquipmentSlot.fromJson(json['slot'] as String),
        baseDamage: json['baseDamage'] as int,
        uniqueEffects: (json['uniqueEffects'] as List)
            .map((e) => UniqueEffect.fromJson(e as Map<String, dynamic>))
            .toList(),
        randomAffixes: (json['randomAffixes'] as List)
            .map((e) => AffixRange.fromJson(e as Map<String, dynamic>))
            .toList(),
        requirements: Map<String, int>.from(json['requirements'] as Map? ?? {}),
        setId: json['setId'] as String?,
        isExclusive: json['isExclusive'] as bool? ?? true,
        dropRealmIds: (json['dropRealmIds'] as List?)?.cast<String>() ?? const [],
        imageUrl: json['imageUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'itemLevel': itemLevel,
        'slot': slot.toJson(),
        'baseDamage': baseDamage,
        'uniqueEffects': uniqueEffects.map((e) => e.toJson()).toList(),
        'randomAffixes': randomAffixes.map((e) => e.toJson()).toList(),
        'requirements': requirements,
        'setId': setId,
        'isExclusive': isExclusive,
        'dropRealmIds': dropRealmIds,
        'imageUrl': imageUrl,
      };

  /// 检查角色是否满足装备要求
  bool meetsRequirements({
    required int body,
    required int level,
    required int alignment,
  }) {
    final reqBody = requirements['body'];
    if (reqBody != null && body < reqBody) return false;
    final reqLevel = requirements['level'];
    if (reqLevel != null && level < reqLevel) return false;
    final reqAlignment = requirements['alignment'];
    if (reqAlignment != null) {
      // 正邪值要求：正值要求正道，负值要求邪道
      if (reqAlignment > 0 && alignment < reqAlignment) return false;
      if (reqAlignment < 0 && alignment > reqAlignment) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UniqueEquipment &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          itemLevel == other.itemLevel &&
          slot == other.slot &&
          baseDamage == other.baseDamage &&
          _listEquals(uniqueEffects, other.uniqueEffects) &&
          _listEquals(randomAffixes, other.randomAffixes);

  @override
  int get hashCode => Object.hash(id, name, itemLevel, slot, baseDamage);

  @override
  String toString() =>
      'UniqueEquipment($id: $name [${slot.displayName}] ilvl=$itemLevel effects=${uniqueEffects.length})';
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

bool _listEquals(List a, List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
