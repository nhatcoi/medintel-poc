import 'dart:convert';

/// Snapshot dữ liệu agent lưu cục bộ (SharedPreferences). Đồng bộ server — sau.
class LocalMedintelState {
  const LocalMedintelState({
    this.medications = const [],
    this.doseLogs = const [],
    this.careNotes = const [],
    this.reminderDrafts = const [],
  });

  final List<LocalMedication> medications;
  final List<LocalDoseLog> doseLogs;
  final List<LocalCareNote> careNotes;
  final List<LocalReminderDraft> reminderDrafts;

  static const LocalMedintelState empty = LocalMedintelState();

  /// Số log liều có recordedAt thuộc ngày calendar local [day].
  int countDoseLogsOnDay(DateTime day) {
    return doseLogs.where((log) {
      final dt = DateTime.tryParse(log.recordedAtIso);
      if (dt == null) return false;
      final local = dt.toLocal();
      return local.year == day.year && local.month == day.month && local.day == day.day;
    }).length;
  }

  factory LocalMedintelState.fromJson(Map<String, dynamic>? json) {
    if (json == null) return empty;
    return LocalMedintelState(
      medications: _listMap(json['medications'], LocalMedication.fromJson),
      doseLogs: _listMap(json['dose_logs'], LocalDoseLog.fromJson),
      careNotes: _listMap(json['care_notes'], LocalCareNote.fromJson),
      reminderDrafts: _listMap(json['reminder_drafts'], LocalReminderDraft.fromJson),
    );
  }

  Map<String, dynamic> toJson() => {
        'medications': medications.map((e) => e.toJson()).toList(),
        'dose_logs': doseLogs.map((e) => e.toJson()).toList(),
        'care_notes': careNotes.map((e) => e.toJson()).toList(),
        'reminder_drafts': reminderDrafts.map((e) => e.toJson()).toList(),
      };

  static String encode(LocalMedintelState s) => jsonEncode(s.toJson());

  static LocalMedintelState decode(String? raw) {
    if (raw == null || raw.isEmpty) return empty;
    try {
      final j = jsonDecode(raw);
      if (j is Map<String, dynamic>) return LocalMedintelState.fromJson(j);
    } catch (_) {}
    return empty;
  }
}

List<T> _listMap<T>(Object? raw, T Function(Map<String, dynamic>) f) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => f(Map<String, dynamic>.from(e)))
      .toList();
}

class LocalMedication {
  const LocalMedication({
    required this.id,
    required this.name,
    this.dosageLabel,
    this.scheduleHint,
  });

  final String id;
  final String name;
  final String? dosageLabel;
  final String? scheduleHint;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (dosageLabel != null) 'dosage_label': dosageLabel,
        if (scheduleHint != null) 'schedule_hint': scheduleHint,
      };

  factory LocalMedication.fromJson(Map<String, dynamic> j) {
    return LocalMedication(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      dosageLabel: j['dosage_label']?.toString(),
      scheduleHint: j['schedule_hint']?.toString(),
    );
  }
}

class LocalDoseLog {
  const LocalDoseLog({
    required this.id,
    required this.medicationName,
    required this.status,
    required this.recordedAtIso,
    this.note,
  });

  final String id;
  final String medicationName;
  /// taken | missed | skipped
  final String status;
  final String recordedAtIso;
  final String? note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'medication_name': medicationName,
        'status': status,
        'recorded_at': recordedAtIso,
        if (note != null && note!.isNotEmpty) 'note': note,
      };

  factory LocalDoseLog.fromJson(Map<String, dynamic> j) {
    return LocalDoseLog(
      id: j['id']?.toString() ?? '',
      medicationName: j['medication_name']?.toString() ?? '',
      status: j['status']?.toString() ?? 'taken',
      recordedAtIso: j['recorded_at']?.toString() ?? '',
      note: j['note']?.toString(),
    );
  }
}

class LocalCareNote {
  const LocalCareNote({
    required this.id,
    required this.text,
    required this.atIso,
  });

  final String id;
  final String text;
  final String atIso;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'at': atIso,
      };

  factory LocalCareNote.fromJson(Map<String, dynamic> j) {
    return LocalCareNote(
      id: j['id']?.toString() ?? '',
      text: j['text']?.toString() ?? '',
      atIso: j['at']?.toString() ?? '',
    );
  }
}

class LocalReminderDraft {
  const LocalReminderDraft({
    required this.id,
    required this.title,
    this.detail,
    required this.atIso,
  });

  final String id;
  final String title;
  final String? detail;
  final String atIso;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (detail != null && detail!.isNotEmpty) 'detail': detail,
        'at': atIso,
      };

  factory LocalReminderDraft.fromJson(Map<String, dynamic> j) {
    return LocalReminderDraft(
      id: j['id']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      detail: j['detail']?.toString(),
      atIso: j['at']?.toString() ?? '',
    );
  }
}

/// Kết quả thực thi tool trên client.
class LocalAgentApplyResult {
  const LocalAgentApplyResult({
    required this.state,
    required this.summaries,
  });

  final LocalMedintelState state;
  final List<String> summaries;
}
