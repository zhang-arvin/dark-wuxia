// =============================================================================
// equipment_card.dart — 装备卡片
// =============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';

import '../theme.dart';
import '../../database/database.dart';
import '../../models/enums.dart';
import '../../models/equipment.dart';
import 'quality_chip.dart';
import 'power_diff_badge.dart';

/// 装备卡片
class EquipmentCard extends StatelessWidget {
  final EquipmentTableData equipment;
  final bool selected;
  final VoidCallback? onTap;
  final int? powerDiff;

  const EquipmentCard({
    super.key,
    required this.equipment,
    this.selected = false,
    this.onTap,
    this.powerDiff,
  });

  @override
  Widget build(BuildContext context) {
    final quality = Quality.fromJson(equipment.quality);
    final qualityColor = quality.color;
    final slot = _parseSlot(equipment.slot);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: quality.dimColor,
          border: Border.all(
            color: selected ? DarkWuxiaColors.darkGold : DarkWuxiaColors.divider,
            width: selected ? 1.5 : 0.5,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一行：槽位图标 + 装备名 + 强化等级
            Row(
              children: [
                Icon(_slotIcon(slot), size: 16, color: slot.iconColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    equipment.name,
                    style: TextStyle(
                      fontFamily: 'serif', fontSize: 14, fontWeight: FontWeight.bold, color: qualityColor,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (equipment.reinforceLevel > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: DarkWuxiaColors.darkGold.withValues(alpha: 0.2),
                      border: Border.all(color: DarkWuxiaColors.darkGold, width: 0.5),
                    ),
                    child: Text('+${equipment.reinforceLevel}',
                      style: const TextStyle(fontFamily: 'serif', fontSize: 10, color: DarkWuxiaColors.darkGold, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // 第二行：品质标签 + 物品等级 + 战力diff
            Row(
              children: [
                QualityChip(quality: quality, compact: true),
                const SizedBox(width: 8),
                Text('Lv.${equipment.itemLevel}',
                  style: const TextStyle(fontFamily: 'serif', fontSize: 10, color: DarkWuxiaColors.textHint)),
                const Spacer(),
                if (powerDiff != null) PowerDiffBadge(diff: powerDiff!, fontSize: 12),
              ],
            ),
            // 词缀列表
            ..._parseAffixes(equipment.affixesJson).take(3).map((affix) => Padding(
              padding: const EdgeInsets.only(bottom: 1, top: 2),
              child: Text('· ${affix.name}',
                style: const TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.textSecondary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            )),
          ],
        ),
      ),
    );
  }

  EquipmentSlot _parseSlot(String slot) {
    switch (slot) {
      case 'weapon': return EquipmentSlot.weapon;
      case 'armor': return EquipmentSlot.armor;
      case 'accessory': return EquipmentSlot.accessory;
      case 'treasure': return EquipmentSlot.treasure;
      default: return EquipmentSlot.weapon;
    }
  }

  IconData _slotIcon(EquipmentSlot slot) {
    switch (slot) {
      case EquipmentSlot.weapon: return Icons.gavel;
      case EquipmentSlot.armor: return Icons.shield;
      case EquipmentSlot.accessory: return Icons.diamond;
      case EquipmentSlot.treasure: return Icons.auto_awesome;
      case EquipmentSlot.boots: return Icons.hiking;
      case EquipmentSlot.offhand: return Icons.shield_outlined;
    }
  }

  List<Affix> _parseAffixes(String json) {
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) {
        final map = e as Map<String, dynamic>;
        return Affix(
          id: map['id'] ?? '',
          name: map['name'] ?? '',
          position: AffixPosition.fromJson(map['position'] ?? map['type'] ?? 'prefix'),
          effects: Map<String, int>.from(map['effects'] ?? {}),
          rolledValues: Map<String, int>.from(map['rolledValues'] ?? {}),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}

/// 装备详情弹窗
class EquipmentDetailDialog extends StatelessWidget {
  final EquipmentTableData equipment;
  final bool isEquipped;
  final int? currentPower;
  final int? newPower;
  final VoidCallback? onSell;
  final VoidCallback? onReinforce;
  final VoidCallback? onEquip;
  final VoidCallback? onUnequip;
  final VoidCallback? onRefine;

  const EquipmentDetailDialog({
    super.key,
    required this.equipment,
    this.isEquipped = false,
    this.currentPower,
    this.newPower,
    this.onSell,
    this.onReinforce,
    this.onEquip,
    this.onUnequip,
    this.onRefine,
  });

  @override
  Widget build(BuildContext context) {
    final quality = Quality.fromJson(equipment.quality);
    final qualityColor = quality.color;
    final powerDiff = (currentPower != null && newPower != null) ? newPower! - currentPower! : null;
    final affixes = _parseAffixes(equipment.affixesJson);

    return Dialog(
      backgroundColor: DarkWuxiaColors.elevated,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  QualityChip(quality: quality, fontSize: 14),
                  const Spacer(),
                  if (equipment.reinforceLevel > 0)
                    Text('强化 +${equipment.reinforceLevel}',
                      style: const TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.darkGold)),
                ],
              ),
              const SizedBox(height: 8),
              Text(equipment.name,
                style: TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.bold, color: qualityColor, letterSpacing: 1)),
              Text('物品等级 ${equipment.itemLevel} · ${equipment.slot}',
                style: const TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textSecondary)),
              const SizedBox(height: 12),
              const DarkWuxiaDivider(),
              if (affixes.isNotEmpty) ...[
                const SizedBox(height: 8),
                const DarkWuxiaSectionTitle(text: '词缀', icon: Icons.list),
                const SizedBox(height: 4),
                ...affixes.map((affix) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        affix.position == AffixPosition.prefix ? Icons.arrow_forward : Icons.arrow_back,
                        size: 12, color: DarkWuxiaColors.textHint),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(affix.name,
                              style: TextStyle(fontFamily: 'serif', fontSize: 13, color: qualityColor.withValues(alpha: 0.8))),
                            ...affix.rolledValues.entries.map((e) => Text(
                              '${_statLabel(e.key)} +${e.value}',
                              style: const TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.textSecondary),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ],
              if (powerDiff != null) ...[
                const SizedBox(height: 12),
                const DarkWuxiaDivider(),
                const SizedBox(height: 8),
                const DarkWuxiaSectionTitle(text: '战力对比', icon: Icons.compare_arrows),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        const Text('当前', style: TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.textSecondary)),
                        Text('$currentPower',
                          style: const TextStyle(fontFamily: 'serif', fontSize: 24, fontWeight: FontWeight.bold, color: DarkWuxiaColors.textPrimary)),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(Icons.arrow_forward, color: DarkWuxiaColors.darkGold),
                    ),
                    Column(
                      children: [
                        const Text('装备后', style: TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.textSecondary)),
                        Text('$newPower',
                          style: TextStyle(fontFamily: 'serif', fontSize: 24, fontWeight: FontWeight.bold,
                            color: powerDiff >= 0 ? DarkWuxiaColors.buffGreen : DarkWuxiaColors.darkRedBright)),
                      ],
                    ),
                    const SizedBox(width: 12),
                    PowerDiffBadge(diff: powerDiff, fontSize: 16),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (onEquip != null)
                    ElevatedButton.icon(
                      onPressed: () { Navigator.pop(context); onEquip!(); },
                      icon: const Icon(Icons.checkroom, size: 18),
                      label: const Text('装备'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DarkWuxiaColors.darkGold.withValues(alpha: 0.2),
                        foregroundColor: DarkWuxiaColors.darkGold,
                      ),
                    ),
                  if (onUnequip != null)
                    OutlinedButton.icon(
                      onPressed: () { Navigator.pop(context); onUnequip!(); },
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      label: const Text('卸下'),
                    ),
                  if (onReinforce != null)
                    OutlinedButton.icon(
                      onPressed: () { Navigator.pop(context); onReinforce!(); },
                      icon: const Icon(Icons.construction, size: 18),
                      label: const Text('熔炼'),
                    ),
                  if (onSell != null)
                    OutlinedButton.icon(
                      onPressed: () { Navigator.pop(context); onSell!(); },
                      icon: const Icon(Icons.monetization_on, size: 18),
                      label: const Text('出售'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statLabel(String key) {
    const labels = {
      'body': '臂力', 'agi': '身法', 'wis': '悟性', 'con': '根骨', 'luck': '福缘',
      'externalDamagePct': '外功伤害%', 'internalDamagePct': '内功伤害%',
      'maxHp': '生命上限', 'maxIe': '内力上限', 'critPct': '暴击率%',
      'dodgePct': '闪避率%', 'defensePct': '防御%', 'fortunePct': '福缘%',
    };
    return labels[key] ?? key;
  }

  List<Affix> _parseAffixes(String json) {
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) {
        final map = e as Map<String, dynamic>;
        return Affix(
          id: map['id'] ?? '',
          name: map['name'] ?? '',
          position: AffixPosition.fromJson(map['position'] ?? map['type'] ?? 'prefix'),
          effects: Map<String, int>.from(map['effects'] ?? {}),
          rolledValues: Map<String, int>.from(map['rolledValues'] ?? {}),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
