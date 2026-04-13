import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/vitalis_colors.dart';

/// Header Caregiver — đặt dưới [SafeArea] của shell, không dùng [AppBar] để tránh notch.
class CaregiverTopBar extends StatelessWidget {
  const CaregiverTopBar({
    super.key,
    required this.displayName,
  });

  final String displayName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.background,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 8, 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Text(
              displayName.isEmpty ? 'B' : displayName[0].toUpperCase(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: VitalisColors.caregiverHeroBlue,
              ),
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
                    color: VitalisColors.caregiverHeroBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(LucideIcons.settings2),
            color: VitalisColors.onSurface,
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
        ],
      ),
    );
  }
}
