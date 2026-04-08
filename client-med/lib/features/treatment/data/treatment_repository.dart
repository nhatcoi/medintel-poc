import 'package:dio/dio.dart';

import '../../../services/api_service.dart';
import 'treatment_models.dart';

class TreatmentRepository {
  const TreatmentRepository(this._api);

  final ApiService _api;

  Future<List<MedicationItem>> listMedications(String profileId) async {
    final resp = await _api.client.get<Map<String, dynamic>>(
      '/api/v1/treatment/medications',
      queryParameters: {'profile_id': profileId},
      options: Options(receiveTimeout: const Duration(seconds: 30)),
    );
    final raw = resp.data?['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => MedicationItem.fromJson(Map<String, dynamic>.from(e)))
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
      '/api/v1/treatment/medications',
      data: {
        'profile_id': profileId,
        'medication_name': medicationName,
        'dosage': dosage,
        'frequency': frequency,
        'instructions': instructions,
        'schedule_times': scheduleTimes,
      },
    );
    final data = resp.data;
    if (data == null) throw const FormatException('Empty medication response');
    return MedicationItem.fromJson(data);
  }

  Future<MedicationItem> updateMedication({
    required String medicationId,
    String? medicationName,
    String? dosage,
    String? frequency,
    String? instructions,
    String? status,
    List<String>? scheduleTimes,
  }) async {
    final payload = <String, dynamic>{};
    if (medicationName != null) payload['medication_name'] = medicationName;
    if (dosage != null) payload['dosage'] = dosage;
    if (frequency != null) payload['frequency'] = frequency;
    if (instructions != null) payload['instructions'] = instructions;
    if (status != null) payload['status'] = status;
    if (scheduleTimes != null) payload['schedule_times'] = scheduleTimes;

    final resp = await _api.client.patch<Map<String, dynamic>>(
      '/api/v1/treatment/medications/$medicationId',
      data: payload,
    );
    final data = resp.data;
    if (data == null) throw const FormatException('Empty medication response');
    return MedicationItem.fromJson(data);
  }

  Future<MedicationLogItem> createMedicationLog({
    required String medicationId,
    required String profileId,
    required String status,
    String? notes,
  }) async {
    final resp = await _api.client.post<Map<String, dynamic>>(
      '/api/v1/treatment/medications/$medicationId/logs',
      data: {
        'profile_id': profileId,
        'status': status,
        'notes': notes,
      },
    );
    final data = resp.data;
    if (data == null) throw const FormatException('Empty medication log response');
    return MedicationLogItem.fromJson(data);
  }

  Future<List<MedicationLogItem>> listMedicationLogs(String medicationId) async {
    final resp = await _api.client.get<Map<String, dynamic>>(
      '/api/v1/treatment/medications/$medicationId/logs',
    );
    final raw = resp.data?['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => MedicationLogItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<AdherenceSummary> getAdherenceSummary({
    required String profileId,
    int days = 7,
  }) async {
    final resp = await _api.client.get<Map<String, dynamic>>(
      '/api/v1/treatment/adherence/summary',
      queryParameters: {
        'profile_id': profileId,
        'days': days,
      },
    );
    return AdherenceSummary.fromJson(resp.data ?? const {});
  }
}
