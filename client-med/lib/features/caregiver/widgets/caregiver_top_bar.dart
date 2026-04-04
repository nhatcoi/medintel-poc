import 'package:flutter/material.dart';

import '../../../core/theme/vitalis_colors.dart';

/// App bar tùy chỉnh: avatar người chăm sóc, logo chữ, cài đặt.
class CaregiverTopBar extends StatelessWidget implements PreferredSizeWidget {
  const CaregiverTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: VitalisColors.caregiverHeroBlue,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: VitalisColors.primaryContainer.withValues(alpha: 0.35),
            child: Icon(Icons.person_rounded, color: VitalisColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('MedIntel', style: titleStyle),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
            color: VitalisColors.onSurface,
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
        ],
      ),
    );
  }
}
