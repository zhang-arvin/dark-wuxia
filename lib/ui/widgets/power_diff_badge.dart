// =============================================================================
// power_diff_badge.dart — 战力对比标签
// =============================================================================

import 'package:flutter/material.dart';

import '../theme.dart';

/// 战力对比标签（+15绿色 / -3红色）
class PowerDiffBadge extends StatelessWidget {
  final int diff;
  final double fontSize;

  const PowerDiffBadge({super.key, required this.diff, this.fontSize = 14});

  @override
  Widget build(BuildContext context) {
    if (diff == 0) return const SizedBox.shrink();

    final isPositive = diff > 0;
    final color = isPositive ? DarkWuxiaColors.buffGreen : DarkWuxiaColors.darkRedBright;
    final prefix = isPositive ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        '$prefix$diff',
        style: TextStyle(
          fontFamily: 'serif',
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

/// 属性对比行（当前值 vs 新值）
class AttributeDiffRow extends StatelessWidget {
  final String attributeName;
  final int currentValue;
  final int newValue;

  const AttributeDiffRow({
    super.key,
    required this.attributeName,
    required this.currentValue,
    required this.newValue,
  });

  @override
  Widget build(BuildContext context) {
    final diff = newValue - currentValue;
    if (diff == 0) return const SizedBox.shrink();

    final color = diff > 0 ? DarkWuxiaColors.buffGreen : DarkWuxiaColors.darkRedBright;
    final prefix = diff > 0 ? '+' : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(attributeName, style: const TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textSecondary)),
          ),
          Text('$currentValue', style: const TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textPrimary)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.arrow_forward, size: 12, color: DarkWuxiaColors.textHint),
          ),
          Text('$newValue', style: TextStyle(fontFamily: 'serif', fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 4),
          Text(
            '($prefix$diff)',
            style: TextStyle(fontFamily: 'serif', fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }
}
