import 'package:flutter/material.dart';

import '../../../core/theme/vitalis_colors.dart';

class AiChatQuickReplies extends StatelessWidget {
  const AiChatQuickReplies({
    super.key,
    required this.labels,
    this.onSelected,
  });

  final List<String> labels;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final label in labels)
            Material(
              color: VitalisColors.secondaryContainer,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: () => onSelected?.call(label),
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Text(
                    label,
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
