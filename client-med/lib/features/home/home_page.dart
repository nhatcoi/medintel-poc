import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../treatment/data/treatment_models.dart';
import '../treatment/data/treatment_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late DateTime _selectedDate;
  late final ScrollController _dayScrollCtrl;
  static const int _dayRange = 15;
  static const int _totalDays = _dayRange * 2;
  static const double _dayItemWidth = 56;

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(DateTime.now());
    _dayScrollCtrl = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday(animate: false);
      _reload();
    });
  }

  @override
  void dispose() {
    _dayScrollCtrl.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _dayAt(int index) {
    final today = _dateOnly(DateTime.now());
    return today.subtract(Duration(days: _dayRange - index));
  }

  void _scrollToToday({bool animate = true}) {
    final offset = (_dayRange * _dayItemWidth) -
        (MediaQuery.sizeOf(context).width / 2) +
        (_dayItemWidth / 2);
    if (animate) {
      _dayScrollCtrl.animateTo(
        offset.clamp(0.0, _dayScrollCtrl.position.maxScrollExtent),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _dayScrollCtrl.jumpTo(offset.clamp(0.0, double.maxFinite));
    }
  }

  Future<void> _reload() async {
    final profileId = ref.read(authProvider).user?.id;
    if (profileId == null || profileId.isEmpty) return;
    await ref.read(treatmentProvider.notifier).loadMedications(profileId);
    await ref.read(treatmentProvider.notifier).loadSummary(profileId);
  }

  Future<void> _logDose({
    required String medicationId,
    required String status,
  }) async {
    final profileId = ref.read(authProvider).user?.id;
    if (profileId == null || profileId.isEmpty) return;
    await ref.read(treatmentProvider.notifier).logDose(
          profileId: profileId,
          medicationId: medicationId,
          status: status,
        );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(treatmentProvider);
    final sections = _buildSections(state.items, state.logs, _selectedDate);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _reload,
        child: CustomScrollView(
          slivers: [
            // ── Day carousel ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: SizedBox(
                  height: 72,
                  child: ListView.builder(
                    controller: _dayScrollCtrl,
                    scrollDirection: Axis.horizontal,
                    itemCount: _totalDays,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (_, i) {
                      final date = _dayAt(i);
                      final isSelected = date == _selectedDate;
                      final isToday = date == _dateOnly(DateTime.now());
                      return _DayChip(
                        date: date,
                        isSelected: isSelected,
                        isToday: isToday,
                        width: _dayItemWidth,
                        onTap: () => setState(() => _selectedDate = date),
                      );
                    },
                  ),
                ),
              ),
            ),

            // ── Loading ──
            if (state.loading)
              const SliverToBoxAdapter(
                child: LinearProgressIndicator(),
              ),

            // ── Error ──
            if (state.error != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: scheme.error),
                      const SizedBox(width: 8),
                      Expanded(child: Text(state.error!, maxLines: 3, overflow: TextOverflow.ellipsis)),
                      TextButton(onPressed: _reload, child: const Text('Thử lại')),
                    ],
                  ),
                ),
              ),

            // ── Empty state ──
            if (!state.loading && sections.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.surfaceContainerLow,
                        ),
                        child: Icon(Icons.medication_outlined, size: 28, color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
                      ),
                      const SizedBox(height: 16),
                      Text('Không có lịch uống thuốc', style: theme.textTheme.titleSmall?.copyWith(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text('Bạn có thể nghỉ ngơi!', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
              ),

            // ── Dose sections by time ──
            for (final section in sections) ...[
              SliverToBoxAdapter(
                child: _DoseTimeSectionWidget(
                  section: section,
                  onLogDose: _logDose,
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Day chip (like client-template day button)
// ─────────────────────────────────────────────

const _dayNames = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.width,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _dayNames[date.weekday % 7],
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: isSelected ? 42 : 36,
              height: isSelected ? 42 : 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? scheme.primary : Colors.transparent,
                border: isToday && !isSelected
                    ? Border.all(color: scheme.primary.withValues(alpha: 0.4), width: 1.5)
                    : null,
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Dose time section (08:00, 13:00, ...)
// ─────────────────────────────────────────────

class _DoseTimeSectionWidget extends StatelessWidget {
  const _DoseTimeSectionWidget({
    required this.section,
    required this.onLogDose,
  });

  final _DoseSection section;
  final Future<void> Function({required String medicationId, required String status}) onLogDose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final takenCount = section.items.where((e) => e.status == _DoseUiStatus.taken).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time header + badge
          Row(
            children: [
              Expanded(
                child: Text(
                  section.timeLabel,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: takenCount == section.items.length
                        ? scheme.primary.withValues(alpha: 0.4)
                        : scheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                  color: takenCount == section.items.length
                      ? scheme.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                ),
                child: Text(
                  '$takenCount/${section.items.length} ĐÃ DÙNG',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: takenCount == section.items.length ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Med cards
          for (final item in section.items)
            _MedDoseCard(item: item, onLogDose: onLogDose),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Single medication dose card
// ─────────────────────────────────────────────

class _MedDoseCard extends StatelessWidget {
  const _MedDoseCard({
    required this.item,
    required this.onLogDose,
  });

  final _DoseSectionItem item;
  final Future<void> Function({required String medicationId, required String status}) onLogDose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isTaken = item.status == _DoseUiStatus.taken;
    final isMissed = item.status == _DoseUiStatus.missed;

    final iconBg = isTaken
        ? scheme.primary
        : isMissed
            ? scheme.error
            : scheme.surfaceContainerHigh;

    return GestureDetector(
      onTap: () {
        if (!isTaken) {
          onLogDose(medicationId: item.medicationId, status: 'taken');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: scheme.surfaceContainerLow,
          border: Border.all(
            color: isTaken
                ? scheme.outlineVariant.withValues(alpha: 0.15)
                : isMissed
                    ? scheme.error.withValues(alpha: 0.2)
                    : scheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            // Status circle (like client-template)
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBg,
                border: (!isTaken && !isMissed)
                    ? Border.all(color: scheme.primary.withValues(alpha: 0.3), width: 2)
                    : null,
              ),
              child: Center(
                child: isTaken
                    ? Icon(Icons.check_rounded, color: scheme.onPrimary, size: 24)
                    : isMissed
                        ? Icon(Icons.close_rounded, color: scheme.onError, size: 24)
                        : Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: scheme.primary,
                            ),
                          ),
              ),
            ),
            const SizedBox(width: 14),

            // Name + dosage
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      decoration: isTaken ? TextDecoration.lineThrough : null,
                      color: isTaken
                          ? scheme.onSurfaceVariant.withValues(alpha: 0.45)
                          : isMissed
                              ? scheme.error
                              : scheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((item.dosage ?? '').trim().isNotEmpty || (item.frequency ?? '').trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        [
                          if ((item.dosage ?? '').trim().isNotEmpty) item.dosage!.trim(),
                          if ((item.frequency ?? '').trim().isNotEmpty) item.frequency!.trim(),
                        ].join(', '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            // Chevron
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surfaceContainerHigh,
              ),
              child: Icon(Icons.chevron_right_rounded, size: 18, color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Data models for timeline sections
// ─────────────────────────────────────────────

class _DoseSection {
  const _DoseSection({required this.timeLabel, required this.items});

  final String timeLabel;
  final List<_DoseSectionItem> items;
}

class _DoseSectionItem {
  const _DoseSectionItem({
    required this.medicationId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.status,
  });

  final String medicationId;
  final String name;
  final String? dosage;
  final String? frequency;
  final _DoseUiStatus status;
}

enum _DoseUiStatus { taken, missed, upcoming }

// ─────────────────────────────────────────────
// Build sections: group meds by scheduled time
// ─────────────────────────────────────────────

List<_DoseSection> _buildSections(
  List<MedicationItem> meds,
  List<MedicationLogItem> logs,
  DateTime selectedDate,
) {
  final now = DateTime.now();
  final byTime = <String, List<_DoseSectionItem>>{};

  _DoseUiStatus resolveStatus(String medId, String hhmmss) {
    final hms = hhmmss.split(':');
    if (hms.length < 2) return _DoseUiStatus.upcoming;
    final h = int.tryParse(hms[0]) ?? 0;
    final m = int.tryParse(hms[1]) ?? 0;
    final scheduled = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, h, m);

    for (final l in logs) {
      if (l.medicationId != medId) continue;
      final s = l.scheduledDatetime.toLocal();
      if (s.year == selectedDate.year && s.month == selectedDate.month && s.day == selectedDate.day && s.hour == h && s.minute == m) {
        final st = l.status.toLowerCase().trim();
        if (st == 'taken' || st == 'late') return _DoseUiStatus.taken;
        if (st == 'missed' || st == 'skipped') return _DoseUiStatus.missed;
      }
    }

    final isSameDay = selectedDate.year == now.year && selectedDate.month == now.month && selectedDate.day == now.day;
    if (isSameDay && scheduled.isBefore(now.subtract(const Duration(minutes: 30)))) {
      return _DoseUiStatus.missed;
    }
    if (selectedDate.isBefore(DateTime(now.year, now.month, now.day))) {
      return _DoseUiStatus.missed;
    }
    return _DoseUiStatus.upcoming;
  }

  for (final med in meds) {
    if ((med.status ?? 'active') != 'active') continue;
    for (final time in med.scheduleTimes) {
      final key = time.trim();
      if (key.isEmpty) continue;
      byTime.putIfAbsent(key, () => []);
      byTime[key]!.add(
        _DoseSectionItem(
          medicationId: med.medicationId,
          name: med.name,
          dosage: med.dosage,
          frequency: med.frequency,
          status: resolveStatus(med.medicationId, key),
        ),
      );
    }
  }

  final keys = byTime.keys.toList()
    ..sort((a, b) {
      int toMin(String k) {
        final p = k.split(':');
        if (p.length < 2) return 0;
        return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
      }
      return toMin(a).compareTo(toMin(b));
    });

  return keys
      .map((k) => _DoseSection(
            timeLabel: k.length >= 5 ? k.substring(0, 5) : k,
            items: byTime[k]!,
          ))
      .toList();
}
