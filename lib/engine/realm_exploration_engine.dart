// =============================================================================
// realm_exploration_engine.dart — 秘境探索引擎
//
// 依据 REALM_DESIGN_V2.md：
//   每秘境 20-30 步抉择制探索，Boss 固定最后一步。
//   节点类型：战斗60% / 抉择13% / 机关7% / 营地5% / 宝箱10% / 奇遇5%
//   难度递推解锁：normal→hard→hell→inferno→下一秘境normal
//   首通奖励：银两200×难度系数 + 保底rare + 福缘+2
//
// 设计原则（与UI解耦）：
//   本引擎只负责：路径生成 / 节点随机事件内容 / 解锁状态 / 首通判定。
//   UI 拿节点后自行决定如何调用 BattleEngine / DropEngine。
// =============================================================================

import 'dart:math';

import '../models/enums.dart';

/// 探索节点类型
enum ExplorationNodeType {
  battle('战斗', 60),
  choice('抉择', 13),
  trap('机关', 7),
  camp('营地', 5),
  treasure('宝箱', 10),
  event('奇遇', 5);

  const ExplorationNodeType(this.displayName, this.weight);

  final String displayName;
  final int weight;
}

/// 探索节点（一次相遇/一件事）
class ExplorationNode {
  final int index;            // 第几步 (1-based)
  final int totalSteps;       // 总步数
  final ExplorationNodeType type;

  final String? enemyId;      // battle/boss 节点的敌人
  final bool isBoss;

  // 事件节点内容
  final String title;
  final String description;
  final String? optionA;      // 选择A文案
  final String? optionB;      // 选择B文案
  final String? optionADesc;  // A结果描述
  final String? optionBDesc;  // B结果描述

  // 结果数值（由引擎预计算，UI展示+应用）
  final int? hpDeltaPct;      // 生命变化百分比（负=扣血）
  final int? rewardSilver;
  final String? rewardNote;   // 奖励描述

  const ExplorationNode({
    required this.index,
    required this.totalSteps,
    required this.type,
    this.enemyId,
    this.isBoss = false,
    this.title = '',
    this.description = '',
    this.optionA,
    this.optionB,
    this.optionADesc,
    this.optionBDesc,
    this.hpDeltaPct,
    this.rewardSilver,
    this.rewardNote,
  });
}

/// 探索产出（节点执行后的结果，供UI处理）
class ExplorationOutcome {
  final String narration;
  final int hpDeltaPct;       // 负值扣血
  final int silverDelta;      // 正得负失
  final bool battleTriggered;
  final String? enemyId;
  final bool isBoss;
  final bool treasureFound;   // 应触发一次掉落

  const ExplorationOutcome({
    required this.narration,
    this.hpDeltaPct = 0,
    this.silverDelta = 0,
    this.battleTriggered = false,
    this.enemyId,
    this.isBoss = false,
    this.treasureFound = false,
  });
}

/// 秘境探索引擎
class RealmExplorationEngine {
  RealmExplorationEngine(this._random);

  final Random _random;

  // 各难度的步数
  static const Map<Difficulty, int> _stepsByDifficulty = {
    Difficulty.normal: 20,
    Difficulty.hard: 24,
    Difficulty.hell: 28,
    Difficulty.inferno: 30,
  };

  // 难度系数（首通奖励/怪物缩放的参考）
  static const Map<Difficulty, int> _difficultyCoeff = {
    Difficulty.normal: 1,
    Difficulty.hard: 2,
    Difficulty.hell: 3,
    Difficulty.inferno: 4,
  };

  static int stepsOf(Difficulty d) => _stepsByDifficulty[d] ?? 20;
  static int coeffOf(Difficulty d) => _difficultyCoeff[d] ?? 1;

  /// 生成探索路径（最后一步必 Boss）
  ///
  /// [enemyPool] 普通敌人ID池，[elitePool] 精英敌人ID池，[bossId] Boss敌人ID。
  /// 遭遇战节点 20% 概率从精英池出怪（否则普通池）。
  /// [eventConfigs] 由调用方从 ConfigLoader 传入（避免引擎依赖 ConfigLoader）。
  List<ExplorationNode> generatePath({
    required Difficulty difficulty,
    required List<String> enemyPool,
    required String bossId,
    List<String> elitePool = const [],
    List<String> eventNames = const [],
  }) {
    final total = stepsOf(difficulty);
    final nodes = <ExplorationNode>[];

    for (var i = 1; i < total; i++) {
      final type = _rollNodeType();
      nodes.add(_buildNode(
        index: i,
        totalSteps: total,
        type: type,
        enemyPool: enemyPool,
        elitePool: elitePool,
        eventNames: eventNames,
      ));
    }

    // Boss 固定最后一步
    nodes.add(ExplorationNode(
      index: total,
      totalSteps: total,
      type: ExplorationNodeType.battle,
      enemyId: bossId,
      isBoss: true,
      title: 'Boss',
      description: '',
    ));

    return nodes;
  }

  /// 按权重随机节点类型
  ExplorationNodeType _rollNodeType() {
    final totalWeight = ExplorationNodeType.values
        .fold<int>(0, (s, t) => s + t.weight);
    var roll = _random.nextInt(totalWeight);
    for (final t in ExplorationNodeType.values) {
      roll -= t.weight;
      if (roll < 0) return t;
    }
    return ExplorationNodeType.battle;
  }

  /// 构建非Boss节点
  ExplorationNode _buildNode({
    required int index,
    required int totalSteps,
    required ExplorationNodeType type,
    required List<String> enemyPool,
    required List<String> elitePool,
    required List<String> eventNames,
  }) {
    switch (type) {
      case ExplorationNodeType.battle:
        // 20% 概率遭遇精英（elitePool 非空时）
        final isElite = elitePool.isNotEmpty && _random.nextInt(100) < 20;
        final pool = isElite ? elitePool : enemyPool;
        final enemyId =
            pool.isEmpty ? null : pool[_random.nextInt(pool.length)];
        return ExplorationNode(
          index: index, totalSteps: totalSteps, type: type,
          enemyId: enemyId,
          title: isElite ? '精英遭遇战' : '遭遇战',
          description: isElite
              ? '前方气息凶戾，似有强敌盘踞！'
              : '前方影影绰绰，有敌人拦路。',
        );

      case ExplorationNodeType.treasure:
        return ExplorationNode(
          index: index, totalSteps: totalSteps, type: type,
          title: '宝箱',
          description: '石壁凹处藏着一口落满灰尘的宝箱，锁扣已经锈蚀。',
          optionA: '打开宝箱',
          optionADesc: '宝箱中跃出一件装备！',
        );

      case ExplorationNodeType.camp:
        return ExplorationNode(
          index: index, totalSteps: totalSteps, type: type,
          title: '营地',
          description: '前方有火光，似乎是一处商旅营地。',
          optionA: '休息恢复',
          optionADesc: '你借宿一夜，气血恢复充盈。',
          optionB: '搜刮营地',
          optionBDesc: '你顺走了些银两，但歇息不足，精神不振。',
          hpDeltaPct: 100,
          rewardSilver: 80 + _random.nextInt(120),
        );

      case ExplorationNodeType.trap:
        return ExplorationNode(
          index: index, totalSteps: totalSteps, type: type,
          title: '机关',
          description: '一道暗箭机关横在路中，机簧声隐约可闻。',
          optionA: '小心躲避',
          optionADesc: '你轻身闪过，毫发无伤。',
          optionB: '硬闯而过',
          optionBDesc: '暗箭擦身而过，你受了些伤，但捡到了机关的宝箱。',
          hpDeltaPct: -20,
        );

      case ExplorationNodeType.choice:
        return ExplorationNode(
          index: index, totalSteps: totalSteps, type: type,
          title: '岔路口',
          description: '两条路摆在眼前：左边山道平缓安全，右边断崖危险但崖底有宝光闪烁。',
          optionA: '走左边（安全）',
          optionADesc: '一路无事，继续前行。',
          optionB: '走右边（冒险）',
          optionBDesc: '你攀崖而下，寻得一件宝物！',
        );

      case ExplorationNodeType.event:
        final eventName =
            eventNames.isEmpty ? '山野奇闻' : eventNames[_random.nextInt(eventNames.length)];
        return ExplorationNode(
          index: index, totalSteps: totalSteps, type: type,
          title: '奇遇',
          description: eventName,
          optionA: '一探究竟',
          optionADesc: '你循着异象而去，小有所获。',
          rewardSilver: 50 + _random.nextInt(150),
        );
    }
  }

  /// 执行"冒险"分支（岔路右/机关硬闯）的决定性判定
  bool rollAdventure() => _random.nextDouble() < 0.5;
}

/// 秘境解锁管理器（难度递推 + 秘境间递推）
class RealmUnlockManager {
  RealmUnlockManager._();

  /// 秘境推关顺序
  static const List<String> realmOrder = [
    'realm_gumu',
    'realm_cangjing',
    'realm_xuemo',
    'realm_tianji',
    'realm_lunhui',
    'endless_void',
  ];

  static const List<Difficulty> difficultyOrder = [
    Difficulty.normal,
    Difficulty.hard,
    Difficulty.hell,
    Difficulty.inferno,
  ];

  /// 判断某秘境+难度是否可进入
  ///
  /// [cleared] 已通关集合，元素为 'realmId:difficulty' 字符串。
  static bool isUnlocked({
    required String realmId,
    required Difficulty difficulty,
    required Set<String> cleared,
  }) {
    final realmIdx = realmOrder.indexOf(realmId);
    if (realmIdx < 0) return true; // 未知秘境放行

    // 第一个秘境的normal恒解锁
    if (realmIdx == 0 && difficulty == Difficulty.normal) return true;

    // 本秘境：通关上一难度解锁
    final diffIdx = difficultyOrder.indexOf(difficulty);
    if (diffIdx > 0) {
      final prev = difficultyOrder[diffIdx - 1];
      if (!cleared.contains('$realmId:${prev.name}')) return false;
      return true;
    }

    // normal难度：需通关上一秘境的inferno
    if (difficulty == Difficulty.normal && realmIdx > 0) {
      final prevRealm = realmOrder[realmIdx - 1];
      return cleared.contains('$prevRealm:inferno');
    }

    return true;
  }

  /// 首通奖励计算
  /// 返回 (银两奖励, 是否首通)
  static (int, bool) completionReward({
    required Difficulty difficulty,
    required bool firstClear,
  }) {
    final coeff = RealmExplorationEngine.coeffOf(difficulty);
    if (firstClear) {
      return (200 * coeff, true);
    }
    return (50 * coeff, false);
  }
}