// =============================================================================
// models/drop_result.dart — 掉落结果（从 drop_engine 平移，批次2）
//
// 纯数据模型：零引擎依赖。一次掉落的完整信息（装备+记录+闪光+保底计数）。
// =============================================================================

import 'equipment.dart';
import 'drop.dart';
import 'enums.dart';

class DropResult {
  /// 生成的装备实例
  final Equipment equipment;

  /// 掉落记录
  final DropRecord record;

  /// 掉落闪光等级
  final DropFlashLevel flashLevel;

  /// 更新后的保底计数器
  final PityCounter updatedPity;

  /// 是否触发了保底
  final bool isPityTriggered;

  /// 暗金效果描述（如品质为暗金以上）
  final String? uniqueEffectDesc;

  /// 是否词缀翻倍惊喜（5% 概率，独立于品质判定）
  final bool isJackpot;

  const DropResult({
    required this.equipment,
    required this.record,
    required this.flashLevel,
    required this.updatedPity,
    this.isPityTriggered = false,
    this.uniqueEffectDesc,
    this.isJackpot = false,
  });

  @override
  String toString() =>
      'DropResult(${equipment.name} [${equipment.quality.displayName}] flash=${flashLevel.displayName}'
      '${isPityTriggered ? " [保底]" : ""})';
}
