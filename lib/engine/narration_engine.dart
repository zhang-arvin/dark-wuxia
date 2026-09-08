// =============================================================================
// narration_engine.dart — 战斗描写引擎
//
// 对应 DESIGN.md 章节：
//   4.4 战斗描写模板（预生成）— 200-500条预写模板，运行时随机选取+变量填充
//   3.2.4 掉落闪光
//   3.10.4 招式描写随战力进化 — 同一招式，战力低朴素/高霸气
//
// 功能：
//   - 模板加载：从narration_templates.json加载所有模板
//   - 模板匹配：根据战斗档位(碾压/正常/Boss)+招式类型筛选可用模板
//   - 变量填充：替换{skill}/{enemy}/{damage}/{player}/{effect}等变量
//   - 战力感知：根据玩家战力选择不同描写(低战力朴素/高战力霸气)
//   - 权重随机：按模板weight加权随机选取，避免重复
// =============================================================================

import 'dart:math';

import '../models/enums.dart';
import '../models/narration.dart';
import 'config_loader.dart';

/// 战斗描写的上下文信息（供模板匹配和变量填充使用）
class NarrationContext {
  /// 战斗档位
  final BattleTier tier;

  /// 玩家名称
  final String playerName;

  /// 敌人名称
  final String enemyName;

  /// 敌人ID（用于Boss专属模板匹配）
  final String? enemyId;

  /// 使用的武功名称
  final String skillName;

  /// 武功类型（外功/内功/轻功/心法）
  final MartialType? martialType;

  /// 造成的伤害数值
  final int damage;

  /// 是否暴击
  final bool isCritical;

  /// 是否闪避成功
  final bool isDodged;

  /// 附加效果描述
  final String? effectNote;

  /// 玩家战力指数（用于战力感知，DESIGN.md 3.10.4）
  final int playerPower;

  /// Boss当前阶段（仅Boss档有效）
  final int? bossPhase;

  /// 内力变化（正=恢复, 负=消耗）
  final int energyChange;

  const NarrationContext({
    required this.tier,
    this.playerName = '你',
    required this.enemyName,
    this.enemyId,
    required this.skillName,
    this.martialType,
    this.damage = 0,
    this.isCritical = false,
    this.isDodged = false,
    this.effectNote,
    this.playerPower = 0,
    this.bossPhase,
    this.energyChange = 0,
  });
}

/// 描写引擎（DESIGN.md 4.4 战斗描写模板）
///
/// 运行时从模板池中按权重随机选取模板，填充变量后生成战斗描写文本。
/// LLM只用于后台批量生成模板，不在运行时调用。
///
/// 可单测：核心逻辑不依赖Flutter UI。
class NarrationEngine {
  NarrationEngine(this._random, {List<NarrationTemplate>? templates})
      : _templates = templates ?? const [];

  /// 随数生成器（可注入以支持确定性测试）
  final Random _random;

  /// 所有描写模板
  final List<NarrationTemplate> _templates;

  /// 已使用的模板ID集合（避免短期内重复，每场战斗重置）
  final Set<String> _recentlyUsed = {};

  /// 从 ConfigLoader 构建描写引擎
  ///
  /// 使用 allNarrationTemplates（基础模板 + 扩展模板），
  /// 而非仅 narrationTemplates（基础模板）。
  factory NarrationEngine.fromConfig(
    ConfigLoader config, {
    Random? random,
  }) {
    return NarrationEngine(
      random ?? Random(),
      templates: config.allNarrationTemplates,
    );
  }

  /// 重置已使用模板记录（每场战斗开始时调用）
  void resetRecentUse() {
    _recentlyUsed.clear();
  }

  // =================== 模板匹配 ===================

  /// 根据上下文筛选可用的模板
  ///
  /// 匹配条件：
  /// 1. 战斗档位匹配（碾压/正常/Boss）
  /// 2. Boss阶段匹配（如有）
  /// 3. 武功类型匹配（如有）
  /// 4. 敌人ID匹配（如有）
  /// 5. 战力区间匹配（DESIGN.md 3.10.4）
  List<NarrationTemplate> _filterTemplates(NarrationContext ctx) {
    return _templates.where((t) {
      // 档位匹配
      if (t.tier != ctx.tier) return false;

      // Boss阶段匹配
      if (ctx.tier == BattleTier.boss) {
        // 模板有指定阶段但与当前阶段不匹配 → 跳过
        if (t.bossPhase != null && ctx.bossPhase != null) {
          if (t.bossPhase != ctx.bossPhase) return false;
        }
        // 模板没有指定阶段 → 通用Boss模板，可用
      }

      // 武功类型匹配
      if (t.applicableTypes.isNotEmpty && ctx.martialType != null) {
        if (!t.applicableTypes.contains(ctx.martialType)) return false;
      }

      // 敌人ID匹配
      if (t.applicableEnemies.isNotEmpty && ctx.enemyId != null) {
        if (!t.applicableEnemies.contains(ctx.enemyId)) return false;
      }

      // 战力区间匹配（DESIGN.md 3.10.4 — 战力感知）
      if (ctx.playerPower > 0) {
        if (t.minPower != null && ctx.playerPower < t.minPower!) return false;
        if (t.maxPower != null && ctx.playerPower > t.maxPower!) return false;
      }

      return true;
    }).toList();
  }

  // =================== 权重随机选取 ===================

  /// 按权重加权随机选取一个模板
  ///
  /// 优先选择未使用过的模板；如全部已用过则重置后重新选择。
  NarrationTemplate? _weightedPick(List<NarrationTemplate> candidates) {
    if (candidates.isEmpty) return null;

    // 过滤掉最近使用过的（优先新鲜感）
    var pool = candidates.where((t) => !_recentlyUsed.contains(t.id)).toList();
    if (pool.isEmpty) {
      // 全都用过了，重置
      pool = candidates;
    }

    // 计算总权重
    final totalWeight = pool.fold(0, (sum, t) => sum + t.weight);
    if (totalWeight <= 0) {
      // 权重全部为0，随机取一个
      return pool[_random.nextInt(pool.length)];
    }

    // 加权随机
    var roll = _random.nextInt(totalWeight);
    for (final t in pool) {
      roll -= t.weight;
      if (roll < 0) {
        _recentlyUsed.add(t.id);
        return t;
      }
    }

    // 理论上不会走到这里，但作为兜底
    return pool.last;
  }

  // =================== 变量填充 ===================

  /// 填充模板变量，生成最终描写文本
  ///
  /// 支持的变量：
  ///   {skill}    — 武功名称
  ///   {enemy}    — 敌人名称（碾压/正常档）
  ///   {boss}     — Boss名称（Boss档）
  ///   {player}   — 玩家名称
  ///   {damage}   — 伤害数值
  ///   {effect}   — 附加效果描述
  String _fillTemplate(NarrationTemplate template, NarrationContext ctx) {
    final variables = <String, String>{
      'skill': ctx.skillName,
      'enemy': ctx.enemyName,
      'boss': ctx.enemyName, // Boss档用{boss}变量
      'player': ctx.playerName,
      'damage': ctx.damage.toString(),
      'effect': ctx.effectNote ?? '',
    };
    return template.fill(variables);
  }

  // =================== 生成描写 ===================

  /// 生成一条动作描写文本
  ///
  /// 根据上下文（档位、武功类型、战力等）选取合适模板并填充变量。
  /// 返回null表示没有匹配的模板（调用方应提供默认描写）。
  String? generateActionNarration(NarrationContext ctx) {
    final candidates = _filterTemplates(ctx);
    final picked = _weightedPick(candidates);
    if (picked == null) return null;
    return _fillTemplate(picked, ctx);
  }

  /// 生成碾压档的简短描写（1句话，DESIGN.md 3.2.1）
  ///
  /// 碾压档：0-1回合，1句话结算
  String generateCrushNarration({
    required String skillName,
    required String enemyName,
    int damage = 0,
    int playerPower = 0,
  }) {
    final ctx = NarrationContext(
      tier: BattleTier.crush,
      enemyName: enemyName,
      skillName: skillName,
      damage: damage,
      playerPower: playerPower,
    );
    return generateActionNarration(ctx) ??
        '你一招$skillName，$enemyName应声倒地。';
  }

  /// 生成Boss阶段切换描写
  ///
  /// Boss战根据血量百分比切换阶段时触发。
  String generatePhaseSwitchNarration({
    required String bossName,
    required int newPhase,
    int playerPower = 0,
  }) {
    // 尝试匹配Boss阶段切换模板
    final candidates = _templates.where((t) {
      if (t.tier != BattleTier.boss) return false;
      if (t.bossPhase != newPhase) return false;
      // 只取模板中变量最少的（阶段切换通常只有boss变量）
      return t.requiredVars.length <= 2;
    }).toList();

    final picked = _weightedPick(candidates);
    if (picked != null) {
      return _fillTemplate(picked, NarrationContext(
        tier: BattleTier.boss,
        enemyName: bossName,
        skillName: '',
        bossPhase: newPhase,
        playerPower: playerPower,
      ));
    }

    // 默认阶段切换描写
    return switch (newPhase) {
      2 => '$bossName面色一变，周身气势陡然暴涨，进入了更加凶险的状态！',
      3 => '$bossName身负重伤却突然仰天长啸，进入了回光返照的拼命之势！',
      99 => '$bossName已至绝境，却爆发出了超越极限的力量，终极形态降临！',
      _ => '$bossName进入了第$newPhase阶段！',
    };
  }

  /// 生成战斗结果描写
  ///
  /// 战斗结束时的胜负描写。
  String generateResultNarration({
    required bool victory,
    required BattleTier tier,
    required String enemyName,
    required int turnsUsed,
  }) {
    if (victory) {
      return switch (tier) {
        BattleTier.crush => '$enemyName已倒地不起。',
        BattleTier.normal => '经过$turnsUsed个回合的激战，你终于击败了$enemyName。',
        BattleTier.boss =>
          '$enemyName轰然倒地，不再起身。这场鏖战终于以你的胜利告终！',
        BattleTier.encounter => '你成功化解了这场奇遇。',
        BattleTier.crit => '致命一击！$enemyName应声倒下。',
        BattleTier.drop => '一件宝物从$enemyName身上掉出...',
        BattleTier.qigongDeviation => '你感到经脉逆行，走火入魔！',
        BattleTier.endless => '虚空之中，又一层被你征服。',
      };
    } else {
      return switch (tier) {
        BattleTier.crush => '你竟不敌$enemyName，仓皇撤退。',
        BattleTier.normal => '你力竭不支，败于$enemyName之手。',
        BattleTier.boss =>
          '你倾尽全力仍不敌$enemyName，败退而去，他日必将再战！',
        BattleTier.encounter => '奇遇失败了。',
        BattleTier.crit => '你的暴击未能扭转战局，败于$enemyName。',
        BattleTier.drop => '你未能获得宝物。',
        BattleTier.qigongDeviation => '真气暴走，走火入魔，你失去了意识。',
        BattleTier.endless => '无尽虚空终有尽头，你倒在了这一层。',
      };
    }
  }

  /// 根据战力感知调整描写风格（DESIGN.md 3.10.4）
  ///
  /// 战力低：朴素描写 "你挥出一拳，打中了对手"
  /// 战力高：霸气描写 "你一拳打出，拳风呼啸，对手连退三步，口吐鲜血"
  String getPowerAwareNarration({
    required String skillName,
    required String enemyName,
    required int damage,
    required int playerPower,
    BattleTier tier = BattleTier.normal,
    MartialType? martialType,
  }) {
    // 战力越高，越倾向选择高权重（更霸气）的模板
    // 这里通过传入 playerPower 让模板过滤自动处理战力区间
    final ctx = NarrationContext(
      tier: tier,
      enemyName: enemyName,
      skillName: skillName,
      damage: damage,
      playerPower: playerPower,
      martialType: martialType,
    );

    final result = generateActionNarration(ctx);
    if (result != null) return result;

    // 如果没有匹配模板，根据战力生成默认描写
    if (playerPower < 500) {
      return '你使出$skillName，对$enemyName造成了${damage}点伤害。';
    } else if (playerPower < 2000) {
      return '你一记$skillName轰然而出，$enemyName吃痛后退，受到${damage}点伤害。';
    } else {
      return '$skillName之势排山倒海，$enemyName被震飞数丈，${damage}点伤害令其口吐鲜血！';
    }
  }

  /// 获取所有模板（供调试/UI展示用）
  List<NarrationTemplate> get allTemplates => List.unmodifiable(_templates);

  /// 获取指定档位的模板数量
  int getTemplateCount(BattleTier tier) =>
      _templates.where((t) => t.tier == tier).length;
}
