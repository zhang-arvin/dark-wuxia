// =============================================================================
// router.dart — go_router 路由配置
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../engine/drop_engine.dart' show DropResult;
import '../../models/session_mods.dart';

import 'theme.dart';
import 'pages/home_page.dart';
import 'pages/character_page.dart';
import 'pages/realm_select_page.dart';
import 'pages/battle_page.dart';
import 'pages/exploration_page.dart';
import 'pages/inventory_page.dart';
import 'pages/blacksmith_page.dart';
import 'pages/tavern_page.dart';
import 'pages/drop_history_page.dart';
import 'pages/odds_page.dart';
import 'pages/settings_page.dart';

/// 路由名称常量
class RouteNames {
  RouteNames._();
  static const String home = '/';
  static const String character = '/character';
  static const String realm = '/realm';
  static const String battle = '/battle';
  static const String exploration = '/exploration';
  static const String inventory = '/inventory';
  static const String blacksmith = '/blacksmith';
  static const String tavern = '/tavern';
  static const String dropHistory = '/drop-history';
  static const String odds = '/odds';
  static const String settings = '/settings';
}

/// go_router 路由配置
final GoRouter appRouter = GoRouter(
  initialLocation: RouteNames.home,
  routes: [
    GoRoute(path: RouteNames.home, builder: (c, s) => const HomePage()),
    GoRoute(path: RouteNames.character, builder: (c, s) => const CharacterPage()),
    GoRoute(path: RouteNames.realm, builder: (c, s) => const RealmSelectPage()),
    GoRoute(path: RouteNames.battle, builder: (c, s) {
      final extra = s.extra as BattleRouteExtra?;
      return BattlePage(extra: extra);
    }),
    GoRoute(path: RouteNames.exploration, builder: (c, s) {
      final extra = s.extra as ExplorationRouteExtra?;
      return ExplorationPage(extra: extra);
    }),
    GoRoute(path: RouteNames.inventory, builder: (c, s) => const InventoryPage()),
    GoRoute(path: RouteNames.blacksmith, builder: (c, s) => const BlacksmithPage()),
    GoRoute(path: RouteNames.tavern, builder: (c, s) => const TavernPage()),
    GoRoute(path: RouteNames.dropHistory, builder: (c, s) => const DropHistoryPage()),
    GoRoute(path: RouteNames.odds, builder: (c, s) => const OddsPage()),
    GoRoute(path: RouteNames.settings, builder: (c, s) => const SettingsPage()),
  ],
  errorBuilder: (c, s) => Scaffold(
    backgroundColor: DarkWuxiaColors.background,
    appBar: AppBar(title: const Text('页面不存在')),
    body: DarkWuxiaEmpty(text: '无法找到页面: ${s.uri.path}', icon: Icons.error_outline),
  ),
);

/// 战斗页面路由参数
class BattleRouteExtra {
  final String realmId;
  final int difficultyIndex;
  final bool isAutoRun;

  /// 指定本次战斗的敌人ID（探索页节点/Boss 传入）。
  /// null 时回退到「秘境 enemyPool[0] → bossId」的旧逻辑。
  final String? enemyId;

  /// 会话修正参数（模块 3：秘境模组+Buff），跨 探索→战斗 传递。
  final SessionMods? mods;

  const BattleRouteExtra({
    required this.realmId,
    this.difficultyIndex = 0,
    this.isAutoRun = false,
    this.enemyId,
    this.mods,
  });
}

/// 战斗页 pop 返回结果（探索页据此判定胜负/掉落结算）
class BattleExitResult {
  /// victory=战胜（返回掉落列表）；retreated=撤退；null=失败/直接退出
  final bool victory;

  /// 是否主动撤退
  final bool retreated;

  /// 战胜时携带的掉落（延迟结算，由调用方写库）
  final List<DropResult> drops;

  const BattleExitResult({
    required this.victory,
    this.retreated = false,
    this.drops = const [],
  });
}

/// 统一的暗黑武侠 Scaffold 包装
class DarkWuxiaScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBackButton;

  const DarkWuxiaScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkWuxiaColors.background,
      appBar: AppBar(
        title: Text(title),
        leading: showBackButton ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ) : null,
        actions: actions,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
