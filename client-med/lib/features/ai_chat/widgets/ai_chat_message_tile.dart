import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/theme/vitalis_colors.dart';
import '../data/ai_chat_models.dart';

class AiChatMessageTile extends StatelessWidget {
  const AiChatMessageTile({super.key, required this.item});

  final AiChatItem item;

  @override
  Widget build(BuildContext context) {
    return switch (item) {
      AiChatAssistantTurn(:final body, :final timeLabel, :final callout) =>
        _AssistantBlock(body: body, timeLabel: timeLabel, callout: callout),
      AiChatUserTurn(:final body, :final timeLabel) => _UserBlock(body: body, timeLabel: timeLabel),
    };
  }
}

class _AssistantBlock extends StatelessWidget {
  const _AssistantBlock({
    required this.body,
    required this.timeLabel,
    this.callout,
  });

  final String body;
  final String timeLabel;
  final String? callout;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MEDINTEL ASSISTANT',
              style: text.labelSmall?.copyWith(
                color: VitalisColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: VitalisColors.surfaceContainerLowest,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                border: Border.all(
                  color: VitalisColors.outlineVariantBase.withValues(alpha: 0.1),
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MarkdownBody(
                      data: body,
                      selectable: true,
                      shrinkWrap: true,
                      styleSheet: MarkdownStyleSheet(
                        p: text.bodyLarge?.copyWith(
                          color: VitalisColors.onSurface,
                          height: 1.5,
                        ),
                        strong: text.bodyLarge?.copyWith(
                          color: VitalisColors.onSurface,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                        em: text.bodyLarge?.copyWith(
                          color: VitalisColors.onSurface,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                        h1: text.titleLarge?.copyWith(
                          color: VitalisColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                        h2: text.titleMedium?.copyWith(
                          color: VitalisColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                        h3: text.titleSmall?.copyWith(
                          color: VitalisColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        listBullet: text.bodyLarge?.copyWith(
                          color: VitalisColors.primary,
                          height: 1.5,
                        ),
                        listIndent: 16,
                        blockSpacing: 8,
                        code: text.bodyMedium?.copyWith(
                          color: VitalisColors.primary,
                          backgroundColor: VitalisColors.surfaceContainerLow,
                          fontFamily: 'monospace',
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: VitalisColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        codeblockPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    if (callout != null) ...[
                      const SizedBox(height: 16),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: VitalisColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: const Border(
                            left: BorderSide(color: VitalisColors.primary, width: 4),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                          child: Text(
                            callout!,
                            style: text.bodySmall?.copyWith(
                              color: VitalisColors.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (timeLabel.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  timeLabel,
                  style: text.labelSmall?.copyWith(
                    color: VitalisColors.outlineVariantBase,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UserBlock extends StatelessWidget {
  const _UserBlock({required this.body, required this.timeLabel});

  final String body;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: VitalisColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: VitalisColors.primary.withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  body,
                  style: text.bodyLarge?.copyWith(
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                timeLabel,
                style: text.labelSmall?.copyWith(
                  color: VitalisColors.outlineVariantBase,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
