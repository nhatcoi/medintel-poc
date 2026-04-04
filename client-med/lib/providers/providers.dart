import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_intel_client/services/api_service.dart';
import 'package:med_intel_client/services/ocr_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final ocrServiceProvider = Provider<OcrService>((ref) => OcrService());
