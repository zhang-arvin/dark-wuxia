// =============================================================================
// health_bar.dart — 生命/内力条
// =============================================================================

import 'package:flutter/material.dart';

import '../theme.dart';

/// 生命/内力条
class HealthBar extends StatelessWidget {
  final int current;
  final int max;
  final String label;
  final Color color;
  final bool showValue;
  final bool showPercentage;

  const HealthBar({
    super.key,
    required this.current,
    required this.max,
    this.label = '',
    this.color = DarkWuxiaColors.darkRedBright,
    this.showValue = true,
    this.showPercentage = false,
  });

  /// 生命条
  factory HealthBar.hp({required int current, required int max, bool showValue = true, bool showPercentage = false}) {
    return HealthBar(
      current: current,
      max: max,
      label: '生命',
      color: DarkWuxiaColors.darkRedBright,
      showValue: showValue,
      showPercentage: showPercentage,
    );
  }

  /// 内力条
  factory HealthBar.innerEnergy({required int current, required int max, bool showValue = true}) {
    return HealthBar(
      current: current,
      max: max,
      label: '内力',
      color: DarkWuxiaColors.innerEnergy,
      showValue: showValue,
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeMax = max > 0 ? max : 1;
    final percent = (current / safeMax).clamp(0.0, 1.0);

    return Row(
      children: [
        if (label.isNotEmpty) ...[
          SizedBox(
            width: 28,
            child: Text(
              label,
              style: const TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.textSecondary),
            ),
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Stack(
            children: [
              // 背景条
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: DarkWuxiaColors.elevated,
                  border: Border.all(color: DarkWuxiaColors.divider, width: 0.5),
                ),
              ),
              // 填充条
              FractionallySizedBox(
                widthFactor: percent,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.6), color],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        if (showValue)
          Text(
            '$current/$max',
            style: TextStyle(
              fontFamily: 'serif', fontSize: 11, color: color, fontWeight: FontWeight.bold,
            ),
          )
        else if (showPercentage)
          Text(
            '${(percent * 100).round()}%',
            style: TextStyle(
              fontFamily: 'serif', fontSize: 11, color: color, fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}
