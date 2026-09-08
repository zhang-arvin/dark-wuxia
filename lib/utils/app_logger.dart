// =============================================================================
// app_logger.dart — 全局日志管理器
//
// 功能：
//   - 单例模式，全局收集日志
//   - 支持 info/warn/error 三个级别
//   - 缓冲区 StringBuffer，可查看/复制/清除
//
// 使用方式：
//   AppLogger.instance.info('开始加载配置...');
//   AppLogger.instance.error('加载失败: $e');
//   final logs = AppLogger.instance.getLogs();
//   AppLogger.instance.clear();
// =============================================================================

/// 全局日志管理器（单例）
class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  final StringBuffer _buffer = StringBuffer();

  /// 记录信息日志
  void info(String msg) {
    _buffer.writeln('[${_now()}] [INFO] $msg');
  }

  /// 记录警告日志
  void warn(String msg) {
    _buffer.writeln('[${_now()}] [WARN] $msg');
  }

  /// 记录错误日志
  void error(String msg) {
    _buffer.writeln('[${_now()}] [ERROR] $msg');
  }

  /// 获取所有日志内容
  String getLogs() => _buffer.toString();

  /// 清空日志缓冲区
  void clear() => _buffer.clear();

  /// 格式化当前时间
  String _now() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}