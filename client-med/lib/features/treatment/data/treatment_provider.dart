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
    this.logs = const [],
    this.summary,
    this.summary30,
    this.nextDose,
    this.missedDoses = const [],
    this.error,
  });

  final bool loading;
  final List<MedicationItem> items;
  final List<MedicationLogItem> logs;
  final AdherenceSummary? summary;
  final AdherenceSummary? summary30;
  final NextDoseInfo? nextDose;
  final List<MissedDoseItem> missedDoses;
  final String? error;

  TreatmentState copyWith({
    bool? loading,
    List<MedicationItem>? items,
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
      logs: logs ?? this.logs,
      summary: summary ?? this.summary,
      summary30: summary30 ?? this.summary30,
      nextDose: nextDose ?? this.nextDose,
      missedDoses: missedDoses ?? this.missedDoses,
      error: error,
    );
  }
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
      final items = await _repo.listMedications(profileId);
      state = state.copyWith(
        loading: false,
        items: items,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadHomeSchedule(String profileId) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final schedules = await _repo.listSchedulesByProfile(profileId);
      final medMap = <String, MedicationItem>{};
      for (final s in schedules) {
        final existing = medMap[s.medicationId];
        if (existing == null) {
          medMap[s.medicationId] = MedicationItem(
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
          medMap[s.medicationId] = existing.copyWith(
            scheduleTimes: [...existing.scheduleTimes, s.scheduledTime],
          );
        }
      }
      final items = medMap.values.toList();
      final allLogs = await _repo.listLogsByProfile(profileId);
      final nextDose = await _repo.getNextDose(profileId);
      final missed = await _repo.getMissedDoseCheck(profileId);
      state = state.copyWith(
        loading: false,
        items: items,
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
