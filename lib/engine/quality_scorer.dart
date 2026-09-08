// =============================================================================
// quality_scorer.dart — 装备品质评分器
//
// 目的：
//   1. 给"品质"一个数值分，装备卡片/详情可展示
//   2. 掉落校验：神品必须达到神品最低分，否则补强（词缀兜底）
//
// 设计：
//   品质仍由掉落表概率决定稀有度（保持掉率不变），
//   但品质会约束词缀生成的最低标准 —— 神品必然有神品的词缀姿态。
// =============================================================================

import '../models/enums.dart';
import '../models/equipment.dart';

/// 装备品质评分器
class QualityScorer {
  QualityScorer._();

  /// 各品质的最低分数要求
  static const Map<Quality, int> _minScores = {
    Quality.normal: 0,
    Quality.magic: 25,
    Quality.rare: 50,
    Quality.unique: 80,
    Quality.divine: 120,
    Quality.legendary: 180,
  };

  /// 计算装备分数
  ///
  /// 维度：
  /// - 词缀数量：每词缀 +15 分
  /// - 词缀数值：rolledValues 总和 × 0.5
  /// - 物品等级：itemLevel × 0.5
  /// - 基础伤害/防御：baseDamage / 5
  static int score({
    required List<Affix> affixes,
    required int itemLevel,
    int baseDamage = 0,
  }) {
    var total = 0.0;

    total += affixes.length * 15.0;

    for (final affix in affixes) {
      final valueSum = affix.rolledValues.values.fold<int>(0, (s, v) => s + v);
      total += valueSum * 0.5;
    }

    total += itemLevel * 0.5;
    total += baseDamage / 5.0;

    return total.round();
  }

  /// 分数 → 品质
  static Quality qualityForScore(int score) {
    // 从高到低匹配
    const sorted = [Quality.legendary, Quality.divine, Quality.unique, Quality.rare, Quality.magic, Quality.normal];
    for (final q in sorted) {
      if (score >= _minScores[q]!) return q;
    }
    return Quality.normal;
  }

  /// 品质的最低分数要求
  static int minScoreFor(Quality quality) => _minScores[quality] ?? 0;

  /// 校验：装备分数是否达到品质最低要求
  static bool meetsMinimumQuality({
    required Quality quality,
    required List<Affix> affixes,
    required int itemLevel,
    int baseDamage = 0,
  }) {
    final s = score(affixes: affixes, itemLevel: itemLevel, baseDamage: baseDamage);
    return s >= minScoreFor(quality);
  }

  /// 校准样例：
  /// - 凡品(1词缀 lv15 roll12): 15 + 6 + 7.5 = ~28
  /// - 良品(2词缀 lv20 roll合计30): 30 + 15 + 10 = 55
  /// - 上品(3词缀 lv30 合计45): 45 + 22.5 + 15 = ~82（顶配上品摸到暗金线）
  /// - 神品(5词缀 lv60 合计90): 75 + 45 + 30 = 150
  /// - 传说(6词缀 lv80 合计140): 90 + 70 + 40 = 200
}