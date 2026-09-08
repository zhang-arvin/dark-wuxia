// =============================================================================
// 对应 DESIGN.md 章节：3.2.2 回合内多动作 / 3.4.5 敌人机制多样性
//   3.7.2 难度分级（困难：敌人有额外词条；地狱：敌人机制改变）
//
// 敌人机制多样性（防BD趋同）：
//   免疫物理Boss → 需要内功流
//   反击近战Boss → 需要轻功远程流
//   持续回血Boss → 需要爆发秒杀流
//   多阶段Boss  → 需要续航+适应流
// =============================================================================

import 'enums.dart';

/// 敌人机制（DESIGN.md 3.4.5）
///
/// 定义敌人的特殊机制，用于防BD趋同。
/// 不同Boss需要不同BD流派应对。
class EnemyMechanic {
  /// 机制唯一ID
  final String id;

  /// 机制类型
  final MechanicType type;

  /// 机制描述（玩家可见提示）
  final String description;

  /// 机制参数
  ///
  /// 示例:
  /// - immunePhysical: {"damageType": "physical", "immunePct": 100}
  /// - counterMelee: {"range": "melee", "counterPct": 50, "counterDamage": 0.5}
  /// - continuousHeal: {"perTurn": 10, "pct": 5}
  /// - multiPhase: {"phases": 3, "phaseTrigger": ["50%hp", "25%hp"]}
  /// - enrage: {"trigger": "30%hp", "atkPct": 50, "spdPct": 30}
  /// - reflectDamage: {"pct": 20}
  /// - lifesteal: {"pct": 15}
  /// - disableLightness: {"target": "lightness"}
  /// - innerDrain: {"perTurn": 10}
  final Map<String, dynamic> params;

  const EnemyMechanic({
    required this.id,
    required this.type,
    required this.description,
    this.params = const {},
  });

  factory EnemyMechanic.fromJson(Map<String, dynamic> json) => EnemyMechanic(
        id: json['id'] as String,
        type: MechanicType.fromJson(json['type'] as String),
        description: json['description'] as String,
        params: Map<String, dynamic>.from(json['params'] as Map? ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toJson(),
        'description': description,
        'params': params,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnemyMechanic &&
          id == other.id &&
          type == other.type &&
          description == other.description;

  @override
  int get hashCode => Object.hash(id, type, description);

  @override
  String toString() => 'EnemyMechanic($id [${type.displayName}] $description)';
}

/// 敌人基础模型
///
/// 普通敌人和精英敌人共用此模型。
class Enemy {
  /// 敌人唯一ID
  final String id;

  /// 敌人名称
  final String name;

  /// 战力指数
  final int powerIndex;

  /// 生命值
  final int health;

  /// 内力值
  final int innerEnergy;

  /// 外功攻击力
  final int externalAttack;

  /// 内功攻击力
  final int internalAttack;

  /// 防御力
  final int defense;

  /// 先手值
  final int initiative;

  /// 闪避率（百分比 0-100）
  final int dodgeRate;

  /// 暴击率（百分比 0-100）
  final int critRate;

  /// 元素亲和性
  final ElementAffinity elementAffinity;

  /// 掉落表ID
  final String dropTableId;

  /// 特殊机制列表（DESIGN.md 3.4.5）
  final List<EnemyMechanic> mechanics;

  /// 敌人类型标签（如"山贼"、"邪修"、"妖兽"）
  final String enemyType;

  /// 是否为精英敌人
  final bool isElite;

  /// 敌人描述
  final String description;

  /// 敌人图片URL（按需下载）
  final String? imageUrl;

  const Enemy({
    required this.id,
    required this.name,
    required this.powerIndex,
    required this.health,
    this.innerEnergy = 0,
    this.externalAttack = 0,
    this.internalAttack = 0,
    this.defense = 0,
    this.initiative = 0,
    this.dodgeRate = 0,
    this.critRate = 0,
    this.elementAffinity = ElementAffinity.neutral,
    required this.dropTableId,
    this.mechanics = const [],
    this.enemyType = '杂兵',
    this.isElite = false,
    this.description = '',
    this.imageUrl,
  });

  factory Enemy.fromJson(Map<String, dynamic> json) => Enemy(
        id: json['id'] as String,
        name: json['name'] as String,
        powerIndex: json['powerIndex'] as int,
        health: json['health'] as int,
        innerEnergy: json['innerEnergy'] as int? ?? 0,
        externalAttack: json['externalAttack'] as int? ?? 0,
        internalAttack: json['internalAttack'] as int? ?? 0,
        defense: json['defense'] as int? ?? 0,
        initiative: json['initiative'] as int? ?? 0,
        dodgeRate: json['dodgeRate'] as int? ?? 0,
        critRate: json['critRate'] as int? ?? 0,
        elementAffinity: json['elementAffinity'] != null
            ? ElementAffinity.fromJson(json['elementAffinity'] as String)
            : ElementAffinity.neutral,
        dropTableId: json['dropTableId'] as String,
        mechanics: (json['mechanics'] as List?)
                ?.map((e) => EnemyMechanic.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        enemyType: json['enemyType'] as String? ?? '杂兵',
        isElite: json['isElite'] as bool? ?? false,
        description: json['description'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'powerIndex': powerIndex,
        'health': health,
        'innerEnergy': innerEnergy,
        'externalAttack': externalAttack,
        'internalAttack': internalAttack,
        'defense': defense,
        'initiative': initiative,
        'dodgeRate': dodgeRate,
        'critRate': critRate,
        'elementAffinity': elementAffinity.toJson(),
        'dropTableId': dropTableId,
        'mechanics': mechanics.map((e) => e.toJson()).toList(),
        'enemyType': enemyType,
        'isElite': isElite,
        'description': description,
        'imageUrl': imageUrl,
      };

  Enemy copyWith({
    String? id,
    String? name,
    int? powerIndex,
    int? health,
    int? innerEnergy,
    int? externalAttack,
    int? internalAttack,
    int? defense,
    int? initiative,
    int? dodgeRate,
    int? critRate,
    ElementAffinity? elementAffinity,
    String? dropTableId,
    List<EnemyMechanic>? mechanics,
    String? enemyType,
    bool? isElite,
    String? description,
    String? imageUrl,
  }) =>
      Enemy(
        id: id ?? this.id,
        name: name ?? this.name,
        powerIndex: powerIndex ?? this.powerIndex,
        health: health ?? this.health,
        innerEnergy: innerEnergy ?? this.innerEnergy,
        externalAttack: externalAttack ?? this.externalAttack,
        internalAttack: internalAttack ?? this.internalAttack,
        defense: defense ?? this.defense,
        initiative: initiative ?? this.initiative,
        dodgeRate: dodgeRate ?? this.dodgeRate,
        critRate: critRate ?? this.critRate,
        elementAffinity: elementAffinity ?? this.elementAffinity,
        dropTableId: dropTableId ?? this.dropTableId,
        mechanics: mechanics ?? this.mechanics,
        enemyType: enemyType ?? this.enemyType,
        isElite: isElite ?? this.isElite,
        description: description ?? this.description,
        imageUrl: imageUrl ?? this.imageUrl,
      );

  /// 根据难度缩放属性（DESIGN.md 3.7.2）
  Enemy scaleByDifficulty(Difficulty difficulty) {
    final mult = difficulty.multiplier;
    return copyWith(
      health: (health * mult).round(),
      externalAttack: (externalAttack * mult).round(),
      internalAttack: (internalAttack * mult).round(),
      defense: (defense * mult).round(),
      powerIndex: (powerIndex * mult).round(),
    );
  }

  /// 判断是否拥有某种机制
  bool hasMechanic(MechanicType type) =>
      mechanics.any((m) => m.type == type);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Enemy &&
          id == other.id &&
          name == other.name &&
          powerIndex == other.powerIndex &&
          health == other.health &&
          innerEnergy == other.innerEnergy &&
          externalAttack == other.externalAttack &&
          internalAttack == other.internalAttack &&
          defense == other.defense &&
          initiative == other.initiative &&
          dodgeRate == other.dodgeRate &&
          critRate == other.critRate &&
          elementAffinity == other.elementAffinity &&
          dropTableId == other.dropTableId &&
          _listEquals(mechanics, other.mechanics) &&
          enemyType == other.enemyType &&
          isElite == other.isElite;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        powerIndex,
        health,
        elementAffinity,
        isElite,
      );

  @override
  String toString() => 'Enemy($id: $name [${enemyType}] power=$powerIndex hp=$health${isElite ? " [精英]" : ""})';
}

/// Boss阶段（DESIGN.md 3.4.5 — 多阶段Boss）
///
/// 多阶段Boss → 需要续航+适应流
/// 地狱难度：Boss新增二阶段（DESIGN.md 3.7.2）
class BossPhase {
  /// 阶段序号（1, 2, 3...）
  final int phase;

  /// 阶段名称（如"狂暴"、"涅槃"、"终极形态"）
  final String name;

  /// 触发条件（如 "50%hp" / "25%hp"）
  final String triggerCondition;

  /// 阶段属性倍率
  final double healthMultiplier;
  final double attackMultiplier;
  final double defenseMultiplier;

  /// 阶段新增机制
  final List<EnemyMechanic> addedMechanics;

  /// 阶段移除机制（某些机制在新阶段不再生效）
  final List<String> removedMechanicIds;

  /// 阶段切换描写模板ID
  final String? narrationTemplateId;

  const BossPhase({
    required this.phase,
    required this.name,
    required this.triggerCondition,
    this.healthMultiplier = 1.0,
    this.attackMultiplier = 1.0,
    this.defenseMultiplier = 1.0,
    this.addedMechanics = const [],
    this.removedMechanicIds = const [],
    this.narrationTemplateId,
  });

  factory BossPhase.fromJson(Map<String, dynamic> json) => BossPhase(
        phase: json['phase'] as int,
        name: json['name'] as String,
        triggerCondition: json['triggerCondition'] as String,
        healthMultiplier: (json['healthMultiplier'] as num?)?.toDouble() ?? 1.0,
        attackMultiplier: (json['attackMultiplier'] as num?)?.toDouble() ?? 1.0,
        defenseMultiplier: (json['defenseMultiplier'] as num?)?.toDouble() ?? 1.0,
        addedMechanics: (json['addedMechanics'] as List?)
                ?.map((e) => EnemyMechanic.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        removedMechanicIds: (json['removedMechanicIds'] as List?)?.cast<String>() ?? const [],
        narrationTemplateId: json['narrationTemplateId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'phase': phase,
        'name': name,
        'triggerCondition': triggerCondition,
        'healthMultiplier': healthMultiplier,
        'attackMultiplier': attackMultiplier,
        'defenseMultiplier': defenseMultiplier,
        'addedMechanics': addedMechanics.map((e) => e.toJson()).toList(),
        'removedMechanicIds': removedMechanicIds,
        'narrationTemplateId': narrationTemplateId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BossPhase &&
          phase == other.phase &&
          name == other.name &&
          triggerCondition == other.triggerCondition &&
          healthMultiplier == other.healthMultiplier &&
          attackMultiplier == other.attackMultiplier &&
          defenseMultiplier == other.defenseMultiplier;

  @override
  int get hashCode =>
      Object.hash(phase, name, triggerCondition, healthMultiplier, attackMultiplier);

  @override
  String toString() => 'BossPhase($phase: $name trigger=$triggerCondition atk×$attackMultiplier)';
}

/// Boss模型（继承自Enemy，增加阶段系统）
///
/// Boss档战斗：10-15回合，展开式招式交锋描写（DESIGN.md 3.2.1）
class Boss extends Enemy {
  /// Boss阶段列表（DESIGN.md 3.4.5 — 多阶段Boss）
  final List<BossPhase> phases;

  /// Boss专属掉落表ID（DESIGN.md 3.7.5 定向掉落）
  final String? bossDropTableId;

  /// Boss故事背景
  final String lore;

  /// Boss配图URL（关键节点配图，DESIGN.md 3.2.4）
  final String? bossImageUrl;

  const Boss({
    required super.id,
    required super.name,
    required super.powerIndex,
    required super.health,
    super.innerEnergy,
    super.externalAttack,
    super.internalAttack,
    super.defense,
    super.initiative,
    super.dodgeRate,
    super.critRate,
    super.elementAffinity,
    required super.dropTableId,
    super.mechanics,
    super.description,
    this.phases = const [],
    this.bossDropTableId,
    this.lore = '',
    this.bossImageUrl,
  }) : super(
          enemyType: 'Boss',
          isElite: true,
          imageUrl: bossImageUrl,
        );

  factory Boss.fromJson(Map<String, dynamic> json) => Boss(
        id: json['id'] as String,
        name: json['name'] as String,
        powerIndex: json['powerIndex'] as int,
        health: json['health'] as int,
        innerEnergy: json['innerEnergy'] as int? ?? 0,
        externalAttack: json['externalAttack'] as int? ?? 0,
        internalAttack: json['internalAttack'] as int? ?? 0,
        defense: json['defense'] as int? ?? 0,
        initiative: json['initiative'] as int? ?? 0,
        dodgeRate: json['dodgeRate'] as int? ?? 0,
        critRate: json['critRate'] as int? ?? 0,
        elementAffinity: json['elementAffinity'] != null
            ? ElementAffinity.fromJson(json['elementAffinity'] as String)
            : ElementAffinity.neutral,
        dropTableId: json['dropTableId'] as String,
        mechanics: (json['mechanics'] as List?)
                ?.map((e) => EnemyMechanic.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        description: json['description'] as String? ?? '',
        phases: (json['phases'] as List?)
                ?.map((e) => BossPhase.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        bossDropTableId: json['bossDropTableId'] as String?,
        lore: json['lore'] as String? ?? '',
        bossImageUrl: json['bossImageUrl'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'phases': phases.map((e) => e.toJson()).toList(),
        'bossDropTableId': bossDropTableId,
        'lore': lore,
        'bossImageUrl': bossImageUrl,
      };

  /// 根据当前血量百分比判断应处于哪个阶段
  ///
  /// 返回当前阶段和下一个阶段（如有）
  (BossPhase? current, BossPhase? next) getCurrentPhase(double healthPct) {
    BossPhase? current;
    BossPhase? next;
    for (var i = 0; i < phases.length; i++) {
      final phase = phases[i];
      // 解析触发条件如 "50%hp"
      final triggerPct = double.tryParse(
              phase.triggerCondition.replaceAll(RegExp(r'[^\d.]'), '')) ??
          100.0;
      if (healthPct <= triggerPct) {
        current = phase;
        next = (i + 1 < phases.length) ? phases[i + 1] : null;
        break;
      }
    }
    return (current, next);
  }

  /// 根据难度缩放（地狱难度Boss新增二阶段，DESIGN.md 3.7.2）
  Boss scaleByDifficulty(Difficulty difficulty) {
    final scaled = super.scaleByDifficulty(difficulty);
    return Boss(
      id: scaled.id,
      name: scaled.name,
      powerIndex: scaled.powerIndex,
      health: scaled.health,
      innerEnergy: scaled.innerEnergy,
      externalAttack: scaled.externalAttack,
      internalAttack: scaled.internalAttack,
      defense: scaled.defense,
      initiative: scaled.initiative,
      dodgeRate: scaled.dodgeRate,
      critRate: scaled.critRate,
      elementAffinity: scaled.elementAffinity,
      dropTableId: scaled.dropTableId,
      mechanics: scaled.mechanics,
      description: scaled.description,
      // 地狱及以上难度增加额外阶段
      phases: difficulty.index >= Difficulty.hell.index
          ? [...phases, _extraPhase()]
          : phases,
      bossDropTableId: bossDropTableId,
      lore: lore,
      bossImageUrl: bossImageUrl,
    );
  }

  /// 地狱难度额外阶段
  BossPhase _extraPhase() => const BossPhase(
        phase: 99,
        name: '终极形态',
        triggerCondition: '10%hp',
        attackMultiplier: 1.5,
        defenseMultiplier: 1.3,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Boss &&
          id == other.id &&
          name == other.name &&
          powerIndex == other.powerIndex &&
          health == other.health &&
          _listEquals(phases, other.phases) &&
          bossDropTableId == other.bossDropTableId;

  @override
  int get hashCode => Object.hash(id, name, powerIndex, bossDropTableId);

  @override
  String toString() =>
      'Boss($id: $name power=$powerIndex hp=$health phases=${phases.length})';
}

bool _listEquals(List a, List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
