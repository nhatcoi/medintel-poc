import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/constants/app_constants.dart';
import 'api_service.dart';

final class OcrService {
  OcrService(this._api);

  final ApiService _api;

  Future<ScanResult> scanPrescription(
    Uint8List bytes, {
    String filename = 'prescription.jpg',
  }) async {
    final fields = <String, dynamic>{
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    };
    if (AppConstants.prescriptionUserId.isNotEmpty) {
      fields['user_id'] = AppConstants.prescriptionUserId;
    }
    final formData = FormData.fromMap(fields);

    final resp = await _api.client.post<Map<String, dynamic>>(
      '/api/v1/scan/prescription',
      data: formData,
      options: Options(receiveTimeout: const Duration(seconds: 90)),
    );

    return ScanResult.fromJson(resp.data!);
  }
}

class ScanResult {
  const ScanResult({
    this.doctorName,
    this.issuedDate,
    this.patientName,
    this.rawText,
    this.medications = const [],
    this.prescriptionId,
    this.savedMedications = const [],
  });

  final String? doctorName;
  final String? issuedDate;
  final String? patientName;
  final String? rawText;
  final List<ScannedMedication> medications;
  final String? prescriptionId;
  final List<SavedMedicationRef> savedMedications;

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      doctorName: json['doctor_name'] as String?,
      issuedDate: json['issued_date'] as String?,
      patientName: json['patient_name'] as String?,
      rawText: json['raw_text'] as String?,
      medications: (json['medications'] as List<dynamic>? ?? [])
          .map((e) => ScannedMedication.fromJson(e as Map<String, dynamic>))
          .toList(),
      prescriptionId: json['prescription_id'] as String?,
      savedMedications: (json['saved_medications'] as List<dynamic>? ?? [])
          .map((e) => SavedMedicationRef.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SavedMedicationRef {
  const SavedMedicationRef({required this.id, required this.name});

  final String id;
  final String name;

  factory SavedMedicationRef.fromJson(Map<String, dynamic> json) {
    return SavedMedicationRef(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class ScannedMedication {
  const ScannedMedication({
    required this.name,
    this.dosage,
    this.frequency,
    this.instructions,
    this.times = const [],
  });

  final String name;
  final String? dosage;
  final String? frequency;
  final String? instructions;
  final List<String> times;

  factory ScannedMedication.fromJson(Map<String, dynamic> json) {
    return ScannedMedication(
      name: json['name'] as String? ?? 'Unknown',
      dosage: json['dosage'] as String?,
      frequency: json['frequency'] as String?,
      instructions: json['instructions'] as String?,
      times: (json['times'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
