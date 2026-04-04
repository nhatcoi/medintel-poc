import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vitalis_colors.dart';

/// Bottom bar: Home, Scan, AI, History + nút CARE nổi bật (mock).
class CaregiverBottomNav extends StatelessWidget {
  const CaregiverBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  static const int indexCare = 4;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Material(
      elevation: 12,
      shadowColor: VitalisColors.onSurface.withValues(alpha: 0.08),
      color: VitalisColors.surfaceContainerLowest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: currentIndex == 0,
                  onTap: () => onSelect(0),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.document_scanner_outlined,
                  label: 'Scan',
                  selected: currentIndex == 1,
                  onTap: () => onSelect(1),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.smart_toy_outlined,
                  label: 'AI Chat',
                  selected: currentIndex == 2,
                  onTap: () => onSelect(2),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.history_rounded,
                  label: 'History',
                  selected: currentIndex == 3,
                  onTap: () => onSelect(3),
                ),
              ),
              const SizedBox(width: 6),
              _CarePill(
                onTap: () => onSelect(indexCare),
                textStyle: text,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? VitalisColors.primary : VitalisColors.neutral;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarePill extends StatelessWidget {
  const _CarePill({
    required this.onTap,
    required this.textStyle,
  });

  final VoidCallback onTap;
  final TextTheme textStyle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VitalisColors.primary,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: SizedBox(
          width: 72,
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people_alt_rounded, color: Colors.white, size: 22),
              const SizedBox(height: 2),
              Text(
                'CARE',
                style: textStyle.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
