import 'package:flutter/material.dart';

import '../../../core/theme/vitalis_colors.dart';

/// Hành động nhanh kiểu clean medical.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({
    super.key,
    this.onScanTap,
    this.onChatTap,
    this.onMedicationTap,
    this.onReminderTap,
  });

  final VoidCallback? onScanTap;
  final VoidCallback? onChatTap;
  final VoidCallback? onMedicationTap;
  final VoidCallback? onReminderTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onScanTap,
              child: Ink(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCECF7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.document_scanner_outlined, color: VitalisColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scan New Prescription',
                            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Add new meds with AI scanning',
                            style: text.bodySmall?.copyWith(color: VitalisColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: VitalisColors.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniActionChip(label: 'AI Chat', icon: Icons.smart_toy_outlined, onTap: onChatTap),
              _MiniActionChip(label: 'Medication', icon: Icons.medication_outlined, onTap: onMedicationTap),
              _MiniActionChip(label: 'Reminder', icon: Icons.alarm_on_outlined, onTap: onReminderTap),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniActionChip extends StatelessWidget {
  const _MiniActionChip({required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFFE9EEF5),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: VitalisColors.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: VitalisColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
