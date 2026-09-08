// =============================================================================
// providers.dart — Riverpod Provider 暴露引擎实例
//
// 对应 DESIGN.md 章节：
//   4.1 技术栈 — 状态管理: Riverpod
//
// 功能：
//   - 通过 Riverpod Provider 暴露 ConfigLoader / NarrationEngine / DropEngine / BattleEngine
//   - 支持懒加载和依赖注入
//   - 支持测试替换（override）
//
// 使用方式：
//   // 在 main.dart 中初始化:
//   runApp(ProviderScope(
//     overrides: [
//       configLoaderProvider.overrideWith(() => ...),
//     ],
//     child: MyApp(),
//   ));
//
//   // 在 Widget 中使用:
//   final battleEngine = ref.watch(battleEngineProvider);
//   final result = battleEngine.executeBattle(...);
// =============================================================================

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../utils/app_logger.dart';
import '../services/ad_service.dart';
import 'config_loader.dart';
import 'narration_engine.dart';
import 'drop_engine.dart';
import 'battle_engine.dart';

/// 随机数生成器 Provider（可override以支持确定性测试）
final randomProvider = Provider<Random>((ref) {
  return Random();
});

/// 配置加载器 Provider（懒加载，自动从assets读取）
final configLoaderProvider = FutureProvider<ConfigLoader>((ref) async {
  final loader = ConfigLoader.forTesting();
  final jsonMap = <ConfigType, String>{};

  AppLogger.instance.info('开始加载配置（共 ${ConfigType.values.length} 个文件）...');

  // 从Flutter assets中加载所有配置JSON
  for (final type in ConfigType.values) {
    try {
      final jsonStr = await rootBundle.loadString('assets/config/${type.fileName}');
      jsonMap[type] = jsonStr;
      AppLogger.instance.info('  ✅ ${type.fileName} (${type.displayName}) 加载成功 (${jsonStr.length} bytes)');
    } catch (e) {
      AppLogger.instance.error('  ❌ ${type.fileName} (${type.displayName}) 加载失败: $e');
    }
  }

  AppLogger.instance.info('配置加载完成: ${jsonMap.length}/${ConfigType.values.length} 个文件成功');
  loader.loadFromJsonMap(jsonMap);
  return loader;
});

/// 配置加载器（同步版，用于已加载后的场景）
///
/// 注意：使用前需确保 configLoaderProvider 已完成加载。
/// 在Widget中使用 ref.watch(configLoaderProvider).whenData((loader) => ...)
final configProvider = Provider<ConfigLoader?>((ref) {
  final asyncConfig = ref.watch(configLoaderProvider);
  return asyncConfig.maybeWhen(
    data: (loader) => loader,
    orElse: () => null,
  );
});

/// 描写引擎 Provider
///
/// 依赖配置加载器，需要等待配置加载完成。
final narrationEngineProvider = FutureProvider<NarrationEngine>((ref) async {
  final config = await ref.watch(configLoaderProvider.future);
  final random = ref.watch(randomProvider);
  return NarrationEngine.fromConfig(config, random: random);
});

/// 掉落引擎 Provider
final dropEngineProvider = FutureProvider<DropEngine>((ref) async {
  final config = await ref.watch(configLoaderProvider.future);
  final random = ref.watch(randomProvider);
  return DropEngine(config, random);
});

/// 战斗引擎 Provider
///
/// 依赖配置加载器、描写引擎和掉落引擎。
/// 需要等待所有依赖加载完成。
final battleEngineProvider = FutureProvider<BattleEngine>((ref) async {
  final config = await ref.watch(configLoaderProvider.future);
  final narrationEngine = await ref.watch(narrationEngineProvider.future);
  final dropEngine = await ref.watch(dropEngineProvider.future);
  final random = ref.watch(randomProvider);
  return BattleEngine(config, narrationEngine, random, dropEngine: dropEngine);
});

/// 战斗引擎同步Provider（用于已加载后的场景）
final battleEngineSyncProvider = Provider<BattleEngine?>((ref) {
  final asyncEngine = ref.watch(battleEngineProvider);
  return asyncEngine.maybeWhen(
    data: (engine) => engine,
    orElse: () => null,
  );
});

/// 引擎加载状态 Provider（供UI显示加载状态）
///
/// 返回true表示所有引擎已加载完成，false表示仍在加载。
final enginesReadyProvider = Provider<bool>((ref) {
  final configReady = ref.watch(configLoaderProvider).maybeWhen(
        data: (_) => true,
        orElse: () => false,
      );
  return configReady;
});

/// 广告服务 Provider（模块 2：广告复活）
///
/// 默认 MockAdService（3 秒模拟）；接真实 SDK 时换成对应实现。
final adServiceProvider = Provider<AdService>((ref) {
  return const MockAdService();
});

/// 测试用Provider（不依赖Flutter assets）
///
/// 用于单元测试中注入配置数据。
///
/// 使用方式:
///   testProvider.overrideWith(() => TestConfigLoader(...))
final testBattleEngineProvider = Provider<BattleEngine?>((ref) {
  return null; // 默认返回null，测试时override
});
