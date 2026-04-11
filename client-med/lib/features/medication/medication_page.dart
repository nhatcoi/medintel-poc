import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        return AlertDialog(
          title: const Text('Thêm thuốc mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Tên thuốc',
                    hintText: 'Ví dụ: Metformin',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: doseCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Liều dùng',
                    hintText: 'Ví dụ: 500mg x 1 viên',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: scheduleCtrl,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                    labelText: 'Giờ uống (HH:MM)',
                    helperText: 'Định dạng 24h, ví dụ 08:00',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu thuốc')),
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
    final state = ref.watch(treatmentProvider);
    final activeCount = state.items.where((m) => (m.status ?? 'active') == 'active').length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thuốc'),
        actions: [
          IconButton(
            onPressed: _addMedicationDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Thêm thuốc',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          children: [
            TreatmentHeaderCard(
              title: 'Danh sách thuốc điều trị',
              subtitle: 'Theo dõi thuốc đang dùng mỗi ngày',
              value: '$activeCount',
              icon: Icons.medication_liquid_outlined,
            ),
            if (state.loading) const LinearProgressIndicator(),
            if (state.error != null)
              TreatmentErrorBanner(message: state.error!, onRetry: _reload),
            if (state.items.isEmpty)
              TreatmentEmptyCard(
                icon: Icons.medication_outlined,
                title: 'Chưa có thuốc trong hồ sơ',
                description: 'Nhấn nút thêm để tạo lịch uống và theo dõi tuân thủ.',
                ctaLabel: 'Thêm thuốc',
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
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'active', child: Text('Đang dùng')),
                              PopupMenuItem(value: 'paused', child: Text('Tạm dừng')),
                              PopupMenuItem(value: 'stopped', child: Text('Ngưng')),
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
                            label: m.scheduleTimes.isEmpty ? 'Chưa có giờ uống' : m.scheduleTimes.join(', '),
                            icon: Icons.schedule_outlined,
                          ),
                          TreatmentInfoChip(
                            label: _statusLabel(m.status),
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

  String _statusLabel(String? status) {
    switch (status) {
      case 'paused':
        return 'Tạm dừng';
      case 'stopped':
        return 'Ngưng';
      case 'active':
      default:
        return 'Đang dùng';
    }
  }
}
