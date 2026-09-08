import 'package:drift/drift.dart';

/// 秘境通关记录表 — 记录每次秘境通关详情
///
/// 设计要点:
/// - realmId: 通关的秘境 ID
/// - difficulty: 通关难度
/// - totalRounds: 总回合数 (用于排行榜)
/// - result: 通关结果 (victory / defeat / retreat)
/// - bdSnapshot: 通关时 BD 快照 JSON (用于排行榜展示流派)
class RunHistoryTable extends Table {
  /// 自增主键
  IntColumn get id => integer().autoIncrement()();

  /// 秘境 ID
  TextColumn get realmId => text()();

  /// 通关难度 (0=普通 1=困难 2=地狱 3=炼狱)
  IntColumn get difficulty => integer()();

  /// 总回合数
  IntColumn get totalRounds => integer()();

  /// 通关结果: victory / defeat / retreat
  TextColumn get result => text()();

  /// BD 快照 JSON (内功+外功+装备+经脉+心法摘要)
  /// 格式: {"innerStyle":"yang","outerArts":["shaolin_quan"],"powerIndex":1850,"meridianCount":5,"heartMantra":"ruanyuekegang"}
  TextColumn get bdSnapshot => text().withDefault(const Constant('{}'))();

  /// 通关时间戳
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}
