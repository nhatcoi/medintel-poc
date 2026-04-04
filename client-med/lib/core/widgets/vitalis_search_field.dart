import 'package:flutter/material.dart';

import '../theme/vitalis_colors.dart';
import '../theme/app_theme.dart';

/// Thanh tìm kiếm kiểu kit — nền surface-container-low, bo tròn, không viền đặc.
class VitalisSearchField extends StatelessWidget {
  const VitalisSearchField({
    super.key,
    this.controller,
    this.hintText = 'Search',
    this.onChanged,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: VitalisColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: theme.textTheme.bodyLarge?.copyWith(color: VitalisColors.neutral),
          prefixIcon: Icon(Icons.search_rounded, color: VitalisColors.neutral.withValues(alpha: 0.85)),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
        ),
      ),
    );
  }
}
