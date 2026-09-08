// =============================================================================
// realm_select_page.dart — 秘境选择
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';
import '../router.dart';
import 'exploration_page.dart';
import '../../database/database.dart';
import '../../database/daos/character_dao.dart';
import '../../models/enums.dart';
import '../../engine/config_loader.dart';
import '../../engine/providers.dart';
import '../../engine/realm_exploration_engine.dart';
import '../../utils/app_logger.dart';

class RealmSelectPage extends ConsumerStatefulWidget {
  const RealmSelectPage({super.key});
  @override
  ConsumerState<RealmSelectPage> createState() => _RealmSelectPageState();
}

class _RealmSelectPageState extends ConsumerState<RealmSelectPage> {
  List<RealmProgressTableData> _progress = [];
  bool _autoRun = false;
  Set<String> _cleared = {}; // 'realmId:difficulty'

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final db = AppDatabase.instance;
      final progress = await db.realmDao.getAllProgress();
      final autoRun = await db.settingsDao.getBool('auto_run_default');
      final clearedRaw = await db.settingsDao.getString('cleared_realms');
      if (mounted) {
        setState(() {
          _progress = progress;
          _autoRun = autoRun;
          _cleared = clearedRaw.isEmpty
              ? <String>{}
              : clearedRaw.split(',').where((s) => s.isNotEmpty).toSet();
        });
      }
    } catch (_) {
      // silently ignore
    }
  }

  RealmProgressTableData? _getProgress(String realmId) {
    try {
      return _progress.firstWhere((p) => p.realmId == realmId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
    // 监听 ConfigLoader 的异步加载状态
    final configAsync = ref.watch(configLoaderProvider);

    return configAsync.when(
      loading: () => const Scaffold(
        backgroundColor: DarkWuxiaColors.background,
        body: DarkWuxiaLoading(text: '秘境配置加载中...'),
      ),
      error: (err, stack) => DarkWuxiaScaffold(
        title: '秘境选择',
        body: Center(
          child: DarkWuxiaEmpty(
            text: '秘境配置加载失败',
            icon: Icons.error_outline,
          ),
        ),
      ),
      data: (config) {
        final realms = config.getRealms();
        if (realms.isEmpty) {
          return const DarkWuxiaScaffold(
            title: '秘境选择',
            body: Center(
              child: DarkWuxiaEmpty(
                text: '暂无秘境配置',
                icon: Icons.explore_off,
              ),
            ),
          );
        }
        return _buildRealmList(realms);
      },
    );
    } catch (e, stack) {
      AppLogger.instance.error('RealmSelectPage.build 崩溃: $e\n$stack');
      return const DarkWuxiaScaffold(
        title: '秘境选择',
        body: DarkWuxiaEmpty(text: '页面加载出错，请查看日志', icon: Icons.error_outline),
      );
    }
  }

  Widget _buildRealmList(List<RealmConfigEntry> realms) {
    return DarkWuxiaScaffold(
      title: '秘境选择',
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            const Icon(Icons.flash_on, color: DarkWuxiaColors.darkGold, size: 20),
            const SizedBox(width: 6),
            const Text('连刷模式',
                style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 14,
                    color: DarkWuxiaColors.textPrimary)),
            const Spacer(),
            Switch(
              value: _autoRun,
              onChanged: (v) => setState(() => _autoRun = v),
            ),
            const SizedBox(width: 8),
            Text(_autoRun ? '开启' : '关闭',
                style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 12,
                    color: _autoRun
                        ? DarkWuxiaColors.buffGreen
                        : DarkWuxiaColors.textSecondary)),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: realms.length,
            itemBuilder: (context, index) {
              final realm = realms[index];
              final progress = _getProgress(realm.id);
              return _RealmCard(
                realm: realm,
                progress: progress,
                autoRun: _autoRun,
                cleared: _cleared,
                onEnter: (difficulty) => _enterRealm(realm, difficulty),
              );
            },
          ),
        ),
      ]),
    );
  }

  void _enterRealm(RealmConfigEntry realm, int difficultyIndex) {
    final difficulty = Difficulty.values[difficultyIndex.clamp(0, Difficulty.values.length - 1)];
    // 连刷模式：直接进战斗页（碾压/正常档整场模拟，胜利结算掉落）
    if (_autoRun) {
      context.push(RouteNames.battle,
          extra: BattleRouteExtra(
            realmId: realm.id,
            difficultyIndex: difficultyIndex,
            isAutoRun: true,
          ));
      return;
    }
    // 探索模式：进秘境探索
    context.push(RouteNames.exploration,
        extra: ExplorationRouteExtra(
          realmId: realm.id,
          difficulty: difficulty,
        ));
  }
}

class _RealmCard extends StatelessWidget {
  final RealmConfigEntry realm;
  final RealmProgressTableData? progress;
  final bool autoRun;
  final Set<String> cleared;
  final ValueChanged<int> onEnter;

  const _RealmCard(
      {required this.realm,
      this.progress,
      required this.autoRun,
      required this.cleared,
      required this.onEnter});

  @override
  Widget build(BuildContext context) {
    final clearedLayers = progress?.currentLayer ?? 0;
    final dropCount = progress?.dropCount ?? 0;
    final enemyCount = progress?.enemyCount ?? 0;
    final hasProgress = clearedLayers > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: DarkWuxiaColors.surface,
        border: Border.all(
          color: hasProgress
              ? DarkWuxiaColors.darkGold.withValues(alpha: 0.5)
              : DarkWuxiaColors.divider,
          width: hasProgress ? 1 : 0.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        title: Row(children: [
          Icon(_realmIcon(realm.id), size: 24, color: DarkWuxiaColors.darkGold),
          const SizedBox(width: 8),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(realm.name,
                    style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: DarkWuxiaColors.darkGold)),
                Text(realm.description,
                    style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 11,
                        color: DarkWuxiaColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ])),
          if (hasProgress)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: DarkWuxiaColors.darkGold.withValues(alpha: 0.15),
                  border: Border.all(
                      color: DarkWuxiaColors.darkGold, width: 0.5)),
              child: Text('已通关 $clearedLayers层',
                  style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 10,
                      color: DarkWuxiaColors.darkGold)),
            ),
        ]),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(children: [
            Text('推荐战力 ${realm.recommendedPower}',
                style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 11,
                    color: _powerColor(realm.recommendedPower))),
            const SizedBox(width: 12),
            Text('击杀 $enemyCount',
                style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 11,
                    color: DarkWuxiaColors.textSecondary)),
            const SizedBox(width: 12),
            Text('掉落 $dropCount件',
                style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 11,
                    color: DarkWuxiaColors.textSecondary)),
          ]),
        ),
        children: [
          const SizedBox(height: 4),
          const Text('选择难度',
              style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 12,
                  color: DarkWuxiaColors.textSecondary)),
          const SizedBox(height: 8),
          Row(children: [
            ...List.generate(4, (i) {
              final name = ['普通', '困难', '地狱', '炼狱'][i];
              final difficulty = Difficulty.values[i];
              final unlocked = RealmUnlockManager.isUnlocked(
                realmId: realm.id,
                difficulty: difficulty,
                cleared: cleared,
              );
              final color = [
                DarkWuxiaColors.textSecondary,
                DarkWuxiaColors.buffGreen,
                DarkWuxiaColors.darkGold,
                DarkWuxiaColors.darkRedBright
              ][i];
              return Expanded(
                  child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: unlocked
                        ? color.withValues(alpha: 0.15)
                        : DarkWuxiaColors.divider,
                    foregroundColor: unlocked ? color : DarkWuxiaColors.textHint,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: unlocked ? () => onEnter(i) : null,
                  child: Text(unlocked ? name : '$name 🔒',
                      style: const TextStyle(
                          fontFamily: 'serif', fontSize: 13)),
                ),
              ));
            }),
          ]),
        ],
      ),
    );
  }

  IconData _realmIcon(String id) {
    switch (id) {
      case 'green_mountain':
        return Icons.terrain;
      case 'blood_valley':
        return Icons.bloodtype;
      case 'ice_palace':
        return Icons.ac_unit;
      case 'demon_tomb':
        return Icons.church;
      case 'sword_tower':
        return Icons.castle;
      case 'dragon_cave':
        return Icons.holiday_village;
      default:
        return Icons.explore;
    }
  }

  Color _powerColor(int power) {
    if (power < 500) return DarkWuxiaColors.textSecondary;
    if (power < 1500) return DarkWuxiaColors.buffGreen;
    if (power < 3000) return DarkWuxiaColors.darkGold;
    if (power < 6000) return DarkWuxiaColors.darkRedBright;
    return DarkWuxiaColors.darkRed;
  }
}