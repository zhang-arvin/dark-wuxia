// =============================================================================
// loot_batch.dart — 掉落批次模型（掉落爆发模块）
//
// 把一次战斗/一次宝箱的一批掉落包装成「批次」，
// 供掉落爆发 Overlay 做分级视觉呈现。
// =============================================================================

import 'enums.dart';
import '../engine/drop_engine.dart' show DropResult;

/// 掉落来源（决定爆发强度和多件逻辑）
enum LootSource {
  /// 普通战斗掉落
  battle,
  /// 精英怪掉落（多件）
  elite,
  /// 宝箱掉落（多件）
  treasure,
  /// Boss 掉落（多件 + 高品保证）
  boss,
  /// 词缀翻倍惊喜时刻
  jackpot,
}

/// 品质视觉分级：把 6 档 Quality 压成 3 级光效
enum QualityTier {
  /// 神品/传说：红光 + 屏幕震动 + 专属音效
  mythic,
  /// 暗金：橙光 + 中等触感
  legendary,
  /// 上品及以下：平光
  common;

  /// 从 Quality 映射视觉分级
  static QualityTier fromQuality(Quality q) {
    return switch (q) {
      Quality.divine || Quality.legendary => QualityTier.mythic,
      Quality.unique => QualityTier.legendary,
      _ => QualityTier.common,
    };
  }
}

/// 一批掉落（掉落爆发弹窗的数据单元）
class LootBatch {
  /// 批内装备
  final List<DropResult> items;

  /// 来源
  final LootSource source;

  /// 是否词缀翻倍惊喜
  final bool isJackpot;

  /// 批内最高视觉等级
  QualityTier get highestTier => items.fold(
        QualityTier.common,
        (t, d) => QualityTier.fromQuality(d.equipment.quality).index > t.index
            ? QualityTier.fromQuality(d.equipment.quality)
            : t,
      );

  bool get isEmpty => items.isEmpty;

  const LootBatch({
    required this.items,
    required this.source,
    this.isJackpot = false,
  });
}