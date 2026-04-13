class MedicationItem {
  const MedicationItem({
    required this.medicationId,
    required this.name,
    this.dosage,
    this.frequency,
    this.instructions,
    this.status,
    this.remainingQuantity,
    this.quantityUnit,
    this.scheduleTimes = const [],
  });

  final String medicationId;
  final String name;
  final String? dosage;
  final String? frequency;
  final String? instructions;
  final String? status;
  final double? remainingQuantity;
  final String? quantityUnit;
  final List<String> scheduleTimes;

  MedicationItem copyWith({
    List<String>? scheduleTimes,
  }) {
    return MedicationItem(
      medicationId: medicationId,
      name: name,
      dosage: dosage,
      frequency: frequency,
      instructions: instructions,
      status: status,
      remainingQuantity: remainingQuantity,
      quantityUnit: quantityUnit,
      scheduleTimes: scheduleTimes ?? this.scheduleTimes,
    );
  }

  factory MedicationItem.fromJson(Map<String, dynamic> json) {
    final rawSlots = json['schedule_times'];
    final slots = <String>[];
    if (rawSlots is List) {
      for (final e in rawSlots) {
        if (e is Map && e['scheduled_time'] != null) {
          slots.add(e['scheduled_time'].toString());
        }
      }
    }
    return MedicationItem(
      medicationId: (json['medication_id'] ?? '').toString(),
      name: (json['name'] ?? json['medication_name'] ?? '').toString(),
      dosage: json['dosage']?.toString(),
      frequency: json['frequency']?.toString(),
      instructions: json['instructions']?.toString(),
      status: json['status']?.toString(),
      remainingQuantity: (json['remaining_quantity'] as num?)?.toDouble(),
      quantityUnit: json['quantity_unit']?.toString(),
      scheduleTimes: slots,
    );
  }
}

class MedicationLogItem {
  const MedicationLogItem({
    required this.logId,
    required this.medicationId,
    required this.medicationName,
    required this.status,
    required this.scheduledDatetime,
    this.actualDatetime,
    this.notes,
  });

  final String logId;
  final String medicationId;
  final String medicationName;
  final String status;
  final DateTime scheduledDatetime;
  final DateTime? actualDatetime;
  final String? notes;

  factory MedicationLogItem.fromJson(Map<String, dynamic> json) {
    return MedicationLogItem(
      logId: (json['log_id'] ?? '').toString(),
      medicationId: (json['medication_id'] ?? '').toString(),
      medicationName: (json['medication_name'] ?? '').toString(),
      status: (json['status'] ?? 'taken').toString(),
      scheduledDatetime: DateTime.tryParse(json['scheduled_datetime']?.toString() ?? '') ??
          DateTime.now(),
      actualDatetime: DateTime.tryParse(json['actual_datetime']?.toString() ?? ''),
      notes: json['notes']?.toString(),
    );
  }
}

class MedicationScheduleItem {
  const MedicationScheduleItem({
    required this.scheduleId,
    required this.medicationId,
    required this.scheduledTime,
    required this.reminderEnabled,
    this.status,
  });

  final String scheduleId;
  final String medicationId;
  final String scheduledTime;
  final bool reminderEnabled;
  final String? status;

  factory MedicationScheduleItem.fromJson(Map<String, dynamic> json) {
    return MedicationScheduleItem(
      scheduleId: (json['schedule_id'] ?? '').toString(),
      medicationId: (json['medication_id'] ?? '').toString(),
      scheduledTime: (json['scheduled_time'] ?? '').toString(),
      reminderEnabled: json['reminder_enabled'] as bool? ?? true,
      status: json['status']?.toString(),
    );
  }
}

class AdherenceSummary {
  const AdherenceSummary({
    required this.total,
    required this.taken,
    required this.missed,
    required this.skipped,
    required this.late,
    required this.days,
    required this.complianceRate,
    required this.onTimeRate,
  });

  final int total;
  final int taken;
  final int missed;
  final int skipped;
  final int late;
  final int days;
  final double complianceRate;
  final double onTimeRate;

  factory AdherenceSummary.fromJson(Map<String, dynamic> json) {
    return AdherenceSummary(
      total: (json['total'] as num?)?.toInt() ??
          (json['total_scheduled'] as num?)?.toInt() ??
          0,
      taken: (json['taken'] as num?)?.toInt() ?? 0,
      missed: (json['missed'] as num?)?.toInt() ?? 0,
      skipped: (json['skipped'] as num?)?.toInt() ?? 0,
      late: (json['late'] as num?)?.toInt() ?? 0,
      days: (json['days'] as num?)?.toInt() ?? 7,
      complianceRate: (json['compliance_rate'] as num?)?.toDouble() ?? 0,
      onTimeRate: (json['on_time_rate'] as num?)?.toDouble() ?? 0,
    );
  }
}

class NextDoseInfo {
  const NextDoseInfo({
    required this.medicationId,
    required this.medicationName,
    required this.scheduleId,
    required this.scheduledDatetime,
  });

  final String medicationId;
  final String medicationName;
  final String scheduleId;
  final DateTime scheduledDatetime;

  factory NextDoseInfo.fromJson(Map<String, dynamic> json) {
    return NextDoseInfo(
      medicationId: (json['medication_id'] ?? '').toString(),
      medicationName: (json['medication_name'] ?? '').toString(),
      scheduleId: (json['schedule_id'] ?? '').toString(),
      scheduledDatetime:
          DateTime.tryParse((json['scheduled_datetime'] ?? '').toString()) ??
              DateTime.now(),
    );
  }
}

class MissedDoseItem {
  const MissedDoseItem({
    required this.medicationId,
    required this.medicationName,
    required this.scheduleId,
    required this.scheduledDatetime,
    required this.minutesOverdue,
  });

  final String medicationId;
  final String medicationName;
  final String scheduleId;
  final DateTime scheduledDatetime;
  final int minutesOverdue;

  factory MissedDoseItem.fromJson(Map<String, dynamic> json) {
    return MissedDoseItem(
      medicationId: (json['medication_id'] ?? '').toString(),
      medicationName: (json['medication_name'] ?? '').toString(),
      scheduleId: (json['schedule_id'] ?? '').toString(),
      scheduledDatetime:
          DateTime.tryParse((json['scheduled_datetime'] ?? '').toString()) ??
              DateTime.now(),
      minutesOverdue: (json['minutes_overdue'] as num?)?.toInt() ?? 0,
    );
  }
}
