import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

import '../../../core/theme/vitalis_colors.dart';
import '../data/ai_chat_models.dart';
import 'animated_markdown_text.dart';

class AiChatMessageTile extends StatelessWidget {
  const AiChatMessageTile({
    super.key,
    required this.item,
    this.animate = false,
    this.onAnimationCompleted,
  });

  final AiChatItem item;
  final bool animate;
  final VoidCallback? onAnimationCompleted;

  @override
  Widget build(BuildContext context) {
    return switch (item) {
      AiChatAssistantTurn(:final body, :final timeLabel, :final callout, :final toolSummaries) =>
        _AssistantBlock(
          body: body,
          timeLabel: timeLabel,
          callout: callout,
          toolSummaries: toolSummaries,
          animate: animate,
          onAnimationCompleted: onAnimationCompleted,
        ),
      AiChatUserTurn(:final body, :final timeLabel) => _UserBlock(body: body, timeLabel: timeLabel),
    };
  }
}

class _AssistantBlock extends StatelessWidget {
  const _AssistantBlock({
    required this.body,
    required this.timeLabel,
    this.callout,
    this.toolSummaries = const [],
    this.animate = false,
    this.onAnimationCompleted,
  });

  final String body;
  final String timeLabel;
  final String? callout;
  final List<String> toolSummaries;
  final bool animate;
  final VoidCallback? onAnimationCompleted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxBubbleWidth = (screenWidth * 0.82).clamp(260.0, 420.0);
    final bodyStyle = text.bodyLarge?.copyWith(
      color: VitalisColors.onSurface,
      height: 1.65,
      fontSize: 16,
    );
    final styleSheet = MarkdownStyleSheet(
      p: bodyStyle,
      strong: bodyStyle?.copyWith(fontWeight: FontWeight.w800),
      em: bodyStyle?.copyWith(fontStyle: FontStyle.italic),
      h1: text.titleLarge?.copyWith(
        color: VitalisColors.onSurface,
        fontWeight: FontWeight.w800,
      ),
      h2: text.titleMedium?.copyWith(
        color: VitalisColors.onSurface,
        fontWeight: FontWeight.w700,
      ),
      h3: text.titleSmall?.copyWith(
        color: VitalisColors.onSurface,
        fontWeight: FontWeight.w700,
      ),
      listBullet: bodyStyle?.copyWith(color: VitalisColors.primary),
      listIndent: 18,
      blockSpacing: 10,
      code: text.bodyMedium?.copyWith(
        color: VitalisColors.primary,
        backgroundColor: VitalisColors.surfaceContainerLow,
        fontFamily: 'monospace',
      ),
      codeblockDecoration: BoxDecoration(
        color: VitalisColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      codeblockPadding: const EdgeInsets.all(12),
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxBubbleWidth + 46),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _AssistantAvatar(),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 4),
                    child: Text(
                      l10n.aiAssistantBadge,
                      style: text.labelSmall?.copyWith(
                        color: VitalisColors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: VitalisColors.surfaceContainerLowest,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(22),
                        bottomRight: Radius.circular(22),
                        bottomLeft: Radius.circular(22),
                      ),
                      border: Border.all(
                        color: VitalisColors.outlineVariantBase
                            .withValues(alpha: 0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 22,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedMarkdownText(
                            text: body,
                            styleSheet: styleSheet,
                            animate: animate,
                            onCompleted: onAnimationCompleted,
                          ),
                          if (callout != null) ...[
                            const SizedBox(height: 16),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: VitalisColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                                border: const Border(
                                  left: BorderSide(
                                    color: VitalisColors.primary,
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 14, 14, 14),
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
                          if (toolSummaries.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final summary in toolSummaries)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: VitalisColors.primaryContainer
                                          .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      summary,
                                      style: text.bodySmall?.copyWith(
                                        color: VitalisColors
                                            .onSecondaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
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
          ],
        ),
      ),
    );
  }
}

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [VitalisColors.primary, VitalisColors.primaryContainer],
        ),
        boxShadow: [
          BoxShadow(
            color: VitalisColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.medical_services_rounded,
        color: Colors.white,
        size: 18,
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
