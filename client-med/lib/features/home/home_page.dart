import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/ui_tokens.dart';
import '../../providers/providers.dart';
import '../medication/widgets/add_medication_sheet.dart';
import '../medication/widgets/medication_search_sheet.dart';
import '../treatment/data/treatment_provider.dart';
import 'data/home_schedule_builder.dart';
import 'widgets/home_day_carousel.dart';
import 'widgets/home_dose_sections.dart';
import 'widgets/home_quick_actions_sheet.dart';
import 'widgets/home_schedule_header.dart';

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
  String? _boundProfileId;
  final Set<String> _pendingDoseKeys = <String>{};

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
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null || profileId.isEmpty) return;
    await ref.read(treatmentProvider.notifier).loadMedications(profileId);
    await ref.read(treatmentProvider.notifier).loadSummary(profileId);
  }

  Future<void> _logDose({
    required String medicationId,
    required String status,
    String? scheduledTime,
    DateTime? scheduledDate,
  }) async {
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null || profileId.isEmpty) return;
    final effectiveDate = scheduledDate ?? _selectedDate;
    final effectiveTime = (scheduledTime ?? '').trim();
    final actionKey = effectiveTime.isEmpty
        ? null
        : homeDoseActionKey(
            medicationId: medicationId,
            timeLabel: effectiveTime,
            selectedDate: effectiveDate,
          );
    if (actionKey != null) {
      setState(() => _pendingDoseKeys.add(actionKey));
    }
    try {
      await ref.read(treatmentProvider.notifier).logDose(
            profileId: profileId,
            medicationId: medicationId,
            status: status,
            scheduledTime: scheduledTime,
            scheduledDate: scheduledDate,
          );
      if (!mounted) return;
      await _reload();
    } finally {
      if (mounted && actionKey != null) {
        setState(() => _pendingDoseKeys.remove(actionKey));
      }
    }
  }

  Future<void> _openAddMedicationSheet() async {
    final profileId = ref.read(activeProfileIdProvider);
    if (profileId == null || profileId.isEmpty) return;

    final selected = await showModalBottomSheet<MedicationSearchCandidate>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (_) => const MedicationSearchSheet(),
    );
    if (selected == null) return;

    final data = await showModalBottomSheet<AddMedicationFormData>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (_) => AddMedicationSheet(initialCandidate: selected),
    );
    if (data == null) return;
    await ref.read(treatmentProvider.notifier).addMedication(
          profileId: profileId,
          medicationName: data.name,
          dosage: data.dosage,
          frequency: data.frequency,
          instructions: data.instructions,
          scheduleTimes: data.scheduleTimes,
        );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final currentProfileId = ref.watch(activeProfileIdProvider);
    if (currentProfileId != _boundProfileId) {
      _boundProfileId = currentProfileId;
      WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
    }
    final state = ref.watch(treatmentProvider);
    final sections = buildHomeDoseSections(state.items, state.logs, _selectedDate);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final displayName = ref.watch(activeProfileDisplayNameProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _reload,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: HomeScheduleHeader(
                displayName: displayName,
                onTapPlus: () => showHomeQuickActionsSheet(
                  context,
                  onTapAddMedication: _openAddMedicationSheet,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: HomeDayCarousel(
                controller: _dayScrollCtrl,
                totalDays: _totalDays,
                dayAt: _dayAt,
                selectedDate: _selectedDate,
                today: _dateOnly(DateTime.now()),
                dayItemWidth: _dayItemWidth,
                onSelect: (date) => setState(() => _selectedDate = date),
              ),
            ),
            if (state.loading)
              const SliverToBoxAdapter(child: LinearProgressIndicator()),
            if (state.error != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(
                    UiTokens.pagePadding,
                    UiTokens.chipGap,
                    UiTokens.pagePadding,
                    UiTokens.chipGap,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: scheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.error!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(onPressed: _reload, child: const Text('Thu lai')),
                    ],
                  ),
                ),
              ),
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
                        child: Icon(
                          Icons.medication_outlined,
                          size: 28,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Khong co lich uong thuoc',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ban co the nghi ngoi!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            for (final section in sections)
              SliverToBoxAdapter(
                child: HomeDoseSectionWidget(
                  section: section,
                  selectedDate: _selectedDate,
                  pendingDoseKeys: _pendingDoseKeys,
                  onLogDose: _logDose,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}
