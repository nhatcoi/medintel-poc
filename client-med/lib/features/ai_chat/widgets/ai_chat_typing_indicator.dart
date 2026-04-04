import 'package:flutter/material.dart';

import '../../../core/theme/vitalis_colors.dart';

/// Ba chấm nhảy — hiển thị khi AI đang "gõ".
class AiChatTypingIndicator extends StatefulWidget {
  const AiChatTypingIndicator({super.key});

  @override
  State<AiChatTypingIndicator> createState() => _AiChatTypingIndicatorState();
}

class _AiChatTypingIndicatorState extends State<AiChatTypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _anims;

  static const int _dotCount = 3;
  static const Duration _period = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _dotCount,
      (i) => AnimationController(vsync: this, duration: _period)
        ..repeat(reverse: true, period: _period),
    );

    // Stagger each dot by 200ms
    for (var i = 0; i < _dotCount; i++) {
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }

    _anims = _controllers
        .map((c) => Tween<double>(begin: 0, end: -6).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: VitalisColors.surfaceContainerLowest,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _dotCount; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                AnimatedBuilder(
                  animation: _anims[i],
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _anims[i].value),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: VitalisColors.primary.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
