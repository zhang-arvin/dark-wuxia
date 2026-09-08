// =============================================================================
// battle_animations.dart — 战斗动画系统（6组件）
//
// 功能：
//   - AttackAnimation: 冲刺攻击 + 暴击震动
//   - DamageNumberAnimation: 伤害数字飞出 + 渐隐
//   - ShakeAnimation: 受击抖动 + 红色闪光
//   - DeathAnimation: 死亡溶解 + 缩小坠落
//   - SkillEffectAnimation: 技能全屏闪光 + 扩散
//   - ComboFlashAnimation: 连击提示放大 + 渐隐
//
// 设计原则：
//   - 纯 Flutter 绘制（Canvas / Container / DecoratedBox），不需图片
//   - 暗黑武侠视觉风格（配色参考 theme.dart）
//   - AnimationController + Tween + CurvedAnimation
//   - 暴露 start() / stop() + onAnimationComplete 回调
//   - 所有 State 类公开，支持 GlobalKey 外部调用 start()/stop()
// =============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../../models/enums.dart';

// =============================================================================
// 伤害类型枚举（本文件局部使用）
// =============================================================================

/// 伤害类型 — 决定 DamageNumberAnimation 的颜色和标签
enum DamageType {
  /// 物理伤害 — 暗红色
  physical('外功'),
  /// 内功伤害 — 蓝色
  internal('内力'),
  /// 真实伤害 — 灰色
  trueDamage('真伤');

  const DamageType(this.subLabel);

  final String subLabel;
}

// =============================================================================
// 1. AttackAnimation — 攻击冲刺 + 暴击震动
// =============================================================================

/// 攻击动作动画
///
/// 攻击者向目标方向冲刺（translateX）然后回弹。
/// - 普通攻击: 200ms, Curves.easeOutQuad 冲刺+回弹
/// - 暴击攻击: 额外画面震动 + 红色闪光遮罩
///
/// 用法：包裹攻击者 Widget，自动开始动画。
/// 可通过 GlobalKey<AttackAnimationState> 调用 start() 重新触发。
class AttackAnimation extends StatefulWidget {
  final Widget child;

  /// 冲刺方向：true=向右(攻击右侧目标), false=向左
  final bool dashRight;

  /// 是否暴击（暴击触发震动+红色闪光）
  final bool isCritical;

  /// 动画完成回调
  final VoidCallback? onAnimationComplete;

  const AttackAnimation({
    super.key,
    required this.child,
    this.dashRight = true,
    this.isCritical = false,
    this.onAnimationComplete,
  });

  @override
  State<AttackAnimation> createState() => AttackAnimationState();
}

class AttackAnimationState extends State<AttackAnimation>
    with TickerProviderStateMixin {
  late AnimationController _dashController;
  late AnimationController _critController;
  late Animation<double> _dashAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _flashAnimation;

  @override
  void initState() {
    super.initState();

    // 冲刺动画: 200ms, easeOutQuad
    _dashController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _dashAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _dashController, curve: Curves.easeOutQuad),
    );

    // 暴击震动+闪光: 300ms
    _critController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _critController, curve: Curves.elasticIn),
    );
    _flashAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _critController, curve: Curves.easeOut),
    );

    _runAnimation();
  }

  void _runAnimation() {
    _dashController.forward(from: 0).then((_) {
      if (widget.isCritical) {
        _critController.forward(from: 0).then((_) {
          widget.onAnimationComplete?.call();
        });
      } else {
        widget.onAnimationComplete?.call();
      }
    });
  }

  /// 重新触发攻击动画
  void start() => _runAnimation();

  /// 停止所有动画
  void stop() {
    _dashController.stop();
    _critController.stop();
  }

  @override
  void dispose() {
    _dashController.dispose();
    _critController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_dashController, _critController]),
      builder: (context, child) {
        // 冲刺位移: sin(π*t) * 60px — 冲刺后回弹归位
        final dashOffset = math.sin(_dashAnimation.value * math.pi) * 60.0;
        final dx = widget.dashRight ? dashOffset : -dashOffset;

        // 暴击震动: sin(8π*t) * 5px — 高频抖动
        final shakeX = math.sin(_shakeAnimation.value * math.pi * 8) * 5.0;

        return Stack(
          children: [
            // 暴击红色闪光遮罩
            if (widget.isCritical && _flashAnimation.value > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: DarkWuxiaColors.darkRedBright
                        .withValues(alpha: _flashAnimation.value * 0.4),
                  ),
                ),
              ),
            // 攻击者位移
            Transform.translate(
              offset: Offset(dx + shakeX, 0),
              child: child,
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

// =============================================================================
// 2. DamageNumberAnimation — 伤害数字飞出
// =============================================================================

/// 伤害数字飞出动画
///
/// 从受击者位置弹出，向上飘浮，渐隐消失。
/// - 物理伤害: 暗红色 #B22222
/// - 内功伤害: 蓝色 #4A6FA5
/// - 真实伤害: 灰色 #9E9E9E
/// - 暴击: 暗金色 #D4AF37，更大字号 + "暴击!" 标签
///
/// 用法：作为 Stack 中的 Positioned/Overlay 子组件，自动开始动画。
class DamageNumberAnimation extends StatefulWidget {
  /// 伤害数值
  final int damage;

  /// 伤害类型
  final DamageType damageType;

  /// 是否暴击
  final bool isCritical;

  /// 动画完成回调
  final VoidCallback? onAnimationComplete;

  const DamageNumberAnimation({
    super.key,
    required this.damage,
    this.damageType = DamageType.physical,
    this.isCritical = false,
    this.onAnimationComplete,
  });

  @override
  State<DamageNumberAnimation> createState() => DamageNumberAnimationState();
}

class DamageNumberAnimationState extends State<DamageNumberAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // 向上飘浮: 0→-80px, easeOutCubic
    _floatAnimation = Tween<double>(begin: 0, end: -80).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    // 渐隐: 前半保持可见, 后半渐隐
    _fadeAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );
    // 弹出缩放: 0.5→1.0, elasticOut
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
      ),
    );

    _controller.forward().then((_) => widget.onAnimationComplete?.call());
  }

  /// 重新触发动画
  void start() => _controller.forward(from: 0);

  /// 停止动画
  void stop() => _controller.stop();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _damageColor {
    if (widget.isCritical) return DarkWuxiaColors.darkGoldBright;
    return switch (widget.damageType) {
      DamageType.physical => DarkWuxiaColors.darkRedBright,
      DamageType.internal => DarkWuxiaColors.innerEnergy,
      DamageType.trueDamage => DarkWuxiaColors.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          border: Border.all(color: _damageColor, width: 1),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '-${widget.damage}',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: widget.isCritical ? 24 : 18,
                fontWeight: FontWeight.bold,
                color: _damageColor,
                shadows: [
                  Shadow(
                    color: _damageColor.withValues(alpha: 0.8),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            if (widget.isCritical)
              Text(
                '暴击!',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 10,
                  color: _damageColor,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Text(
                widget.damageType.subLabel,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 9,
                  color: _damageColor.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 3. ShakeAnimation — 受击抖动 + 红色闪光
// =============================================================================

/// 受击抖动动画
///
/// 左右快速抖动3次（translateX ±8px），150ms，配合红色闪光遮罩。
///
/// 用法：包裹受击者 Widget，自动开始动画。
/// 可通过 GlobalKey<ShakeAnimationState> 调用 start() 重新触发。
class ShakeAnimation extends StatefulWidget {
  final Widget child;

  /// 动画完成回调
  final VoidCallback? onAnimationComplete;

  const ShakeAnimation({
    super.key,
    required this.child,
    this.onAnimationComplete,
  });

  @override
  State<ShakeAnimation> createState() => ShakeAnimationState();
}

class ShakeAnimationState extends State<ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;
  late Animation<double> _flashAnimation;

  @override
  void initState() {
    super.initState();

    // 150ms
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // 抖动: t∈[0,1], sin(6π*t) 产生3次往返
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    // 红色闪光: 快速亮→灭
    _flashAnimation = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward().then((_) => widget.onAnimationComplete?.call());
  }

  /// 触发抖动动画
  void start() => _controller.forward(from: 0);

  /// 停止动画
  void stop() => _controller.stop();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // sin(6π * t) * 8px — 3次往返抖动
        final shakeX = math.sin(_shakeAnimation.value * math.pi * 6) * 8.0;
        return Stack(
          children: [
            // 红色闪光遮罩
            if (_flashAnimation.value > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: DarkWuxiaColors.darkRedBright
                        .withValues(alpha: _flashAnimation.value * 0.3),
                  ),
                ),
              ),
            // 受击者抖动
            Transform.translate(
              offset: Offset(shakeX, 0),
              child: child,
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

// =============================================================================
// 4. DeathAnimation — 死亡溶解 + 缩小坠落
// =============================================================================

/// 死亡溶解动画
///
/// 透明度渐降 + 缩放缩小 + 向下坠落，500ms，配合灰色遮罩。
///
/// 用法：包裹死亡者 Widget，自动开始动画。
/// 可通过 GlobalKey<DeathAnimationState> 调用 start() 重新触发。
class DeathAnimation extends StatefulWidget {
  final Widget child;

  /// 动画完成回调
  final VoidCallback? onAnimationComplete;

  const DeathAnimation({
    super.key,
    required this.child,
    this.onAnimationComplete,
  });

  @override
  State<DeathAnimation> createState() => DeathAnimationState();
}

class DeathAnimationState extends State<DeathAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fallAnimation;
  late Animation<double> _overlayAnimation;

  @override
  void initState() {
    super.initState();

    // 500ms
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // 透明度渐降: 1→0
    _opacityAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    // 缩放缩小: 1.0→0.3
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    // 向下坠落: 0→40px
    _fallAnimation = Tween<double>(begin: 0, end: 40).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    // 灰色遮罩: 0→0.5
    _overlayAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward().then((_) => widget.onAnimationComplete?.call());
  }

  /// 触发死亡动画
  void start() => _controller.forward(from: 0);

  /// 停止动画
  void stop() => _controller.stop();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // 灰色遮罩
            if (_overlayAnimation.value > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.grey
                        .withValues(alpha: _overlayAnimation.value),
                  ),
                ),
              ),
            // 死亡者: 透明度+缩放+坠落
            Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.translate(
                offset: Offset(0, _fallAnimation.value),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

// =============================================================================
// 5. SkillEffectAnimation — 技能全屏闪光 + 扩散
// =============================================================================

/// 技能特效动画
///
/// 全屏发光闪光（不同颜色对应不同武学类型）+ 放射状扩散动画（中心向外），300ms。
///
/// 武学类型颜色映射：
/// - 内功(internal): 蓝色 #4A6FA5
/// - 外功(external): 暗红 #B22222
/// - 轻功(lightness): 暗金 #C5A059
/// - 心法(mantra): 绿色 #4CAF50
///
/// 用法：作为全屏 Overlay 子组件，自动开始动画。
/// 可通过 GlobalKey<SkillEffectAnimationState> 调用 start() 重新触发。
class SkillEffectAnimation extends StatefulWidget {
  /// 武学类型（决定闪光颜色）
  final MartialType martialType;

  /// 动画完成回调
  final VoidCallback? onAnimationComplete;

  const SkillEffectAnimation({
    super.key,
    this.martialType = MartialType.external,
    this.onAnimationComplete,
  });

  @override
  State<SkillEffectAnimation> createState() => SkillEffectAnimationState();
}

class SkillEffectAnimationState extends State<SkillEffectAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flashAnimation;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();

    // 300ms
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 全屏闪光: 0.7→0, 快速亮→灭
    _flashAnimation = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    // 放射状扩散: 0→1, 中心向外
    _expandAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward().then((_) => widget.onAnimationComplete?.call());
  }

  /// 触发技能特效
  void start() => _controller.forward(from: 0);

  /// 停止动画
  void stop() => _controller.stop();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _effectColor => switch (widget.martialType) {
        MartialType.internal => DarkWuxiaColors.innerEnergy,
        MartialType.external => DarkWuxiaColors.darkRedBright,
        MartialType.lightness => DarkWuxiaColors.darkGold,
        MartialType.mantra => DarkWuxiaColors.buffGreen,
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return IgnorePointer(
          child: Stack(
            children: [
              // 全屏发光闪光
              Positioned.fill(
                child: Container(
                  color: _effectColor
                      .withValues(alpha: _flashAnimation.value * 0.5),
                ),
              ),
              // 放射状扩散 — CustomPaint 绘制
              Positioned.fill(
                child: CustomPaint(
                  painter: _RadialExplosionPainter(
                    progress: _expandAnimation.value,
                    color: _effectColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 放射状扩散绘制器 — 中心向外扩散的圆环 + 射线
class _RadialExplosionPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RadialExplosionPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.max(size.width, size.height) * 0.7;
    final radius = maxRadius * progress;
    final alpha = (1 - progress).clamp(0.0, 1.0);

    // 扩散圆环（3层）
    for (var i = 0; i < 3; i++) {
      final ringRadius = radius * (1 - i * 0.2);
      if (ringRadius <= 0) continue;
      final paint = Paint()
        ..color = color.withValues(alpha: alpha * (0.6 - i * 0.15))
        ..style = PaintingStyle.stroke
        ..strokeWidth = (3 - i).toDouble();
      canvas.drawCircle(center, ringRadius, paint);
    }

    // 射线（8条放射线）
    final rayPaint = Paint()
      ..color = color.withValues(alpha: alpha * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 8; i++) {
      final angle = (i * math.pi) / 4;
      final innerR = radius * 0.3;
      final outerR = radius;
      final startX = center.dx + innerR * math.cos(angle);
      final startY = center.dy + innerR * math.sin(angle);
      final endX = center.dx + outerR * math.cos(angle);
      final endY = center.dy + outerR * math.sin(angle);
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        rayPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadialExplosionPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// =============================================================================
// 6. ComboFlashAnimation — 连击提示放大 + 渐隐
// =============================================================================

/// 连击提示动画
///
/// 屏幕中央显示 "连击 x2!" "连击 x3!" 等，快速放大+渐隐，600ms。
///
/// 用法：作为全屏 Overlay 子组件，自动开始动画。
/// 可通过 GlobalKey<ComboFlashAnimationState> 调用 start() 重新触发。
class ComboFlashAnimation extends StatefulWidget {
  /// 连击数（显示为 "连击 xN!"）
  final int comboCount;

  /// 动画完成回调
  final VoidCallback? onAnimationComplete;

  const ComboFlashAnimation({
    super.key,
    required this.comboCount,
    this.onAnimationComplete,
  });

  @override
  State<ComboFlashAnimation> createState() => ComboFlashAnimationState();
}

class ComboFlashAnimationState extends State<ComboFlashAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 600ms
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // 放大: 0.3→1.5→1.0 — 弹出效果
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );
    // 渐隐: 后半渐隐
    _fadeAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) => widget.onAnimationComplete?.call());
  }

  /// 重新触发连击提示
  void start() => _controller.forward(from: 0);

  /// 停止动画
  void stop() => _controller.stop();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 连击数越高，颜色越华丽
    final color = switch (widget.comboCount) {
      >= 10 => DarkWuxiaColors.darkGoldBright,
      >= 5 => DarkWuxiaColors.darkGold,
      >= 3 => DarkWuxiaColors.darkRedBright,
      _ => DarkWuxiaColors.textPrimary,
    };

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // 后半段缩放回弹: 1.5→1.0
        final scalePhase = _controller.value < 0.4
            ? _scaleAnimation.value
            : 1.5 - (1.0 * (_controller.value - 0.4) / 0.6);

        return Center(
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: scalePhase,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(
          '连击 x${widget.comboCount}!',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 3,
            shadows: [
              Shadow(
                color: color.withValues(alpha: 0.8),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
