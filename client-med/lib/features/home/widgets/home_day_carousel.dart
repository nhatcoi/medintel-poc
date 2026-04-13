import 'package:flutter/material.dart';

const _dayNames = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

class HomeDayCarousel extends StatelessWidget {
  const HomeDayCarousel({
    super.key,
    required this.controller,
    required this.totalDays,
    required this.dayAt,
    required this.selectedDate,
    required this.today,
    required this.dayItemWidth,
    required this.onSelect,
  });

  final ScrollController controller;
  final int totalDays;
  final DateTime Function(int index) dayAt;
  final DateTime selectedDate;
  final DateTime today;
  final double dayItemWidth;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: SizedBox(
        height: 72,
        child: ListView.builder(
          controller: controller,
          scrollDirection: Axis.horizontal,
          itemCount: totalDays,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemBuilder: (_, i) {
            final date = dayAt(i);
            return _DayChip(
              date: date,
              isSelected: date == selectedDate,
              isToday: date == today,
              width: dayItemWidth,
              onTap: () => onSelect(date),
            );
          },
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.width,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _dayNames[date.weekday % 7],
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: isSelected ? 42 : 36,
              height: isSelected ? 42 : 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? scheme.primary : Colors.transparent,
                border: isToday && !isSelected
                    ? Border.all(color: scheme.primary.withValues(alpha: 0.4), width: 1.5)
                    : null,
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
