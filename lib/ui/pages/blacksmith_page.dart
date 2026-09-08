// =============================================================================
// blacksmith_page.dart — 炼器（合成/强化）
//
// 对应 DESIGN.md 3.3.5 合成 + 强化
//   - 强化: 选装备+材料→强化等级+1(+10%属性)
//   - 合成: 低品质→高品质(3白→1蓝, 3蓝→1黄...)
//   - 材料消耗展示
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';
import '../router.dart';
import '../widgets/equipment_card.dart';
import '../widgets/quality_chip.dart';
import '../../database/database.dart';
import '../../models/enums.dart';
import '../../models/equipment.dart';
import '../../utils/app_logger.dart';

class BlacksmithPage extends ConsumerStatefulWidget {
  const BlacksmithPage({super.key});

  @override
  ConsumerState<BlacksmithPage> createState() => _BlacksmithPageState();
}

class _BlacksmithPageState extends ConsumerState<BlacksmithPage> {
  int _selectedTab = 0; // 0=强化, 1=合成
  List<EquipmentTableData> _equipment = [];
  String? _selectedEquipmentId;
  EquipmentTableData? _selectedEquipment;
  int _silver = 0;

  // 合成选中
  Quality? _synthQuality;
  List<EquipmentTableData> _synthSelected = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final db = AppDatabase.instance;
      final char = await db.characterDao.getCharacter();
      _silver = char?.silver ?? 0;
      _equipment = await db.equipmentDao.getAll();

      if (_selectedEquipmentId != null) {
        _selectedEquipment = _equipment.firstWhere(
          (e) => e.id == _selectedEquipmentId,
          orElse: () => _equipment.first,
        );
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    try {
    return DarkWuxiaScaffold(
      title: '炼器坊',
      actions: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: DarkWuxiaColors.darkGold, size: 18),
                const SizedBox(width: 4),
                Text(
                  '$_silver',
                  style: const TextStyle(fontFamily: 'serif', fontSize: 14, color: DarkWuxiaColors.darkGold, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
      body: Column(
        children: [
          // Tab 切换
          Container(
            color: DarkWuxiaColors.elevated,
            child: Row(
              children: [
                Expanded(
                  child: _buildTab('强化', 0, Icons.arrow_upward, DarkWuxiaColors.darkGold),
                ),
                Expanded(
                  child: _buildTab('合成', 1, Icons.merge, DarkWuxiaColors.darkRedBright),
                ),
              ],
            ),
          ),

          // 内容区
          Expanded(
            child: _loading
                ? const DarkWuxiaLoading()
                : _selectedTab == 0
                    ? _buildReinforceView()
                    : _buildSynthView(),
          ),
        ],
      ),
    );
    } catch (e, stack) {
      AppLogger.instance.error('BlacksmithPage.build 崩溃: $e\n$stack');
      return const DarkWuxiaScaffold(
        title: '炼器坊',
        body: DarkWuxiaEmpty(text: '页面加载出错，请查看日志', icon: Icons.error_outline),
      );
    }
  }

  Widget _buildTab(String label, int index, IconData icon, Color color) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? color : DarkWuxiaColors.divider,
              width: isSelected ? 2 : 0.5,
            ),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: isSelected ? color : DarkWuxiaColors.textSecondary),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : DarkWuxiaColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== 强化视图 =====================

  Widget _buildReinforceView() {
    return Column(
      children: [
        // 选中的装备
        if (_selectedEquipment != null)
          Container(
            padding: const EdgeInsets.all(12),
            color: DarkWuxiaColors.surface,
            child: _buildSelectedEquipmentCard(_selectedEquipment!),
          )
        else
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.touch_app, size: 48, color: DarkWuxiaColors.textHint),
                const SizedBox(height: 8),
                const Text('请选择要强化的装备', style: TextStyle(fontFamily: 'serif', fontSize: 14, color: DarkWuxiaColors.textSecondary)),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // 强化材料消耗
        if (_selectedEquipment != null)
          _buildReinforceCost(_selectedEquipment!),

        // 强化按钮
        if (_selectedEquipment != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            child: ElevatedButton.icon(
              onPressed: _canReinforce() ? _doReinforce : null,
              icon: const Icon(Icons.arrow_upward),
              label: Text('强化 +${_selectedEquipment!.reinforceLevel} → +${_selectedEquipment!.reinforceLevel + 1}'),
              style: ElevatedButton.styleFrom(backgroundColor: DarkWuxiaColors.darkGold),
            ),
          ),

        // 装备列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _equipment.length,
            itemBuilder: (context, index) {
              final eq = _equipment[index];
              final isSelected = eq.id == _selectedEquipmentId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedEquipmentId = eq.id;
                    _selectedEquipment = eq;
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? DarkWuxiaColors.darkGold.withValues(alpha: 0.1) : DarkWuxiaColors.elevated,
                      border: Border.all(
                        color: isSelected ? DarkWuxiaColors.darkGold : DarkWuxiaColors.divider,
                        width: isSelected ? 1 : 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(_slotIcon(eq.baseId), size: 20, color: Quality.fromJson(eq.quality).color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                eq.name,
                                style: TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Quality.fromJson(eq.quality).color,
                                ),
                              ),
                              Text(
                                '强化+${eq.reinforceLevel} · Lv.${eq.itemLevel}',
                                style: const TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        QualityChip(quality: Quality.fromJson(eq.quality), compact: true),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedEquipmentCard(EquipmentTableData eq) {
    final quality = Quality.fromJson(eq.quality);
    return Row(
      children: [
        Icon(_slotIcon(eq.baseId), size: 32, color: quality.color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eq.name,
                style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: quality.color),
              ),
              Text(
                '当前强化 +${eq.reinforceLevel}',
                style: const TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textSecondary),
              ),
            ],
          ),
        ),
        Column(
          children: [
            QualityChip(quality: quality, compact: true),
          ],
        ),
      ],
    );
  }

  Widget _buildReinforceCost(EquipmentTableData eq) {
    final nextLevel = eq.reinforceLevel + 1;
    final silverCost = nextLevel * 50;
    final materialName = _reinforceMaterial(nextLevel);
    final materialCount = nextLevel; // 简化

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: DarkWuxiaColors.elevated,
        border: Border.all(color: DarkWuxiaColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DarkWuxiaSectionTitle(text: '消耗', icon: Icons.local_fire_department),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.monetization_on, color: DarkWuxiaColors.darkGold, size: 16),
              const SizedBox(width: 4),
              Text('银两 $silverCost', style: const TextStyle(fontFamily: 'serif', fontSize: 13, color: DarkWuxiaColors.darkGold)),
              const SizedBox(width: 16),
              const Icon(Icons.gavel, color: DarkWuxiaColors.darkRedBright, size: 16),
              const SizedBox(width: 4),
              Text('$materialName x$materialCount', style: const TextStyle(fontFamily: 'serif', fontSize: 13, color: DarkWuxiaColors.darkRedBright)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('强化成功: 属性 +10%', style: TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.buffGreen)),
        ],
      ),
    );
  }

  String _reinforceMaterial(int level) {
    if (level >= 10) return '玄铁';
    if (level >= 5) return '精钢';
    return '铁锭';
  }

  bool _canReinforce() {
    if (_selectedEquipment == null) return false;
    final nextLevel = _selectedEquipment!.reinforceLevel + 1;
    final silverCost = nextLevel * 50;
    return _silver >= silverCost && _selectedEquipment!.reinforceLevel < 15;
  }

  Future<void> _doReinforce() async {
    try {
      final db = AppDatabase.instance;
      final eq = _selectedEquipment!;
      final nextLevel = eq.reinforceLevel + 1;
      final silverCost = nextLevel * 50;

      await db.equipmentDao.updateReinforceLevel(eq.id, nextLevel);
      await db.characterDao.addSilver(-silverCost);

      _showSuccess('强化成功！+${eq.reinforceLevel} → +$nextLevel');
      _loadData();
    } catch (e) {
      _showError('强化失败: $e');
    }
  }

  // ===================== 合成视图 =====================

  Widget _buildSynthView() {
    return Column(
      children: [
        // 合成规则说明
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          color: DarkWuxiaColors.surface,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.merge, color: DarkWuxiaColors.darkRedBright, size: 18),
                  SizedBox(width: 6),
                  Text('合成规则', style: TextStyle(fontFamily: 'serif', fontSize: 14, fontWeight: FontWeight.bold, color: DarkWuxiaColors.darkRedBright)),
                ],
              ),
              SizedBox(height: 4),
              Text('3件凡品 → 1件良品\n3件良品 → 1件上品\n3件上品 → 1件暗金\n3件暗金 → 1件神品\n3件神品 → 1件传说',
                style: TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textSecondary, height: 1.6)),
            ],
          ),
        ),

        // 选中的合成品质
        if (_synthQuality != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: DarkWuxiaColors.elevated,
            child: Row(
              children: [
                QualityChip(quality: _synthQuality!),
                const SizedBox(width: 8),
                Text(
                  '已选 ${_synthSelected.length}/3',
                  style: const TextStyle(fontFamily: 'serif', fontSize: 14, color: DarkWuxiaColors.darkGold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _synthSelected.length == 3 ? _doSynth : null,
                  icon: const Icon(Icons.merge),
                  label: const Text('合成'),
                  style: ElevatedButton.styleFrom(backgroundColor: DarkWuxiaColors.darkRedBright),
                ),
              ],
            ),
          ),

        // 装备列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _equipment.length,
            itemBuilder: (context, index) {
              final eq = _equipment[index];
              final quality = Quality.fromJson(eq.quality);

              // 只显示可合成品质（排除传说）
              if (quality == Quality.legendary) return const SizedBox.shrink();

              final isSelected = _synthSelected.any((e) => e.id == eq.id);

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: GestureDetector(
                  onTap: () => _toggleSynthSelect(eq),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? quality.color.withValues(alpha: 0.1) : DarkWuxiaColors.elevated,
                      border: Border.all(
                        color: isSelected ? quality.color : DarkWuxiaColors.divider,
                        width: isSelected ? 1 : 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(_slotIcon(eq.baseId), size: 20, color: quality.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            eq.name,
                            style: TextStyle(fontFamily: 'serif', fontSize: 14, color: quality.color),
                          ),
                        ),
                        QualityChip(quality: quality, compact: true),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: DarkWuxiaColors.buffGreen, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _toggleSynthSelect(EquipmentTableData eq) {
    final quality = Quality.fromJson(eq.quality);

    // 如果选了不同品质，重新开始
    if (_synthQuality != null && _synthQuality != quality) {
      setState(() {
        _synthQuality = quality;
        _synthSelected = [eq];
      });
      return;
    }

    setState(() {
      _synthQuality ??= quality;
      if (_synthSelected.any((e) => e.id == eq.id)) {
        _synthSelected.removeWhere((e) => e.id == eq.id);
        if (_synthSelected.isEmpty) _synthQuality = null;
      } else {
        if (_synthSelected.length < 3) {
          _synthSelected.add(eq);
        }
      }
    });
  }

  Future<void> _doSynth() async {
    if (_synthSelected.length != 3) return;
    try {
      final db = AppDatabase.instance;
      final currentQuality = _synthQuality!;
      final nextQuality = _nextQuality(currentQuality);

      // 删除3件
      for (final eq in _synthSelected) {
        await db.equipmentDao.deleteById(eq.id);
      }

      // 生成1件新装备（简化）
      // 实际应调用 drop_engine 生成
      await db.equipmentDao.create(
        baseId: 'synth_${nextQuality.name}',
        quality: nextQuality.name,
        slot: 'weapon',
        name: '合成${nextQuality.displayName}装备',
        affixesJson: '[]',
        reinforceLevel: 0,
        itemLevel: _synthSelected.first.itemLevel,
      );

      _showSuccess('合成成功！获得${nextQuality.displayName}装备');
      setState(() {
        _synthQuality = null;
        _synthSelected = [];
      });
      _loadData();
    } catch (e) {
      _showError('合成失败: $e');
    }
  }

  Quality _nextQuality(Quality q) {
    switch (q) {
      case Quality.normal: return Quality.magic;
      case Quality.magic: return Quality.rare;
      case Quality.rare: return Quality.unique;
      case Quality.unique: return Quality.divine;
      case Quality.divine: return Quality.legendary;
      case Quality.legendary: return Quality.legendary; // 传说不能再合
    }
  }

  // ===================== 辅助 =====================

  IconData _slotIcon(String baseId) {
    if (baseId.contains('weapon') || baseId.contains('sword')) return Icons.gavel;
    if (baseId.contains('armor')) return Icons.shield;
    if (baseId.contains('access')) return Icons.diamond;
    return Icons.auto_awesome;
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: DarkWuxiaColors.buffGreen),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: DarkWuxiaColors.darkRed),
    );
  }
}
