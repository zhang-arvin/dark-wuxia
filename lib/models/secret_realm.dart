// =============================================================================
// 对应 DESIGN.md 章节：3.7 秘境系统
//   3.7.1 秘境类型 → RealmType (在 enums.dart 中)
//   3.7.2 难度分级 → Difficulty (在 enums.dart 中)
//   3.7.3 秘境变体 → RealmVariant (在 enums.dart 中)
//   3.7.4 首发秘境列表
//   3.7.5 定向掉落
//   五、数据结构 5.1 — RealmProgress 定义
// =============================================================================

import 'enums.dart';

/// 秘境进度（DESIGN.md 5.1）
///
/// 跟踪玩家在某个秘境中的推进进度。
class RealmProgress {
  /// 秘境ID
  final String realmId;

  /// 当前层数
  final int currentLayer;

  /// 当前难度等级索引（0=普通, 1=困难, 2=地狱, 3=炼狱）
  final int currentDifficulty;

  /// 已完成的事件ID列表
  final List<String> completedEvents;

  /// 已击败敌人数
  final int enemyCount;

  /// 已获得掉落数
  final int dropCount;

  /// 连刷模式是否开启（DESIGN.md 3.2.3）
  final bool isAutoRun;

  /// 当前层数的房间探索进度（迷宫秘境的分支路径选择）
  final List<String> visitedRooms;

  const RealmProgress({
    required this.realmId,
    this.currentLayer = 1,
    this.currentDifficulty = 0,
    this.completedEvents = const [],
    this.enemyCount = 0,
    this.dropCount = 0,
    this.isAutoRun = false,
    this.visitedRooms = const [],
  });

  factory RealmProgress.fromJson(Map<String, dynamic> json) => RealmProgress(
        realmId: json['realmId'] as String,
        currentLayer: json['currentLayer'] as int? ?? 1,
        currentDifficulty: json['currentDifficulty'] as int? ?? 0,
        completedEvents: (json['completedEvents'] as List?)?.cast<String>() ?? const [],
        enemyCount: json['enemyCount'] as int? ?? 0,
        dropCount: json['dropCount'] as int? ?? 0,
        isAutoRun: json['isAutoRun'] as bool? ?? false,
        visitedRooms: (json['visitedRooms'] as List?)?.cast<String>() ?? const [],
      );

  Map<String, dynamic> toJson() => {
        'realmId': realmId,
        'currentLayer': currentLayer,
        'currentDifficulty': currentDifficulty,
        'completedEvents': completedEvents,
        'enemyCount': enemyCount,
        'dropCount': dropCount,
        'isAutoRun': isAutoRun,
        'visitedRooms': visitedRooms,
      };

  RealmProgress copyWith({
    String? realmId,
    int? currentLayer,
    int? currentDifficulty,
    List<String>? completedEvents,
    int? enemyCount,
    int? dropCount,
    bool? isAutoRun,
    List<String>? visitedRooms,
  }) =>
      RealmProgress(
        realmId: realmId ?? this.realmId,
        currentLayer: currentLayer ?? this.currentLayer,
        currentDifficulty: currentDifficulty ?? this.currentDifficulty,
        completedEvents: completedEvents ?? this.completedEvents,
        enemyCount: enemyCount ?? this.enemyCount,
        dropCount: dropCount ?? this.dropCount,
        isAutoRun: isAutoRun ?? this.isAutoRun,
        visitedRooms: visitedRooms ?? this.visitedRooms,
      );

  /// 获取难度枚举
  Difficulty get difficulty => Difficulty.values[currentDifficulty.clamp(0, 3)];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RealmProgress &&
          realmId == other.realmId &&
          currentLayer == other.currentLayer &&
          currentDifficulty == other.currentDifficulty &&
          _listEquals(completedEvents, other.completedEvents) &&
          enemyCount == other.enemyCount &&
          dropCount == other.dropCount &&
          isAutoRun == other.isAutoRun &&
          _listEquals(visitedRooms, other.visitedRooms);

  @override
  int get hashCode => Object.hash(
        realmId,
        currentLayer,
        currentDifficulty,
        enemyCount,
        dropCount,
        isAutoRun,
      );

  @override
  String toString() =>
      'RealmProgress($realmId L$currentLayer D${difficulty.displayName} kills=$enemyCount drops=$dropCount autoRun=$isAutoRun)';
}

/// 秘境配置（DESIGN.md 3.7.1 / 3.7.4）
///
/// 首发秘境列表：
/// | 秘境 | 类型 | 特色 | Boss掉落 |
/// |------|------|------|---------|
/// | 古墓遗迹 | 线性 | 新手友好 | 少林系暗金 |
/// | 剑冢 | 开放 | 剑法BD圣地 | 剑系暗金 |
/// | 藏经洞 | 线性 | 内功BD圣地 | 内功系暗金 |
/// | 幽冥鬼蜮 | 迷宫 | 邪功BD圣地 | 邪功系暗金 |
/// | 龙脉深处 | 挑战 | 最难，掉落最好 | 神品掉落 |
class RealmConfig {
  /// 秘境ID
  final String id;

  /// 秘境名称
  final String name;

  /// 秘境类型
  final RealmType type;

  /// 秘境描述/特色
  final String description;

  /// 总层数
  final int totalLayers;

  /// 推荐战力（玩家战力指数参考值）
  final int recommendedPower;

  /// Boss掉落表ID（DESIGN.md 3.7.5 定向掉落）
  final String bossDropTableId;

  /// 该秘境专属暗金ID列表
  final List<String> uniqueDropPool;

  /// 是否为新手友好
  final bool isBeginnerFriendly;

  /// 秘境场景图URL（可选，按需下载）
  final String? sceneImageUrl;

  /// 秘境变体列表（DESIGN.md 3.7.3）
  final List<RealmVariant> availableVariants;

  const RealmConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.totalLayers,
    required this.recommendedPower,
    required this.bossDropTableId,
    this.uniqueDropPool = const [],
    this.isBeginnerFriendly = false,
    this.sceneImageUrl,
    this.availableVariants = const [RealmVariant.normal],
  });

  factory RealmConfig.fromJson(Map<String, dynamic> json) => RealmConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        type: RealmType.fromJson(json['type'] as String),
        description: json['description'] as String,
        totalLayers: json['totalLayers'] as int,
        recommendedPower: json['recommendedPower'] as int,
        bossDropTableId: json['bossDropTableId'] as String,
        uniqueDropPool: (json['uniqueDropPool'] as List?)?.cast<String>() ?? const [],
        isBeginnerFriendly: json['isBeginnerFriendly'] as bool? ?? false,
        sceneImageUrl: json['sceneImageUrl'] as String?,
        availableVariants: (json['availableVariants'] as List?)
                ?.map((e) => RealmVariant.fromJson(e as String))
                .toList() ??
            const [RealmVariant.normal],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.toJson(),
        'description': description,
        'totalLayers': totalLayers,
        'recommendedPower': recommendedPower,
        'bossDropTableId': bossDropTableId,
        'uniqueDropPool': uniqueDropPool,
        'isBeginnerFriendly': isBeginnerFriendly,
        'sceneImageUrl': sceneImageUrl,
        'availableVariants': availableVariants.map((e) => e.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RealmConfig &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          description == other.description &&
          totalLayers == other.totalLayers &&
          recommendedPower == other.recommendedPower &&
          bossDropTableId == other.bossDropTableId;

  @override
  int get hashCode =>
      Object.hash(id, name, type, totalLayers, recommendedPower, bossDropTableId);

  @override
  String toString() => 'RealmConfig($id: $name [${type.displayName}] L$totalLayers)';
}

bool _listEquals(List a, List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
