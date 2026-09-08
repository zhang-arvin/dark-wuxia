// =============================================================================
// home_page.dart — 主页/主城
// =============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';
import '../router.dart';
import '../widgets/health_bar.dart';
import '../../database/database.dart';
import '../../models/attributes.dart';
import '../../utils/app_logger.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  CharacterTableData? _character;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCharacter();
  }

  Future<void> _loadCharacter() async {
    try {
      AppLogger.instance.info('[_loadCharacter] 开始加载角色...');
      final db = AppDatabase.instance;
      final char = await db.characterDao.getCharacter();
      if (char == null && mounted) {
        AppLogger.instance.info('[_loadCharacter] getCharacter() 返回 null — 无角色，进入创建流程');
        _createNewCharacter();
        return; // _createNewCharacter 内部会再次调用 _loadCharacter
      }
      AppLogger.instance.info('[_loadCharacter] 角色已加载: ${char!.name}, 等级=${char.level}, 战力=${char.powerIndex}');
      setState(() {
        _character = char;
        _loading = false;
      });
      AppLogger.instance.info('[_loadCharacter] setState 完成，角色面板已刷新');
    } catch (e) {
      AppLogger.instance.error('[_loadCharacter] 加载角色异常: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
    if (_loading) {
      return const Scaffold(
        backgroundColor: DarkWuxiaColors.background,
        body: DarkWuxiaLoading(text: '正在读取江湖名册...'),
      );
    }
    if (_character == null) {
      AppLogger.instance.info('[build] 显示无角色视图');
      return _buildNoCharacterView();
    }

    final char = _character!;
    AppLogger.instance.info('[build] 显示角色主页: ${char.name}, 战力=${char.powerIndex}');
    final attrs = _parseAttributes(char.attributesJson);
    final maxHp = (attrs['body'] ?? 10) * char.level * 15;
    final maxIe = (attrs['con'] ?? 10) * char.level * 10;

    return Scaffold(
      backgroundColor: DarkWuxiaColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCharacterOverview(char, attrs, maxHp, maxIe),
            const SizedBox(height: 12),
            _buildBDArchetype(char),
            const SizedBox(height: 12),
            _buildFunctionGrid(),
            const SizedBox(height: 12),
            _buildBackpackOverview(),
          ],
        ),
      ),
    );
    } catch (e, stack) {
      AppLogger.instance.error('HomePage.build 崩溃: $e\n$stack');
      return const Scaffold(
        backgroundColor: DarkWuxiaColors.background,
        body: DarkWuxiaEmpty(text: '页面加载出错，请查看日志', icon: Icons.error_outline),
      );
    }
  }

  Widget _buildCharacterOverview(CharacterTableData char, Map<String, int> attrs, int maxHp, int maxIe) {
    return DarkWuxiaCard(
      padding: const EdgeInsets.all(16),
      borderColor: DarkWuxiaColors.darkGold,
      borderWidth: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: DarkWuxiaColors.darkGold, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(char.name,
                      style: const TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.bold, color: DarkWuxiaColors.darkGold)),
                    Text('${char.origin.isEmpty ? "江湖浪子" : char.origin} · 第${char.age}年',
                      style: const TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: DarkWuxiaColors.darkGold.withValues(alpha: 0.15),
                  border: Border.all(color: DarkWuxiaColors.darkGold, width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    const Text('战力', style: TextStyle(fontFamily: 'serif', fontSize: 10, color: DarkWuxiaColors.textSecondary)),
                    Text('${char.powerIndex}',
                      style: const TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.bold, color: DarkWuxiaColors.darkGold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          HealthBar.hp(current: char.health, max: maxHp),
          const SizedBox(height: 6),
          HealthBar.innerEnergy(current: char.innerEnergy, max: maxIe),
          const SizedBox(height: 12),
          const DarkWuxiaSectionTitle(text: '五维属性', icon: Icons.bar_chart),
          const SizedBox(height: 6),
          _buildAttributeBar('臂力', attrs['body'] ?? 0, DarkWuxiaColors.darkRedBright),
          _buildAttributeBar('身法', attrs['agi'] ?? 0, DarkWuxiaColors.innerEnergy),
          _buildAttributeBar('悟性', attrs['wis'] ?? 0, DarkWuxiaColors.darkGold),
          _buildAttributeBar('根骨', attrs['con'] ?? 0, DarkWuxiaColors.buffGreen),
          _buildAttributeBar('福缘', attrs['luck'] ?? 0, DarkWuxiaColors.darkGoldBright),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildInfoChip('等级', '${char.level}', DarkWuxiaColors.darkGold),
              const SizedBox(width: 12),
              _buildInfoChip('银两', '${char.silver}', DarkWuxiaColors.darkGoldBright),
              const SizedBox(width: 12),
              _buildInfoChip('名望', '${char.reputation}', DarkWuxiaColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          label == '银两' ? Icons.monetization_on : label == '等级' ? Icons.star : Icons.people,
          size: 16, color: color,
        ),
        const SizedBox(width: 4),
        Text('$label ', style: TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.textSecondary)),
        Text(value, style: TextStyle(fontFamily: 'serif', fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildAttributeBar(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          SizedBox(width: 32, child: Text(label, style: const TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textSecondary))),
          const SizedBox(width: 4),
          Expanded(
            child: LinearProgressIndicator(
              value: (value / 50).clamp(0.0, 1.0),
              backgroundColor: DarkWuxiaColors.elevated,
              color: color, minHeight: 6,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(width: 28, child: Text('$value', textAlign: TextAlign.right,
            style: TextStyle(fontFamily: 'serif', fontSize: 12, color: color, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildBDArchetype(CharacterTableData char) {
    return DarkWuxiaCard(
      padding: const EdgeInsets.all(12),
      borderColor: DarkWuxiaColors.darkRed,
      child: Row(
        children: [
          const Icon(Icons.auto_stories, color: DarkWuxiaColors.darkRed, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('武学流派', style: TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.textSecondary)),
                Text(char.heartMantra != null ? '心法流' : '杂学一路',
                  style: const TextStyle(fontFamily: 'serif', fontSize: 15, fontWeight: FontWeight.bold, color: DarkWuxiaColors.darkRed)),
                const Text('博采众长但不够精深，尚未形成明确流派。',
                  style: TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.textSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.person_outline, color: DarkWuxiaColors.darkGold),
            onPressed: () => context.push(RouteNames.character)),
        ],
      ),
    );
  }

  Widget _buildFunctionGrid() {
    final entries = <_FunctionEntry>[
      _FunctionEntry('秘境', Icons.explore, DarkWuxiaColors.darkRed, RouteNames.realm),
      _FunctionEntry('角色', Icons.person, DarkWuxiaColors.darkGold, RouteNames.character),
      _FunctionEntry('背包', Icons.inventory_2, DarkWuxiaColors.darkGold, RouteNames.inventory),
      _FunctionEntry('炼器', Icons.construction, DarkWuxiaColors.buffGreen, RouteNames.blacksmith),
      _FunctionEntry('客栈', Icons.local_hotel, DarkWuxiaColors.darkGoldBright, RouteNames.tavern),
      _FunctionEntry('掉落', Icons.history, DarkWuxiaColors.innerEnergy, RouteNames.dropHistory),
      _FunctionEntry('概率', Icons.percent, DarkWuxiaColors.textSecondary, RouteNames.odds),
      _FunctionEntry('设置', Icons.settings, DarkWuxiaColors.textHint, RouteNames.settings),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final e = entries[index];
        return GestureDetector(
          onTap: () => context.push(e.route),
          child: DarkWuxiaCard(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(e.icon, size: 28, color: e.color),
                const SizedBox(height: 4),
                Text(e.name, style: TextStyle(fontFamily: 'serif', fontSize: 11, color: e.color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackpackOverview() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadBackpackStats(),
      builder: (context, snapshot) {
        final count = snapshot.data?['count'] ?? 0;
        final isFull = snapshot.data?['isFull'] ?? false;
        return DarkWuxiaCard(
          padding: const EdgeInsets.all(12),
          borderColor: isFull ? DarkWuxiaColors.darkRedBright : null,
          child: Row(
            children: [
              const Icon(Icons.backpack, color: DarkWuxiaColors.darkGold, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('行囊', style: TextStyle(fontFamily: 'serif', fontSize: 14, fontWeight: FontWeight.bold, color: DarkWuxiaColors.darkGold)),
                    Text('$count / 500 件',
                      style: TextStyle(fontFamily: 'serif', fontSize: 12,
                        color: isFull ? DarkWuxiaColors.darkRedBright : DarkWuxiaColors.textSecondary)),
                  ],
                ),
              ),
              if (isFull)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: DarkWuxiaColors.darkRed.withValues(alpha: 0.2),
                    border: Border.all(color: DarkWuxiaColors.darkRed, width: 0.5)),
                  child: const Text('已满', style: TextStyle(fontSize: 10, color: DarkWuxiaColors.darkRedBright)),
                ),
              IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: () => context.push(RouteNames.inventory)),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadBackpackStats() async {
    try {
      final db = AppDatabase.instance;
      final count = await db.equipmentDao.equipmentCount();
      final isFull = await db.equipmentDao.isBagFull();
      return {'count': count, 'isFull': isFull};
    } catch (_) {
      return {'count': 0, 'isFull': false};
    }
  }

  Widget _buildNoCharacterView() {
    return Scaffold(
      backgroundColor: DarkWuxiaColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add, size: 64, color: DarkWuxiaColors.darkGold),
              const SizedBox(height: 16),
              const Text('踏入江湖',
                style: TextStyle(fontFamily: 'serif', fontSize: 28, fontWeight: FontWeight.bold, color: DarkWuxiaColors.darkGold, letterSpacing: 4)),
              const SizedBox(height: 8),
              const Text('江湖风雨起，英雄路不同。\n何不就此踏上江湖，书写属于你的武学传奇？',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'serif', fontSize: 14, color: DarkWuxiaColors.textSecondary, height: 1.8)),
              const SizedBox(height: 24),
              ElevatedButton.icon(onPressed: _createNewCharacter, icon: const Icon(Icons.create), label: const Text('创建角色')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createNewCharacter() async {
    final name = await _showNameDialog();
    if (name == null || name.trim().isEmpty) {
      AppLogger.instance.info('[_createNewCharacter] 用户取消了创建');
      setState(() { _loading = false; });
      return;
    }

    AppLogger.instance.info('[_createNewCharacter] 用户输入角色名: ${name.trim()}, 开始创建角色...');
    try {
      final db = AppDatabase.instance;
      final defaultAttrs = Attributes.defaultValues();
      await db.characterDao.createCharacter(
        name: name.trim(),
        origin: '江湖浪子',
        attributes: {
          'body': defaultAttrs.body, 'agi': defaultAttrs.agi,
          'wis': defaultAttrs.wis, 'con': defaultAttrs.con, 'luck': defaultAttrs.luck,
        },
        // health=100, innerEnergy=50, silver=100 是 createCharacter 默认值
      );
      AppLogger.instance.info('[_createNewCharacter] 角色创建完成，重新加载角色');
      _loadCharacter();
    } catch (e) {
      AppLogger.instance.error('[_createNewCharacter] 创建角色异常: $e');
      setState(() => _loading = false);
    }
  }

  /// 弹出输入名字的对话框，返回输入的名字或 null(取消)
  Future<String?> _showNameDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: DarkWuxiaColors.elevated,
          title: const Text('踏入江湖',
            style: TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.bold, color: DarkWuxiaColors.darkGold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('敢问少侠尊姓大名？',
                style: TextStyle(fontFamily: 'serif', fontSize: 14, color: DarkWuxiaColors.textSecondary)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 8,
                style: const TextStyle(fontFamily: 'serif', fontSize: 18, color: DarkWuxiaColors.textPrimary),
                decoration: InputDecoration(
                  hintText: '输入角色名',
                  hintStyle: TextStyle(fontFamily: 'serif', fontSize: 14, color: DarkWuxiaColors.textHint),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: DarkWuxiaColors.darkGold)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: DarkWuxiaColors.darkGold, width: 2)),
                ),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    Navigator.of(ctx).pop(v.trim());
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('取消', style: TextStyle(color: DarkWuxiaColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  Navigator.of(ctx).pop(text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DarkWuxiaColors.darkGold,
                foregroundColor: DarkWuxiaColors.background,
              ),
              child: const Text('创建'),
            ),
          ],
        );
      },
    );
  }

  Map<String, int> _parseAttributes(String json) {
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {'body': 10, 'agi': 10, 'wis': 10, 'con': 10, 'luck': 5};
    }
  }
}

class _FunctionEntry {
  final String name;
  final IconData icon;
  final Color color;
  final String route;
  const _FunctionEntry(this.name, this.icon, this.color, this.route);
}
