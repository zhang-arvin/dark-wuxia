import 'dart:convert';

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/realm_progress_table.dart';

part 'realm_dao.g.dart';

/// 秘境进度 DAO — 秘境进度表的数据访问层
///
/// 功能:
/// - 秘境进度 CRUD
/// - 同步策略: Last-Write-Wins + 版本号
@DriftAccessor(tables: [RealmProgressTable])
class RealmDao extends DatabaseAccessor<AppDatabase>
    with _$RealmDaoMixin {
  RealmDao(super.db);

  /// 获取所有秘境进度
  Future<List<RealmProgressTableData>> getAllProgress() async {
    return await select(db.realmProgressTable).get();
  }

  /// 根据 ID 获取单个秘境进度
  Future<RealmProgressTableData?> getProgress(String realmId) async {
    final query = select(db.realmProgressTable)
      ..where((t) => t.realmId.equals(realmId));
    return await query.getSingleOrNull();
  }

  /// 创建或更新秘境进度 (upsert)
  ///
  /// 同步时使用 Last-Write-Wins + 版本号策略:
  /// 当 [version] 大于现有版本时才更新
  Future<void> upsertProgress(RealmProgressTableCompanion progress,
      {bool useVersionCheck = false}) async {
    if (useVersionCheck) {
      // 版本号检查: 仅当新版本号更大时才更新
      final existing = await getProgress(progress.realmId.value);
      if (existing != null && existing.version >= progress.version.value) {
        return; // 旧版本，跳过
      }
    }
    await into(db.realmProgressTable).insertOnConflictUpdate(progress);
  }

  /// 更新层数
  Future<void> updateLayer(String realmId, int layer) async {
    await (update(db.realmProgressTable)
          ..where((t) => t.realmId.equals(realmId)))
        .write(RealmProgressTableCompanion(
      currentLayer: Value(layer),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// 更新难度
  Future<void> updateDifficulty(String realmId, int difficulty) async {
    await (update(db.realmProgressTable)
          ..where((t) => t.realmId.equals(realmId)))
        .write(RealmProgressTableCompanion(
      currentDifficulty: Value(difficulty),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// 添加已完成事件 ID
  Future<void> addCompletedEvent(String realmId, String eventId) async {
    final progress = await getProgress(realmId);
    if (progress == null) return;

    final events = (jsonDecode(progress.completedEventsJson) as List<dynamic>)
        .cast<String>();
    if (!events.contains(eventId)) {
      events.add(eventId);
      await (update(db.realmProgressTable)
            ..where((t) => t.realmId.equals(realmId)))
          .write(RealmProgressTableCompanion(
        completedEventsJson: Value(jsonEncode(events)),
        updatedAt: Value(DateTime.now()),
      ));
    }
  }

  /// 增加击杀计数
  Future<void> incrementEnemyCount(String realmId, {int delta = 1}) async {
    final progress = await getProgress(realmId);
    if (progress == null) return;

    await (update(db.realmProgressTable)
          ..where((t) => t.realmId.equals(realmId)))
        .write(RealmProgressTableCompanion(
      enemyCount: Value(progress.enemyCount + delta),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// 增加掉落计数
  Future<void> incrementDropCount(String realmId, {int delta = 1}) async {
    final progress = await getProgress(realmId);
    if (progress == null) return;

    await (update(db.realmProgressTable)
          ..where((t) => t.realmId.equals(realmId)))
        .write(RealmProgressTableCompanion(
      dropCount: Value(progress.dropCount + delta),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// 重置秘境进度 (重新挑战)
  Future<void> resetProgress(String realmId) async {
    await (update(db.realmProgressTable)
          ..where((t) => t.realmId.equals(realmId)))
        .write(RealmProgressTableCompanion(
      currentLayer: const Value(0),
      currentDifficulty: const Value(0),
      completedEventsJson: const Value('[]'),
      enemyCount: const Value(0),
      dropCount: const Value(0),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// 删除秘境进度
  Future<int> deleteProgress(String realmId) {
    return (delete(db.realmProgressTable)
          ..where((t) => t.realmId.equals(realmId)))
        .go();
  }

  // ==================== JSON 序列化辅助 ====================

  /// 从秘境进度行数据中解析已完成事件列表
  static List<String> parseCompletedEvents(RealmProgressTableData data) {
    final list = jsonDecode(data.completedEventsJson) as List<dynamic>;
    return list.cast<String>();
  }
}
