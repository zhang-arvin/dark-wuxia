// =============================================================================
// app.dart — App 入口
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class DarkWuxiaApp extends StatelessWidget {
  const DarkWuxiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '暗黑武侠',
      debugShowCheckedModeBanner: false,
      theme: DarkWuxiaTheme.theme,
      routerConfig: appRouter,
    );
  }
}
