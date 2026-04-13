import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:med_intel_client/l10n/app_localizations.dart';

import '../features/caregiver/data/caregiver_ui_model.dart';
import '../features/home/data/home_ui_model.dart';
import 'local_medintel_state.dart';

/// Gộp dữ liệu đồng bộ database / cache (thuốc + log liều) thành UI Home / Care — không dùng mẫu tĩnh.
class DashboardFromLocal {
  DashboardFromLocal._();

  static HomeUiModel buildHome(
    LocalMedintelState local,
    String userName,
    AppLocalizations l10n,
  ) {
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
                : l10n.dashMedFallback,
            timeLabel: _timeLabelForMed(local, m.name, day, m.scheduleHint, l10n),
            status: _toHomeStatus(_statusForMedOnDay(local, m.name, day)),
            medicationServerId: m.id.trim().isNotEmpty ? m.id.trim() : null,
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
    AppLocalizations l10n,
  ) {
    final home = buildHome(local, patientName, l10n);
    final today = DateTime.now();
    final day = _dateOnly(today);
    final meds = local.medications;

    final medItems = meds
        .map(
          (m) => MedicationDoseItem(
            name: m.name,
            timeLabel: _timeLabelForMed(local, m.name, day, m.scheduleHint, l10n),
            dosageLabel: (m.dosageLabel != null && m.dosageLabel!.trim().isNotEmpty)
                ? m.dosageLabel!.trim()
                : l10n.dashMedFallback,
            status: _toCareStatus(_statusForMedOnDay(local, m.name, day)),
          ),
        )
        .toList();

    final weekly = _weeklyFraction(local, day);
    final alerts = _buildAlerts(local, patientName, day, l10n);

    return CaregiverDashboardUiModel(
      patientName: patientName,
      adherenceFraction: home.adherenceFraction,
      dosesTaken: home.dosesTaken,
      dosesTotal: home.dosesTotal,
      weeklyScoreFraction: weekly,
      weeklyCaption: _weeklyCaption(l10n, weekly),
      vitalsHeadline: l10n.careVitalsDisconnected,
      vitalsSub: l10n.careVitalsSubtitle,
      medicationsDateLabel: _dateChipLabel(today, l10n),
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
    AppLocalizations l10n,
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
      if (dt != null) return _formatTime(dt.toLocal(), l10n);
    }
    final hint = scheduleHint?.trim();
    if (hint != null && hint.isNotEmpty) return hint;
    return l10n.dashTimeInDay;
  }

  static String _formatTime(DateTime t, AppLocalizations l10n) {
    final h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    if (h < 12) return l10n.dashTimeAm(h.toString(), m);
    final h12 = h == 12 ? 12 : h - 12;
    return l10n.dashTimePm(h12.toString(), m);
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

  static String _weeklyCaption(AppLocalizations l10n, double f) {
    if (f >= 0.85) return l10n.weeklyCaptionGood;
    if (f >= 0.55) return l10n.weeklyCaptionOk;
    if (f > 0) return l10n.weeklyCaptionWatch;
    return l10n.weeklyCaptionNoData;
  }

  static String _dateChipLabel(DateTime d, AppLocalizations l10n) {
    final wd = DateFormat.E(l10n.localeName).format(d);
    return '$wd, ${d.day}/${d.month}';
  }

  static List<CareAlertItem> _buildAlerts(
    LocalMedintelState local,
    String patientName,
    DateTime day,
    AppLocalizations l10n,
  ) {
    final out = <CareAlertItem>[];
    final shortName =
        patientName.trim().isEmpty ? l10n.dashUserFallback : patientName.trim();

    for (final m in local.medications) {
      if (_statusForMedOnDay(local, m.name, day) == _MedDayStatus.missed) {
        out.add(
          CareAlertItem(
            isUrgent: true,
            title: l10n.dashAlertMissedTitle(shortName),
            subtitle: l10n.dashAlertMissedSubtitle(m.name, l10n.dashTodayLocalNote),
            actionLabel: l10n.careOpenAiChat,
            opensAiChat: true,
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
          title: l10n.dashAlertCareNote,
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
