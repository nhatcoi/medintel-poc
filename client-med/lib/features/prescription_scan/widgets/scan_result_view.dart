import 'package:flutter/material.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

import '../../../core/theme/vitalis_colors.dart';
import '../../../services/ocr_service.dart';

class ScanResultView extends StatelessWidget {
  const ScanResultView({super.key, required this.result});

  final ScanResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final meds = result.medications;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: VitalisColors.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: VitalisColors.tertiary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.scanResultTitle,
              style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: VitalisColors.onSurface,
              ),
            ),
          ],
        ),
        if (result.prescriptionId != null) ...[
          const SizedBox(height: 10),
          Text(
            l10n.scanResultSaved(result.savedMedications.length),
            style: text.labelLarge?.copyWith(
              color: VitalisColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],

        // Doctor & patient info
        if (result.doctorName != null || result.patientName != null) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: VitalisColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: VitalisColors.outlineVariantBase.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result.doctorName != null)
                  _InfoRow(icon: Icons.person_outline, label: l10n.scanLabelDoctor, value: result.doctorName!),
                if (result.patientName != null) ...[
                  if (result.doctorName != null) const SizedBox(height: 6),
                  _InfoRow(icon: Icons.badge_outlined, label: l10n.scanLabelPatient, value: result.patientName!),
                ],
                if (result.issuedDate != null) ...[
                  const SizedBox(height: 6),
                  _InfoRow(icon: Icons.calendar_today_outlined, label: l10n.scanLabelDate, value: result.issuedDate!),
                ],
              ],
            ),
          ),
        ],

        // Medications
        const SizedBox(height: 18),
        Text(
          l10n.scanMedsDetected(meds.length),
          style: text.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: VitalisColors.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        if (meds.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFF9A825), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.scanNoMedsFound,
                    style: const TextStyle(color: Color(0xFF795548), fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else
          ...meds.asMap().entries.map((entry) => Padding(
                padding: EdgeInsets.only(top: entry.key > 0 ? 10 : 0),
                child: _MedicationCard(med: entry.value, index: entry.key + 1, schedulePrefix: l10n.scanSchedulePrefix),
              )),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: VitalisColors.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: VitalisColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: VitalisColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.med,
    required this.index,
    required this.schedulePrefix,
  });

  final ScannedMedication med;
  final int index;
  final String schedulePrefix;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VitalisColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: VitalisColors.outlineVariantBase.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + index badge
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: VitalisColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  med.name,
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: VitalisColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Details
          if (med.dosage != null)
            _DetailChip(icon: Icons.medication_outlined, text: med.dosage!),
          if (med.frequency != null)
            _DetailChip(icon: Icons.repeat_rounded, text: med.frequency!),
          if (med.instructions != null)
            _DetailChip(icon: Icons.info_outline, text: med.instructions!),

          // Schedule times
          if (med.times.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: VitalisColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: VitalisColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    schedulePrefix,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: VitalisColors.primary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      med.times.join('  ·  '),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: VitalisColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: VitalisColors.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: VitalisColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
