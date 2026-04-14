import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HomeScheduleHeader extends StatelessWidget {
  const HomeScheduleHeader({
    super.key,
    required this.displayName,
    required this.onTapPlus,
  });

  final String displayName;
  final VoidCallback onTapPlus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      color: scheme.background,
      padding:
          EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 16, 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: scheme.surfaceContainerHighest,
            child: Text(
              displayName.isEmpty ? 'T' : displayName[0].toUpperCase(),
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'XIN CHÀO',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.black54,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onTapPlus,
            icon: const Icon(LucideIcons.plus, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
