// =============================================================================
// quality_chip.dart — 品质标签
// =============================================================================

import 'package:flutter/material.dart';

import '../theme.dart';
import '../../models/enums.dart';

/// 品质标签 — 显示品质名称和颜色标记
class QualityChip extends StatelessWidget {
  final Quality quality;
  final bool compact;
  final double fontSize;

  const QualityChip({super.key, required this.quality, this.compact = false, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    final color = quality.color;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: compact ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (quality.stars > 0 && !compact) ...[
            Text(
              '★' * quality.stars,
              style: TextStyle(fontSize: fontSize - 1, color: color),
            ),
            const SizedBox(width: 2),
          ],
          Text(
            quality.displayName,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: fontSize,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
