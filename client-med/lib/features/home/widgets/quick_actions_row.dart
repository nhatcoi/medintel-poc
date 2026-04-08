import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vitalis_colors.dart';

/// Hai ô nhanh: Quét đơn thuốc + AI Chat.
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
          Text(
            'THAO TÁC NHANH',
            style: text.labelMedium?.copyWith(
              color: VitalisColors.neutral,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.document_scanner_outlined,
                  label: 'Quét đơn thuốc',
                  subtitle: 'OCR & lưu tự động',
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A56C5), Color(0xFF3D7FC8)],
                  ),
                  onTap: onScanTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionTile(
                  icon: Icons.smart_toy_rounded,
                  label: 'AI Tư vấn',
                  subtitle: 'Hỏi về thuốc & liều',
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
                  ),
                  onTap: onChatTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.medication_outlined,
                  label: 'Quản lý thuốc',
                  subtitle: 'Thêm/Sửa danh sách',
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
                  ),
                  onTap: onMedicationTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionTile(
                  icon: Icons.alarm_on_outlined,
                  label: 'Nhắc uống',
                  subtitle: 'Xác nhận đã uống',
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                  ),
                  onTap: onReminderTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 16),
                Text(
                  label,
                  style: text.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: text.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.80),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
