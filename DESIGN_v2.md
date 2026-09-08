# 秘境玩法增强 v2 设计文档（4 模块 · 两周落地）

> 状态：待确认。确认后按批次实施，每批编译验证 + APK 交付。
> 原则：不动平衡内核（BattleEngine 的 RNG 序列与伤害公式），全部改动是**叠加层**。

---

## 总览与依赖

| # | 模块 | 价值 | 改引擎? | 依赖 |
|---|------|------|---------|------|
| 1 | 掉落爆发（品质特效+多件弹窗） | 爽点 | 否 | 无 |
| 2 | 广告复活（失败挽留） | 变现 | 否 | 失败作废系统（✅已上线） |
| 4→3 | 精英词缀敌人 → 秘境模组+Buff | 重开引力 | **是** | 敌人配置 + BuffContext 贯穿层 |

顺序说明：技术上 **4 先于 3**——4 只给 Enemy 加词缀字段（自包含），3 要新增 BuffContext 贯穿「探索→战斗→掉落」三层。两者都动引擎，但 4 简单先行可当引擎扩展的试水。

---

## 模块 1：掉落爆发

### 需求
1. 品质视觉分级：神话=红光+震动；暗金=橙光；橙色以下平光
2. 多件掉落弹窗：精英/宝箱/Boss 掉 2-4 件，一张卡片列
3. 惊喜机制：5% 概率"词缀翻倍"（本批装备词缀数×2）

### 数据结构（lib/models/loot_batch.dart 新增）

```dart
enum LootSource { battle, elite, treasure, boss, jackpot }

class LootBatch {
  final List<DropResult> items;   // 延迟结算语义不变
  final LootSource source;
  final bool isJackpot;           // 词缀翻倍触发
}

/// 品质 → 视觉等级映射
enum QualityTier { mythic, legendary, rare, common }

QualityTier tierOf(Quality q) {
  // 神话/神品 → mythic；暗金 → legendary；橙 → rare；其余 common
}
```

### UI（lib/ui/widgets/loot_explosion_overlay.dart 新增）
- 全屏 Overlay，黑色半透明 0.75 遮罩
- 装备卡片 **0.15s 交错入场**（scale 0.8→1.0 + fade）
- mythic：红金色边框 + `HapticFeedback.heavyImpact` 屏幕震动
- legendary：橙色边框 + `HapticFeedback.mediumImpact`
- Synced 音效：现有 `drop` 音效；mythic 用 `crit` 音效（已存在，无新资源依赖）
- 点击任意处关闭

### 接入点
| 文件 | 改动 |
|------|------|
| battle_page._finishBattle | 掉落行展示 → 收集为 LootBatch → 弹 overlay |
| battle_page._runAutoBattle | 同样改造 |
| exploration_page（宝箱/精英节点） | loot 结算点也弹（先做战斗页，探索页第二批） |
| drop_engine | 加 `rollJackpot()`：5% 返回 true；true 时本批词缀 ×2 |

### 验收
- 神品掉落：红光+震动+音效，肉眼可辨
- 精英/宝箱掉 2-4 件，弹窗逐张入场
- 词缀翻倍事件：日志有「词缀翻倍！」提示

---

## 模块 2：广告复活

### 需求
玩家死亡瞬间（收益作废回调触发时），弹「广告复活」：
- 看广告成功 → HP 回 50%，收益池保留，从当前节点继续
- 拒绝 → 现有失败流程（收益作废）
- 每日 3 次上限（settingsDao 存 `revive_used_today` / date）

### AdService 抽象（lib/services/ad_service.dart 新增）

```dart
abstract class AdService {
  /// 返回 true = 用户看完了激励视频
  Future<bool> showRewardedAd();
  /// 本日剩余复活次数
  Future<int> dailyRevivesLeft();
  /// 消耗一次复活机会
  Future<void> consumeRevive();
}

/// 默认实现：3 秒倒计时模拟（SDK 集成就绪前的占位）
class MockAdService implements AdService { ... }
```

**决策点（待你确认）**：先跑 Mock（倒计时+弹窗模拟），后期接穿山甲/优量汇时替换实现即可，业务代码零改动。海外版可用 AdMob 同样接口。

### 接入点
| 文件 | 改动 |
|------|------|
| services/ad_service.dart | 新增（含 Provider：adServiceProvider → Mock） |
| exploration_page._markFailed | 失败前先查剩余次数 → 弹 revive 面板 → 看广告 → 复活分支（HP=50%*,收益池保留,_failed 不置位,_persistExplorationHp 写回） |
| battle_page._finishBattle（败北分支） | 同样弹（先做探索页，战斗页第二批） |

*HP 回 50%：`min(_maxHp, max(_hp, _maxHp ~/ 2))`，且计为一次"复活"，日志加 `⚠ 你从鬼门关醒了回来（HP恢复50%）。`

### 验收
- 失败瞬间弹广告面板，30s 不操作不自动通过
- 看广告 → 复活继续；拒绝 → 作废
- 每日 3 次，用完出「次数已用完」灰按钮

---

## 模块 4：精英词缀敌人（先于模块 3）

### 需求
小怪带 1 个词缀（20% 概率精英），词缀改变战斗行为：
| 词缀 | 效果 |
|------|------|
| 石肤 stoneSkin | 受伤 -40% |
| 瘟疫 plague | 战斗内每回合玩家 -2% maxHP（毒） |
| 闪现 blink | 精英前 2 回合先手 |
| 火链 chains | 每回合玩家额外受 1-3 点灼烧 |

精英掉落 +50%（dropMultiplier 0.5 加成）。

### 数据结构
```dart
// models/enemy.dart
enum EnemyAffix { stoneSkin, plague, blink, chains }

class Enemy {
  // 现有字段不变
  final EnemyAffix? affix;    // null=普通，非 null=精英
  bool get isElite => affix != null;
}

// engine/config_loader.dart：EnemyConfig 加 affix 字段（enemies.json 可选）
```

### 引擎接入（battle_engine.dart，叠加层）
- `initRuntime`：enemy.affix 存进 `BattleRuntimeState.enemyAffix`
- `_executeTurn` 玩家受伤结算后：plague → 追加毒伤；chains → 追加灼烧（动作描述注明）
- 先手：blink → `playerFirst` 前 2 回合强制 false
- 减伤：stoneSkin → 敌人受伤结算 ×0.6
- **RNG 安全**：词缀结算不消耗额外 RNG（毒伤定值：maxHP 的 2%；灼烧 1-3 用现有 roll 顺序内的值，或用固定 2——定值优先，避免 RNG 序列扰动影响既有测试）

### 配置 & 掉率
- `assets/config/enemies.json`：新增 `elite_*` 3-4 只（每种词缀 1 只）
- 探索引擎 `realm_exploration_engine`：battle 节点 20% roll 精英（`_rng.nextInt(100) < 20`）
- 精英计入击杀计数，战斗页顶部显示词缀 tag（如 `🔥火链`）

### 验收
- 约每 5 次战斗遇 1 只精英（日志回发可数）
- 石肤精英明显更硬；瘟疫精英血线持续掉
- 精英掉落数量多于普通（+50% 生效）

---

## 模块 3：秘境随机模组 + Buff 三选

### 需求
1. **开局模组**：进秘境前 roll 1 个全局规则（本局生效）
   - 毒影迷境：毒系词缀掉率 +30%
   - 血月之夜：敌人强 20%（全属性），掉落 +25%
   - 灵泉涌动：气血回复 +50%
   - 藏宝迷窟：宝箱节点出现率翻倍
2. **Buff 三选**：每 5 步弹一次，3 个随机 Buff 选 1（本局有效）
   - 血怒：暴击率 +15%
   - 铁骨：受伤 -15%
   - 贪婪：掉落 +10%
   - 气盈：内力回复 +20%
   - 破甲：对精英伤害 +20%
   - 迅影：闪避概率 +10%

### 数据结构（lib/models/session_mods.dart 新增）

```dart
enum RealmModifierType { poisonAffinity, bloodMoon, spiritSpring, treasureHunt }

class RealmModifier {
  final RealmModifierType type;
  final String title;       // 进门前展示
  final String description;
}

enum SessionBuffType { bloodfury, ironbone, greed, qiFlow, armorBreak, swift }

class SessionBuff {
  final SessionBuffType type;
  final String title;
  final String description;
}

/// 贯穿 探索→战斗→掉落 的会话修正参数（引擎叠加层）
class SessionMods {
  final Set<SessionBuff> buffs;
  final RealmModifier? modifier;

  double get critBonus;        // bloodfury / bloodMoon 副作用
  double get dmgReduce;        // ironbone
  double get dropMultiplier;   // greed / bloodMoon / treasureHunt
  double get poisonAffinity;   // poisonAffinity
  double get hpRegenBonus;     // spiritSpring
  double get eliteDmgBonus;    // armorBreak
  double get dodgeBonus;       // swift
}
```

### 引擎 API 扩展（关键，一次改全）
```dart
// BattleEngine.initRuntime 参数追加：
SessionMods? sessionMods,
// → BattleRuntimeState.mods 持有
// _executeTurn：crit/dodge/dmgReduce/eliteDmg 各在对应位置叠加
// DropEngine.roll：
//   dropMultiplier → 掉落概率乘区
//   poisonAffinity → 毒系词缀权重上调

// 探索引擎 realm_exploration_engine：
// generateNodes(realmId, difficulty, mods)：
//   modifier.bloodMoon → 敌人 powerIndex ×1.2
//   treasureHunt → treasure 节点概率 ×2
```

RNG 注意：加成是纯乘数，不新增随机源（除 buff 三选本身 roll——在探索页而非引擎，不污染战斗 RNG 序列）。

### 接入点
| 文件 | 改动 |
|------|------|
| models/session_mods.dart | 新增 |
| realm_exploration_engine | generateNodes 接收 mods；buff 三选步点插入（index%5==0 弹） |
| exploration_page | 开局弹 modifier 展示卡；buff 三选弹面板；_sessionMods 持有会话修正 |
| battle_page | `_startBattle` 从 exploration_page 传入 SessionMods（经 BattleRouteExtra.mods 字段） |
| battle_engine | initRuntime/stepTurn 接收 mods |
| drop_engine | roll 接收 mods |
| realm_select_page | _enterRealm 先弹 modifier roll 结果（进入前展示） |

### 验收
- 每局进门见 modifier 卡；每 5 步见 buff 三选面板
- buff/模组数值真实生效（血怒后暴击可见变多；血月下敌人血条明显长）
- SessionMods 不进存档——局内临时（无 schema 变更）

---

## 文件改动总表 + 分批计划

| Day | 批次 | 文件 | 风险 |
|-----|------|------|------|
| 1-2 | #1 掉落爆发 | loot_batch.dart, loot_explosion_overlay.dart, drop_engine(rollJackpot), battle_page | 低 |
| 3-4 | #2 广告复活 | ad_service.dart, providers, exploration_page | 低（Mock 无外部依赖） |
| 5-7 | #4 精英词缀 | enemy.dart, enemies.json, battle_engine, realm_exploration_engine, battle_page(tag) | 中（RNG 安全） |
| 8-10 | #3 模组+Buff | session_mods.dart, 引擎×2, 页面×3 | 中偏高（贯穿层） |
| 11-14 | 减速打磨 | 数值、文案、回归测试 | - |

**数据库 schema：零变更**（全部局内临时数据，不动 drift 表）。

## 待你确认的 2 点
1. 广告先跑 Mock（3 秒模拟）可否？你的广告账号/投放地区情况说一下，我判断 SDK 选型
2. 顺序 1→2→4→3（4 在 3 前，引擎扩展先易后难）可否？