import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/run_history_table.dart';

part 'run_history_dao.g.dart';

/// 通关记录 DAO — 秘境通关记录表的数据访问层
///
/// 功能:
/// - 记录每次秘境通关 (含 BD 快照)
/// - 排行榜数据查询
@DriftAccessor(tables: [RunHistoryTable])
class RunDao extends DatabaseAccessor<AppDatabase> with _$RunDaoMixin {
  RunDao(super.db);

  /// 记录一次通关
  Future<int> recordRun(RunHistoryTableCompanion run) {
    return into(db.runHistoryTable).insert(run);
  }

  /// 获取最近 N 条通关记录
  Future<List<RunHistoryTableData>> getRecentRuns({int limit = 20}) async {
    final query = select(db.runHistoryTable)
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
      ..limit(limit);
    return await query.get();
  }

  /// 分页查询通关记录
  Future<List<RunHistoryTableData>> getRunsByPage({int page = 0}) async {
    const pageItemCount = 50;
    final query = select(db.runHistoryTable)
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
      ..limit(pageItemCount, offset: page * pageItemCount);
    return await query.get();
  }

  /// 按秘境查询通关记录 (用于秘境专属排行)
  Future<List<RunHistoryTableData>> getRunsByRealm(String realmId) async {
    final query = select(db.runHistoryTable)
      ..where((t) => t.realmId.equals(realmId))
      ..orderBy([(t) => OrderingTerm.asc(t.totalRounds)]);
    return await query.get();
  }

  /// 按秘境+难度查询最快通关记录 (排行榜)
  ///
  /// [realmId] 秘境 ID
  /// [difficulty] 难度等级
  /// [limit] 返回条数
  Future<List<RunHistoryTableData>> getLeaderboard(
    String realmId,
    int difficulty, {
    int limit = 10,
  }) async {
    final query = select(db.runHistoryTable)
      ..where((t) =>
          t.realmId.equals(realmId) &
          t.difficulty.equals(difficulty) &
          t.result.equals('victory'))
      ..orderBy([(t) => OrderingTerm.asc(t.totalRounds)])
      ..limit(limit);
    return await query.get();
  }

  /// 统计某秘境通关次数
  Future<int> countByRealm(String realmId) async {
    final countExpr = db.runHistoryTable.id.count();
    final query = selectOnly(db.runHistoryTable)
      ..addColumns([countExpr])
      ..where(db.runHistoryTable.realmId.equals(realmId));
    final result = await query.map((row) => row.read(countExpr)).getSingle();
    return result ?? 0;
  }

  /// 统计总通关次数
  Future<int> totalRunCount() async {
    final countExpr = db.runHistoryTable.id.count();
    final query = selectOnly(db.runHistoryTable)..addColumns([countExpr]);
    final result = await query.map((row) => row.read(countExpr)).getSingle();
    return result ?? 0;
  }

  /// 获取 BD 快照 (用于排行榜流派展示)
  ///
  /// 返回 JSON 字符串
  Future<String?> getBdSnapshot(int runId) async {
    final query = select(db.runHistoryTable)
      ..where((t) => t.id.equals(runId));
    final data = await query.getSingleOrNull();
    return data?.bdSnapshot;
  }
}
