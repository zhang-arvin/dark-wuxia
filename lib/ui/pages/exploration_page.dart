// =============================================================================
// exploration_page.dart — 秘境探索页（20-30步抉择制）
//
// 依据 REALM_DESIGN_V2.md：
//   每秘境 20-30 步，节点类型随机（战斗/抉择/机关/营地/宝箱/奇遇）
//   Boss 固定最后一步，通关后按难度递推解锁
// =============================================================================

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';
import '../router.dart';
import '../../database/database.dart';
import '../../database/daos/character_dao.dart';
import '../../database/daos/loot_persistence.dart';
import '../../models/enums.dart';
import '../../engine/drop_engine.dart' show DropResult;
import '../../engine/providers.dart';
import '../../models/session_mods.dart';
import '../../engine/realm_exploration_engine.dart';
import '../../utils/app_logger.dart';

/// 探索页路由参数
class ExplorationRouteExtra {
  final String realmId;
  final Difficulty difficulty;
  const ExplorationRouteExtra({required this.realmId, required this.difficulty});
}

class ExplorationPage extends ConsumerStatefulWidget {
  final ExplorationRouteExtra? extra;
  const ExplorationPage({super.key, this.extra});

  @override
  ConsumerState<ExplorationPage> createState() => _ExplorationPageState();
}

class _ExplorationPageState extends ConsumerState<ExplorationPage> {
  final Random _rng = Random();
  late RealmExplorationEngine _engine;

  List<ExplorationNode> _nodes = [];
  int _currentIndex = 0;
  bool _loading = true;
  bool _complete = false;
  bool _failed = false;

  // 角色临时HP/IE（营地恢复、机关扣血）
  int _hp = 0;
  int _maxHp = 100;
  int _ie = 0;
  int _maxIe = 50;
  int _silver = 0;

  // 本次探索收益
  int _gainedSilver = 0;
  int _kills = 0;

  // 会话收益池：战斗掉落的延迟结算（撤离/通关才写库，失败作废）
  final List<DropResult> _sessionDrops = [];
  final List<String> _sessionLootLog = [];

  // 模块 3：会话修正（开局随机模组 + 每 5 步 Buff 三选）
  SessionMods _mods = const SessionMods();
  final List<SessionBuffType> _ownedBuffs = [];

  // 复活流程进行中（防重入：复活弹窗异步期间禁止再次触发）
  bool _revivePending = false;

  final List<String> _log = [];

  // 通关信息
  bool _firstClear = false;
  int _reward = 0;

  @override
  void initState() {
    super.initState();
    _engine = RealmExplorationEngine(_rng);
    _start();
  }

  Future<void> _start() async {
    try {
      final config = ref.read(configLoaderProvider).valueOrNull;
      final realmId = widget.extra?.realmId ?? 'realm_gumu';
      final difficulty = widget.extra?.difficulty ?? Difficulty.normal;
      final realm = config?.getRealm(realmId);

      // 读取角色
      final db = AppDatabase.instance;
      final char = await db.characterDao.getCharacter();
      final attrs = char != null ? CharacterDao.parseAttributes(char) : const <String, int>{};
      final body = attrs['body'] ?? 10;
      final con = attrs['con'] ?? 10;
      _maxHp = body * (char?.level ?? 1) * 15;
      _maxIe = con * (char?.level ?? 1) * 10;
      _hp = char?.health ?? _maxHp;
      _ie = char?.innerEnergy ?? _maxIe;
      _silver = char?.silver ?? 0;

      // 生成路径
      final eliteIds = (realm?.enemyPool ?? const [])
          .where((id) => id.startsWith('elite_'))
          .toList();
      final normalIds = (realm?.enemyPool ?? const [])
          .where((id) => !id.startsWith('elite_'))
          .toList();
      final path = _engine.generatePath(
        difficulty: difficulty,
        enemyPool: normalIds,
        elitePool: eliteIds,
        bossId: realm?.bossId ?? '',
      );

      // 模块 3：开局随机秘境模组（50% 概率，采不中则无模组）
      final modTypes = RealmModifierType.values;
      final rolled = _rng.nextInt(100) < 50 ? modTypes[_rng.nextInt(modTypes.length)] : null;
      _mods = SessionMods(modifier: rolled);

      // 新手引导：首次探索时在日志区展示核心规则（设置标记避免重复）
      final tutorialSeen = await db.settingsDao.getBool('tutorial_seen_dark_wuxia');

      setState(() {
        _nodes = path;
        _loading = false;
        if (path.isNotEmpty) _log.add('踏入${realm?.name ?? '秘境'}（${difficulty.displayName}），前方共${path.length}步。');
        if (rolled != null) {
          _log.add('【${rolled.displayName}】${rolled.description}');
        }
        if (!tutorialSeen) {
          _log.add('⚠️ 秘境规矩一：战斗倒下则本次秘境收益尽数作废，请谨慎应敌。');
          _log.add('⚔️ 秘境规矩二：可随时点「撤离秘境」结算已有收益，见好就收。');
          _log.add('🐉 秘境规矩三：关卡末路有 Boss 镇守，战败同失败处理，量力而行。');
        }
      });

      // 标记新手引导已读（fire-and-forget）
      if (!tutorialSeen) {
        db.settingsDao.setBool('tutorial_seen_dark_wuxia', true);
      }
    } catch (e) {
      AppLogger.instance.error('ExplorationPage._start 失败: $e');
      setState(() { _loading = false; _failed = true; });
    }
  }

  // ==================== 节点交互 ====================

  /// 战斗节点 → 跳转现有战斗页
  void _handleBattle(ExplorationNode node) {
    final realmId = widget.extra?.realmId ?? 'realm_gumu';
    final difficulty = widget.extra?.difficulty ?? Difficulty.normal;
    if (node.enemyId == null && !node.isBoss) {
      _advance();
      return;
    }
    // 复用 battle_page（真回合制战斗UI），传 enemyId 确保 Boss/节点敌人正确
    context.push(RouteNames.battle, extra: BattleRouteExtra(
      realmId: realmId,
      difficultyIndex: difficulty.index,
      isAutoRun: false,
      enemyId: node.enemyId,
      mods: _mods.isEmpty ? null : _mods,
    )).then((result) {
      final exit = result as BattleExitResult?;
      if (exit == null) {
        // 战斗页未给出结果（如 loading 时直接退出）= 未发生战斗，仅刷新
        _refreshCharacterState();
        return;
      }
      if (exit.retreated) {
        // 主动撤退：战斗作废但不算失败，留在当前节点可再挑战
        _refreshCharacterState();
        setState(() {
          _log.add('你从容撤离这场战斗，喘息未定...');
        });
        return;
      }
      if (!exit.victory) {
        // 战败：气血惩罚已写库（战斗页内），本次秘境收益全部作废
        _markFailed(leaveLoot: true);
        return;
      }
      // 战胜：掉落进入会话收益池（延迟结算），继续深入
      _sessionDrops.addAll(exit.drops);
      _refreshCharacterState();
      setState(() {
        _kills++;
        _log.add(node.isBoss
            ? 'Boss已倒在你的剑下！'
            : '击败强敌，继续深入。');
        if (exit.drops.isNotEmpty) {
          for (final d in exit.drops) {
            _sessionLootLog.add('获得 [${d.equipment.quality.displayName}] ${d.equipment.name}');
          }
        }
      });
      _advance();
    });
  }

  Future<void> _refreshCharacterState() async {
    try {
      final char = await AppDatabase.instance.characterDao.getCharacter();
      if (char != null && mounted) {
        setState(() {
          _hp = char.health;
          _ie = char.innerEnergy;
          _silver = char.silver;
        });
      }
    } catch (_) {}
  }

  void _handleChoice(ExplorationNode node) {
    // 岔路口：右=冒险 50%宝箱/50%扣血（引擎判定）
    if (node.type == ExplorationNodeType.choice) {
      final adventure = _engine.rollAdventure();
      setState(() {
        int dmg = 0;
        if (adventure) {
          dmg = (_maxHp * 0.2).round();
          _hp = max(0, _hp - dmg);
          _log.add('崖底凶险，你受了伤（-${dmg}生命）。');
        } else {
          _log.add('崖底果然藏宝，你寻得一件装备！（已入行囊设想）');
          _gainedSilver += 100;
        }
      });
      // 气血变化写回 DB（气血连锁：探索遭遇同样留伤）
      _persistExplorationHp();
      if (_hp <= 0) { _markFailed(); return; }
    }
    _advance();
  }

  void _handleTrap(ExplorationNode node, bool careful) {
    setState(() {
      if (careful) {
        final dodge = _rng.nextDouble() < 0.6; // 身法六成躲过
        if (dodge) {
          _log.add('你轻身闪过机关，毫发无伤。');
        } else {
          final dmg = (_maxHp * 0.3).round();
          _hp = max(0, _hp - dmg);
          _log.add('机关暗箭迅疾，未能完全躲开（-${dmg}生命）。');
        }
      } else {
        final dmg = (_maxHp * 0.2).round();
        _hp = max(0, _hp - dmg);
        final silver = 100 + _rng.nextInt(200);
        _gainedSilver += silver;
        _log.add('你硬闯而过（-${dmg}生命），顺手拾得$silver两银子。');
      }
    });
    // 气血变化写回 DB
    _persistExplorationHp();
    if (_hp <= 0) { _markFailed(); return; }
    _advance();
  }

  void _handleCamp(ExplorationNode node, bool rest) {
    setState(() {
      if (rest) {
        _hp = _maxHp;
        _ie = _maxIe;
        _log.add('于营地歇息一夜，气血恢复充盈。');
      } else {
        final silver = 80 + _rng.nextInt(120);
        _gainedSilver += silver;
        _log.add('你顺走了营地的盘缠，得$silver两银子。');
      }
    });
    // 营地恢复/内力变化写回 DB
    _persistExplorationHp();
    _advance();
  }

  /// 将探索页内存态气血写回 DB（气血连锁：探索遭遇的伤同样持久化）
  Future<void> _persistExplorationHp() async {
    try {
      final db = AppDatabase.instance;
      await db.characterDao.updateHealth(_hp);
      await db.characterDao.updateInnerEnergy(_ie);
    } catch (e) {
      AppLogger.instance.error('_persistExplorationHp 失败: $e');
    }
  }

  void _handleTreasure() {
    setState(() {
      _log.add('宝箱开启，宝物已收入行囊。（装备掉落见战斗掉落记录）');
      _gainedSilver += 50;
    });
    // 简化：宝箱给一件掉落（后续接入DropEngine）
    _advance();
  }

  void _handleEvent(ExplorationNode node) {
    setState(() {
      final silver = node.rewardSilver ?? (50 + _rng.nextInt(150));
      _gainedSilver += silver;
      _log.add('${node.description.isEmpty ? '奇遇' : node.description}——小有所获（+$silver两）。');
    });
    _advance();
  }

  void _advance() {
    if (_currentIndex >= _nodes.length - 1) {
      _completeRealm();
      return;
    }
    setState(() => _currentIndex++);
    // 模块 3：每 5 步触发一轮 Buff 三选（异步弹窗不阻塞推进）
    if ((_currentIndex + 1) % 5 == 0 &&
        !_offerBuffPending &&
        _ownedBuffs.length < 3) {
      _maybeOfferBuff();
    }
  }

  // Buff 三选弹窗防重入
  bool _offerBuffPending = false;

  /// 每 5 步的 Buff 三选（模块 3）：从 3 个随机候选中挑 1，叠加进会话修正
  Future<void> _maybeOfferBuff() async {
    _offerBuffPending = true;
    try {
      // 从未选过的 Buff 类型中抽 3 个候选（不够 3 个则全上）
      final owned = _ownedBuffs.toSet();
      final available =
          SessionBuffType.values.where((b) => !owned.contains(b)).toList()
            ..shuffle(_rng);
      final candidates = available.take(3).toList();
      if (candidates.isEmpty) return;

      final picked = await showModalBottomSheet<SessionBuffType>(
        context: context,
        backgroundColor: DarkWuxiaColors.elevated,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('✨ 灵光一现，择一傍身',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: DarkWuxiaColors.darkGold)),
              const SizedBox(height: 4),
              const Text('本局生效，可叠加三层',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 11,
                      color: DarkWuxiaColors.textSecondary)),
              const SizedBox(height: 12),
              ...candidates.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _actionButton(
                      '${b.displayName} — ${b.description}',
                      () => Navigator.of(ctx).pop(b),
                    ),
                  )),
            ],
          ),
        ),
      );
      if (picked != null && mounted) {
        setState(() {
          _ownedBuffs.add(picked);
          _mods = _mods.withBuff(picked);
          _log.add('获得 Buff【${picked.displayName}】${picked.description}');
        });
      }
    } finally {
      _offerBuffPending = false;
    }
  }

  Future<void> _completeRealm() async {
    final realmId = widget.extra?.realmId ?? 'realm_gumu';
    final difficulty = widget.extra?.difficulty ?? Difficulty.normal;
    try {
      final db = AppDatabase.instance;
      // 已通关集合
      final clearedRaw = await db.settingsDao.getString('cleared_realms');
      final cleared = clearedRaw.isEmpty
          ? <String>{}
          : clearedRaw.split(',').toSet();
      final firstClear = !cleared.contains('$realmId:${difficulty.name}');
      final (reward, isFirst) = RealmUnlockManager.completionReward(
        difficulty: difficulty, firstClear: firstClear);

      if (firstClear) {
        cleared.add('$realmId:${difficulty.name}');
        await db.settingsDao.setString('cleared_realms', cleared.join(','));
      }
      final totalSilver = reward + _gainedSilver;
      if (totalSilver > 0) await db.characterDao.addSilver(totalSilver);

      // 结算会话掉落（通关=第二个结算点）
      if (_sessionDrops.isNotEmpty) {
        await LootPersistence.persistDrops(
          _sessionDrops,
          ref.read(configLoaderProvider).valueOrNull,
        );
      }

      setState(() {
        _complete = true;
        _firstClear = isFirst;
        _reward = reward;
        _silver += totalSilver;
        _log.add('\n秘境通关！');
        if (isFirst) {
          _log.add('首次通关奖励：$reward两银子 + 保底上品装备 + 福缘+2。');
          _log.add('${difficulty.displayName}难度已解锁下一难度。');
        } else {
          _log.add('再次通关奖励：$reward两银子。');
        }
      });
    } catch (e) {
      AppLogger.instance.error('_completeRealm 失败: $e');
      setState(() { _complete = true; _reward = 0; _firstClear = false; });
    }
  }

  /// 失败处理：先尝试广告复活，拒绝才真正失败
  ///
  /// 模块 2「广告复活」：每日 3 次，看广告成功 → HP 回 50%，
  /// 收益池保留、_failed 不置位、从当前节点继续。
  Future<void> _markFailed({bool leaveLoot = false}) async {
    if (_revivePending) return; // 复活流程进行中，防重入
    _revivePending = true;
    try {
      final adService = ref.read(adServiceProvider);
      final left = await adService.dailyRevivesLeft();
      if (!mounted) return;

    // 有复活机会 → 弹复活确认
    if (left > 0) {
      final revived = await _showReviveDialog(left);
      if (!mounted) return;
      if (revived) {
        final watched = await adService.showRewardedAd();
        if (!mounted) return;
        if (watched) {
          final remaining = await adService.consumeRevive();
          if (!mounted) return;
          setState(() {
            // HP 回 50%（不低于当前值）
            _hp = (_hp < _maxHp ~/ 2) ? _maxHp ~/ 2 : _hp;
            _log.add('⚠ 你从鬼门关醒了回来（HP恢复50%），今日还剩$remaining次复活。');
          });
          await _persistExplorationHp();
          return; // 未失败，留在原地
        }
      }
    }

    setState(() {
      _failed = true;
      _log.add(leaveLoot
          ? '你身负重伤，只得退出秘境。（本次所得尽数遗落）'
          : '你身负重伤，只得退出秘境。');
      if (left <= 0) _log.add('（今日复活次数已用完）');
    });
    } finally {
      _revivePending = false;
    }
  }

  /// 复活确认弹窗：返回用户是否选择看广告
  Future<bool> _showReviveDialog(int left) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: DarkWuxiaColors.elevated,
        title: const Text('气血衰竭',
            style: TextStyle(
                fontFamily: 'serif',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: DarkWuxiaColors.darkRedBright)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('你身负重伤，本次秘境所得即将作废……',
                style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 14,
                    color: DarkWuxiaColors.textPrimary)),
            const SizedBox(height: 10),
            Text('看一段广告即可保住收益，气血恢复 50%。今日剩余 $left 次。',
                style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 13,
                    color: DarkWuxiaColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('放弃收益',
                style: TextStyle(color: DarkWuxiaColors.textHint)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DarkWuxiaColors.darkGold.withValues(alpha: 0.3),
              foregroundColor: DarkWuxiaColors.darkGoldBright,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('看广告复活'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// 撤离秘境：结算本次会话收益（掉落写库+银两入账），返回秘境列表
  Future<void> _retreatFromRealm() async {
    try {
      final db = AppDatabase.instance;
      if (_gainedSilver > 0) await db.characterDao.addSilver(_gainedSilver);
      if (_sessionDrops.isNotEmpty) {
        await LootPersistence.persistDrops(
          _sessionDrops,
          ref.read(configLoaderProvider).valueOrNull,
        );
      }
      if (mounted) {
        setState(() {
          _log.add('\n你带走了本次所得，安然撤离秘境。');
          if (_sessionDrops.isNotEmpty) {
            _log.add('带走装备 ${_sessionDrops.length} 件（已入行囊）。');
          }
        });
        // 短暂展示结算结果后返回
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted && context.canPop()) context.pop();
      }
    } catch (e) {
      AppLogger.instance.error('_retreatFromRealm 失败: $e');
      if (mounted && context.canPop()) context.pop();
    }
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    return DarkWuxiaScaffold(
      title: '秘境探索',
      body: _loading
          ? const DarkWuxiaLoading(text: '正在踏入秘境...')
          : _failed
              ? _buildEndPanel(false)
              : _complete
                  ? _buildEndPanel(true)
                  : _buildExplorationView(),
    );
  }

  Widget _buildExplorationView() {
    if (_nodes.isEmpty) return const DarkWuxiaEmpty(text: '暂无路径');
    final node = _nodes[_currentIndex];
    final total = _nodes.length;

    return Column(children: [
      // 进度条
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Row(children: [
          Text('第 ${_currentIndex + 1}/$total 步',
            style: const TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textSecondary)),
          const Spacer(),
          Text('生命 $_hp/$_maxHp · 内力 $_ie/$_maxIe · 银两 $_silver',
            style: const TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.innerEnergy)),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: LinearProgressIndicator(
          value: (_currentIndex + 1) / total,
          backgroundColor: DarkWuxiaColors.divider,
          valueColor: const AlwaysStoppedAnimation(DarkWuxiaColors.darkGold),
        ),
      ),
      // 滚动区
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // 节点卡片
          DarkWuxiaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(node.isBoss ? '⚔️ Boss' : '📍 ${node.type.displayName}',
                style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.bold,
                  color: node.isBoss ? DarkWuxiaColors.darkRedBright : DarkWuxiaColors.darkGold)),
              if (node.isBoss) ...[
                const Spacer(),
                const Text('最终一战', style: TextStyle(fontSize: 11, color: DarkWuxiaColors.darkRedBright)),
              ],
            ]),
            const SizedBox(height: 8),
            Text(node.description.isEmpty ? node.title : node.description,
              style: const TextStyle(fontFamily: 'serif', fontSize: 14, color: DarkWuxiaColors.textPrimary, height: 1.6)),
          ])),
          const SizedBox(height: 12),
          // 节点交互区
          ..._buildNodeActions(node),
          const SizedBox(height: 12),
          // 探索日志
          if (_log.isNotEmpty)
            DarkWuxiaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const DarkWuxiaSectionTitle(text: '探索日志'),
              const SizedBox(height: 6),
              ..._log.reversed.take(6).map((line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(line,
                  style: const TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textSecondary)),
              )),
            ])),
          const SizedBox(height: 12),
          // 撤离按钮（正确收手唯一结算点）
          _actionButton('撤离秘境（结算本次收益）', _retreatFromRealm),
        ]),
      )),
    ]);
  }

  List<Widget> _buildNodeActions(ExplorationNode node) {
    switch (node.type) {
      case ExplorationNodeType.battle:
        return [_actionButton(node.isBoss ? '迎战Boss' : '迎战', () => _handleBattle(node), dark: node.isBoss)];
      case ExplorationNodeType.treasure:
        return [_actionButton('打开宝箱', _handleTreasure)];
      case ExplorationNodeType.camp:
        return [
          _actionButton(node.optionA ?? '休息恢复', () => _handleCamp(node, true)),
          const SizedBox(height: 6),
          _actionButton(node.optionB ?? '搜刮营地', () => _handleCamp(node, false)),
        ];
      case ExplorationNodeType.trap:
      case ExplorationNodeType.choice:
        return [
          _actionButton(node.optionA ?? '保守选择', () =>
              node.type == ExplorationNodeType.trap ? _handleTrap(node, true) : _handleChoice(node)),
          const SizedBox(height: 6),
          _actionButton(node.optionB ?? '冒险选择', () =>
              node.type == ExplorationNodeType.trap ? _handleTrap(node, false) : _handleChoice(node)),
        ];
      case ExplorationNodeType.event:
        return [_actionButton('一探究竟', () => _handleEvent(node))];
    }
  }

  Widget _actionButton(String label, VoidCallback onTap, {bool dark = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: dark
              ? DarkWuxiaColors.darkRed.withValues(alpha: 0.2)
              : DarkWuxiaColors.darkGold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: dark ? DarkWuxiaColors.darkRed : DarkWuxiaColors.darkGold, width: 0.6),
        ),
        child: Center(child: Text(label,
          style: TextStyle(fontFamily: 'serif', fontSize: 14, fontWeight: FontWeight.bold,
            color: dark ? DarkWuxiaColors.darkRedBright : DarkWuxiaColors.darkGold))),
      ),
    );
  }

  Widget _buildEndPanel(bool victory) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Icon(victory ? Icons.emoji_events : Icons.local_hospital,
          size: 64, color: victory ? DarkWuxiaColors.darkGold : DarkWuxiaColors.darkRedBright),
        const SizedBox(height: 16),
        Text(victory ? '秘境通关' : '重伤而归',
          style: const TextStyle(fontFamily: 'serif', fontSize: 24, fontWeight: FontWeight.bold, color: DarkWuxiaColors.darkGold)),
        const SizedBox(height: 8),
        if (victory) ...[
          Text(_firstClear ? '首次通关！' : '通关成功',
            style: const TextStyle(fontFamily: 'serif', fontSize: 14, color: DarkWuxiaColors.textPrimary)),
          const SizedBox(height: 8),
          Text('奖励：$_reward 两银子${_gainedSilver > 0 ? ' + 探索所得$_gainedSilver两' : ''}',
            style: const TextStyle(fontFamily: 'serif', fontSize: 14, color: DarkWuxiaColors.innerEnergy)),
          const SizedBox(height: 4),
          Text('击杀：$_kills',
            style: const TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textSecondary)),
        ],
        const SizedBox(height: 24),
        _actionButton('返回秘境列表', () => context.pop()),
      ]),
    );
  }
}