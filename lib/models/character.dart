// =============================================================================
// 对应 DESIGN.md 章节：3.1 角色系统 — 3.1.1 五维属性 / 3.1.2 衍生属性
//   3.6 真气逆行系统
//   五、数据结构 5.1 — Character 定义
//
// 角色状态（每世临时）：
//   包含角色基本信息、五维属性、武功列表、装备配置、经脉状态、心法、
//   生命/内力/福缘/名望/正邪值/战力指数等。
// =============================================================================

import 'enums.dart';
import 'attributes.dart';
import 'martial_art.dart';
import 'meridian.dart';

/// 当前装备配置（4个槽位的装备实例ID）
///
/// DESIGN.md 3.3.4 装备槽位:
///   weapon    兵器
///   armor     护体
///   accessory 饰品
///   treasure  奇物（消耗品）
class EquipmentLoadout {
  /// 兵器装备实例ID
  final String? weaponId;

  /// 护体装备实例ID
  final String? armorId;

  /// 饰品装备实例ID
  final String? accessoryId;

  /// 奇物装备实例ID
  final String? treasureId;

  const EquipmentLoadout({
    this.weaponId,
    this.armorId,
    this.accessoryId,
    this.treasureId,
  });

  factory EquipmentLoadout.fromJson(Map<String, dynamic> json) => EquipmentLoadout(
        weaponId: json['weaponId'] as String?,
        armorId: json['armorId'] as String?,
        accessoryId: json['accessoryId'] as String?,
        treasureId: json['treasureId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'weaponId': weaponId,
        'armorId': armorId,
        'accessoryId': accessoryId,
        'treasureId': treasureId,
      };

  EquipmentLoadout copyWith({
    String? weaponId,
    String? armorId,
    String? accessoryId,
    String? treasureId,
  }) =>
      EquipmentLoadout(
        weaponId: weaponId ?? this.weaponId,
        armorId: armorId ?? this.armorId,
        accessoryId: accessoryId ?? this.accessoryId,
        treasureId: treasureId ?? this.treasureId,
      );

  /// 获取所有已装备的装备ID列表
  List<String> get equippedIds =>
      [weaponId, armorId, accessoryId, treasureId].whereType<String>().toList();

  /// 获取指定槽位的装备ID
  String? getSlot(EquipmentSlot slot) => switch (slot) {
        EquipmentSlot.weapon => weaponId,
        EquipmentSlot.armor => armorId,
        EquipmentSlot.accessory => accessoryId,
        EquipmentSlot.treasure => treasureId,
        EquipmentSlot.boots => null,
        EquipmentSlot.offhand => null,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquipmentLoadout &&
          weaponId == other.weaponId &&
          armorId == other.armorId &&
          accessoryId == other.accessoryId &&
          treasureId == other.treasureId;

  @override
  int get hashCode => Object.hash(weaponId, armorId, accessoryId, treasureId);

  @override
  String toString() =>
      'EquipmentLoadout(weapon=$weaponId armor=$armorId accessory=$accessoryId treasure=$treasureId)';
}

/// 角色模型（DESIGN.md 5.1）
///
/// 角色状态（每世临时）— 存储在 shared_preferences 中的 player_state。
class Character {
  /// 角色名称
  final String name;

  /// 出身（如"少林弟子"、"江湖浪子"、"幽冥教徒"）
  final String origin;

  /// 年龄
  final int age;

  /// 等级
  final int level;

  /// 经验值
  final int experience;

  /// 五维属性
  final Attributes attributes;

  /// 武功列表
  final List<MartialArt> martialArts;

  /// 当前装备配置
  final EquipmentLoadout equipment;

  /// 经脉状态（30个穴位）
  final List<MeridianNode> meridians;

  /// 心法ID（DESIGN.md 3.4.3）
  final String? heartMantraId;

  /// 当前生命值
  final int health;

  /// 当前内力值
  final int innerEnergy;

  /// 福缘（掉率加成，=D2的MF）
  final int fortune;

  /// 名望
  final int reputation;

  /// 正邪值 -100~100（负=邪道, 正=正道, 0=中立）
  final int alignment;

  /// 战力指数（综合评分，DESIGN.md 3.10.1）
  final int powerIndex;

  /// 真气逆行程度（DESIGN.md 3.6）
  final QiDeviationLevel qiDeviation;

  /// 银两（游戏内货币）
  final int silver;

  const Character({
    required this.name,
    required this.origin,
    required this.age,
    required this.level,
    this.experience = 0,
    required this.attributes,
    this.martialArts = const [],
    this.equipment = const EquipmentLoadout(),
    this.meridians = const [],
    this.heartMantraId,
    required this.health,
    required this.innerEnergy,
    this.fortune = 0,
    this.reputation = 0,
    this.alignment = 0,
    required this.powerIndex,
    this.qiDeviation = QiDeviationLevel.none,
    this.silver = 0,
  });

  factory Character.fromJson(Map<String, dynamic> json) => Character(
        name: json['name'] as String,
        origin: json['origin'] as String,
        age: json['age'] as int,
        level: json['level'] as int,
        experience: json['experience'] as int? ?? 0,
        attributes: Attributes.fromJson(json['attributes'] as Map<String, dynamic>),
        martialArts: (json['martialArts'] as List?)
                ?.map((e) => MartialArt.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        equipment: json['equipment'] != null
            ? EquipmentLoadout.fromJson(json['equipment'] as Map<String, dynamic>)
            : const EquipmentLoadout(),
        meridians: (json['meridians'] as List?)
                ?.map((e) => MeridianNode.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        heartMantraId: json['heartMantraId'] as String?,
        health: json['health'] as int,
        innerEnergy: json['innerEnergy'] as int,
        fortune: json['fortune'] as int? ?? 0,
        reputation: json['reputation'] as int? ?? 0,
        alignment: json['alignment'] as int? ?? 0,
        powerIndex: json['powerIndex'] as int,
        qiDeviation: json['qiDeviation'] != null
            ? QiDeviationLevel.fromJson(json['qiDeviation'] as String)
            : QiDeviationLevel.none,
        silver: json['silver'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'origin': origin,
        'age': age,
        'level': level,
        'experience': experience,
        'attributes': attributes.toJson(),
        'martialArts': martialArts.map((e) => e.toJson()).toList(),
        'equipment': equipment.toJson(),
        'meridians': meridians.map((e) => e.toJson()).toList(),
        'heartMantraId': heartMantraId,
        'health': health,
        'innerEnergy': innerEnergy,
        'fortune': fortune,
        'reputation': reputation,
        'alignment': alignment,
        'powerIndex': powerIndex,
        'qiDeviation': qiDeviation.toJson(),
        'silver': silver,
      };

  Character copyWith({
    String? name,
    String? origin,
    int? age,
    int? level,
    int? experience,
    Attributes? attributes,
    List<MartialArt>? martialArts,
    EquipmentLoadout? equipment,
    List<MeridianNode>? meridians,
    String? heartMantraId,
    int? health,
    int? innerEnergy,
    int? fortune,
    int? reputation,
    int? alignment,
    int? powerIndex,
    QiDeviationLevel? qiDeviation,
    int? silver,
  }) =>
      Character(
        name: name ?? this.name,
        origin: origin ?? this.origin,
        age: age ?? this.age,
        level: level ?? this.level,
        experience: experience ?? this.experience,
        attributes: attributes ?? this.attributes,
        martialArts: martialArts ?? this.martialArts,
        equipment: equipment ?? this.equipment,
        meridians: meridians ?? this.meridians,
        heartMantraId: heartMantraId ?? this.heartMantraId,
        health: health ?? this.health,
        innerEnergy: innerEnergy ?? this.innerEnergy,
        fortune: fortune ?? this.fortune,
        reputation: reputation ?? this.reputation,
        alignment: alignment ?? this.alignment,
        powerIndex: powerIndex ?? this.powerIndex,
        qiDeviation: qiDeviation ?? this.qiDeviation,
        silver: silver ?? this.silver,
      );

  // ===========================================================================
  // 衍生属性计算（DESIGN.md 3.1.2）
  // ===========================================================================

  /// 内力上限 — 根骨×等级×内功加成
  int get maxInnerEnergy => attributes.con * level * 10;

  /// 生命上限 — 臂力×等级×装备加成
  int get maxHealth => attributes.body * level * 15;

  /// 先手值 — 身法×轻功加成
  int get initiative => attributes.agi * 5;

  /// 闪避率 — 身法×轻功×经脉加成（百分比 0-100）
  int get dodgeRate => (attributes.agi * 0.5).round().clamp(0, 75);

  /// 暴击率 — 身法影响（百分比 0-100）
  int get critRate => (attributes.agi * 0.3).round().clamp(0, 50);

  /// 福缘掉率加成百分比（DESIGN.md 3.9.1 — =D2 MF）
  double get fortuneBonus => fortune * 0.1;

  /// 正邪阵营描述
  String get alignmentLabel => switch (alignment) {
        >= 50 => '正道',
        <= -50 => '邪道',
        _ => '中立',
      };

  /// 是否处于真气逆行状态（DESIGN.md 3.6）
  bool get hasQiDeviation => qiDeviation != QiDeviationLevel.none;

  /// 经脉已打通穴位数
  int get openedMeridianCount => meridians.where((m) => m.isOpen).length;

  /// 经脉已种入种子数
  int get plantedSeedCount =>
      meridians.where((m) => m.seedId != null).length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Character &&
          name == other.name &&
          origin == other.origin &&
          age == other.age &&
          level == other.level &&
          experience == other.experience &&
          attributes == other.attributes &&
          _listEquals(martialArts, other.martialArts) &&
          equipment == other.equipment &&
          _listEquals(meridians, other.meridians) &&
          heartMantraId == other.heartMantraId &&
          health == other.health &&
          innerEnergy == other.innerEnergy &&
          fortune == other.fortune &&
          reputation == other.reputation &&
          alignment == other.alignment &&
          powerIndex == other.powerIndex &&
          qiDeviation == other.qiDeviation &&
          silver == other.silver;

  @override
  int get hashCode => Object.hash(
        name,
        origin,
        level,
        attributes,
        health,
        innerEnergy,
        powerIndex,
        qiDeviation,
      );

  @override
  String toString() =>
      'Character($name [$origin] Lv.$level power=$powerIndex hp=$health/$maxHealth ie=$innerEnergy/$maxInnerEnergy fortune=$fortune align=$alignment)';
}

/// 玩家会话状态（存于 shared_preferences 的 player_state）
///
/// DESIGN.md 4.2 存档架构:
///   shared_preferences (快速KV):
///     - player_state (当前角色状态)
///     - settings (游戏设置)
///     - session_cache (会话缓存)
class PlayerState {
  /// 当前角色
  final Character character;

  /// 当前所在场景（城镇/秘境ID）
  final String currentScene;

  /// 当前秘境进度（如有）
  final String? activeRealmId;

  /// 背包已用容量
  final int backpackUsed;

  /// 背包软上限（DESIGN.md 4.2 — 500件）
  final int backpackLimit;

  /// 最后保存时间
  final DateTime lastSaved;

  /// 游戏内时间（天）
  final int gameDay;

  /// 已解锁的秘境ID列表
  final List<String> unlockedRealms;

  /// 全局保底计数器（按掉落表ID索引）
  final Map<String, int> globalPityCounters;

  const PlayerState({
    required this.character,
    this.currentScene = 'town',
    this.activeRealmId,
    this.backpackUsed = 0,
    this.backpackLimit = 500,
    required this.lastSaved,
    this.gameDay = 1,
    this.unlockedRealms = const [],
    this.globalPityCounters = const {},
  });

  factory PlayerState.fromJson(Map<String, dynamic> json) => PlayerState(
        character: Character.fromJson(json['character'] as Map<String, dynamic>),
        currentScene: json['currentScene'] as String? ?? 'town',
        activeRealmId: json['activeRealmId'] as String?,
        backpackUsed: json['backpackUsed'] as int? ?? 0,
        backpackLimit: json['backpackLimit'] as int? ?? 500,
        lastSaved: DateTime.parse(json['lastSaved'] as String),
        gameDay: json['gameDay'] as int? ?? 1,
        unlockedRealms: (json['unlockedRealms'] as List?)?.cast<String>() ?? const [],
        globalPityCounters:
            Map<String, int>.from(json['globalPityCounters'] as Map? ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'character': character.toJson(),
        'currentScene': currentScene,
        'activeRealmId': activeRealmId,
        'backpackUsed': backpackUsed,
        'backpackLimit': backpackLimit,
        'lastSaved': lastSaved.toIso8601String(),
        'gameDay': gameDay,
        'unlockedRealms': unlockedRealms,
        'globalPityCounters': globalPityCounters,
      };

  PlayerState copyWith({
    Character? character,
    String? currentScene,
    String? activeRealmId,
    int? backpackUsed,
    int? backpackLimit,
    DateTime? lastSaved,
    int? gameDay,
    List<String>? unlockedRealms,
    Map<String, int>? globalPityCounters,
  }) =>
      PlayerState(
        character: character ?? this.character,
        currentScene: currentScene ?? this.currentScene,
        activeRealmId: activeRealmId ?? this.activeRealmId,
        backpackUsed: backpackUsed ?? this.backpackUsed,
        backpackLimit: backpackLimit ?? this.backpackLimit,
        lastSaved: lastSaved ?? this.lastSaved,
        gameDay: gameDay ?? this.gameDay,
        unlockedRealms: unlockedRealms ?? this.unlockedRealms,
        globalPityCounters: globalPityCounters ?? this.globalPityCounters,
      );

  /// 背包是否已满
  bool get isBackpackFull => backpackUsed >= backpackLimit;

  /// 背包剩余容量
  int get backpackRemaining => backpackLimit - backpackUsed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerState &&
          character == other.character &&
          currentScene == other.currentScene &&
          activeRealmId == other.activeRealmId &&
          backpackUsed == other.backpackUsed &&
          backpackLimit == other.backpackLimit &&
          gameDay == other.gameDay &&
          _listEquals(unlockedRealms, other.unlockedRealms);

  @override
  int get hashCode => Object.hash(
        character,
        currentScene,
        backpackUsed,
        gameDay,
      );

  @override
  String toString() =>
      'PlayerState(${character.name} scene=$currentScene backpack=$backpackUsed/$backpackLimit day=$gameDay)';
}

bool _listEquals(List a, List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
