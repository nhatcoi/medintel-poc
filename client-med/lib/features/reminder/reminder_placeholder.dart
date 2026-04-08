import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../services/notification_service.dart';
import '../treatment/data/treatment_models.dart';
import '../treatment/data/treatment_provider.dart';

class ReminderPlaceholder extends ConsumerStatefulWidget {
  const ReminderPlaceholder({super.key});

  @override
  ConsumerState<ReminderPlaceholder> createState() => _ReminderPlaceholderState();
}

class _ReminderPlaceholderState extends ConsumerState<ReminderPlaceholder> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final profileId = ref.read(authProvider).user?.id;
    if (profileId == null || profileId.isEmpty) return;
    await ref.read(treatmentProvider.notifier).loadMedications(profileId);
  }

  Future<void> _log(MedicationItem med, String status) async {
    final profileId = ref.read(authProvider).user?.id;
    if (profileId == null || profileId.isEmpty) return;
    await ref.read(treatmentProvider.notifier).logDose(
          profileId: profileId,
          medicationId: med.medicationId,
          status: status,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã ghi nhận ${med.name}: $status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(treatmentProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Nhắc thuốc hôm nay')),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          children: [
            if (state.loading) const LinearProgressIndicator(),
            if (state.items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Chưa có lịch thuốc để nhắc.'),
              ),
            for (final med in state.items)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med.name, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('Giờ: ${med.scheduleTimes.isEmpty ? "—" : med.scheduleTimes.join(", ")}'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton(
                            onPressed: () async {
                              final t = med.scheduleTimes.isNotEmpty ? med.scheduleTimes.first : 'bây giờ';
                              await NotificationService.showMedicationReminder(
                                id: med.medicationId.hashCode,
                                title: 'Nhắc uống thuốc',
                                body: '${med.name} • $t',
                              );
                            },
                            child: const Text('Nhắc ngay'),
                          ),
                          FilledButton.tonal(
                            onPressed: () => _log(med, 'taken'),
                            child: const Text('Đã uống'),
                          ),
                          FilledButton.tonal(
                            onPressed: () => _log(med, 'late'),
                            child: const Text('Uống trễ'),
                          ),
                          FilledButton.tonal(
                            onPressed: () => _log(med, 'missed'),
                            child: const Text('Bỏ lỡ'),
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
