// =============================================================================
// odds_page.dart — 概率公示
//
// 对应 DESIGN.md 3.10.4 概率公示 + App Store 审核
//   - 各品质掉率(凡55%/良28%/上12%/暗金3%/神品0.5%/传说0.1%)
//   - 保底机制说明
//   - 福缘影响说明
// =============================================================================

import 'package:flutter/material.dart';

import '../theme.dart';
import '../router.dart';
import '../widgets/quality_chip.dart';
import '../../models/enums.dart';
import '../../utils/app_logger.dart';

class OddsPage extends StatelessWidget {
  const OddsPage({super.key});

  /// 各品质掉率
  static const Map<Quality, double> _dropRates = {
    Quality.normal: 55.0,
    Quality.magic: 28.0,
    Quality.rare: 12.0,
    Quality.unique: 3.0,
    Quality.divine: 0.5,
    Quality.legendary: 0.1,
  };

  @override
  Widget build(BuildContext context) {
    try {
    return DarkWuxiaScaffold(
      title: '概率公示',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildIntroCard(),
            const SizedBox(height: 12),
            _buildDropRateCard(),
            const SizedBox(height: 12),
            _buildPityCard(),
            const SizedBox(height: 12),
            _buildFortuneCard(),
            const SizedBox(height: 12),
            _buildDisclaimerCard(),
          ],
        ),
      ),
    );
    } catch (e, stack) {
      AppLogger.instance.error('OddsPage.build 崩溃: $e\n$stack');
      return const DarkWuxiaScaffold(
        title: '概率公示',
        body: DarkWuxiaEmpty(text: '页面加载出错，请查看日志', icon: Icons.error_outline),
      );
    }
  }

  /// 引言
  Widget _buildIntroCard() {
    return DarkWuxiaCard(
      borderColor: DarkWuxiaColors.darkGold,
      borderWidth: 1,
      child: Column(
        children: [
          const Icon(Icons.info_outline, size: 32, color: DarkWuxiaColors.darkGold),
          const SizedBox(height: 8),
          const Text(
            '掉落概率公示',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: DarkWuxiaColors.darkGold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '本页面公示所有装备掉落的概率参数，\n确保随机抽取机制公开透明。',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textSecondary, height: 1.6),
          ),
        ],
      ),
    );
  }

  /// 各品质掉率
  Widget _buildDropRateCard() {
    return DarkWuxiaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DarkWuxiaSectionTitle(text: '品质掉率', icon: Icons.percent),
          const SizedBox(height: 8),
          const Text(
            '每次击败敌人或完成秘境后，掉落装备的品质按以下概率分布：',
            style: TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 12),

          // 掉率柱状图
          ..._dropRates.entries.map((entry) {
            final quality = entry.key;
            final rate = entry.value;
            return _buildRateBar(quality, rate);
          }),

          const SizedBox(height: 8),
          const Divider(color: DarkWuxiaColors.divider),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('合计', style: TextStyle(fontFamily: 'serif', fontSize: 14, fontWeight: FontWeight.bold, color: DarkWuxiaColors.darkGold)),
              Text(
                '${_dropRates.values.fold(0.0, (a, b) => a + b)}%',
                style: const TextStyle(fontFamily: 'serif', fontSize: 14, fontWeight: FontWeight.bold, color: DarkWuxiaColors.darkGold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRateBar(Quality quality, double rate) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: QualityChip(quality: quality, compact: true),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                // 背景
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: DarkWuxiaColors.elevated,
                    border: Border.all(color: DarkWuxiaColors.divider, width: 0.5),
                  ),
                ),
                // 概率条
                FractionallySizedBox(
                  widthFactor: (rate / 100).clamp(0.001, 1.0),
                  child: Container(
                    height: 16,
                    color: quality.color.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              '$rate%',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: quality.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 保底机制说明
  Widget _buildPityCard() {
    return DarkWuxiaCard(
      borderColor: DarkWuxiaColors.buffGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield, color: DarkWuxiaColors.buffGreen, size: 20),
              SizedBox(width: 6),
              Text(
                '保底机制',
                style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: DarkWuxiaColors.buffGreen),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildPityRow('上品保底', '每 10 次掉落未出上品及以上，第 11 次必出上品或更高。', Quality.rare),
          _buildPityRow('暗金保底', '每 30 次掉落未出暗金及以上，第 31 次必出暗金或更高。', Quality.unique),
          _buildPityRow('神品保底', '每 100 次掉落未出神品及以上，第 101 次必出神品或更高。', Quality.divine),
          _buildPityRow('传说保底', '每 300 次掉落未出传说，第 301 次必出传说。', Quality.legendary),
          const SizedBox(height: 8),
          const Text(
            '※ 保底计数独立于秘境和难度，跨秘境累计。\n※ 触发保底时，掉落闪光会显示「⚡ 保底触发」标记。',
            style: TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPityRow(String title, String desc, Quality quality) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: quality.color.withValues(alpha: 0.15),
              border: Border.all(color: quality.color, width: 0.5),
            ),
            child: Text(
              title,
              style: TextStyle(fontFamily: 'serif', fontSize: 11, fontWeight: FontWeight.bold, color: quality.color),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textPrimary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  /// 福缘影响说明
  Widget _buildFortuneCard() {
    return DarkWuxiaCard(
      borderColor: DarkWuxiaColors.darkGoldBright,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: DarkWuxiaColors.darkGoldBright, size: 20),
              SizedBox(width: 6),
              Text(
                '福缘影响',
                style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: DarkWuxiaColors.darkGoldBright),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '角色的「福缘」属性会提升高品质装备的掉落概率：',
            style: TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textSecondary),
          ),
          const SizedBox(height: 8),
          _buildFortuneRow('福缘 5（初始）', '掉率不变'),
          _buildFortuneRow('福缘 10', '上品 +2%，暗金 +0.5%'),
          _buildFortuneRow('福缘 20', '上品 +5%，暗金 +1.5%，神品 +0.1%'),
          _buildFortuneRow('福缘 30', '上品 +8%，暗金 +3%，神品 +0.3%'),
          const SizedBox(height: 8),
          const Text(
            '※ 福缘提升来自装备词缀、经脉种子、心法加成。\n※ 福缘不会降低凡品掉率，而是将部分良品概率转移到更高品质。',
            style: TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFortuneRow(String label, String effect) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.darkGold)),
          ),
          Expanded(
            child: Text(effect, style: const TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  /// 声明
  Widget _buildDisclaimerCard() {
    return DarkWuxiaCard(
      padding: const EdgeInsets.all(12),
      borderColor: DarkWuxiaColors.divider,
      child: Column(
        children: [
          const Icon(Icons.gavel, size: 20, color: DarkWuxiaColors.textSecondary),
          const SizedBox(height: 8),
          const Text(
            '本游戏所有随机抽取概率均在此页面公示，\n不存在未公示的概率参数。\n所有抽取均使用加密随机数生成器，\n确保每次抽取独立且公平。',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.textSecondary, height: 1.6),
          ),
        ],
      ),
    );
  }
}
