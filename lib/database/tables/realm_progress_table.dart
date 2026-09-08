import 'package:drift/drift.dart';

/// 秘境进度表 — 记录每个秘境的当前推进状态
///
/// 设计要点:
/// - realmId: 秘境 ID (指向 config/secret_realms.json)
/// - currentLayer: 当前层数
/// - currentDifficulty: 当前难度 (0=普通 1=困难 2=地狱 3=炼狱)
/// - completedEventsJson: 已完成事件 ID 列表 JSON
/// - 同步策略: Last-Write-Wins + 版本号
class RealmProgressTable extends Table {
  /// 秘境 ID
  TextColumn get realmId => text()();

  /// 当前层数
  IntColumn get currentLayer => integer().withDefault(const Constant(0))();

  /// 当前难度 (0=普通 1=困难 2=地狱 3=炼狱)
  IntColumn get currentDifficulty => integer().withDefault(const Constant(0))();

  /// 已完成事件 ID 列表 JSON
  /// 格式: ["event_001","event_002", ...]
  TextColumn get completedEventsJson => text().withDefault(const Constant('[]'))();

  /// 击杀敌人数
  IntColumn get enemyCount => integer().withDefault(const Constant(0))();

  /// 掉落物品数
  IntColumn get dropCount => integer().withDefault(const Constant(0))();

  /// 版本号 (用于 Last-Write-Wins 同步)
  IntColumn get version => integer().withDefault(const Constant(0))();

  /// 最后更新时间
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {realmId};
}
