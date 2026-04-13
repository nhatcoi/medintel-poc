import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/vitalis_colors.dart';

/// Dòng chữ gõ dần, xoay vòng — khuyến khích tương tác khi màn chat trống.
class AiChatWelcomeTypewriter extends StatefulWidget {
  const AiChatWelcomeTypewriter({
    super.key,
    required this.phrases,
  });

  final List<String> phrases;

  @override
  State<AiChatWelcomeTypewriter> createState() => _AiChatWelcomeTypewriterState();
}

class _AiChatWelcomeTypewriterState extends State<AiChatWelcomeTypewriter> {
  static const _typeMs = 42;
  static const _deleteMs = 22;
  static const _holdMs = 2600;
  static const _betweenMs = 400;

  int _phraseIndex = 0;
  int _visibleChars = 0;
  bool _deleting = false;
  Timer? _timer;
  bool _cursorOn = true;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    _startCursorBlink();
    _scheduleStep();
  }

  @override
  void didUpdateWidget(covariant AiChatWelcomeTypewriter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phrases != widget.phrases) {
      _timer?.cancel();
      setState(() {
        _phraseIndex = 0;
        _visibleChars = 0;
        _deleting = false;
      });
      _scheduleStep();
    }
  }

  void _startCursorBlink() {
    _cursorTimer?.cancel();
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 530), (_) {
      if (!mounted) return;
      setState(() => _cursorOn = !_cursorOn);
    });
  }

  List<String> get _phrases =>
      widget.phrases.where((e) => e.trim().isNotEmpty).toList(growable: false);

  void _scheduleStep() {
    _timer?.cancel();
    final list = _phrases;
    if (list.isEmpty) return;

    final phrase = list[_phraseIndex % list.length];
    final len = phrase.characters.length;

    if (!_deleting) {
      if (_visibleChars < len) {
        _timer = Timer(const Duration(milliseconds: _typeMs), () {
          if (!mounted) return;
          setState(() => _visibleChars++);
          _scheduleStep();
        });
      } else {
        _timer = Timer(const Duration(milliseconds: _holdMs), () {
          if (!mounted) return;
          setState(() => _deleting = true);
          _scheduleStep();
        });
      }
    } else {
      if (_visibleChars > 0) {
        _timer = Timer(const Duration(milliseconds: _deleteMs), () {
          if (!mounted) return;
          setState(() => _visibleChars--);
          _scheduleStep();
        });
      } else {
        _timer = Timer(const Duration(milliseconds: _betweenMs), () {
          if (!mounted) return;
          setState(() {
            _deleting = false;
            _phraseIndex = (_phraseIndex + 1) % list.length;
          });
          _scheduleStep();
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = _phrases;
    if (list.isEmpty) return const SizedBox.shrink();

    final phrase = list[_phraseIndex % list.length];
    final len = phrase.characters.length;
    final visible = phrase.characters.take(_visibleChars).toString();
    final atEnd = !_deleting && _visibleChars >= len;
    final showCaret = !atEnd || _cursorOn;

    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: VitalisColors.primary,
          height: 1.4,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
        );

    return Semantics(
      label: visible,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Align(
          alignment: Alignment.center,
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: textStyle,
              children: [
                TextSpan(text: visible),
                TextSpan(
                  text: showCaret ? '▍' : '',
                  style: textStyle?.copyWith(
                    color: VitalisColors.primary.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
