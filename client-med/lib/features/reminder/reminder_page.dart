import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      final msg = switch (status) {
        'taken' => 'Đã ghi nhận: ${med.name} đã uống đúng liều',
        'late' => 'Đã ghi nhận: ${med.name} uống trễ',
        'missed' => 'Đã ghi nhận: bỏ lỡ ${med.name}',
        _ => 'Đã ghi nhận ${med.name}: $status',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(treatmentProvider);
    final reminderCount = state.items.where((m) => m.scheduleTimes.isNotEmpty).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Nhắc thuốc hôm nay')),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          children: [
            TreatmentHeaderCard(
              title: 'Lịch thuốc hôm nay',
              subtitle: 'Ưu tiên các liều cần uống trong ngày',
              value: '$reminderCount',
              icon: Icons.alarm_on_outlined,
            ),
            if (state.loading) const LinearProgressIndicator(),
            if (state.error != null) TreatmentErrorBanner(message: state.error!, onRetry: _reload),
            if (state.items.isEmpty)
              const TreatmentEmptyCard(
                icon: Icons.notifications_paused_outlined,
                title: 'Chưa có lịch thuốc để nhắc',
                description: 'Hãy thêm thuốc và giờ uống ở màn Quản lý thuốc.',
              ),
            for (final med in state.items)
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
                              med.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          TreatmentInfoChip(
                            label: med.scheduleTimes.isEmpty ? 'Không giờ cố định' : 'Có lịch',
                            icon: Icons.schedule_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final time in med.scheduleTimes)
                            TreatmentInfoChip(
                              label: time,
                              icon: Icons.access_time_outlined,
                            ),
                          if (med.scheduleTimes.isEmpty)
                            const TreatmentInfoChip(
                              label: 'Chưa có giờ uống',
                              icon: Icons.info_outline,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
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
