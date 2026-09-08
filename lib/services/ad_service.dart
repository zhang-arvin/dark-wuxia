// =============================================================================
// ad_service.dart — 广告服务抽象（模块 2：广告复活）
//
// 设计原则：
//   - 业务代码只依赖 AdService 抽象，不感知具体 SDK
//   - 默认 MockAdService：3 秒倒计时模拟「看完激励视频」
//   - 将来接穿山甲/优量汇/AdMob：实现同名接口，业务零改动
//
// 产品规则（复活）：
//   - 每日最多 [MAX_DAILY_REVIVES] 次（settingsDao 存当日计数）
//   - 看广告成功 → 返回 true，调用方消耗一次复活并保留收益
// =============================================================================

import '../database/database.dart';
import '../utils/app_logger.dart';

/// 每日复活次数上限
const int MAX_DAILY_REVIVES = 3;

/// 广告服务接口
abstract class AdService {
  /// 展示激励视频。
  /// 返回 true = 用户完整看完（可获复活）；false = 失败/中途关闭。
  Future<bool> showRewardedAd();

  /// 今日本日剩余复活次数
  Future<int> dailyRevivesLeft();

  /// 消耗一次复活机会（返回消耗后剩余次数）
  Future<int> consumeRevive();
}

/// Mock 实现：3 秒倒计时模拟（SDK 集成就绪前的占位）
///
/// 逻辑与真实 SDK 对齐：倒计时对应「观看」阶段，超时/取消=失败返回 false。
class MockAdService implements AdService {
  const MockAdService();

  /// 本日复活计数在 settingsDao 的 key
  static const _reviveKey = 'ad_revive_used_today';
  static const _reviveDateKey = 'ad_revive_used_date';

  @override
  Future<bool> showRewardedAd() async {
    // 模拟观看：3 秒后视为完整观看
    // （真实 SDK 会阻塞到用户关闭广告页；Mock 用延迟等价）
    await Future.delayed(const Duration(seconds: 3));
    AppLogger.instance.info('[MockAdService] 倒计时结束，模拟完整观看成功');
    return true;
  }

  @override
  Future<int> dailyRevivesLeft() async {
    final db = AppDatabase.instance;
    final usedToday = await _usedToday(db);
    return (MAX_DAILY_REVIVES - usedToday).clamp(0, MAX_DAILY_REVIVES);
  }

  @override
  Future<int> consumeRevive() async {
    final db = AppDatabase.instance;
    final today = _todayKey();
    final usedToday = await _usedToday(db);
    final newCount = usedToday + 1;
    await db.settingsDao.setString(_reviveDateKey, today);
    await db.settingsDao.setInt(_reviveKey, newCount);
    return (MAX_DAILY_REVIVES - newCount).clamp(0, MAX_DAILY_REVIVES);
  }

  /// 读取当日已用次数（跨天自动归零）
  Future<int> _usedToday(AppDatabase db) async {
    final date = await db.settingsDao.getString(_reviveDateKey);
    if (date != _todayKey()) return 0;
    return db.settingsDao.getInt(_reviveKey);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}