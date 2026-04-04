import 'package:flutter/material.dart';

import '../theme/vitalis_colors.dart';
import '../theme/app_theme.dart';

/// CTA chính — gradient `primary` → `primaryContainer` (DESIGN.md §2, §5).
class VitalisPrimaryGradientButton extends StatelessWidget {
  const VitalisPrimaryGradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd * 2),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd * 2),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                VitalisColors.primary,
                VitalisColors.primaryContainer,
              ],
            ),
            boxShadow: onPressed != null ? VitalisColors.ambientFloating : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.buttonVerticalPadding,
              horizontal: 28,
            ),
            child: DefaultTextStyle.merge(
              style: style,
              child: IconTheme.merge(
                data: const IconThemeData(color: Colors.white, size: 22),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon),
                      const SizedBox(width: 10),
                    ],
                    Text(label),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
