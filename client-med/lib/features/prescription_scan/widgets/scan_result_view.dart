import 'package:flutter/material.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

import '../../../core/theme/vitalis_colors.dart';
import '../../../services/ocr_service.dart';

class ScanResultView extends StatelessWidget {
  const ScanResultView({
    super.key,
    required this.result,
    required this.onResultChanged,
  });

  final ScanResult result;
  final ValueSetter<ScanResult> onResultChanged;

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
              _EditableInfoRow(
                icon: Icons.person_outline,
                label: l10n.scanLabelDoctor,
                value: result.doctorName ?? '',
                onChanged: (val) => onResultChanged(result.copyWith(doctorName: val)),
              ),
              const SizedBox(height: 8),
              _EditableInfoRow(
                icon: Icons.badge_outlined,
                label: l10n.scanLabelPatient,
                value: result.patientName ?? '',
                onChanged: (val) => onResultChanged(result.copyWith(patientName: val)),
              ),
              const SizedBox(height: 8),
              _EditableInfoRow(
                icon: Icons.calendar_today_outlined,
                label: l10n.scanLabelDate,
                value: result.issuedDate ?? '',
                onChanged: (val) => onResultChanged(result.copyWith(issuedDate: val)),
              ),
            ],
          ),
        ),

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
          ...meds.asMap().entries.map((entry) {
            final idx = entry.key;
            final m = entry.value;
            return Padding(
              padding: EdgeInsets.only(top: idx > 0 ? 12 : 0),
              child: _MedicationCard(
                med: m,
                index: idx + 1,
                schedulePrefix: l10n.scanSchedulePrefix,
                onChanged: (updatedMed) {
                  final newMeds = List<ScannedMedication>.from(result.medications);
                  newMeds[idx] = updatedMed;
                  onResultChanged(result.copyWith(medications: newMeds));
                },
                onRemove: () {
                  final newMeds = List<ScannedMedication>.from(result.medications);
                  newMeds.removeAt(idx);
                  onResultChanged(result.copyWith(medications: newMeds));
                },
              ),
            );
          }),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: () {
              final newMeds = List<ScannedMedication>.from(result.medications);
              newMeds.add(const ScannedMedication(name: ''));
              onResultChanged(result.copyWith(medications: newMeds));
            },
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text('Thêm thuốc thủ công'),
            style: TextButton.styleFrom(foregroundColor: VitalisColors.primary),
          ),
        ),
      ],
    );
  }
}

class _EditableInfoRow extends StatelessWidget {
  const _EditableInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: VitalisColors.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: VitalisColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _showEditDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: VitalisColors.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value.isEmpty ? 'Chưa rõ' : value,
                      style: TextStyle(
                        fontSize: 13,
                        color: value.isEmpty ? VitalisColors.onSurfaceVariant.withValues(alpha: 0.5) : VitalisColors.onSurface,
                        fontWeight: FontWeight.w600,
                        fontStyle: value.isEmpty ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ),
                  const Icon(Icons.edit_outlined, size: 12, color: VitalisColors.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: value);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sửa $label'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Nhập $label',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              onChanged(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.med,
    required this.index,
    required this.schedulePrefix,
    required this.onChanged,
    required this.onRemove,
  });

  final ScannedMedication med;
  final int index;
  final String schedulePrefix;
  final ValueChanged<ScannedMedication> onChanged;
  final VoidCallback onRemove;

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
                child: InkWell(
                  onTap: () => _showEditMedDialog(context),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          med.name.isEmpty ? 'Tên thuốc...' : med.name,
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: med.name.isEmpty ? VitalisColors.onSurfaceVariant.withValues(alpha: 0.5) : VitalisColors.onSurface,
                          ),
                        ),
                      ),
                      const Icon(Icons.edit_outlined, size: 16, color: VitalisColors.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, color: VitalisColors.statusError, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Details
          _EditableDetailChip(
            icon: Icons.medication_outlined,
            text: med.dosage ?? '',
            hint: 'Liều dùng (VD: 1 viên)',
            onChanged: (val) => onChanged(med.copyWith(dosage: val)),
          ),
          _EditableDetailChip(
            icon: Icons.repeat_rounded,
            text: med.frequency ?? '',
            hint: 'Tần suất (VD: 2 lần/ngày)',
            onChanged: (val) => onChanged(med.copyWith(frequency: val)),
          ),
          _EditableDetailChip(
            icon: Icons.info_outline,
            text: med.instructions ?? '',
            hint: 'Ghi chú (VD: Sau ăn)',
            onChanged: (val) => onChanged(med.copyWith(instructions: val)),
          ),

          // Schedule times
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _showTimesEditDialog(context),
            child: Container(
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
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: VitalisColors.primary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      med.times.isEmpty ? 'Chưa đặt giờ' : med.times.join('  ·  '),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: VitalisColors.primary,
                      ),
                    ),
                  ),
                  const Icon(Icons.edit_outlined, size: 14, color: VitalisColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditMedDialog(BuildContext context) {
    final controller = TextEditingController(text: med.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa tên thuốc'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Nhập tên thuốc',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              onChanged(med.copyWith(name: controller.text));
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showTimesEditDialog(BuildContext context) {
    final controller = TextEditingController(text: med.times.join(', '));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa giờ uống'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'VD: 08:00, 20:00',
                helperText: 'Các giờ cách nhau bởi dấu phẩy',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              final newTimes = controller.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              onChanged(med.copyWith(times: newTimes));
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}

class _EditableDetailChip extends StatelessWidget {
  const _EditableDetailChip({
    required this.icon,
    required this.text,
    required this.hint,
    required this.onChanged,
  });

  final IconData icon;
  final String text;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showEditDialog(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 15, color: VitalisColors.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text.isEmpty ? hint : text,
                  style: TextStyle(
                    fontSize: 13,
                    color: text.isEmpty ? VitalisColors.onSurfaceVariant.withValues(alpha: 0.5) : VitalisColors.onSurfaceVariant,
                    fontStyle: text.isEmpty ? FontStyle.italic : FontStyle.normal,
                    height: 1.4,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_right, size: 16, color: VitalisColors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sửa ${hint.split(' (')[0].toLowerCase()}'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
          maxLines: null,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              onChanged(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
