import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/providers.dart';
import 'treatment_models.dart';
import 'treatment_repository.dart';

final treatmentRepositoryProvider = Provider<TreatmentRepository>(
  (ref) => TreatmentRepository(ref.watch(apiServiceProvider)),
);

class TreatmentState {
  const TreatmentState({
    this.loading = false,
    this.items = const [],
    this.schedules = const [],
    this.logs = const [],
    this.summary,
    this.summary30,
    this.nextDose,
    this.missedDoses = const [],
    this.error,
  });

  final bool loading;
  final List<MedicationItem> items;
  final List<MedicationScheduleItem> schedules;
  final List<MedicationLogItem> logs;
  final AdherenceSummary? summary;
  final AdherenceSummary? summary30;
  final NextDoseInfo? nextDose;
  final List<MissedDoseItem> missedDoses;
  final String? error;

  TreatmentState copyWith({
    bool? loading,
    List<MedicationItem>? items,
    List<MedicationScheduleItem>? schedules,
    List<MedicationLogItem>? logs,
    AdherenceSummary? summary,
    AdherenceSummary? summary30,
    NextDoseInfo? nextDose,
    List<MissedDoseItem>? missedDoses,
    String? error,
  }) {
    return TreatmentState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
      schedules: schedules ?? this.schedules,
      logs: logs ?? this.logs,
      summary: summary ?? this.summary,
      summary30: summary30 ?? this.summary30,
      nextDose: nextDose ?? this.nextDose,
      missedDoses: missedDoses ?? this.missedDoses,
      error: error,
    );
  }
}

List<MedicationItem> _mergeSchedulesIntoItems(
  List<MedicationItem> meds,
  List<MedicationScheduleItem> schedules,
) {
  final byMed = <String, List<String>>{};
  for (final s in schedules) {
    byMed.putIfAbsent(s.medicationId, () => []).add(s.scheduledTime);
  }
  final known = meds.map((m) => m.medicationId).toSet();
  final merged = meds
      .map((m) => m.copyWith(scheduleTimes: byMed[m.medicationId] ?? const []))
      .toList();
  // Any schedules referencing meds we didn't load (edge case) — synthesize
  // minimal items so home schedule still renders them.
  final orphans = <String, MedicationItem>{};
  for (final s in schedules) {
    if (known.contains(s.medicationId)) continue;
    final existing = orphans[s.medicationId];
    if (existing == null) {
      orphans[s.medicationId] = MedicationItem(
        medicationId: s.medicationId,
        name: (s.medicationName ?? '').trim().isEmpty
            ? 'Thuốc'
            : s.medicationName!.trim(),
        dosage: s.medicationDosage,
        frequency: s.medicationFrequency,
        instructions: s.medicationInstructions,
        status: s.status ?? 'active',
        scheduleTimes: [s.scheduledTime],
      );
    } else {
      orphans[s.medicationId] = existing.copyWith(
        scheduleTimes: [...existing.scheduleTimes, s.scheduledTime],
      );
    }
  }
  return [...merged, ...orphans.values];
}

class TreatmentNotifier extends StateNotifier<TreatmentState> {
  TreatmentNotifier(this._repo) : super(const TreatmentState());

  final TreatmentRepository _repo;

  Future<void> loadMedications(String profileId) async {
    await loadHomeSchedule(profileId);
  }

  Future<void> loadCabinet(String profileId) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final medsFuture = _repo.listMedications(profileId);
      final schedulesFuture = _repo.listSchedulesByProfile(profileId);
      final meds = await medsFuture;
      final schedules = await schedulesFuture;
      state = state.copyWith(
        loading: false,
        items: _mergeSchedulesIntoItems(meds, schedules),
        schedules: schedules,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadHomeSchedule(String profileId) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final meds = await _repo.listMedications(profileId);
      final schedules = await _repo.listSchedulesByProfile(profileId);
      final items = _mergeSchedulesIntoItems(meds, schedules);
      final allLogs = await _repo.listLogsByProfile(profileId);
      NextDoseInfo? nextDose;
      List<MissedDoseItem> missed = const [];
      try {
        nextDose = await _repo.getNextDose(profileId);
      } catch (_) {}
      try {
        missed = await _repo.getMissedDoseCheck(profileId);
      } catch (_) {}
      state = state.copyWith(
        loading: false,
        items: items,
        schedules: schedules,
        logs: allLogs,
        nextDose: nextDose,
        missedDoses: missed,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> addMedication({
    required String profileId,
    required String medicationName,
    String? dosage,
    String? frequency,
    String? instructions,
    List<String> scheduleTimes = const [],
  }) async {
    await _repo.createMedication(
      profileId: profileId,
      medicationName: medicationName,
      dosage: dosage,
      frequency: frequency,
      instructions: instructions,
      scheduleTimes: scheduleTimes,
    );
    await loadCabinet(profileId);
  }

  Future<void> updateMedication({
    required String profileId,
    required String medicationId,
    String? status,
  }) async {
    await _repo.updateMedication(
      medicationId: medicationId,
      status: status,
    );
    await loadCabinet(profileId);
  }

  Future<void> deleteMedication({
    required String profileId,
    required String medicationId,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _repo.deleteMedication(
        medicationId: medicationId,
        profileId: profileId,
      );
      await loadCabinet(profileId);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> logDose({
    required String profileId,
    required String medicationId,
    required String status,
    String? scheduledTime,
    DateTime? scheduledDate,
    String? notes,
  }) async {
    await _repo.createMedicationLog(
      medicationId: medicationId,
      profileId: profileId,
      status: status,
      scheduledTime: scheduledTime,
      scheduledDate: scheduledDate,
      notes: notes,
    );
    // Reload full dataset to avoid transient UI flicker where `logs`
    // gets overwritten by a single-medication subset.
    await loadHomeSchedule(profileId);
    await loadSummary(profileId);
  }

  Future<void> updateLogStatus({
    required String profileId,
    required String medicationId,
    required String logId,
    required String status,
    String? notes,
  }) async {
    await _repo.updateMedicationLog(
      medicationId: medicationId,
      logId: logId,
      status: status,
      notes: notes,
    );
    await loadHomeSchedule(profileId);
    await loadSummary(profileId);
  }

  Future<void> addSchedule({
    required String profileId,
    required String medicationId,
    required String scheduledTime,
  }) async {
    await _repo.createSchedule(
      medicationId: medicationId,
      scheduledTime: scheduledTime,
    );
    await loadCabinet(profileId);
  }

  Future<void> removeSchedule({
    required String profileId,
    required String medicationId,
    required String scheduleId,
  }) async {
    await _repo.deleteSchedule(
      medicationId: medicationId,
      scheduleId: scheduleId,
    );
    await loadCabinet(profileId);
  }

  Future<void> loadLogs(String medicationId) async {
    try {
      final items = await _repo.listMedicationLogs(medicationId);
      state = state.copyWith(logs: items, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadSummary(String profileId, {int days = 7}) async {
    try {
      final summary7 = await _repo.getAdherenceSummary(profileId: profileId, days: 7);
      final summary30 = await _repo.getAdherenceSummary(profileId: profileId, days: 30);
      state = state.copyWith(summary: summary7, summary30: summary30, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final treatmentProvider = StateNotifierProvider<TreatmentNotifier, TreatmentState>((ref) {
  return TreatmentNotifier(ref.watch(treatmentRepositoryProvider));
});
