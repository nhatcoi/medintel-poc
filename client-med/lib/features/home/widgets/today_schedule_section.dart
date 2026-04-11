import 'package:flutter/material.dart';

import '../../../core/theme/vitalis_colors.dart';
import '../data/home_ui_model.dart';

/// Danh sách thuốc hôm nay — không divider, khoảng cách dọc phân tầng.
class TodayScheduleSection extends StatelessWidget {
  const TodayScheduleSection({
    super.key,
    required this.items,
    this.onViewCalendarTap,
    this.onMarkTakenTap,
    this.onRescheduleTap,
  });

  final List<HomeDoseItem> items;
  final VoidCallback? onViewCalendarTap;
  final VoidCallback? onMarkTakenTap;
  final VoidCallback? onRescheduleTap;

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
                    color: VitalisColors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onViewCalendarTap,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.calendar_month_outlined, size: 16),
                label: Text(
                  'View Calendar',
                  style: text.labelMedium?.copyWith(
                    color: VitalisColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => _DoseItemTile(
              item: item,
              onMarkTakenTap: onMarkTakenTap,
              onRescheduleTap: onRescheduleTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoseItemTile extends StatelessWidget {
  const _DoseItemTile({
    required this.item,
    this.onMarkTakenTap,
    this.onRescheduleTap,
  });

  final HomeDoseItem item;
  final VoidCallback? onMarkTakenTap;
  final VoidCallback? onRescheduleTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (bgColor, iconColor, statusText, statusColor, detailText) = _statusTokens(item.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D333A).withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Icon(item.icon, size: 18, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.dosageLabel,
                          style: text.bodySmall?.copyWith(color: VitalisColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        statusText,
                        style: text.labelMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        detailText,
                        style: text.labelSmall?.copyWith(color: VitalisColors.neutral),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildAction(context, item.status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context, HomeDoseStatus status) {
    switch (status) {
      case HomeDoseStatus.taken:
        return SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: null,
            child: const Text('Already Recorded'),
          ),
        );
      case HomeDoseStatus.upcoming:
        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onMarkTakenTap,
            child: const Text('Mark as Taken'),
          ),
        );
      case HomeDoseStatus.missed:
        return Row(
          children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed: onRescheduleTap,
                child: const Text('Reschedule'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.tonal(
                onPressed: onMarkTakenTap,
                child: const Text('Mark Taken'),
              ),
            ),
          ],
        );
    }
  }

  (Color bg, Color icon, String status, Color statusColor, String detail) _statusTokens(
    HomeDoseStatus status,
  ) {
    return switch (status) {
      HomeDoseStatus.taken => (
          const Color(0xFFE7F5EB),
          VitalisColors.statusSuccess,
          'TAKEN',
          VitalisColors.statusSuccess,
          item.timeLabel,
        ),
      HomeDoseStatus.missed => (
          const Color(0xFFFCEAEA),
          VitalisColors.statusError,
          'MISSED',
          VitalisColors.statusError,
          'Hôm qua',
        ),
      HomeDoseStatus.upcoming => (
          const Color(0xFFE7F0FD),
          VitalisColors.primary,
          'UPCOMING',
          VitalisColors.primary,
          item.timeLabel,
        ),
    };
  }
}
