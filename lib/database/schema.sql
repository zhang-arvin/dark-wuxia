-- ============================================================
-- 暗黑武侠 — SQLite 存档架构 Schema
-- 参考: DESIGN.md 4.2 存档架构
-- 实际使用: drift 包自动建表，本文件仅供参考/迁移/调试
-- ============================================================

PRAGMA foreign_keys = ON;

-- ============================================================
-- 1. 装备表 (equipment_table)
-- 存储所有掉落/获得的装备
-- 分页查询每次50条，背包软上限500件
-- ============================================================
CREATE TABLE IF NOT EXISTS equipment_table (
  id                TEXT PRIMARY KEY NOT NULL,           -- 装备唯一 ID (UUID)
  base_id           TEXT NOT NULL,                       -- 基础装备 ID (指向 JSON 配置)
  quality           TEXT NOT NULL,                       -- 品质: normal/magic/rare/unique/divine/legendary
  slot              TEXT NOT NULL DEFAULT 'weapon',      -- 槽位: weapon/armor/accessory/treasure
  name              TEXT NOT NULL,                       -- 生成名 (含词缀前缀后缀)
  affixes_json      TEXT NOT NULL DEFAULT '[]',          -- 词缀列表 JSON 字符串
  reinforce_level   INTEGER NOT NULL DEFAULT 0,          -- 强化等级 (0-15)
  meridian_seed_id  TEXT,                                 -- 镶嵌的真气种子 ID (可空)
  item_level        INTEGER NOT NULL,                    -- 物品等级 (影响词缀范围)
  created_at        INTEGER NOT NULL DEFAULT (strftime('%s', 'now')) -- 创建时间戳
);

-- 按品质查询索引
CREATE INDEX IF NOT EXISTS idx_equipment_quality ON equipment_table(quality);

-- 按槽位查询索引
CREATE INDEX IF NOT EXISTS idx_equipment_slot ON equipment_table(slot);

-- 按创建时间排序索引 (分页查询用)
CREATE INDEX IF NOT EXISTS idx_equipment_created ON equipment_table(created_at DESC);

-- ============================================================
-- 2. 角色状态表 (character_table)
-- 单角色存档 (始终只有一行 id=1)
-- ============================================================
CREATE TABLE IF NOT EXISTS character_table (
  id                INTEGER PRIMARY KEY NOT NULL DEFAULT 1,  -- 主键固定为1 (单角色)
  name              TEXT NOT NULL,                           -- 角色名
  origin            TEXT NOT NULL DEFAULT '',               -- 出身
  level             INTEGER NOT NULL DEFAULT 1,             -- 等级
  attributes_json   TEXT NOT NULL DEFAULT '{}',             -- 五维属性 JSON: {"body":10,"agi":8,"wis":12,"con":10,"luck":5}
  age               INTEGER NOT NULL DEFAULT 16,            -- 年龄
  health            INTEGER NOT NULL DEFAULT 100,           -- 当前生命值
  inner_energy      INTEGER NOT NULL DEFAULT 50,            -- 当前内力值
  fortune           INTEGER NOT NULL DEFAULT 0,            -- 福缘 (掉率加成)
  reputation        INTEGER NOT NULL DEFAULT 0,            -- 名望
  alignment         INTEGER NOT NULL DEFAULT 0,            -- 正邪值 -100~100
  power_index       INTEGER NOT NULL DEFAULT 0,            -- 战力指数 (综合评分)
  martial_arts_json TEXT NOT NULL DEFAULT '[]',            -- 武功列表 JSON
  meridians_json    TEXT NOT NULL DEFAULT '[]',             -- 经脉状态 JSON (6脉30穴)
  heart_mantra      TEXT,                                   -- 心法 ID (可空)
  updated_at        INTEGER NOT NULL DEFAULT (strftime('%s', 'now')) -- 最后更新时间
);

-- ============================================================
-- 3. 秘境进度表 (realm_progress_table)
-- 记录每个秘境的当前推进状态
-- 同步策略: Last-Write-Wins + 版本号
-- ============================================================
CREATE TABLE IF NOT EXISTS realm_progress_table (
  realm_id               TEXT PRIMARY KEY NOT NULL,      -- 秘境 ID
  current_layer          INTEGER NOT NULL DEFAULT 0,      -- 当前层数
  current_difficulty     INTEGER NOT NULL DEFAULT 0,      -- 当前难度 (0=普通 1=困难 2=地狱 3=炼狱)
  completed_events_json TEXT NOT NULL DEFAULT '[]',       -- 已完成事件 ID 列表 JSON
  enemy_count            INTEGER NOT NULL DEFAULT 0,      -- 击杀敌人数
  drop_count             INTEGER NOT NULL DEFAULT 0,      -- 掉落物品数
  version                INTEGER NOT NULL DEFAULT 0,      -- 版本号 (用于 Last-Write-Wins 同步)
  updated_at             INTEGER NOT NULL DEFAULT (strftime('%s', 'now')) -- 最后更新时间
);

-- ============================================================
-- 4. 掉落记录表 (drop_history_table)
-- 记录每次装备掉落，用于统计分析和保底计数
-- ============================================================
CREATE TABLE IF NOT EXISTS drop_history_table (
  id             INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,  -- 自增主键
  equipment_id   TEXT NOT NULL,                              -- 关联装备 ID
  realm_id       TEXT NOT NULL,                              -- 秘境 ID
  layer          INTEGER NOT NULL,                           -- 层数
  quality        TEXT NOT NULL,                              -- 品质
  timestamp      INTEGER NOT NULL DEFAULT (strftime('%s', 'now')) -- 掉落时间戳
);

-- 按秘境查询索引
CREATE INDEX IF NOT EXISTS idx_drop_realm ON drop_history_table(realm_id);

-- 按品质查询索引
CREATE INDEX IF NOT EXISTS idx_drop_quality ON drop_history_table(quality);

-- 按时间排序索引
CREATE INDEX IF NOT EXISTS idx_drop_timestamp ON drop_history_table(timestamp DESC);

-- ============================================================
-- 5. 秘境通关记录表 (run_history_table)
-- 记录每次秘境通关详情，用于排行榜
-- ============================================================
CREATE TABLE IF NOT EXISTS run_history_table (
  id            INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,  -- 自增主键
  realm_id      TEXT NOT NULL,                               -- 秘境 ID
  difficulty    INTEGER NOT NULL,                            -- 通关难度
  total_rounds  INTEGER NOT NULL,                            -- 总回合数
  result        TEXT NOT NULL,                               -- 通关结果: victory/defeat/retreat
  bd_snapshot   TEXT NOT NULL DEFAULT '{}',                  -- BD 快照 JSON (用于排行榜流派展示)
  timestamp     INTEGER NOT NULL DEFAULT (strftime('%s', 'now')) -- 通关时间戳
);

-- 按秘境+难度查询索引 (排行榜用)
CREATE INDEX IF NOT EXISTS idx_run_realm_diff ON run_history_table(realm_id, difficulty);

-- 按时间排序索引
CREATE INDEX IF NOT EXISTS idx_run_timestamp ON run_history_table(timestamp DESC);

-- ============================================================
-- 6. 设置表 (settings_table)
-- KV 存储 (游戏设置 + 会话缓存)
-- ============================================================
CREATE TABLE IF NOT EXISTS settings_table (
  key   TEXT PRIMARY KEY NOT NULL,    -- 设置键名
  value TEXT NOT NULL                 -- 设置值 (JSON 字符串，支持任意类型)
);

-- ============================================================
-- 视图: 装备品质统计
-- 用于概率公示页和背包管理
-- ============================================================
CREATE VIEW IF NOT EXISTS v_quality_stats AS
SELECT
  quality,
  COUNT(*) as count
FROM equipment_table
GROUP BY quality;

-- ============================================================
-- 视图: 槽位统计
-- ============================================================
CREATE VIEW IF NOT EXISTS v_slot_stats AS
SELECT
  slot,
  COUNT(*) as count
FROM equipment_table
GROUP BY slot;

-- ============================================================
-- 视图: 掉率统计
-- 用于概率公示页
-- ============================================================
CREATE VIEW IF NOT EXISTS v_drop_rate_stats AS
SELECT
  quality,
  COUNT(*) as drop_count,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM drop_history_table), 2) as drop_rate_percent
FROM drop_history_table
GROUP BY quality;

-- ============================================================
-- 视图: 秘境通关排行
-- ============================================================
CREATE VIEW IF NOT EXISTS v_leaderboard AS
SELECT
  realm_id,
  difficulty,
  MIN(total_rounds) as best_rounds,
  COUNT(*) as run_count
FROM run_history_table
WHERE result = 'victory'
GROUP BY realm_id, difficulty;
