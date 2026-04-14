import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

import '../../providers/providers.dart';
import '../treatment/data/treatment_provider.dart';

class AdherencePlaceholder extends ConsumerStatefulWidget {
  const AdherencePlaceholder({super.key});

  @override
  ConsumerState<AdherencePlaceholder> createState() => _AdherencePlaceholderState();
}

class _AdherencePlaceholderState extends ConsumerState<AdherencePlaceholder> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null || profileId.isEmpty) return;
    await ref.read(treatmentProvider.notifier).loadMedications(profileId);
    await ref.read(treatmentProvider.notifier).loadSummary(profileId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(treatmentProvider);
    final summary = state.summary;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adherenceTitle)),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (summary == null) ...[
              if (state.loading) const LinearProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.adherenceNoData),
            ] else ...[
              _tile(context, l10n.adherenceTotalDoses(summary.days), summary.total.toString()),
              _tile(context, l10n.adherenceTakenLabel, summary.taken.toString()),
              _tile(context, l10n.adherenceMissedLabel, summary.missed.toString()),
              _tile(context, l10n.adherenceSkippedLabel, summary.skipped.toString()),
              _tile(context, l10n.adherenceLateLabel, summary.late.toString()),
              const SizedBox(height: 12),
              Text(
                'Lich su gan day',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              if (state.logs.isEmpty)
                Text(
                  l10n.adherenceNoData,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              for (final log in state.logs.take(30))
                Card(
                  child: ListTile(
                    title: Text(log.medicationName),
                    subtitle: Text(log.scheduledDatetime.toLocal().toString()),
                    trailing: Text(log.status),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, String title, String value) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
