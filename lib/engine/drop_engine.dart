// =============================================================================
// drop_engine.dart — 掉落引擎
//
// 对应 DESIGN.md 章节：
//   3.2.4 掉落闪光
//   3.3.1 品质分级
//   3.3.2 保底机制 — PityCounter
//   3.3.3 词缀系统 — AffixRange roll
//   3.3.5 暗金设计原则
//   3.7.5 定向掉落
//   3.9.1 福缘系统（=D2 MF）
//
// 功能：
//   - 掉落计算：根据DropTable的概率+福缘加成+保底机制计算品质
//   - 词缀随机：根据品质决定词缀数量，从affixPool中加权随机选取词缀
//   - 暗金掉落：从unique_equipment.json中选取，附带固定独特效果+随机词缀
//   - 掉落闪光等级：根据品质决定(plain/detailed/ceremonial/legendary)
//   - 保底机制：PityCounter跟踪连续未掉暗金+的次数，达到阈值后必掉
// =============================================================================

import 'dart:math';

import '../models/enums.dart';
import '../models/equipment.dart';
import '../models/drop.dart';
import '../models/unique_effect.dart';
import '../models/session_mods.dart';
import 'config_loader.dart';
import 'quality_scorer.dart';

/// 掉落结果（一次掉落的完整信息）
class DropResult {
  /// 生成的装备实例
  final Equipment equipment;

  /// 掉落记录
  final DropRecord record;

  /// 掉落闪光等级
  final DropFlashLevel flashLevel;

  /// 更新后的保底计数器
  final PityCounter updatedPity;

  /// 是否触发了保底
  final bool isPityTriggered;

  /// 暗金效果描述（如品质为暗金以上）
  final String? uniqueEffectDesc;

  /// 是否词缀翻倍惊喜（5% 概率，独立于品质判定）
  final bool isJackpot;

  const DropResult({
    required this.equipment,
    required this.record,
    required this.flashLevel,
    required this.updatedPity,
    this.isPityTriggered = false,
    this.uniqueEffectDesc,
    this.isJackpot = false,
  });

  @override
  String toString() =>
      'DropResult(${equipment.name} [${equipment.quality.displayName}] flash=${flashLevel.displayName}'
      '${isPityTriggered ? " [保底]" : ""})';
}

/// 掉落引擎（DESIGN.md 3.3 装备系统 / 3.9.1 福缘系统）
///
/// 负责根据掉落表、福缘、保底机制计算掉落品质，
/// 生成词缀、随机数值，并生成完整装备实例。
///
/// 可单测：核心逻辑不依赖Flutter UI。
class DropEngine {
  DropEngine(this._config, this._random);

  /// 配置加载器
  final ConfigLoader _config;

  /// 随数生成器（可注入以支持确定性测试）
  final Random _random;

  // =================== 品质判定 ===================

  /// 根据掉落表概率+福缘+保底计算最终品质
  ///
  /// DESIGN.md 3.3.2 保底机制：
  ///   运气积累: 每刷N只怪未掉暗金+ → 暗金掉率递增
  ///   保底: 连续刷200只未掉暗金 → 第201只必掉暗金
  ///
  /// DESIGN.md 3.9.1 福缘系统：
  ///   福缘属性影响掉落率，可牺牲战力堆福缘
  (Quality, bool) _rollQuality({
    required DropTable table,
    required int fortune,
    required PityCounter pity,
    SessionMods? mods,
  }) {
    // 获取经福缘和保底调整后的实际掉率
    final actualRates = table.calculateActualRates(fortune, pity);

    // 会话修正（模块 3）：greed buff / bloodMoon mod 提高高品质掉率（权重乘数）
    final qMult = mods?.dropQualityMultiplier ?? 1.0;
    if (qMult != 1.0) {
      for (final q in [Quality.unique, Quality.divine, Quality.legendary]) {
        actualRates[q] = (actualRates[q] ?? 0) * qMult;
      }
      final total = actualRates.values.fold(0.0, (a, b) => a + b);
      if (total > 0) {
        actualRates.updateAll((k, v) => v / total);
      }
    }

    // 保底触发标志
    bool pityTriggered = false;

    // 保底检测：如果保底计数器已达到阈值，必掉暗金
    if (pity.isPityTriggered) {
      pityTriggered = true;
      return (Quality.unique, pityTriggered);
    }

    // 按概率随机选取品质
    var roll = _random.nextDouble();
    Quality? selected;
    double cumulative = 0;

    // 从高品质到低品质遍历，确保高品质优先
    final sortedQualities = Quality.values.toList()
      ..sort((a, b) => b.index.compareTo(a.index));

    for (final q in sortedQualities) {
      final rate = actualRates[q] ?? 0;
      cumulative += rate;
      if (roll < cumulative) {
        selected = q;
        break;
      }
    }

    // 兜底：选最低品质
    selected ??= Quality.normal;

    return (selected, pityTriggered);
  }

  // =================== 词缀生成 ===================

  /// 根据品质决定词缀数量（DESIGN.md 3.3.1）
  ///
  /// | 品质 | 词缀数 |
  /// | 凡品 | 1-2 |
  /// | 良品 | 2-3 |
  /// | 上品 | 3-4 |
  /// | 暗金 | 固定独特+2-4随机 |
  /// | 神品 | 5-8 |
  /// | 传说 | 6-10 |
  int _rollAffixCount(Quality quality) {
    final min = quality.minAffixes;
    final max = quality.maxAffixes;
    if (max <= min) return min;
    return min + _random.nextInt(max - min + 1);
  }

  /// 从词缀池中加权随机选取指定数量的词缀
  ///
  /// [availableAffixIds] 可用的词缀ID列表（来自装备基础配置的affixPool）
  /// [count] 需要选取的词缀数量
  /// [requireBothPositions] 是否要求同时包含前缀和后缀
  List<Affix> _rollAffixes({
    required List<String> availableAffixIds,
    required int count,
    bool requireBothPositions = false,
  }) {
    // 从配置中获取可用词缀
    final candidates = <AffixConfig>[];
    for (final id in availableAffixIds) {
      final affixCfg = _config.getAffix(id);
      if (affixCfg != null) {
        candidates.add(affixCfg);
      }
    }

    if (candidates.isEmpty || count <= 0) return const [];

    // 按位置分组
    final prefixes =
        candidates.where((a) => a.type == 'prefix').toList();
    final suffixes =
        candidates.where((a) => a.type == 'suffix').toList();

    final result = <Affix>[];
    final used = <String>{};

    // 如果要求同时包含前缀和后缀
    if (requireBothPositions && prefixes.isNotEmpty && suffixes.isNotEmpty) {
      // 先各选一个
      final prefix = _weightedPickAffix(prefixes, used);
      if (prefix != null) {
        result.add(prefix);
        used.add(prefix.id);
      }
      final suffix = _weightedPickAffix(suffixes, used);
      if (suffix != null) {
        result.add(suffix);
        used.add(suffix.id);
      }
      count -= 2;
    }

    // 从剩余候选中随机选取
    final remaining = candidates.where((a) => !used.contains(a.id)).toList();
    for (var i = 0; i < count && remaining.isNotEmpty; i++) {
      final picked = _weightedPickAffix(remaining, used);
      if (picked != null) {
        result.add(picked);
        used.add(picked.id);
        remaining.removeWhere((a) => a.id == picked.id);
      }
    }

    return result;
  }

  /// 从词缀列表中按权重随机选取一个
  Affix? _weightedPickAffix(List<AffixConfig> candidates, Set<String> used) {
    final available = candidates.where((a) => !used.contains(a.id)).toList();
    if (available.isEmpty) return null;

    final totalWeight =
        available.fold(0, (sum, a) => sum + a.weight);
    if (totalWeight <= 0) {
      return _rollAffixFromConfig(available[_random.nextInt(available.length)]);
    }

    var roll = _random.nextInt(totalWeight);
    for (final a in available) {
      roll -= a.weight;
      if (roll < 0) {
        return _rollAffixFromConfig(a);
      }
    }
    return _rollAffixFromConfig(available.last);
  }

  /// 将AffixConfig随机滚动数值并生成Affix实例
  Affix _rollAffixFromConfig(AffixConfig cfg) {
    // 在 minVal 和 maxVal 之间随机
    final value = cfg.minVal >= cfg.maxVal
        ? cfg.minVal
        : cfg.minVal + _random.nextInt(cfg.maxVal - cfg.minVal + 1);

    return Affix(
      id: cfg.id,
      name: cfg.name,
      position: cfg.type == 'prefix' ? AffixPosition.prefix : AffixPosition.suffix,
      effects: {cfg.stat: value},
      rolledValues: {cfg.stat: value},
    );
  }

  // =================== 暗金掉落 ===================

  /// 选取暗金装备（DESIGN.md 3.3.5 暗金设计原则）
  ///
  /// 从掉落表的 uniquePool 中随机选取一件暗金装备。
  /// 如 uniquePool 为空，则从全局 unique_equipment.json 中随机选取。
  UniqueEquipment? _pickUniqueEquipment(DropTable table) {
    List<UniqueEquipment> pool;

    if (table.uniquePool.isNotEmpty) {
      // 从掉落表指定的暗金池中选取
      pool = table.uniquePool
          .map((id) => _config.getUniqueEquipment(id))
          .whereType<UniqueEquipment>()
          .toList();
    } else {
      // 从全局暗金列表中随机
      pool = _config.uniqueEquipments;
    }

    if (pool.isEmpty) return null;
    return pool[_random.nextInt(pool.length)];
  }

  /// 生成暗金装备实例（固定独特效果 + 随机词缀）
  Equipment _generateUniqueEquipment(UniqueEquipment uniqueDef,
      {int affixMultiplier = 1}) {
    // 滚动暗金的随机词缀（2-4条），jackpot 时翻倍
    final baseCount = 2 + _random.nextInt(3); // 2, 3, or 4
    final affixCount = baseCount * affixMultiplier;
    final affixes = <Affix>[];

    for (final affixRange in uniqueDef.randomAffixes) {
      if (affixes.length >= affixCount) break;
      // 使用 AffixRange.roll 方法滚动数值
      final seed = _random.nextInt(0x7FFFFFFF);
      final affix = affixRange.roll(seed);
      affixes.add(affix);
    }

    // 生成装备名（暗金名称 + 词缀修饰）
    final prefixNames = affixes
        .where((a) => a.position == AffixPosition.prefix)
        .map((a) => a.name)
        .join('');
    final suffixNames = affixes
        .where((a) => a.position == AffixPosition.suffix)
        .map((a) => a.name)
        .join(' ');
    final fullName = '$prefixNames${uniqueDef.name}$suffixNames';

    return Equipment(
      id: 'eq_${uniqueDef.id}_${_random.nextInt(999999)}',
      baseId: uniqueDef.id,
      quality: Quality.unique,
      name: fullName.trim(),
      affixes: affixes,
      reinforceLevel: 0,
      itemLevel: uniqueDef.itemLevel,
      setId: uniqueDef.setId,
      uniqueId: uniqueDef.id,
    );
  }

  // =================== 普通装备生成 ===================

  /// 生成普通品质装备实例（凡品~上品）
  Equipment _generateNormalEquipment({
    required DropTable table,
    required Quality quality,
    int affixMultiplier = 1,
  }) {
    // 从掉落表的装备池中随机选取基础装备
    final pool = table.equipmentPool;
    if (pool.isEmpty) {
      // 兜底：返回一个默认装备
      return Equipment(
        id: 'eq_fallback_${_random.nextInt(999999)}',
        baseId: 'eq_w_001',
        quality: quality,
        name: '未知装备',
        affixes: const [],
        itemLevel: 1,
      );
    }

    final baseId = pool[_random.nextInt(pool.length)];
    final base = _config.getEquipmentBase(baseId);

    // 生成装备名
    String baseName = base?.name ?? '未知装备';
    int itemLevel = base?.itemLevel ?? 1;

    // 词缀数量（jackpot 时翻倍）
    final affixCount = _rollAffixCount(quality) * affixMultiplier;
    // 词缀池兜底：装备基础配置无词缀池时用全局词缀池
    var availableAffixIds = base?.affixPool ?? const [];
    if (availableAffixIds.isEmpty) {
      availableAffixIds = _config.affixConfigs
          .map((a) => a.id)
          .where((id) => id.startsWith('prefix_') || id.startsWith('suffix_'))
          .toList();
    }

    // 上品以上要求同时包含前缀和后缀
    final requireBoth =
        quality.index >= Quality.rare.index && affixCount >= 2;

    var affixes = _rollAffixes(
      availableAffixIds: availableAffixIds,
      count: affixCount,
      requireBothPositions: requireBoth,
    );

    // 品质分数保底：若分数未达标，最多补滚2轮
    var guard = 0;
    while (guard < 2 &&
        !QualityScorer.meetsMinimumQuality(
          quality: quality,
          affixes: affixes,
          itemLevel: itemLevel,
        ) &&
        availableAffixIds.isNotEmpty) {
      affixes = _rollAffixes(
        availableAffixIds: availableAffixIds,
        count: affixCount + 1 + guard, // 每次补滚多一条词缀
        requireBothPositions: requireBoth,
      );
      guard++;
    }

    // 生成装备名
    final prefixNames = affixes
        .where((a) => a.position == AffixPosition.prefix)
        .map((a) => a.name)
        .join('');
    final suffixNames = affixes
        .where((a) => a.position == AffixPosition.suffix)
        .map((a) => a.name)
        .join(' ');
    final fullName = suffixNames.isNotEmpty
        ? '$prefixNames$baseName $suffixNames'
        : '$prefixNames$baseName';

    return Equipment(
      id: 'eq_${baseId}_${_random.nextInt(999999)}',
      baseId: baseId,
      quality: quality,
      name: fullName.trim(),
      affixes: affixes,
      reinforceLevel: 0,
      itemLevel: itemLevel,
      setId: base?.setImage,
    );
  }

  // =================== 掉落闪光等级 ===================

  /// 根据品质决定掉落闪光等级（DESIGN.md 3.2.4）
  ///
  /// 凡品/良品: 简短文字
  /// 上品: 带词条
  /// 暗金: 仪式感停顿 + 完整描述 + 配图
  /// 神品/传说: 全屏文字特效 + 故事化掉落叙事 + 配图
  DropFlashLevel _getFlashLevel(Quality quality) {
    return DropFlashLevel.fromQuality(quality);
  }

  // =================== 主掉落接口 ===================

  /// 执行一次掉落计算
  ///
  /// [dropTableId] 掉落表ID
  /// [fortune] 玩家福缘值
  /// [pity] 当前保底计数器
  /// [realmId] 秘境ID
  /// [layer] 层数
  /// [sourceId] 掉落来源（敌人/Boss ID）
  /// [isAutoRun] 是否连刷模式
  ///
  /// 返回掉落结果（含装备实例、记录、闪光等级、更新后的保底计数器）
  DropResult? generateDrop({
    required String dropTableId,
    required int fortune,
    required PityCounter pity,
    required String realmId,
    required int layer,
    required String sourceId,
    bool isAutoRun = false,
    SessionMods? mods,
  }) {
    final table = _config.getDropTable(dropTableId);
    if (table == null) return null;

    // 0. 词缀翻倍惊喜判定（5%）
    final jackpot = _random.nextInt(100) < 5;

    // 1. 品质判定（含福缘加成+保底机制+会话修正）
    final (quality, pityTriggered) = _rollQuality(
      table: table,
      fortune: fortune,
      pity: pity,
      mods: mods,
    );

    // 2. 生成装备实例
    Equipment equipment;
    String? uniqueEffectDesc;

    if (quality.isUniqueOrAbove) {
      // 暗金以上品质 → 从暗金池中选取
      final uniqueDef = _pickUniqueEquipment(table);
      if (uniqueDef != null) {
        equipment = _generateUniqueEquipment(
          uniqueDef,
          affixMultiplier: jackpot ? 2 : 1,
        );
        uniqueEffectDesc = uniqueDef.uniqueEffects
            .map((e) => e.description)
            .join('；');
      } else {
        // 暗金池为空，降级为上品
        equipment = _generateNormalEquipment(
          table: table,
          quality: Quality.rare,
          affixMultiplier: jackpot ? 2 : 1,
        );
      }
    } else {
      // 普通品质装备
      equipment = _generateNormalEquipment(
        table: table,
        quality: quality,
        affixMultiplier: jackpot ? 2 : 1,
      );
    }

    // 3. 闪光等级
    final flashLevel = _getFlashLevel(quality);

    // 4. 更新保底计数器
    PityCounter updatedPity;
    if (quality.isUniqueOrAbove) {
      // 掉了暗金+ → 重置保底
      updatedPity = pity.reset();
    } else {
      // 未掉暗金 → 递增保底
      updatedPity = pity.increment();
    }

    // 5. 生成掉落记录
    final record = DropRecord(
      equipmentId: equipment.id,
      realmId: realmId,
      layer: layer,
      timestamp: DateTime.now(),
      quality: quality,
      sourceId: sourceId,
      isAutoRun: isAutoRun,
    );

    return DropResult(
      equipment: equipment,
      record: record,
      flashLevel: flashLevel,
      updatedPity: updatedPity,
      isPityTriggered: pityTriggered,
      uniqueEffectDesc: uniqueEffectDesc,
      isJackpot: jackpot,
    );
  }

  /// 批量掉落（一次击杀多个敌人时的掉落）
  ///
  /// [count] 掉落次数
  /// 返回所有掉落结果列表
  List<DropResult> generateDrops({
    required String dropTableId,
    required int fortune,
    required PityCounter pity,
    required String realmId,
    required int layer,
    required String sourceId,
    required int count,
    bool isAutoRun = false,
    SessionMods? mods,
  }) {
    final results = <DropResult>[];
    var currentPity = pity;

    for (var i = 0; i < count; i++) {
      final result = generateDrop(
        dropTableId: dropTableId,
        fortune: fortune,
        pity: currentPity,
        realmId: realmId,
        layer: layer,
        sourceId: sourceId,
        isAutoRun: isAutoRun,
        mods: mods,
      );
      if (result != null) {
        results.add(result);
        currentPity = result.updatedPity;
      }
    }

    return results;
  }

  /// 生成掉落展示文本（DESIGN.md 3.2.4 掉落闪光）
  ///
  /// 根据闪光等级生成不同详细程度的展示文本。
  String generateDropDisplayText(DropResult drop) {
    final eq = drop.equipment;
    final qualityTag = eq.quality.colorTag;

    return switch (drop.flashLevel) {
      DropFlashLevel.plain =>
        // 凡品/良品: 简短文字 "> 获得【良品】精钢剑"
        '> 获得${qualityTag}【${eq.quality.displayName}】${eq.name}',
      DropFlashLevel.detailed =>
        // 上品: 带词条 "> ★【上品】寒铁剑 | 外功+15% 破甲"
        '> ★${qualityTag}【${eq.quality.displayName}】${eq.name}'
        ' | ${eq.affixes.map((a) => '${a.name}${a.rolledValues.values.first}').join(' ')}',
      DropFlashLevel.ceremonial =>
        // 暗金: 仪式感停顿 + 完整描述 + 配图
        '★★ ${eq.quality.colorTag}【${eq.quality.displayName}】${eq.name}'
        '${drop.uniqueEffectDesc != null ? '\n  独特效果: ${drop.uniqueEffectDesc}' : ''}'
        '${eq.affixes.isNotEmpty ? '\n  词缀: ${eq.affixes.map((a) => '${a.name}${a.rolledValues.values.first}').join(' | ')}' : ''}'
        '${drop.isPityTriggered ? '\n  [保底触发]' : ''}',
      DropFlashLevel.legendary =>
        // 神品/传说: 全屏文字特效 + 故事化掉落叙事
        '★★★ ${eq.quality.colorTag}【${eq.quality.displayName}】${eq.name}'
        '${drop.uniqueEffectDesc != null ? '\n  独特效果: ${drop.uniqueEffectDesc}' : ''}'
        '${eq.affixes.isNotEmpty ? '\n  词缀: ${eq.affixes.map((a) => '${a.name}${a.rolledValues.values.first}').join(' | ')}' : ''}'
        '${drop.isPityTriggered ? '\n  [保底触发]' : ''}',
    };
  }
}
