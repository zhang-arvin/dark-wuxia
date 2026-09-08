import 'package:drift/drift.dart';

/// 装备表 — 存储所有掉落/获得的装备
///
/// 设计要点:
/// - id: 唯一主键 (UUID)
/// - baseId: 指向 config/equipment_base.json 中的基础装备
/// - quality: 品质枚举 (凡品/良品/上品/暗金/神品/传说)
/// - affixesJson: 词缀列表的 JSON 字符串 (4-6个词缀)
///   DAO 层负责序列化/反序列化
/// - meridianSeedId: 镶嵌的真气种子 ID (可空)
/// - 背包软上限 500 件，超限提示熔炼/出售
class EquipmentTable extends Table {
  /// 装备唯一 ID (UUID)
  TextColumn get id => text()();

  /// 基础装备 ID (指向 JSON 配置)
  TextColumn get baseId => text()();

  /// 品质: normal / magic / rare / unique / divine / legendary
  TextColumn get quality => text()();

  /// 装备槽位: weapon / armor / accessory / treasure
  TextColumn get slot => text()();

  /// 生成名 (含词缀前缀后缀)
  TextColumn get name => text()();

  /// 词缀列表 JSON 字符串
  /// 格式: [{"id":"sharp","type":"prefix","name":"锋利的","stat":"outerDamage","value":15,"isPercent":true}, ...]
  TextColumn get affixesJson => text().withDefault(const Constant('[]'))();

  /// 强化等级 (0-15)
  IntColumn get reinforceLevel => integer().withDefault(const Constant(0))();

  /// 镶嵌的真气种子 ID (可空)
  TextColumn get meridianSeedId => text().nullable()();

  /// 物品等级 (影响词缀范围)
  IntColumn get itemLevel => integer()();

  /// 是否已装备 (false=在背包中, true=已装备在槽位上)
  BoolColumn get isEquipped => boolean().withDefault(const Constant(false))();

  /// 创建时间戳
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
