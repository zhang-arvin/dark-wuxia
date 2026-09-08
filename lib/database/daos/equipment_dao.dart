import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/equipment_table.dart';
import '../../models/equipment.dart';
import 'power_calculator.dart';

part 'equipment_dao.g.dart';

/// 装备 DAO — 装备表的数据访问层
///
/// 功能:
/// - CRUD (增删改查)
/// - 分页查询 (LIMIT/OFFSET, 每次50条)
/// - 按品质筛选
/// - 按槽位筛选
/// - 背包软上限检查 (500件)
@DriftAccessor(tables: [EquipmentTable])
class EquipmentDao extends DatabaseAccessor<AppDatabase> with _$EquipmentDaoMixin {
  EquipmentDao(super.db);

  /// 背包软上限
  static const int bagSoftLimit = 500;

  /// 每页查询条数
  static const int pageItemCount = 50;

  // ==================== CRUD ====================

  /// 插入一件新装备
  /// [equipment] 装备数据
  Future<String> insertEquipment(EquipmentTableCompanion equipment) async {
    await into(db.equipmentTable).insert(equipment);
    return equipment.id.value;
  }

  /// 批量插入装备 (用于同步合并)
  Future<void> insertAll(List<EquipmentTableCompanion> equipments) async {
    await batch((batch) {
      batch.insertAll(db.equipmentTable, equipments);
    });
  }

  /// 根据 ID 获取单件装备
  Future<EquipmentTableData?> getById(String id) async {
    final query = select(db.equipmentTable)
      ..where((t) => t.id.equals(id));
    return await query.getSingleOrNull();
  }

  /// 更新装备 (强化/镶嵌等)
  Future<bool> updateEquipment(EquipmentTableCompanion equipment) async {
    final rows = await (update(db.equipmentTable)
          ..where((t) => t.id.equals(equipment.id.value)))
        .write(equipment);
    return rows > 0;
  }

  /// 删除装备 (出售/熔炼)
  Future<int> deleteById(String id) {
    return (delete(db.equipmentTable)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  /// 批量删除装备
  Future<int> deleteByIds(List<String> ids) async {
    var deleted = 0;
    for (final id in ids) {
      deleted += await deleteById(id);
    }
    return deleted;
  }

  // ==================== 分页查询 ====================

  /// 分页查询装备 (每次50条)
  ///
  /// [page] 页码 (从0开始)
  /// 返回按创建时间倒序排列的装备列表
  Future<List<EquipmentTableData>> getEquipmentsByPage({int page = 0}) async {
    final query = select(db.equipmentTable)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(pageItemCount, offset: page * pageItemCount);
    return await query.get();
  }

  // ==================== 按品质筛选 ====================

  /// 按品质分页查询装备
  ///
  /// [quality] 品质: normal / magic / rare / unique / divine / legendary
  /// [page] 页码 (从0开始)
  Future<List<EquipmentTableData>> getByQuality(String quality,
      {int page = 0}) async {
    final query = select(db.equipmentTable)
      ..where((t) => t.quality.equals(quality))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(pageItemCount, offset: page * pageItemCount);
    return await query.get();
  }

  // ==================== 按槽位筛选 ====================

  /// 按槽位分页查询装备
  ///
  /// [slot] 槽位: weapon / armor / accessory / treasure
  /// [page] 页码 (从0开始)
  Future<List<EquipmentTableData>> getBySlot(String slot,
      {int page = 0}) async {
    final query = select(db.equipmentTable)
      ..where((t) => t.slot.equals(slot))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(pageItemCount, offset: page * pageItemCount);
    return await query.get();
  }

  // ==================== 背包软上限检查 ====================

  /// 检查背包是否达到软上限
  ///
  /// 返回 true 表示已达上限 (500件)，应提示玩家熔炼/出售
  Future<bool> isBagFull() async {
    final count = await equipmentCount();
    return count >= bagSoftLimit;
  }

  /// 获取当前装备总数
  Future<int> equipmentCount() async {
    final countExpr = db.equipmentTable.id.count();
    final query = selectOnly(db.equipmentTable)
      ..addColumns([countExpr])
      ..where(db.equipmentTable.isEquipped.equals(false));
    final result = await query.map((row) => row.read(countExpr)).getSingle();
    return result ?? 0;
  }

  // ==================== JSON 序列化/反序列化 ===================

  /// 从装备行数据中解析词缀列表
  ///
  /// 使用 parseAffixListCompat 兼容新旧两种 JSON 格式:
  /// - 新格式 (Affix): {id, name, position, effects, rolledValues}
  /// - 旧格式 (AffixData): {id, type, name, stat, value, isPercent}
  static List<Affix> parseAffixes(EquipmentTableData data) {
    return parseAffixListCompat(data.affixesJson);
  }

  /// 将词缀列表序列化为 JSON 字符串
  ///
  /// 使用统一的 Affix.toJson 格式
  static String serializeAffixes(List<Affix> affixes) {
    return serializeAffixListCompat(affixes);
  }

  // ==================== 统计 ====================

  /// 按品质统计装备数量
  ///
  /// 返回 Map<品质, 数量>
  Future<Map<String, int>> countByQuality() async {
    final query = selectOnly(db.equipmentTable)
      ..addColumns([db.equipmentTable.quality, db.equipmentTable.id.count()])
      ..groupBy([db.equipmentTable.quality]);
    final result = await query.map((row) {
      return MapEntry(
        row.read(db.equipmentTable.quality)!,
        row.read(db.equipmentTable.id.count()) ?? 0,
      );
    }).get();
    return Map.fromEntries(result);
  }

  /// 按槽位统计装备数量
  Future<Map<String, int>> countBySlot() async {
    final query = selectOnly(db.equipmentTable)
      ..addColumns([db.equipmentTable.slot, db.equipmentTable.id.count()])
      ..groupBy([db.equipmentTable.slot]);
    final result = await query.map((row) {
      return MapEntry(
        row.read(db.equipmentTable.slot)!,
        row.read(db.equipmentTable.id.count()) ?? 0,
      );
    }).get();
    return Map.fromEntries(result);
  }

  /// 获取最强装备 (按物品等级排序)
  Future<List<EquipmentTableData>> getTopEquipments({int limit = 10}) async {
    final query = select(db.equipmentTable)
      ..orderBy([
        (t) => OrderingTerm.desc(t.itemLevel),
        (t) => OrderingTerm.desc(t.reinforceLevel),
      ])
      ..limit(limit);
    return await query.get();
  }

  // ==================== 统一分页查询 (UI层调用) ====================

  /// 统一分页查询（支持品质+槽位组合筛选）
  ///
  /// [page] 页码 (从0开始)
  /// [pageSize] 每页条数 (默认50)
  /// [quality] 品质筛选 (可空)
  /// [slot] 槽位筛选 (可空)
  Future<List<EquipmentTableData>> getPage({
    int page = 0,
    int pageSize = 50,
    String? quality,
    String? slot,
  }) async {
    final query = select(db.equipmentTable);
    if (quality != null) {
      query.where((t) => t.quality.equals(quality));
    }
    if (slot != null) {
      query.where((t) => t.slot.equals(slot));
    }
    query
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(pageSize, offset: page * pageSize);
    return await query.get();
  }

  // ==================== 装备/卸下 ====================

  /// 装备一件装备 (设置 isEquipped=true)
  ///
  /// 同时卸下同槽位的其他装备 (一个槽位只能装备一件)
  Future<void> equip(String id) async {
    await db.transaction(() async {
      // 先查询这件装备的槽位
      final item = await getById(id);
      if (item == null) return;
      final slot = item.slot;
      // 卸下同槽位的其他已装备装备
      final sameSlotEquipped = await (select(db.equipmentTable)
            ..where((t) => t.slot.equals(slot) & t.isEquipped.equals(true)))
          .get();
      for (final e in sameSlotEquipped) {
        await (update(db.equipmentTable)..where((t) => t.id.equals(e.id)))
            .write(const EquipmentTableCompanion(isEquipped: Value(false)));
      }
      // 装备目标装备
      await (update(db.equipmentTable)..where((t) => t.id.equals(id)))
          .write(const EquipmentTableCompanion(isEquipped: Value(true)));
    });
  }

  /// 卸下一件装备 (设置 isEquipped=false)
  Future<void> unequip(String id) async {
    await (update(db.equipmentTable)..where((t) => t.id.equals(id)))
        .write(const EquipmentTableCompanion(isEquipped: Value(false)));
  }

  /// 获取所有已装备的装备
  Future<List<EquipmentTableData>> getEquipped() async {
    final query = select(db.equipmentTable)
      ..where((t) => t.isEquipped.equals(true));
    return await query.get();
  }

  /// 获取指定槽位中所有未装备的装备（装备选择弹窗用）
  ///
  /// [slot] 槽位: weapon / armor / accessory / treasure
  Future<List<EquipmentTableData>> getUnequippedBySlot(String slot) async {
    final query = select(db.equipmentTable)
      ..where((t) => t.slot.equals(slot) & t.isEquipped.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return await query.get();
  }

  // ==================== UI 层需要的额外方法 ====================

  /// 获取所有装备 (UI层 getAll)
  Future<List<EquipmentTableData>> getAll() async {
    return await select(db.equipmentTable).get();
  }

  /// 创建新装备 (UI层 create)
  Future<String> create({
    required String baseId,
    required String quality,
    required String slot,
    required String name,
    required int itemLevel,
    String affixesJson = '[]',
    int reinforceLevel = 0,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await into(db.equipmentTable).insert(EquipmentTableCompanion.insert(
      id: id,
      baseId: baseId,
      quality: quality,
      slot: slot,
      name: name,
      itemLevel: itemLevel,
      affixesJson: Value(affixesJson),
      reinforceLevel: Value(reinforceLevel),
    ));
    return id;
  }

  /// 更新强化等级
  Future<void> updateReinforceLevel(String id, int level) async {
    await (update(db.equipmentTable)..where((t) => t.id.equals(id)))
        .write(EquipmentTableCompanion(reinforceLevel: Value(level)));
  }

  /// 删除装备 (使用 ID) — deleteById 已在上方定义
}
