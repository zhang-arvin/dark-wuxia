// =============================================================================
// settings_page.dart — 设置
//
// 对应 DESIGN.md 3.10.5 设置
//   - 音效开关
//   - 战斗描写详细度(简洁/标准/详细)
//   - 连刷模式默认开关
//   - 存档导出/导入
//   - 关于页面
// =============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';
import '../router.dart';
import '../../utils/app_logger.dart';
import '../../database/database.dart';
import '../../audio/sound_manager.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _soundEnabled = true;
  int _narrationDetail = 1; // 0=简洁, 1=标准, 2=详细
  bool _autoRunDefault = false;
  String _saveDataJson = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final db = AppDatabase.instance;
      _soundEnabled = await db.settingsDao.getBool('sound_enabled');
      _narrationDetail = await db.settingsDao.getInt('narration_detail') ?? 1;
      _autoRunDefault = await db.settingsDao.getBool('auto_run_default');
    } catch (_) {}
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    try {
    return DarkWuxiaScaffold(
      title: '设置',
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildSection('游戏偏好', [
            _buildSwitchTile(
              '音效',
              '战斗音效与界面提示音',
              Icons.volume_up,
              _soundEnabled,
              (v) async {
                setState(() => _soundEnabled = v);
                await AppDatabase.instance.settingsDao.setBool('sound_enabled', v);
                SoundManager.instance.setEnabled(v);
              },
            ),
            _buildSegmentTile(
              '战斗描写详细度',
              '控制战斗描写的文字量和风格',
              Icons.article,
              _narrationDetail,
              (v) async {
                setState(() => _narrationDetail = v);
                await AppDatabase.instance.settingsDao.setInt('narration_detail', v);
              },
            ),
            _buildSwitchTile(
              '连刷模式（默认）',
              '进入秘境时默认开启连刷模式',
              Icons.repeat,
              _autoRunDefault,
              (v) async {
                setState(() => _autoRunDefault = v);
                await AppDatabase.instance.settingsDao.setBool('auto_run_default', v);
              },
            ),
          ]),
          const SizedBox(height: 12),
          _buildSection('存档管理', [
            _buildActionTile(
              '导出存档',
              '将当前存档导出为 JSON 文件',
              Icons.file_download,
              _exportSave,
            ),
            _buildActionTile(
              '导入存档',
              '从 JSON 文件恢复存档',
              Icons.file_upload,
              _importSave,
            ),
            _buildActionTile(
              '清除存档',
              '删除所有角色与装备数据（不可恢复）',
              Icons.delete_forever,
              _clearSave,
              isDanger: true,
            ),
          ]),
          const SizedBox(height: 12),
          _buildSection('关于', [
            _buildInfoTile('游戏名称', '暗黑武侠'),
            _buildInfoTile('版本', '1.0.0'),
            _buildInfoTile('引擎', 'Flutter + Drift'),
            _buildActionTile(
              '关于本作',
              '查看设计与制作说明',
              Icons.info_outline,
              _showAbout,
            ),
            _buildActionTile(
              '查看日志',
              '查看应用运行日志，排查问题',
              Icons.bug_report,
              _showLogs,
            ),
          ]),
        ],
      ),
    );
    } catch (e, stack) {
      AppLogger.instance.error('SettingsPage.build 崩溃: $e\n$stack');
      return const DarkWuxiaScaffold(
        title: '设置',
        body: DarkWuxiaEmpty(text: '页面加载出错，请查看日志', icon: Icons.error_outline),
      );
    }
  }

  // --- 区块容器 ---
  Widget _buildSection(String title, List<Widget> children) {
    return DarkWuxiaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: DarkWuxiaColors.darkGold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  // --- 开关项 ---
  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: value ? DarkWuxiaColors.darkGold : DarkWuxiaColors.textSecondary, size: 24),
      title: Text(title, style: const TextStyle(fontFamily: 'serif', fontSize: 14, color: DarkWuxiaColors.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.textSecondary)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: DarkWuxiaColors.darkGold,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  // --- 分段选择项 ---
  Widget _buildSegmentTile(
    String title,
    String subtitle,
    IconData icon,
    int value,
    ValueChanged<int> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: DarkWuxiaColors.darkGold, size: 24),
      title: Text(title, style: const TextStyle(fontFamily: 'serif', fontSize: 14, color: DarkWuxiaColors.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.textSecondary)),
      trailing: ToggleButtons(
        isSelected: [value == 0, value == 1, value == 2],
        onPressed: (index) => onChanged(index),
        borderColor: DarkWuxiaColors.divider,
        selectedColor: DarkWuxiaColors.darkGold,
        fillColor: DarkWuxiaColors.darkGold.withValues(alpha: 0.1),
        children: const [
          Text('简洁', style: TextStyle(fontFamily: 'serif', fontSize: 11)),
          Text('标准', style: TextStyle(fontFamily: 'serif', fontSize: 11)),
          Text('详细', style: TextStyle(fontFamily: 'serif', fontSize: 11)),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  // --- 操作项 ---
  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDanger = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDanger ? DarkWuxiaColors.darkRedBright : DarkWuxiaColors.darkGold, size: 24),
      title: Text(
        title,
        style: TextStyle(fontFamily: 'serif', fontSize: 14, color: isDanger ? DarkWuxiaColors.darkRedBright : DarkWuxiaColors.textPrimary),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right, color: DarkWuxiaColors.textHint, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  // --- 信息项 ---
  Widget _buildInfoTile(String label, String value) {
    return ListTile(
      leading: const Icon(Icons.fiber_manual_record, color: DarkWuxiaColors.textHint, size: 12),
      title: Text(label, style: const TextStyle(fontFamily: 'serif', fontSize: 14, color: DarkWuxiaColors.textSecondary)),
      trailing: Text(value, style: const TextStyle(fontFamily: 'serif', fontSize: 14, fontWeight: FontWeight.bold, color: DarkWuxiaColors.darkGold)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  // --- 存档操作 ---

  Future<void> _exportSave() async {
    try {
      final db = AppDatabase.instance;
      final data = await db.exportAll();

      final json = const JsonEncoder.withIndent('  ').convert(data);
      _saveDataJson = json;

      // 复制到剪贴板（简化处理，实际可用 file_picker 保存到文件）
      await Clipboard.setData(ClipboardData(text: json));

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('存档已导出'),
            content: const Text('存档数据已复制到剪贴板。\n请粘贴到文本编辑器保存。'),
            actions: [
              ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('确定')),
            ],
          ),
        );
      }
    } catch (e) {
      _showError('导出失败: $e');
    }
  }

  Future<void> _importSave() async {
    // 简化版：从剪贴板读取
    final clip = await Clipboard.getData('text');
    final json = clip?.text;
    if (json == null || json.isEmpty) {
      _showError('剪贴板为空');
      return;
    }

    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final db = AppDatabase.instance;
      await db.importAll(data);
      _showSuccess('存档已导入');
      _loadSettings();
    } catch (e) {
      _showError('导入失败: $e');
    }
  }

  Future<void> _clearSave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清除存档？'),
        content: const Text('此操作将删除所有角色、装备、掉落记录。\n此操作不可恢复！'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: DarkWuxiaColors.darkRed),
            child: const Text('确认清除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final db = AppDatabase.instance;
        await db.clearAll();
        _showSuccess('存档已清除');
        _loadSettings();
      } catch (e) {
        _showError('清除失败: $e');
      }
    }
  }

  void _showLogs() {
    final logs = AppLogger.instance.getLogs();
    final displayText = logs.isEmpty ? '（暂无日志）' : logs;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.bug_report, color: DarkWuxiaColors.darkGold, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('运行日志', style: TextStyle(fontSize: 16)),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 18, color: DarkWuxiaColors.darkGold),
              tooltip: '复制日志',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: displayText));
                Navigator.pop(ctx);
                _showSuccess('日志已复制到剪贴板');
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: DarkWuxiaColors.darkRed),
              tooltip: '清除日志',
              onPressed: () {
                AppLogger.instance.clear();
                Navigator.pop(ctx);
                _showSuccess('日志已清除');
              },
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.5,
          child: SingleChildScrollView(
            child: SelectableText(
              displayText,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('关于暗黑武侠'),
        content: const SingleChildScrollView(
          child: Text(
            '暗黑武侠\n\n'
            '一款暗黑破坏神2风格 + 武侠题材的文字刷装备游戏。\n\n'
            '特点:\n'
            '· 六级品质装备系统(凡/良/上/暗金/神品/传说)\n'
            '· 30穴经脉 + 武功熟练度 + 心法BD\n'
            '· 五大秘境 + 四档难度\n'
            '· 碾压连刷 + 正常回合 + Boss展开式三档战斗\n'
            '· 四级掉落闪光动画\n'
            '· 完整概率公示\n\n'
            '技术栈: Flutter + Riverpod + Drift + go_router\n\n'
            '© 2024 暗黑武侠',
            style: TextStyle(fontFamily: 'serif', fontSize: 13, height: 1.6),
          ),
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: DarkWuxiaColors.buffGreen),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: DarkWuxiaColors.darkRed),
    );
  }
}
