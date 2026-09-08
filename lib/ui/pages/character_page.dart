// =============================================================================
// character_page.dart — 角色面板
// =============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';
import '../router.dart';
import '../widgets/health_bar.dart';
import '../../database/database.dart';
import '../../database/daos/meridian_dao.dart';
import '../../models/enums.dart';
import '../../models/attributes.dart';
import '../../models/martial_art.dart';
import '../../models/meridian.dart';
import '../../engine/config_loader.dart';
import '../../engine/providers.dart';
import '../../utils/app_logger.dart';

class CharacterPage extends ConsumerStatefulWidget {
  const CharacterPage({super.key});
  @override
  ConsumerState<CharacterPage> createState() => _CharacterPageState();
}

class _CharacterPageState extends ConsumerState<CharacterPage> {
  CharacterTableData? _character;
  List<EquipmentTableData> _equippedItems = [];
  Map<String, MeridianStateTableData> _meridianStates = {};
  List<MeridianConfigEntry> _meridianConfigs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 每次页面变为可见时刷新数据（从背包返回后能看到最新装备状态）
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 使用 ModalRoute 检测页面是否变为顶层路由
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final db = AppDatabase.instance;
      final char = await db.characterDao.getCharacter();
      final equipped = await db.equipmentDao.getEquipped();
      // 经脉状态（表为空时按配置初始化）
      final states = await db.meridianDao.getStates();
      final configs = ref.read(configProvider)?.meridianConfigs ?? const <MeridianConfigEntry>[];
      if (states.isEmpty && configs.isNotEmpty) {
        await db.meridianDao.ensureStatesFor(configs.map((c) => c.id).toList());
      }
      final states2 = states.isEmpty ? await db.meridianDao.getStates() : states;
      if (!mounted) return;
      setState(() {
        _character = char;
        _equippedItems = equipped;
        _meridianConfigs = configs;
        _meridianStates = {for (final s in states2) s.meridianId: s};
        _loading = false;
      });
    } catch (e, stack) {
      AppLogger.instance.error('CharacterPage._loadData 失败: $e\n$stack');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      if (_loading) {
        return const Scaffold(backgroundColor: DarkWuxiaColors.background, body: DarkWuxiaLoading());
      }
      return DarkWuxiaScaffold(
        title: '角色面板',
        body: _character == null
          ? const DarkWuxiaEmpty(text: '尚无角色')
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildHeader(_character!),
                const SizedBox(height: 12),
                _buildAttributes(_character!),
                const SizedBox(height: 12),
                _buildMartialArts(_character!),
                const SizedBox(height: 12),
                _buildMeridians(_character!),
                const SizedBox(height: 12),
                _buildHeartMantra(_character!),
                const SizedBox(height: 12),
                _buildEquipmentSlots(),
              ]),
      );
    } catch (e, stack) {
      AppLogger.instance.error('CharacterPage.build 崩溃: $e\n$stack');
      return const DarkWuxiaScaffold(
        title: '角色面板',
        body: DarkWuxiaEmpty(text: '页面加载出错，请查看日志', icon: Icons.error_outline),
      );
    }
  }

  Widget _buildHeader(CharacterTableData char) {
    try {
    final attrs = _parseAttributes(char.attributesJson);
    final maxHp = (attrs['body'] ?? 10) * char.level * 15;
    final maxIe = (attrs['con'] ?? 10) * char.level * 10;
    return DarkWuxiaCard(
      borderColor: DarkWuxiaColors.darkGold,
      borderWidth: 1,
      child: Column(children: [
        Row(children: [
          const Icon(Icons.person, color: DarkWuxiaColors.darkGold, size: 32),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(char.name, style: const TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.bold, color: DarkWuxiaColors.darkGold)),
            Text('${char.origin} · 等级 ${char.level} · ${char.age}岁',
              style: const TextStyle(fontFamily: 'serif', fontSize: 13, color: DarkWuxiaColors.textSecondary)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: DarkWuxiaColors.darkGold.withValues(alpha: 0.15),
              border: Border.all(color: DarkWuxiaColors.darkGold)),
            child: Column(children: [
              const Text('战力指数', style: TextStyle(fontFamily: 'serif', fontSize: 10, color: DarkWuxiaColors.textSecondary)),
              Text('${char.powerIndex}', style: const TextStyle(fontFamily: 'serif', fontSize: 28, fontWeight: FontWeight.bold, color: DarkWuxiaColors.darkGold)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        HealthBar.hp(current: char.health, max: maxHp),
        const SizedBox(height: 6),
        HealthBar.innerEnergy(current: char.innerEnergy, max: maxIe),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _buildStatChip('正邪', char.alignment, _alignmentLabel(char.alignment)),
          _buildStatChip('名望', char.reputation, ''),
          _buildStatChip('福缘', char.fortune, ''),
        ]),
      ]),
    );
    } catch (e, stack) {
      AppLogger.instance.error('CharacterPage._buildHeader 崩溃: $e\n$stack');
      return DarkWuxiaCard(child: const Text('角色信息加载失败', style: TextStyle(color: DarkWuxiaColors.darkRedBright)));
    }
  }

  Widget _buildStatChip(String label, int value, String suffix) {
    return Column(children: [
      Text(label, style: const TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.textSecondary)),
      Text(suffix.isNotEmpty ? '$value($suffix)' : '$value',
        style: const TextStyle(fontFamily: 'serif', fontSize: 14, fontWeight: FontWeight.bold, color: DarkWuxiaColors.darkGold)),
    ]);
  }

  String _alignmentLabel(int alignment) {
    if (alignment >= 50) return '正道';
    if (alignment <= -50) return '邪道';
    return '中立';
  }

  Widget _buildAttributes(CharacterTableData char) {
    try {
    final attrs = _parseAttributes(char.attributesJson);
    return DarkWuxiaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const DarkWuxiaSectionTitle(text: '五维属性', icon: Icons.bar_chart),
      const SizedBox(height: 8),
      _buildAttrBar('臂力', attrs['body'] ?? 0, '外功伤害基数', DarkWuxiaColors.darkRedBright),
      _buildAttrBar('身法', attrs['agi'] ?? 0, '先手/闪避/暴击', DarkWuxiaColors.innerEnergy),
      _buildAttrBar('悟性', attrs['wis'] ?? 0, '修炼速度/兼容性', DarkWuxiaColors.darkGold),
      _buildAttrBar('根骨', attrs['con'] ?? 0, '内力上限/恢复', DarkWuxiaColors.buffGreen),
      _buildAttrBar('福缘', attrs['luck'] ?? 0, '掉率加成', DarkWuxiaColors.darkGoldBright),
    ]));
    } catch (e, stack) {
      AppLogger.instance.error('CharacterPage._buildAttributes 崩溃: $e\n$stack');
      return DarkWuxiaCard(child: const Text('属性加载失败', style: TextStyle(color: DarkWuxiaColors.darkRedBright)));
    }
  }

  Widget _buildAttrBar(String label, int value, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(width: 36, child: Text(label, style: TextStyle(fontFamily: 'serif', fontSize: 13, fontWeight: FontWeight.bold, color: color))),
        const SizedBox(width: 4),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LinearProgressIndicator(
            value: (value / 50).clamp(0.0, 1.0),
            backgroundColor: DarkWuxiaColors.elevated, color: color, minHeight: 8),
          Text(desc, style: const TextStyle(fontFamily: 'serif', fontSize: 9, color: DarkWuxiaColors.textHint)),
        ])),
        const SizedBox(width: 4),
        SizedBox(width: 30, child: Text('$value', textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'serif', fontSize: 14, fontWeight: FontWeight.bold, color: color))),
      ]),
    );
  }

  Widget _buildMartialArts(CharacterTableData char) {
    try {
    final arts = _parseMartialArts(char.martialArtsJson);
    return DarkWuxiaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const DarkWuxiaSectionTitle(text: '武功', icon: Icons.sports_martial_arts),
        const Spacer(),
        Text('${arts.length} 门', style: const TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textSecondary)),
      ]),
      const SizedBox(height: 8),
      if (arts.isEmpty)
        const DarkWuxiaEmpty(text: '尚未习得任何武功', icon: Icons.sports_martial_arts)
      else
        ...arts.map((art) => _MartialArtTile(art: art)),
    ]));
    } catch (e, stack) {
      AppLogger.instance.error('CharacterPage._buildMartialArts 崩溃: $e\n$stack');
      return DarkWuxiaCard(child: const Text('武功加载失败', style: TextStyle(color: DarkWuxiaColors.darkRedBright)));
    }
  }

  Widget _buildMeridians(CharacterTableData char) {
      try {
      final configs = _meridianConfigs;
      if (configs.isEmpty) {
        return DarkWuxiaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          DarkWuxiaSectionTitle(text: '经脉', icon: Icons.account_tree),
          SizedBox(height: 8),
          Text('经脉图鉴尚未解锁', style: TextStyle(fontFamily: 'serif', fontSize: 13, color: DarkWuxiaColors.textSecondary)),
        ]));
      }

      final activeCount = _meridianStates.values.where((s) => s.isActive).length;
      final totalOpened = _meridianStates.values.fold<int>(0, (sum, s) => sum + s.openedNodes);
      final totalNodes = configs.fold<int>(0, (sum, c) => sum + c.nodes.length);

      return DarkWuxiaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const DarkWuxiaSectionTitle(text: '经脉', icon: Icons.account_tree),
          const Spacer(),
          Text('已通 $totalOpened/$totalNodes 穴 · 激活 $activeCount 脉',
              style: const TextStyle(fontFamily: 'serif', fontSize: 10, color: DarkWuxiaColors.textSecondary)),
        ]),
        const SizedBox(height: 8),
        ...configs.map((cfg) => _buildMeridianTile(cfg)),
      ]));
      } catch (e, stack) {
        AppLogger.instance.error('CharacterPage._buildMeridians 崩溃: $e\n$stack');
        return DarkWuxiaCard(child: const Text('经脉加载失败', style: TextStyle(color: DarkWuxiaColors.darkRedBright)));
      }
    }

    Widget _buildMeridianTile(MeridianConfigEntry cfg) {
      final state = _meridianStates[cfg.id];
      final opened = state?.openedNodes ?? 0;
      final total = cfg.nodes.length;
      final isActive = state?.isActive ?? false;
      final isYang = cfg.type == 'yang';
      final color = isYang ? DarkWuxiaColors.darkRedBright : DarkWuxiaColors.innerEnergy;
      final silver = charSilver();
      final nextCost = opened >= total ? 0 : AppDatabase.instance.meridianDao.silverCostForNode(opened + 1);

      // 相克已激活检查
      final activeConflicts = <String>[
        for (final cid in cfg.conflictMeridians)
          if (_meridianStates[cid]?.isActive ?? false) cid,
      ];
      final hasSynergy = cfg.synergyMeridians
          .any((sid) => _meridianStates[sid]?.isActive ?? false);

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: DarkWuxiaColors.background,
          border: Border.all(color: isActive ? color : DarkWuxiaColors.divider, width: isActive ? 1 : 0.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 标题行
          Row(children: [
            Text(cfg.name,
                style: TextStyle(fontFamily: 'serif', fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text('${cfg.tier}阶', style: TextStyle(fontFamily: 'serif', fontSize: 9, color: color)),
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle, size: 14, color: DarkWuxiaColors.darkGold),
            ],
            if (activeConflicts.isNotEmpty) ...[
              const SizedBox(width: 6),
              const Icon(Icons.warning_amber, size: 14, color: DarkWuxiaColors.darkRed),
            ],
            if (hasSynergy) ...[
              const SizedBox(width: 6),
              const Icon(Icons.link, size: 12, color: DarkWuxiaColors.darkGold),
            ],
            const Spacer(),
            Text('$opened/$total 穴',
                style: const TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.textSecondary)),
          ]),
          if (cfg.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(cfg.description, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.textSecondary)),
          ],
          const SizedBox(height: 6),
          // 穴位线
          Row(children: [
            ...List.generate(total, (i) {
              final isOpen = i < opened;
              return Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  height: 22,
                  decoration: BoxDecoration(
                    color: isOpen ? color.withValues(alpha: 0.4) : DarkWuxiaColors.elevated,
                    border: Border.all(color: isOpen ? color : DarkWuxiaColors.divider, width: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: isOpen ? Icon(Icons.circle, size: 6, color: color) : null,
                ),
              ));
            }),
          ]),
          const SizedBox(height: 6),
          // 操作行
          Row(children: [
            InkWell(
              onTap: opened >= total ? null : () => _openMeridianNode(cfg),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DarkWuxiaColors.darkGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: DarkWuxiaColors.darkGold, width: 0.5),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add_circle_outline, size: 13, color: DarkWuxiaColors.darkGold),
                  const SizedBox(width: 4),
                  Text(opened >= total ? '已全通' : '冲穴 (-$nextCost银)',
                      style: const TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.darkGold)),
                ]),
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () => isActive ? _deactivateMeridian(cfg) : _activateMeridian(cfg),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isActive ? DarkWuxiaColors.darkRed : DarkWuxiaColors.buffGreen).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: isActive ? DarkWuxiaColors.darkRedBright : DarkWuxiaColors.buffGreen, width: 0.5),
                ),
                child: Text(isActive ? '关闭' : '激活',
                    style: TextStyle(fontFamily: 'serif', fontSize: 11,
                      color: isActive ? DarkWuxiaColors.darkRedBright : DarkWuxiaColors.buffGreen)),
              ),
            ),
          ]),
        ]),
      );
    }

    int charSilver() => _character?.silver ?? 0;

    Future<void> _openMeridianNode(MeridianConfigEntry cfg) async {
      try {
        await AppDatabase.instance.meridianDao.openNode(cfg.id, maxNodes: cfg.nodes.length);
        await _loadData();
        _showSnack('经脉穴位已冲开，战力提升！');
      } on MeridianBusinessException catch (e) {
        _showSnack(e.message);
      } catch (e) {
        AppLogger.instance.error('_openMeridianNode 失败: $e');
        _showSnack('冲穴失败，请查看日志');
      }
    }

    Future<void> _activateMeridian(MeridianConfigEntry cfg) async {
      try {
        final db = AppDatabase.instance;
        // 相克检测
        final activeConflicts = <String>[
          for (final cid in cfg.conflictMeridians)
            if (_meridianStates[cid]?.isActive ?? false) cid,
        ];

        if (activeConflicts.isNotEmpty) {
          if (!mounted) return;
          final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: DarkWuxiaColors.elevated,
              title: const Text('真气逆行之险',
                  style: TextStyle(color: DarkWuxiaColors.darkRedBright)),
              content: Text('激活【${cfg.name}】将与已激活的相克经脉冲突，'
                  '两股真气相撞，身陷走火入魔之险！\n确定要强行激活吗？',
                  style: const TextStyle(fontSize: 13, color: DarkWuxiaColors.textPrimary)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('谨慎后退'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('强行激活'),
                ),
              ],
            ),
          );
          if (proceed != true) return;
        }

        final warning = await db.meridianDao.activateMeridian(
          cfg.id,
          requireAllNodesOpened: true,
          maxNodes: cfg.nodes.length,
          conflictIdsForMeridian: (_) => cfg.conflictMeridians,
        );
        await _loadData();
        if (warning.hasConflict) {
          _showSnack('⚠ 真气逆行！相克经脉同时激活，战力受损！');
        } else {
          _showSnack('【${cfg.name}】已激活，脉系加成生效！');
        }
      } on MeridianBusinessException catch (e) {
        _showSnack(e.message);
      } catch (e) {
        AppLogger.instance.error('_activateMeridian 失败: $e');
        _showSnack('激活失败，请查看日志');
      }
    }

    Future<void> _deactivateMeridian(MeridianConfigEntry cfg) async {
      try {
        await AppDatabase.instance.meridianDao.deactivateMeridian(
          cfg.id,
          conflictIdsForMeridian: (_) => cfg.conflictMeridians,
        );
        await _loadData();
        _showSnack('【${cfg.name}】已关闭');
      } catch (e) {
        AppLogger.instance.error('_deactivateMeridian 失败: $e');
        _showSnack('关闭失败，请查看日志');
      }
    }

    void _showSnack(String msg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 13)),
        duration: const Duration(seconds: 2),
      ));
    }

  Widget _buildMeridianRow(String name, List<MeridianNode> nodes, bool isYang) {
    final color = isYang ? DarkWuxiaColors.darkRedBright : DarkWuxiaColors.innerEnergy;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        SizedBox(width: 50, child: Text(name, style: TextStyle(fontFamily: 'serif', fontSize: 11, color: color, fontWeight: FontWeight.w600))),
        ...List.generate(5, (i) {
          final node = nodes.firstWhere((n) => n.nodeIndex == i,
            orElse: () => MeridianNode(meridianId: '', nodeIndex: i));
          final isOpen = node.isOpen;
          return Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                color: isOpen ? color.withValues(alpha: 0.3) : DarkWuxiaColors.elevated,
                border: Border.all(color: isOpen ? color : DarkWuxiaColors.divider, width: isOpen ? 1 : 0.5),
                shape: BoxShape.circle,
              ),
              child: node.seedId != null
                ? Icon(Icons.eco, size: 12, color: color)
                : isOpen ? Icon(Icons.circle, size: 8, color: color) : null,
            ),
          ));
        }),
      ]),
    );
  }

  Widget _buildHeartMantra(CharacterTableData char) {
    try {
    return DarkWuxiaCard(
      borderColor: char.heartMantra != null ? DarkWuxiaColors.darkGold : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const DarkWuxiaSectionTitle(text: '心法', icon: Icons.auto_awesome),
        const SizedBox(height: 8),
        if (char.heartMantra == null)
          const Text('尚未装备心法', style: TextStyle(fontFamily: 'serif', fontSize: 13, color: DarkWuxiaColors.textSecondary))
        else
          Row(children: [
            const Icon(Icons.auto_awesome, color: DarkWuxiaColors.darkGold, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(char.heartMantra!,
              style: const TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: DarkWuxiaColors.darkGold))),
          ]),
      ]),
    );
    } catch (e, stack) {
      AppLogger.instance.error('CharacterPage._buildHeartMantra 崩溃: $e\n$stack');
      return DarkWuxiaCard(child: const Text('心法加载失败', style: TextStyle(color: DarkWuxiaColors.darkRedBright)));
    }
  }

  Widget _buildEquipmentSlots() {
    try {
    final slotDefs = [
      ('兵器', 'weapon', Icons.gavel, DarkWuxiaColors.darkRedBright),
      ('护体', 'armor', Icons.shield, DarkWuxiaColors.buffGreen),
      ('饰品', 'accessory', Icons.diamond, DarkWuxiaColors.innerEnergy),
      ('奇物', 'treasure', Icons.auto_awesome, DarkWuxiaColors.darkGold),
    ];
    return DarkWuxiaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const DarkWuxiaSectionTitle(text: '装备', icon: Icons.inventory_2),
      const SizedBox(height: 8),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: 3.5),
        itemCount: 4,
        itemBuilder: (context, index) {
          final s = slotDefs[index];
          final slotName = s.$1;
          final slotKey = s.$2;
          final icon = s.$3;
          final color = s.$4;
          final equipped = _equippedItems.where((e) => e.slot == slotKey).toList();
          final hasEquipped = equipped.isNotEmpty;
          final eq = hasEquipped ? equipped.first : null;
          // 品质颜色
          Color? qualityColor;
          if (eq != null) {
            try {
              final q = Quality.fromJson(eq.quality);
              qualityColor = _qualityColor(q);
            } catch (_) {}
          }
          return Container(
            decoration: BoxDecoration(
              color: hasEquipped ? color.withValues(alpha: 0.12) : DarkWuxiaColors.elevated,
              border: Border.all(
                color: hasEquipped ? (qualityColor ?? color) : DarkWuxiaColors.divider,
                width: hasEquipped ? 1.5 : 0.5,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(children: [
              // 装备图标 — 已装备点击查看详情，空槽位点击弹出未装备列表
              Expanded(
                child: GestureDetector(
                  onTap: hasEquipped
                      ? () => _showEquippedDetail(eq!)
                      : () => _showUnEquippedPicker(slotKey, slotName, color),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(children: [
                      Icon(icon, size: 24, color: hasEquipped ? (qualityColor ?? color) : DarkWuxiaColors.textHint),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(slotName,
                              style: TextStyle(fontFamily: 'serif', fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                            if (hasEquipped)
                              Text(eq!.name,
                                style: TextStyle(fontFamily: 'serif', fontSize: 11, fontWeight: FontWeight.bold,
                                  color: qualityColor ?? DarkWuxiaColors.textPrimary),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (!hasEquipped)
                              const Text('点击选择装备', style: TextStyle(fontFamily: 'serif', fontSize: 10, color: DarkWuxiaColors.textHint)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
              // 卸下按钮
              if (hasEquipped)
                GestureDetector(
                  onTap: () => _unequipFromSlot(eq!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: DarkWuxiaColors.darkRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.close, size: 16, color: DarkWuxiaColors.darkRedBright),
                  ),
                ),
              if (!hasEquipped)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: const Icon(Icons.add, size: 16, color: DarkWuxiaColors.textHint),
                ),
            ]),
          );
        },
      ),
    ]));
    } catch (e, stack) {
      AppLogger.instance.error('CharacterPage._buildEquipmentSlots 崩溃: $e\n$stack');
      return DarkWuxiaCard(child: const Text('装备加载失败', style: TextStyle(color: DarkWuxiaColors.darkRedBright)));
    }
  }

  /// 品质颜色映射
  Color _qualityColor(Quality q) {
    switch (q) {
      case Quality.normal: return DarkWuxiaColors.textSecondary;
      case Quality.magic: return DarkWuxiaColors.buffGreen;
      case Quality.rare: return DarkWuxiaColors.innerEnergy;
      case Quality.unique: return DarkWuxiaColors.darkGold;
      case Quality.divine: return DarkWuxiaColors.darkGoldBright;
      case Quality.legendary: return DarkWuxiaColors.darkRedBright;
    }
  }

  /// 空槽位点击 — 弹出该槽位背包中未装备的装备列表
  void _showUnEquippedPicker(String slotKey, String slotName, Color slotColor) async {
    try {
      final db = AppDatabase.instance;
      final candidates = await db.equipmentDao.getUnequippedBySlot(slotKey);
      if (!mounted) return;

      if (candidates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('行囊中没有可装备的${slotName}，先去秘境刷装备吧！'),
            backgroundColor: DarkWuxiaColors.elevated,
          ),
        );
        return;
      }

      // 按品质/物品等级排序（高品质优先）
      candidates.sort((a, b) {
        final qa = Quality.fromJson(a.quality).index;
        final qb = Quality.fromJson(b.quality).index;
        if (qa != qb) return qb.compareTo(qa);
        return b.itemLevel.compareTo(a.itemLevel);
      });

      await showModalBottomSheet(
        context: context,
        backgroundColor: DarkWuxiaColors.elevated,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
        builder: (ctx) => _UnEquippedPickerSheet(
          slotName: slotName,
          slotColor: slotColor,
          candidates: candidates,
          onPick: (eq) async {
            Navigator.pop(ctx);
            await _equipFromPicker(eq);
          },
        ),
      );
      // 无论是否选择，返回后刷新装备状态
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载可装备列表失败: $e'), backgroundColor: DarkWuxiaColors.darkRed),
        );
      }
    }
  }

  /// 从选择弹窗装备一件装备
  Future<void> _equipFromPicker(EquipmentTableData eq) async {
    try {
      final db = AppDatabase.instance;
      await db.equipmentDao.equip(eq.id);
      await db.characterDao.recalculateAndSavePowerIndex();
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已装备 ${eq.name}'), backgroundColor: DarkWuxiaColors.darkGold),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('装备失败: $e'), backgroundColor: DarkWuxiaColors.darkRed),
        );
      }
    }
  }

  /// 显示已装备装备的详情弹窗
  void _showEquippedDetail(EquipmentTableData eq) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DarkWuxiaColors.surface,
        title: Row(children: [
          Icon(Icons.inventory_2, color: _qualityColor(Quality.fromJson(eq.quality))),
          const SizedBox(width: 8),
          Expanded(child: Text(eq.name, style: const TextStyle(fontFamily: 'serif', fontSize: 16, color: DarkWuxiaColors.darkGold))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('品质: ${Quality.fromJson(eq.quality).displayName}', style: const TextStyle(fontFamily: 'serif', fontSize: 13, color: DarkWuxiaColors.textPrimary)),
          const SizedBox(height: 4),
          Text('槽位: ${_slotLabel(eq.slot)}', style: const TextStyle(fontFamily: 'serif', fontSize: 13, color: DarkWuxiaColors.textSecondary)),
          const SizedBox(height: 4),
          Text('物品等级: ${eq.itemLevel}', style: const TextStyle(fontFamily: 'serif', fontSize: 13, color: DarkWuxiaColors.textSecondary)),
          const SizedBox(height: 4),
          Text('强化等级: +${eq.reinforceLevel}', style: const TextStyle(fontFamily: 'serif', fontSize: 13, color: DarkWuxiaColors.textSecondary)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭', style: TextStyle(color: DarkWuxiaColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _unequipFromSlot(eq);
            },
            style: ElevatedButton.styleFrom(backgroundColor: DarkWuxiaColors.darkRed.withValues(alpha: 0.3)),
            child: const Text('卸下', style: TextStyle(color: DarkWuxiaColors.darkRedBright)),
          ),
        ],
      ),
    );
  }

  /// 卸下指定槽位的装备
  Future<void> _unequipFromSlot(EquipmentTableData eq) async {
    try {
      final db = AppDatabase.instance;
      await db.equipmentDao.unequip(eq.id);
      await db.characterDao.recalculateAndSavePowerIndex();
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已卸下 ${eq.name}'), backgroundColor: DarkWuxiaColors.darkGold),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('卸下失败: $e'), backgroundColor: DarkWuxiaColors.darkRed),
        );
      }
    }
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

  Map<String, int> _parseAttributes(String json) {
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {'body': 10, 'agi': 10, 'wis': 10, 'con': 10, 'luck': 5};
    }
  }

  List<MartialArt> _parseMartialArts(String json) {
    try {
      final decoded = jsonDecode(json) as List;
      return decoded.map((e) {
        final map = e as Map<String, dynamic>;
        return MartialArt(
          id: map['id'] ?? '',
          name: map['name'] ?? '无名功法',
          type: map['type'] != null ? MartialType.fromJson(map['type']) : MartialType.external,
          proficiency: (map['proficiency'] ?? 0) as int,
          proficiencyLevel: map['proficiencyLevel'] != null
            ? ProficiencyLevel.fromJson(map['proficiencyLevel']) : ProficiencyLevel.novice,
          elementAffinity: map['elementAffinity'] != null
            ? ElementAffinity.fromJson(map['elementAffinity']) : ElementAffinity.neutral,
          damageMultiplier: (map['damageMultiplier'] ?? 1.0).toDouble(),
          energyCost: (map['energyCost'] ?? 0) as int,
          isActive: (map['isActive'] ?? true) as bool,
          description: (map['description'] ?? '') as String,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  List<MeridianNode> _parseMeridians(String json) {
    try {
      final decoded = jsonDecode(json) as List;
      return decoded.map((e) {
        final map = e as Map<String, dynamic>;
        return MeridianNode(
          meridianId: map['meridianId'] ?? '',
          nodeIndex: map['nodeIndex'] ?? 0,
          isOpen: map['isOpen'] ?? false,
          seedId: map['seedId'],
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}

class _MartialArtTile extends StatefulWidget {
  final MartialArt art;
  const _MartialArtTile({required this.art});
  @override
  State<_MartialArtTile> createState() => _MartialArtTileState();
}

class _MartialArtTileState extends State<_MartialArtTile> {
  @override
  Widget build(BuildContext context) {
    final color = _typeColor(widget.art.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: DarkWuxiaColors.elevated,
        border: Border.all(color: DarkWuxiaColors.divider, width: 0.5),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Row(children: [
          Icon(_typeIcon(widget.art.type), size: 16, color: color),
          const SizedBox(width: 6),
          Text(widget.art.name, style: TextStyle(fontFamily: 'serif', fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color, width: 0.5)),
            child: Text(widget.art.proficiencyLevel.displayName,
              style: TextStyle(fontFamily: 'serif', fontSize: 9, color: color)),
          ),
        ]),
        subtitle: Text('${widget.art.type.displayName} · ${widget.art.elementAffinity.displayName} · 熟练度 ${widget.art.proficiency}/100',
          style: const TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.textSecondary)),
        children: [
          if (widget.art.description.isNotEmpty)
            Text(widget.art.description,
              style: const TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textPrimary, height: 1.5)),
          const SizedBox(height: 4),
          Text('伤害倍率: ${widget.art.damageMultiplier}x',
            style: const TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.textSecondary)),
          Text('内力消耗: ${widget.art.energyCost}',
            style: const TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.textSecondary)),
        ],
      ),
    );
  }

  Color _typeColor(MartialType type) {
    switch (type) {
      case MartialType.internal: return DarkWuxiaColors.darkGold;
      case MartialType.external: return DarkWuxiaColors.darkRedBright;
      case MartialType.lightness: return DarkWuxiaColors.innerEnergy;
      case MartialType.mantra: return DarkWuxiaColors.darkGoldBright;
    }
  }

  IconData _typeIcon(MartialType type) {
    switch (type) {
      case MartialType.internal: return Icons.self_improvement;
      case MartialType.external: return Icons.sports_martial_arts;
      case MartialType.lightness: return Icons.directions_run;
      case MartialType.mantra: return Icons.auto_awesome;
    }
  }
}

// =============================================================================
// 未装备列表选择弹窗 — 点击槽位后展示行囊中该槽位的可装备列表
// =============================================================================
class _UnEquippedPickerSheet extends StatelessWidget {
  final String slotName;
  final Color slotColor;
  final List<EquipmentTableData> candidates;
  final void Function(EquipmentTableData eq) onPick;

  const _UnEquippedPickerSheet({
    required this.slotName,
    required this.slotColor,
    required this.candidates,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  Icon(Icons.inventory_2, size: 18, color: slotColor),
                  const SizedBox(width: 6),
                  Text(
                    '选择$slotName',
                    style: const TextStyle(
                      fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold,
                      color: DarkWuxiaColors.darkGold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${candidates.length} 件可选',
                    style: const TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.textHint),
                  ),
                ],
              ),
            ),
            const Divider(color: DarkWuxiaColors.divider, height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: candidates.length,
                itemBuilder: (context, index) {
                  final eq = candidates[index];
                  final quality = Quality.fromJson(eq.quality);
                  final qColor = _pickerQualityColor(quality);
                  return InkWell(
                    onTap: () => onPick(eq),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: DarkWuxiaColors.surface,
                        border: Border.all(color: DarkWuxiaColors.divider, width: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(_slotIconFor(eq.slot), size: 18, color: qColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  eq.name,
                                  style: TextStyle(
                                    fontFamily: 'serif', fontSize: 13, fontWeight: FontWeight.bold, color: qColor,
                                  ),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${quality.displayName} · Lv.${eq.itemLevel}'
                                  '${eq.reinforceLevel > 0 ? ' · 强化+${eq.reinforceLevel}' : ''}',
                                  style: TextStyle(
                                    fontFamily: 'serif', fontSize: 10, color: qColor.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 18, color: DarkWuxiaColors.textHint),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Color _pickerQualityColor(Quality q) {
    switch (q) {
      case Quality.normal: return DarkWuxiaColors.textSecondary;
      case Quality.magic: return DarkWuxiaColors.buffGreen;
      case Quality.rare: return DarkWuxiaColors.innerEnergy;
      case Quality.unique: return DarkWuxiaColors.darkGold;
      case Quality.divine: return DarkWuxiaColors.darkGoldBright;
      case Quality.legendary: return DarkWuxiaColors.darkRedBright;
    }
  }

  IconData _slotIconFor(String slot) {
    switch (slot) {
      case 'weapon': return Icons.gavel;
      case 'armor': return Icons.shield;
      case 'accessory': return Icons.diamond;
      case 'treasure': return Icons.auto_awesome;
      default: return Icons.inventory_2;
    }
  }
}
