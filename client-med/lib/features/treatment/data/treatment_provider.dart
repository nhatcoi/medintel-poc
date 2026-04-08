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
    this.error,
  });

  final bool loading;
  final List<MedicationItem> items;
  final List<MedicationLogItem> logs;
  final AdherenceSummary? summary;
  final String? error;

  TreatmentState copyWith({
    bool? loading,
    List<MedicationItem>? items,
    List<MedicationLogItem>? logs,
    AdherenceSummary? summary,
    String? error,
  }) {
    return TreatmentState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
      logs: logs ?? this.logs,
      summary: summary ?? this.summary,
      error: error,
    );
  }
}

class TreatmentNotifier extends StateNotifier<TreatmentState> {
  TreatmentNotifier(this._repo) : super(const TreatmentState());

  final TreatmentRepository _repo;

  Future<void> loadMedications(String profileId) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final items = await _repo.listMedications(profileId);
      state = state.copyWith(loading: false, items: items, error: null);
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
    await loadMedications(profileId);
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
    await loadMedications(profileId);
  }

  Future<void> logDose({
    required String profileId,
    required String medicationId,
    required String status,
    String? notes,
  }) async {
    await _repo.createMedicationLog(
      medicationId: medicationId,
      profileId: profileId,
      status: status,
      notes: notes,
    );
    await loadLogs(medicationId);
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
      final summary = await _repo.getAdherenceSummary(profileId: profileId, days: days);
      state = state.copyWith(summary: summary, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final treatmentProvider = StateNotifierProvider<TreatmentNotifier, TreatmentState>((ref) {
  return TreatmentNotifier(ref.watch(treatmentRepositoryProvider));
});
