import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../treatment/data/treatment_provider.dart';

class MedicationPlaceholder extends ConsumerStatefulWidget {
  const MedicationPlaceholder({super.key});

  @override
  ConsumerState<MedicationPlaceholder> createState() => _MedicationPlaceholderState();
}

class _MedicationPlaceholderState extends ConsumerState<MedicationPlaceholder> {
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
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm thuốc'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên thuốc')),
            TextField(controller: doseCtrl, decoration: const InputDecoration(labelText: 'Liều dùng')),
            TextField(
              controller: scheduleCtrl,
              decoration: const InputDecoration(labelText: 'Giờ (HH:MM)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
        ],
      ),
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
            if (state.loading) const LinearProgressIndicator(),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(state.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            if (state.items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Chưa có thuốc. Nhấn + để thêm.'),
              ),
            for (final m in state.items)
              ListTile(
                title: Text(m.name),
                subtitle: Text([
                  if ((m.dosage ?? '').isNotEmpty) m.dosage!,
                  if (m.scheduleTimes.isNotEmpty) 'Giờ: ${m.scheduleTimes.join(", ")}',
                ].join(' • ')),
                trailing: PopupMenuButton<String>(
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
              ),
          ],
        ),
      ),
    );
  }
}
