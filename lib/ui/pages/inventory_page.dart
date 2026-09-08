// =============================================================================
// inventory_page.dart — 背包
//
// 对应 DESIGN.md 3.3 装备系统 + 3.10.2 装备 diff 面板
//   - 分页(50条/页)
//   - 按品质/槽位筛选
//   - 装备卡片: 名称(品质色)+词缀+强化等级
//   - 装备详情弹窗: 对比当前装备的战力diff(+15/-3)
//   - 操作: 装备/卸下/出售/熔炼
//   - 背包软上限提示(500件)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';
import '../router.dart';
import '../widgets/equipment_card.dart';
import '../widgets/quality_chip.dart';
import '../../database/database.dart';
import '../../database/daos/equipment_dao.dart';
import '../../models/enums.dart';
import '../../utils/app_logger.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  List<EquipmentTableData> _items = [];
  int _totalCount = 0;
  int _currentPage = 0;
  static const int _pageSize = 50;

  // 筛选
  Quality? _filterQuality;
  String? _filterSlot; // weapon/armor/accessory/treasure

  bool _loading = true;
  int? _characterPower; // 角色战力

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final db = AppDatabase.instance;
      final dao = db.equipmentDao;

      _totalCount = await dao.equipmentCount();
      _items = await dao.getPage(
        page: _currentPage,
        pageSize: _pageSize,
        quality: _filterQuality?.name,
        slot: _filterSlot,
      );

      // 加载角色战力
      final char = await db.characterDao.getCharacter();
      _characterPower = char?.powerIndex;
    } catch (_) {}

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    try {
    final totalPages = (_totalCount / _pageSize).ceil().clamp(1, 999);
    final isFull = _totalCount >= 500;

    return DarkWuxiaScaffold(
      title: '行囊 ($_totalCount/500)',
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterDialog,
        ),
      ],
      body: Column(
        children: [
          // 背包满提示
          if (isFull)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: DarkWuxiaColors.darkRed.withValues(alpha: 0.15),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: DarkWuxiaColors.darkRedBright, size: 18),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '行囊已满！无法获取新装备，建议前往炼器熔炼或出售。',
                      style: TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.darkRedBright),
                    ),
                  ),
                ],
              ),
            ),

          // 筛选标签显示
          if (_filterQuality != null || _filterSlot != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: DarkWuxiaColors.elevated,
              child: Row(
                children: [
                  if (_filterQuality != null) ...[
                    QualityChip(quality: _filterQuality!, compact: true),
                    const SizedBox(width: 8),
                  ],
                  if (_filterSlot != null)
                    Text('槽位: ${_slotLabel(_filterSlot!)}', style: const TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textSecondary)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _filterQuality = null;
                        _filterSlot = null;
                        _currentPage = 0;
                      });
                      _loadData();
                    },
                    child: const Icon(Icons.clear, size: 16, color: DarkWuxiaColors.textHint),
                  ),
                ],
              ),
            ),

          // 装备列表
          Expanded(
            child: _loading
                ? const DarkWuxiaLoading()
                : _items.isEmpty
                    ? const DarkWuxiaEmpty(text: '行囊空空如也', icon: Icons.inventory_2)
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final row = _items[index];
                          return _buildCompactRow(row);
                        },
                      ),
          ),

          // 分页控制
          if (totalPages > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: DarkWuxiaColors.elevated,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 0
                        ? () {
                            setState(() => _currentPage--);
                            _loadData();
                          }
                        : null,
                  ),
                  Text(
                    '${_currentPage + 1} / $totalPages',
                    style: const TextStyle(fontFamily: 'serif', fontSize: 14, color: DarkWuxiaColors.darkGold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < totalPages - 1
                        ? () {
                            setState(() => _currentPage++);
                            _loadData();
                          }
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    } catch (e, stack) {
      AppLogger.instance.error('InventoryPage.build 崩溃: $e\n$stack');
      return const DarkWuxiaScaffold(
        title: '行囊',
        body: DarkWuxiaEmpty(text: '页面加载出错，请查看日志', icon: Icons.error_outline),
      );
    }
  }

  /// 构建紧凑装备行（点击看详情）
  Widget _buildCompactRow(EquipmentTableData row) {
    final quality = Quality.fromJson(row.quality);
    final isEquipped = row.isEquipped;
    return InkWell(
      onTap: () => _showDetailDialog(row),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: DarkWuxiaColors.elevated,
          border: Border.all(color: quality.color.withValues(alpha: 0.35), width: 0.8),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            // 品质色条
            Container(width: 4, height: 36, decoration: BoxDecoration(
              color: quality.color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            // 名称+简述
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Flexible(child: Text(row.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'serif', fontSize: 14, fontWeight: FontWeight.bold, color: quality.color))),
                    if (row.reinforceLevel > 0) ...[
                      const SizedBox(width: 4),
                      Text('+${row.reinforceLevel}',
                        style: TextStyle(fontFamily: 'serif', fontSize: 12, fontWeight: FontWeight.bold, color: quality.color)),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text(
                    _formatAffixSummary(row),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.textSecondary)),
                ],
              ),
            ),
            // 已装备标签
            if (isEquipped)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: DarkWuxiaColors.darkGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3)),
                child: const Text('已装备', style: TextStyle(fontSize: 10, color: DarkWuxiaColors.darkGold, fontWeight: FontWeight.bold)),
              ),
            // 装备/卸下按钮
            InkWell(
              onTap: () => isEquipped ? _unequip(row) : _equip(row),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isEquipped
                      ? DarkWuxiaColors.darkRed.withValues(alpha: 0.15)
                      : DarkWuxiaColors.darkGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(isEquipped ? Icons.remove_circle : Icons.checkroom, size: 13,
                    color: isEquipped ? DarkWuxiaColors.darkRedBright : DarkWuxiaColors.darkGold),
                  const SizedBox(width: 4),
                  Text(isEquipped ? '卸下' : '装备',
                    style: TextStyle(fontSize: 11,
                      color: isEquipped ? DarkWuxiaColors.darkRedBright : DarkWuxiaColors.darkGold)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化词缀简述
  String _formatAffixSummary(EquipmentTableData row) {
    final parts = <String>['${_slotLabel(row.slot)}', 'Lv.${row.itemLevel}'];
    try {
      final affixes = EquipmentDao.parseAffixes(row);
      if (affixes.isNotEmpty) {
        parts.add(affixes.map((a) => a.name).take(2).join('·'));
      }
    } catch (_) {}
    return parts.join(' · ');
  }

  /// 构建装备卡片（保留兼容）
  Widget _buildEquipmentCard(EquipmentTableData row) {
    return _buildCompactRow(row);
  }

  /// 装备详情弹窗
  void _showDetailDialog(EquipmentTableData row) {
    // 从数据库读取角色战力
    final currentPower = _characterPower ?? 0;
    final newPower = currentPower + (row.reinforceLevel * 15) + (row.itemLevel * 2);

    showDialog(
      context: context,
      builder: (ctx) => EquipmentDetailDialog(
        equipment: row,
        isEquipped: row.isEquipped,
        currentPower: row.isEquipped ? null : currentPower,
        newPower: row.isEquipped ? null : newPower,
        onEquip: row.isEquipped ? null : () => _equip(row),
        onUnequip: row.isEquipped ? () => _unequip(row) : null,
        onSell: () => _sell(row),
        onRefine: () => context.push(RouteNames.blacksmith),
      ),
    );
  }

  /// 装备
    Future<void> _equip(EquipmentTableData row) async {
      try {
        final db = AppDatabase.instance;
        final dao = db.equipmentDao;

        // 检查同槽位是否有已装备的装备
        final equipped = await dao.getEquipped();
        final sameSlotEquipped = equipped.where((e) => e.slot == row.slot).toList();

        if (sameSlotEquipped.isNotEmpty) {
          if (!mounted) return;
          // 弹窗确认是否替换
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('替换装备'),
              content: Text(
                '${_slotLabel(row.slot)}槽位已装备【${sameSlotEquipped.first.name}】，\n'
                '是否替换为【${row.name}】？',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('替换'),
                ),
              ],
            ),
          );

          if (confirmed != true) return;
        }

        await dao.equip(row.id);
        // 装备后重算战力
        await db.characterDao.recalculateAndSavePowerIndex();
        _loadData();
      } catch (e) {
        _showError('装备失败: $e');
      }
    }

  /// 卸下
  Future<void> _unequip(EquipmentTableData row) async {
    try {
      final db = AppDatabase.instance;
      await db.equipmentDao.unequip(row.id);
      // 卸下后重算战力
      await db.characterDao.recalculateAndSavePowerIndex();
      _loadData();
    } catch (e) {
      _showError('卸下失败: $e');
    }
  }

  /// 出售
  Future<void> _sell(EquipmentTableData row) async {
    final quality = Quality.fromJson(row.quality);
    final sellPrice = _sellPrice(quality, row.itemLevel, row.reinforceLevel);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('出售装备'),
        content: Text('出售【${row.name}】将获得 $sellPrice 银两，此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('出售')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final db = AppDatabase.instance;
        await db.equipmentDao.deleteById(row.id);
        await db.characterDao.addSilver(sellPrice);
        _loadData();
      } catch (e) {
        _showError('出售失败: $e');
      }
    }
  }

  int _sellPrice(Quality quality, int itemLevel, int reinforceLevel) {
    final basePrice = switch (quality) {
      Quality.normal => itemLevel * 2,
      Quality.magic => itemLevel * 8,
      Quality.rare => itemLevel * 25,
      Quality.unique => itemLevel * 80,
      Quality.divine => itemLevel * 200,
      Quality.legendary => itemLevel * 500,
    };
    return basePrice * (1 + reinforceLevel);
  }

  String _slotLabel(String slot) {
    switch (slot) {
      case 'weapon': return '兵器';
      case 'armor': return '护体';
      case 'accessory': return '饰品';
      case 'treasure': return '奇物';
      default: return slot;
    }
  }

  /// 筛选弹窗
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('筛选'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('品质', style: TextStyle(fontFamily: 'serif', fontSize: 14, color: DarkWuxiaColors.darkGold)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [null, ...Quality.values].map((q) {
                final isSelected = _filterQuality == q;
                return ChoiceChip(
                  label: Text(q?.displayName ?? '全部'),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _filterQuality = q;
                      _currentPage = 0;
                    });
                    Navigator.pop(ctx);
                    _loadData();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            const Text('槽位', style: TextStyle(fontFamily: 'serif', fontSize: 14, color: DarkWuxiaColors.darkGold)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [
                (null, '全部'),
                ('weapon', '兵器'),
                ('armor', '护体'),
                ('accessory', '饰品'),
                ('treasure', '奇物'),
              ].map((s) {
                final isSelected = _filterSlot == s.$1;
                return ChoiceChip(
                  label: Text(s.$2),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _filterSlot = s.$1;
                      _currentPage = 0;
                    });
                    Navigator.pop(ctx);
                    _loadData();
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: DarkWuxiaColors.darkRed),
    );
  }
}
