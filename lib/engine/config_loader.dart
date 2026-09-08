// =============================================================================
// config_loader.dart — 配置加载器
//
// 对应 DESIGN.md 章节：
//   4.3 数据驱动架构 — 所有游戏内容用JSON配置
//   4.5 离线/在线设计 — 远程配置拉取(CDN)接口预留
//
// 功能：
//   - 从 /assets/config/ 加载所有JSON配置文件
//   - 解析为Dart对象（使用已有model类的fromJson）
//   - 提供统一的 getConfig 接口
//   - 支持远程配置拉取（未来CDN更新）的接口预留
// =============================================================================

import 'dart:convert';
import 'dart:typed_data';

import '../models/equipment.dart';
import '../models/unique_effect.dart';
import '../models/drop.dart';
import '../models/narration.dart';
import '../models/martial_art.dart';
import '../models/meridian.dart';
import '../models/enums.dart';
import '../models/heart_mantra.dart';
import '../models/secret_realm.dart';
import '../models/enemy.dart';
import '../utils/app_logger.dart';

/// 配置类型枚举 — 标识每种JSON配置文件
enum ConfigType {
  equipmentBase('equipment_base.json', '装备基础'),
  affixes('affixes.json', '词缀'),
  uniqueEquipment('unique_equipment.json', '暗金装备'),
  martialArts('martial_arts.json', '武功'),
  meridians('meridians.json', '经脉'),
  dropTables('drop_tables.json', '掉落表'),
  narrationTemplates('narration_templates.json', '描写模板'),
  // 扩展配置类型（M4: 补充9个缺失的ConfigType）
  enemies('enemies.json', '敌人'),
  events('events.json', '奇遇事件'),
  realms('realms.json', '秘境'),
  heartMantras('heart_mantras.json', '心法'),
  equipmentExpansion('equipment_expansion.json', '装备扩展'),
  uniqueExpansion('unique_expansion.json', '暗金扩展'),
  martialArtsExpansion('martial_arts_expansion.json', '武功扩展'),
  narrationExpansion('narration_expansion.json', '描写模板扩展'),
  imageManifest('image_manifest.json', '图片清单');

  const ConfigType(this.fileName, this.displayName);

  /// JSON文件名（在 /assets/config/ 下）
  final String fileName;

  /// 显示名称
  final String displayName;
}

/// 词缀配置条目（对应 affixes.json 的格式）
///
/// affixes.json 的格式与 AffixRange 不同：
/// {id, name, type(prefix/suffix), stat, minVal, maxVal, weight}
/// 需要转换为 AffixRange 供引擎使用
class AffixConfig {
  final String id;
  final String name;
  final String type; // "prefix" 或 "suffix"
  final String stat;
  final int minVal;
  final int maxVal;
  final int weight;

  const AffixConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.stat,
    required this.minVal,
    required this.maxVal,
    this.weight = 100,
  });

  factory AffixConfig.fromJson(Map<String, dynamic> json) => AffixConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        stat: json['stat'] as String,
        minVal: json['minVal'] as int,
        maxVal: json['maxVal'] as int,
        weight: json['weight'] as int? ?? 100,
      );

  /// 转换为 AffixRange（供 AffixRange.roll 使用）
  AffixRange toAffixRange() {
    final position =
        type == 'prefix' ? AffixPosition.prefix : AffixPosition.suffix;
    return AffixRange(
      affixId: id,
      name: name,
      position: position,
      ranges: {stat: (minVal, maxVal)},
    );
  }
}

/// 武功配置条目（对应 martial_arts.json 的格式）
///
/// martial_arts.json 格式与 MartialArt 略有不同：
/// {id, name, type, elementAffinity, tier, proficiencyBase, description}
class MartialArtConfig {
  final String id;
  final String name;
  final String type; // inner / outer / lightness / mantra
  final String elementAffinity;
  final String tier;
  final int proficiencyBase;
  final String description;

  const MartialArtConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.elementAffinity,
    required this.tier,
    required this.proficiencyBase,
    this.description = '',
  });

  factory MartialArtConfig.fromJson(Map<String, dynamic> json) =>
      MartialArtConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        elementAffinity: json['elementAffinity'] as String,
        tier: json['tier'] as String,
        proficiencyBase: json['proficiencyBase'] as int,
        description: json['description'] as String? ?? '',
      );

  /// 转换为 MartialArt 模型
  MartialArt toMartialArt() {
    final mType = switch (type) {
      'inner' => MartialType.internal,
      'outer' => MartialType.external,
      'lightness' => MartialType.lightness,
      'mantra' => MartialType.mantra, // 心法类型，不再默认外功
      _ => MartialType.external,
    };
    final affinity = ElementAffinity.fromJson(elementAffinity);
    final profLevel = ProficiencyLevel.fromProficiency(proficiencyBase);
    return MartialArt(
      id: id,
      name: name,
      type: mType,
      proficiency: proficiencyBase,
      proficiencyLevel: profLevel,
      elementAffinity: affinity,
      damageMultiplier: 1.0 + proficiencyBase * 0.01,
      isActive: type != 'mantra',
      description: description,
    );
  }
}

/// 经脉穴位配置条目（对应 meridians.json 中的 nodes 格式）
class MeridianNodeConfig {
  final int index;
  final String name;
  final String baseStat;
  final int statValue;

  const MeridianNodeConfig({
    required this.index,
    required this.name,
    required this.baseStat,
    required this.statValue,
  });

  factory MeridianNodeConfig.fromJson(Map<String, dynamic> json) =>
      MeridianNodeConfig(
        index: json['index'] as int,
        name: json['name'] as String,
        baseStat: json['baseStat'] as String,
        statValue: json['statValue'] as int,
      );
}

/// 经脉配置条目（对应 meridians.json 中的经脉定义）
class MeridianConfigEntry {
  final String id;
  final String name;
  final String type; // "yang" / "yin"
  final List<MeridianNodeConfig> nodes;
  final String description;
  final int tier;
  final List<String> conflictMeridians;
  final List<String> synergyMeridians;

  const MeridianConfigEntry({
    required this.id,
    required this.name,
    required this.type,
    this.nodes = const [],
    this.description = '',
    this.tier = 1,
    this.conflictMeridians = const [],
    this.synergyMeridians = const [],
  });

  factory MeridianConfigEntry.fromJson(Map<String, dynamic> json) =>
      MeridianConfigEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        nodes: (json['nodes'] as List?)
                ?.map((e) => MeridianNodeConfig.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        description: json['description'] as String? ?? '',
        tier: json['tier'] as int? ?? 1,
        conflictMeridians:
            (json['conflictMeridians'] as List?)?.cast<String>() ?? const [],
        synergyMeridians:
            (json['synergyMeridians'] as List?)?.cast<String>() ?? const [],
      );

  /// 转换为 MeridianConfig 模型
  MeridianConfig toMeridianConfig() {
    return MeridianConfig(
      id: id,
      name: name,
      yinYang: MeridianYinYang.fromJson(type),
      nodeCount: nodes.length,
      nodeNames: nodes.map((n) => n.name).toList(),
      // 阳脉与阴脉相克
      conflictMeridianId:
          type == 'yang' ? id.replaceAll('yang', 'yin') : id.replaceAll('yin', 'yang'),
    );
  }
}

/// 奇遇事件配置条目（对应 events.json）
class EventConfig {
  final String id;
  final String type; // combat / choice / encounter
  final String realmId;
  final String name;
  final String description;
  final List<String> triggerConditions;
  final String? enemyId;
  final bool isAutoRun;
  final String? narration;

  const EventConfig({
    required this.id,
    required this.type,
    required this.realmId,
    required this.name,
    required this.description,
    this.triggerConditions = const [],
    this.enemyId,
    this.isAutoRun = false,
    this.narration,
  });

  factory EventConfig.fromJson(Map<String, dynamic> json) => EventConfig(
        id: json['id'] as String,
        type: json['type'] as String,
        realmId: json['realmId'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        triggerConditions: (json['triggerConditions'] as List?)?.cast<String>() ?? const [],
        enemyId: json['enemyId'] as String?,
        isAutoRun: json['isAutoRun'] as bool? ?? false,
        narration: json['narration'] as String?,
      );
}

/// 秘境配置条目（对应 realms.json — 字段名与 RealmConfig 略有差异）
class RealmConfigEntry {
  final String id;
  final String name;
  final String type;
  final String description;
  final int layers;
  final int recommendedPower;
  final String bossId;
  final String bossDropTableId;
  final List<String> uniqueDropPool;
  final List<String> enemyPool;
  final int minLevel;

  const RealmConfigEntry({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.layers,
    required this.recommendedPower,
    required this.bossId,
    required this.bossDropTableId,
    this.uniqueDropPool = const [],
    this.enemyPool = const [],
    this.minLevel = 1,
  });

  factory RealmConfigEntry.fromJson(Map<String, dynamic> json) => RealmConfigEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        description: json['description'] as String,
        layers: json['layers'] as int? ?? json['totalLayers'] as int? ?? 1,
        recommendedPower: json['recommendedPower'] as int,
        bossId: json['bossId'] as String? ?? '',
        bossDropTableId: json['bossDropTableId'] as String? ?? '',
        uniqueDropPool: (json['uniqueDropPool'] as List?)?.cast<String>() ?? const [],
        enemyPool: (json['enemyPool'] as List?)?.cast<String>() ?? const [],
        minLevel: json['minLevel'] as int? ?? 1,
      );

  /// 转换为 RealmConfig 模型
  RealmConfig toRealmConfig() {
    return RealmConfig(
      id: id,
      name: name,
      type: RealmType.fromJson(type),
      description: description,
      totalLayers: layers,
      recommendedPower: recommendedPower,
      bossDropTableId: bossDropTableId,
      uniqueDropPool: uniqueDropPool,
      isBeginnerFriendly: minLevel <= 1,
    );
  }
}

/// 敌人配置条目（对应 enemies.json — 包含普通敌人和Boss）
///
/// enemies.json 中 type 字段区分 normal/elite/boss，
/// Boss类型额外包含 phases/bossDropTableId/lore/bossImageUrl
class EnemyConfig {
  final String id;
  final String name;
  final String title;
  final String realmId;
  final String type; // normal / elite / boss
  final int powerIndex;
  final int health;
  final int externalAttack;
  final int internalAttack;
  final int defense;
  final int initiative;
  final int dodgeRate;
  final int critRate;
  final String elementAffinity;
  final String dropTableId;
  final String? bossDropTableId;
  final List<EnemyMechanic> mechanics;
  final List<BossPhase> phases;
  final String? lore;
  final String? bossImageUrl;
  final String enemyType;
  final String description;

  const EnemyConfig({
    required this.id,
    required this.name,
    required this.title,
    required this.realmId,
    required this.type,
    required this.powerIndex,
    required this.health,
    required this.externalAttack,
    required this.internalAttack,
    required this.defense,
    required this.initiative,
    required this.dodgeRate,
    required this.critRate,
    required this.elementAffinity,
    required this.dropTableId,
    this.bossDropTableId,
    this.mechanics = const [],
    this.phases = const [],
    this.lore,
    this.bossImageUrl,
    this.enemyType = '杂兵',
    this.description = '',
  });

  factory EnemyConfig.fromJson(Map<String, dynamic> json) => EnemyConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        title: json['title'] as String? ?? '',
        realmId: json['realmId'] as String? ?? '',
        type: json['type'] as String? ?? 'normal',
        powerIndex: json['powerIndex'] as int? ?? 0,
        health: json['health'] as int? ?? 0,
        externalAttack: json['externalAttack'] as int? ?? 0,
        internalAttack: json['internalAttack'] as int? ?? 0,
        defense: json['defense'] as int? ?? 0,
        initiative: json['initiative'] as int? ?? 0,
        dodgeRate: json['dodgeRate'] as int? ?? 0,
        critRate: json['critRate'] as int? ?? 0,
        elementAffinity: json['elementAffinity'] as String? ?? 'neutral',
        dropTableId: json['dropTableId'] as String? ?? '',
        bossDropTableId: json['bossDropTableId'] as String?,
        mechanics: (json['mechanics'] as List?)
                ?.map((e) => EnemyMechanic.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        phases: (json['phases'] as List?)
                ?.map((e) => BossPhase.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        lore: json['lore'] as String?,
        bossImageUrl: json['bossImageUrl'] as String?,
        enemyType: json['enemyType'] as String? ?? '杂兵',
        description: json['description'] as String? ?? '',
      );

  /// 是否为Boss
  bool get isBoss => type == 'boss';

  /// 是否为精英
  bool get isElite => type == 'elite' || isBoss;

  /// 转换为 Enemy 模型
  Enemy toEnemy() {
    final affinity = ElementAffinity.fromJson(elementAffinity);
    if (isBoss) {
      return Boss(
        id: id,
        name: name,
        powerIndex: powerIndex,
        health: health,
        innerEnergy: 0,
        externalAttack: externalAttack,
        internalAttack: internalAttack,
        defense: defense,
        initiative: initiative,
        dodgeRate: dodgeRate,
        critRate: critRate,
        elementAffinity: affinity,
        dropTableId: dropTableId,
        mechanics: mechanics,
        description: description,
        phases: phases,
        bossDropTableId: bossDropTableId,
        lore: lore ?? '',
        bossImageUrl: bossImageUrl,
      );
    }
    return Enemy(
      id: id,
      name: name,
      powerIndex: powerIndex,
      health: health,
      innerEnergy: 0,
      externalAttack: externalAttack,
      internalAttack: internalAttack,
      defense: defense,
      initiative: initiative,
      dodgeRate: dodgeRate,
      critRate: critRate,
      elementAffinity: affinity,
      dropTableId: dropTableId,
      mechanics: mechanics,
      enemyType: enemyType,
      isElite: isElite,
      description: description,
    );
  }
}

/// 图片清单条目（对应 image_manifest.json）
class ImageManifestEntry {
  final String id;
  final String type; // scene / boss / equipment / icon
  final String path;
  final int size; // KB
  final String priority; // must_have / optional
  final String description;

  const ImageManifestEntry({
    required this.id,
    required this.type,
    required this.path,
    this.size = 0,
    this.priority = 'optional',
    this.description = '',
  });

  factory ImageManifestEntry.fromJson(Map<String, dynamic> json) =>
      ImageManifestEntry(
        id: json['id'] as String,
        type: json['type'] as String,
        path: json['path'] as String,
        size: json['size'] as int? ?? 0,
        priority: json['priority'] as String? ?? 'optional',
        description: json['description'] as String? ?? '',
      );
}

/// 配置加载器（DESIGN.md 4.3 数据驱动架构）
///
/// 负责从 /assets/config/ 加载所有JSON配置文件，解析为Dart对象。
/// 支持远程配置拉取（未来CDN更新）的接口预留。
///
/// 使用方式：
///   // Flutter环境中（通过rootBundle）
///   final loader = ConfigLoader(assetBundle: rootBundle);
///   await loader.loadAll();
///   final equipmentBases = loader.equipmentBases;
///
///   // 测试环境中（直接传入JSON字符串）
///   final loader = ConfigLoader.forTesting();
///   loader.loadFromJsonMap({...});
class ConfigLoader {
  ConfigLoader._();

  // =================== 已加载的配置数据 ===================

  /// 装备基础列表（equipment_base.json）
  List<EquipmentBase> _equipmentBases = const [];
  List<EquipmentBase> get equipmentBases => _equipmentBases;

  /// 词缀配置列表（affixes.json）
  List<AffixConfig> _affixConfigs = const [];
  List<AffixConfig> get affixConfigs => _affixConfigs;

  /// 词缀ID → AffixConfig 的快速查找表
  Map<String, AffixConfig> _affixMap = {};
  Map<String, AffixConfig> get affixMap => _affixMap;

  /// 暗金装备列表（unique_equipment.json）
  List<UniqueEquipment> _uniqueEquipments = const [];
  List<UniqueEquipment> get uniqueEquipments => _uniqueEquipments;

  /// 暗金ID → UniqueEquipment 的快速查找表
  Map<String, UniqueEquipment> _uniqueMap = {};
  Map<String, UniqueEquipment> get uniqueMap => _uniqueMap;

  /// 武功配置列表（martial_arts.json）
  List<MartialArtConfig> _martialArtConfigs = const [];
  List<MartialArtConfig> get martialArtConfigs => _martialArtConfigs;

  /// 武功ID → MartialArtConfig 的快速查找表
  Map<String, MartialArtConfig> _martialArtMap = {};
  Map<String, MartialArtConfig> get martialArtMap => _martialArtMap;

  /// 经脉配置列表（meridians.json）
  List<MeridianConfigEntry> _meridianConfigs = const [];
  List<MeridianConfigEntry> get meridianConfigs => _meridianConfigs;

  /// 掉落表列表（drop_tables.json）
  List<DropTable> _dropTables = const [];
  List<DropTable> get dropTables => _dropTables;

  /// 掉落表ID → DropTable 的快速查找表
  Map<String, DropTable> _dropTableMap = {};
  Map<String, DropTable> get dropTableMap => _dropTableMap;

  /// 战斗描写模板列表（narration_templates.json）
  List<NarrationTemplate> _narrationTemplates = const [];
  List<NarrationTemplate> get narrationTemplates => _narrationTemplates;

  // =================== 扩展配置数据 ===================

  /// 敌人配置列表（enemies.json）
  List<EnemyConfig> _enemyConfigs = const [];
  List<EnemyConfig> get enemyConfigs => _enemyConfigs;

  /// 敌人ID → EnemyConfig 的快速查找表
  Map<String, EnemyConfig> _enemyMap = {};
  Map<String, EnemyConfig> get enemyMap => _enemyMap;

  /// 奇遇事件配置列表（events.json）
  List<EventConfig> _eventConfigs = const [];
  List<EventConfig> get eventConfigs => _eventConfigs;

  /// 秘境配置列表（realms.json）
  List<RealmConfigEntry> _realmConfigs = const [];
  List<RealmConfigEntry> get realmConfigs => _realmConfigs;

  /// 秘境ID → RealmConfigEntry 的快速查找表
  Map<String, RealmConfigEntry> _realmMap = {};
  Map<String, RealmConfigEntry> get realmMap => _realmMap;

  /// 心法配置列表（heart_mantras.json）
  List<HeartMantra> _heartMantras = const [];
  List<HeartMantra> get heartMantras => _heartMantras;

  /// 心法ID → HeartMantra 的快速查找表
  Map<String, HeartMantra> _heartMantraMap = {};
  Map<String, HeartMantra> get heartMantraMap => _heartMantraMap;

  /// 装备扩展列表（equipment_expansion.json）
  List<EquipmentBase> _equipmentExpansion = const [];
  List<EquipmentBase> get equipmentExpansion => _equipmentExpansion;

  /// 暗金扩展列表（unique_expansion.json）
  List<UniqueEquipment> _uniqueExpansion = const [];
  List<UniqueEquipment> get uniqueExpansion => _uniqueExpansion;

  /// 暗金扩展ID → UniqueEquipment 的快速查找表
  Map<String, UniqueEquipment> _uniqueExpansionMap = {};
  Map<String, UniqueEquipment> get uniqueExpansionMap => _uniqueExpansionMap;

  /// 武功扩展列表（martial_arts_expansion.json）
  List<MartialArtConfig> _martialArtsExpansion = const [];
  List<MartialArtConfig> get martialArtsExpansion => _martialArtsExpansion;

  /// 武功扩展ID → MartialArtConfig 的快速查找表
  Map<String, MartialArtConfig> _martialArtsExpansionMap = {};
  Map<String, MartialArtConfig> get martialArtsExpansionMap => _martialArtsExpansionMap;

  /// 战斗描写模板扩展列表（narration_expansion.json）
  List<NarrationTemplate> _narrationExpansion = const [];
  List<NarrationTemplate> get narrationExpansion => _narrationExpansion;

  /// 合并后的描写模板（基础+扩展，供 NarrationEngine 使用）
  List<NarrationTemplate> get allNarrationTemplates =>
      [..._narrationTemplates, ..._narrationExpansion];

  /// 图片清单列表（image_manifest.json）
  List<ImageManifestEntry> _imageManifest = const [];
  List<ImageManifestEntry> get imageManifest => _imageManifest;

  /// 图片ID → ImageManifestEntry 的快速查找表
  Map<String, ImageManifestEntry> _imageMap = {};
  Map<String, ImageManifestEntry> get imageMap => _imageMap;

  /// 是否已加载完成
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  // =================== 加载方法 ===================

  /// 从JSON字符串Map批量加载所有配置（测试环境用）
  ///
  /// [jsonMap] 的key是ConfigType，value是对应的JSON字符串
  void loadFromJsonMap(Map<ConfigType, String> jsonMap) {
    AppLogger.instance.info('ConfigLoader: 开始解析配置...');

    if (jsonMap.containsKey(ConfigType.equipmentBase)) {
      try {
        _loadEquipmentBases(jsonMap[ConfigType.equipmentBase]!);
        AppLogger.instance.info('  ✅ 解析 equipment_base.json 成功 (${_equipmentBases.length} 条)');
      } catch (e) {
        AppLogger.instance.error('  ❌ 解析 equipment_base.json 失败: $e');
      }
    }
    if (jsonMap.containsKey(ConfigType.affixes)) {
      try {
        _loadAffixes(jsonMap[ConfigType.affixes]!);
        AppLogger.instance.info('  ✅ 解析 affixes.json 成功 (${_affixConfigs.length} 条)');
      } catch (e) {
        AppLogger.instance.error('  ❌ 解析 affixes.json 失败: $e');
      }
    }
    if (jsonMap.containsKey(ConfigType.uniqueEquipment)) {
      try {
        _loadUniqueEquipments(jsonMap[ConfigType.uniqueEquipment]!);
        AppLogger.instance.info('  ✅ 解析 unique_equipment.json 成功 (${_uniqueEquipments.length} 条)');
      } catch (e) {
        AppLogger.instance.error('  ❌ 解析 unique_equipment.json 失败: $e');
      }
    }
    if (jsonMap.containsKey(ConfigType.martialArts)) {
      try {
        _loadMartialArts(jsonMap[ConfigType.martialArts]!);
        AppLogger.instance.info('  ✅ 解析 martial_arts.json 成功 (${_martialArtConfigs.length} 条)');
      } catch (e) {
        AppLogger.instance.error('  ❌ 解析 martial_arts.json 失败: $e');
      }
    }
    if (jsonMap.containsKey(ConfigType.meridians)) {
      try {
        _loadMeridians(jsonMap[ConfigType.meridians]!);
        AppLogger.instance.info('  ✅ 解析 meridians.json 成功 (${_meridianConfigs.length} 条)');
      } catch (e) {
        AppLogger.instance.error('  ❌ 解析 meridians.json 失败: $e');
      }
    }
    if (jsonMap.containsKey(ConfigType.dropTables)) {
      try {
        _loadDropTables(jsonMap[ConfigType.dropTables]!);
        AppLogger.instance.info('  ✅ 解析 drop_tables.json 成功 (${_dropTables.length} 条)');
      } catch (e) {
        AppLogger.instance.error('  ❌ 解析 drop_tables.json 失败: $e');
      }
    }
    if (jsonMap.containsKey(ConfigType.narrationTemplates)) {
      try {
        _loadNarrationTemplates(jsonMap[ConfigType.narrationTemplates]!);
        AppLogger.instance.info('  ✅ 解析 narration_templates.json 成功 (${_narrationTemplates.length} 条)');
      } catch (e) {
        AppLogger.instance.error('  ❌ 解析 narration_templates.json 失败: $e');
      }
    }
    // 扩展配置
    if (jsonMap.containsKey(ConfigType.enemies)) {
      try {
        _loadEnemies(jsonMap[ConfigType.enemies]!);
        AppLogger.instance.info('  ✅ 解析 enemies.json 成功 (${_enemyConfigs.length} 条)');
      } catch (e) {
        AppLogger.instance.error('  ❌ 解析 enemies.json 失败: $e');
      }
    }
    if (jsonMap.containsKey(ConfigType.events)) {
      try {
        _loadEvents(jsonMap[ConfigType.events]!);
        AppLogger.instance.info('  ✅ 解析 events.json 成功 (${_eventConfigs.length} 条)');
      } catch (e) {
        AppLogger.instance.error('  ❌ 解析 events.json 失败: $e');
      }
    }
    if (jsonMap.containsKey(ConfigType.realms)) {
      try {
        _loadRealms(jsonMap[ConfigType.realms]!);
        AppLogger.instance.info('  ✅ 解析 realms.json 成功 (${_realmConfigs.length} 条)');
      } catch (e) {
        AppLogger.instance.error('  ❌ 解析 realms.json 失败: $e');
      }
    }
    if (jsonMap.containsKey(ConfigType.heartMantras)) {
      try {
        _loadHeartMantras(jsonMap[ConfigType.heartMantras]!);
        AppLogger.instance.info('  ✅ 解析 heart_mantras.json 成功 (${_heartMantras.length} 条)');
      } catch (e) {
        AppLogger.instance.error('  ❌ 解析 heart_mantras.json 失败: $e');
      }
    }
    if (jsonMap.containsKey(ConfigType.equipmentExpansion)) {
      try {
        _loadEquipmentExpansion(jsonMap[ConfigType.equipmentExpansion]!);
        AppLogger.instance.info('  ✅ 解析 equipment_expansion.json 成功 (${_equipmentExpansion.length} 条)');
      } catch (e) {
        AppLogger.instance.error('  ❌ 解析 equipment_expansion.json 失败: $e');
      }
    }
    if (jsonMap.containsKey(ConfigType.uniqueExpansion)) {
      try {
        _loadUniqueExpansion(jsonMap[ConfigType.uniqueExpansion]!);
        AppLogger.instance.info('  ✅ 解析 unique_expansion.json 成功 (${_uniqueExpansion.length} 条)');
      } catch (e) {
        AppLogger.instance.error('  ❌ 解析 unique_expansion.json 失败: $e');
      }
    }
    if (jsonMap.containsKey(ConfigType.martialArtsExpansion)) {
      try {
        _loadMartialArtsExpansion(jsonMap[ConfigType.martialArtsExpansion]!);
        AppLogger.instance.info('  ✅ 解析 martial_arts_expansion.json 成功 (${_martialArtsExpansion.length} 条)');
      } catch (e) {
        AppLogger.instance.error('  ❌ 解析 martial_arts_expansion.json 失败: $e');
      }
    }
    if (jsonMap.containsKey(ConfigType.narrationExpansion)) {
      try {
        _loadNarrationExpansion(jsonMap[ConfigType.narrationExpansion]!);
        AppLogger.instance.info('  ✅ 解析 narration_expansion.json 成功 (${_narrationExpansion.length} 条)');
      } catch (e) {
        AppLogger.instance.error('  ❌ 解析 narration_expansion.json 失败: $e');
      }
    }
    if (jsonMap.containsKey(ConfigType.imageManifest)) {
      try {
        _loadImageManifest(jsonMap[ConfigType.imageManifest]!);
        AppLogger.instance.info('  ✅ 解析 image_manifest.json 成功 (${_imageManifest.length} 条)');
      } catch (e) {
        AppLogger.instance.error('  ❌ 解析 image_manifest.json 失败: $e');
      }
    }
    _isLoaded = true;
    AppLogger.instance.info('ConfigLoader: 配置解析完成');
  }

  /// 加载装备基础配置
  ///
  /// 注意：equipment_base.json 中武器使用 "baseDamage" 字段，
  /// 但护甲/饰品/奇物使用 "baseDefense" 字段。
  /// EquipmentBase.fromJson 读取的是 "baseDamage"，因此需要在此处
  /// 将 "baseDefense" 映射为 "baseDamage" 以兼容模型。
  void _loadEquipmentBases(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    _equipmentBases = list.map((rawJson) {
      final json = Map<String, dynamic>.from(rawJson as Map);
      // 字段名兼容：护甲/饰品/奇物使用 baseDefense，统一映射为 baseDamage
      if (!json.containsKey('baseDamage') && json.containsKey('baseDefense')) {
        json['baseDamage'] = json['baseDefense'];
      }
      return EquipmentBase.fromJson(json);
    }).toList();
  }

  /// 加载词缀配置
  void _loadAffixes(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    _affixConfigs = list
        .map((e) => AffixConfig.fromJson(e as Map<String, dynamic>))
        .toList();
    _affixMap = {for (final a in _affixConfigs) a.id: a};
  }

  /// 加载暗金装备配置
  ///
  /// 注意：unique_equipment.json 中的 uniqueEffects[].type 字段
  /// 使用了一些不在 EffectType 枚举中的字符串（如 onHitDebuff、onHitReflect 等）。
  /// 这些类型字符串会被存储在 UniqueEffect.params 中的原始值中，
  /// 以便引擎通过 params 而非 EffectType 枚举来识别效果。
  void _loadUniqueEquipments(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    _uniqueEquipments = list
        .whereType<Map<String, dynamic>>()
        .map((json) {
      try {
        return _parseUniqueEquipment(json);
      } catch (e) {
        AppLogger.instance.error('  unique_equipment 解析条目 ${json['id']} 失败: $e');
        return null;
      }
    }).whereType<UniqueEquipment>().toList();
    _uniqueMap = {for (final u in _uniqueEquipments) u.id: u};
  }

  /// 解析单个 UniqueEquipment 条目
  UniqueEquipment _parseUniqueEquipment(Map<String, dynamic> json) {
    final effects = (json['uniqueEffects'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((effectJson) {
      final typeStr = effectJson['type'] as String;
      EffectType effectType;
      try {
        effectType = EffectType.fromJson(typeStr);
      } catch (_) {
        effectType = _mapEffectType(typeStr);
      }
      return UniqueEffect(
        id: effectJson['id'] as String,
        description: effectJson['description'] as String,
        type: effectType,
        params: {
          ...Map<String, dynamic>.from(effectJson['params'] as Map? ?? {}),
          '_originalType': typeStr,
        },
      );
    }).toList();

    return UniqueEquipment(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      itemLevel: json['itemLevel'] as int,
      slot: EquipmentSlot.fromJson(json['slot'] as String),
      baseDamage: json['baseDamage'] as int? ?? 0,
      uniqueEffects: effects ?? const [],
      randomAffixes: (json['randomAffixes'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => AffixRange.fromJson(e))
              .toList() ??
          const [],
      requirements: Map<String, int>.from(json['requirements'] as Map? ?? {}),
      setId: json['setId'] as String?,
      isExclusive: json['isExclusive'] as bool? ?? true,
      dropRealmIds: (json['dropRealmIds'] as List?)?.cast<String>() ?? const [],
      imageUrl: json['imageUrl'] as String?,
    );
  }

  /// 将未知的效果类型字符串映射到最接近的 EffectType 枚举值
  EffectType _mapEffectType(String typeStr) {
    return switch (typeStr) {
      'damageConversion' => EffectType.damageConvert,
      'onHitDebuff' || 'onHitReflect' || 'onHitShield' || 'comboDamage' || 'stackingBurst' =>
        EffectType.trigger,
      'meridianConflictImmune' => EffectType.meridianRelated,
      _ => EffectType.ruleChange,
    };
  }

  /// 加载武功配置
  void _loadMartialArts(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    _martialArtConfigs = list
        .map((e) => MartialArtConfig.fromJson(e as Map<String, dynamic>))
        .toList();
    _martialArtMap = {for (final m in _martialArtConfigs) m.id: m};
  }

  /// 加载经脉配置
  void _loadMeridians(String jsonStr) {
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    final meridianList = json['meridians'] as List<dynamic>;
    _meridianConfigs = meridianList
        .map((e) => MeridianConfigEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    // 同时加载经脉之语（如有）
    // final wordList = json['meridianWords'] as List<dynamic?;
    // → MeridianWord.fromJson
  }

  /// 加载掉落表配置
  void _loadDropTables(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    _dropTables = list
        .map((e) => DropTable.fromJson(e as Map<String, dynamic>))
        .toList();
    _dropTableMap = {for (final d in _dropTables) d.id: d};
  }

  /// 加载战斗描写模板配置
  void _loadNarrationTemplates(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    _narrationTemplates = list
        .whereType<Map<String, dynamic>>()
        .map((e) => NarrationTemplate.fromJson(e))
        .toList();
  }

  // =================== 扩展配置加载方法 ===================

  /// 加载敌人配置（enemies.json — 包含普通敌人和Boss）
  void _loadEnemies(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    _enemyConfigs = list
        .whereType<Map<String, dynamic>>()
        .map((e) {
      try {
        return EnemyConfig.fromJson(e);
      } catch (err) {
        AppLogger.instance.error('  enemies 解析条目 ${e['id']} 失败: $err');
        return null;
      }
    }).whereType<EnemyConfig>().toList();
    _enemyMap = {for (final e in _enemyConfigs) e.id: e};
  }

  /// 加载奇遇事件配置（events.json）
  void _loadEvents(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    _eventConfigs = list
        .whereType<Map<String, dynamic>>()
        .map((e) {
      try {
        return EventConfig.fromJson(e);
      } catch (err) {
        AppLogger.instance.error('  events 解析条目 ${e['id']} 失败: $err');
        return null;
      }
    }).whereType<EventConfig>().toList();
  }

  /// 加载秘境配置（realms.json）
  void _loadRealms(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    _realmConfigs = list
        .map((e) {
      try {
        return RealmConfigEntry.fromJson(e as Map<String, dynamic>);
      } catch (err) {
        AppLogger.instance.error('  realms 解析条目 ${(e as Map)['id']} 失败: $err');
        return null;
      }
    }).whereType<RealmConfigEntry>().toList();
    _realmMap = {for (final r in _realmConfigs) r.id: r};
  }

  /// 加载心法配置（heart_mantras.json）
  void _loadHeartMantras(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    _heartMantras = list
        .whereType<Map<String, dynamic>>()
        .map((e) {
      try {
        return HeartMantra.fromJson(e);
      } catch (err) {
        AppLogger.instance.error('  heart_mantras 解析条目 ${e['id']} 失败: $err');
        return null;
      }
    }).whereType<HeartMantra>().toList();
    _heartMantraMap = {for (final h in _heartMantras) h.id: h};
  }

  /// 加载装备扩展配置（equipment_expansion.json）
  /// 格式与 equipment_base.json 相同，使用 EquipmentBase 模型
  void _loadEquipmentExpansion(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    _equipmentExpansion = list.map((rawJson) {
      try {
        final json = Map<String, dynamic>.from(rawJson as Map);
        if (!json.containsKey('baseDamage') && json.containsKey('baseDefense')) {
          json['baseDamage'] = json['baseDefense'];
        }
        return EquipmentBase.fromJson(json);
      } catch (err) {
        AppLogger.instance.error('  equipment_expansion 解析条目失败: $err');
        return null;
      }
    }).whereType<EquipmentBase>().toList();
  }

  /// 加载暗金装备扩展配置（unique_expansion.json）
  /// 格式与 unique_equipment.json 相同，复用解析逻辑
  void _loadUniqueExpansion(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    _uniqueExpansion = list
        .whereType<Map<String, dynamic>>()
        .map((json) {
      try {
        return _parseUniqueEquipment(json);
      } catch (e) {
        AppLogger.instance.error('  unique_expansion 解析条目 ${json['id']} 失败: $e');
        return null;
      }
    }).whereType<UniqueEquipment>().toList();
    _uniqueExpansionMap = {for (final u in _uniqueExpansion) u.id: u};
  }

  /// 加载武功扩展配置（martial_arts_expansion.json）
  /// 格式与 martial_arts.json 相同，使用 MartialArtConfig 模型
  void _loadMartialArtsExpansion(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    _martialArtsExpansion = list
        .map((e) {
      try {
        return MartialArtConfig.fromJson(e as Map<String, dynamic>);
      } catch (err) {
        AppLogger.instance.error('  martial_arts_expansion 解析条目失败: $err');
        return null;
      }
    }).whereType<MartialArtConfig>().toList();
    _martialArtsExpansionMap = {
      for (final m in _martialArtsExpansion) m.id: m
    };
  }

  /// 加载战斗描写模板扩展配置（narration_expansion.json）
  /// 格式与 narration_templates.json 相同，使用 NarrationTemplate 模型
  void _loadNarrationExpansion(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    _narrationExpansion = list
        .whereType<Map<String, dynamic>>()
        .map((e) {
      try {
        return NarrationTemplate.fromJson(e);
      } catch (err) {
        AppLogger.instance.error('  narration_expansion 解析条目失败: $err');
        return null;
      }
    }).whereType<NarrationTemplate>().toList();
  }

  /// 加载图片清单配置（image_manifest.json）
  void _loadImageManifest(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    _imageManifest = list
        .map((e) {
      try {
        return ImageManifestEntry.fromJson(e as Map<String, dynamic>);
      } catch (err) {
        AppLogger.instance.error('  image_manifest 解析条目失败: $err');
        return null;
      }
    }).whereType<ImageManifestEntry>().toList();
    _imageMap = {for (final i in _imageManifest) i.id: i};
  }

  // =================== 查询接口 ===================

  /// 统一配置查询接口
  ///
  /// [type] 配置类型
  /// 返回对应类型的已解析对象列表
  List<dynamic> getConfig(ConfigType type) {
    return switch (type) {
      ConfigType.equipmentBase => _equipmentBases,
      ConfigType.affixes => _affixConfigs,
      ConfigType.uniqueEquipment => _uniqueEquipments,
      ConfigType.martialArts => _martialArtConfigs,
      ConfigType.meridians => _meridianConfigs,
      ConfigType.dropTables => _dropTables,
      ConfigType.narrationTemplates => _narrationTemplates,
      // 扩展配置类型（9种）
      ConfigType.enemies => _enemyConfigs,
      ConfigType.events => _eventConfigs,
      ConfigType.realms => _realmConfigs,
      ConfigType.heartMantras => _heartMantras,
      ConfigType.equipmentExpansion => _equipmentExpansion,
      ConfigType.uniqueExpansion => _uniqueExpansion,
      ConfigType.martialArtsExpansion => _martialArtsExpansion,
      ConfigType.narrationExpansion => _narrationExpansion,
      ConfigType.imageManifest => _imageManifest,
    };
  }

  /// 根据ID获取装备基础配置
  EquipmentBase? getEquipmentBase(String id) {
    for (final e in _equipmentBases) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// 根据ID获取词缀配置
  AffixConfig? getAffix(String id) => _affixMap[id];

  /// 根据ID获取暗金装备配置
  UniqueEquipment? getUniqueEquipment(String id) => _uniqueMap[id];

  /// 根据ID获取武功配置
  MartialArtConfig? getMartialArtConfig(String id) => _martialArtMap[id];

  /// 根据ID获取掉落表
  DropTable? getDropTable(String id) => _dropTableMap[id];

  /// 获取指定掉落表中的可用暗金列表
  List<UniqueEquipment> getUniquePoolForDropTable(String dropTableId) {
    final table = _dropTableMap[dropTableId];
    if (table == null) return const [];
    return table.uniquePool
        .map((id) => _uniqueMap[id])
        .whereType<UniqueEquipment>()
        .toList();
  }

  // =================== 扩展配置查询方法 ===================

  /// 根据ID获取心法配置
  HeartMantra? getHeartMantra(String id) => _heartMantraMap[id];

  /// 获取所有秘境配置
  List<RealmConfigEntry> getRealms() => _realmConfigs;

  /// 获取所有敌人配置
  List<EnemyConfig> getEnemies() => _enemyConfigs;

  /// 获取所有奇遇事件配置
  List<EventConfig> getEvents() => _eventConfigs;

  /// 根据ID获取敌人配置
  EnemyConfig? getEnemy(String id) => _enemyMap[id];

  /// 根据ID获取秘境配置
  RealmConfigEntry? getRealm(String id) => _realmMap[id];

  /// 根据ID获取图片清单条目
  ImageManifestEntry? getImage(String id) => _imageMap[id];

  /// 获取所有心法配置
  List<HeartMantra> getHeartMantras() => _heartMantras;

  // =================== 远程配置接口预留 ===================

  /// 远程配置拉取（未来CDN更新，DESIGN.md 4.5）
  ///
  /// 预留接口，当前返回false表示未实现。
  /// 未来实现时，从此URL拉取JSON配置并覆盖本地配置。
  ///
  /// [cdnBaseUrl] CDN基础URL
  /// [version] 配置版本号
  Future<bool> fetchRemoteConfig({
    String? cdnBaseUrl,
    String? version,
  }) async {
    // TODO: 未来CDN远程配置拉取实现
    // 1. 从 cdnBaseUrl + '/' + version + '/manifest.json' 获取配置清单
    // 2. 比对本地版本，拉取更新的配置文件
    // 3. 解析并覆盖本地配置
    // 4. 缓存到本地文件系统作为fallback
    return false;
  }

  /// 从字节数据加载单个配置（远程拉取后使用）
  void loadFromBytes(ConfigType type, Uint8List bytes) {
    final jsonStr = utf8.decode(bytes);
    switch (type) {
      case ConfigType.equipmentBase:
        _loadEquipmentBases(jsonStr);
      case ConfigType.affixes:
        _loadAffixes(jsonStr);
      case ConfigType.uniqueEquipment:
        _loadUniqueEquipments(jsonStr);
      case ConfigType.martialArts:
        _loadMartialArts(jsonStr);
      case ConfigType.meridians:
        _loadMeridians(jsonStr);
      case ConfigType.dropTables:
        _loadDropTables(jsonStr);
      case ConfigType.narrationTemplates:
        _loadNarrationTemplates(jsonStr);
      // 扩展配置类型（9种）
      case ConfigType.enemies:
        _loadEnemies(jsonStr);
      case ConfigType.events:
        _loadEvents(jsonStr);
      case ConfigType.realms:
        _loadRealms(jsonStr);
      case ConfigType.heartMantras:
        _loadHeartMantras(jsonStr);
      case ConfigType.equipmentExpansion:
        _loadEquipmentExpansion(jsonStr);
      case ConfigType.uniqueExpansion:
        _loadUniqueExpansion(jsonStr);
      case ConfigType.martialArtsExpansion:
        _loadMartialArtsExpansion(jsonStr);
      case ConfigType.narrationExpansion:
        _loadNarrationExpansion(jsonStr);
      case ConfigType.imageManifest:
        _loadImageManifest(jsonStr);
    }
    _isLoaded = true;
  }

  /// 清除所有已加载的配置
  void clear() {
    // 基础配置
    _equipmentBases = const [];
    _affixConfigs = const [];
    _affixMap = {};
    _uniqueEquipments = const [];
    _uniqueMap = {};
    _martialArtConfigs = const [];
    _martialArtMap = {};
    _meridianConfigs = const [];
    _dropTables = const [];
    _dropTableMap = {};
    _narrationTemplates = const [];
    // 扩展配置
    _enemyConfigs = const [];
    _enemyMap = {};
    _eventConfigs = const [];
    _realmConfigs = const [];
    _realmMap = {};
    _heartMantras = const [];
    _heartMantraMap = {};
    _equipmentExpansion = const [];
    _uniqueExpansion = const [];
    _uniqueExpansionMap = {};
    _martialArtsExpansion = const [];
    _martialArtsExpansionMap = {};
    _narrationExpansion = const [];
    _imageManifest = const [];
    _imageMap = {};
    _isLoaded = false;
  }

  /// 创建用于测试的空ConfigLoader
  factory ConfigLoader.forTesting() => ConfigLoader._();
}
