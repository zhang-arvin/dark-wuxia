// =============================================================================
// sound_manager.dart — 音效管理器 (单例)
//
// 功能:
//   - BGM 播放: 循环播放背景音乐 (城镇 / 战斗 / Boss)
//   - SFX 播放: 攻击 / 受击 / 暴击 / 掉落 / 装备 / 升级 / 点击 / 翻页 / 撤退
//   - 音量控制: BGM 音量 + SFX 音量 (0.0–1.0)
//   - 音效开关: 全局开关 (从 settingsDao 读取 sound_enabled)
//   - 预加载: init() 在 app 启动时调用
//
// 依赖: audioplayers ^5.2.0
// 音效文件规范见 assets/sounds/README.md
// =============================================================================

import 'package:audioplayers/audioplayers.dart';

import '../database/database.dart';

// -----------------------------------------------------------------------------
// 枚举
// -----------------------------------------------------------------------------

/// BGM 类型
enum BgmType {
  town, // 城镇背景音乐
  battle, // 战斗背景音乐
  boss, // Boss 战背景音乐
}

/// SFX 类型
enum SfxType {
  attack, // 攻击
  hit, // 受击
  crit, // 暴击
  drop, // 掉落
  equip, // 装备
  upgrade, // 升级
  click, // 点击
  page, // 翻页
  retreat, // 撤退
}

// -----------------------------------------------------------------------------
// SoundManager 单例
// -----------------------------------------------------------------------------

class SoundManager {
  static final SoundManager instance = SoundManager._();
  SoundManager._();

  // 音频播放器
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  // 状态
  bool _enabled = true;
  double _bgmVolume = 0.5;
  double _sfxVolume = 0.7;
  BgmType? _currentBgm;
  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // 初始化 & 预加载
  // ---------------------------------------------------------------------------

  /// 在 app 启动时调用，预加载音效配置并从数据库恢复设置。
  ///
  /// 音效文件尚未就位时不会报错，播放时静默跳过即可。
  Future<void> init() async {
    if (_initialized) return;

    // 从数据库读取音效开关和音量
    try {
      final dao = AppDatabase.instance.settingsDao;
      _enabled = await dao.getBool('sound_enabled', defaultValue: true);
      _bgmVolume = await dao.getDouble('bgm_volume', defaultValue: 0.5);
      _sfxVolume = await dao.getDouble('sfx_volume', defaultValue: 0.7);
    } catch (_) {
      // 数据库未就绪时使用默认值
    }

    // 设置播放器模式
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setPlayerMode(PlayerMode.mediaPlayer);

    // 应用音量
    await _bgmPlayer.setVolume(_enabled ? _bgmVolume : 0.0);
    await _sfxPlayer.setVolume(_enabled ? _sfxVolume : 0.0);

    _initialized = true;
  }

  // ---------------------------------------------------------------------------
  // BGM 播放
  // ---------------------------------------------------------------------------

  /// 播放背景音乐（循环）。若当前已在播放相同 BGM 则不重复切换。
  Future<void> playBgm(BgmType type) async {
    if (!_initialized) return;
    if (_currentBgm == type) return; // 相同 BGM 不切换

    final assetPath = _bgmAssetPath(type);
    if (assetPath == null) return;

    _currentBgm = type;
    try {
      await _bgmPlayer.stop();
      await _bgmPlayer.setSource(AssetSource(assetPath));
      await _bgmPlayer.setVolume(_enabled ? _bgmVolume : 0.0);
      await _bgmPlayer.resume();
    } catch (_) {
      // 音效文件缺失时静默忽略
      _currentBgm = null;
    }
  }

  /// 停止背景音乐。
  void stopBgm() {
    _currentBgm = null;
    _bgmPlayer.stop();
  }

  // ---------------------------------------------------------------------------
  // SFX 播放
  // ---------------------------------------------------------------------------

  /// 播放一次性音效。
  Future<void> playSfx(SfxType type) async {
    if (!_initialized) return;
    if (!_enabled) return;

    final assetPath = _sfxAssetPath(type);
    if (assetPath == null) return;

    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setSource(AssetSource(assetPath));
      await _sfxPlayer.setVolume(_sfxVolume);
      await _sfxPlayer.resume();
    } catch (_) {
      // 音效文件缺失时静默忽略
    }
  }

  // ---------------------------------------------------------------------------
  // 设置
  // ---------------------------------------------------------------------------

  /// 设置全局音效开关（由设置页面调用）。
  ///
  /// 关闭时停止 BGM 并静音 SFX；开启时恢复 BGM（如有）并恢复音量。
  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) {
      // 停止所有播放
      _bgmPlayer.setVolume(0.0);
      _sfxPlayer.setVolume(0.0);
      stopBgm();
    } else {
      // 恢复音量
      _bgmPlayer.setVolume(_bgmVolume);
      _sfxPlayer.setVolume(_sfxVolume);
    }
  }

  /// 设置 BGM 音量 (0.0–1.0)。
  void setBgmVolume(double vol) {
    _bgmVolume = vol.clamp(0.0, 1.0);
    if (_enabled) {
      _bgmPlayer.setVolume(_bgmVolume);
    }
  }

  /// 设置 SFX 音量 (0.0–1.0)。
  void setSfxVolume(double vol) {
    _sfxVolume = vol.clamp(0.0, 1.0);
    if (_enabled) {
      _sfxPlayer.setVolume(_sfxVolume);
    }
  }

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  bool get enabled => _enabled;
  double get bgmVolume => _bgmVolume;
  double get sfxVolume => _sfxVolume;
  BgmType? get currentBgm => _currentBgm;

  // ---------------------------------------------------------------------------
  // 资源路径映射
  // ---------------------------------------------------------------------------

  String? _bgmAssetPath(BgmType type) {
    switch (type) {
      case BgmType.town:
        return 'sounds/bgm_town.mp3';
      case BgmType.battle:
        return 'sounds/bgm_battle.mp3';
      case BgmType.boss:
        return 'sounds/bgm_boss.mp3';
    }
  }

  String? _sfxAssetPath(SfxType type) {
    switch (type) {
      case SfxType.attack:
        return 'sounds/sfx_attack.mp3';
      case SfxType.hit:
        return 'sounds/sfx_hit.mp3';
      case SfxType.crit:
        return 'sounds/sfx_crit.mp3';
      case SfxType.drop:
        return 'sounds/sfx_drop.mp3';
      case SfxType.equip:
        return 'sounds/sfx_equip.mp3';
      case SfxType.upgrade:
        return 'sounds/sfx_upgrade.mp3';
      case SfxType.click:
        return 'sounds/sfx_click.mp3';
      case SfxType.page:
        return 'sounds/sfx_page.mp3';
      case SfxType.retreat:
        return 'sounds/sfx_retreat.mp3';
    }
  }
}
