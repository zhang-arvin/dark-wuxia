import 'package:drift/drift.dart';

/// 掉落记录表 — 记录每次装备掉落
///
/// 设计要点:
/// - equipmentId: 关联装备表 ID
/// - realmId: 在哪个秘境掉落
/// - layer: 在第几层掉落
/// - quality: 掉落时品质 (用于统计分析)
/// - 用于统计掉率分布、保底计数等
class DropHistoryTable extends Table {
  /// 自增主键
  IntColumn get id => integer().autoIncrement()();

  /// 关联装备 ID
  TextColumn get equipmentId => text()();

  /// 秘境 ID
  TextColumn get realmId => text()();

  /// 层数
  IntColumn get layer => integer()();

  /// 品质: normal / magic / rare / unique / divine / legendary
  TextColumn get quality => text()();

  /// 掉落时间戳
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}
