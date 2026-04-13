import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

import '../../providers/providers.dart';
import '../treatment/data/treatment_provider.dart';
import '../treatment/widgets/treatment_ui.dart';

class MedicationPage extends ConsumerStatefulWidget {
  const MedicationPage({super.key});

  @override
  ConsumerState<MedicationPage> createState() => _MedicationPageState();
}

class _MedicationPageState extends ConsumerState<MedicationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final auth = ref.read(authProvider);
    final profileId = auth.user?.id;
    if (profileId == null || profileId.isEmpty) return;
    await ref.read(treatmentProvider.notifier).loadMedications(profileId);
    await ref.read(treatmentProvider.notifier).loadSummary(profileId);
  }

  Future<void> _addMedicationDialog() async {
    final nameCtrl = TextEditingController();
    final doseCtrl = TextEditingController();
    final scheduleCtrl = TextEditingController(text: '08:00');
    final auth = ref.read(authProvider);
    final profileId = auth.user?.id;
    if (profileId == null || profileId.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(l10n.medicationAddTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.medicationDrugName,
                    hintText: l10n.medicationDrugNameHint,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: doseCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.medicationDosage,
                    hintText: l10n.medicationDosageHint,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: scheduleCtrl,
                  keyboardType: TextInputType.datetime,
                  decoration: InputDecoration(
                    labelText: l10n.medicationSchedule,
                    helperText: l10n.medicationScheduleHelper,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.genericCancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.medicationSave)),
          ],
        );
      },
    );
    if (ok != true) return;
    await ref.read(treatmentProvider.notifier).addMedication(
          profileId: profileId,
          medicationName: nameCtrl.text.trim(),
          dosage: doseCtrl.text.trim().isEmpty ? null : doseCtrl.text.trim(),
          scheduleTimes: [scheduleCtrl.text.trim()],
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(treatmentProvider);
    final activeCount = state.items.where((m) => (m.status ?? 'active') == 'active').length;
    final summary7 = state.summary;
    final summary30 = state.summary30;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.medicationListTitle),
        actions: [
          IconButton(
            onPressed: _addMedicationDialog,
            icon: const Icon(Icons.add),
            tooltip: l10n.medicationAddTooltip,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          children: [
            TreatmentHeaderCard(
              title: l10n.medicationHeaderTitle,
              subtitle: l10n.medicationHeaderSubtitle,
              value: '$activeCount',
              icon: Icons.medication_liquid_outlined,
            ),
            if (summary7 != null)
              TreatmentHeaderCard(
                title: 'Tuân thủ 7 ngày',
                subtitle: 'Tỉ lệ uống đúng/đủ',
                value: '${(summary7.complianceRate * 100).toStringAsFixed(0)}%',
                icon: Icons.insights_outlined,
              ),
            if (summary30 != null)
              TreatmentHeaderCard(
                title: 'Tuân thủ 30 ngày',
                subtitle: 'Xu hướng dài hạn',
                value: '${(summary30.complianceRate * 100).toStringAsFixed(0)}%',
                icon: Icons.timeline_outlined,
              ),
            if (state.nextDose != null)
              Card(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: ListTile(
                  leading: const Icon(Icons.alarm),
                  title: const Text('Liều kế tiếp'),
                  subtitle: Text(
                    '${state.nextDose!.medicationName} • ${state.nextDose!.scheduledDatetime.toLocal()}',
                  ),
                ),
              ),
            if (state.missedDoses.isNotEmpty)
              Card(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                color: Theme.of(context).colorScheme.errorContainer,
                child: ListTile(
                  leading: const Icon(Icons.warning_amber_outlined),
                  title: const Text('Liều có nguy cơ quên'),
                  subtitle: Text(
                    '${state.missedDoses.length} liều quá hạn cần xử lý',
                  ),
                ),
              ),
            if (state.loading) const LinearProgressIndicator(),
            if (state.error != null)
              TreatmentErrorBanner(message: state.error!, onRetry: _reload),
            if (state.items.isEmpty)
              TreatmentEmptyCard(
                icon: Icons.medication_outlined,
                title: l10n.medicationEmptyTitle,
                description: l10n.medicationEmptyDescription,
                ctaLabel: l10n.medicationEmptyCta,
                onTapCta: _addMedicationDialog,
              ),
            for (final m in state.items)
              Card(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              m.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (v) async {
                              final auth = ref.read(authProvider);
                              final profileId = auth.user?.id;
                              if (profileId == null || profileId.isEmpty) return;
                              await ref.read(treatmentProvider.notifier).updateMedication(
                                    profileId: profileId,
                                    medicationId: m.medicationId,
                                    status: v,
                                  );
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(value: 'active', child: Text(l10n.medicationStatusActive)),
                              PopupMenuItem(value: 'paused', child: Text(l10n.medicationStatusPaused)),
                              PopupMenuItem(value: 'stopped', child: Text(l10n.medicationStatusStopped)),
                            ],
                          ),
                        ],
                      ),
                      if ((m.dosage ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            m.dosage!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          TreatmentInfoChip(
                            label: m.scheduleTimes.isEmpty ? l10n.medicationNoDoseTime : m.scheduleTimes.join(', '),
                            icon: Icons.schedule_outlined,
                          ),
                          TreatmentInfoChip(
                            label: _statusLabel(m.status, l10n),
                            icon: Icons.health_and_safety_outlined,
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

  String _statusLabel(String? status, AppLocalizations l10n) {
    switch (status) {
      case 'paused':
        return l10n.medicationStatusPaused;
      case 'stopped':
        return l10n.medicationStatusStopped;
      case 'active':
      default:
        return l10n.medicationStatusActive;
    }
  }
}
