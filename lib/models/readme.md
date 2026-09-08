# 暗黑武侠 · 数据模型层

> 对应 DESIGN.md 章节：五、数据结构（5.1 核心数据模型 / 5.2 配置数据）

## 文件结构

```
lib/models/
├── enums.dart           # 所有共用枚举（Dart 3 enhanced enum）
├── attributes.dart      # 五维属性 Attributes
├── character.dart       # 角色 Character + 玩家状态 PlayerState + EquipmentLoadout
├── equipment.dart       # 装备 Equipment + 词缀 Affix/AffixRange + 基础配置 EquipmentBase + 套装 SetBonus
├── martial_art.dart     # 武功 MartialArt
├── meridian.dart        # 经脉 MeridianNode + 真气种子 MeridianSeed + 经脉之语 MeridianWord + MeridianConfig
├── secret_realm.dart    # 秘境进度 RealmProgress + 秘境配置 RealmConfig
├── drop.dart            # 掉落表 DropTable + 掉落记录 DropRecord + 保底计数器 PityCounter
├── narration.dart       # 战斗描写模板 NarrationTemplate
├── unique_effect.dart   # 暗金独特效果 UniqueEffect + 暗金配置 UniqueEquipment
├── heart_mantra.dart    # 心法 HeartMantra
├── enemy.dart           # 敌人 Enemy + Boss + Boss阶段 BossPhase + 敌人机制 EnemyMechanic
├── battle.dart          # 战斗状态 BattleState + 回合 BattleTurn + 动作 BattleAction + 结果 BattleResult
├── index.dart           # 统一导出
└── readme.md            # 本文件
```

## 模型关系图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PlayerState (玩家会话状态)                      │
│  character: Character                                                │
│  currentScene, activeRealmId, backpackUsed, unlockedRealms         │
│  globalPityCounters: Map<String, int>                               │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     Character (角色，每世临时)                         │
│  name, origin, age, level, experience                               │
│  attributes: Attributes    ← 五维属性                                │
│  martialArts: List<MartialArt> ← 武功列表                             │
│  equipment: EquipmentLoadout ← 当前装备配置(4槽位)                      │
│  meridians: List<MeridianNode> ← 经脉状态(30穴位)                      │
│  heartMantraId: String?    ← 心法ID                                   │
│  health, innerEnergy, fortune, reputation, alignment, powerIndex   │
│  qiDeviation: QiDeviationLevel ← 真气逆行程度                         │
│  silver: int              ← 银两                                      │
└──────┬──────────┬──────────┬──────────┬─────────────────────────────┘
       │          │          │          │
       ▼          ▼          ▼          ▼
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐
│ Attributes│ │ MartialArt│ │Equipment │ │   MeridianNode    │
│ (五维属性) │ │ (武功)    │ │ Loadout  │ │   (经脉穴位)       │
│ body      │ │ id,name  │ │ (4槽位)   │ │ meridianId        │
│ agi       │ │ type     │ │ weapon   │ │ nodeIndex          │
│ wis       │ │ proficien │ │ armor    │ │ isOpen             │
│ con       │ │ level    │ │ accessory│ │ seedId             │
│ luck      │ │ element   │ │ treasure  │ └────────┬───────────┘
│           │ │ Affinity  │ └────┬─────┘          │
└──────────┘ └──────────┘      │                 │
                               │                 ▼
                               │        ┌──────────────────┐
                               │        │  MeridianWord     │
                               │        │  (经脉之语=符文之语) │
                               │        │  sequence:        │
                               │        │  List<MeridianSeedSlot> │
                               │        │  bonuses, effect   │
                               │        └──────────────────┘
                               ▼
┌─────────────────────────────────────────────────────┐
│                 Equipment (装备实例)                    │
│  id, baseId, quality, name                            │
│  affixes: List<Affix>   ← 词缀列表                     │
│  reinforceLevel, itemLevel                            │
│  meridianSeedId (镶嵌真气种子)                          │
│  setId (套装), uniqueId (暗金配置)                      │
└──────┬──────────────────────────┬─────────────────────┘
       │                          │
       ▼                          ▼
┌──────────────┐    ┌───────────────────────────┐
│   Affix      │    │   UniqueEquipment          │
│  (词缀)       │    │   (暗金配置)                │
│ id, name     │    │  id, name, description     │
│ position     │    │  uniqueEffects:            │
│ effects      │    │   List<UniqueEffect>       │
│ rolledValues │    │  randomAffixes:            │
└──────────────┘    │   List<AffixRange>         │
                    │  requirements              │
┌──────────────┐    └──────────┬────────────────┘
│ AffixRange   │               │
│ (词缀范围)    │               ▼
│ affixId      │    ┌───────────────────────────┐
│ ranges       │    │   UniqueEffect            │
│ .roll() →    │    │  (改机制独特词条)           │
│   Affix      │    │  id, description          │
└──────────────┘    │  type: EffectType         │
                    │  params: Map              │
                    └───────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                   HeartMantra (心法)                    │
│  id, name, effectDescription                         │
│  category: HeartMantraCategory                      │
│  params: Map (改规则参数)                              │
│  requiredWis, requiredLevel, requiredAlignment      │
│  immuneToQiDeviation (如"天人合一")                   │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                 秘境系统                                │
│                                                       │
│  RealmConfig (秘境配置)          RealmProgress (进度)    │
│  id, name, type, layers           realmId, currentLayer │
│  recommendedPower                currentDifficulty     │
│  bossDropTableId                 completedEvents       │
│  uniqueDropPool                  enemyCount, dropCount │
│  availableVariants               isAutoRun (连刷)       │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                 掉落系统                                │
│                                                       │
│  DropTable (掉落表)              PityCounter (保底)     │
│  rates: Map<Quality, double>     dropTableId            │
│  equipmentPool                   count, threshold       │
│  uniquePool                      .increment()           │
│  fortuneMultiplier               .reset()               │
│  calculateActualRates()          isPityTriggered        │
│                                                       │
│  DropRecord (掉落记录)                                 │
│  equipmentId, realmId, layer, timestamp               │
│  quality, flashLevel (掉落闪光)                         │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                 战斗系统                                │
│                                                       │
│  BattleState (运行时战斗状态)                            │
│  battleId, tier, realmId, difficulty                 │
│  currentTurn, maxTurns                               │
│  playerHealth/Max, enemyHealth/Max                   │
│  isAutoRun (连刷模式)                                   │
│  turns: List<BattleTurn>                              │
│  qiDeviation (真气逆行)                                │
│  bossPhase (Boss阶段)                                  │
│                                                       │
│  BattleTurn (回合)                                     │
│  actions: List<BattleAction>                          │
│                                                       │
│  BattleAction (动作: 出招/运功/闪避/反击)                  │
│  type, actorId, isPlayer                              │
│  damage, dodged, critical, narration                  │
│                                                       │
│  BattleResult (战斗结果)                                │
│  victory, turnsUsed, fullNarration                    │
│  bdArchetypeName (BD流派画像)                           │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                 敌人系统                                │
│                                                       │
│  Enemy (普通/精英敌人)                                   │
│  id, name, powerIndex, health                         │
│  externalAttack, internalAttack, defense             │
│  mechanics: List<EnemyMechanic>                      │
│  scaleByDifficulty()                                 │
│                                                       │
│  Boss extends Enemy                                   │
│  phases: List<BossPhase>                              │
│  getCurrentPhase(healthPct)                           │
│  scaleByDifficulty() (地狱+额外阶段)                    │
│                                                       │
│  BossPhase (Boss阶段)                                  │
│  phase, triggerCondition                              │
│  attackMultiplier, addedMechanics                     │
│                                                       │
│  EnemyMechanic (敌人机制: 免疫物理/反击/回血/多阶段)       │
│  type: MechanicType, params                           │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                 战斗描写模板                              │
│                                                       │
│  NarrationTemplate                                    │
│  tier: BattleTier (碾压/正常/Boss)                      │
│  template: "{skill}击中{enemy}"                        │
│  requiredVars: ["skill","enemy"]                      │
│  fill(vars) → 最终文本                                  │
│  isApplicable(martialType, enemyId, power)            │
│  minPower/maxPower (战力区间，DESIGN 3.10.4)            │
└─────────────────────────────────────────────────────┘
```

## BD 四维关系（DESIGN.md 3.4.1）

```
┌───────────────────────────────────────────────────────────────┐
│                    BD 流派系统 (4维)                             │
├───────────┬──────────┬──────────┬─────────────────────────────┤
│  内功      │  外功     │  装备     │  心法                        │
│  (根基)    │  (招式)   │  (词条)   │  (改规则)                    │
│           │          │          │                              │
│ MartialArt│ MartialArt│ Equipment│ HeartMantra                 │
│ type=     │ type=     │ Affixes  │ category=                   │
│  internal │  external │ Meridian │  damageConversion           │
│           │  lightness│  Seed    │  actionBonus                │
│ Element   │ Element   │          │  stackingBonus              │
│ Affinity  │ Affinity  │          │  meridianImmunity           │
│           │          │          │                              │
│ 决定基础   │ 主动行为   │ 含经脉    │ 改变规则                     │
│ 数值方向   │ 选择      │ 镶嵌子系统 │ 非数值加成                    │
│ 影响外功   │          │          │                              │
│ 兼容性    │          │          │                              │
└───────────┴──────────┴──────────┴─────────────────────────────┘
         │              │           │              │
         └──────────────┴───────────┴──────────────┘
                              │
                    真气逆行检测 (3.6)
                    ElementAffinity.conflictsWith()
                    QiDeviationLevel
```

## 真气逆行触发路径（DESIGN.md 3.6）

```
经脉相克(少阳+少阴) ──┐
内功外功冲突(阳刚内功+阴柔外功) ──┤──→ QiDeviationLevel
强制高阶(熟练度不够用高阶武功) ──┘

解除方式:
  - 回城休整 → Character.health 恢复
  - 服用定心丹 → 消耗品 (treasure 槽位)
  - 特定内功自动压制 → MartialArt + ElementAffinity
  - 心法"天人合一" → HeartMantra.immuneToQiDeviation = true

双修流:
  同时走阳+阴经脉 → 触发真气逆行但属性暴增
  需要用心法/装备/丹药压制 → BD构建选择
```

## 枚举一览（enums.dart）

| 枚举 | 用途 | 值 |
|------|------|-----|
| `Quality` | 装备品质 | normal, magic, rare, unique, divine, legendary |
| `EquipmentSlot` | 装备槽位 | weapon, armor, accessory, treasure |
| `MartialType` | 武功类型 | internal, external, lightness |
| `ProficiencyLevel` | 熟练度等级 | novice, beginner, minor, major, mastery |
| `BattleTier` | 战斗档位 | crush, normal, boss |
| `EffectType` | 暗金效果类型 | damageConvert, statBonus, ruleChange, trigger, immunity, skillUnlock, meridianRelated, conditional |
| `RealmType` | 秘境类型 | linear, open, challenge, maze |
| `Difficulty` | 秘境难度 | normal, hard, hell, inferno |
| `ElementAffinity` | 元素亲和性 | yang, yin, neutral |
| `QiDeviationLevel` | 真气逆行程度 | none, mild, moderate, severe |
| `RealmVariant` | 秘境变体 | normal, cursed, ancient |
| `BattleActionType` | 战斗动作类型 | attack, channel, dodge, counter, skill, item |
| `MechanicType` | 敌人机制类型 | immunePhysical, counterMelee, continuousHeal, multiPhase, ... |
| `AffixPosition` | 词缀位置 | prefix, suffix |
| `LeaderboardType` | 排行榜类型 | realmClear, endlessDepth, dailySeed |
| `DropFlashLevel` | 掉落闪光等级 | plain, detailed, ceremonial, legendary |
| `HeartMantraCategory` | 心法效果类别 | damageConversion, actionBonus, stackingBonus, meridianImmunity, ruleChange |
| `MeridianYinYang` | 经脉阴阳属性 | yang, yin |

## 技术约定

1. **Dart 3 enhanced enum** — 所有枚举携带元数据（显示名、掉率、数值范围等）
2. **手写 == / hashCode** — 使用 `Object.hash()` 实现值相等比较，用于 Riverpod 状态比较
3. **fromJson / toJson** — 每个类都有 JSON 序列化方法
4. **copyWith** — 可变类提供 copyWith 方法（不可变模式）
5. **中文注释** — 所有注释用中文
6. **Dart 3 switch expression** — 使用 `switch` 表达式替代 if-else 链
7. **Record 类型** — AffixRange 使用 `(int, int)` 记录类型表示范围
8. **文件顶部注释** — 标注对应 DESIGN.md 章节
