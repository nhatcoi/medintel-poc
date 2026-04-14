import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

import '../../core/theme/ui_tokens.dart';
import '../../providers/providers.dart';
import '../../services/notification_service.dart';
import '../treatment/data/treatment_models.dart';
import '../treatment/data/treatment_provider.dart';
import '../treatment/widgets/treatment_ui.dart';

class ReminderPage extends ConsumerStatefulWidget {
  const ReminderPage({super.key});

  @override
  ConsumerState<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends ConsumerState<ReminderPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null || profileId.isEmpty) return;
    await ref.read(treatmentProvider.notifier).loadMedications(profileId);
  }

  Future<void> _log(MedicationItem med, String status) async {
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null || profileId.isEmpty) return;
    await ref.read(treatmentProvider.notifier).logDose(
          profileId: profileId,
          medicationId: med.medicationId,
          status: status,
        );
    if (mounted) {
      final l10n = AppLocalizations.of(context);
      final msg = switch (status) {
        'taken' => l10n.reminderLoggedTaken(med.name),
        'late' => l10n.reminderLoggedLate(med.name),
        'missed' => l10n.reminderLoggedMissed(med.name),
        _ => l10n.reminderLoggedGeneric(med.name, status),
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<void> _bulkLog(String status) async {
    final profileId = ref.read(activeProfileIdProvider);
    final meds = ref.read(treatmentProvider).items;
    if (profileId == null || profileId.isEmpty || meds.isEmpty) return;

    var ok = 0;
    var fail = 0;
    for (final med in meds) {
      try {
        await ref.read(treatmentProvider.notifier).logDose(
              profileId: profileId,
              medicationId: med.medicationId,
              status: status,
            );
        ok += 1;
      } catch (_) {
        fail += 1;
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã cập nhật $ok thuốc${fail > 0 ? ', lỗi $fail' : ''}.',
        ),
      ),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(treatmentProvider);
    final reminderCount = state.items.where((m) => m.scheduleTimes.isNotEmpty).length;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reminderTitle),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Cập nhật hàng loạt',
            onSelected: _bulkLog,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'taken', child: Text('Đánh dấu tất cả: Đã uống')),
              PopupMenuItem(value: 'late', child: Text('Đánh dấu tất cả: Muộn')),
              PopupMenuItem(value: 'missed', child: Text('Đánh dấu tất cả: Bỏ lỡ')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          children: [
            TreatmentHeaderCard(
              title: l10n.reminderHeaderTitle,
              subtitle: l10n.reminderHeaderSubtitle,
              value: '$reminderCount',
              icon: Icons.alarm_on_outlined,
            ),
            if (state.loading) const LinearProgressIndicator(),
            if (state.error != null) TreatmentErrorBanner(message: state.error!, onRetry: _reload),
            if (state.items.isEmpty)
              TreatmentEmptyCard(
                icon: Icons.notifications_paused_outlined,
                title: l10n.reminderEmptyTitle,
                description: l10n.reminderEmptyDescription,
              ),
            for (final med in state.items)
              Card(
                margin: const EdgeInsets.fromLTRB(
                  UiTokens.pagePadding,
                  UiTokens.chipGap,
                  UiTokens.pagePadding,
                  4,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              med.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          TreatmentInfoChip(
                            label: med.scheduleTimes.isEmpty ? l10n.reminderScheduleFlexible : l10n.reminderScheduleFixed,
                            icon: Icons.schedule_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: UiTokens.sectionGap),
                      Wrap(
                        spacing: UiTokens.chipGap,
                        runSpacing: UiTokens.chipGap,
                        children: [
                          for (final time in med.scheduleTimes)
                            TreatmentInfoChip(
                              label: time,
                              icon: Icons.access_time_outlined,
                            ),
                          if (med.scheduleTimes.isEmpty)
                            TreatmentInfoChip(
                              label: l10n.reminderNoDoseTime,
                              icon: Icons.info_outline,
                            ),
                        ],
                      ),
                      const SizedBox(height: UiTokens.sectionGap),
                      Wrap(
                        spacing: UiTokens.chipGap,
                        runSpacing: UiTokens.chipGap,
                        children: [
                          FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, UiTokens.buttonHeight),
                            ),
                            onPressed: () async {
                              final t = med.scheduleTimes.isNotEmpty ? med.scheduleTimes.first : l10n.reminderNow;
                              await NotificationService.showMedicationReminder(
                                id: med.medicationId.hashCode,
                                title: l10n.reminderNotifyTitle,
                                body: '${med.name} • $t',
                              );
                            },
                            child: Text(l10n.reminderNotifyNow),
                          ),
                          FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, UiTokens.buttonHeight),
                            ),
                            onPressed: () => _log(med, 'taken'),
                            child: Text(l10n.reminderTaken),
                          ),
                          FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, UiTokens.buttonHeight),
                            ),
                            onPressed: () => _log(med, 'late'),
                            child: Text(l10n.reminderLate),
                          ),
                          FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, UiTokens.buttonHeight),
                            ),
                            onPressed: () => _log(med, 'missed'),
                            child: Text(l10n.reminderMissed),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
