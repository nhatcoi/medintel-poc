import 'package:flutter/material.dart';

import '../features/caregiver/data/caregiver_ui_model.dart';
import '../features/home/data/home_ui_model.dart';
import 'local_medintel_state.dart';

/// Gộp dữ liệu cục bộ (thuốc + log liều) thành UI Home / Care — không dùng mẫu tĩnh.
class DashboardFromLocal {
  DashboardFromLocal._();

  static HomeUiModel buildHome(LocalMedintelState local, String userName) {
    final day = _dateOnly(DateTime.now());
    final meds = local.medications;

    if (meds.isEmpty) {
      return HomeUiModel(
        userName: userName,
        adherenceFraction: 0,
        dosesTaken: 0,
        dosesTotal: 0,
        nextDose: null,
        todaySchedule: const [],
      );
    }

    final schedule = meds
        .map(
          (m) => HomeDoseItem(
            name: m.name,
            dosageLabel: (m.dosageLabel != null && m.dosageLabel!.trim().isNotEmpty)
                ? m.dosageLabel!.trim()
                : 'Thuốc',
            timeLabel: _timeLabelForMed(local, m.name, day, m.scheduleHint),
            status: _toHomeStatus(_statusForMedOnDay(local, m.name, day)),
            icon: Icons.medication_rounded,
          ),
        )
        .toList();

    var taken = 0;
    for (final m in meds) {
      if (_statusForMedOnDay(local, m.name, day) == _MedDayStatus.taken) {
        taken++;
      }
    }
    final total = meds.length;
    final fraction = total > 0 ? taken / total : 0.0;

    HomeDoseItem? next;
    for (final item in schedule) {
      if (item.status == HomeDoseStatus.upcoming) {
        next = item;
        break;
      }
    }
    if (next == null) {
      for (final item in schedule) {
        if (item.status == HomeDoseStatus.missed) {
          next = item;
          break;
        }
      }
    }

    return HomeUiModel(
      userName: userName,
      adherenceFraction: fraction,
      dosesTaken: taken,
      dosesTotal: total,
      nextDose: next,
      todaySchedule: schedule,
    );
  }

  static CaregiverDashboardUiModel buildCaregiver(
    LocalMedintelState local,
    String patientName,
  ) {
    final home = buildHome(local, patientName);
    final today = DateTime.now();
    final day = _dateOnly(today);
    final meds = local.medications;

    final medItems = meds
        .map(
          (m) => MedicationDoseItem(
            name: m.name,
            timeLabel: _timeLabelForMed(local, m.name, day, m.scheduleHint),
            dosageLabel: (m.dosageLabel != null && m.dosageLabel!.trim().isNotEmpty)
                ? m.dosageLabel!.trim()
                : 'Thuốc',
            status: _toCareStatus(_statusForMedOnDay(local, m.name, day)),
          ),
        )
        .toList();

    final weekly = _weeklyFraction(local, day);
    final alerts = _buildAlerts(local, patientName, day);

    return CaregiverDashboardUiModel(
      patientName: patientName,
      adherenceFraction: home.adherenceFraction,
      dosesTaken: home.dosesTaken,
      dosesTotal: home.dosesTotal,
      weeklyScoreFraction: weekly,
      weeklyCaption: _weeklyCaptionVi(weekly),
      vitalsHeadline: 'CHƯA KẾT NỐI',
      vitalsSub: 'Sinh hiệu — tích hợp thiết bị sau',
      medicationsDateLabel: _dateChipLabel(today),
      medications: medItems,
      alerts: alerts,
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Log mới nhất trong ngày [day] (local) quyết định trạng thái.
  static _MedDayStatus _statusForMedOnDay(
    LocalMedintelState local,
    String medName,
    DateTime day,
  ) {
    final key = medName.toLowerCase().trim();
    final logs = local.doseLogs
        .where((l) => l.medicationName.toLowerCase().trim() == key)
        .where((l) {
          final dt = DateTime.tryParse(l.recordedAtIso);
          if (dt == null) return false;
          final loc = dt.toLocal();
          return _sameDay(loc, day);
        })
        .toList()
      ..sort((a, b) => b.recordedAtIso.compareTo(a.recordedAtIso));

    if (logs.isEmpty) return _MedDayStatus.upcoming;
    final s = logs.first.status.toLowerCase().trim();
    if (s == 'taken') return _MedDayStatus.taken;
    if (s == 'missed' || s == 'skipped') return _MedDayStatus.missed;
    return _MedDayStatus.upcoming;
  }

  static String _timeLabelForMed(
    LocalMedintelState local,
    String medName,
    DateTime day,
    String? scheduleHint,
  ) {
    final key = medName.toLowerCase().trim();
    final logs = local.doseLogs
        .where((l) => l.medicationName.toLowerCase().trim() == key)
        .where((l) {
          final dt = DateTime.tryParse(l.recordedAtIso);
          if (dt == null) return false;
          return _sameDay(dt.toLocal(), day);
        })
        .toList()
      ..sort((a, b) => b.recordedAtIso.compareTo(a.recordedAtIso));

    if (logs.isNotEmpty) {
      final dt = DateTime.tryParse(logs.first.recordedAtIso);
      if (dt != null) return _formatTimeVi(dt.toLocal());
    }
    final hint = scheduleHint?.trim();
    if (hint != null && hint.isNotEmpty) return hint;
    return 'Trong ngày';
  }

  static String _formatTimeVi(DateTime t) {
    final h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    if (h < 12) return '$h:$m SA';
    final h12 = h == 12 ? 12 : h - 12;
    return '$h12:$m CH';
  }

  static double _weeklyFraction(LocalMedintelState local, DateTime todayStart) {
    final meds = local.medications;
    if (meds.isEmpty) return 0;
    var sum = 0.0;
    for (var i = 0; i < 7; i++) {
      final d = todayStart.subtract(Duration(days: i));
      var t = 0;
      for (final m in meds) {
        if (_statusForMedOnDay(local, m.name, d) == _MedDayStatus.taken) {
          t++;
        }
      }
      sum += t / meds.length;
    }
    return (sum / 7).clamp(0.0, 1.0);
  }

  static String _weeklyCaptionVi(double f) {
    if (f >= 0.85) return 'TIẾN ĐỘ TỐT';
    if (f >= 0.55) return 'ĐANG ỔN ĐỊNH';
    if (f > 0) return 'CẦN THEO DÕI THÊM';
    return 'CHƯA CÓ DỮ LIỆU TUẦN';
  }

  static String _dateChipLabel(DateTime d) {
    const labels = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final i = d.weekday == DateTime.sunday ? 0 : d.weekday;
    return '${labels[i]}, ${d.day}/${d.month}';
  }

  static List<CareAlertItem> _buildAlerts(
    LocalMedintelState local,
    String patientName,
    DateTime day,
  ) {
    final out = <CareAlertItem>[];
    final shortName = patientName.trim().isEmpty ? 'Người dùng' : patientName.trim();

    for (final m in local.medications) {
      if (_statusForMedOnDay(local, m.name, day) == _MedDayStatus.missed) {
        out.add(
          CareAlertItem(
            isUrgent: true,
            title: '$shortName bỏ lỡ / bỏ qua liều',
            subtitle: '${m.name} • hôm nay (dữ liệu cục bộ)',
            actionLabel: 'MỞ AI CHAT',
          ),
        );
      }
    }

    final notes = List<LocalCareNote>.from(local.careNotes)
      ..sort((a, b) => b.atIso.compareTo(a.atIso));
    for (final n in notes.take(2)) {
      final dt = DateTime.tryParse(n.atIso);
      if (dt == null) continue;
      final age = DateTime.now().difference(dt.toLocal());
      if (age.inDays > 7) continue;
      final preview = n.text.length > 80 ? '${n.text.substring(0, 80)}…' : n.text;
      out.add(
        CareAlertItem(
          isUrgent: false,
          title: 'Ghi chú chăm sóc',
          subtitle: preview,
          actionLabel: null,
        ),
      );
    }

    return out;
  }

  static HomeDoseStatus _toHomeStatus(_MedDayStatus s) => switch (s) {
        _MedDayStatus.taken => HomeDoseStatus.taken,
        _MedDayStatus.missed => HomeDoseStatus.missed,
        _MedDayStatus.upcoming => HomeDoseStatus.upcoming,
      };

  static MedicationDoseStatus _toCareStatus(_MedDayStatus s) => switch (s) {
        _MedDayStatus.taken => MedicationDoseStatus.taken,
        _MedDayStatus.missed => MedicationDoseStatus.missed,
        _MedDayStatus.upcoming => MedicationDoseStatus.upcoming,
      };
}

enum _MedDayStatus { taken, missed, upcoming }
