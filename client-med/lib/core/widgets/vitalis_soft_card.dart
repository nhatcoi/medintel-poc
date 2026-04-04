import 'package:flutter/material.dart';

import '../theme/vitalis_colors.dart';
import '../theme/app_theme.dart';

/// Thẻ “daily summary” — bo `xl`, không elevation; phân tầng bằng màu nền.
class VitalisSoftCard extends StatelessWidget {
  const VitalisSoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? VitalisColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: VitalisColors.ambientFloating,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
