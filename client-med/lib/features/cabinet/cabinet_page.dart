import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/providers.dart';
import '../home/widgets/home_schedule_header.dart';
import '../medication/widgets/add_medication_sheet.dart';
import '../medication/widgets/medication_search_sheet.dart';
import '../treatment/data/treatment_models.dart';
import '../treatment/data/treatment_provider.dart';

class CabinetPage extends ConsumerStatefulWidget {
  const CabinetPage({super.key});

  @override
  ConsumerState<CabinetPage> createState() => _CabinetPageState();
}

class _CabinetPageState extends ConsumerState<CabinetPage> {
  String? _boundProfileId;

  Future<void> _reload() async {
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null || profileId.isEmpty) return;
    await ref.read(treatmentProvider.notifier).loadCabinet(profileId);
  }

  Future<void> _openAddMedication() async {
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null || profileId.isEmpty) return;

    final selected = await showModalBottomSheet<MedicationSearchCandidate>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const MedicationSearchSheet(),
    );
    if (selected == null) return;

    final data = await showModalBottomSheet<AddMedicationFormData>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddMedicationSheet(initialCandidate: selected),
    );
    if (data == null) return;

    await ref.read(treatmentProvider.notifier).addMedication(
          profileId: profileId,
          medicationName: data.name,
          dosage: data.dosage,
          frequency: data.frequency,
          instructions: data.instructions,
          scheduleTimes: const [],
        );
    await _reload();
  }

  Future<void> _updateInventory(MedicationItem item) async {
    final qtyCtrl = TextEditingController(
      text: item.remainingQuantity?.toStringAsFixed(0) ?? '',
    );
    final unitCtrl = TextEditingController(text: item.quantityUnit ?? 'vien');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cập nhật tồn kho - ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Số lượng còn lại'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: unitCtrl,
              decoration: const InputDecoration(labelText: 'Đơn vị (viên/gói/ml)'),
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
    final qty = double.tryParse(qtyCtrl.text.trim());
    if (qty == null) return;
    await ref.read(treatmentRepositoryProvider).updateMedicationInventory(
          medicationId: item.medicationId,
          remainingQuantity: qty,
          quantityUnit: unitCtrl.text.trim().isEmpty ? null : unitCtrl.text.trim(),
          lowStockThreshold: 5.0,
        );
    await _reload();
  }

  Future<void> _setupSchedule(MedicationItem item) async {
    final timeCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Thiết lập lịch - ${item.name}'),
        content: TextField(
          controller: timeCtrl,
          keyboardType: TextInputType.datetime,
          decoration: const InputDecoration(
            labelText: 'Giờ uống (HH:mm)',
            hintText: 'Ví dụ 08:00',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
        ],
      ),
    );
    if (ok != true) return;
    final raw = timeCtrl.text.trim();
    final isValid = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(raw);
    if (!isValid) return;
    await ref.read(treatmentRepositoryProvider).createSchedule(
          medicationId: item.medicationId,
          scheduledTime: '$raw:00',
        );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final profileId = ref.watch(activeProfileIdProvider);
    if (profileId != _boundProfileId) {
      _boundProfileId = profileId;
      WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
    }

    final displayName = ref.watch(activeProfileDisplayNameProvider);
    final state = ref.watch(treatmentProvider);
    final items = state.items;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            HomeScheduleHeader(
              displayName: displayName,
              onTapPlus: _openAddMedication,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tủ thuốc cá nhân',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${items.length} thuốc đang quản lý',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (state.loading) const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  if (state.error != null)
                    Text(
                      state.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  if (!state.loading && items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                      ),
                      child: const Text(
                        'Chưa có thuốc trong tủ. Bấm + để thêm thuốc.',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    )
                  else
                    ...items.map(
                      (m) => _CabinetMedicationCard(
                        item: m,
                        onUpdateInventory: () => _updateInventory(m),
                        onSetupSchedule: () => _setupSchedule(m),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddMedication,
        icon: const Icon(LucideIcons.pill),
        label: const Text('Thêm thuốc'),
      ),
    );
  }
}

class _CabinetMedicationCard extends StatelessWidget {
  const _CabinetMedicationCard({
    required this.item,
    required this.onUpdateInventory,
    required this.onSetupSchedule,
  });

  final MedicationItem item;
  final VoidCallback onUpdateInventory;
  final VoidCallback onSetupSchedule;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = [
      if ((item.dosage ?? '').trim().isNotEmpty) item.dosage!.trim(),
      if ((item.frequency ?? '').trim().isNotEmpty) item.frequency!.trim(),
    ].join(' • ');
    final remaining = item.remainingQuantity;
    final unit = (item.quantityUnit ?? '').trim();
    final hasInventory = remaining != null;
    final lowStock = hasInventory && remaining <= 5;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerLowest,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: scheme.primary.withValues(alpha: 0.14),
                ),
                child: Icon(LucideIcons.pill, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _InventoryBadge(
                text: hasInventory
                    ? 'Còn ${remaining.toStringAsFixed(0)} ${unit.isEmpty ? 'đv' : unit}'
                    : 'Chưa có tồn kho',
                isWarning: lowStock,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onUpdateInventory,
                  icon: const Icon(LucideIcons.archive),
                  label: Text(hasInventory ? 'Cập nhật tồn kho' : 'Thiết lập tồn kho'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onSetupSchedule,
                  icon: const Icon(LucideIcons.alarmClock, size: 18),
                  label: const Text('Thiết lập lịch'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InventoryBadge extends StatelessWidget {
  const _InventoryBadge({
    required this.text,
    required this.isWarning,
  });

  final String text;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bgColor = isWarning
        ? Colors.orange.withValues(alpha: 0.15)
        : scheme.primary.withValues(alpha: 0.1);
    final fgColor = isWarning ? Colors.orange.shade800 : scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: bgColor,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fgColor,
        ),
      ),
    );
  }
}
