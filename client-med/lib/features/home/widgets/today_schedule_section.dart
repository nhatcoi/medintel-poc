import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vitalis_colors.dart';
import '../data/home_demo_data.dart';

/// Danh sách thuốc hôm nay — không divider, khoảng cách dọc phân tầng.
class TodayScheduleSection extends StatelessWidget {
  const TodayScheduleSection({super.key, required this.items});

  final List<HomeDoseItem> items;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'LỊCH THUỐC HÔM NAY',
                  style: text.labelMedium?.copyWith(
                    color: VitalisColors.neutral,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Xem tất cả',
                  style: text.labelMedium?.copyWith(
                    color: VitalisColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _DoseItemTile(item: item)),
        ],
      ),
    );
  }
}

class _DoseItemTile extends StatelessWidget {
  const _DoseItemTile({required this.item});

  final HomeDoseItem item;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (bgColor, iconColor, chipColor, chipText) = _statusTokens(item.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: VitalisColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(item.icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.dosageLabel,
                      style: text.bodySmall?.copyWith(color: VitalisColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.timeLabel,
                    style: text.labelMedium?.copyWith(
                      color: VitalisColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _StatusChip(color: chipColor, label: chipText),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color bg, Color icon, Color chip, String label) _statusTokens(HomeDoseStatus status) {
    return switch (status) {
      HomeDoseStatus.taken => (
          VitalisColors.statusSuccessSoft,
          VitalisColors.statusSuccess,
          VitalisColors.statusSuccess,
          'Đã uống',
        ),
      HomeDoseStatus.missed => (
          VitalisColors.statusErrorSoft,
          VitalisColors.statusError,
          VitalisColors.statusError,
          'Bỏ lỡ',
        ),
      HomeDoseStatus.upcoming => (
          VitalisColors.surfaceContainerLow,
          VitalisColors.statusUpcomingIcon,
          VitalisColors.neutral,
          'Sắp tới',
        ),
    };
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: text.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
