// =============================================================================
// theme.dart — 暗黑武侠全局主题
//
// 功能：
//   - 暗黑武侠风格色板：黑底(#0a0a0a) + 暗红(#8b0000) + 暗金(#c5a059)
//   - 品质颜色映射：Quality枚举 → Color
//   - 武侠字体感：使用 serif 字体族
//   - 通用组件样式：按钮/卡片/列表/弹窗的暗黑风格
// =============================================================================

import 'package:flutter/material.dart';

import '../models/enums.dart';

// =============================================================================
// 颜色常量
// =============================================================================

/// 暗黑武侠色板
class DarkWuxiaColors {
  DarkWuxiaColors._();

  /// 主背景 — 黑底
  static const Color background = Color(0xFF0A0A0A);

  /// 次背景 — 略亮的黑色（卡片/面板）
  static const Color surface = Color(0xFF1A1A1A);

  /// 三级背景 — 弹窗/对话框
  static const Color elevated = Color(0xFF2A2A2A);

  /// 暗红 — 强调色（危险/血量/标题）
  static const Color darkRed = Color(0xFF8B0000);

  /// 暗红高亮
  static const Color darkRedBright = Color(0xFFB22222);

  /// 暗金 — 金色文字/边框/战力
  static const Color darkGold = Color(0xFFC5A059);

  /// 暗金高亮
  static const Color darkGoldBright = Color(0xFFD4AF37);

  /// 正文文字 — 灰白
  static const Color textPrimary = Color(0xFFE0E0E0);

  /// 次要文字 — 灰色
  static const Color textSecondary = Color(0xFF9E9E9E);

  /// 提示文字 — 暗灰
  static const Color textHint = Color(0xFF606060);

  /// 分割线
  static const Color divider = Color(0xFF333333);

  /// 内力条颜色 — 蓝色
  static const Color innerEnergy = Color(0xFF4A6FA5);

  /// 状态效果 — 绿色增益
  static const Color buffGreen = Color(0xFF4CAF50);

  /// 状态效果 — 红色减益
  static const Color debuffRed = Color(0xFFE53935);
}

// =============================================================================
// 品质颜色映射（DESIGN.md 3.3.1）
// =============================================================================

/// Quality 枚举 → 实际 Color 映射
///
/// | 品质 | 颜色标记 | Color |
/// |------|---------|-------|
/// | 凡品(normal)   | 白   | #E0E0E0 |
/// | 良品(magic)    | 蓝   | #4A6FA5 |
/// | 上品(rare)     | 黄   | #D4AF37 |
/// | 暗金(unique)   | 橙★  | #E65100 |
/// | 神品(divine)   | 红★★ | #D32F2F |
/// | 传说(legendary)| 金★★★| #FFD700 |
extension QualityColor on Quality {
  /// 获取品质对应的颜色
  Color get color => switch (this) {
        Quality.normal => const Color(0xFFE0E0E0),
        Quality.magic => const Color(0xFF4A6FA5),
        Quality.rare => const Color(0xFFD4AF37),
        Quality.unique => const Color(0xFFE65100),
        Quality.divine => const Color(0xFFD32F2F),
        Quality.legendary => const Color(0xFFFFD700),
      };

  /// 品质对应的暗色背景色（用于卡片背景）
  Color get dimColor => switch (this) {
        Quality.normal => const Color(0xFF2A2A2A),
        Quality.magic => const Color(0xFF1A2433),
        Quality.rare => const Color(0xFF2A2410),
        Quality.unique => const Color(0xFF2A1400),
        Quality.divine => const Color(0xFF2A0A0A),
        Quality.legendary => const Color(0xFF2A2200),
      };

  /// 品质星级（★的数量，暗金1★、神品2★、传说3★）
  int get stars => switch (this) {
        Quality.normal => 0,
        Quality.magic => 0,
        Quality.rare => 0,
        Quality.unique => 1,
        Quality.divine => 2,
        Quality.legendary => 3,
      };
}

// =============================================================================
// 装备槽位颜色
// =============================================================================

extension EquipmentSlotColor on EquipmentSlot {
  /// 槽位图标颜色
  Color get iconColor => switch (this) {
        EquipmentSlot.weapon => const Color(0xFFB22222),
        EquipmentSlot.armor => const Color(0xFF556B2F),
        EquipmentSlot.accessory => const Color(0xFF6A4C93),
        EquipmentSlot.treasure => const Color(0xFFC5A059),
        EquipmentSlot.boots => const Color(0xFF4A90D9),
        EquipmentSlot.offhand => const Color(0xFF8B4513),
      };
}

// =============================================================================
// 暗黑武侠主题
// =============================================================================

class DarkWuxiaTheme {
  DarkWuxiaTheme._();

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: const ColorScheme.dark(
        primary: DarkWuxiaColors.darkGold,
        onPrimary: DarkWuxiaColors.background,
        secondary: DarkWuxiaColors.darkRed,
        onSecondary: DarkWuxiaColors.textPrimary,
        surface: DarkWuxiaColors.surface,
        onSurface: DarkWuxiaColors.textPrimary,
        error: DarkWuxiaColors.darkRedBright,
        onError: DarkWuxiaColors.textPrimary,
      ),

      fontFamily: 'serif',

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'serif', fontSize: 28, fontWeight: FontWeight.bold,
          color: DarkWuxiaColors.darkGold, letterSpacing: 2,
        ),
        displayMedium: TextStyle(
          fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.bold,
          color: DarkWuxiaColors.darkGold, letterSpacing: 1.5,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.bold,
          color: DarkWuxiaColors.darkGold,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w600,
          color: DarkWuxiaColors.darkGold,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.w600,
          color: DarkWuxiaColors.darkGold,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'serif', fontSize: 16, color: DarkWuxiaColors.textPrimary, height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'serif', fontSize: 14, color: DarkWuxiaColors.textPrimary, height: 1.5,
        ),
        bodySmall: TextStyle(
          fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontFamily: 'serif', fontSize: 14, fontWeight: FontWeight.bold, color: DarkWuxiaColors.textPrimary,
        ),
        labelMedium: TextStyle(
          fontFamily: 'serif', fontSize: 12, fontWeight: FontWeight.w600, color: DarkWuxiaColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontFamily: 'serif', fontSize: 10, color: DarkWuxiaColors.textHint,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: DarkWuxiaColors.background,
        foregroundColor: DarkWuxiaColors.darkGold,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.bold,
          color: DarkWuxiaColors.darkGold, letterSpacing: 2,
        ),
        iconTheme: IconThemeData(color: DarkWuxiaColors.darkGold),
      ),

      scaffoldBackgroundColor: DarkWuxiaColors.background,

      cardTheme: CardThemeData(
        color: DarkWuxiaColors.surface,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: DarkWuxiaColors.divider, width: 0.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DarkWuxiaColors.darkRed,
          foregroundColor: DarkWuxiaColors.textPrimary,
          textStyle: const TextStyle(fontFamily: 'serif', fontSize: 15, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DarkWuxiaColors.darkGold,
          textStyle: const TextStyle(fontFamily: 'serif', fontSize: 15),
          side: const BorderSide(color: DarkWuxiaColors.darkGold, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DarkWuxiaColors.darkGold,
          textStyle: const TextStyle(fontFamily: 'serif'),
        ),
      ),

      listTileTheme: const ListTileThemeData(
        textColor: DarkWuxiaColors.textPrimary,
        iconColor: DarkWuxiaColors.darkGold,
        tileColor: DarkWuxiaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),

      dividerTheme: const DividerThemeData(
        color: DarkWuxiaColors.divider, thickness: 0.5, space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DarkWuxiaColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: DarkWuxiaColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: DarkWuxiaColors.darkGold),
        ),
        labelStyle: const TextStyle(fontFamily: 'serif', color: DarkWuxiaColors.textSecondary),
        hintStyle: const TextStyle(fontFamily: 'serif', color: DarkWuxiaColors.textHint),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: DarkWuxiaColors.elevated,
        titleTextStyle: const TextStyle(
          fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.bold, color: DarkWuxiaColors.darkGold,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'serif', fontSize: 14, color: DarkWuxiaColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: DarkWuxiaColors.background,
        selectedItemColor: DarkWuxiaColors.darkGold,
        unselectedItemColor: DarkWuxiaColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontFamily: 'serif', fontSize: 11),
        unselectedLabelStyle: TextStyle(fontFamily: 'serif', fontSize: 11),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: DarkWuxiaColors.darkGold,
        inactiveTrackColor: DarkWuxiaColors.divider,
        thumbColor: DarkWuxiaColors.darkGoldBright,
        overlayColor: DarkWuxiaColors.darkGold.withValues(alpha: 0.2),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return DarkWuxiaColors.darkGold;
          return DarkWuxiaColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return DarkWuxiaColors.darkRed;
          return DarkWuxiaColors.divider;
        }),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: DarkWuxiaColors.darkGold,
        linearTrackColor: DarkWuxiaColors.divider,
      ),

      iconTheme: const IconThemeData(color: DarkWuxiaColors.darkGold),

      chipTheme: ChipThemeData(
        backgroundColor: DarkWuxiaColors.surface,
        labelStyle: const TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.textPrimary),
        side: const BorderSide(color: DarkWuxiaColors.divider, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}

// =============================================================================
// 通用组件
// =============================================================================

/// 暗黑风格卡片
class DarkWuxiaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? borderColor;
  final Color? backgroundColor;
  final double? borderWidth;

  const DarkWuxiaCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.backgroundColor,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? DarkWuxiaColors.surface,
        border: Border.all(
          color: borderColor ?? DarkWuxiaColors.divider,
          width: borderWidth ?? 0.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }
}

/// 暗黑风格标题（带装饰线）
class DarkWuxiaSectionTitle extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? color;

  const DarkWuxiaSectionTitle({super.key, required this.text, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: color ?? DarkWuxiaColors.darkGold),
          const SizedBox(width: 6),
        ],
        Text(
          text,
          style: TextStyle(
            fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold,
            color: color ?? DarkWuxiaColors.darkGold, letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 8),
        const Flexible(child: Divider(color: DarkWuxiaColors.divider, thickness: 0.5)),
      ],
    );
  }
}

/// 分割线
class DarkWuxiaDivider extends StatelessWidget {
  const DarkWuxiaDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(color: DarkWuxiaColors.divider, thickness: 0.5, height: 1);
  }
}

/// 加载中
class DarkWuxiaLoading extends StatelessWidget {
  final String? text;
  const DarkWuxiaLoading({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: DarkWuxiaColors.darkGold),
          if (text != null) ...[
            const SizedBox(height: 16),
            Text(text!, style: const TextStyle(fontFamily: 'serif', fontSize: 14, color: DarkWuxiaColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

/// 空状态
class DarkWuxiaEmpty extends StatelessWidget {
  final String text;
  final IconData? icon;

  const DarkWuxiaEmpty({super.key, required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon ?? Icons.inbox, size: 64, color: DarkWuxiaColors.textHint),
          const SizedBox(height: 16),
          Text(text, style: const TextStyle(fontFamily: 'serif', fontSize: 14, color: DarkWuxiaColors.textSecondary)),
        ],
      ),
    );
  }
}
