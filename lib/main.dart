import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/app.dart';
import 'utils/app_logger.dart';

void main() {
  // 全局 Flutter 错误捕获 — 输出到 AppLogger 避免静默崩溃
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger.instance.error('FlutterError: ${details.exception}');
    if (details.stack != null) {
      AppLogger.instance.error('Stack: ${details.stack}');
    }
  };

  runApp(const ProviderScope(child: DarkWuxiaApp()));
}