import 'package:flutter/material.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

import '../../../core/theme/vitalis_colors.dart';

class AiChatComposer extends StatefulWidget {
  const AiChatComposer({
    super.key,
    this.controller,
    this.onSend,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final VoidCallback? onSend;
  final bool enabled;

  @override
  State<AiChatComposer> createState() => _AiChatComposerState();
}

class _AiChatComposerState extends State<AiChatComposer> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(AiChatComposer old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_onTextChanged);
      widget.controller?.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final has = (widget.controller?.text.trim().isNotEmpty) ?? false;
    if (has != _hasText) setState(() => _hasText = has);
  }

  void _handleSend() {
    if (_hasText && widget.enabled) widget.onSend?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: VitalisColors.surfaceContainerLowest.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: VitalisColors.onSurface.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.enabled ? () {} : null,
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: VitalisColors.primary,
                style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  enabled: widget.enabled,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: VitalisColors.onSurface,
                      ),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).aiComposerHint,
                    hintStyle: TextStyle(
                      color: VitalisColors.outlineVariantBase.withValues(alpha: 0.65),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: _hasText
                      ? Material(
                          key: const ValueKey('send'),
                          color: VitalisColors.primary,
                          shape: const CircleBorder(),
                          elevation: 2,
                          shadowColor: VitalisColors.primary.withValues(alpha: 0.35),
                          child: InkWell(
                            onTap: _handleSend,
                            customBorder: const CircleBorder(),
                            child: const SizedBox(
                              width: 48,
                              height: 48,
                              child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        )
                      : Material(
                          key: const ValueKey('mic'),
                          color: VitalisColors.surfaceContainerLow,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: widget.enabled ? () {} : null,
                            customBorder: const CircleBorder(),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: Icon(
                                Icons.mic_rounded,
                                color: widget.enabled
                                    ? VitalisColors.primary
                                    : VitalisColors.neutral,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
