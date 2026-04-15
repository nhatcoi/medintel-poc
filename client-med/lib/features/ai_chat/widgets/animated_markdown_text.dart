import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Renders markdown text with an optional typewriter reveal so patients see
/// letters appearing one-by-one (feels like the assistant is actually typing).
///
/// When [animate] is false — or after the animation completes — the full
/// markdown is rendered with all flutter_markdown formatting intact.
class AnimatedMarkdownText extends StatefulWidget {
  const AnimatedMarkdownText({
    super.key,
    required this.text,
    required this.styleSheet,
    this.animate = true,
    this.charsPerTick = 2,
    this.tickDuration = const Duration(milliseconds: 16),
    this.selectable = true,
    this.onCompleted,
  });

  final String text;
  final MarkdownStyleSheet styleSheet;
  final bool animate;
  final int charsPerTick;
  final Duration tickDuration;
  final bool selectable;
  final VoidCallback? onCompleted;

  @override
  State<AnimatedMarkdownText> createState() => _AnimatedMarkdownTextState();
}

class _AnimatedMarkdownTextState extends State<AnimatedMarkdownText> {
  Timer? _timer;
  int _visible = 0;

  @override
  void initState() {
    super.initState();
    if (widget.animate && widget.text.isNotEmpty) {
      _visible = 0;
      _start();
    } else {
      _visible = widget.text.length;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedMarkdownText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _timer?.cancel();
      if (widget.animate) {
        _visible = 0;
        _start();
      } else {
        _visible = widget.text.length;
      }
    } else if (!old.animate && widget.animate) {
      _visible = 0;
      _start();
    }
  }

  void _start() {
    _timer = Timer.periodic(widget.tickDuration, (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      final next = _visible + widget.charsPerTick;
      if (next >= widget.text.length) {
        setState(() => _visible = widget.text.length);
        t.cancel();
        widget.onCompleted?.call();
      } else {
        setState(() => _visible = next);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rendered = widget.text.substring(0, _visible);
    final isDone = _visible >= widget.text.length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        MarkdownBody(
          data: rendered.isEmpty ? '\u200B' : rendered,
          selectable: widget.selectable && isDone,
          shrinkWrap: true,
          styleSheet: widget.styleSheet,
        ),
        if (!isDone)
          Positioned(
            right: -2,
            bottom: 2,
            child: _BlinkingCaret(color: widget.styleSheet.p?.color),
          ),
      ],
    );
  }
}

class _BlinkingCaret extends StatefulWidget {
  const _BlinkingCaret({this.color});

  final Color? color;

  @override
  State<_BlinkingCaret> createState() => _BlinkingCaretState();
}

class _BlinkingCaretState extends State<_BlinkingCaret>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 2,
        height: 18,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
