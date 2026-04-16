import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/providers.dart';
import '../../core/theme/vitalis_colors.dart';
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
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null || profileId.isEmpty) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: 'Thêm giờ uống - ${item.name}',
    );
    if (picked == null) return;
    final hh = picked.hour.toString().padLeft(2, '0');
    final mm = picked.minute.toString().padLeft(2, '0');
    await ref.read(treatmentProvider.notifier).addSchedule(
          profileId: profileId,
          medicationId: item.medicationId,
          scheduledTime: '$hh:$mm:00',
        );
  }

  Future<void> _removeSchedule(MedicationItem item, MedicationScheduleItem schedule) async {
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null || profileId.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa giờ uống?'),
        content: Text('Xóa giờ ${_shortTime(schedule.scheduledTime)} của ${item.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(treatmentProvider.notifier).removeSchedule(
          profileId: profileId,
          medicationId: item.medicationId,
          scheduleId: schedule.scheduleId,
        );
  }

  Future<void> _deleteMedication(MedicationItem item) async {
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null || profileId.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gỡ thuốc?'),
        content: Text('Bạn có chắc chắn muốn gỡ ${item.name} khỏi tủ thuốc?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Gỡ'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await ref.read(treatmentProvider.notifier).deleteMedication(
          profileId: profileId,
          medicationId: item.medicationId,
        );
    await _reload();
  }

  static String _shortTime(String raw) =>
      raw.length >= 5 ? raw.substring(0, 5) : raw;

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
    final schedulesByMed = <String, List<MedicationScheduleItem>>{};
    for (final s in state.schedules) {
      schedulesByMed.putIfAbsent(s.medicationId, () => []).add(s);
    }
    for (final list in schedulesByMed.values) {
      list.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    }

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
                        schedules: schedulesByMed[m.medicationId] ?? const [],
                        onUpdateInventory: () => _updateInventory(m),
                        onDelete: () => _deleteMedication(m),
                        onSetupSchedule: () => _setupSchedule(m),
                        onRemoveSchedule: (s) => _removeSchedule(m, s),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openAddMedication,
            borderRadius: BorderRadius.circular(22),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    VitalisColors.primary,
                    VitalisColors.primary.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: VitalisColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.plus,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Thêm thuốc',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CabinetMedicationCard extends StatelessWidget {
  const _CabinetMedicationCard({
    required this.item,
    required this.schedules,
    required this.onUpdateInventory,
    required this.onDelete,
    required this.onSetupSchedule,
    required this.onRemoveSchedule,
  });

  final MedicationItem item;
  final List<MedicationScheduleItem> schedules;
  final VoidCallback onUpdateInventory;
  final VoidCallback onDelete;
  final VoidCallback onSetupSchedule;
  final void Function(MedicationScheduleItem schedule) onRemoveSchedule;

  String _shortTime(String raw) => raw.length >= 5 ? raw.substring(0, 5) : raw;

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
          if (schedules.isEmpty)
            Text(
              'Chưa có giờ uống. Bấm "Thêm giờ" để cài đặt.',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in schedules)
                  InputChip(
                    avatar: Icon(LucideIcons.alarmClock, size: 14, color: scheme.primary),
                    label: Text(_shortTime(s.scheduledTime)),
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    onDeleted: () => onRemoveSchedule(s),
                    deleteIconColor: scheme.error.withValues(alpha: 0.8),
                    backgroundColor: scheme.primary.withValues(alpha: 0.08),
                    side: BorderSide(color: scheme.primary.withValues(alpha: 0.2)),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: onDelete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.error,
                  side: BorderSide(color: scheme.error.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Gỡ', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onUpdateInventory,
                  icon: const Icon(LucideIcons.archive, size: 16),
                  label: Text(hasInventory ? 'Cập nhật kho' : 'Thiết lập kho', style: const TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onSetupSchedule,
                  icon: const Icon(LucideIcons.alarmClock, size: 16),
                  label: const Text('Thêm giờ', style: TextStyle(fontSize: 13)),
                  style: FilledButton.styleFrom(padding: EdgeInsets.zero),
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
