import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vitalis_colors.dart';
import '../../treatment/data/treatment_models.dart';

/// COM-B behavioural scoring (Michie et al., 2011).
///
/// B (behaviour = adherence) = f(Capability, Opportunity, Motivation).
/// Each dimension is normalised to 0–100 so caregivers can see which lever
/// to pull rather than only a single compliance %.
class ComBScore {
  const ComBScore({
    required this.capability,
    required this.opportunity,
    required this.motivation,
    required this.behaviour,
    required this.primaryGap,
  });

  final double capability;
  final double opportunity;
  final double motivation;
  final double behaviour;

  /// Name of the weakest dimension — used to drive the recommendation text.
  final String primaryGap;
}

ComBScore computeComBScore({
  required List<MedicationItem> meds,
  required List<MedicationScheduleItem> schedules,
  required List<MedicationLogItem> logs,
  required List<MissedDoseItem> missedDoses,
  AdherenceSummary? summary7,
}) {
  final totalMeds = meds.length;

  // ---- Capability: does the patient HAVE what they need to act? ----
  // Proxies: every active med has a schedule configured, and has inventory
  // information (so they know when/how much to take).
  final activeMeds = meds
      .where((m) => (m.status ?? 'active').toLowerCase() == 'active')
      .toList();
  final scheduledMedIds = schedules.map((s) => s.medicationId).toSet();
  final withSchedule =
      activeMeds.where((m) => scheduledMedIds.contains(m.medicationId)).length;
  final withInventory =
      activeMeds.where((m) => m.remainingQuantity != null).length;
  double capability;
  if (activeMeds.isEmpty) {
    capability = 0;
  } else {
    final schedRatio = withSchedule / activeMeds.length;
    final invRatio = withInventory / activeMeds.length;
    capability = (schedRatio * 0.7 + invRatio * 0.3) * 100;
  }

  // ---- Opportunity: is the environment allowing on-time behaviour? ----
  // Proxies: on-time rate from adherence summary, penalised by low-stock
  // meds (no supply = no opportunity) and by overdue missed doses right now.
  final lowStock = activeMeds
      .where((m) =>
          m.remainingQuantity != null && (m.remainingQuantity ?? 0) <= 5)
      .length;
  final lowStockPenalty =
      activeMeds.isEmpty ? 0.0 : (lowStock / activeMeds.length) * 30.0;
  final missedNowPenalty = (missedDoses.length * 6).clamp(0, 30).toDouble();
  final onTimeBase = (summary7?.onTimeRate ?? 0) * 100;
  final opportunity =
      (onTimeBase - lowStockPenalty - missedNowPenalty).clamp(0.0, 100.0);

  // ---- Motivation: is the patient choosing to act when able? ----
  // Proxies: 7-day compliance rate + recent streak of 'taken' logs, with a
  // penalty for consecutive missed/skipped events (demotivation signal).
  final sortedLogs = [...logs]
    ..sort((a, b) => b.scheduledDatetime.compareTo(a.scheduledDatetime));
  int streakTaken = 0;
  int streakBroken = 0;
  for (final log in sortedLogs.take(10)) {
    final s = log.status.toLowerCase();
    if (s == 'taken' || s == 'late') {
      if (streakBroken == 0) streakTaken++;
    } else if (s == 'missed' || s == 'skipped') {
      streakBroken++;
      if (streakTaken == 0) continue;
    }
  }
  final complianceBase = (summary7?.complianceRate ?? 0) * 100;
  final streakBonus = (streakTaken * 2).clamp(0, 10).toDouble();
  final streakPenalty = (streakBroken * 3).clamp(0, 15).toDouble();
  final motivation =
      (complianceBase + streakBonus - streakPenalty).clamp(0.0, 100.0);

  // Weighted behaviour score (compliance-weighted; COM-B treats all 3 as
  // necessary, so we use a harmonic-style floor on the minimum).
  final minDim = [capability, opportunity, motivation].reduce((a, b) => a < b ? a : b);
  final avgDim = (capability + opportunity + motivation) / 3;
  final behaviour = (avgDim * 0.7 + minDim * 0.3);

  String gap;
  if (capability <= opportunity && capability <= motivation) {
    gap = 'capability';
  } else if (opportunity <= motivation) {
    gap = 'opportunity';
  } else {
    gap = 'motivation';
  }
  if (totalMeds == 0) gap = 'none';

  return ComBScore(
    capability: capability,
    opportunity: opportunity,
    motivation: motivation,
    behaviour: behaviour,
    primaryGap: gap,
  );
}

class ComBInsightCard extends StatelessWidget {
  const ComBInsightCard({super.key, required this.score});

  final ComBScore score;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final recommendation = _recommendationFor(score.primaryGap);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VitalisColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: VitalisColors.ambientFloating,
          border: Border.all(
            color: VitalisColors.primary.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: VitalisColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.psychology_alt_rounded,
                      size: 18, color: VitalisColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phân tích hành vi COM-B',
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: VitalisColors.caregiverHeroBlue,
                        ),
                      ),
                      Text(
                        'Capability · Opportunity · Motivation',
                        style: text.bodySmall?.copyWith(
                          color: VitalisColors.onSurfaceVariant,
                          fontSize: 11,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                _BehaviourBadge(value: score.behaviour),
              ],
            ),
            const SizedBox(height: 14),
            _ComBBar(
              label: 'Năng lực (Capability)',
              hint: 'Lịch uống & thông tin tồn kho đã sẵn sàng?',
              value: score.capability,
              color: const Color(0xFF1565C0),
            ),
            const SizedBox(height: 10),
            _ComBBar(
              label: 'Cơ hội (Opportunity)',
              hint: 'Thuốc có sẵn, không lỡ giờ, môi trường thuận lợi?',
              value: score.opportunity,
              color: const Color(0xFF00897B),
            ),
            const SizedBox(height: 10),
            _ComBBar(
              label: 'Động lực (Motivation)',
              hint: 'Bệnh nhân duy trì chuỗi uống thuốc đều đặn?',
              value: score.motivation,
              color: const Color(0xFFD84315),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: VitalisColors.chipDateBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tips_and_updates_rounded,
                      size: 16, color: VitalisColors.chipDateForeground),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: text.bodySmall?.copyWith(
                        color: VitalisColors.chipDateForeground,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _recommendationFor(String gap) {
    switch (gap) {
      case 'capability':
        return 'Gợi ý khoa học: Củng cố Năng lực — hoàn thiện lịch uống và cập nhật tồn kho cho từng thuốc để bệnh nhân biết rõ "khi nào / bao nhiêu".';
      case 'opportunity':
        return 'Gợi ý khoa học: Mở rộng Cơ hội — bổ sung thuốc sắp hết, đặt nhắc giờ rõ ràng, nhờ người thân hỗ trợ ở các khung giờ dễ quên.';
      case 'motivation':
        return 'Gợi ý khoa học: Tăng Động lực — phản hồi tích cực khi bệnh nhân uống đúng, ghi nhận chuỗi ngày liên tục, thảo luận rào cản qua AI Chat.';
      case 'none':
        return 'Chưa đủ dữ liệu: hãy thêm thuốc và lịch uống để hệ thống phân tích hành vi.';
      default:
        return 'Duy trì thói quen hiện tại. Nhắc nhở nhẹ nhàng và theo dõi xu hướng 30 ngày.';
    }
  }
}

class _ComBBar extends StatelessWidget {
  const _ComBBar({
    required this.label,
    required this.hint,
    required this.value,
    required this.color,
  });

  final String label;
  final String hint;
  final double value; // 0-100
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final pct = value.clamp(0, 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: text.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: VitalisColors.onSurface,
                ),
              ),
            ),
            Text(
              '$pct',
              style: text.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          hint,
          style: text.bodySmall?.copyWith(
            color: VitalisColors.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: (value.clamp(0, 100)) / 100,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _BehaviourBadge extends StatelessWidget {
  const _BehaviourBadge({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final pct = value.clamp(0, 100).round();
    Color bg;
    Color fg;
    String label;
    if (pct >= 80) {
      bg = VitalisColors.statusSuccessSoft;
      fg = VitalisColors.statusSuccess;
      label = 'Tốt';
    } else if (pct >= 50) {
      bg = const Color(0xFFFFF3E0);
      fg = const Color(0xFFBF5A00);
      label = 'Trung bình';
    } else {
      bg = VitalisColors.statusErrorSoft;
      fg = VitalisColors.statusError;
      label = 'Cần chú ý';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$pct',
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              height: 1,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
