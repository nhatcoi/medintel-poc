import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

void showHomeQuickActionsSheet(
  BuildContext context, {
  required VoidCallback onTapAddMedication,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      final maxHeight = MediaQuery.sizeOf(ctx).height * 0.78;
      return SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Theme.of(ctx).colorScheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Thêm mới & Tra cứu',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _QuickActionTile(
                    icon: LucideIcons.pill,
                    title: 'Thêm thuốc',
                    subtitle: 'Thêm thuốc mới vào tủ',
                    onTap: () {
                      Navigator.of(ctx).pop();
                      onTapAddMedication();
                    },
                  ),
                  _QuickActionTile(
                    icon: LucideIcons.search,
                    title: 'Tra cứu thuốc',
                    subtitle: 'Thông tin, liều dùng, tác dụng phụ',
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.go('/ai');
                    },
                  ),
                  _QuickActionTile(
                    icon: LucideIcons.scanLine,
                    title: 'Trích xuất từ hóa đơn',
                    subtitle: 'Quét bằng AI (camera)',
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.go('/scan');
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Hủy bỏ'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(LucideIcons.chevronRight, size: 18),
      ),
    );
  }
}
