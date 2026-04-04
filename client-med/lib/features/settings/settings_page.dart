import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/display_fonts.dart';
import '../../core/theme/vitalis_colors.dart';
import '../../providers/display_preferences_provider.dart';

/// Cài đặt hiển thị: font + cỡ chữ (áp dụng toàn app).
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(displayPreferencesProvider);
    final notifier = ref.read(displayPreferencesProvider.notifier);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Hiển thị',
            style: text.titleMedium?.copyWith(
              color: VitalisColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Font và cỡ chữ áp dụng cho toàn bộ ứng dụng.',
            style: text.bodyMedium?.copyWith(color: VitalisColors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Text('Font chữ', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...DisplayFontIds.choices.map(
            (c) {
              final selected = prefs.fontId == c.id;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(c.label, style: text.bodyLarge),
                trailing: Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? VitalisColors.primary : VitalisColors.outlineGhost,
                ),
                selected: selected,
                onTap: () => notifier.setFontId(c.id),
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Cỡ chữ', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            '${(prefs.textScale * 100).round()}%',
            style: text.bodySmall?.copyWith(color: VitalisColors.onSurfaceVariant),
          ),
          Slider(
            value: prefs.textScale,
            min: DisplayPreferencesState.minTextScale,
            max: DisplayPreferencesState.maxTextScale,
            divisions: 10,
            label: '${(prefs.textScale * 100).round()}%',
            onChanged: (v) => notifier.setTextScale(v),
          ),
          const SizedBox(height: 24),
          Text('Xem trước', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MedIntel', style: text.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Đây là đoạn văn mẫu để bạn chỉnh font và cỡ chữ cho dễ đọc hơn.',
                    style: text.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
