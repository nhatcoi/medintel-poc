import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_intel_client/features/auth/data/auth_notifier.dart';
import 'package:med_intel_client/features/auth/data/auth_repository.dart';
import 'package:med_intel_client/providers/shared_preferences_provider.dart';
import 'package:med_intel_client/services/api_service.dart';
import 'package:med_intel_client/services/ocr_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final ocrServiceProvider = Provider<OcrService>(
  (ref) => OcrService(ref.watch(apiServiceProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiServiceProvider)),
);

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(apiServiceProvider),
    ref.watch(sharedPreferencesProvider),
  );
});
