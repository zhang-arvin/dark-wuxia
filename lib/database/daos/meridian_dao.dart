import 'dart:convert';

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/character_table.dart';
import '../tables/meridian_state_table.dart';
import 'power_calculator.dart';

part 'meridian_dao.g.dart';

/// 参数校验引发的业务错误（不消耗银两）
class MeridianBusinessException implements Exception {
  final String message;
  const MeridianBusinessException(this.message);

  @override
  String toString() => 'MeridianBusinessException: $message';
}

/// 真气逆行警告
class QiDeviationWarning {
  /// 本次激活的目标经脉 ID
  final String meridianId;

  /// 与目标相克、且当前已激活的经脉 ID
  final List<String> activeConflicts;

  const QiDeviationWarning({
    required this.meridianId,
    this.activeConflicts = const [],
  });

  bool get hasConflict => activeConflicts.isNotEmpty;

  @override
  String toString() =>
      'QiDeviationWarning($meridianId conflicts=$activeConflicts)';
}

/// 经脉 DAO — 经脉状态表的数据访问层
///
/// 功能:
/// - 获取所有经脉状态 (对应 meridians.json 的 15 条经脉)
/// - 冲开穴位 (第N穴消耗 100+N×50 银两)
/// - 激活/关闭整脉 (激活相克经脉触发真气逆行警告)
/// - 每次操作后重算战力指数
@DriftAccessor(tables: [MeridianStateTable, CharacterTable])
class MeridianDao extends DatabaseAccessor<AppDatabase>
    with _$MeridianDaoMixin {
  MeridianDao(super.db);

  /// 经脉配置条目样例（供花名册调用）— 花名册是 ConfigLoader.MeridianConfigEntry
  /// 的状态视图，DAO 里不做类型依赖。

  // ==================== 查询 ====================

  /// 获取所有经脉状态
  ///
  /// 返回 Map<经脉ID, 状态行> 以及原始行列表
  Future<List<MeridianStateTableData>> getStates() async {
    final query = select(db.meridianStateTable)
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    return await query.get();
  }

  /// 获取单条经脉状态 (不存在返回 null)
  Future<MeridianStateTableData?> getState(String meridianId) async {
    final query = select(db.meridianStateTable)
      ..where((t) => t.meridianId.equals(meridianId));
    return await query.getSingleOrNull();
  }

  /// 获取当前已激活的经脉 ID 列表
  Future<List<String>> getActiveMeridianIds() async {
    final query = select(db.meridianStateTable)
      ..where((t) => t.isActive.equals(true));
    final rows = await query.get();
    return rows.map((r) => r.meridianId).toList();
  }

  /// 检查激活 [meridianId] 是否与已激活经脉相克（真气逆行）
  ///
  /// [conflictIdsForMeridian] 回调: 由调用方(配置层)提供目标经脉的相克列表。
  /// 返回 [QiDeviationWarning]，hasConflict=false 表示可安全激活。
  Future<QiDeviationWarning> checkQiDeviation(
    String meridianId, {
    required List<String> Function(String meridianId) conflictIdsForMeridian,
  }) async {
    final conflicts =
        (conflictIdsForMeridian(meridianId) ?? const <String>[])
            .toList();
    final activeIds = await getActiveMeridianIds();
    final activeConflicts = activeIds.where(conflicts.contains).toList();
    return QiDeviationWarning(
      meridianId: meridianId,
      activeConflicts: activeConflicts,
    );
  }

  // ==================== 冲关 ====================

  /// 第 N 穴 (N 从 1 开始) 的银两消耗: 100 + N × 50
  int silverCostForNode(int nextNodeIndex) =>
      100 + nextNodeIndex * 50;

  /// 冲开一个穴位
  ///
  /// - 银两不足或该脉已达上限时抛 [MeridianBusinessException]
  /// - 成功后 openedNodes+1，并重算战力
  /// - [maxNodes] 该脉总穴位数，默认 5
  Future<void> openNode(
    String meridianId, {
    int maxNodes = 5,
  }) async {
    final state = await getState(meridianId);
    final opened = state?.openedNodes ?? 0;

    if (opened >= maxNodes) {
      throw MeridianBusinessException(
          '经脉 $meridianId 已全部冲开 (openedNodes=$opened)');
    }

    final nextNodeIndex = opened + 1; // 下一穴序号 (1-based)
    final cost = silverCostForNode(nextNodeIndex);

    await db.transaction(() async {
      // 银两不足时回滚并抛业务异常
      final silverOk = await db.characterDao.spendSilver(cost);
      if (!silverOk) {
        throw MeridianBusinessException(
            '银两不足: 冲开第$nextNodeIndex穴需 $cost 两');
      }

      if (state == null) {
        await into(db.meridianStateTable).insert(
          MeridianStateTableCompanion.insert(
            meridianId: meridianId,
            openedNodes: const Value(1),
          ),
        );
      } else {
        await (update(db.meridianStateTable)
              ..where((t) => t.meridianId.equals(meridianId)))
            .write(MeridianStateTableCompanion(
          openedNodes: Value(state.openedNodes + 1),
          updatedAt: Value(DateTime.now()),
        ));
      }
    });

    await _syncCharacterMeridians();
    await db.characterDao.recalculateAndSavePowerIndex();
  }

  // ==================== 激活 / 关闭 ====================

  /// 激活整脉
  ///
  /// - 若与已激活经脉相克，设置真气逆行警告值 (settings.qiDeviation
  ///   已通过 characterDao.setQiDeviation 持久化) 并返回警告
  /// - [requireAllNodesOpened] 为 true 时需要全部穴位冲开才能激活
  /// - [conflictIdsForMeridian] 提供目标经脉的相克列表
  Future<QiDeviationWarning> activateMeridian(
    String meridianId, {
    bool requireAllNodesOpened = true,
    int maxNodes = 5,
    List<String> Function(String meridianId)? conflictIdsForMeridian,
  }) async {
    final state = await getState(meridianId);
    return _activate(
      meridianId,
      state: state,
      requireAllNodesOpened: requireAllNodesOpened,
      maxNodes: maxNodes,
      conflictIdsForMeridian:
          conflictIdsForMeridian ?? _noConflicts,
    );
  }

  /// 关闭整脉 (整脉失效，真气逆行随之解除)
  ///
  /// [conflictIdsForMeridian] 提供相克列表时，若关闭后不再存在
  /// 任何已激活的相克对，则清除真气逆行。
  Future<void> deactivateMeridian(
    String meridianId, {
    List<String> Function(String meridianId)? conflictIdsForMeridian,
  }) async {
    final state = await getState(meridianId);
    if (state == null || !state.isActive) return;

    await db.transaction(() async {
      await (update(db.meridianStateTable)
            ..where((t) => t.meridianId.equals(meridianId)))
          .write(MeridianStateTableCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ));

      // 解除真气逆行标记 (仅在不再有相克对时)
      await _tryClearQiDeviation(conflictIdsForMeridian);
    });

    await _syncCharacterMeridians();
    await db.characterDao.recalculateAndSavePowerIndex();
  }

  /// 内部激活逻辑
  Future<QiDeviationWarning> _activate(
    String meridianId, {
    required MeridianStateTableData? state,
    required bool requireAllNodesOpened,
    required int maxNodes,
    required List<String> Function(String meridianId)
        conflictIdsForMeridian,
  }) async {
    final opened = state?.openedNodes ?? 0;

    if (state != null && state.isActive) {
      throw const MeridianBusinessException('该经脉已激活');
    }
    if (requireAllNodesOpened && opened < maxNodes) {
      throw MeridianBusinessException(
          '需冲开全部穴位才能激活 ($opened/${maxNodes}穴)');
    }

    // 相克检测
    final warning = await checkQiDeviation(
      meridianId,
      conflictIdsForMeridian: conflictIdsForMeridian,
    );

    await db.transaction(() async {
      if (state == null) {
        await into(db.meridianStateTable).insert(
          MeridianStateTableCompanion.insert(
            meridianId: meridianId,
            isActive: const Value(true),
          ),
        );
      } else {
        await (update(db.meridianStateTable)
              ..where((t) => t.meridianId.equals(meridianId)))
            .write(MeridianStateTableCompanion(
          isActive: const Value(true),
          updatedAt: Value(DateTime.now()),
        ));
      }

      if (warning.hasConflict) {
        // 真气逆行: 增加逆行值（触发 warning）
        final current =
            await db.characterDao.getQiDeviation();
        await db.characterDao
            .setQiDeviation(current + warning.activeConflicts.length);
      }
    });

    await _syncCharacterMeridians();
    await db.characterDao.recalculateAndSavePowerIndex();
    return warning;
  }

  /// 若已无相克冲突激活，清除真气逆行
  ///
  /// 未提供 [conflictIdsForMeridian] 时按保守策略:
  /// 真气逆行值减1 (每次关闭解除至少一对相克)。
  Future<void> _tryClearQiDeviation(
    List<String> Function(String meridianId)? conflictIdsForMeridian,
  ) async {
    final current = await db.characterDao.getQiDeviation();
    if (current <= 0) return;
    if (conflictIdsForMeridian == null) {
      await db.characterDao.setQiDeviation(current - 1);
      return;
    }
    final remaining = await _countActiveConflicts(
      conflictIdsForMeridian: conflictIdsForMeridian,
    );
    if (remaining == 0) {
      await db.characterDao.clearQiDeviation();
    }
  }

  /// 统计当前已激活经脉之间存在的冲突数量
  Future<int> _countActiveConflicts({
    required List<String> Function(String meridianId)
        conflictIdsForMeridian,
  }) async {
    final activeIds = (await getActiveMeridianIds()).toSet();
    var count = 0;
    for (final id in activeIds) {
      for (final c in conflictIdsForMeridian(id)) {
        if (activeIds.contains(c)) count++;
      }
    }
    return count ~/ 2; // 每对冲突算了两次
  }

  /// 无相克关系的兜底回调
  static List<String> _noConflicts(String meridianId) => const [];

  // ==================== 角色经脉 JSON 同步 ====================

  /// 将本表状态同步到 character.meridiansJson（保持兼容）
  ///
  /// 每次打开穴位/激活/关闭后调用。
  /// 同步规则:
  /// - 按 openedNodes 冲开前 N 个穴位 (nodeIndex 0..N-1)
  /// - character 中原有的放开穴位记录被忽略（本表为权威数据源）
  Future<void> _syncCharacterMeridians() async {
    final states = await getStates();
    final nodes = <MeridianNodeData>[];
    for (final s in states) {
      for (var i = 0; i < s.openedNodes; i++) {
        nodes.add(MeridianNodeData(
          meridianId: s.meridianId,
          nodeIndex: i,
          isOpen: true,
        ));
      }
    }
    await (update(db.characterTable)..where((t) => t.id.equals(1))).write(
      CharacterTableCompanion(
        meridiansJson: Value(jsonEncode(
            nodes.map((n) => n.toJson()).toList())),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 确保角色存在 15 条经脉的初始状态行（幂等）
  ///
  /// [meridianIds] 来自 ConfigLoader.meridianConfigs
  Future<void> ensureStatesFor(List<String> meridianIds) async {
    await db.transaction(() async {
      for (final id in meridianIds) {
        final existing = await getState(id);
        if (existing == null) {
          await into(db.meridianStateTable).insert(
            MeridianStateTableCompanion.insert(
              meridianId: id,
              openedNodes: const Value(0),
            ),
          );
        }
      }
    });
  }
}