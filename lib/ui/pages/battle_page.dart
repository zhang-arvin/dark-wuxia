// =============================================================================
// battle_page.dart — 战斗页面
//
// 已接入真实 BattleEngine，替换 mock 数据。
// 通过 ref.read(battleEngineSyncProvider) 获取引擎实例，
// 从 AppDatabase 读取角色，从 BattleRouteExtra + ConfigLoader 读取秘境/敌人，
// 调用 BattleEngine.executeBattle() 执行真实战斗。
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dart:async';
import 'dart:math' show sin, pi;

import '../theme.dart';
import '../router.dart';
import '../widgets/health_bar.dart';
import '../widgets/status_effect_badge.dart';
import '../widgets/narration_view.dart';
import '../../database/database.dart';
import '../../database/daos/character_dao.dart';
import '../../database/daos/loot_persistence.dart';
import '../../models/enums.dart';
import '../../models/battle.dart';
import '../../models/character.dart';
import '../../models/attributes.dart';
import '../../models/martial_art.dart';
import '../../models/meridian.dart';
import '../../models/enemy.dart';
import '../../engine/battle_engine.dart';
import '../../engine/config_loader.dart';
import '../../engine/providers.dart';
import '../../models/drop.dart' show PityCounter;
import '../../models/loot_batch.dart';
import '../../models/session_mods.dart';
import '../widgets/loot_explosion_overlay.dart';

import '../widgets/battle_animations.dart';
import '../../audio/sound_manager.dart';
import '../../utils/app_logger.dart';

class BattlePage extends ConsumerStatefulWidget {
  final BattleRouteExtra? extra;
  const BattlePage({super.key, this.extra});

  @override
  ConsumerState<BattlePage> createState() => _BattlePageState();
}

class _BattlePageState extends ConsumerState<BattlePage> {
  int _round = 1;
  bool _isBossPhase = false;
  bool _battleEnded = false;
  bool _victory = false;
  bool _retreated = false;
  bool _loading = true;
  bool _noCharacter = false;
  String? _errorMessage;

  final List<String> _narrationLines = [];
  final List<String> _autoRunLines = [];
  final List<String> _dropLines = [];

  // 战斗结果（真实数据）
  BattleResult? _battleResult;

  // 真回合制运行时状态（手动/托管共用）
  BattleRuntimeState? _runtime;

  // 托管模式开关 + 定时器
  bool _autoPilot = false;
  Timer? _autoPilotTimer;

  // 保底计数器（用于掉落）
  PityCounter _pity = const PityCounter(dropTableId: 'default', count: 0);

  // 运行时战斗状态（HP/IE）
  int _playerHp = 0;
  int _playerMaxHp = 0;
  int _playerIe = 0;
  int _playerMaxIe = 0;
  int _enemyHp = 0;
  int _enemyMaxHp = 0;
  String _enemyName = '敌人';

  /// 敌人是否为精英（含机制描述，用于战斗页 tag 显示）
  bool _enemyIsElite = false;
  String _enemyMechanicDesc = '';
  String _playerName = '你';

  // --- 战斗动画状态 ---
  // 动画触发标记：每次触发后用 setState 重置，驱动 widget 重建播动画
  bool _playerAttacking = false;   // 玩家攻击动画
  bool _enemyShaking = false;       // 敌人受击抖动
  bool _playerShaking = false;      // 玩家受击抖动
  bool _enemyDying = false;         // 敌人死亡动画
  int _damageToEnemy = 0;           // 显示在敌人上方的伤害数字
  int _damageToPlayer = 0;         // 显示在玩家上方的伤害数字
  bool _lastHitCritical = false;   // 上次攻击是否暴击
  bool _enemyDead = false;          // 敌人是否已死亡（控制 DeathAnimation）

  // HP 条动画用的"显示值"（滞后追随真实值，制造渐变效果）
  int _displayedPlayerHp = 0;
  int _displayedEnemyHp = 0;


  @override
  void initState() {
    super.initState();
    // 使用 addPostFrameCallback 确保 ref 在第一帧后可用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBattle();
    });
  }

  @override
  void dispose() {
    // 取消托管定时器
    _autoPilotTimer?.cancel();
    // 战斗页面销毁时切回城镇 BGM
    _safePlayBgm('town');
    super.dispose();
  }

  // ===================================================================
  // 音效 & 动画安全调用（try-catch 包裹，文件不存在不崩溃）
  // ===================================================================

  /// 安全播放 SFX 音效
  void _safePlaySfx(String sfxType) {
    try {
      final type = SfxType.values.byName(sfxType);
      SoundManager.instance.playSfx(type);
    } catch (_) {
      // 音效文件不存在或 SoundManager 未初始化 — 忽略
    }
  }

  /// 安全播放 BGM
  void _safePlayBgm(String bgmType) {
    try {
      final type = BgmType.values.byName(bgmType);
      SoundManager.instance.playBgm(type);
    } catch (_) {
      // BGM 文件不存在或 SoundManager 未初始化 — 忽略
    }
  }

  /// 触发玩家攻击动画 + 音效
  void _triggerPlayerAttack({bool isCritical = false, int damage = 0}) {
    _safePlaySfx(isCritical ? 'crit' : 'attack');
    setState(() {
      _playerAttacking = true;
      _lastHitCritical = isCritical;
      if (damage > 0) {
        _damageToEnemy = damage;
        _enemyShaking = true;
      }
    });
    // 动画时长后重置标志（模拟 onComplete 回调）
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _playerAttacking = false;
          _enemyShaking = false;
        });
      }
    });
  }

  /// 触发玩家受击动画 + 音效
  void _triggerPlayerHit(int damage) {
    _safePlaySfx('hit');
    setState(() {
      _playerShaking = true;
      _damageToPlayer = damage;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _playerShaking = false);
      }
    });
  }

  /// 触发敌人死亡动画 + 掉落音效
  void _triggerEnemyDeath() {
    _safePlaySfx('drop');
    setState(() {
      _enemyDying = true;
      _enemyDead = true;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _enemyDying = false);
      }
    });
  }

  /// 启动战斗：读取角色 + 秘境/敌人信息，初始化真回合制运行时
  Future<void> _startBattle() async {
    final engine = ref.read(battleEngineSyncProvider);
    if (engine == null) {
      setState(() {
        _loading = false;
        _errorMessage = '战斗引擎加载中，请稍后重试。';
      });
      return;
    }

    // 1. 从 AppDatabase 读取角色
    final db = AppDatabase.instance;
    final characterData = await db.characterDao.getCharacter();
    if (characterData == null) {
      setState(() {
        _loading = false;
        _noCharacter = true;
      });
      return;
    }

    // 2. 从 BattleRouteExtra 读取秘境信息
    final extra = widget.extra;
    final realmId = extra?.realmId ?? 'realm_001';
    final isAutoRun = extra?.isAutoRun ?? false;
    final difficultyIndex = extra?.difficultyIndex ?? 0;
    final difficulty = Difficulty.values[difficultyIndex.clamp(0, Difficulty.values.length - 1)];

    // 3. 从 ConfigLoader 读取秘境配置和敌人
    final config = ref.read(configProvider);
    if (config == null) {
      setState(() {
        _loading = false;
        _errorMessage = '配置加载中，请稍后重试。';
      });
      return;
    }
    final realmConfig = config.getRealm(realmId);

    // 4. 构建敌人（enemyId 路由优先：探索页节点/Boss 指定）
    Enemy? enemy;
    final explicitEnemyId = extra?.enemyId;
    if (explicitEnemyId != null) {
      final enemyConfig = config.getEnemy(explicitEnemyId);
      if (enemyConfig != null) enemy = enemyConfig.toEnemy();
    }
    enemy ??= _fallbackEnemyFromRealm(realmConfig, config);

    // 兜底：创建一个默认敌人
    enemy ??= Enemy(
      id: 'default_enemy',
      name: '神秘敌人',
      powerIndex: 100,
      health: 500,
      externalAttack: 50,
      internalAttack: 30,
      defense: 20,
      initiative: 10,
      dodgeRate: 5,
      critRate: 5,
      elementAffinity: ElementAffinity.neutral,
      dropTableId: 'drop_normal',
      mechanics: const [],
      enemyType: '杂兵',
    );


    // 5. 从 CharacterTableData 构建 Character 模型
    final character = _buildCharacterFromData(characterData);

    // 兜底已在上方保证非空
    final enemyData = enemy;

    // 更新 UI 显示用的名称和初始 HP/IE
    setState(() {
      _playerName = character.name;
      _enemyName = enemyData.name;
      _enemyIsElite = enemyData.isElite && enemyData is! Boss;
      _enemyMechanicDesc = _enemyIsElite
          ? enemyData.mechanics.map((m) => m.description).join('；')
          : '';
      _playerHp = character.health;
      _playerMaxHp = character.maxHealth;
      _playerIe = character.innerEnergy;
      _playerMaxIe = character.maxInnerEnergy;
      _enemyHp = enemyData.health;
      _enemyMaxHp = enemyData.health;
      // 初始化 HP 显示值（用于渐变动画）
      _displayedPlayerHp = character.health;
      _displayedEnemyHp = enemyData.health;
    });

    // 战斗开始：播放战斗 BGM（Boss 战用 boss BGM）
    _safePlayBgm(enemyData.isElite ? 'boss' : 'battle');

    // 6. 连刷模式：整场模拟（延迟结算，胜利才写库）
    if (isAutoRun) {
      _narrationLines.add('你踏入了秘境，四周弥漫着阴冷的气息...');
      await _runAutoBattle(engine, character, enemyData, realmId, difficulty);
      return;
    }

    // 7. 真回合制模式：初始化战斗运行时，等待玩家逐回合操作
    _runtime = engine.initRuntime(
      player: character,
      enemy: enemyData,
      realmId: realmId,
      layer: 1,
      difficulty: difficulty,
      pity: _pity,
      mods: widget.extra?.mods ?? const SessionMods(),
    );

    setState(() {
      _loading = false;
      _round = 1;
      _narrationLines.add('你踏入了秘境，四周弥漫着阴冷的气息...');
      _narrationLines.add('遭遇了 ${enemyData.name}！');
      _isBossPhase = enemyData.isElite || enemyData is Boss;
      // 会话修正提示（模块 3）
      final m = widget.extra?.mods;
      if (m != null && !m.isEmpty) {
        _narrationLines.add('（本局生效：${m.summary.join(' · ')}）');
      }
    });
  }

  /// 从秘境配置回退选取敌人：enemyPool[0] → bossId → null
  Enemy? _fallbackEnemyFromRealm(RealmConfigEntry? realmConfig, ConfigLoader config) {
    if (realmConfig == null) return null;
    if (realmConfig.enemyPool.isNotEmpty) {
      final enemyConfig = config.getEnemy(realmConfig.enemyPool[0]);
      if (enemyConfig != null) return enemyConfig.toEnemy();
    }
    if (realmConfig.bossId.isNotEmpty) {
      final enemyConfig = config.getEnemy(realmConfig.bossId);
      if (enemyConfig != null) return enemyConfig.toEnemy();
    }
    return null;
  }

  /// 从 CharacterTableData 构建 Character 模型
  Character _buildCharacterFromData(CharacterTableData data) {
    final attrs = CharacterDao.parseAttributes(data);
    final martialArtsData = CharacterDao.parseMartialArts(data);
    final meridiansData = CharacterDao.parseMeridians(data);

    // 将 MartialArtData 转为 MartialArt
    final martialArts = martialArtsData.map((m) => MartialArt(
      id: m.id,
      name: m.name,
      type: _parseMartialType(m.type),
      proficiency: m.proficiency,
      proficiencyLevel: _parseProficiencyLevel(m.level),
      elementAffinity: _parseElementAffinity(m.elementAffinity),
    )).toList();

    // 将 MeridianNodeData 转为 MeridianNode
    final meridians = meridiansData.map((m) => MeridianNode(
      meridianId: m.meridianId,
      nodeIndex: m.nodeIndex,
      isOpen: m.isOpen,
      seedId: m.seedId,
    )).toList();

    return Character(
      name: data.name,
      origin: data.origin,
      age: data.age,
      level: data.level,
      attributes: Attributes(
        body: attrs['body'] ?? 10,
        agi: attrs['agi'] ?? 10,
        wis: attrs['wis'] ?? 10,
        con: attrs['con'] ?? 10,
        luck: attrs['luck'] ?? 5,
      ),
      martialArts: martialArts,
      meridians: meridians,
      heartMantraId: data.heartMantra,
      health: data.health,
      innerEnergy: data.innerEnergy,
      fortune: data.fortune,
      reputation: data.reputation,
      alignment: data.alignment,
      powerIndex: data.powerIndex,
      silver: data.silver,
    );
  }

  MartialType _parseMartialType(String type) {
    switch (type) {
      case 'inner':
        return MartialType.internal;
      case 'outer':
      case 'external':
        return MartialType.external;
      case 'light':
      case 'lightness':
        return MartialType.lightness;
      default:
        return MartialType.external;
    }
  }

  ProficiencyLevel _parseProficiencyLevel(String level) {
    switch (level) {
      case 'novice':
        return ProficiencyLevel.novice;
      case 'beginner':
        return ProficiencyLevel.beginner;
      case 'minor':
        return ProficiencyLevel.minor;
      case 'major':
        return ProficiencyLevel.major;
      case 'mastery':
        return ProficiencyLevel.mastery;
      default:
        return ProficiencyLevel.novice;
    }
  }

  ElementAffinity _parseElementAffinity(String affinity) {
    switch (affinity) {
      case 'yang':
        return ElementAffinity.yang;
      case 'yin':
        return ElementAffinity.yin;
      default:
        return ElementAffinity.neutral;
    }
  }

  /// 连刷模式：调用 BattleEngine.executeBattle(isAutoRun=true)
  Future<void> _runAutoBattle(
    BattleEngine engine,
    Character player,
    Enemy enemy,
    String realmId,
    Difficulty difficulty,
  ) async {
    try {
      final result = engine.executeBattle(
        player: player,
        enemy: enemy,
        realmId: realmId,
        layer: 1,
        difficulty: difficulty,
        isAutoRun: true,
        pity: _pity,
      );

      // 连刷碾压模式：快速播放攻击音效
      _safePlaySfx('attack');

      // 延迟结算：drops 只展示/累积，胜利才写库（失败作废）
      AppLogger.instance.info('[_runAutoBattle] 战斗结果: victory=${result.victory}, drops=${result.drops.length}');
      for (final drop in result.drops) {
        final equip = drop.equipment;
        _dropLines.add('获得 [${equip.quality.displayName}] ${equip.name}');
        if (drop.isPityTriggered) _dropLines.add('  ※ 触发保底！');
      }

      // 气血写回数据库（气血连锁；失败同样生效=气血惩罚）
      await _persistBattleOutcome(result);

      // 更新保底计数器（无论胜负都推进保底，只作废物质收益）
      if (result.drops.isNotEmpty) {
        _pity = result.drops.last.updatedPity;
      }

      // 掉落结算：胜利才写库，失败清空作废
      if (result.victory) {
        await LootPersistence.persistDrops(
          result.drops,
          ref.read(configProvider),
        );
      } else {
        _dropLines.clear();
        _dropLines.add('战斗失败，本次掉落尽数遗落。');
      }

      setState(() {
        _battleResult = result;
        _battleEnded = true;
        _victory = result.victory;
        _loading = false;

        // 更新 HP（真实数据）
        _playerHp = result.playerHealthRemaining;
        _enemyHp = result.victory ? 0 : _enemyHp;

        // 从战斗描写中提取行
        final lines = result.fullNarration.split('\n').where((l) => l.trim().isNotEmpty).toList();
        _autoRunLines.addAll(lines);
      });

      // 连刷胜利：播放掉落音效 + BGM 切回城镇
      if (result.victory) {
        _safePlaySfx('drop');
      }
      // 连刷结束：BGM 切回城镇
      _safePlayBgm('town');
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = '战斗执行出错: $e';
      });
    }
  }

  /// 真回合制：执行玩家选择的一个回合（DESIGN.md 3.2.2 重构）
  ///
  /// 不再「每次动作整场模拟」——玩家的选择写入 Runtime，只推进一回合，
  /// 回合动作、伤害、血条变化、动画全部来自这一回合的真实数据。
  Future<void> _executeAction(BattleActionType action) async {
    final engine = ref.read(battleEngineSyncProvider);
    final runtime = _runtime;
    if (engine == null || runtime == null) return;
    if (_battleEnded || _loading) return;

    // 玩家选择写入 Runtime（本回合生效，只施加到玩家第一个动作）
    runtime.setPlayerAction(action);

    // 推进一回合
    final turn = engine.stepTurn(runtime);

    // 本回合玩家造成的伤害（第一个造成伤害的玩家动作）
    final playerAttack =
        turn.actions.where((a) => a.isPlayer && a.damage > 0).firstOrNull;

    setState(() {
      _round = turn.turnNumber + 1; // UI 显示「下一回合」
      _narrationLines.add('第${turn.turnNumber}回合：');
      for (final a in turn.actions) {
        if (a.narration.trim().isNotEmpty) {
          _narrationLines.add('· ${a.narration.trim()}');
        }
      }
      // 血条跟随本回合真实 HP
      _playerHp = turn.playerHealthEnd;
      _enemyHp = turn.enemyHealthEnd;
      _playerIe = runtime.playerCombatant.innerEnergy;
    });

    // 玩家攻击动画（暴击标记 + 伤害数字）
    if (playerAttack != null) {
      _triggerPlayerAttack(
        isCritical: playerAttack.critical,
        damage: playerAttack.damage,
      );
    }

    // 玩家受击动画
    if (turn.totalDamageTaken > 0) {
      _triggerPlayerHit(turn.totalDamageTaken);
    }

    // 战斗结束？
    if (engine.isBattleOver(runtime)) {
      await _finishBattle(engine, runtime);
    }
  }

  /// 结算整场战斗（真回合制）：掉落延迟（不进库）、气血写库
  Future<void> _finishBattle(BattleEngine engine, BattleRuntimeState runtime) async {
    final result = engine.finishBattle(runtime, isAutoRun: false);

    // 更新保底计数器
    if (result.drops.isNotEmpty) {
      _pity = result.drops.last.updatedPity;
    }

    // 展示掉落文本（不进库——由探索页/连刷页在合适时机结算）
    for (final drop in result.drops) {
      final equip = drop.equipment;
      _dropLines.add('获得 [${equip.quality.displayName}] ${equip.name}');
      if (drop.isPityTriggered) _dropLines.add('  ※ 触发保底！');
      if (drop.isJackpot) _dropLines.add('  ⚡ 词缀翻倍！');
    }

    // 掉落爆发弹窗（多件交错入场 + 品质分级光效）
    if (result.victory && result.drops.isNotEmpty) {
      final batch = LootBatch(
        items: result.drops,
        source: result.tier == BattleTier.boss ? LootSource.boss : LootSource.battle,
        isJackpot: result.drops.any((d) => d.isJackpot),
      );
      if (mounted) {
        LootExplosionOverlay.show(
          context,
          batch,
          onDismiss: () => mounted ? setState(() {}) : null,
        );
      }
    }

    setState(() {
      _battleResult = result;
      _battleEnded = true;
      _victory = result.victory;
      _playerHp = result.playerHealthRemaining;
      _enemyHp = result.victory ? 0 : _enemyHp;
      final lines = result.fullNarration
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
      _narrationLines.addAll(lines);
    });

    // 气血写回（无论胜负：失败保留气血惩罚，胜利回写剩余气血）
    // 内力传 Runtime 真实终值（运功恢复/武功消耗都真实结算）
    await _persistBattleOutcome(
      result,
      finalInnerEnergy: runtime.playerCombatant.innerEnergy,
    );

    if (result.victory) {
      _triggerEnemyDeath();
      _safePlayBgm('town');
    }
  }

  /// 战斗结果持久化：剩余气血/内力写回角色表（气血连锁的核心）
  ///
  /// [finalInnerEnergy]：真回合制下传 runtime 终值（运功恢复/消耗都真实结算）；
  /// 不传时回退读 DB 旧值（兼容连刷路径）。
  ///
  /// 写回后：
  /// - 下一次战斗以残血状态开局（不再满血复活）
  /// - 探索页能读到真实气血
  Future<void> _persistBattleOutcome(BattleResult result, {int? finalInnerEnergy}) async {
    try {
      final db = AppDatabase.instance;
      final charData = await db.characterDao.getCharacter();
      if (charData == null) return;

      final char = _buildCharacterFromData(charData);
      final hp = result.playerHealthRemaining.clamp(0, char.maxHealth);
      final ie = result.playerHealthRemaining > 0
          ? (finalInnerEnergy ?? charData.innerEnergy)
          : 0;
      await db.characterDao.updateHealth(hp);
      await db.characterDao.updateInnerEnergy(ie);
      AppLogger.instance.info('[_persistBattleOutcome] 战斗后气血写回: hp=$hp/${char.maxHealth} ie=$ie');
    } catch (e) {
      AppLogger.instance.error('_persistBattleOutcome 气血写回失败: $e');
    }
  }

  /// 统一退出入口：pop 时携带战斗结果（探索页据此判定胜负/结算掉落）
  void _exitBattle() {
    final result = _battleResult;
    final exit = BattleExitResult(
      victory: _victory && result != null,
      retreated: _retreated,
      drops: (_victory && result != null) ? result.drops : const [],
    );
    if (context.canPop()) context.pop(exit);
  }

  /// 切换托管模式：每秒自动选招推进一回合，可随时切回手动
  void _toggleAutoPilot() {
    if (_battleEnded) return;
    setState(() {
      _autoPilot = !_autoPilot;
      _narrationLines.add(_autoPilot ? '———— 你心念一转，战意交由本能驱使（智能托管开启） ————' : '———— 你收敛心神，重新接管战斗（智能托管关闭） ————');
    });
    if (_autoPilot) {
      _autoPilotTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _autoPilotTick();
      });
    } else {
      _autoPilotTimer?.cancel();
      _autoPilotTimer = null;
    }
  }

  /// 托管每秒一次的推进：AI 选招 → stepTurn
  void _autoPilotTick() {
    if (!_autoPilot || _battleEnded || !mounted) return;
    final engine = ref.read(battleEngineSyncProvider);
    final runtime = _runtime;
    if (engine == null || runtime == null) return;

    // 战斗结束则停止托管并结算
    if (engine.isBattleOver(runtime)) {
      _autoPilotTimer?.cancel();
      _autoPilot = false;
      _finishBattle(engine, runtime);
      return;
    }

    final action = engine.chooseAutoAction(runtime);
    _executeAction(action);
  }

  /// 撤退
  void _doRetreat() {
    if (_battleEnded) return;
    // 撤退音效 + BGM 切回城镇
    _safePlaySfx('retreat');
    _safePlayBgm('town');
    setState(() {
      _narrationLines.add('你见势不妙，转身撤退，脱离了战斗。');
      _battleEnded = true;
      _victory = false;
      _retreated = true;
    });
    // 立即携带撤退结果返回秘境
    _exitBattle();
  }

  @override
  Widget build(BuildContext context) {
    try {
    final isAutoRun = widget.extra?.isAutoRun ?? false;

    // 显示加载中
    if (_loading && !isAutoRun) {
      return PopScope(
        canPop: true,
        child: Scaffold(
          backgroundColor: DarkWuxiaColors.background,
          appBar: AppBar(
            title: Text(isAutoRun ? '连刷战斗' : '战斗'),
            leading: IconButton(icon: const Icon(Icons.exit_to_app), onPressed: () => context.pop()),
          ),
          body: const Center(
            child: CircularProgressIndicator(color: DarkWuxiaColors.darkGold),
          ),
        ),
      );
    }

    // 角色不存在
    if (_noCharacter) {
      return PopScope(
        canPop: true,
        child: Scaffold(
          backgroundColor: DarkWuxiaColors.background,
          appBar: AppBar(
            title: const Text('战斗'),
            leading: IconButton(icon: const Icon(Icons.exit_to_app), onPressed: () => context.pop()),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_off, size: 64, color: DarkWuxiaColors.textSecondary),
                const SizedBox(height: 16),
                const Text('请先创建角色',
                  style: TextStyle(fontFamily: 'serif', fontSize: 18, color: DarkWuxiaColors.textPrimary)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    context.go(RouteNames.character);
                  },
                  child: const Text('去创建角色'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 引擎未加载
    if (_errorMessage != null) {
      return PopScope(
        canPop: true,
        child: Scaffold(
          backgroundColor: DarkWuxiaColors.background,
          appBar: AppBar(
            title: const Text('战斗'),
            leading: IconButton(icon: const Icon(Icons.exit_to_app), onPressed: () => context.pop()),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: DarkWuxiaColors.darkRedBright),
                const SizedBox(height: 16),
                Text(_errorMessage!,
                  style: const TextStyle(fontFamily: 'serif', fontSize: 14, color: DarkWuxiaColors.textPrimary),
                  textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('返回'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: DarkWuxiaColors.background,
        appBar: AppBar(
          title: Text(isAutoRun ? '连刷战斗' : '战斗'),
          leading: IconButton(icon: const Icon(Icons.exit_to_app), onPressed: () => context.pop()),
        ),
        body: isAutoRun ? _buildAutoRunView() : _buildBattleView(),
      ),
    );
    } catch (e, stack) {
      AppLogger.instance.error('BattlePage.build 崩溃: $e\n$stack');
      return PopScope(
        canPop: true,
        child: Scaffold(
          backgroundColor: DarkWuxiaColors.background,
          appBar: AppBar(
            title: const Text('战斗'),
            leading: IconButton(icon: const Icon(Icons.exit_to_app), onPressed: () => context.pop()),
          ),
          body: const DarkWuxiaEmpty(text: '战斗页面加载出错，请查看日志', icon: Icons.error_outline),
        ),
      );
    }
  }

  Widget _buildBattleView() {
    return Column(children: [
      _buildCombatantBars(),
      const Divider(height: 1),
      _buildRoundInfo(),
      Expanded(child: _buildNarrationArea()),
      if (_battleEnded) _buildEndPanel(),
      if (!_battleEnded) _buildActionBar(),
    ]);
  }

  Widget _buildAutoRunView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_loading)
          const Center(child: CircularProgressIndicator(color: DarkWuxiaColors.darkGold))
        else ...[
          ..._autoRunLines.map((line) => AutoRunNarrationView(narration: line, dropLines: _dropLines)),
          const SizedBox(height: 12),
          if (_battleEnded) ...[
            DarkWuxiaCard(
              borderColor: DarkWuxiaColors.darkGold,
              child: Column(children: [
                const Text('连刷结束', style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.bold, color: DarkWuxiaColors.darkGold)),
                const SizedBox(height: 8),
                Text('总掉落 ${_dropLines.length} 件',
                  style: const TextStyle(fontFamily: 'serif', fontSize: 14, color: DarkWuxiaColors.textPrimary)),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  OutlinedButton(onPressed: () => context.pop(), child: const Text('返回')),
                  ElevatedButton(onPressed: () => context.pop(), child: const Text('再次连刷')),
                ]),
              ]),
            ),
          ],
        ],
      ]),
    );
  }

  /// 从 BattleResult 读取真实 HP/IE 数据
  Widget _buildCombatantBars() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(children: [
        // 玩家行：受击时 ShakeAnimation 包裹
        _buildCombatantRow(_playerName, _playerHp, _playerMaxHp, _playerIe, _playerMaxIe, true),
        const SizedBox(height: 8),
        // 敌人行：受击时 ShakeAnimation 包裹，死亡时 DeathAnimation
        _buildCombatantRow(_enemyName, _enemyHp, _enemyMaxHp, 0, 0, false),
      ]),
    );
  }

  Widget _buildCombatantRow(String name, int hp, int maxHp, int ie, int maxIe, bool isPlayer) {
    final bool shouldShake = isPlayer ? _playerShaking : _enemyShaking;
    final bool isDead = !isPlayer && _enemyDead;
    final bool isAttacking = isPlayer && _playerAttacking;
    final bool isDying = !isPlayer && _enemyDying;
    final int damageNum = isPlayer ? _damageToPlayer : _damageToEnemy;
    // HP 显示值用于动画起点（从上次显示值渐变到真实值）
    final int displayedHp = isPlayer ? _displayedPlayerHp : _displayedEnemyHp;

    // 更新显示值（下次重建时从此值开始渐变）
    if (isPlayer) {
      _displayedPlayerHp = hp;
    } else {
      _displayedEnemyHp = hp;
    }

    // 基础内容
    final card = DarkWuxiaCard(
      padding: const EdgeInsets.all(8),
      borderColor: isPlayer ? DarkWuxiaColors.darkGold : DarkWuxiaColors.darkRed,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(isPlayer ? Icons.person : Icons.dangerous,
            size: 16, color: isPlayer ? DarkWuxiaColors.darkGold : DarkWuxiaColors.darkRedBright),
          const SizedBox(width: 4),
          Text(name, style: TextStyle(fontFamily: 'serif', fontSize: 13, fontWeight: FontWeight.bold,
            color: isPlayer ? DarkWuxiaColors.darkGold : DarkWuxiaColors.darkRedBright)),
          // 攻击中标记
          if (isAttacking) ...[
            const SizedBox(width: 4),
            Icon(Icons.flash_on, size: 14,
              color: _lastHitCritical ? DarkWuxiaColors.darkGold : DarkWuxiaColors.buffGreen),
          ],
          // 伤害数字浮层（叠在名称旁边）
          if (damageNum > 0) ...[
            const SizedBox(width: 8),
            _buildDamageNumber(damageNum, isPlayer),
          ],
        ]),
        const SizedBox(height: 4),
        // HP 条用 TweenAnimationBuilder 实现渐变动画
        // 从 displayedHp（上次值）渐变到 hp（当前值）
        TweenAnimationBuilder<double>(
          tween: Tween(
            begin: maxHp > 0 ? (displayedHp / maxHp).clamp(0.0, 1.0) : 0.0,
            end: maxHp > 0 ? (hp / maxHp).clamp(0.0, 1.0) : 0.0,
          ),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, pct, child) {
            return HealthBar.hp(current: (pct * maxHp).round(), max: maxHp);
          },
        ),
        const SizedBox(height: 4),
        HealthBar.innerEnergy(current: ie, max: maxIe),
      ]),
    );

    // 死亡动画包裹（敌人）
    // 当 DeathAnimation 可用时，替换为:
    // if (isDead || isDying) {
    //   return DeathAnimation(child: card, onComplete: () {});
    // }
    // 当前: isDead/isDying 用于决定是否在死亡后展示灰化效果
    if (isDead || isDying) {
      return Opacity(opacity: 0.5, child: card);
    }

    // 受击抖动动画包裹
    // 当 ShakeAnimation 可用时，替换为:
    // if (shouldShake) {
    //   return ShakeAnimation(child: card, onComplete: () {});
    // }

    // 暂用 AnimatedContainer 模拟抖动效果
    if (shouldShake) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transformAlignment: Alignment.center,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 400),
          builder: (context, val, child) {
            // 模拟左右抖动
            final offset = sin(val * pi * 6) * 3;
            return Transform.translate(
              offset: Offset(offset, 0),
              child: child,
            );
          },
          child: card,
        ),
      );
    }

    return card;
  }

  /// 伤害数字浮动显示（模拟 DamageNumberAnimation）
  /// 当 DamageNumberAnimation 可用时，替换为: DamageNumberAnimation(damage: damage, type: ...)
  Widget _buildDamageNumber(int damage, bool isPlayer) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, val, child) {
        return Opacity(
          opacity: 1 - val,
          child: Transform.translate(
            offset: Offset(0, -val * 20),
            child: Text(
              '-$damage',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 14 + (isPlayer ? 0 : 2),
                fontWeight: FontWeight.bold,
                color: isPlayer ? DarkWuxiaColors.darkRedBright : DarkWuxiaColors.darkGold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoundInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(children: [
        if (_isBossPhase) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: DarkWuxiaColors.darkRed.withValues(alpha: 0.2),
              border: Border.all(color: DarkWuxiaColors.darkRed)),
            child: const Text('⚡ Boss阶段',
              style: TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.darkRedBright, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
        if (_enemyIsElite) ...[
          Tooltip(
            message: _enemyMechanicDesc,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: DarkWuxiaColors.darkGold.withValues(alpha: 0.2),
                border: Border.all(color: DarkWuxiaColors.darkGold)),
              child: const Text('👑 精英',
                style: TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.darkGoldBright, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text('第 $_round 回合',
          style: const TextStyle(fontFamily: 'serif', fontSize: 13, color: DarkWuxiaColors.darkGold, fontWeight: FontWeight.bold)),
        const Spacer(),
        // 状态效果区
        StatusEffectArea(effects: const [], isPlayer: true),
      ]),
    );
  }

  Widget _buildNarrationArea() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: NarrationView(
        text: _narrationLines.join('\n\n'),
        tier: _isBossPhase ? BattleTier.boss : BattleTier.normal,
      ),
    );
  }

  Widget _buildActionBar() {
    final actions = [
      ('出招', BattleActionType.attack, Icons.sports_martial_arts, DarkWuxiaColors.darkRedBright),
      ('运功', BattleActionType.channel, Icons.self_improvement, DarkWuxiaColors.innerEnergy),
      ('闪避', BattleActionType.dodge, Icons.directions_run, DarkWuxiaColors.buffGreen),
      ('反击', BattleActionType.counter, Icons.swap_horiz, DarkWuxiaColors.darkGold),
    ];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: DarkWuxiaColors.surface,
        border: Border(top: BorderSide(color: DarkWuxiaColors.divider, width: 0.5)),
      ),
      child: Row(children: [
        ...actions.map((a) {
          return Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: a.$4.withValues(alpha: 0.2),
                foregroundColor: a.$4,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () => _executeAction(a.$2),
              child: Column(children: [
                Icon(a.$3, size: 18),
                const SizedBox(height: 2),
                Text(a.$1, style: const TextStyle(fontFamily: 'serif', fontSize: 11)),
              ]),
            ),
          ));
        }),
        // 撤退出招按钮
        Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DarkWuxiaColors.textSecondary.withValues(alpha: 0.2),
              foregroundColor: DarkWuxiaColors.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onPressed: _doRetreat,
            child: const Column(children: [
              Icon(Icons.exit_to_app, size: 18),
              SizedBox(height: 2),
              Text('撤退', style: TextStyle(fontFamily: 'serif', fontSize: 11)),
            ]),
          ),
        )),
        // 托管开关
        Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _autoPilot
                  ? DarkWuxiaColors.darkGold.withValues(alpha: 0.35)
                  : DarkWuxiaColors.darkGold.withValues(alpha: 0.15),
              foregroundColor: DarkWuxiaColors.darkGold,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onPressed: _toggleAutoPilot,
            child: Column(children: [
              Icon(_autoPilot ? Icons.pause_circle_outline : Icons.smart_toy_outlined, size: 18),
              const SizedBox(height: 2),
              Text(_autoPilot ? '关闭托管' : '智能托管',
                  style: const TextStyle(fontFamily: 'serif', fontSize: 11)),
            ]),
          ),
        )),
      ]),
    );
  }

  /// 战斗结束面板：显示胜负 + 真实掉落
  Widget _buildEndPanel() {
    final result = _battleResult;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: DarkWuxiaColors.elevated,
        border: Border(top: BorderSide(color: DarkWuxiaColors.darkGold, width: 1)),
      ),
      child: Column(children: [
        Text(_retreated ? '撤退' : (_victory ? '胜' : '败'),
          style: TextStyle(fontFamily: 'serif', fontSize: 28, fontWeight: FontWeight.bold,
            color: _victory ? DarkWuxiaColors.buffGreen : DarkWuxiaColors.darkRedBright)),
        const SizedBox(height: 8),
        if (result != null) ...[
          Text('击杀: ${result.killCount}  掉落: ${result.dropCount}  回合: ${result.turnsUsed}',
            style: const TextStyle(fontFamily: 'serif', fontSize: 13, color: DarkWuxiaColors.textSecondary)),
          const SizedBox(height: 8),
        ],
        const DarkWuxiaSectionTitle(text: '掉落', icon: Icons.inventory_2),
        if (_dropLines.isEmpty)
          const Padding(
            padding: EdgeInsets.all(4),
            child: Text('未获得掉落', style: TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textHint)),
          )
        else
          ..._dropLines.map((d) => Text(d, style: const TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.darkGold))),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          OutlinedButton(onPressed: _exitBattle, child: const Text('返回秘境')),
          if (_victory) ElevatedButton(onPressed: _exitBattle, child: const Text('继续')),
        ]),
      ]),
    );
  }
}
