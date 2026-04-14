import 'package:flutter/material.dart';

import '../data/home_schedule_models.dart';

String homeDoseActionKey({
  required String medicationId,
  required String timeLabel,
  required DateTime selectedDate,
}) {
  final d = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  return '$medicationId|${d.toIso8601String()}|$timeLabel';
}

class HomeDoseSectionWidget extends StatelessWidget {
  const HomeDoseSectionWidget({
    super.key,
    required this.section,
    required this.selectedDate,
    required this.pendingDoseKeys,
    required this.onLogDose,
  });

  final HomeDoseSection section;
  final DateTime selectedDate;
  final Set<String> pendingDoseKeys;
  final Future<void> Function({
    required String medicationId,
    required String status,
    String? scheduledTime,
    DateTime? scheduledDate,
  }) onLogDose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final takenCount = section.items.where((e) => e.status == HomeDoseStatus.taken).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  section.timeLabel,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: takenCount == section.items.length
                        ? scheme.primary.withValues(alpha: 0.4)
                        : scheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                  color: takenCount == section.items.length
                      ? scheme.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                ),
                child: Text(
                  '$takenCount/${section.items.length} ĐÃ DÙNG',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: takenCount == section.items.length ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in section.items)
            _HomeMedDoseCard(
              item: item,
              onLogDose: onLogDose,
              sectionTimeLabel: section.timeLabel,
              selectedDate: selectedDate,
              isLoading: pendingDoseKeys.contains(
                homeDoseActionKey(
                  medicationId: item.medicationId,
                  timeLabel: section.timeLabel,
                  selectedDate: selectedDate,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeMedDoseCard extends StatelessWidget {
  const _HomeMedDoseCard({
    required this.item,
    required this.onLogDose,
    required this.sectionTimeLabel,
    required this.selectedDate,
    required this.isLoading,
  });

  final HomeDoseSectionItem item;
  final String sectionTimeLabel;
  final DateTime selectedDate;
  final bool isLoading;
  final Future<void> Function({
    required String medicationId,
    required String status,
    String? scheduledTime,
    DateTime? scheduledDate,
  }) onLogDose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isTaken = item.status == HomeDoseStatus.taken;
    final isMissed = item.status == HomeDoseStatus.missed;

    final iconBg = isTaken
        ? scheme.primary
        : isMissed
            ? scheme.error
            : scheme.surfaceContainerHigh;

    return GestureDetector(
      onTap: () {
        if (!isTaken && !isLoading) {
          onLogDose(
            medicationId: item.medicationId,
            status: 'taken',
            scheduledTime: sectionTimeLabel,
            scheduledDate: selectedDate,
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: scheme.surfaceContainerLow,
          border: Border.all(
            color: isTaken
                ? scheme.outlineVariant.withValues(alpha: 0.15)
                : isMissed
                    ? scheme.error.withValues(alpha: 0.2)
                    : scheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBg,
                border: (!isTaken && !isMissed)
                    ? Border.all(color: scheme.primary.withValues(alpha: 0.3), width: 2)
                    : null,
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isTaken
                                ? scheme.onPrimary
                                : isMissed
                                    ? scheme.onError
                                    : scheme.primary,
                          ),
                        ),
                      )
                    : isTaken
                        ? Icon(Icons.check_rounded, color: scheme.onPrimary, size: 24)
                        : isMissed
                            ? Icon(Icons.close_rounded, color: scheme.onError, size: 24)
                            : Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scheme.primary,
                                ),
                              ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      decoration: isTaken ? TextDecoration.lineThrough : null,
                      color: isTaken
                          ? scheme.onSurfaceVariant.withValues(alpha: 0.45)
                          : isMissed
                              ? scheme.error
                              : scheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((item.dosage ?? '').trim().isNotEmpty || (item.frequency ?? '').trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        [
                          if ((item.dosage ?? '').trim().isNotEmpty) item.dosage!.trim(),
                          if ((item.frequency ?? '').trim().isNotEmpty) item.frequency!.trim(),
                        ].join(', '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surfaceContainerHigh,
              ),
              child: isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          scheme.primary.withValues(alpha: 0.8),
                        ),
                      ),
                    )
                  : Icon(Icons.chevron_right_rounded, size: 18, color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
            ),
          ],
        ),
      ),
    );
  }
}
