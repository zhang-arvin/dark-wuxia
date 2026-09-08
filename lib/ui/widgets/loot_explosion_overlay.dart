// =============================================================================
// loot_explosion_overlay.dart — 掉落爆发弹窗（多件批次 · 品质分级视觉）
//
// 模块 1「掉落爆发」：
//   - 多件掉落逐张交错入场（0.15s stagger）
//   - 神品/传说：红光 + 屏幕触感震动（heavyImpact）
//   - 暗金：橙光 + mediumImpact
//   - 词缀翻倍惊喜：顶部横幅提示
//   - 点击任意处关闭
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../../models/loot_batch.dart';
import '../../engine/drop_engine.dart' show DropResult;
import 'quality_chip.dart';

/// 掉落爆发全屏弹窗
///
/// 用法：
/// ```dart
/// await LootExplosionOverlay.show(context, LootBatch(items: drops, source: LootSource.battle));
/// ```
class LootExplosionOverlay extends StatefulWidget {
  final LootBatch batch;
  final VoidCallback? onDismiss;

  const LootExplosionOverlay({super.key, required this.batch, this.onDismiss});

  /// 弹窗入口：全屏渐进遮罩 + 触感反馈
  static Future<void> show(BuildContext context, LootBatch batch,
      {VoidCallback? onDismiss}) {
    if (batch.isEmpty) return Future.value();
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'loot_explosion',
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (context, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
      pageBuilder: (_, __, ___) =>
          LootExplosionOverlay(batch: batch, onDismiss: onDismiss),
    );
  }

  @override
  State<LootExplosionOverlay> createState() => _LootExplosionOverlayState();
}

class _LootExplosionOverlayState extends State<LootExplosionOverlay> {
  @override
  void initState() {
    super.initState();
    // 按批内最高品质触发触感反馈
    switch (widget.batch.highestTier) {
      case QualityTier.mythic:
        HapticFeedback.heavyImpact();
      case QualityTier.legendary:
        HapticFeedback.mediumImpact();
      case QualityTier.common:
        break;
    }
  }

  void _dismiss() {
    widget.onDismiss?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final batch = widget.batch;
    final header = _headerOf(batch);

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _dismiss,
        child: Container(
          color: Colors.transparent,
          alignment: Alignment.center,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题区
                if (batch.isJackpot)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: DarkWuxiaColors.darkRed.withValues(alpha: 0.25),
                      border: Border.all(
                          color: DarkWuxiaColors.darkRedBright, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('⚡ 词缀翻倍！天降奇遇 ⚡',
                        style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: DarkWuxiaColors.darkRedBright,
                            letterSpacing: 1.5)),
                  ),
                Text(header.$1,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: header.$2,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(
                          color: header.$2.withValues(alpha: 0.7),
                          blurRadius: 18,
                        ),
                      ],
                    )),
                const SizedBox(height: 4),
                Text('点击任意处收起',
                    style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.4))),
                const SizedBox(height: 18),
                // 装备卡片（交错入场）
                ...List.generate(batch.items.length, (i) {
                  return _StaggeredCard(
                    index: i,
                    drop: batch.items[i],
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (String title, Color color) _headerOf(LootBatch batch) {
    return switch (batch.highestTier) {
      QualityTier.mythic => ('★ 神物出世 ★', DarkWuxiaColors.darkRedBright),
      QualityTier.legendary => ('◆ 暗金现世 ◆', DarkWuxiaColors.darkGoldBright),
      QualityTier.common => (
          '— 战利品 —',
          batch.source == LootSource.elite || batch.source == LootSource.treasure
              ? DarkWuxiaColors.textSecondary
              : DarkWuxiaColors.textPrimary
        ),
    };
  }
}

/// 单张装备卡片（带交错入场动画）
class _StaggeredCard extends StatefulWidget {
  final int index;
  final DropResult drop;
  const _StaggeredCard({required this.index, required this.drop});

  @override
  State<_StaggeredCard> createState() => _StaggeredCardState();
}

class _StaggeredCardState extends State<_StaggeredCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );
    _scale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    // 交错入场：每张比前一张晚 150ms
    Future.delayed(Duration(milliseconds: widget.index * 150), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drop = widget.drop;
    final quality = drop.equipment.quality;
    final tier = QualityTier.fromQuality(quality);
    final borderColor = switch (tier) {
      QualityTier.mythic => DarkWuxiaColors.darkRedBright,
      QualityTier.legendary => DarkWuxiaColors.darkGoldBright,
      QualityTier.common => quality.color,
    };
    final glowColor = borderColor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value,
          child: Transform.scale(
            scale: _scale.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: quality.dimColor.withValues(alpha: 0.9),
                border: Border.all(
                    color: borderColor,
                    width: tier == QualityTier.common ? 1.2 : 2),
                borderRadius: BorderRadius.circular(6),
                boxShadow: tier == QualityTier.common
                    ? null
                    : [
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.45),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ],
              ),
              child: child,
            ),
          ),
        );
      },
      child: Row(
        children: [
          QualityChip(quality: quality, fontSize: 12),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drop.equipment.name,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: quality.color,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                if (drop.isJackpot)
                  Text('词缀翻倍 ×2',
                      style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 11,
                          color: DarkWuxiaColors.darkRedBright)),
                if (drop.isPityTriggered)
                  const Text('⚡ 保底触发',
                      style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 11,
                          color: DarkWuxiaColors.darkGold)),
                if (drop.equipment.affixes.isNotEmpty)
                  Text(
                    drop.equipment.affixes
                        .map((a) => '${a.name}${a.rolledValues.values.firstOrNull ?? ''}')
                        .take(3)
                        .join(' · '),
                    style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 11,
                        color: DarkWuxiaColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}