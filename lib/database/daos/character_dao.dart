import 'dart:convert';

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/character_table.dart';
import 'power_calculator.dart';
import '../../utils/app_logger.dart';

part 'character_dao.g.dart';

/// 角色 DAO — 角色状态表的数据访问层
///
/// 功能:
/// - 单角色状态读写 (此表始终只有一行 id=1)
/// - 自动重算战力指数
/// - JSON 字段序列化/反序列化 (五维属性/武功/经脉)
@DriftAccessor(tables: [CharacterTable])
class CharacterDao extends DatabaseAccessor<AppDatabase>
    with _$CharacterDaoMixin {
  CharacterDao(super.db);

  /// 获取角色状态 (单行表，取 id=1)
  Future<CharacterTableData?> getCharacter() async {
    AppLogger.instance.info('[getCharacter] 查询角色数据...');
    final query = select(db.characterTable)
      ..where((t) => t.id.equals(1));
    final result = await query.getSingleOrNull();
    if (result == null) {
      AppLogger.instance.info('[getCharacter] 查询结果: 无角色');
    } else {
      AppLogger.instance.info('[getCharacter] 查询结果: 有角色 — ${result.name}, 等级=${result.level}, 战力=${result.powerIndex}');
    }
    return result;
  }

  /// 创建新角色 (首次存档)
  ///
  /// [name] 角色名
  /// [origin] 出身
  /// [attributes] 五维属性 {"body":10,"agi":8,"wis":12,"con":10,"luck":5}
  /// [health] 初始生命值 (默认按 body*15 计算满值)
  /// [innerEnergy] 初始内力值 (默认按 con*10 计算满值)
  /// [silver] 初始银两 (默认 100)
  ///
  /// 创建后自动重算战力指数
  Future<void> createCharacter({
    required String name,
    String origin = '',
    required Map<String, int> attributes,
    int? health,
    int? innerEnergy,
    int silver = 100,
  }) async {
    final body = attributes['body'] ?? 10;
    final con = attributes['con'] ?? 10;
    // 初始生命/内力设为满值 (level=1)
    final maxHealth = body * 15;
    final maxInnerEnergy = con * 10;
    final initHealth = health ?? maxHealth;
    final initInnerEnergy = innerEnergy ?? maxInnerEnergy;
    AppLogger.instance.info('[createCharacter] 插入前: name=$name, origin=$origin, health=$initHealth, innerEnergy=$initInnerEnergy, silver=$silver');
    try {
      final companion = CharacterTableCompanion.insert(
        name: name,
        origin: Value(origin),
        attributesJson: Value(jsonEncode(attributes)),
        health: Value(initHealth),
        innerEnergy: Value(initInnerEnergy),
        silver: Value(silver),
      );
      await into(db.characterTable).insert(companion);
      AppLogger.instance.info('[createCharacter] 插入完成');
      // 创建后重算战力指数
      AppLogger.instance.info('[createCharacter] 重算战力前...');
      final powerIndex = await recalculateAndSavePowerIndex();
      AppLogger.instance.info('[createCharacter] 重算战力后: powerIndex=$powerIndex');
    } catch (e) {
      AppLogger.instance.error('[createCharacter] 异常: $e');
      rethrow;
    }
  }

  /// 更新角色完整状态
  ///
  /// 会自动重算战力指数
  Future<void> updateCharacter(CharacterTableCompanion companion) async {
    // 重算战力指数
    final recalculated = await _recalculatePowerIndex(companion);
    await (update(db.characterTable)..where((t) => t.id.equals(1)))
        .write(recalculated);
  }

  /// 更新五维属性 (会自动重算战力)
  Future<void> updateAttributes(Map<String, int> attributes) async {
    await (update(db.characterTable)..where((t) => t.id.equals(1))).write(
      CharacterTableCompanion(
        attributesJson: Value(jsonEncode(attributes)),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await recalculateAndSavePowerIndex();
  }

  /// 更新武功列表 (会自动重算战力)
  Future<void> updateMartialArts(List<MartialArtData> arts) async {
    await (update(db.characterTable)..where((t) => t.id.equals(1))).write(
      CharacterTableCompanion(
        martialArtsJson: Value(MartialArtData.toJsonList(arts)),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await recalculateAndSavePowerIndex();
  }

  /// 更新经脉状态 (会自动重算战力)
  Future<void> updateMeridians(List<MeridianNodeData> nodes) async {
    await (update(db.characterTable)..where((t) => t.id.equals(1))).write(
      CharacterTableCompanion(
        meridiansJson: Value(MeridianNodeData.toJsonList(nodes)),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await recalculateAndSavePowerIndex();
  }

  /// 更新心法
  Future<void> updateHeartMantra(String? heartMantraId) async {
    await (update(db.characterTable)..where((t) => t.id.equals(1))).write(
      CharacterTableCompanion(
        heartMantra: Value(heartMantraId),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await recalculateAndSavePowerIndex();
  }

  /// 更新生命值
  Future<void> updateHealth(int health) async {
    await (update(db.characterTable)..where((t) => t.id.equals(1))).write(
      CharacterTableCompanion(
        health: Value(health),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 更新内力值
  Future<void> updateInnerEnergy(int innerEnergy) async {
    await (update(db.characterTable)..where((t) => t.id.equals(1))).write(
      CharacterTableCompanion(
        innerEnergy: Value(innerEnergy),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 更新等级
  Future<void> updateLevel(int level) async {
    await (update(db.characterTable)..where((t) => t.id.equals(1))).write(
      CharacterTableCompanion(
        level: Value(level),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await recalculateAndSavePowerIndex();
  }

  // ==================== 战力指数计算 ====================

  /// 重算并保存战力指数
  ///
  /// 读取当前角色状态，综合计算后写回 powerIndex 字段
  Future<int> recalculateAndSavePowerIndex() async {
    final character = await getCharacter();
    if (character == null) return 0;

    // 查询已装备的装备并计算装备战力贡献
    final equipped = await db.equipmentDao.getEquipped();
    final equipmentPowerSum = PowerCalculator.calculateEquipmentPower(
      equipped.map((e) => EquipmentPowerInput(
        itemLevel: e.itemLevel,
        quality: e.quality,
        reinforceLevel: e.reinforceLevel,
        affixesJson: e.affixesJson,
      )).toList(),
    );

    final powerIndex = _calculatePowerFromCharacter(character,
        equipmentPowerSum: equipmentPowerSum);

    await (update(db.characterTable)..where((t) => t.id.equals(1))).write(
      CharacterTableCompanion(
        powerIndex: Value(powerIndex),
        updatedAt: Value(DateTime.now()),
      ),
    );

    return powerIndex;
  }

  /// 计算战力指数 (不写回数据库)
  int _calculatePowerFromCharacter(CharacterTableData character,
      {int equipmentPowerSum = 0}) {
    // 解析五维属性
    final attrs = jsonDecode(character.attributesJson) as Map<String, dynamic>;

    // 解析武功
    final arts = MartialArtData.fromJsonList(character.martialArtsJson);
    final proficiencySum = arts.fold<int>(0, (sum, a) => sum + a.proficiency);

    // 解析经脉
    final meridians = MeridianNodeData.fromJsonList(character.meridiansJson);
    final openCount = meridians.where((m) => m.isOpen).length;

    return PowerCalculator.calculate(
      body: (attrs['body'] ?? 0) as int,
      agi: (attrs['agi'] ?? 0) as int,
      wis: (attrs['wis'] ?? 0) as int,
      con: (attrs['con'] ?? 0) as int,
      luck: (attrs['luck'] ?? 0) as int,
      level: character.level,
      health: character.health,
      innerEnergy: character.innerEnergy,
      martialArtsCount: arts.length,
      martialArtsProficiencySum: proficiencySum,
      meridianOpenCount: openCount,
      heartMantraActive: character.heartMantra != null,
      // 装备战力通过参数传入，由 recalculateAndSavePowerIndex 查询计算
      equipmentPowerSum: equipmentPowerSum,
    );
  }

  /// 在更新时计算战力并附加到 companion
  Future<CharacterTableCompanion> _recalculatePowerIndex(
      CharacterTableCompanion companion) async {
    // 获取当前角色状态
    final character = await getCharacter();
    if (character == null) return companion;

    // 查询已装备的装备并计算装备战力贡献
    final equipped = await db.equipmentDao.getEquipped();
    final equipmentPowerSum = PowerCalculator.calculateEquipmentPower(
      equipped.map((e) => EquipmentPowerInput(
        itemLevel: e.itemLevel,
        quality: e.quality,
        reinforceLevel: e.reinforceLevel,
        affixesJson: e.affixesJson,
      )).toList(),
    );

    // 用新值覆盖旧值计算
    final powerIndex = PowerCalculator.calculate(
      body: _getIntFromCompanion(companion.attributesJson, character, 'body'),
      agi: _getIntFromCompanion(companion.attributesJson, character, 'agi'),
      wis: _getIntFromCompanion(companion.attributesJson, character, 'wis'),
      con: _getIntFromCompanion(companion.attributesJson, character, 'con'),
      luck: _getIntFromCompanion(companion.attributesJson, character, 'luck'),
      level: companion.level.present
          ? companion.level.value
          : character.level,
      health: companion.health.present
          ? companion.health.value
          : character.health,
      innerEnergy: companion.innerEnergy.present
          ? companion.innerEnergy.value
          : character.innerEnergy,
      martialArtsCount: companion.martialArtsJson.present
          ? MartialArtData.fromJsonList(companion.martialArtsJson.value).length
          : MartialArtData.fromJsonList(character.martialArtsJson).length,
      martialArtsProficiencySum: companion.martialArtsJson.present
          ? MartialArtData.fromJsonList(
                  companion.martialArtsJson.value)
              .fold<int>(0, (sum, a) => sum + a.proficiency)
          : MartialArtData.fromJsonList(
                  character.martialArtsJson)
              .fold<int>(0, (sum, a) => sum + a.proficiency),
      meridianOpenCount: companion.meridiansJson.present
          ? MeridianNodeData.fromJsonList(
                  companion.meridiansJson.value)
              .where((m) => m.isOpen)
              .length
          : MeridianNodeData.fromJsonList(
                  character.meridiansJson)
              .where((m) => m.isOpen)
              .length,
      heartMantraActive: companion.heartMantra.present
          ? companion.heartMantra.value != null
          : character.heartMantra != null,
      equipmentPowerSum: equipmentPowerSum,
    );

    return companion.copyWith(powerIndex: Value(powerIndex));
  }

  /// 从 companion 或 fallback 中获取五维属性整数值
  int _getIntFromCompanion(
      Value<String> attributesJsonValue,
      CharacterTableData fallback,
      String key) {
    final source = attributesJsonValue.present
        ? attributesJsonValue.value
        : fallback.attributesJson;
    final attrs = jsonDecode(source) as Map<String, dynamic>;
    return (attrs[key] ?? 0) as int;
  }

  // ==================== JSON 序列化辅助 ====================

  /// 从角色行数据中解析五维属性
  static Map<String, int> parseAttributes(CharacterTableData data) {
    final decoded = jsonDecode(data.attributesJson) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  /// 从角色行数据中解析武功列表
  static List<MartialArtData> parseMartialArts(CharacterTableData data) {
    return MartialArtData.fromJsonList(data.martialArtsJson);
  }

  /// 从角色行数据中解析经脉状态
  static List<MeridianNodeData> parseMeridians(CharacterTableData data) {
    return MeridianNodeData.fromJsonList(data.meridiansJson);
  }

  // ==================== 银两管理 ====================

  /// 获取当前银两
  Future<int> getSilver() async {
    final character = await getCharacter();
    return character?.silver ?? 0;
  }

  /// 增加银两 (出售装备/完成任务等)
  Future<void> addSilver(int amount) async {
    final character = await getCharacter();
    final currentSilver = character?.silver ?? 0;
    await (update(db.characterTable)..where((t) => t.id.equals(1))).write(
      CharacterTableCompanion(
        silver: Value(currentSilver + amount),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 消耗银两 (购买/赌博/强化等)
  ///
  /// 返回 true 表示银两足够并已扣除，false 表示银两不足
  Future<bool> spendSilver(int amount) async {
    final character = await getCharacter();
    final currentSilver = character?.silver ?? 0;
    if (currentSilver < amount) return false;
    await (update(db.characterTable)..where((t) => t.id.equals(1))).write(
      CharacterTableCompanion(
        silver: Value(currentSilver - amount),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return true;
  }

  // ==================== 真气逆行(Qi Deviation) ====================

  /// 获取真气逆行值 (存于 settings 表, 0=正常)
  Future<int> getQiDeviation() async {
    return db.settingsDao.getInt('qiDeviation');
  }

  /// 清除真气逆行
  Future<void> clearQiDeviation() async {
    await db.settingsDao.setInt('qiDeviation', 0);
  }

  /// 设置真气逆行值
  Future<void> setQiDeviation(int value) async {
    await db.settingsDao.setInt('qiDeviation', value);
  }
}
