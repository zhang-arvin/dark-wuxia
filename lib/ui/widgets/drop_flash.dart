// =============================================================================
// drop_flash.dart — 掉落闪光动画（四级）
// =============================================================================

import 'package:flutter/material.dart';

import '../theme.dart';
import '../../models/enums.dart';
import 'quality_chip.dart';

/// 掉落闪光动画（四级）
class DropFlash extends StatefulWidget {
  final Quality quality;
  final String equipmentName;
  final String? affixText;
  final String? uniqueEffectText;
  final bool isPity;
  final VoidCallback? onComplete;

  const DropFlash({
    super.key,
    required this.quality,
    required this.equipmentName,
    this.affixText,
    this.uniqueEffectText,
    this.isPity = false,
    this.onComplete,
  });

  @override
  State<DropFlash> createState() => _DropFlashState();
}

class _DropFlashState extends State<DropFlash> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    final flashLevel = DropFlashLevel.fromQuality(widget.quality);
    final duration = switch (flashLevel) {
      DropFlashLevel.plain => 600,
      DropFlashLevel.detailed => 1200,
      DropFlashLevel.ceremonial => 2500,
      DropFlashLevel.legendary => 4000,
    };

    _controller = AnimationController(duration: Duration(milliseconds: duration), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3, curve: Curves.easeIn)),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.elasticOut)),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)),
    );

    _controller.forward().then((_) => widget.onComplete?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flashLevel = DropFlashLevel.fromQuality(widget.quality);
    final color = widget.quality.color;

    // plain 级：简短文字
    if (flashLevel == DropFlashLevel.plain) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: DarkWuxiaColors.surface,
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: Text(
            '> 获得【${widget.quality.displayName}】${widget.equipmentName}',
            style: TextStyle(fontFamily: 'serif', fontSize: 13, color: color),
          ),
        ),
      );
    }

    // detailed 以上：仪式感动画
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            if (flashLevel.priority >= DropFlashLevel.ceremonial.priority)
              Positioned.fill(
                child: Container(color: Colors.black.withValues(alpha: _fadeAnimation.value * 0.8)),
              ),
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.quality.dimColor,
                    border: Border.all(color: color, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: _glowAnimation.value),
                        blurRadius: 20 * _glowAnimation.value + 5,
                        spreadRadius: _glowAnimation.value * 10,
                      ),
                    ],
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildContent(color, flashLevel),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(Color color, DropFlashLevel flashLevel) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.isPity)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: DarkWuxiaColors.darkGold.withValues(alpha: 0.2),
              border: Border.all(color: DarkWuxiaColors.darkGold, width: 0.5),
            ),
            child: const Text('⚡ 保底触发', style: TextStyle(fontFamily: 'serif', fontSize: 11, color: DarkWuxiaColors.darkGold, fontWeight: FontWeight.bold)),
          ),
        QualityChip(quality: widget.quality, fontSize: 16),
        const SizedBox(height: 8),
        Text(
          widget.equipmentName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: flashLevel == DropFlashLevel.legendary ? 22 : 18,
            fontWeight: FontWeight.bold, color: color, letterSpacing: 2,
          ),
        ),
        if (widget.affixText != null && flashLevel.priority >= DropFlashLevel.detailed.priority) ...[
          const SizedBox(height: 8),
          Text(widget.affixText!, textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'serif', fontSize: 13, color: DarkWuxiaColors.textPrimary, height: 1.5)),
        ],
        if (widget.uniqueEffectText != null && flashLevel.priority >= DropFlashLevel.ceremonial.priority) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), border: Border.all(color: color, width: 0.5)),
            child: Text(widget.uniqueEffectText!, textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'serif', fontSize: 14, color: color, fontStyle: FontStyle.italic, height: 1.5)),
          ),
        ],
        if (flashLevel == DropFlashLevel.legendary) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: Divider(color: color, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('★' * widget.quality.stars, style: TextStyle(fontSize: 16, color: color)),
              ),
              Expanded(child: Divider(color: color, thickness: 1)),
            ],
          ),
        ],
      ],
    );
  }
}

/// 掉落闪光覆盖层（全屏，用于 legendary 级）
class DropFlashOverlay extends StatelessWidget {
  final Quality quality;
  final String equipmentName;
  final String? affixText;
  final String? uniqueEffectText;
  final bool isPity;
  final VoidCallback? onDismiss;

  const DropFlashOverlay({
    super.key,
    required this.quality,
    required this.equipmentName,
    this.affixText,
    this.uniqueEffectText,
    this.isPity = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () => onDismiss?.call(),
        child: Container(
          color: Colors.black.withValues(alpha: 0.9),
          alignment: Alignment.center,
          child: DropFlash(
            quality: quality,
            equipmentName: equipmentName,
            affixText: affixText,
            uniqueEffectText: uniqueEffectText,
            isPity: isPity,
          ),
        ),
      ),
    );
  }
}
