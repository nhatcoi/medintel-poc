import 'package:flutter/material.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

import '../data/caregiver_ui_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vitalis_colors.dart';

class MedicationsSection extends StatelessWidget {
  const MedicationsSection({
    super.key,
    required this.dateChipLabel,
    required this.items,
  });

  final String dateChipLabel;
  final List<MedicationDoseItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                l10n.careMedicationsTitle,
                style: text.titleLarge?.copyWith(
                  color: VitalisColors.caregiverHeroBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: VitalisColors.chipDateBackground,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Text(
                  dateChipLabel,
                  style: text.labelLarge?.copyWith(
                    color: VitalisColors.chipDateForeground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Text(
              l10n.careMedicationsEmpty,
              style: text.bodyMedium?.copyWith(
                color: VitalisColors.onSurfaceVariant,
                height: 1.4,
              ),
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              _MedicationRow(item: items[i], l10n: l10n),
            ],
        ],
      ),
    );
  }
}

class _MedicationRow extends StatelessWidget {
  const _MedicationRow({required this.item, required this.l10n});

  final MedicationDoseItem item;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final meta = _MetaForStatus(item.status, l10n);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: VitalisColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: VitalisColors.ambientFloating,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: meta.leadingBg,
                shape: BoxShape.circle,
              ),
              child: Icon(meta.icon, color: meta.leadingFg, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.timeLabel} • ${item.dosageLabel}',
                    style: text.bodyMedium?.copyWith(color: VitalisColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: meta.badgeBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                meta.badgeLabel,
                style: text.labelMedium?.copyWith(
                  color: meta.badgeFg,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaForStatus {
  _MetaForStatus(MedicationDoseStatus s, AppLocalizations l10n)
      : leadingBg = switch (s) {
          MedicationDoseStatus.taken => VitalisColors.statusSuccessSoft,
          MedicationDoseStatus.missed => VitalisColors.statusErrorSoft,
          MedicationDoseStatus.upcoming => VitalisColors.surfaceContainerLow,
        },
        leadingFg = switch (s) {
          MedicationDoseStatus.taken => VitalisColors.statusSuccess,
          MedicationDoseStatus.missed => VitalisColors.statusError,
          MedicationDoseStatus.upcoming => VitalisColors.statusUpcomingIcon,
        },
        icon = switch (s) {
          MedicationDoseStatus.taken => Icons.check_rounded,
          MedicationDoseStatus.missed => Icons.priority_high_rounded,
          MedicationDoseStatus.upcoming => Icons.schedule_rounded,
        },
        badgeLabel = switch (s) {
          MedicationDoseStatus.taken => l10n.doseStatusTaken,
          MedicationDoseStatus.missed => l10n.doseStatusMissed,
          MedicationDoseStatus.upcoming => l10n.doseStatusUpcoming,
        },
        badgeBg = switch (s) {
          MedicationDoseStatus.taken => VitalisColors.statusSuccessSoft,
          MedicationDoseStatus.missed => VitalisColors.statusErrorSoft,
          MedicationDoseStatus.upcoming => VitalisColors.surfaceContainerLow,
        },
        badgeFg = switch (s) {
          MedicationDoseStatus.taken => VitalisColors.statusSuccess,
          MedicationDoseStatus.missed => VitalisColors.statusError,
          MedicationDoseStatus.upcoming => VitalisColors.neutral,
        };

  final Color leadingBg;
  final Color leadingFg;
  final IconData icon;
  final String badgeLabel;
  final Color badgeBg;
  final Color badgeFg;
}
