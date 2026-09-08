// =============================================================================
// drop_history_page.dart — 掉落记录
//
// 对应 DESIGN.md 3.10.3 掉落记录
//   - 掉落历史列表(时间/品质/名称/秘境)
//   - 按品质筛选
//   - 统计图(各品质数量柱状图)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';
import '../router.dart';
import '../widgets/quality_chip.dart';
import '../../database/database.dart';
import '../../models/enums.dart';
import '../../engine/config_loader.dart';
import '../../engine/providers.dart';
import '../../utils/app_logger.dart';

class DropHistoryPage extends ConsumerStatefulWidget {
  const DropHistoryPage({super.key});

  @override
  ConsumerState<DropHistoryPage> createState() => _DropHistoryPageState();
}

class _DropHistoryPageState extends ConsumerState<DropHistoryPage> {
  List<DropHistoryTableData> _records = [];
  Quality? _filterQuality;
  Map<Quality, int> _stats = {};
  int _totalCount = 0;
  bool _loading = true;

  /// 装备ID → 中文名 缓存（含配置回退）
  final Map<String, String> _nameCache = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final db = AppDatabase.instance;
      final dao = db.dropDao;

      _records = _filterQuality != null
          ? await dao.getDropsByQuality(_filterQuality!.name)
          : await dao.getDropsByPage();
      _totalCount = await dao.totalDropCount();
      final statsMap = await dao.countByQuality();
      _stats = statsMap.map((k, v) => MapEntry(Quality.fromJson(k), v));

      // 批量解析装备中文名：优先查装备表，其次用 baseId 查静态配置
      await _resolveNames(db);
    } catch (_) {}
    setState(() => _loading = false);
  }

  /// 解析记录中的装备名（装备表已删除的装备回退到基础配置名）
  Future<void> _resolveNames(AppDatabase db) async {
    final ids = _records.map((r) => r.equipmentId).toSet().toList();
    final found = await db.dropDao.getEquipmentNameMap(ids);
    for (final r in _records) {
      final eq = found[r.equipmentId];
      if (eq != null && eq.name.isNotEmpty) {
        _nameCache[r.equipmentId] = eq.name;
      } else {
        _nameCache[r.equipmentId] = _configFallbackName(r.equipmentId);
      }
    }
  }

  /// 记录中只有ID（装备已出售/删除）时，从 baseId 解析基础装备中文名
  String _configFallbackName(String equipmentId) {
    final config = ref.read(configProvider);
    if (config == null) {
      final short = equipmentId.length > 12 ? '${equipmentId.substring(0, 12)}…' : equipmentId;
      return '装备($short)';
    }

    // ID 格式: eq_{baseId}_{随机数} — 反向解析基础装备ID
    var baseId = equipmentId;
    final prefixIdx = equipmentId.indexOf('eq_');
    if (prefixIdx >= 0) {
      final rest = equipmentId.substring(prefixIdx + 3);
      final parts = rest.split('_');
      // 基础装备ID为 eq_w_001 格式，取前3段拼回
      if (parts.length >= 3) {
        baseId = '${parts[0]}_${parts[1]}_${parts[2]}';
      }
    }
    final base = config.getEquipmentBase(baseId);
    if (base != null && base.name.isNotEmpty) return base.name;
    // 暗金装备回退
    final unique = config.getUniqueEquipment(baseId);
    if (unique != null && unique.name.isNotEmpty) return unique.name;
    return '装备·$baseId';
  }

  /// 获取一条记录应显示的装备中文名
  String _displayName(DropHistoryTableData record) {
    return _nameCache[record.equipmentId] ?? '已获得装备';
  }

  @override
  Widget build(BuildContext context) {
    try {
    return DarkWuxiaScaffold(
      title: '掉落记录',
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterSheet,
        ),
      ],
      body: _loading
          ? const DarkWuxiaLoading()
          : CustomScrollView(
              slivers: [
                // 统计柱状图
                SliverToBoxAdapter(child: _buildStatsChart()),

                // 筛选标签
                if (_filterQuality != null)
                  SliverToBoxAdapter(child: _buildFilterBar()),

                // 掉落列表
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildRecordTile(_records[index]),
                    childCount: _records.length,
                  ),
                ),
              ],
            ),
    );
    } catch (e, stack) {
      AppLogger.instance.error('DropHistoryPage.build 崩溃: $e\n$stack');
      return const DarkWuxiaScaffold(
        title: '掉落记录',
        body: DarkWuxiaEmpty(text: '页面加载出错，请查看日志', icon: Icons.error_outline),
      );
    }
  }

  /// 统计柱状图
  Widget _buildStatsChart() {
    final maxCount = _stats.values.fold(0, (a, b) => a > b ? a : b).clamp(1, 9999);

    return DarkWuxiaCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const DarkWuxiaSectionTitle(text: '掉落统计', icon: Icons.bar_chart),
              const Spacer(),
              Text(
                '总计 $_totalCount 件',
                style: const TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 柱状图
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: Quality.values.map((q) {
                final count = _stats[q] ?? 0;
                final height = (count / maxCount) * 100;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _filterQuality = _filterQuality == q ? null : q;
                      });
                      _loadData();
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$count',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 10,
                            color: count > 0 ? q.color : DarkWuxiaColors.textHint,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 20,
                          height: height.clamp(2.0, 100.0),
                          decoration: BoxDecoration(
                            color: q.color.withValues(alpha: count > 0 ? 0.7 : 0.2),
                            border: Border.all(color: q.color, width: 0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          q.displayName,
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 9,
                            color: q.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 筛选标签
  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: DarkWuxiaColors.elevated,
      child: Row(
        children: [
          const Text('筛选: ', style: TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textSecondary)),
          QualityChip(quality: _filterQuality!, compact: true),
          const Spacer(),
          GestureDetector(
            onTap: () {
              setState(() => _filterQuality = null);
              _loadData();
            },
            child: const Icon(Icons.clear, size: 16, color: DarkWuxiaColors.textHint),
          ),
        ],
      ),
    );
  }

  /// 掉落记录条目
  Widget _buildRecordTile(DropHistoryTableData record) {
    final quality = Quality.fromJson(record.quality);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: quality.dimColor,
        border: Border(
          left: BorderSide(color: quality.color, width: 3),
        ),
      ),
      child: Row(
        children: [
          // 品质色条
          Container(
            width: 4,
            height: 40,
            color: quality.color,
          ),
          const SizedBox(width: 8),
          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _displayName(record),
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: quality.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    QualityChip(quality: quality, compact: true),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: DarkWuxiaColors.textHint),
                    const SizedBox(width: 2),
                    Text(
                      record.realmId,
                      style: const TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time, size: 12, color: DarkWuxiaColors.textHint),
                    const SizedBox(width: 2),
                    Text(
                      _formatTime(record.timestamp),
                      style: const TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.textHint),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DarkWuxiaColors.elevated,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('按品质筛选', style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: DarkWuxiaColors.darkGold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                (null, '全部'),
                ...Quality.values.map((q) => (q, q.displayName)),
              ].map((pair) {
                final isSelected = _filterQuality == pair.$1;
                return ChoiceChip(
                  label: Text(pair.$2),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _filterQuality = pair.$1);
                    Navigator.pop(ctx);
                    _loadData();
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
