import 'package:flutter/material.dart';

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

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Wrap(
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
    );
  }
}
