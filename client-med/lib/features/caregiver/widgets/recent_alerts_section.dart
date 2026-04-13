import 'package:flutter/material.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

import '../data/caregiver_ui_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vitalis_colors.dart';

class RecentAlertsSection extends StatelessWidget {
  const RecentAlertsSection({
    super.key,
    required this.alerts,
    this.onActionTap,
  });

  final List<CareAlertItem> alerts;
  final void Function(CareAlertItem alert)? onActionTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.careRecentAlerts,
            style: text.titleLarge?.copyWith(
              color: VitalisColors.caregiverHeroBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          if (alerts.isEmpty)
            Text(
              l10n.careAlertsEmpty,
              style: text.bodyMedium?.copyWith(
                color: VitalisColors.onSurfaceVariant,
                height: 1.4,
              ),
            )
          else
            DecoratedBox(
              decoration: BoxDecoration(
                color: VitalisColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < alerts.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: VitalisColors.outlineVariantBase.withValues(alpha: 0.12),
                      ),
                    _AlertTile(alert: alerts[i], onActionTap: onActionTap),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert, this.onActionTap});

  final CareAlertItem alert;
  final void Function(CareAlertItem alert)? onActionTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final dot = alert.isUrgent ? VitalisColors.statusError : VitalisColors.statusSuccess;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.subtitle,
                  style: text.bodySmall?.copyWith(color: VitalisColors.onSurfaceVariant),
                ),
                if (alert.actionLabel != null) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => onActionTap?.call(alert),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(48, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${alert.actionLabel!} ',
                          style: text.labelLarge?.copyWith(
                            color: VitalisColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 20, color: VitalisColors.primary),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
