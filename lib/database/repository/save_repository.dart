import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database.dart';
import '../tables/character_table.dart';
import '../tables/drop_history_table.dart';
import '../tables/equipment_table.dart';
import '../tables/realm_progress_table.dart';
import '../tables/run_history_table.dart';
import '../daos/equipment_dao.dart';
import '../daos/character_dao.dart';
import '../daos/realm_dao.dart';
import '../daos/drop_dao.dart';
import '../daos/run_history_dao.dart';
import '../daos/settings_dao.dart';
import '../daos/power_calculator.dart';

/// 统一存档门面 (Facade)
///
/// 对外暴露统一的存档 API: save / load / export / import
///
/// 设计原则:
/// - 外部不直接操作 DAO，统一通过此门面
/// - 简化调用方代码，提供业务级语义
/// - 封装事务性操作 (如存档=角色+装备+进度一起保存)
class SaveRepository {
  final AppDatabase _db;

  SaveRepository(this._db);

  // ==================== DAO 访问器 (快捷访问) ====================

  /// 装备 DAO
  EquipmentDao get equipmentDao => _db.equipmentDao;

  /// 角色 DAO
  CharacterDao get characterDao => _db.characterDao;

  /// 秘境进度 DAO
  RealmDao get realmDao => _db.realmDao;

  /// 掉落记录 DAO
  DropDao get dropDao => _db.dropDao;

  /// 通关记录 DAO
  RunDao get runDao => _db.runDao;

  /// 设置 DAO
  SettingsDao get settingsDao => _db.settingsDao;

  // ==================== 存档 (Save) ====================

  /// 保存完整存档 (事务性)
  ///
  /// 将角色状态、当前秘境进度一起保存
  ///
  /// [character] 角色状态 companion
  /// [realmProgress] 秘境进度 companion (可选)
  Future<void> save({
    required CharacterTableCompanion character,
    RealmProgressTableCompanion? realmProgress,
  }) async {
    await _db.transaction(() async {
      await characterDao.updateCharacter(character);
      if (realmProgress != null) {
        await realmDao.upsertProgress(realmProgress);
      }
    });
  }

  /// 保存新掉落装备 (事务性)
  ///
  /// 同时记录掉落历史
  ///
  /// [equipment] 装备数据
  /// [realmId] 秘境 ID
  /// [layer] 层数
  Future<String> saveDrop({
    required EquipmentTableCompanion equipment,
    required String realmId,
    required int layer,
  }) async {
    return await _db.transaction(() async {
      // 插入装备
      final equipmentId = await equipmentDao.insertEquipment(equipment);

      // 记录掉落历史
      await dropDao.recordDrop(DropHistoryTableCompanion.insert(
        equipmentId: equipmentId,
        realmId: realmId,
        layer: layer,
        quality: equipment.quality.value,
      ));

      // 更新秘境掉落计数
      await realmDao.incrementDropCount(realmId);

      return equipmentId;
    });
  }

  /// 保存通关记录 (事务性)
  ///
  /// [realmId] 秘境 ID
  /// [difficulty] 难度
  /// [totalRounds] 总回合数
  /// [result] 结果: victory / defeat / retreat
  /// [bdSnapshot] BD 快照 JSON
  Future<int> saveRun({
    required String realmId,
    required int difficulty,
    required int totalRounds,
    required String result,
    required Map<String, dynamic> bdSnapshot,
  }) async {
    return await _db.transaction(() async {
      return await runDao.recordRun(RunHistoryTableCompanion.insert(
        realmId: realmId,
        difficulty: difficulty,
        totalRounds: totalRounds,
        result: result,
        bdSnapshot: Value(jsonEncode(bdSnapshot)),
      ));
    });
  }

  // ==================== 读档 (Load) ====================

  /// 加载完整存档
  ///
  /// 返回包含角色状态、秘境进度列表、装备统计的复合数据
  Future<SaveData> load() async {
    final character = await characterDao.getCharacter();
    final realmProgressList = await realmDao.getAllProgress();
    final equipmentCount = await equipmentDao.equipmentCount();
    final isBagFull = await equipmentDao.isBagFull();
    final qualityStats = await equipmentDao.countByQuality();
    final slotStats = await equipmentDao.countBySlot();

    return SaveData(
      character: character,
      realmProgressList: realmProgressList,
      equipmentCount: equipmentCount,
      isBagFull: isBagFull,
      qualityStats: qualityStats,
      slotStats: slotStats,
    );
  }

  /// 加载角色状态
  Future<CharacterTableData?> loadCharacter() {
    return characterDao.getCharacter();
  }

  /// 分页加载装备 (每次50条)
  Future<List<EquipmentTableData>> loadEquipmentsByPage({int page = 0}) {
    return equipmentDao.getEquipmentsByPage(page: page);
  }

  /// 加载秘境进度
  Future<List<RealmProgressTableData>> loadRealmProgress() {
    return realmDao.getAllProgress();
  }

  // ==================== 导出 (Export) ====================

  /// 导出存档为 JSON 字符串
  ///
  /// 包含: 角色、装备、秘境进度、通关记录、设置
  /// 用于云存档同步或本地备份
  Future<String> exportSave() async {
    final character = await characterDao.getCharacter();
    final equipments = await _exportAllEquipments();
    final realmProgressList = await realmDao.getAllProgress();
    final runHistory = await runDao.getRecentRuns(limit: 500);
    final settings = await settingsDao.getAll();
    final dropHistory = await dropDao.getRecentDrops(limit: 1000);

    final exportData = {
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'character': character?.toJson(),
      'equipments': equipments.map((e) => e.toJson()).toList(),
      'realmProgress': realmProgressList.map((e) => e.toJson()).toList(),
      'runHistory': runHistory.map((e) => e.toJson()).toList(),
      'settings': settings,
      'dropHistory': dropHistory.map((e) => e.toJson()).toList(),
    };

    return jsonEncode(exportData);
  }

  /// 导出存档到文件
  ///
  /// 返回文件路径
  Future<String> exportToFile() async {
    final jsonStr = await exportSave();
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path,
        'dark_wuxia_export_${DateTime.now().millisecondsSinceEpoch}.json'));
    await file.writeAsString(jsonStr);
    return file.path;
  }

  // ==================== 导入 (Import) ====================

  /// 从 JSON 字符串导入存档
  ///
  /// 策略 (DESIGN.md 4.5 离线/在线设计):
  /// - 装备库存: 追加合并 (by id，无冲突)
  /// - 经脉进度: Last-Write-Wins + 版本号
  /// - 秘境进度: Last-Write-Wins
  /// - 角色属性: 从基础数据重算
  Future<void> importSave(String jsonStr) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    await _db.transaction(() async {
      // 导入角色 (覆盖)
      if (data['character'] != null) {
        final charJson = data['character'] as Map<String, dynamic>;
        await _importCharacter(charJson);
      }

      // 导入装备 (追加合并 by id)
      if (data['equipments'] != null) {
        final equipList = data['equipments'] as List<dynamic>;
        await _importEquipments(equipList);
      }

      // 导入秘境进度 (Last-Write-Wins)
      if (data['realmProgress'] != null) {
        final realmList = data['realmProgress'] as List<dynamic>;
        await _importRealmProgress(realmList);
      }

      // 导交通关记录
      if (data['runHistory'] != null) {
        final runList = data['runHistory'] as List<dynamic>;
        await _importRunHistory(runList);
      }

      // 导入设置
      if (data['settings'] != null) {
        final settings = data['settings'] as Map<String, dynamic>;
        await _importSettings(settings);
      }
    });

    // 导入后重算战力
    await characterDao.recalculateAndSavePowerIndex();
  }

  /// 从文件导入存档
  Future<void> importFromFile(String filePath) async {
    final file = File(filePath);
    final jsonStr = await file.readAsString();
    await importSave(jsonStr);
  }

  // ==================== 导入辅助方法 ====================

  Future<void> _importCharacter(Map<String, dynamic> json) async {
    final existing = await characterDao.getCharacter();
    final companion = CharacterTableCompanion(
      id: const Value(1),
      name: Value(json['name'] as String? ?? '无名'),
      origin: Value(json['origin'] as String? ?? ''),
      level: Value(json['level'] as int? ?? 1),
      attributesJson: Value(json['attributesJson'] as String? ?? '{}'),
      age: Value(json['age'] as int? ?? 16),
      health: Value(json['health'] as int? ?? 100),
      innerEnergy: Value(json['innerEnergy'] as int? ?? 50),
      fortune: Value(json['fortune'] as int? ?? 0),
      reputation: Value(json['reputation'] as int? ?? 0),
      alignment: Value(json['alignment'] as int? ?? 0),
      powerIndex: Value(json['powerIndex'] as int? ?? 0),
      martialArtsJson: Value(json['martialArtsJson'] as String? ?? '[]'),
      meridiansJson: Value(json['meridiansJson'] as String? ?? '[]'),
      heartMantra: Value(json['heartMantra'] as String?),
      updatedAt: Value(DateTime.now()),
    );

    if (existing == null) {
      await characterDao.createCharacter(
        name: companion.name.value,
        origin: companion.origin.value,
        attributes: (jsonDecode(companion.attributesJson.value) as Map).map(
          (k, v) => MapEntry(k.toString(), (v as num).toInt()),
        ),
      );
      // 更新其余字段
      await characterDao.updateCharacter(companion);
    } else {
      await characterDao.updateCharacter(companion);
    }
  }

  Future<void> _importEquipments(List<dynamic> equipList) async {
    final companions = <EquipmentTableCompanion>[];
    for (final item in equipList) {
      final json = item as Map<String, dynamic>;
      final id = json['id'] as String;

      // 检查是否已存在 (追加合并 by id)
      final existing = await equipmentDao.getById(id);
      if (existing != null) continue; // 已存在则跳过

      companions.add(EquipmentTableCompanion.insert(
        id: id,
        baseId: json['baseId'] as String,
        quality: json['quality'] as String,
        slot: json['slot'] as String? ?? 'weapon',
        name: json['name'] as String,
        affixesJson: Value(json['affixesJson'] as String? ?? '[]'),
        reinforceLevel: Value(json['reinforceLevel'] as int? ?? 0),
        meridianSeedId: Value(json['meridianSeedId'] as String?),
        itemLevel: json['itemLevel'] as int,
      ));
    }
    if (companions.isNotEmpty) {
      await equipmentDao.insertAll(companions);
    }
  }

  Future<void> _importRealmProgress(List<dynamic> realmList) async {
    for (final item in realmList) {
      final json = item as Map<String, dynamic>;
      final realmId = json['realmId'] as String;
      final version = json['version'] as int? ?? 0;

      await realmDao.upsertProgress(
        RealmProgressTableCompanion.insert(
          realmId: realmId,
          currentLayer: Value(json['currentLayer'] as int? ?? 0),
          currentDifficulty: Value(json['currentDifficulty'] as int? ?? 0),
          completedEventsJson:
              Value(json['completedEventsJson'] as String? ?? '[]'),
          enemyCount: Value(json['enemyCount'] as int? ?? 0),
          dropCount: Value(json['dropCount'] as int? ?? 0),
          version: Value(version),
          updatedAt: Value(DateTime.now()),
        ),
        useVersionCheck: true, // Last-Write-Wins + 版本号
      );
    }
  }

  Future<void> _importRunHistory(List<dynamic> runList) async {
    for (final item in runList) {
      final json = item as Map<String, dynamic>;
      await runDao.recordRun(RunHistoryTableCompanion.insert(
        realmId: json['realmId'] as String,
        difficulty: json['difficulty'] as int,
        totalRounds: json['totalRounds'] as int,
        result: json['result'] as String,
        bdSnapshot: Value(json['bdSnapshot'] as String? ?? '{}'),
      ));
    }
  }

  Future<void> _importSettings(Map<String, dynamic> settings) async {
    for (final entry in settings.entries) {
      await settingsDao.setString(entry.key, entry.value.toString());
    }
  }

  // ==================== 辅助 ====================

  /// 导出所有装备 (不分页，用于导出存档)
  Future<List<EquipmentTableData>> _exportAllEquipments() async {
    // 分批导出避免内存溢出
    final allEquipments = <EquipmentTableData>[];
    var page = 0;
    while (true) {
      final batch = await equipmentDao.getEquipmentsByPage(page: page);
      if (batch.isEmpty) break;
      allEquipments.addAll(batch);
      page++;
    }
    return allEquipments;
  }
}

/// 存档数据复合结构
class SaveData {
  /// 角色状态 (可空，首次进入时为 null)
  final CharacterTableData? character;

  /// 秘境进度列表
  final List<RealmProgressTableData> realmProgressList;

  /// 装备总数
  final int equipmentCount;

  /// 背包是否已满 (>=500)
  final bool isBagFull;

  /// 按品质统计
  final Map<String, int> qualityStats;

  /// 按槽位统计
  final Map<String, int> slotStats;

  SaveData({
    required this.character,
    required this.realmProgressList,
    required this.equipmentCount,
    required this.isBagFull,
    required this.qualityStats,
    required this.slotStats,
  });
}
