import 'package:drift/drift.dart';

/// 经脉状态表 — 单角色经脉冲关状态 (每脉一行)
///
/// 设计要点:
/// - meridianId: 对应 assets/config/meridians.json 中的经脉 ID
/// - openedNodes: 已冲开的穴位数量 (从第1穴起顺序冲开)
/// - isActive: 整脉是否激活 (激活后提供脉系加成)
/// - 激活相克经脉会触发真气逆行 (qiDeviation, 存于 settings 表)
/// - 本表是经脉进度的新数据源 (character.meridiansJson 由 DAO 同步生成)
class MeridianStateTable extends Table {
  /// 自增主键
  IntColumn get id => integer().autoIncrement()();

  /// 经脉 ID (对应 meridians.json 的 id, 如 'mer_yang_1')
  /// 每条经脉一行，唯一约束
  TextColumn get meridianId => text().unique()();

  /// 已冲开的穴位数量
  IntColumn get openedNodes => integer().withDefault(const Constant(0))();

  /// 整脉是否激活
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();

  /// 最后更新时间
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}