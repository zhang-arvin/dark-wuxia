import 'package:drift/drift.dart';

/// 角色状态表 — 单角色存档 (单行表)
///
/// 设计要点:
/// - 单角色游戏，此表始终只有一行 (id=1)
/// - attributesJson: 五维属性 (body/agi/wis/con/luck) JSON
/// - martialArtsJson: 武功列表 JSON
/// - meridiansJson: 经脉状态 JSON (6脉30穴)
/// - powerIndex: 战力指数，由 character_dao 自动重算
/// - updatedAt: 最后更新时间
class CharacterTable extends Table {
  /// 主键固定为 1 (单角色)
  IntColumn get id => integer().withDefault(const Constant(1))();

  /// 角色名
  TextColumn get name => text()();

  /// 出身
  TextColumn get origin => text().withDefault(const Constant(''))();

  /// 等级
  IntColumn get level => integer().withDefault(const Constant(1))();

  /// 五维属性 JSON: {"body":10,"agi":8,"wis":12,"con":10,"luck":5}
  TextColumn get attributesJson => text().withDefault(const Constant('{}'))();

  /// 年龄
  IntColumn get age => integer().withDefault(const Constant(16))();

  /// 当前生命值
  IntColumn get health => integer().withDefault(const Constant(100))();

  /// 当前内力值
  IntColumn get innerEnergy => integer().withDefault(const Constant(50))();

  /// 福缘 (掉率加成, =D2的MF)
  IntColumn get fortune => integer().withDefault(const Constant(0))();

  /// 名望
  IntColumn get reputation => integer().withDefault(const Constant(0))();

  /// 正邪值 -100~100
  IntColumn get alignment => integer().withDefault(const Constant(0))();

  /// 战力指数 (综合评分)
  IntColumn get powerIndex => integer().withDefault(const Constant(0))();

  /// 武功列表 JSON
  /// 格式: [{"id":"shaolin_quan","name":"少林长拳","type":"outer","proficiency":30,"level":"beginner","elementAffinity":"yang"}, ...]
  TextColumn get martialArtsJson => text().withDefault(const Constant('[]'))();

  /// 经脉状态 JSON (6脉30穴)
  /// 格式: [{"meridianId":"yang1","nodeIndex":0,"isOpen":true,"seedId":"seed_fire"}, ...]
  TextColumn get meridiansJson => text().withDefault(const Constant('[]'))();

  /// 心法 ID (可空)
  TextColumn get heartMantra => text().nullable()();

  /// 银两 (货币，用于购买/赌博/强化)
  IntColumn get silver => integer().withDefault(const Constant(0))();

  /// 最后更新时间
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
