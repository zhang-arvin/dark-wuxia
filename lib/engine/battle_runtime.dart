// =============================================================================
// engine/battle_runtime.dart — 战斗运行时状态（从 battle_engine 平移，批次1）
//
// 真回合制的运行时机制：_EquipmentBonuses（引擎内部装备词缀聚合缓存）
// 与 BattleRuntimeState。BattleRuntimeState 的实际构建发生在 battle_engine。
// =============================================================================

import '../models/character.dart';
import '../models/enemy.dart';
import '../models/enums.dart';
import '../models/drop.dart';
import '../models/battle.dart';
import '../models/combatant.dart';
import '../models/martial_art.dart';
import '../models/unique_effect.dart';
import '../models/heart_mantra.dart';
import '../models/session_mods.dart';
import 'narration_engine.dart';

/// 装备词缀聚合加成值（内部使用）
class EquipmentBonusesCache {
  final int atkBonus; // 外功攻击力加成
  final int defBonus; // 防御力加成
  final int hpBonus; // 生命上限加成
  final int ieBonus; // 内力上限加成
  final int innerAtkBonus; // 内功攻击力加成

  const EquipmentBonusesCache({
    required this.atkBonus,
    required this.defBonus,
    required this.hpBonus,
    required this.ieBonus,
    required this.innerAtkBonus,
  });
}


/// 战斗运行时状态（真回合制，DESIGN.md 3.2.2）
///
/// 由 [BattleEngine.initRuntime] 创建，[BattleEngine.stepTurn] 逐回合推进，
/// [BattleEngine.finishBattle] 结算。持有原始输入与可变战斗数据。
class BattleRuntimeState {
  // --- 原始输入（不可变） ---
  final Character player;
  final Enemy enemy; // 原始敌人（含 Boss 类型与 phases）
  final String realmId;
  final int layer;
  final Difficulty difficulty;
  final PityCounter? pity;
  final BattleTier tier;

  // --- 战斗参与者（可变） ---
  final Combatant playerCombatant;
  final Combatant enemyCombatant;

  // --- 武功/效果/心法 ---
  final List<MartialArt> playerArts;
  final List<MartialArt> enemyArts;
  final List<UniqueEffect> playerUniqueEffects;
  final List<UniqueEffect> enemyUniqueEffects;
  final HeartMantra? heartMantra;
  final QiDeviationLevel qiDeviation;

  // --- 回合进度 ---
  final int maxTurns;
  final List<BattleTurn> turns = [];
  int currentBossPhase = 1;
  String? pendingPhaseNarration;
  bool battleOver = false;

  /// 心法「先发制人」标记（⚠️ 与旧 executeBattle 一致为死代码，暂不消费）
  final bool extraFirstTurn;

  /// 会话修正参数（模块 3：秘境模组+Buff），战斗侧加成消费点
  final SessionMods mods;

  /// 本回合玩家选择的动作（UI 真回合制设置；null=托管/AI roll）
  BattleActionType? _pendingPlayerAction;

  /// 设置玩家本回合选择（覆盖 AI roll），只能设置一个回合
  void setPlayerAction(BattleActionType action) {
    _pendingPlayerAction = action;
  }

  /// 取出并清除本回合玩家选择（由 stepTurn 调用）
  BattleActionType? consumePlayerAction() {
    final a = _pendingPlayerAction;
    _pendingPlayerAction = null;
    return a;
  }

  BattleRuntimeState({
    required this.player,
    required this.enemy,
    required this.realmId,
    required this.layer,
    required this.difficulty,
    required this.pity,
    required this.tier,
    required this.playerCombatant,
    required this.enemyCombatant,
    required this.playerArts,
    required this.enemyArts,
    required this.playerUniqueEffects,
    required this.enemyUniqueEffects,
    required this.heartMantra,
    required this.qiDeviation,
    required this.maxTurns,
    required this.extraFirstTurn,
    this.mods = const SessionMods(),
  });

  bool get playerAlive => playerCombatant.isAlive;
  bool get enemyAlive => enemyCombatant.isAlive;
  bool get isBossFight => enemy is Boss && (enemy as Boss).phases.isNotEmpty;
}

