// =============================================================================
// status_effect_badge.dart — 状态效果图标
// =============================================================================

import 'package:flutter/material.dart';

import '../theme.dart';
import '../../engine/battle_engine.dart';

/// 单个状态效果图标
class StatusEffectBadge extends StatelessWidget {
  final StatusEffect effect;

  const StatusEffectBadge({super.key, required this.effect});

  @override
  Widget build(BuildContext context) {
    final isBuff = _isBuff(effect.type);
    final color = isBuff ? DarkWuxiaColors.buffGreen : DarkWuxiaColors.debuffRed;

    return Tooltip(
      message: '${_effectName(effect.type)} ${effect.stacks}层 (剩余${effect.remainingTurns}回合)',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color, width: 0.5),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_effectIcon(effect.type), size: 12, color: color),
            const SizedBox(width: 2),
            if (effect.stacks > 1)
              Text(
                '${effect.stacks}',
                style: TextStyle(fontFamily: 'serif', fontSize: 10, color: color, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  bool _isBuff(StatusEffectType type) {
    switch (type) {
      case StatusEffectType.attackUp:
      case StatusEffectType.defenseUp:
      case StatusEffectType.lifesteal:
      case StatusEffectType.enrage:
      case StatusEffectType.shield:
      case StatusEffectType.qiAccumulation:
      case StatusEffectType.comboEscalation:
      case StatusEffectType.regeneration:
        return true;
      case StatusEffectType.attackDown:
      case StatusEffectType.defenseDown:
      case StatusEffectType.poison:
      case StatusEffectType.chill:
      case StatusEffectType.reflect:
      case StatusEffectType.dodgeDown:
        return false;
    }
  }

  String _effectName(StatusEffectType type) {
    switch (type) {
      case StatusEffectType.attackUp: return '攻击+';
      case StatusEffectType.defenseUp: return '防御+';
      case StatusEffectType.attackDown: return '攻击-';
      case StatusEffectType.defenseDown: return '防御-';
      case StatusEffectType.poison: return '中毒';
      case StatusEffectType.chill: return '冰寒';
      case StatusEffectType.lifesteal: return '嗜血';
      case StatusEffectType.enrage: return '狂暴';
      case StatusEffectType.shield: return '护体罡气';
      case StatusEffectType.qiAccumulation: return '蓄力';
      case StatusEffectType.comboEscalation: return '连击';
      case StatusEffectType.regeneration: return '回血';
      case StatusEffectType.reflect: return '反伤';
      case StatusEffectType.dodgeDown: return '身法受制';
    }
  }

  IconData _effectIcon(StatusEffectType type) {
    switch (type) {
      case StatusEffectType.attackUp: return Icons.arrow_upward;
      case StatusEffectType.defenseUp: return Icons.shield;
      case StatusEffectType.attackDown: return Icons.arrow_downward;
      case StatusEffectType.defenseDown: return Icons.shield_moon;
      case StatusEffectType.poison: return Icons.bug_report;
      case StatusEffectType.chill: return Icons.ac_unit;
      case StatusEffectType.lifesteal: return Icons.bloodtype;
      case StatusEffectType.enrage: return Icons.whatshot;
      case StatusEffectType.shield: return Icons.security;
      case StatusEffectType.qiAccumulation: return Icons.battery_charging_full;
      case StatusEffectType.comboEscalation: return Icons.repeat;
      case StatusEffectType.regeneration: return Icons.favorite;
      case StatusEffectType.reflect: return Icons.refresh;
      case StatusEffectType.dodgeDown: return Icons.directions_off;
    }
  }
}

/// 状态效果区域（多个状态效果并排展示）
class StatusEffectArea extends StatelessWidget {
  final List<StatusEffect> effects;
  final bool isPlayer;

  const StatusEffectArea({super.key, required this.effects, required this.isPlayer});

  @override
  Widget build(BuildContext context) {
    if (effects.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        spacing: 4,
        runSpacing: 2,
        children: effects.map((e) => StatusEffectBadge(effect: e)).toList(),
      ),
    );
  }
}
