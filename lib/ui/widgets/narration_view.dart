// =============================================================================
// narration_view.dart — 战斗描写文本展示（带打字机效果）
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme.dart';
import '../../models/enums.dart';

/// 战斗描写文本展示（带打字机效果）
class NarrationView extends StatefulWidget {
  final String text;
  final BattleTier? tier;
  final bool enableTypewriter;
  final int typeSpeed;
  final double fontSize;
  final bool autoScroll;

  const NarrationView({
    super.key,
    required this.text,
    this.tier,
    this.enableTypewriter = true,
    this.typeSpeed = 30,
    this.fontSize = 14,
    this.autoScroll = true,
  });

  @override
  State<NarrationView> createState() => _NarrationViewState();
}

class _NarrationViewState extends State<NarrationView> {
  final ScrollController _scrollController = ScrollController();
  String _displayedText = '';
  int _charIndex = 0;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    if (widget.enableTypewriter) {
      _startTyping();
    } else {
      _displayedText = widget.text;
    }
  }

  @override
  void didUpdateWidget(NarrationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      if (widget.enableTypewriter) {
        _startTyping();
      } else {
        _displayedText = widget.text;
      }
    }
  }

  void _startTyping() {
    _charIndex = 0;
    _displayedText = '';
    _isTyping = true;
    _typeNextChar();
  }

  void _typeNextChar() {
    if (!mounted || !_isTyping) return;
    if (_charIndex < widget.text.length) {
      setState(() {
        _displayedText = widget.text.substring(0, _charIndex + 1);
        _charIndex++;
      });
      if (widget.autoScroll) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          }
        });
      }
      Future.delayed(Duration(milliseconds: widget.typeSpeed), _typeNextChar);
    } else {
      _isTyping = false;
    }
  }

  void skipTyping() {
    setState(() {
      _displayedText = widget.text;
      _charIndex = widget.text.length;
      _isTyping = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color get _textColor {
    switch (widget.tier) {
      case BattleTier.crush: return DarkWuxiaColors.textSecondary;
      case BattleTier.normal: return DarkWuxiaColors.textPrimary;
      case BattleTier.boss: return DarkWuxiaColors.darkGold;
      case BattleTier.encounter: return DarkWuxiaColors.darkGold;
      case BattleTier.crit: return DarkWuxiaColors.darkRed;
      case BattleTier.drop: return DarkWuxiaColors.darkGold;
      case BattleTier.qigongDeviation: return DarkWuxiaColors.darkRed;
      case BattleTier.endless: return DarkWuxiaColors.darkGold;
      case null: return DarkWuxiaColors.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: skipTyping,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: DarkWuxiaColors.background,
          border: Border.all(color: DarkWuxiaColors.divider, width: 0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: SelectableText(
            _displayedText,
            style: TextStyle(
              fontFamily: 'serif', fontSize: widget.fontSize, color: _textColor, height: 1.8,
            ),
          ),
        ),
      ),
    );
  }
}

/// 连刷模式的简化描写视图（1句话 + 掉落列表）
class AutoRunNarrationView extends StatelessWidget {
  final String narration;
  final List<String> dropLines;

  const AutoRunNarrationView({super.key, required this.narration, this.dropLines = const []});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: DarkWuxiaColors.surface,
        border: Border.all(color: DarkWuxiaColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(narration, style: const TextStyle(fontFamily: 'serif', fontSize: 13, color: DarkWuxiaColors.textSecondary)),
          if (dropLines.isNotEmpty) ...[
            const SizedBox(height: 4),
            const Divider(height: 1, color: DarkWuxiaColors.divider),
            const SizedBox(height: 4),
            ...dropLines.map((line) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(line, style: const TextStyle(fontFamily: 'serif', fontSize: 12, color: DarkWuxiaColors.darkGold)),
            )),
          ],
        ],
      ),
    );
  }
}
