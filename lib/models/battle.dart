// =============================================================================
// 对应 DESIGN.md 章节：3.2 战斗系统
//   3.2.1 三档战斗 → BattleTier (在 enums.dart 中)
//   3.2.2 回合内多动作 → BattleAction, BattleTurn
//   3.2.3 连刷模式 → autoRun 标志
//   3.6 真气逆行 → QiDeviationLevel (在 enums.dart 中)
//   3.10.4 招式描写随战力进化
// =============================================================================

import 'enums.dart';
import '../engine/drop_engine.dart' show DropResult;

/// 战斗动作（DESIGN.md 3.2.2 — 回合内多动作）
///
/// 1回合 = 1轮
/// 1轮 = 双方各做 2-3 个动作（出招/运功/闪避/反击）
class BattleAction {
  /// 动作类型
  final BattleActionType type;

  /// 执行者ID（玩家角色ID或敌人ID）
  final String actorId;

  /// 是否为玩家方动作
  final bool isPlayer;

  /// 使用的武功ID（出招/运功/施展武功时）
  final String? martialArtId;

  /// 造成伤害（如有）
  final int damage;

  /// 受到伤害（反击/闪避失败时）
  final int damageTaken;

  /// 闪避成功
  final bool dodged;

  /// 暴击
  final bool critical;

  /// 内力变化（正=恢复, 负=消耗）
  final int energyChange;

  /// 动作描写文本（已填充变量后的最终文本）
  final String narration;

  /// 附加效果描述（如触发了暗金特殊效果）
  final String? effectNote;

  const BattleAction({
    required this.type,
    required this.actorId,
    required this.isPlayer,
    this.martialArtId,
    this.damage = 0,
    this.damageTaken = 0,
    this.dodged = false,
    this.critical = false,
    this.energyChange = 0,
    this.narration = '',
    this.effectNote,
  });

  factory BattleAction.fromJson(Map<String, dynamic> json) => BattleAction(
        type: BattleActionType.fromJson(json['type'] as String),
        actorId: json['actorId'] as String,
        isPlayer: json['isPlayer'] as bool,
        martialArtId: json['martialArtId'] as String?,
        damage: json['damage'] as int? ?? 0,
        damageTaken: json['damageTaken'] as int? ?? 0,
        dodged: json['dodged'] as bool? ?? false,
        critical: json['critical'] as bool? ?? false,
        energyChange: json['energyChange'] as int? ?? 0,
        narration: json['narration'] as String? ?? '',
        effectNote: json['effectNote'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'type': type.toJson(),
        'actorId': actorId,
        'isPlayer': isPlayer,
        'martialArtId': martialArtId,
        'damage': damage,
        'damageTaken': damageTaken,
        'dodged': dodged,
        'critical': critical,
        'energyChange': energyChange,
        'narration': narration,
        'effectNote': effectNote,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BattleAction &&
          type == other.type &&
          actorId == other.actorId &&
          isPlayer == other.isPlayer &&
          martialArtId == other.martialArtId &&
          damage == other.damage &&
          damageTaken == other.damageTaken &&
          dodged == other.dodged &&
          critical == other.critical &&
          energyChange == other.energyChange &&
          narration == other.narration &&
          effectNote == other.effectNote;

  @override
  int get hashCode =>
      Object.hash(type, actorId, isPlayer, damage, narration, critical, dodged);

  @override
  String toString() =>
      'BattleAction(${isPlayer ? "玩家" : "敌方"} ${type.displayName} dmg=$damage${critical ? " [暴击]" : ""}${dodged ? " [闪避]" : ""})';
}

/// 战斗回合（DESIGN.md 3.2.2）
///
/// 1回合 = 双方各做 2-3 个动作
class BattleTurn {
  /// 回合序号（从1开始）
  final int turnNumber;

  /// 本回合所有动作（按时间顺序）
  final List<BattleAction> actions;

  /// 回合开始时玩家生命
  final int playerHealthStart;

  /// 回合结束时玩家生命
  final int playerHealthEnd;

  /// 回合开始时敌方生命
  final int enemyHealthStart;

  /// 回合结束时敌方生命
  final int enemyHealthEnd;

  /// 回合描写文本（整回合的综合描写）
  final String narration;

  const BattleTurn({
    required this.turnNumber,
    this.actions = const [],
    this.playerHealthStart = 0,
    this.playerHealthEnd = 0,
    this.enemyHealthStart = 0,
    this.enemyHealthEnd = 0,
    this.narration = '',
  });

  factory BattleTurn.fromJson(Map<String, dynamic> json) => BattleTurn(
        turnNumber: json['turnNumber'] as int,
        actions: (json['actions'] as List?)
                ?.map((e) => BattleAction.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        playerHealthStart: json['playerHealthStart'] as int? ?? 0,
        playerHealthEnd: json['playerHealthEnd'] as int? ?? 0,
        enemyHealthStart: json['enemyHealthStart'] as int? ?? 0,
        enemyHealthEnd: json['enemyHealthEnd'] as int? ?? 0,
        narration: json['narration'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'turnNumber': turnNumber,
        'actions': actions.map((e) => e.toJson()).toList(),
        'playerHealthStart': playerHealthStart,
        'playerHealthEnd': playerHealthEnd,
        'enemyHealthStart': enemyHealthStart,
        'enemyHealthEnd': enemyHealthEnd,
        'narration': narration,
      };

  /// 本回合玩家造成的总伤害
  int get totalPlayerDamage =>
      actions.where((a) => a.isPlayer).fold(0, (sum, a) => sum + a.damage);

  /// 本回合玩家受到的总伤害
  int get totalDamageTaken =>
      actions.where((a) => !a.isPlayer).fold(0, (sum, a) => sum + a.damage);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BattleTurn &&
          turnNumber == other.turnNumber &&
          _listEquals(actions, other.actions) &&
          playerHealthStart == other.playerHealthStart &&
          playerHealthEnd == other.playerHealthEnd &&
          enemyHealthStart == other.enemyHealthStart &&
          enemyHealthEnd == other.enemyHealthEnd &&
          narration == other.narration;

  @override
  int get hashCode =>
      Object.hash(turnNumber, playerHealthStart, enemyHealthStart, narration);

  @override
  String toString() => 'BattleTurn(#$turnNumber actions=${actions.length} pHP:$playerHealthStart→$playerHealthEnd eHP:$enemyHealthStart→$enemyHealthEnd)';
}

/// 战斗状态（运行时战斗引擎状态）
///
/// 表示一场正在进行中的战斗的完整状态。
class BattleState {
  /// 战斗唯一ID
  final String battleId;

  /// 战斗档位
  final BattleTier tier;

  /// 秘境ID
  final String realmId;

  /// 当前层数
  final int layer;

  /// 难度
  final Difficulty difficulty;

  /// 敌人ID
  final String enemyId;

  /// 当前回合数
  final int currentTurn;

  /// 最大回合数
  final int maxTurns;

  /// 玩家当前生命
  final int playerHealth;

  /// 玩家最大生命
  final int playerMaxHealth;

  /// 玩家当前内力
  final int playerInnerEnergy;

  /// 敌人当前生命
  final int enemyHealth;

  /// 敌人最大生命
  final int enemyMaxHealth;

  /// 是否为连刷模式（DESIGN.md 3.2.3）
  final bool isAutoRun;

  /// 已执行的回合列表
  final List<BattleTurn> turns;

  /// 真气逆行程度（DESIGN.md 3.6）
  final QiDeviationLevel qiDeviation;

  /// Boss当前阶段（仅Boss档）
  final int? bossPhase;

  const BattleState({
    required this.battleId,
    required this.tier,
    required this.realmId,
    required this.layer,
    required this.difficulty,
    required this.enemyId,
    this.currentTurn = 1,
    required this.maxTurns,
    required this.playerHealth,
    required this.playerMaxHealth,
    this.playerInnerEnergy = 0,
    required this.enemyHealth,
    required this.enemyMaxHealth,
    this.isAutoRun = false,
    this.turns = const [],
    this.qiDeviation = QiDeviationLevel.none,
    this.bossPhase,
  });

  factory BattleState.fromJson(Map<String, dynamic> json) => BattleState(
        battleId: json['battleId'] as String,
        tier: BattleTier.fromJson(json['tier'] as String),
        realmId: json['realmId'] as String,
        layer: json['layer'] as int,
        difficulty: Difficulty.fromJson(json['difficulty'] as String),
        enemyId: json['enemyId'] as String,
        currentTurn: json['currentTurn'] as int? ?? 1,
        maxTurns: json['maxTurns'] as int,
        playerHealth: json['playerHealth'] as int,
        playerMaxHealth: json['playerMaxHealth'] as int,
        playerInnerEnergy: json['playerInnerEnergy'] as int? ?? 0,
        enemyHealth: json['enemyHealth'] as int,
        enemyMaxHealth: json['enemyMaxHealth'] as int,
        isAutoRun: json['isAutoRun'] as bool? ?? false,
        turns: (json['turns'] as List?)
                ?.map((e) => BattleTurn.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        qiDeviation: json['qiDeviation'] != null
            ? QiDeviationLevel.fromJson(json['qiDeviation'] as String)
            : QiDeviationLevel.none,
        bossPhase: json['bossPhase'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'battleId': battleId,
        'tier': tier.toJson(),
        'realmId': realmId,
        'layer': layer,
        'difficulty': difficulty.toJson(),
        'enemyId': enemyId,
        'currentTurn': currentTurn,
        'maxTurns': maxTurns,
        'playerHealth': playerHealth,
        'playerMaxHealth': playerMaxHealth,
        'playerInnerEnergy': playerInnerEnergy,
        'enemyHealth': enemyHealth,
        'enemyMaxHealth': enemyMaxHealth,
        'isAutoRun': isAutoRun,
        'turns': turns.map((e) => e.toJson()).toList(),
        'qiDeviation': qiDeviation.toJson(),
        'bossPhase': bossPhase,
      };

  BattleState copyWith({
    String? battleId,
    BattleTier? tier,
    String? realmId,
    int? layer,
    Difficulty? difficulty,
    String? enemyId,
    int? currentTurn,
    int? maxTurns,
    int? playerHealth,
    int? playerMaxHealth,
    int? playerInnerEnergy,
    int? enemyHealth,
    int? enemyMaxHealth,
    bool? isAutoRun,
    List<BattleTurn>? turns,
    QiDeviationLevel? qiDeviation,
    int? bossPhase,
  }) =>
      BattleState(
        battleId: battleId ?? this.battleId,
        tier: tier ?? this.tier,
        realmId: realmId ?? this.realmId,
        layer: layer ?? this.layer,
        difficulty: difficulty ?? this.difficulty,
        enemyId: enemyId ?? this.enemyId,
        currentTurn: currentTurn ?? this.currentTurn,
        maxTurns: maxTurns ?? this.maxTurns,
        playerHealth: playerHealth ?? this.playerHealth,
        playerMaxHealth: playerMaxHealth ?? this.playerMaxHealth,
        playerInnerEnergy: playerInnerEnergy ?? this.playerInnerEnergy,
        enemyHealth: enemyHealth ?? this.enemyHealth,
        enemyMaxHealth: enemyMaxHealth ?? this.enemyMaxHealth,
        isAutoRun: isAutoRun ?? this.isAutoRun,
        turns: turns ?? this.turns,
        qiDeviation: qiDeviation ?? this.qiDeviation,
        bossPhase: bossPhase ?? this.bossPhase,
      );

  /// 玩家是否存活
  bool get isPlayerAlive => playerHealth > 0;

  /// 敌人是否存活
  bool get isEnemyAlive => enemyHealth > 0;

  /// 战斗是否结束
  bool get isOver => !isPlayerAlive || !isEnemyAlive || currentTurn > maxTurns;

  /// 玩家生命百分比
  double get playerHealthPct => playerMaxHealth > 0 ? playerHealth / playerMaxHealth : 0;

  /// 敌人生命百分比
  double get enemyHealthPct => enemyMaxHealth > 0 ? enemyHealth / enemyMaxHealth : 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BattleState &&
          battleId == other.battleId &&
          tier == other.tier &&
          realmId == other.realmId &&
          layer == other.layer &&
          difficulty == other.difficulty &&
          enemyId == other.enemyId &&
          currentTurn == other.currentTurn &&
          maxTurns == other.maxTurns &&
          playerHealth == other.playerHealth &&
          playerMaxHealth == other.playerMaxHealth &&
          playerInnerEnergy == other.playerInnerEnergy &&
          enemyHealth == other.enemyHealth &&
          enemyMaxHealth == other.enemyMaxHealth &&
          isAutoRun == other.isAutoRun &&
          qiDeviation == other.qiDeviation &&
          bossPhase == other.bossPhase;

  @override
  int get hashCode => Object.hash(
        battleId,
        tier,
        currentTurn,
        playerHealth,
        enemyHealth,
        qiDeviation,
      );

  @override
  String toString() =>
      'BattleState($battleId [${tier.displayName}] turn=$currentTurn/$maxTurns pHP=$playerHealth/$playerMaxHealth eHP=$enemyHealth/$enemyMaxHealth${isAutoRun ? " [连刷]" : ""})';
}

/// 战斗结果（战斗结束后生成）
class BattleResult {
  /// 战斗唯一ID
  final String battleId;

  /// 是否胜利
  final bool victory;

  /// 战斗档位
  final BattleTier tier;

  /// 战斗回合数
  final int turnsUsed;

  /// 玩家剩余生命
  final int playerHealthRemaining;

  /// 敌人ID
  final String enemyId;

  /// 秘境ID
  final String realmId;

  /// 层数
  final int layer;

  /// 难度
  final Difficulty difficulty;

  /// 战斗描写全文（所有回合描写的拼接）
  final String fullNarration;

  /// 排行榜记录用的时间戳
  final DateTime timestamp;

  /// BD流派名称（DESIGN.md 3.4.4 — BD流派画像）
  final String? bdArchetypeName;

  /// BD流派描述
  final String? bdArchetypeDesc;

  /// 是否为连刷模式
  final bool isAutoRun;

  /// 掉落结果列表（DESIGN.md 3.2.4 — 战斗结束后生成的装备掉落）
  final List<DropResult> drops;

  /// 击杀数量（本次战斗击杀的敌人数量）
  final int killCount;

  /// 掉落数量（本次战斗的掉落装备数量）
  final int dropCount;

  /// 每回合明细（回合回放和数据埋点用）
  /// 仅保留最后 N 回合，避免极端战斗撑爆内存
  final List<BattleTurn> turns;

  const BattleResult({
    required this.battleId,
    required this.victory,
    required this.tier,
    required this.turnsUsed,
    required this.playerHealthRemaining,
    required this.enemyId,
    required this.realmId,
    required this.layer,
    required this.difficulty,
    required this.fullNarration,
    required this.timestamp,
    this.bdArchetypeName,
    this.bdArchetypeDesc,
    this.isAutoRun = false,
    this.drops = const [],
    this.killCount = 0,
    this.dropCount = 0,
    this.turns = const [],
  });

  factory BattleResult.fromJson(Map<String, dynamic> json) => BattleResult(
        battleId: json['battleId'] as String,
        victory: json['victory'] as bool,
        tier: BattleTier.fromJson(json['tier'] as String),
        turnsUsed: json['turnsUsed'] as int,
        playerHealthRemaining: json['playerHealthRemaining'] as int,
        enemyId: json['enemyId'] as String,
        realmId: json['realmId'] as String,
        layer: json['layer'] as int,
        difficulty: Difficulty.fromJson(json['difficulty'] as String),
        fullNarration: json['fullNarration'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        bdArchetypeName: json['bdArchetypeName'] as String?,
        bdArchetypeDesc: json['bdArchetypeDesc'] as String?,
        isAutoRun: json['isAutoRun'] as bool? ?? false,
        drops: const [], // drops 不序列化（运行时数据）
        turns: (json['turns'] as List?)
                ?.map((e) => BattleTurn.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'battleId': battleId,
        'victory': victory,
        'tier': tier.toJson(),
        'turnsUsed': turnsUsed,
        'playerHealthRemaining': playerHealthRemaining,
        'enemyId': enemyId,
        'realmId': realmId,
        'layer': layer,
        'difficulty': difficulty.toJson(),
        'fullNarration': fullNarration,
        'timestamp': timestamp.toIso8601String(),
        'bdArchetypeName': bdArchetypeName,
        'bdArchetypeDesc': bdArchetypeDesc,
        'isAutoRun': isAutoRun,
        'turns': turns.map((e) => e.toJson()).toList(),
        // drops 不序列化（运行时数据）
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BattleResult &&
          battleId == other.battleId &&
          victory == other.victory &&
          tier == other.tier &&
          turnsUsed == other.turnsUsed &&
          playerHealthRemaining == other.playerHealthRemaining &&
          enemyId == other.enemyId &&
          realmId == other.realmId &&
          layer == other.layer &&
          difficulty == other.difficulty &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      Object.hash(battleId, victory, tier, turnsUsed, enemyId, timestamp);

  @override
  String toString() =>
      'BattleResult($battleId ${victory ? "胜利" : "失败"} [${tier.displayName}] turns=$turnsUsed)';
}

bool _listEquals(List a, List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
