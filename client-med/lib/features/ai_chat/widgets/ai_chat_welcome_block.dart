import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/vitalis_colors.dart';
import '../../../providers/providers.dart';

class AiChatWelcomeBlock extends ConsumerWidget {
  const AiChatWelcomeBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final auth = ref.watch(authProvider);
    final name = auth.user?.fullName?.trim().isNotEmpty == true
        ? auth.user!.fullName!.trim()
        : 'Bạn';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
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
                  color: VitalisColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            'Xin chào, $name',
            textAlign: TextAlign.center,
            style: text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: VitalisColors.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Trợ lý agent: có thể ghi nhận uống thuốc, thêm thuốc, ghi chú — '
            'lưu ngay trên máy bạn (đồng bộ đám mây sẽ làm sau nếu bạn bật).',
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(
              color: VitalisColors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
