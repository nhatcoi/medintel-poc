import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/local_medintel_state.dart';

/// Key SharedPreferences lưu JSON agent (đồng bộ với [LocalMedintelState]).
const String kMedintelLocalAgentPrefsKey = 'medintel_local_agent_v1';

class LocalMedintelStore {
  LocalMedintelStore._();

  static LocalMedintelState load(SharedPreferences? prefs) {
    if (prefs == null) return LocalMedintelState.empty;
    final raw = prefs.getString(kMedintelLocalAgentPrefsKey);
    return LocalMedintelState.decode(raw);
  }

  static Future<void> save(SharedPreferences? prefs, LocalMedintelState state) async {
    if (prefs == null) return;
    await prefs.setString(kMedintelLocalAgentPrefsKey, LocalMedintelState.encode(state));
  }

  /// Thực thi tool_calls từ LLM; bỏ qua tool không hợp lệ.
  static LocalAgentApplyResult apply(
    LocalMedintelState current,
    List<Map<String, dynamic>> toolCalls,
  ) {
    var meds = List<LocalMedication>.from(current.medications);
    var logs = List<LocalDoseLog>.from(current.doseLogs);
    var notes = List<LocalCareNote>.from(current.careNotes);
    var reminders = List<LocalReminderDraft>.from(current.reminderDrafts);
    final summaries = <String>[];

    String newId() => '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 30)}';

    for (final call in toolCalls) {
      final tool = call['tool']?.toString() ?? '';
      final rawArgs = call['args'];
      final map = <String, dynamic>{};
      if (rawArgs is Map) {
        rawArgs.forEach((k, v) => map[k.toString()] = v);
      }

      switch (tool) {
        case 'log_dose':
          final name = _str(map['medication_name']).trim();
          if (name.isEmpty) break;
          var status = _str(map['status']).toLowerCase().trim();
          if (!const {'taken', 'missed', 'skipped'}.contains(status)) {
            status = 'taken';
          }
          var iso = _str(map['recorded_at']).trim();
          if (iso.isEmpty) {
            iso = DateTime.now().toUtc().toIso8601String();
          }
          final note = _optionalStr(map['note']);
          logs = [
            ...logs,
            LocalDoseLog(
              id: newId(),
              medicationName: _clip(name, 120),
              status: status,
              recordedAtIso: iso,
              note: note != null ? _clip(note, 500) : null,
            ),
          ];
          final vn = switch (status) {
            'missed' => 'bỏ lỡ',
            'skipped' => 'bỏ qua',
            _ => 'đã uống',
          };
          summaries.add('Đã lưu vào database: $name — $vn');
          break;

        case 'upsert_medication':
          final name = _str(map['name']).trim();
          if (name.isEmpty) break;
          final dosage = _optionalStr(map['dosage_label']);
          final hint = _optionalStr(map['schedule_hint']);
          final lower = name.toLowerCase();
          final idx = meds.indexWhere((m) => m.name.toLowerCase() == lower);
          final row = LocalMedication(
            id: idx >= 0 ? meds[idx].id : newId(),
            name: _clip(name, 120),
            dosageLabel: dosage != null ? _clip(dosage, 120) : null,
            scheduleHint: hint != null ? _clip(hint, 200) : null,
          );
          if (idx >= 0) {
            meds = [...meds]..[idx] = row;
          } else {
            meds = [...meds, row];
          }
          summaries.add('Đã lưu thuốc vào database: $name');
          break;

        case 'append_care_note':
          final text = _str(map['text']).trim();
          if (text.isEmpty) break;
          notes = [
            ...notes,
            LocalCareNote(
              id: newId(),
              text: _clip(text, 2000),
              atIso: DateTime.now().toUtc().toIso8601String(),
            ),
          ];
          summaries.add('Đã lưu ghi chú chăm sóc vào database');
          break;

        case 'save_reminder_intent':
          final title = _str(map['title']).trim();
          if (title.isEmpty) break;
          final detail = _optionalStr(map['detail']);
          reminders = [
            ...reminders,
            LocalReminderDraft(
              id: newId(),
              title: _clip(title, 200),
              detail: detail != null ? _clip(detail, 500) : null,
              atIso: DateTime.now().toUtc().toIso8601String(),
            ),
          ];
          summaries.add('Đã lưu nháp nhắc: $title');
          break;
      }
    }

    return LocalAgentApplyResult(
      state: LocalMedintelState(
        medications: meds,
        doseLogs: logs,
        careNotes: notes,
        reminderDrafts: reminders,
      ),
      summaries: summaries,
    );
  }

  static String _str(Object? v) => v?.toString() ?? '';

  static String? _optionalStr(Object? v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  static String _clip(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}…';
}
