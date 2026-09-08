import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/drop_history_table.dart';

part 'drop_dao.g.dart';

/// 掉落记录 DAO — 掉落记录表的数据访问层
///
/// 功能:
/// - 记录每次装备掉落
/// - 统计分析 (按品质/秘境/时间)
@DriftAccessor(tables: [DropHistoryTable])
class DropDao extends DatabaseAccessor<AppDatabase> with _$DropDaoMixin {
  DropDao(super.db);

  /// 记录一次掉落
  Future<int> recordDrop(DropHistoryTableCompanion drop) {
    return into(db.dropHistoryTable).insert(drop);
  }

  /// 批量记录掉落
  Future<void> recordDrops(List<DropHistoryTableCompanion> drops) async {
    await batch((batch) {
      batch.insertAll(db.dropHistoryTable, drops);
    });
  }

  /// 获取最近 N 条掉落记录
  Future<List<DropHistoryTableData>> getRecentDrops({int limit = 50}) async {
    final query = select(db.dropHistoryTable)
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
      ..limit(limit);
    return await query.get();
  }

  /// 根据掉落记录关联的装备ID批量查询装备名称
  ///
  /// 用于掉落记录页把记录中的装备ID转换为装备名展示（避免逐条查询）。
  Future<Map<String, EquipmentTableData>> getEquipmentNameMap(
      List<String> equipmentIds) async {
    if (equipmentIds.isEmpty) return const {};
    final query = select(db.equipmentTable)
      ..where((t) => t.id.isIn(equipmentIds));
    final rows = await query.get();
    return {for (final row in rows) row.id: row};
  }

  /// 分页查询掉落记录
  Future<List<DropHistoryTableData>> getDropsByPage({int page = 0, int pageSize = 50}) async {
    final query = select(db.dropHistoryTable)
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
      ..limit(pageSize, offset: page * pageSize);
    return await query.get();
  }

  /// 按秘境查询掉落记录
  Future<List<DropHistoryTableData>> getDropsByRealm(String realmId) async {
    final query = select(db.dropHistoryTable)
      ..where((t) => t.realmId.equals(realmId))
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]);
    return await query.get();
  }

  /// 按品质查询掉落记录
  Future<List<DropHistoryTableData>> getDropsByQuality(String quality) async {
    final query = select(db.dropHistoryTable)
      ..where((t) => t.quality.equals(quality))
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]);
    return await query.get();
  }

  // ==================== 统计 ====================

  /// 按品质统计掉落数量
  ///
  /// 返回 Map<品质, 数量>
  /// 用于概率公示页和保底计数
  Future<Map<String, int>> countByQuality() async {
    final query = selectOnly(db.dropHistoryTable)
      ..addColumns([db.dropHistoryTable.quality, db.dropHistoryTable.id.count()])
      ..groupBy([db.dropHistoryTable.quality]);
    final result = await query.map((row) {
      return MapEntry(
        row.read(db.dropHistoryTable.quality)!,
        row.read(db.dropHistoryTable.id.count()) ?? 0,
      );
    }).get();
    return Map.fromEntries(result);
  }

  /// 按秘境统计掉落数量
  Future<Map<String, int>> countByRealm() async {
    final query = selectOnly(db.dropHistoryTable)
      ..addColumns([db.dropHistoryTable.realmId, db.dropHistoryTable.id.count()])
      ..groupBy([db.dropHistoryTable.realmId]);
    final result = await query.map((row) {
      return MapEntry(
        row.read(db.dropHistoryTable.realmId)!,
        row.read(db.dropHistoryTable.id.count()) ?? 0,
      );
    }).get();
    return Map.fromEntries(result);
  }

  /// 获取总掉落数
  Future<int> totalDropCount() async {
    final countExpr = db.dropHistoryTable.id.count();
    final query = selectOnly(db.dropHistoryTable)..addColumns([countExpr]);
    final result = await query.map((row) => row.read(countExpr)).getSingle();
    return result ?? 0;
  }

  /// 统计某品质自上次暗金+掉落后的怪物击杀数 (保底计数)
  ///
  /// 返回距离上次掉落 unique/divine/legendary 品质以来的普通掉落数
  Future<int> countSinceLastRarePlus() async {
    // 查找最近一次暗金+品质掉落的时间
    final lastRareQuery = select(db.dropHistoryTable)
      ..where((t) => t.quality.isIn(['unique', 'divine', 'legendary']))
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
      ..limit(1);
    final lastRare = await lastRareQuery.getSingleOrNull();

    if (lastRare == null) {
      // 从未掉过暗金+，返回总掉落数
      return totalDropCount();
    }

    // 统计此时间之后的掉落数
    final countExpr = db.dropHistoryTable.id.count();
    final query = selectOnly(db.dropHistoryTable)
      ..addColumns([countExpr])
      ..where(db.dropHistoryTable.timestamp.isBiggerThanValue(lastRare.timestamp));
    final result = await query.map((row) => row.read(countExpr)).getSingle();
    return result ?? 0;
  }

  /// 清理指定时间之前的掉落记录 (节省空间)
  Future<int> cleanupBefore(DateTime before) {
    return (delete(db.dropHistoryTable)
          ..where((t) => t.timestamp.isSmallerThanValue(before)))
        .go();
  }
}
