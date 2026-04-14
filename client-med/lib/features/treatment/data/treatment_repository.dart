import 'package:dio/dio.dart';

import '../../../services/api_service.dart';
import '../../../core/constants/api_paths.dart';
import 'treatment_models.dart';

class TreatmentRepository {
  const TreatmentRepository(this._api);

  final ApiService _api;

  Future<List<MedicationItem>> listMedications(String profileId) async {
    final resp = await _api.client.get<Map<String, dynamic>>(
      ApiPaths.treatmentMedications,
      queryParameters: {'profile_id': profileId},
      options: Options(receiveTimeout: const Duration(seconds: 30)),
    );
    final raw = resp.data?['items'] ?? resp.data?['medications'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => MedicationItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<MedicationScheduleItem>> listSchedulesByProfile(String profileId) async {
    final resp = await _api.client.get(
      ApiPaths.treatmentSchedules,
      queryParameters: {'profile_id': profileId},
      options: Options(receiveTimeout: const Duration(seconds: 30)),
    );
    final data = resp.data;
    final raw = data is List ? data : (data is Map<String, dynamic> ? data['items'] : null);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => MedicationScheduleItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<MedicationItem> createMedication({
    required String profileId,
    required String medicationName,
    String? dosage,
    String? frequency,
    String? instructions,
    List<String> scheduleTimes = const [],
  }) async {
    final resp = await _api.client.post<Map<String, dynamic>>(
      ApiPaths.treatmentMedications,
      data: {
        'profile_id': profileId,
        'medication_name': medicationName,
        'dosage': dosage,
        'frequency': frequency,
        'instructions': instructions,
        'start_date': DateTime.now().toUtc().toIso8601String().split('T').first,
      },
    );
    final data = resp.data;
    if (data == null) throw const FormatException('Empty medication response');
    final item = MedicationItem.fromJson(data);
    for (final t in scheduleTimes) {
      final clean = t.trim();
      if (clean.isEmpty) continue;
      final normalized = clean.length == 5 ? '$clean:00' : clean;
      await createSchedule(
        medicationId: item.medicationId,
        scheduledTime: normalized,
      );
    }
    final schedules = await listSchedules(item.medicationId);
    return item.copyWith(
      scheduleTimes: schedules.map((s) => s.scheduledTime).toList(),
    );
  }

  Future<MedicationItem> updateMedication({
    required String medicationId,
    String? medicationName,
    String? dosage,
    String? frequency,
    String? instructions,
    String? status,
    double? remainingQuantity,
    String? quantityUnit,
    List<String>? scheduleTimes,
  }) async {
    final payload = <String, dynamic>{};
    if (medicationName != null) payload['medication_name'] = medicationName;
    if (dosage != null) payload['dosage'] = dosage;
    if (frequency != null) payload['frequency'] = frequency;
    if (instructions != null) payload['instructions'] = instructions;
    if (status != null) payload['status'] = status;
    if (remainingQuantity != null) payload['remaining_quantity'] = remainingQuantity;
    if (quantityUnit != null) payload['quantity_unit'] = quantityUnit;
    if (scheduleTimes != null) payload['schedule_times'] = scheduleTimes;

    final resp = await _api.client.patch<Map<String, dynamic>>(
      '${ApiPaths.treatmentMedications}/$medicationId',
      data: payload,
    );
    final data = resp.data;
    if (data == null) throw const FormatException('Empty medication response');
    return MedicationItem.fromJson(data);
  }

  Future<MedicationItem> updateMedicationInventory({
    required String medicationId,
    required double remainingQuantity,
    String? quantityUnit,
    double? lowStockThreshold,
  }) async {
    final resp = await _api.client.patch<Map<String, dynamic>>(
      '${ApiPaths.treatmentMedications}/$medicationId/inventory',
      data: {
        'remaining_quantity': remainingQuantity,
        if (quantityUnit != null) 'quantity_unit': quantityUnit,
        if (lowStockThreshold != null) 'low_stock_threshold': lowStockThreshold,
      },
    );
    final data = resp.data;
    if (data == null) throw const FormatException('Empty inventory response');
    return MedicationItem.fromJson(data);
  }

  Future<MedicationItem> consumeMedication({
    required String medicationId,
    double amount = 1.0,
  }) async {
    final resp = await _api.client.post<Map<String, dynamic>>(
      '${ApiPaths.treatmentMedications}/$medicationId/consume',
      data: {'amount': amount},
    );
    final data = resp.data;
    if (data == null) throw const FormatException('Empty consume response');
    return MedicationItem.fromJson(data);
  }

  Future<MedicationLogItem> createMedicationLog({
    required String medicationId,
    required String profileId,
    required String status,
    String? scheduledTime,
    DateTime? scheduledDate,
    String? notes,
  }) async {
    final schedules = await listSchedules(medicationId);
    if (schedules.isEmpty) {
      throw const FormatException('No schedule found for medication');
    }
    MedicationScheduleItem selected = schedules.first;
    final hhmm = scheduledTime?.trim();
    if (hhmm != null && hhmm.isNotEmpty) {
      for (final s in schedules) {
        final normalized = s.scheduledTime.length >= 5
            ? s.scheduledTime.substring(0, 5)
            : s.scheduledTime;
        if (normalized == hhmm) {
          selected = s;
          break;
        }
      }
    }

    final nowUtc = DateTime.now().toUtc();
    DateTime scheduledUtc = nowUtc;
    if (scheduledDate != null && hhmm != null && RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(hhmm)) {
      final parts = hhmm.split(':');
      final scheduledLocal = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      scheduledUtc = scheduledLocal.toUtc();
    }
    final resp = await _api.client.post<Map<String, dynamic>>(
      '${ApiPaths.treatmentMedications}/$medicationId/logs',
      data: {
        'schedule_id': selected.scheduleId,
        'profile_id': profileId,
        'status': status,
        'scheduled_datetime': scheduledUtc.toIso8601String(),
        'actual_datetime': nowUtc.toIso8601String(),
        'notes': notes,
      },
    );
    final data = resp.data;
    if (data == null) throw const FormatException('Empty medication log response');
    return MedicationLogItem.fromJson(data);
  }

  Future<List<MedicationLogItem>> listMedicationLogs(String medicationId) async {
    final resp = await _api.client.get(
      '${ApiPaths.treatmentMedications}/$medicationId/logs',
    );
    final data = resp.data;
    final raw = data is List ? data : (data is Map<String, dynamic> ? data['items'] : null);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => MedicationLogItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<MedicationLogItem>> listLogsByProfile(String profileId) async {
    final resp = await _api.client.get(
      ApiPaths.treatmentLogs,
      queryParameters: {'profile_id': profileId},
    );
    final data = resp.data;
    final raw = data is List ? data : (data is Map<String, dynamic> ? data['items'] : null);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => MedicationLogItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<MedicationLogItem> updateMedicationLog({
    required String medicationId,
    required String logId,
    String? status,
    String? notes,
  }) async {
    final payload = <String, dynamic>{};
    if (status != null) payload['status'] = status;
    if (notes != null) payload['notes'] = notes;
    if (status != null) {
      payload['actual_datetime'] = DateTime.now().toUtc().toIso8601String();
    }
    final resp = await _api.client.patch<Map<String, dynamic>>(
      '${ApiPaths.treatmentMedications}/$medicationId/logs/$logId',
      data: payload,
    );
    final data = resp.data;
    if (data == null) throw const FormatException('Empty medication log response');
    return MedicationLogItem.fromJson(data);
  }

  Future<List<MedicationScheduleItem>> listSchedules(String medicationId) async {
    final resp = await _api.client.get(
      '${ApiPaths.treatmentMedications}/$medicationId/schedules',
    );
    final data = resp.data;
    final raw = data is List ? data : (data is Map<String, dynamic> ? data['items'] : null);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => MedicationScheduleItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<MedicationScheduleItem> createSchedule({
    required String medicationId,
    required String scheduledTime,
  }) async {
    final resp = await _api.client.post<Map<String, dynamic>>(
      '${ApiPaths.treatmentMedications}/$medicationId/schedules',
      data: {
        'scheduled_time': scheduledTime,
        'status': 'active',
      },
    );
    final data = resp.data;
    if (data == null) throw const FormatException('Empty schedule response');
    return MedicationScheduleItem.fromJson(data);
  }

  Future<AdherenceSummary> getAdherenceSummary({
    required String profileId,
    int days = 7,
  }) async {
    final resp = await _api.client.get<Map<String, dynamic>>(
      ApiPaths.treatmentAdherenceSummary,
      queryParameters: {
        'profile_id': profileId,
        'days': days,
      },
    );
    return AdherenceSummary.fromJson(resp.data ?? const {});
  }

  Future<NextDoseInfo?> getNextDose(String profileId) async {
    try {
      final resp = await _api.client.get<Map<String, dynamic>>(
        ApiPaths.treatmentNextDose,
        queryParameters: {'profile_id': profileId},
      );
      final data = resp.data;
      if (data == null) return null;
      return NextDoseInfo.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<List<MissedDoseItem>> getMissedDoseCheck(
    String profileId, {
    int graceMinutes = 60,
  }) async {
    final resp = await _api.client.get<Map<String, dynamic>>(
      ApiPaths.treatmentMissedDoseCheck,
      queryParameters: {
        'profile_id': profileId,
        'grace_minutes': graceMinutes,
      },
    );
    final raw = resp.data?['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => MissedDoseItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
