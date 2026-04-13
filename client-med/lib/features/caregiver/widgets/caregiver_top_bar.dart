import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

import '../../../core/theme/vitalis_colors.dart';

/// Header Caregiver — đặt dưới [SafeArea] của shell, không dùng [AppBar] để tránh notch.
class CaregiverTopBar extends StatelessWidget {
  const CaregiverTopBar({super.key});

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
            child: Text(AppLocalizations.of(context).appTitle, style: titleStyle),
          ),
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
            color: VitalisColors.onSurface,
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
        ],
      ),
    );
  }
}
