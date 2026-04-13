import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/vitalis_colors.dart';
import 'nav_slot_metrics.dart';

/// Bottom bar full-width: vòng primary **căn giữa** cùng hàng icon; chỉ trượt **ngang** khi đổi tab.
class SlidingCircleNavBar extends StatelessWidget {
  const SlidingCircleNavBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  /// Chiều cao thanh (không gồm inset đáy thiết bị).
  static const double layoutHeight = _barHeight;

  static const double _barHeight = 80;
  static const double _highlightDiameter = 64;
  static const double _topCornerRadius = 44;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final stackH = _barHeight + bottomInset;

    return SizedBox(
      height: stackH,
      child: LayoutBuilder(
        builder: (context, c) {
          final m = NavSlotMetrics(width: c.maxWidth);
          final highlightLeft = m.centerXForIndex(currentIndex) - _highlightDiameter / 2;
          // Căn dọc tâm vòng = tâm vùng hàng tab (cùng band với HOME, SCAN, …)
          final rowTop = stackH - bottomInset - _barHeight;
          final circleTop = rowTop + _barHeight / 2 - _highlightDiameter / 2;

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _barHeight + bottomInset,
                child: Material(
                  elevation: 18,
                  shadowColor: VitalisColors.onSurface.withValues(alpha: 0.12),
                  color: VitalisColors.surfaceContainerLowest,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(_topCornerRadius),
                    topRight: Radius.circular(_topCornerRadius),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: const SizedBox.expand(),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: highlightLeft,
                top: circleTop,
                child: const _NavCircleHighlight(diameter: _highlightDiameter),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomInset,
                height: _barHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: _NavEntry(
                        icon: LucideIcons.clock,
                        selected: currentIndex == 0,
                        onTap: () => onDestinationSelected(0),
                      ),
                    ),
                    Expanded(
                      child: _NavEntry(
                        icon: LucideIcons.pill,
                        selected: currentIndex == 1,
                        onTap: () => onDestinationSelected(1),
                      ),
                    ),
                    Expanded(
                      child: _NavEntry(
                        icon: LucideIcons.layoutGrid,
                        selected: currentIndex == 2,
                        onTap: () => onDestinationSelected(2),
                      ),
                    ),
                    Expanded(
                      child: _NavEntry(
                        icon: LucideIcons.clipboardList,
                        selected: currentIndex == 3,
                        onTap: () => onDestinationSelected(3),
                      ),
                    ),
                    Expanded(
                      child: _NavEntry(
                        icon: LucideIcons.user,
                        selected: currentIndex == 4,
                        onTap: () => onDestinationSelected(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NavCircleHighlight extends StatelessWidget {
  const _NavCircleHighlight({required this.diameter});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              VitalisColors.primary,
              VitalisColors.primaryContainer,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: VitalisColors.primary.withValues(alpha: 0.42),
              blurRadius: 20,
              spreadRadius: -2,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: VitalisColors.primaryContainer.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavEntry extends StatelessWidget {
  const _NavEntry({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? Colors.white : VitalisColors.navBarInactive;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: selected ? 26 : 24, color: iconColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
