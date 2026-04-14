import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

import '../../core/theme/display_fonts.dart';
import '../../core/theme/vitalis_colors.dart';
import '../../providers/display_preferences_provider.dart';
import '../../providers/locale_preferences_provider.dart';
import '../../providers/local_medintel_provider.dart';
import '../../providers/shared_preferences_provider.dart';
import '../../providers/providers.dart';
import 'widgets/local_data_json_panel.dart';

/// Cài đặt hiển thị: font + cỡ chữ (áp dụng toàn app).
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _clearAllData(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(l10n.settingsDeleteAllTitle),
          content: Text(l10n.settingsDeleteAllBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.genericCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.settingsDeleteData),
            ),
          ],
        );
      },
    );
    if (shouldDelete != true || !context.mounted) return;

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs?.clear();
    await ref.read(authProvider.notifier).logout();
    ref.invalidate(localMedintelProvider);
    ref.invalidate(displayPreferencesProvider);
    ref.invalidate(appLocaleProvider);

    if (context.mounted) {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final prefs = ref.watch(displayPreferencesProvider);
    final notifier = ref.read(displayPreferencesProvider.notifier);
    final appLocale = ref.watch(appLocaleProvider);
    final localeNotifier = ref.read(appLocaleProvider.notifier);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            l10n.settingsDisplaySection,
            style: text.titleMedium?.copyWith(
              color: VitalisColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.settingsDisplaySubtitle,
            style: text.bodyMedium?.copyWith(color: VitalisColors.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.settingsLanguageSection,
            style: text.titleMedium?.copyWith(
              color: VitalisColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.settingsLanguageSubtitle,
            style: text.bodyMedium?.copyWith(color: VitalisColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: [
              ButtonSegment<String>(
                value: AppLocaleNotifier.vi,
                label: Text(l10n.settingsLanguageVi),
                icon: const Icon(Icons.language_rounded, size: 18),
              ),
              ButtonSegment<String>(
                value: AppLocaleNotifier.en,
                label: Text(l10n.settingsLanguageEn),
                icon: const Icon(Icons.translate_rounded, size: 18),
              ),
            ],
            selected: {appLocale},
            onSelectionChanged: (next) {
              final v = next.first;
              localeNotifier.setLanguageCode(v);
            },
          ),
          const SizedBox(height: 24),
          Text(l10n.settingsFont, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
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
          Text(l10n.settingsTextScale, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
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
          Text(l10n.settingsPreview, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.appTitle, style: text.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    l10n.settingsPreviewSample,
                    style: text.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.settingsDebugSection,
            style: text.titleMedium?.copyWith(
              color: VitalisColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.settingsDebugSubtitle,
            style: text.bodyMedium?.copyWith(color: VitalisColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          const LocalDataJsonPanel(refreshInterval: Duration(seconds: 5)),
          const SizedBox(height: 16),
          Text(
            'Dữ liệu y tế',
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.description_outlined),
            title: const Text('Hồ sơ bệnh án'),
            subtitle: const Text('Xem dữ liệu từ /api/v1/medical-records/'),
            onTap: () => context.push('/medical-records'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.psychology_outlined),
            title: const Text('Memory'),
            subtitle: const Text('Xem/thêm dữ liệu từ /api/v1/memory/'),
            onTap: () => context.push('/memory'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _clearAllData(context, ref),
            icon: const Icon(Icons.delete_forever_outlined),
            label: Text(l10n.settingsClearLocalData),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}
