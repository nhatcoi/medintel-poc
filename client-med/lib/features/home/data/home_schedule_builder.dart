import '../../treatment/data/treatment_models.dart';
import 'home_schedule_models.dart';

List<HomeDoseSection> buildHomeDoseSections(
  List<MedicationItem> meds,
  List<MedicationLogItem> logs,
  DateTime selectedDate,
) {
  final now = DateTime.now();
  final byTime = <String, List<HomeDoseSectionItem>>{};

  HomeDoseStatus resolveStatus(String medId, String hhmmss) {
    final hms = hhmmss.split(':');
    if (hms.length < 2) return HomeDoseStatus.upcoming;
    final h = int.tryParse(hms[0]) ?? 0;
    final m = int.tryParse(hms[1]) ?? 0;
    final scheduled = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, h, m);

    for (final l in logs) {
      if (l.medicationId != medId) continue;
      final s = l.scheduledDatetime.toLocal();
      if (s.year == selectedDate.year && s.month == selectedDate.month && s.day == selectedDate.day && s.hour == h && s.minute == m) {
        final st = l.status.toLowerCase().trim();
        if (st == 'taken' || st == 'late') return HomeDoseStatus.taken;
        if (st == 'missed' || st == 'skipped') return HomeDoseStatus.missed;
      }
    }

    final isSameDay = selectedDate.year == now.year && selectedDate.month == now.month && selectedDate.day == now.day;
    if (isSameDay && scheduled.isBefore(now.subtract(const Duration(minutes: 30)))) {
      return HomeDoseStatus.missed;
    }
    if (selectedDate.isBefore(DateTime(now.year, now.month, now.day))) {
      return HomeDoseStatus.missed;
    }
    return HomeDoseStatus.upcoming;
  }

  for (final med in meds) {
    final medStatus = (med.status ?? 'active').trim().toLowerCase();
    if (medStatus != 'active') continue;
    for (final time in med.scheduleTimes) {
      final key = time.trim();
      if (key.isEmpty) continue;
      byTime.putIfAbsent(key, () => []);
      byTime[key]!.add(
        HomeDoseSectionItem(
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
      .map((k) => HomeDoseSection(
            timeLabel: k.length >= 5 ? k.substring(0, 5) : k,
            items: byTime[k]!,
          ))
      .toList();
}
