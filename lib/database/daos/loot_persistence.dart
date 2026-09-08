// =============================================================================
// loot_persistence.dart — 掉落结算持久化（延迟结算层）
//
// 定稿方案：战斗/探索期间的掉落不再"战斗中立即写库"，而是：
//   1. 战斗页把 BattleResult（含 drops）通过 pop 返回值交还调用方
//   2. 探索页把掉落累积进"会话收益池"
//   3. 只有两个结算点写库：**撤离秘境** 与 **通关**（连刷路径=胜利即结算）
//   4. 探索失败 = 收益池整体丢弃（零回滚代码，崩溃也不留脏数据）
//
// 气血惩罚（playerHealthRemaining 写回）不在此列——失败时气血惩罚仍然生效。
// =============================================================================

import 'package:drift/drift.dart' show Value;

import '../../engine/config_loader.dart';
import '../../engine/drop_engine.dart';
import '../../utils/app_logger.dart';
import '../database.dart';

/// 掉落结算：把一场战斗/一次秘境的掉落列表写入装备表+掉落记录表。
class LootPersistence {
  /// 持久化掉落列表（幂等：重复调用会重复插入，调用方保证只调一次）
  static Future<void> persistDrops(
    List<DropResult> drops,
    ConfigLoader? config,
  ) async {
    if (drops.isEmpty) return;

    final db = AppDatabase.instance;

    for (final drop in drops) {
      final equip = drop.equipment;
      final qualityText = equip.quality.displayName;
      AppLogger.instance.info('[loot] 结算掉落: [$qualityText] ${equip.name}');

      try {
        // 确定槽位：优先从暗金配置查，其次从基础装备配置查
        String slot = 'weapon'; // 默认
        if (config != null) {
          if (equip.uniqueId != null) {
            final uniqueDef = config.getUniqueEquipment(equip.uniqueId!);
            if (uniqueDef != null) {
              slot = uniqueDef.slot.toJson();
            }
          } else {
            final base = config.getEquipmentBase(equip.baseId);
            if (base != null) {
              slot = base.slot.toJson();
            }
          }
        }

        // 序列化词缀
        final affixesJson = equip.affixes.isNotEmpty
            ? '[${equip.affixes.map((a) => '{"id":"${a.id}","name":"${a.name}","position":"${a.position.toJson()}","effects":${_mapToJson(a.effects)},"rolledValues":${_mapToJson(a.rolledValues)}}').join(',')}]'
            : '[]';

        // 插入装备表
        await db.equipmentDao.insertEquipment(EquipmentTableCompanion.insert(
          id: equip.id,
          baseId: equip.baseId,
          quality: equip.quality.toJson(),
          slot: slot,
          name: equip.name,
          affixesJson: Value(affixesJson),
          reinforceLevel: Value(equip.reinforceLevel),
          meridianSeedId: Value(equip.meridianSeedId),
          itemLevel: equip.itemLevel,
        ));

        // 插入掉落记录
        await db.dropDao.recordDrop(DropHistoryTableCompanion.insert(
          equipmentId: equip.id,
          realmId: drop.record.realmId,
          layer: drop.record.layer,
          quality: equip.quality.toJson(),
          timestamp: Value(drop.record.timestamp),
        ));
      } catch (e) {
        AppLogger.instance.error('[loot] 结算掉落写入失败: $e');
      }
    }
  }

  static String _mapToJson(Map<String, int> map) {
    final entries = map.entries.map((e) => '"${e.key}":${e.value}').join(',');
    return '{$entries}';
  }
}