// =============================================================================
// 对应 DESIGN.md 章节：3.3 装备系统
//   3.3.2 保底机制 → PityCounter
//   3.2.4 掉落闪光 → DropFlashLevel (在 enums.dart 中)
//   3.7.5 定向掉落
//   3.9.1 福缘系统（=D2 MF）
//   五、数据结构 5.2 — DropTable / DropRecord 定义
// =============================================================================

import 'enums.dart';

/// 掉落表（DESIGN.md 5.2）
///
/// 定义某秘境/某敌人的掉落概率和装备池。
class DropTable {
  /// 掉落表ID
  final String id;

  /// 品质掉率表
  ///
  /// key = 品质, value = 基础掉率
  /// 示例: {Quality.normal: 0.55, Quality.magic: 0.28, ...}
  final Map<Quality, double> rates;

  /// 可掉装备ID列表（基础装备baseId）
  final List<String> equipmentPool;

  /// 福缘影响系数（DESIGN.md 3.9.1 — 福缘属性影响掉落率）
  ///
  /// 值越高，福缘对提升品质掉率的放大越大
  final double fortuneMultiplier;

  /// 保底阈值（DESIGN.md 3.3.2 — 连续刷N只未掉暗金 → 保底）
  final int pityThreshold;

  /// 该掉落表对应的秘境ID（用于定向掉落）
  final String? realmId;

  /// 暗金专属掉落池（该掉落表专属的暗金ID列表，DESIGN.md 3.7.5）
  final List<String> uniquePool;

  /// 材料掉率（熔炼材料掉落，DESIGN.md 3.3.7）
  final double materialDropRate;

  const DropTable({
    required this.id,
    required this.rates,
    required this.equipmentPool,
    this.fortuneMultiplier = 0.01,
    this.pityThreshold = 200,
    this.realmId,
    this.uniquePool = const [],
    this.materialDropRate = 0.3,
  });

  factory DropTable.fromJson(Map<String, dynamic> json) => DropTable(
        id: json['id'] as String,
        rates: (json['rates'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(Quality.fromJson(k), (v as num).toDouble()),
        ),
        equipmentPool: (json['equipmentPool'] as List?)?.cast<String>() ?? const [],
        fortuneMultiplier: (json['fortuneMultiplier'] as num?)?.toDouble() ?? 0.01,
        pityThreshold: json['pityThreshold'] as int? ?? 200,
        realmId: json['realmId'] as String?,
        uniquePool: (json['uniquePool'] as List?)?.cast<String>() ?? const [],
        materialDropRate: (json['materialDropRate'] as num?)?.toDouble() ?? 0.3,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'rates': rates.map((k, v) => MapEntry(k.toJson(), v)),
        'equipmentPool': equipmentPool,
        'fortuneMultiplier': fortuneMultiplier,
        'pityThreshold': pityThreshold,
        'realmId': realmId,
        'uniquePool': uniquePool,
        'materialDropRate': materialDropRate,
      };

  /// 根据玩家福缘和保底计数器计算实际掉率
  ///
  /// DESIGN.md 3.3.2 保底机制:
  ///   运气积累: 每刷N只怪未掉暗金+ → 暗金掉率递增
  ///   保底: 连续刷200只未掉暗金 → 第201只必掉暗金
  Map<Quality, double> calculateActualRates(int fortune, PityCounter pity) {
    final adjustedRates = Map<Quality, double>.from(rates);

    // 福缘加成：提升高品质掉率
    final fortuneBonus = fortune * fortuneMultiplier;
    adjustedRates[Quality.unique] =
        (adjustedRates[Quality.unique] ?? 0) + fortuneBonus * 0.3;
    adjustedRates[Quality.divine] =
        (adjustedRates[Quality.divine] ?? 0) + fortuneBonus * 0.15;
    adjustedRates[Quality.legendary] =
        (adjustedRates[Quality.legendary] ?? 0) + fortuneBonus * 0.05;

    // 保底加成：递增暗金掉率
    if (pity.count > 0 && pity.count < pityThreshold) {
      // 每未掉一次，暗金掉率递增
      final pityBonus = (pity.count / pityThreshold) * 0.5; // 最多+50%
      adjustedRates[Quality.unique] =
          (adjustedRates[Quality.unique] ?? 0) + pityBonus;
    } else if (pity.count >= pityThreshold) {
      // 保底触发：必掉暗金
      adjustedRates[Quality.unique] = 1.0;
      for (final q in Quality.values) {
        if (q != Quality.unique) adjustedRates[q] = 0.0;
      }
    }

    // 归一化
    final total = adjustedRates.values.fold(0.0, (a, b) => a + b);
    if (total > 0) {
      adjustedRates.updateAll((k, v) => v / total);
    }

    return adjustedRates;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DropTable &&
          id == other.id &&
          rates.length == other.rates.length &&
          _mapEqualsDouble(rates, other.rates) &&
          _listEquals(equipmentPool, other.equipmentPool) &&
          fortuneMultiplier == other.fortuneMultiplier &&
          pityThreshold == other.pityThreshold &&
          realmId == other.realmId;

  @override
  int get hashCode => Object.hash(id, fortuneMultiplier, pityThreshold, realmId);

  @override
  String toString() => 'DropTable($id pool=${equipmentPool.length} pity=$pityThreshold)';
}

/// 掉落记录（DESIGN.md 5.1）
///
/// 记录每次掉落的历史，用于掉落展示和统计分析。
class DropRecord {
  /// 掉落的装备实例ID
  final String equipmentId;

  /// 掉落来源秘境ID
  final String realmId;

  /// 掉落层数
  final int layer;

  /// 掉落时间戳
  final DateTime timestamp;

  /// 掉落品质
  final Quality quality;

  /// 掉落来源（敌人ID或BossID）
  final String sourceId;

  /// 是否为连刷模式自动结算掉落
  final bool isAutoRun;

  const DropRecord({
    required this.equipmentId,
    required this.realmId,
    required this.layer,
    required this.timestamp,
    required this.quality,
    required this.sourceId,
    this.isAutoRun = false,
  });

  factory DropRecord.fromJson(Map<String, dynamic> json) => DropRecord(
        equipmentId: json['equipmentId'] as String,
        realmId: json['realmId'] as String,
        layer: json['layer'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        quality: Quality.fromJson(json['quality'] as String),
        sourceId: json['sourceId'] as String,
        isAutoRun: json['isAutoRun'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'equipmentId': equipmentId,
        'realmId': realmId,
        'layer': layer,
        'timestamp': timestamp.toIso8601String(),
        'quality': quality.toJson(),
        'sourceId': sourceId,
        'isAutoRun': isAutoRun,
      };

  /// 掉落闪光等级（DESIGN.md 3.2.4）
  DropFlashLevel get flashLevel => DropFlashLevel.fromQuality(quality);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DropRecord &&
          equipmentId == other.equipmentId &&
          realmId == other.realmId &&
          layer == other.layer &&
          timestamp == other.timestamp &&
          quality == other.quality &&
          sourceId == other.sourceId &&
          isAutoRun == other.isAutoRun;

  @override
  int get hashCode => Object.hash(equipmentId, realmId, layer, timestamp, quality, sourceId);

  @override
  String toString() =>
      'DropRecord($equipmentId [${quality.displayName}] $realmId L$layer ${timestamp.toIso8601String()})';
}

/// 保底计数器（DESIGN.md 3.3.2）
///
/// 运气积累: 每刷N只怪未掉暗金+ → 暗金掉率递增
/// 保底: 连续刷200只未掉暗金 → 第201只必掉暗金
class PityCounter {
  /// 掉落表ID
  final String dropTableId;

  /// 当前连续未掉暗金的次数
  final int count;

  /// 保底阈值
  final int threshold;

  /// 上次掉落暗金的时间戳
  final DateTime? lastUniqueDrop;

  const PityCounter({
    required this.dropTableId,
    this.count = 0,
    this.threshold = 200,
    this.lastUniqueDrop,
  });

  factory PityCounter.fromJson(Map<String, dynamic> json) => PityCounter(
        dropTableId: json['dropTableId'] as String,
        count: json['count'] as int? ?? 0,
        threshold: json['threshold'] as int? ?? 200,
        lastUniqueDrop: json['lastUniqueDrop'] != null
            ? DateTime.parse(json['lastUniqueDrop'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'dropTableId': dropTableId,
        'count': count,
        'threshold': threshold,
        'lastUniqueDrop': lastUniqueDrop?.toIso8601String(),
      };

  PityCounter copyWith({
    String? dropTableId,
    int? count,
    int? threshold,
    DateTime? lastUniqueDrop,
  }) =>
      PityCounter(
        dropTableId: dropTableId ?? this.dropTableId,
        count: count ?? this.count,
        threshold: threshold ?? this.threshold,
        lastUniqueDrop: lastUniqueDrop ?? this.lastUniqueDrop,
      );

  /// 掉了暗金+品质时重置计数器
  PityCounter reset() => PityCounter(
        dropTableId: dropTableId,
        count: 0,
        threshold: threshold,
        lastUniqueDrop: DateTime.now(),
      );

  /// 未掉暗金时递增计数器
  PityCounter increment() => copyWith(count: count + 1);

  /// 是否触发保底
  bool get isPityTriggered => count >= threshold;

  /// 距离保底还差多少次
  int get remaining => (threshold - count).clamp(0, threshold);

  /// 保底进度百分比
  double get progress => count / threshold;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PityCounter &&
          dropTableId == other.dropTableId &&
          count == other.count &&
          threshold == other.threshold;

  @override
  int get hashCode => Object.hash(dropTableId, count, threshold);

  @override
  String toString() =>
      'PityCounter($dropTableId count=$count/$threshold remaining=${remaining})';
}

// =============================================================================
// 内部辅助方法
// =============================================================================

bool _listEquals(List a, List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEqualsDouble(Map<Quality, double> a, Map<Quality, double> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || (a[key]! - b[key]!).abs() > 0.0001) return false;
  }
  return true;
}
