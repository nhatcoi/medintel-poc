import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vitalis_colors.dart';

/// Khi chưa có thuốc cục bộ — hướng dẫn thêm qua quét đơn hoặc AI agent.
class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: VitalisColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: VitalisColors.outlineVariantBase.withValues(alpha: 0.15),
          ),
          boxShadow: VitalisColors.ambientFloating,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.medication_liquid_rounded, size: 40, color: VitalisColors.primary),
              const SizedBox(height: 14),
              Text(
                'Chưa có lịch thuốc',
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: VitalisColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thêm thuốc bằng Quét đơn hoặc nhờ trợ lý AI ghi nhận (lưu trên máy bạn). '
                'Đồng bộ tài khoản sẽ bổ sung sau.',
                style: text.bodyMedium?.copyWith(
                  color: VitalisColors.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => context.goNamed('scan'),
                      icon: const Icon(Icons.document_scanner_outlined, size: 20),
                      label: const Text('Quét đơn'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.goNamed('ai'),
                      icon: const Icon(Icons.smart_toy_outlined, size: 20),
                      label: const Text('AI Chat'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
