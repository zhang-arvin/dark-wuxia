import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart' show NativeDatabase;
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'daos/character_dao.dart';
import 'daos/drop_dao.dart';
import 'daos/equipment_dao.dart';
import 'daos/realm_dao.dart';
import 'daos/run_history_dao.dart';
import 'daos/meridian_dao.dart';
import 'daos/settings_dao.dart';
import 'tables/character_table.dart';
import 'tables/drop_history_table.dart';
import 'tables/equipment_table.dart';
import 'tables/meridian_state_table.dart';
import 'tables/realm_progress_table.dart';
import 'tables/run_history_table.dart';
import 'tables/settings_table.dart';

part 'database.g.dart';

/// 暗黑武侠 — SQLite 数据库 (drift)
///
/// 架构设计 (DESIGN.md 4.2):
/// - SQLite (结构化大数据): equipment, run_history, drop_history, realm_progress, settings
/// - shared_preferences (快速KV): player_state, settings, session_cache
/// - 文件系统: 存档截图/分享图, 图片缓存
/// - 背包软上限: 500件
///
/// 数据库版本管理:
/// - v1: 初始版本 (所有表)
/// - 后续迁移: 使用 MigrationStrategy
@DriftDatabase(
  tables: [
    EquipmentTable,
    CharacterTable,
    MeridianStateTable,
    RealmProgressTable,
    DropHistoryTable,
    RunHistoryTable,
    SettingsTable,
  ],
  daos: [
    EquipmentDao,
    CharacterDao,
    MeridianDao,
    RealmDao,
    DropDao,
    RunDao,
    SettingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._(QueryExecutor executor) : super(executor);

  /// 单例实例
  static AppDatabase? _instance;

  /// 获取单例 (懒加载)
  ///
  /// 数据库文件存放在应用文档目录: dark_wuxia_save.db
  static AppDatabase get instance {
    _instance ??= AppDatabase._(_openConnection());
    return _instance!;
  }

  /// 打开数据库连接
  ///
  /// 使用 LazyDatabase + path_provider 异步获取路径
  /// 数据库文件: dark_wuxia_save.db
  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      // 确保 sqlite3 在旧版 Android 上正确加载
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();

      // 获取应用文档目录
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'dark_wuxia_save.db'));

      // 使用 drift_flutter 的 NativeDatabase
      return NativeDatabase(file, logStatements: false);
    });
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      // 数据库创建时执行 (首次安装)
      onCreate: (m) async {
        await m.createAll();
      },
      // 数据库升级时执行
      onUpgrade: (m, from, to) async {
        // 版本迁移策略 (按序执行)
        for (var i = from; i < to; i++) {
          switch (i) {
            case 0:
              // v0 → v1: 初始建表 (onCreate 已处理)
              break;
            case 1:
              // v1 → v2: 新增经脉状态表
              await m.createTable(meridianStateTable);
              break;
            default:
              break;
          }
        }
      },
      // 数据库打开前执行 (每次启动)
      beforeOpen: (details) async {
        // 启用外键约束
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// 关闭数据库连接
  @override
  Future<void> close() async {
    await executor.close();
    _instance = null;
  }

  /// 重置数据库 (清空所有数据，重新建表)
  ///
  /// 仅用于调试/开发环境
  Future<void> reset() async {
    // 简单实现：关闭数据库再删除文件
    await close();
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'dark_wuxia.db'));
    if (file.existsSync()) {
      await file.delete();
    }
    // 重新打开
    _instance = AppDatabase._(_openConnection());
  }

  /// 导出所有存档数据 (用于存档备份)
  Future<Map<String, dynamic>> exportAll() async {
    final equipment = await equipmentDao.getEquipmentsByPage(page: 0);
    final character = await characterDao.getCharacter();
    final drops = await dropDao.getDropsByPage();
    final realms = await realmDao.getAllProgress();
    final settings = await settingsDao.getAll();

    return {
      'character': character?.toJson(),
      'equipment': equipment.map((e) => e.toJson()).toList(),
      'drops': drops.map((d) => d.toJson()).toList(),
      'realms': realms.map((r) => r.toJson()).toList(),
      'settings': settings,
      'exportTime': DateTime.now().toIso8601String(),
    };
  }

  /// 导入存档数据 (用于存档恢复)
  Future<void> importAll(Map<String, dynamic> data) async {
    // 清空当前数据
    await reset();

    // 导入角色
    if (data['character'] != null) {
      final charData = data['character'] as Map<String, dynamic>;
      await characterDao.createCharacter(
        name: charData['name'] as String? ?? '主角',
        origin: charData['origin'] as String? ?? '',
        attributes: <String, int>{},
      );
    }

    // 导入设置
    if (data['settings'] != null) {
      final settings = data['settings'] as Map<String, dynamic>;
      for (final entry in settings.entries) {
        await settingsDao.setString(entry.key, entry.value.toString());
      }
    }
  }

  /// 清除所有存档数据
  Future<void> clearAll() async {
    await reset();
  }
}
