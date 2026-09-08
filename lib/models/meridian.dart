// =============================================================================
// 对应 DESIGN.md 章节：3.5 经脉系统（=D2符文之语）
//   3.5.1 简化设计 — 6条经脉（3阳3阴），每条5个穴位 = 30穴位
//   3.5.2 真气种子（=符文）
//   3.5.3 经脉之语（=符文之语）
//   3.5.4 配方发现
//   五、数据结构 5.2 — MeridianWord 定义
// =============================================================================

import 'enums.dart';

/// 经脉穴位节点（DESIGN.md 5.1 — MeridianNode）
///
/// 6条经脉，每条5个穴位，共30个穴位。
/// 命名: 阳脉1穴/阳脉2穴... 不用真实中医名。
class MeridianNode {
  /// 经脉ID（如 'yang_1', 'yin_2'）
  final String meridianId;

  /// 穴位序号（0-4，每条经脉5个穴位）
  final int nodeIndex;

  /// 是否打通
  final bool isOpen;

  /// 种入的真气种子ID（DESIGN.md 3.5.2）
  final String? seedId;

  const MeridianNode({
    required this.meridianId,
    required this.nodeIndex,
    this.isOpen = false,
    this.seedId,
  });

  factory MeridianNode.fromJson(Map<String, dynamic> json) => MeridianNode(
        meridianId: json['meridianId'] as String,
        nodeIndex: json['nodeIndex'] as int,
        isOpen: json['isOpen'] as bool? ?? false,
        seedId: json['seedId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'meridianId': meridianId,
        'nodeIndex': nodeIndex,
        'isOpen': isOpen,
        'seedId': seedId,
      };

  MeridianNode copyWith({
    String? meridianId,
    int? nodeIndex,
    bool? isOpen,
    String? seedId,
  }) =>
      MeridianNode(
        meridianId: meridianId ?? this.meridianId,
        nodeIndex: nodeIndex ?? this.nodeIndex,
        isOpen: isOpen ?? this.isOpen,
        seedId: seedId ?? this.seedId,
      );

  /// 打通穴位并（可选）种入真气种子
  MeridianNode open({String? seed}) => copyWith(isOpen: true, seedId: seed ?? seedId);

  /// 移除真气种子
  MeridianNode removeSeed() => copyWith(seedId: null);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeridianNode &&
          meridianId == other.meridianId &&
          nodeIndex == other.nodeIndex &&
          isOpen == other.isOpen &&
          seedId == other.seedId;

  @override
  int get hashCode => Object.hash(meridianId, nodeIndex, isOpen, seedId);

  @override
  String toString() =>
      'MeridianNode($meridianId #$nodeIndex open=$isOpen seed=$seedId)';
}

/// 真气种子（=D2符文，DESIGN.md 3.5.2）
///
/// 掉落物，种入穴位后提供属性加成。
/// 不同种子对应不同穴位的加成效果。
class MeridianSeed {
  /// 种子唯一ID
  final String id;

  /// 种子名称（如"少阳种子"、"玄阴种子"）
  final String name;

  /// 种子等级（1-5，越高越稀有越强）
  final int tier;

  /// 阴阳属性（阳脉种子只能种入阳脉，阴脉种子只能种入阴脉）
  final MeridianYinYang yinYang;

  /// 种入穴位后的属性加成
  ///
  /// key = 属性名（如 'body', 'agi'）, value = 加成数值
  final Map<String, int> bonuses;

  /// 掉落率权重
  final int dropWeight;

  /// 种子描述
  final String description;

  const MeridianSeed({
    required this.id,
    required this.name,
    required this.tier,
    required this.yinYang,
    this.bonuses = const {},
    this.dropWeight = 100,
    this.description = '',
  });

  factory MeridianSeed.fromJson(Map<String, dynamic> json) => MeridianSeed(
        id: json['id'] as String,
        name: json['name'] as String,
        tier: json['tier'] as int,
        yinYang: MeridianYinYang.fromJson(json['yinYang'] as String),
        bonuses: Map<String, int>.from(json['bonuses'] as Map? ?? {}),
        dropWeight: json['dropWeight'] as int? ?? 100,
        description: json['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tier': tier,
        'yinYang': yinYang.toJson(),
        'bonuses': bonuses,
        'dropWeight': dropWeight,
        'description': description,
      };

  MeridianSeed copyWith({
    String? id,
    String? name,
    int? tier,
    MeridianYinYang? yinYang,
    Map<String, int>? bonuses,
    int? dropWeight,
    String? description,
  }) =>
      MeridianSeed(
        id: id ?? this.id,
        name: name ?? this.name,
        tier: tier ?? this.tier,
        yinYang: yinYang ?? this.yinYang,
        bonuses: bonuses ?? this.bonuses,
        dropWeight: dropWeight ?? this.dropWeight,
        description: description ?? this.description,
      );

  /// 是否可种入指定经脉（阴阳属性匹配）
  bool canPlantIn(String meridianId) {
    if (meridianId.startsWith('yang')) return yinYang == MeridianYinYang.yang;
    if (meridianId.startsWith('yin')) return yinYang == MeridianYinYang.yin;
    return false;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeridianSeed &&
          id == other.id &&
          name == other.name &&
          tier == other.tier &&
          yinYang == other.yinYang;

  @override
  int get hashCode => Object.hash(id, name, tier, yinYang);

  @override
  String toString() => 'MeridianSeed($id: $name T$tier ${yinYang.displayName})';
}

/// 经脉之语种子序列槽位（DESIGN.md 5.2 — MeridianSeedSlot）
///
/// 定义经脉之语所需的种子序列中每个槽位的要求。
class MeridianSeedSlot {
  /// 经脉ID
  final String meridianId;

  /// 穴位序号
  final int nodeIndex;

  /// 要求种入的种子ID（精确匹配）
  final String requiredSeedId;

  /// 或要求种入的种子等级（备选匹配）
  final int? requiredSeedTier;

  const MeridianSeedSlot({
    required this.meridianId,
    required this.nodeIndex,
    this.requiredSeedId = '',
    this.requiredSeedTier,
  });

  factory MeridianSeedSlot.fromJson(Map<String, dynamic> json) => MeridianSeedSlot(
        meridianId: json['meridianId'] as String,
        nodeIndex: json['nodeIndex'] as int,
        requiredSeedId: json['requiredSeedId'] as String? ?? '',
        requiredSeedTier: json['requiredSeedTier'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'meridianId': meridianId,
        'nodeIndex': nodeIndex,
        'requiredSeedId': requiredSeedId,
        'requiredSeedTier': requiredSeedTier,
      };

  /// 检查给定穴位节点是否满足此槽位要求
  bool matches(MeridianNode node, MeridianSeed? seed) {
    if (node.meridianId != meridianId || node.nodeIndex != nodeIndex) {
      return false;
    }
    if (!node.isOpen || seed == null) return false;
    if (requiredSeedId.isNotEmpty && seed.id != requiredSeedId) return false;
    if (requiredSeedTier != null && seed.tier < requiredSeedTier!) return false;
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeridianSeedSlot &&
          meridianId == other.meridianId &&
          nodeIndex == other.nodeIndex &&
          requiredSeedId == other.requiredSeedId &&
          requiredSeedTier == other.requiredSeedTier;

  @override
  int get hashCode => Object.hash(meridianId, nodeIndex, requiredSeedId, requiredSeedTier);

  @override
  String toString() =>
      'MeridianSeedSlot($meridianId #$nodeIndex seed=$requiredSeedId tier=$requiredSeedTier)';
}

/// 经脉之语（=D2符文之语，DESIGN.md 5.2 / 3.5.3）
///
/// 特定穴位按特定顺序种入真气种子 → 解锁隐藏效果。
/// 例: "任督贯通" = 会阴→气海→膻中→天突→百会→玉枕→命门 → 内力恢复x2
class MeridianWord {
  /// 经脉之语唯一ID
  final String id;

  /// 名称
  final String name;

  /// 故事化描述
  final String description;

  /// 要求的种子序列（每个槽位指定经脉穴位和所需种子）
  final List<MeridianSeedSlot> sequence;

  /// 效果描述
  final String effect;

  /// 属性加成（解锁后获得的属性加成）
  ///
  /// key = 属性名, value = 加成数值
  final Map<String, int> bonuses;

  /// 是否已发现（DESIGN.md 3.5.4 — 配方发现）
  ///
  /// 通过收集"经脉残卷"拼出完整配方
  final bool isDiscovered;

  /// 发现此配方所需的残卷碎片数
  final int requiredFragments;

  const MeridianWord({
    required this.id,
    required this.name,
    required this.description,
    required this.sequence,
    required this.effect,
    this.bonuses = const {},
    this.isDiscovered = false,
    this.requiredFragments = 3,
  });

  factory MeridianWord.fromJson(Map<String, dynamic> json) => MeridianWord(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        sequence: (json['sequence'] as List)
            .map((e) => MeridianSeedSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
        effect: json['effect'] as String,
        bonuses: Map<String, int>.from(json['bonuses'] as Map? ?? {}),
        isDiscovered: json['isDiscovered'] as bool? ?? false,
        requiredFragments: json['requiredFragments'] as int? ?? 3,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'sequence': sequence.map((e) => e.toJson()).toList(),
        'effect': effect,
        'bonuses': bonuses,
        'isDiscovered': isDiscovered,
        'requiredFragments': requiredFragments,
      };

  MeridianWord copyWith({
    String? id,
    String? name,
    String? description,
    List<MeridianSeedSlot>? sequence,
    String? effect,
    Map<String, int>? bonuses,
    bool? isDiscovered,
    int? requiredFragments,
  }) =>
      MeridianWord(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        sequence: sequence ?? this.sequence,
        effect: effect ?? this.effect,
        bonuses: bonuses ?? this.bonuses,
        isDiscovered: isDiscovered ?? this.isDiscovered,
        requiredFragments: requiredFragments ?? this.requiredFragments,
      );

  /// 检查当前经脉状态是否满足此经脉之语的条件
  bool isCompleted(List<MeridianNode> nodes, Map<String, MeridianSeed> seedMap) {
    for (final slot in sequence) {
      final node = nodes.firstWhere(
        (n) => n.meridianId == slot.meridianId && n.nodeIndex == slot.nodeIndex,
        orElse: () => const MeridianNode(meridianId: '', nodeIndex: -1),
      );
      if (node.nodeIndex < 0) return false;
      final seed = node.seedId != null ? seedMap[node.seedId] : null;
      if (!slot.matches(node, seed)) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeridianWord &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          _listEquals(sequence, other.sequence) &&
          effect == other.effect &&
          isDiscovered == other.isDiscovered;

  @override
  int get hashCode => Object.hash(id, name, effect, isDiscovered);

  @override
  String toString() => 'MeridianWord($id: $name [${sequence.length}步] $effect)';
}

/// 经脉系统配置（6条经脉定义，DESIGN.md 3.5.1）
///
/// 6条经脉（3阳3阴），每条5个穴位 = 30穴位
class MeridianConfig {
  /// 经脉ID（如 'yang_1', 'yin_2'）
  final String id;

  /// 经脉名称（如"少阳脉"、"太阴脉"）
  final String name;

  /// 阴阳属性
  final MeridianYinYang yinYang;

  /// 穴位数（默认5）
  final int nodeCount;

  /// 穴位名称列表（如 ["阳脉1穴", "阳脉2穴", ...]）
  final List<String> nodeNames;

  /// 相克经脉ID（DESIGN.md 3.6.2 — 经脉相克触发真气逆行）
  final String? conflictMeridianId;

  const MeridianConfig({
    required this.id,
    required this.name,
    required this.yinYang,
    this.nodeCount = 5,
    this.nodeNames = const [],
    this.conflictMeridianId,
  });

  factory MeridianConfig.fromJson(Map<String, dynamic> json) => MeridianConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        yinYang: MeridianYinYang.fromJson(json['yinYang'] as String),
        nodeCount: json['nodeCount'] as int? ?? 5,
        nodeNames: (json['nodeNames'] as List?)?.cast<String>() ?? const [],
        conflictMeridianId: json['conflictMeridianId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'yinYang': yinYang.toJson(),
        'nodeCount': nodeCount,
        'nodeNames': nodeNames,
        'conflictMeridianId': conflictMeridianId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeridianConfig && id == other.id && name == other.name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'MeridianConfig($id: $name ${yinYang.displayName})';
}

bool _listEquals(List a, List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
