import 'dart:convert';

import '../../models/equipment.dart';
import '../../models/enums.dart';

/// 装备战力输入数据 (避免循环依赖 EquipmentTableData)
class EquipmentPowerInput {
  final int itemLevel;
  final String quality;
  final int reinforceLevel;
  final String affixesJson;

  const EquipmentPowerInput({
    required this.itemLevel,
    required this.quality,
    required this.reinforceLevel,
    required this.affixesJson,
  });
}

/// 战力指数计算器
///
/// 战力指数 (Power Index) 是角色综合评分，一键看成长。
/// 计算公式综合五维属性、武功、装备、经脉等因素。
///
/// 设计依据 (DESIGN.md 3.10.1):
/// - 臂力(BODY)   → 外功伤害基数、生命上限
/// - 身法(AGI)    → 先手值、闪避率、暴击率
/// - 悟性(WIS)    → 修炼速度、武功兼容性
/// - 根骨(CON)    → 内力上限、内力恢复
/// - 福缘(LUCK)   → 掉落率加成、奇遇触发率
class PowerCalculator {
  PowerCalculator._();

  /// 品质战力系数
  static int _qualityMultiplier(String quality) {
    switch (quality) {
      case 'legendary': return 300;
      case 'divine': return 150;
      case 'unique': return 80;
      case 'rare': return 40;
      case 'magic': return 20;
      default: return 10; // normal
    }
  }

  /// 计算装备战力贡献
  ///
  /// [equippedItems] 已装备的装备列表
  /// 返回装备战力总和
  static int calculateEquipmentPower(List<EquipmentPowerInput> equippedItems) {
    var total = 0;
    for (final item in equippedItems) {
      // 基础战力 = 物品等级 × 品质系数
      final basePower = item.itemLevel * _qualityMultiplier(item.quality);
      // 强化加成 = 强化等级 × 10
      final reinforcePower = item.reinforceLevel * 10;
      // 词缀加成 — 解析词缀并累加数值
      var affixPower = 0;
      try {
        final affixes = parseAffixListCompat(item.affixesJson);
        for (final affix in affixes) {
          for (final value in affix.rolledValues.values) {
            affixPower += value.abs();
          }
        }
      } catch (_) {}
      total += basePower + reinforcePower + affixPower;
    }
    return total;
  }

  /// 计算战力指数
  ///
  /// [body]    臂力
  /// [agi]     身法
  /// [wis]     悟性
  /// [con]     根骨
  /// [luck]    福缘
  /// [level]   等级
  /// [health]  当前生命
  /// [innerEnergy] 当前内力
  /// [martialArtsCount] 武功数量
  /// [martialArtsProficiencySum] 武功熟练度总和
  /// [meridianOpenCount] 已打通穴位数
  /// [heartMantraActive] 是否有心法
  /// [equipmentPowerSum] 装备贡献战力总和 (由装备词缀汇总)
  static int calculate({
    required int body,
    required int agi,
    required int wis,
    required int con,
    required int luck,
    required int level,
    required int health,
    required int innerEnergy,
    required int martialArtsCount,
    required int martialArtsProficiencySum,
    required int meridianOpenCount,
    required bool heartMantraActive,
    required int equipmentPowerSum,
  }) {
    // 1. 基础属性战力 = 五维总和 × 等级系数
    final baseAttributes = body * 3 + agi * 3 + wis * 2 + con * 2 + luck * 1;
    final basePower = (baseAttributes * level * 1.5).round();

    // 2. 衍生属性战力 (生命+内力)
    final derivedPower = (health * 0.3 + innerEnergy * 0.5).round();

    // 3. 武功战力 = 熟练度总和 × 武功数量加成
    final martialPower = (martialArtsProficiencySum * martialArtsCount * 0.1).round();

    // 4. 经脉战力 = 每穴 +50 战力
    final meridianPower = meridianOpenCount * 50;

    // 5. 心法加成 = 总战力 × 10%
    final heartMantraBonus = heartMantraActive ? 0.1 : 0.0;

    // 6. 装备战力 = 装备贡献总和
    final equipmentPower = equipmentPowerSum;

    // 汇总
    final rawPower = (basePower + derivedPower + martialPower + meridianPower + equipmentPower);
    final totalPower = (rawPower * (1 + heartMantraBonus)).round();

    return totalPower;
  }

  /// 从五维属性 JSON 计算基础战力 (简化版，用于快速预览)
  static int quickCalculate(Map<String, dynamic> attributes, int level) {
    final body = (attributes['body'] ?? 0) as int;
    final agi = (attributes['agi'] ?? 0) as int;
    final wis = (attributes['wis'] ?? 0) as int;
    final con = (attributes['con'] ?? 0) as int;
    final luck = (attributes['luck'] ?? 0) as int;

    final baseAttributes = body * 3 + agi * 3 + wis * 2 + con * 2 + luck * 1;
    return (baseAttributes * level * 1.5).round();
  }
}

/// 词缀数据统一使用 models/equipment.dart 中的 Affix 类
///
/// 统一说明:
/// 原先 AffixData 使用 {id, type, name, stat, value, isPercent} 格式，
/// 而 Affix 使用 {id, name, position, effects, rolledValues} 格式。
/// 现统一为 Affix，AffixData 作为其别名 (typedef)。
///
/// 旧代码中使用 AffixData.fromJsonList / AffixData.toJsonList 的地方，
/// 请改用顶层函数 parseAffixListCompat / serializeAffixListCompat。
typedef AffixData = Affix;

/// 词缀列表 JSON 解析（兼容新旧两种格式）
///
/// 新格式: {id, name, position, effects, rolledValues} → 直接用 Affix.fromJson
/// 旧格式: {id, type, name, stat, value, isPercent} → 转换为 Affix
List<Affix> parseAffixListCompat(String jsonStr) {
  if (jsonStr.isEmpty) return [];
  final list = jsonDecode(jsonStr) as List<dynamic>;
  return list.map((e) {
    final json = e as Map<String, dynamic>;
    // 新格式: 有 position 字段 → 直接用 Affix.fromJson
    if (json.containsKey('position')) {
      return Affix.fromJson(json);
    }
    // 旧格式: 有 type 字段 → 转换为 Affix 格式
    if (json.containsKey('type')) {
      final stat = json['stat'] as String? ?? '';
      final value = (json['value'] as num?)?.toInt() ?? 0;
      return Affix(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        position: json['type'] == 'suffix'
            ? AffixPosition.suffix
            : AffixPosition.prefix,
        effects: {stat: value},
        rolledValues: {stat: value},
      );
    }
    // 兜底: 尝试直接解析
    return Affix.fromJson(json);
  }).toList();
}

/// 词缀列表 JSON 序列化（使用 Affix.toJson 统一格式）
String serializeAffixListCompat(List<Affix> affixes) {
  return jsonEncode(affixes.map((e) => e.toJson()).toList());
}

/// 武功数据模型 (用于角色武功 JSON 序列化/反序列化)
class MartialArtData {
  final String id;
  final String name;
  final String type; // inner / outer / light (内功/外功/轻功)
  final int proficiency; // 0-100 熟练度
  final String level; // novice/beginner/minor/major/mastery
  final String elementAffinity; // yang/yin/neutral

  const MartialArtData({
    required this.id,
    required this.name,
    required this.type,
    required this.proficiency,
    required this.level,
    required this.elementAffinity,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'proficiency': proficiency,
        'level': level,
        'elementAffinity': elementAffinity,
      };

  factory MartialArtData.fromJson(Map<String, dynamic> json) {
    return MartialArtData(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      proficiency: (json['proficiency'] as num).toInt(),
      level: json['level'] as String? ?? 'novice',
      elementAffinity: json['elementAffinity'] as String? ?? 'neutral',
    );
  }

  static List<MartialArtData> fromJsonList(String jsonStr) {
    if (jsonStr.isEmpty) return [];
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => MartialArtData.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String toJsonList(List<MartialArtData> arts) {
    return jsonEncode(arts.map((e) => e.toJson()).toList());
  }
}

/// 经脉节点数据模型 (用于角色经脉 JSON 序列化/反序列化)
class MeridianNodeData {
  final String meridianId;
  final int nodeIndex;
  final bool isOpen;
  final String? seedId;

  const MeridianNodeData({
    required this.meridianId,
    required this.nodeIndex,
    required this.isOpen,
    this.seedId,
  });

  Map<String, dynamic> toJson() => {
        'meridianId': meridianId,
        'nodeIndex': nodeIndex,
        'isOpen': isOpen,
        'seedId': seedId,
      };

  factory MeridianNodeData.fromJson(Map<String, dynamic> json) {
    return MeridianNodeData(
      meridianId: json['meridianId'] as String,
      nodeIndex: (json['nodeIndex'] as num).toInt(),
      isOpen: json['isOpen'] as bool? ?? false,
      seedId: json['seedId'] as String?,
    );
  }

  static List<MeridianNodeData> fromJsonList(String jsonStr) {
    if (jsonStr.isEmpty) return [];
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => MeridianNodeData.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String toJsonList(List<MeridianNodeData> nodes) {
    return jsonEncode(nodes.map((e) => e.toJson()).toList());
  }
}
