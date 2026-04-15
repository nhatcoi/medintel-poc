import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vitalis_colors.dart';
import '../../treatment/data/treatment_models.dart';

enum WarningSeverity { critical, warning, info }

enum WarningAction { logTaken, openChat, openCabinet, openSchedule }

class CareWarning {
  const CareWarning({
    required this.id,
    required this.title,
    required this.body,
    required this.severity,
    required this.action,
    required this.actionLabel,
    this.medicationId,
    this.scheduleId,
    this.scheduledDatetime,
    this.scheduledTime,
  });

  final String id;
  final String title;
  final String body;
  final WarningSeverity severity;
  final WarningAction action;
  final String actionLabel;
  final String? medicationId;
  final String? scheduleId;
  final DateTime? scheduledDatetime;
  final String? scheduledTime;
}

/// Derive warnings from current treatment state using simple, auditable rules
/// aligned to evidence-based adherence support (WHO 2003; Michie 2011).
List<CareWarning> deriveWarnings({
  required List<MedicationItem> meds,
  required List<MedicationScheduleItem> schedules,
  required List<MissedDoseItem> missedDoses,
  required NextDoseInfo? nextDose,
  required AdherenceSummary? summary7,
}) {
  final out = <CareWarning>[];

  // Rule 1: Overdue doses → critical, offer "mark taken" (BCT 1.2 problem solving).
  for (final m in missedDoses.take(3)) {
    out.add(CareWarning(
      id: 'missed:${m.scheduleId}:${m.scheduledDatetime.toIso8601String()}',
      title: '${m.medicationName} đã trễ ${m.minutesOverdue} phút',
      body:
          'Liều lúc ${_fmt(m.scheduledDatetime)} chưa được ghi nhận. Xác nhận với bệnh nhân và ghi lại trạng thái.',
      severity: WarningSeverity.critical,
      action: WarningAction.logTaken,
      actionLabel: 'Ghi nhận đã uống',
      medicationId: m.medicationId,
      scheduleId: m.scheduleId,
      scheduledDatetime: m.scheduledDatetime,
      scheduledTime: _hhmm(m.scheduledDatetime),
    ));
  }

  // Rule 2: Low stock → warning, open cabinet to refill (Capability / Opportunity).
  for (final m in meds) {
    final q = m.remainingQuantity;
    if (q == null) continue;
    if (q <= 5) {
      out.add(CareWarning(
        id: 'low:${m.medicationId}',
        title: 'Sắp hết ${m.name}',
        body:
            'Chỉ còn ${q.toStringAsFixed(0)} ${m.quantityUnit ?? 'đơn vị'}. Đặt thêm hoặc cập nhật tồn kho để tránh gián đoạn.',
        severity: q <= 2 ? WarningSeverity.critical : WarningSeverity.warning,
        action: WarningAction.openCabinet,
        actionLabel: 'Mở tủ thuốc',
        medicationId: m.medicationId,
      ));
    }
  }

  // Rule 3: Active med without schedule → info, set up schedule (Capability).
  final scheduledIds = schedules.map((s) => s.medicationId).toSet();
  for (final m in meds) {
    final active = (m.status ?? 'active').toLowerCase() == 'active';
    if (!active) continue;
    if (!scheduledIds.contains(m.medicationId)) {
      out.add(CareWarning(
        id: 'nosched:${m.medicationId}',
        title: '${m.name} chưa có lịch uống',
        body:
            'Thiết lập giờ uống cụ thể giúp tăng khả năng tuân thủ (bằng chứng: nhắc giờ có cấu trúc cải thiện adherence ~20%).',
        severity: WarningSeverity.info,
        action: WarningAction.openSchedule,
        actionLabel: 'Thiết lập lịch',
        medicationId: m.medicationId,
      ));
    }
  }

  // Rule 4: Compliance dưới 70% trong 7 ngày → motivation issue, đưa vào AI chat.
  final rate = summary7?.complianceRate ?? 0;
  if (summary7 != null && (summary7.total > 0) && rate < 0.7) {
    out.add(CareWarning(
      id: 'lowcompliance:7d',
      title:
          'Tuân thủ 7 ngày chỉ ${(rate * 100).round()}% (${summary7.taken}/${summary7.total})',
      body:
          'Thảo luận cùng AI để phân tích rào cản và đề xuất can thiệp hành vi (COM-B: Motivation).',
      severity: WarningSeverity.warning,
      action: WarningAction.openChat,
      actionLabel: 'Hỏi AI trợ lý',
    ));
  }

  // Sort critical → warning → info, limit to top 5.
  out.sort((a, b) => a.severity.index.compareTo(b.severity.index));
  return out.take(5).toList();
}

String _fmt(DateTime dt) {
  final local = dt.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$hh:$mm ${local.day}/${local.month}';
}

String _hhmm(DateTime dt) {
  final local = dt.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

class InteractiveWarningsSection extends StatelessWidget {
  const InteractiveWarningsSection({
    super.key,
    required this.warnings,
    required this.onAction,
  });

  final List<CareWarning> warnings;
  final void Function(CareWarning warning) onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (warnings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: VitalisColors.statusSuccessSoft,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_rounded,
                  color: VitalisColors.statusSuccess),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Không có cảnh báo — bệnh nhân đang tuân thủ tốt.',
                  style: text.bodyMedium?.copyWith(
                    color: VitalisColors.statusSuccess,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_rounded,
                  color: VitalisColors.caregiverHeroBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Nhắc việc chăm sóc (${warnings.length})',
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: VitalisColors.caregiverHeroBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final w in warnings) ...[
            _WarningCard(warning: w, onAction: () => onAction(w)),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.warning, required this.onAction});

  final CareWarning warning;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final palette = _paletteFor(warning.severity);

    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      onTap: onAction,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.bg,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: palette.fg.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: palette.fg.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(palette.icon, color: palette.fg, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          warning.title,
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: VitalisColors.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: palette.fg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          palette.label,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    warning.body,
                    style: text.bodySmall?.copyWith(
                      color: VitalisColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      FilledButton.tonal(
                        onPressed: onAction,
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.fg,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              warning.actionLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded, size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _WarningPalette _paletteFor(WarningSeverity s) {
    switch (s) {
      case WarningSeverity.critical:
        return const _WarningPalette(
          bg: Color(0xFFFFEBEE),
          fg: VitalisColors.statusError,
          icon: Icons.error_rounded,
          label: 'KHẨN',
        );
      case WarningSeverity.warning:
        return const _WarningPalette(
          bg: Color(0xFFFFF3E0),
          fg: Color(0xFFBF5A00),
          icon: Icons.warning_amber_rounded,
          label: 'CHÚ Ý',
        );
      case WarningSeverity.info:
        return const _WarningPalette(
          bg: Color(0xFFE3F2FD),
          fg: VitalisColors.chipDateForeground,
          icon: Icons.info_rounded,
          label: 'GỢI Ý',
        );
    }
  }
}

class _WarningPalette {
  const _WarningPalette({
    required this.bg,
    required this.fg,
    required this.icon,
    required this.label,
  });

  final Color bg;
  final Color fg;
  final IconData icon;
  final String label;
}
