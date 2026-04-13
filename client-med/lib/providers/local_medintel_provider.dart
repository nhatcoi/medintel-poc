import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_intel_client/data/local_medintel_state.dart';
import 'package:med_intel_client/features/treatment/data/treatment_models.dart';
import 'package:med_intel_client/providers/shared_preferences_provider.dart';
import 'package:med_intel_client/services/local_medintel_store.dart';

/// Trạng thái dữ liệu agent / người dùng đồng bộ database (cache thiết bị).
final localMedintelProvider =
    NotifierProvider<LocalMedintelNotifier, LocalMedintelState>(LocalMedintelNotifier.new);

class LocalMedintelNotifier extends Notifier<LocalMedintelState> {
  @override
  LocalMedintelState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return LocalMedintelStore.load(prefs);
  }

  /// Thực thi tool_calls sau khi nhận phản hồi chat; trả về dòng tóm tắt cho UI.
  Future<List<String>> applyAgentToolCalls(List<Map<String, dynamic>> toolCalls) async {
    if (toolCalls.isEmpty) return [];
    final prefs = ref.read(sharedPreferencesProvider);
    final result = LocalMedintelStore.apply(state, toolCalls);
    await LocalMedintelStore.save(prefs, result.state);
    state = result.state;
    return result.summaries;
  }

  /// Ghi log liều (cache + đồng bộ database; luôn dùng sau khi bấm Đã uống / Bỏ qua trên Home).
  Future<void> appendDoseLog({
    required String medicationName,
    required String status,
    String? note,
  }) async {
    final prefs = ref.read(sharedPreferencesProvider);
    var s = status.toLowerCase().trim();
    if (!const {'taken', 'missed', 'skipped', 'late'}.contains(s)) {
      s = 'taken';
    }
    final id = '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 30)}';
    final iso = DateTime.now().toUtc().toIso8601String();
    final logs = [
      ...state.doseLogs,
      LocalDoseLog(
        id: id,
        medicationName: medicationName.trim(),
        status: s,
        recordedAtIso: iso,
        note: note,
      ),
    ];
    final next = LocalMedintelState(
      medications: state.medications,
      doseLogs: logs,
      careNotes: state.careNotes,
      reminderDrafts: state.reminderDrafts,
    );
    await LocalMedintelStore.save(prefs, next);
    state = next;
  }

  /// Ghi đè danh sách thuốc từ API khi server trả về ít nhất một mục (giữ log & ghi chú trên cache/database).
  Future<void> mergeMedicationsFromApi(List<MedicationItem> items) async {
    if (items.isEmpty) return;
    final prefs = ref.read(sharedPreferencesProvider);
    final active = items.where((m) {
      final st = (m.status ?? 'active').toLowerCase();
      return st != 'stopped';
    }).toList();
    if (active.isEmpty) return;

    final meds = active
        .map(
          (m) => LocalMedication(
            id: m.medicationId,
            name: m.name,
            dosageLabel: m.dosage,
            scheduleHint: m.scheduleTimes.isNotEmpty ? m.scheduleTimes.join(', ') : null,
          ),
        )
        .toList();

    final next = LocalMedintelState(
      medications: meds,
      doseLogs: state.doseLogs,
      careNotes: state.careNotes,
      reminderDrafts: state.reminderDrafts,
    );
    await LocalMedintelStore.save(prefs, next);
    state = next;
  }
}
