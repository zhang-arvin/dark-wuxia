// =============================================================================
// tavern_page.dart — 客栈
//
// 对应 DESIGN.md 3.8 城镇枢纽 — 客栈功能
//   - 回城休整(恢复生命/内力/清除真气逆行)
//   - 天机阁赌博(D2式: 花100银两随机一个装备，可能出暗金)
//   - 定心丹购买(压制真气逆行)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';
import '../router.dart';
import '../widgets/quality_chip.dart';
import '../widgets/drop_flash.dart';
import '../../database/database.dart';
import '../../models/enums.dart';
import '../../utils/app_logger.dart';

class TavernPage extends ConsumerStatefulWidget {
  const TavernPage({super.key});

  @override
  ConsumerState<TavernPage> createState() => _TavernPageState();
}

class _TavernPageState extends ConsumerState<TavernPage> {
  int _silver = 0;
  int _health = 0;
  int _maxHp = 100;
  int _innerEnergy = 0;
  int _maxIe = 50;
  bool _qiDeviation = false;
  int _calmingPills = 0;

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
      if (char != null) {
        _silver = char.silver;
        _health = char.health;
        _innerEnergy = char.innerEnergy;
        _qiDeviation = (await db.characterDao.getQiDeviation()) > 0;
      }
      _calmingPills = await db.settingsDao.getInt('calming_pills') ?? 0;
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    try {
    return DarkWuxiaScaffold(
      title: '客栈',
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
      body: _loading
          ? const DarkWuxiaLoading()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRestCard(),
                  const SizedBox(height: 12),
                  _buildGamblingCard(),
                  const SizedBox(height: 12),
                  _buildCalmingPillCard(),
                ],
              ),
            ),
    );
    } catch (e, stack) {
      AppLogger.instance.error('TavernPage.build 崩溃: $e\n$stack');
      return const DarkWuxiaScaffold(
        title: '客栈',
        body: DarkWuxiaEmpty(text: '页面加载出错，请查看日志', icon: Icons.error_outline),
      );
    }
  }

  // --- 回城休整 ---
  Widget _buildRestCard() {
    final needRest = _health < _maxHp || _innerEnergy < _maxIe || _qiDeviation;

    return DarkWuxiaCard(
      borderColor: DarkWuxiaColors.buffGreen,
      borderWidth: needRest ? 1 : 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bedtime, color: DarkWuxiaColors.buffGreen, size: 24),
              SizedBox(width: 8),
              Text(
                '回城休整',
                style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: DarkWuxiaColors.buffGreen),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '在客栈安歇一夜，恢复全部生命与内力，并清除真气逆行状态。',
            style: TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 8),

          // 当前状态
          if (needRest) ...[
            if (_health < _maxHp)
              _buildStatusRow('生命', '$_health/$_maxHp', DarkWuxiaColors.darkRedBright),
            if (_innerEnergy < _maxIe)
              _buildStatusRow('内力', '$_innerEnergy/$_maxIe', DarkWuxiaColors.innerEnergy),
            if (_qiDeviation)
              _buildStatusRow('真气逆行', '已触发', DarkWuxiaColors.darkRed),
          ] else
            const Row(
              children: [
                Icon(Icons.check_circle, color: DarkWuxiaColors.buffGreen, size: 16),
                SizedBox(width: 4),
                Text('气血充盈，无需休整', style: TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.buffGreen)),
              ],
            ),

          const SizedBox(height: 8),
          // 休整按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: needRest ? _doRest : null,
              icon: const Icon(Icons.bedtime),
              label: const Text('休整'),
              style: ElevatedButton.styleFrom(backgroundColor: DarkWuxiaColors.buffGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: const TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textSecondary)),
          ),
          Text(value, style: TextStyle(fontFamily: 'serif', fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Future<void> _doRest() async {
    try {
      final db = AppDatabase.instance;
      // 恢复生命/内力到满
      await db.characterDao.updateHealth(_maxHp);
      await db.characterDao.updateInnerEnergy(_maxIe);
      // 清除真气逆行
      if (_qiDeviation) {
        await db.characterDao.clearQiDeviation();
      }
      _showMsg('休整完毕，气血充盈，内力回满。');
      _loadData();
    } catch (e) {
      _showMsg('休整失败: $e');
    }
  }

  // --- 天机阁赌博 ---
  Widget _buildGamblingCard() {
    return DarkWuxiaCard(
      borderColor: DarkWuxiaColors.darkGold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.casino, color: DarkWuxiaColors.darkGold, size: 24),
              SizedBox(width: 8),
              Text(
                '天机阁 · 神宝抽选',
                style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: DarkWuxiaColors.darkGold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '花费 100 银两，随机获得一件装备。\n运气好的话，可能抽到暗金甚至神品！',
            style: TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 8),
          // 概率简示
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  QualityChip(quality: Quality.normal, compact: true),
                  Text('55%', style: TextStyle(fontSize: 11, color: DarkWuxiaColors.textSecondary)),
                ],
              ),
              Column(
                children: [
                  QualityChip(quality: Quality.magic, compact: true),
                  Text('28%', style: TextStyle(fontSize: 11, color: DarkWuxiaColors.textSecondary)),
                ],
              ),
              Column(
                children: [
                  QualityChip(quality: Quality.rare, compact: true),
                  Text('12%', style: TextStyle(fontSize: 11, color: DarkWuxiaColors.textSecondary)),
                ],
              ),
              Column(
                children: [
                  QualityChip(quality: Quality.unique, compact: true),
                  Text('3%', style: TextStyle(fontSize: 11, color: DarkWuxiaColors.darkGold)),
                ],
              ),
              Column(
                children: [
                  QualityChip(quality: Quality.divine, compact: true),
                  Text('0.5%', style: TextStyle(fontSize: 11, color: DarkWuxiaColors.darkGold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _silver >= 100 ? _doGamble : null,
              icon: const Icon(Icons.casino),
              label: const Text('抽选 (100 银两)'),
              style: ElevatedButton.styleFrom(backgroundColor: DarkWuxiaColors.darkGold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doGamble() async {
    if (_silver < 100) return;

    try {
      final db = AppDatabase.instance;

      // 扣银两
      await db.characterDao.addSilver(-100);

      // 随机品质（按概率）
      final roll = (DateTime.now().millisecondsSinceEpoch % 1000) / 10.0;
      Quality quality;
      if (roll < 55) {
        quality = Quality.normal;
      } else if (roll < 83) {
        quality = Quality.magic;
      } else if (roll < 95) {
        quality = Quality.rare;
      } else if (roll < 98.5) {
        quality = Quality.unique;
      } else if (roll < 99.5) {
        quality = Quality.divine;
      } else {
        quality = Quality.legendary;
      }

      // 生成装备
      final name = _randomName(quality);
      await db.equipmentDao.create(
        baseId: 'gamble_${quality.name}',
        quality: quality.name,
        slot: 'weapon',
        name: name,
        affixesJson: '[]',
        reinforceLevel: 0,
        itemLevel: 10,
      );

      // 显示掉落闪光动画
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => DropFlashOverlay(
            quality: quality,
            equipmentName: name,
            onDismiss: () => Navigator.pop(ctx),
          ),
        );
      }

      _loadData();
    } catch (e) {
      _showMsg('抽选失败: $e');
    }
  }

  String _randomName(Quality quality) {
    final adjectives = ['玄铁', '寒冰', '烈焰', '清风', '紫雷', '幽冥', '天罡', '昆仑'];
    final nouns = ['剑', '刀', '枪', '棍', '掌套', '护腕', '腰带', '玉佩'];
    final adj = adjectives[DateTime.now().millisecond % adjectives.length];
    final noun = nouns[(DateTime.now().second) % nouns.length];
    return '$adj$noun';
  }

  // --- 定心丹 ---
  Widget _buildCalmingPillCard() {
    return DarkWuxiaCard(
      borderColor: DarkWuxiaColors.innerEnergy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.healing, color: DarkWuxiaColors.innerEnergy, size: 24),
              SizedBox(width: 8),
              Text(
                '定心丹',
                style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: DarkWuxiaColors.innerEnergy),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '服用定心丹可压制真气逆行，防止修炼走火入魔。\n每颗 50 银两，持有数: 0',
            style: TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 4),
          if (_qiDeviation)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: DarkWuxiaColors.darkRed.withValues(alpha: 0.15),
                border: Border.all(color: DarkWuxiaColors.darkRed, width: 0.5),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: DarkWuxiaColors.darkRedBright, size: 16),
                  SizedBox(width: 4),
                  Text('当前已触发真气逆行！', style: TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.darkRedBright)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _silver >= 50 ? _buyCalmingPill : null,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('购买 (50 银两)'),
                  style: ElevatedButton.styleFrom(backgroundColor: DarkWuxiaColors.innerEnergy),
                ),
              ),
              if (_qiDeviation) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _calmingPills > 0 ? _useCalmingPill : null,
                  icon: const Icon(Icons.medication),
                  label: const Text('服用'),
                  style: ElevatedButton.styleFrom(backgroundColor: DarkWuxiaColors.buffGreen),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _buyCalmingPill() async {
    if (_silver < 50) return;
    try {
      final db = AppDatabase.instance;
      await db.characterDao.addSilver(-50);
      final newCount = _calmingPills + 1;
      await db.settingsDao.setInt('calming_pills', newCount);
      _showMsg('购买定心丹 x1');
      _loadData();
    } catch (e) {
      _showMsg('购买失败: $e');
    }
  }

  Future<void> _useCalmingPill() async {
    if (_calmingPills <= 0) return;
    try {
      final db = AppDatabase.instance;
      await db.characterDao.clearQiDeviation();
      final newCount = _calmingPills - 1;
      await db.settingsDao.setInt('calming_pills', newCount);
      _showMsg('真气逆行已压制。');
      _loadData();
    } catch (e) {
      _showMsg('服用失败: $e');
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: DarkWuxiaColors.elevated),
    );
  }
}
