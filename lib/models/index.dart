// =============================================================================
// models/index.dart — 统一导出所有数据模型
//
// 对应 DESIGN.md 章节：五、数据结构（5.1 核心数据模型 / 5.2 配置数据）
//
// 使用方式: import 'package:.../models/index.dart';
// =============================================================================

// 共用枚举
export 'enums.dart';

// 五维属性
export 'attributes.dart';

// 角色与玩家状态
export 'character.dart';

// 装备系统（Equipment, Affix, AffixRange, EquipmentBase, SetBonus）
export 'equipment.dart';

// 武功
export 'martial_art.dart';

// 经脉系统（MeridianNode, MeridianSeed, MeridianSeedSlot, MeridianWord, MeridianConfig）
export 'meridian.dart';

// 秘境系统（RealmProgress, RealmConfig）
export 'secret_realm.dart';

// 掉落系统（DropTable, DropRecord, PityCounter）
export 'drop.dart';

// 战斗描写模板（NarrationTemplate）
export 'narration.dart';

// 暗金独特效果（UniqueEffect, UniqueEquipment）
export 'unique_effect.dart';

// 心法（HeartMantra）
export 'heart_mantra.dart';

// 敌人系统（Enemy, Boss, BossPhase, EnemyMechanic）
export 'enemy.dart';

// 战斗系统（BattleState, BattleTurn, BattleAction, BattleResult）
export 'battle.dart';
