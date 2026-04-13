import 'package:flutter/material.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

import '../../../core/theme/vitalis_colors.dart';
import '../data/ai_chat_models.dart';

class AiChatQuickReplies extends StatelessWidget {
  const AiChatQuickReplies({
    super.key,
    required this.actions,
    this.onSelected,
  });

  final List<SuggestedChatAction> actions;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final app = actions.where((a) => a.kind == SuggestedActionKind.app).toList();
    final knowledge = actions.where((a) => a.kind == SuggestedActionKind.knowledge).toList();
    final other = actions.where((a) => a.kind == SuggestedActionKind.other).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (app.isNotEmpty) _QuickReplySection(title: l10n.aiSuggestSectionApp, actions: app, onSelected: onSelected),
          if (knowledge.isNotEmpty)
            _QuickReplySection(title: l10n.aiSuggestSectionKnowledge, actions: knowledge, onSelected: onSelected),
          if (other.isNotEmpty) _QuickReplySection(title: l10n.aiSuggestSectionOther, actions: other, onSelected: onSelected),
        ],
      ),
    );
  }
}

class _QuickReplySection extends StatelessWidget {
  const _QuickReplySection({
    required this.title,
    required this.actions,
    this.onSelected,
  });

  final String title;
  final List<SuggestedChatAction> actions;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              title,
              style: text.labelSmall?.copyWith(
                color: VitalisColors.neutral,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final action in actions)
                Material(
                  color: VitalisColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: () => onSelected?.call(action.prompt),
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Text(
                        action.label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: VitalisColors.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
