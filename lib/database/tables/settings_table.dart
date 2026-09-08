import 'package:drift/drift.dart';

/// 设置表 — KV 存储 (游戏设置 + 会话缓存)
///
/// 设计要点:
/// - key-value 结构，灵活存储各种设置
/// - 用于: 音效开关、文字速度、连刷模式、保底计数器等
/// - 补充 shared_preferences 的结构化需求
class SettingsTable extends Table {
  /// 设置键名
  TextColumn get key => text()();

  /// 设置值 (JSON 字符串，支持任意类型)
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
