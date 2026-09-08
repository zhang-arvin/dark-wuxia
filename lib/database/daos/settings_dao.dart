import 'dart:convert';

import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/settings_table.dart';

part 'settings_dao.g.dart';

/// 设置 DAO — 设置表(KV存储)的数据访问层
///
/// 功能:
/// - KV 设置读写
/// - 支持 int / double / bool / String / JSON 类型
/// - 补充 shared_preferences 的结构化需求
@DriftAccessor(tables: [SettingsTable])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// 获取设置值 (字符串)
  ///
  /// [key] 设置键
  /// [defaultValue] 默认值 (键不存在时返回)
  Future<String> getString(String key, {String defaultValue = ''}) async {
    final query = select(db.settingsTable)
      ..where((t) => t.key.equals(key));
    final result = await query.getSingleOrNull();
    return result?.value ?? defaultValue;
  }

  /// 设置字符串值
  Future<void> setString(String key, String value) async {
    await into(db.settingsTable).insertOnConflictUpdate(
      SettingsTableCompanion.insert(key: key, value: value),
    );
  }

  /// 获取 int 值
  Future<int> getInt(String key, {int defaultValue = 0}) async {
    final value = await getString(key, defaultValue: defaultValue.toString());
    return int.tryParse(value) ?? defaultValue;
  }

  /// 设置 int 值
  Future<void> setInt(String key, int value) async {
    await setString(key, value.toString());
  }

  /// 获取 double 值
  Future<double> getDouble(String key, {double defaultValue = 0.0}) async {
    final value =
        await getString(key, defaultValue: defaultValue.toString());
    return double.tryParse(value) ?? defaultValue;
  }

  /// 设置 double 值
  Future<void> setDouble(String key, double value) async {
    await setString(key, value.toString());
  }

  /// 获取 bool 值
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final value =
        await getString(key, defaultValue: defaultValue.toString());
    return value.toLowerCase() == 'true';
  }

  /// 设置 bool 值
  Future<void> setBool(String key, bool value) async {
    await setString(key, value.toString());
  }

  /// 获取 JSON 值 (Map)
  Future<Map<String, dynamic>> getJson(String key,
      {Map<String, dynamic>? defaultValue}) async {
    final value = await getString(key);
    if (value.isEmpty) return defaultValue ?? {};
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return defaultValue ?? {};
    } catch (_) {
      return defaultValue ?? {};
    }
  }

  /// 设置 JSON 值
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    await setString(key, jsonEncode(value));
  }

  /// 删除设置项
  Future<int> deleteKey(String key) {
    return (delete(db.settingsTable)..where((t) => t.key.equals(key))).go();
  }

  /// 获取所有设置项
  Future<Map<String, String>> getAll() async {
    final rows = await select(db.settingsTable).get();
    return Map.fromEntries(rows.map((r) => MapEntry(r.key, r.value)));
  }

  /// 清空所有设置
  Future<int> clearAll() {
    return delete(db.settingsTable).go();
  }
}
