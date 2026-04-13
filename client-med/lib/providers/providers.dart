import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_intel_client/features/auth/data/auth_notifier.dart';
import 'package:med_intel_client/features/auth/data/auth_repository.dart';
import 'package:med_intel_client/features/caregiver/data/caregiver_profiles_state.dart';
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

final activeProfileIdProvider = Provider<String?>((ref) {
  final selected = ref.watch(caregiverProfilesProvider).selectedProfile;
  final selectedId = selected?.profileId.trim();
  if (selectedId != null && selectedId.isNotEmpty) return selectedId;
  final authId = ref.watch(authProvider).user?.id?.trim();
  if (authId != null && authId.isNotEmpty) return authId;
  return null;
});

final activeProfileDisplayNameProvider = Provider<String>((ref) {
  final selected = ref.watch(caregiverProfilesProvider).selectedProfile;
  final selectedName = selected?.displayName.trim();
  if (selectedName != null && selectedName.isNotEmpty) return selectedName;
  final authName = ref.watch(authProvider).user?.fullName?.trim();
  if (authName != null && authName.isNotEmpty) return authName;
  return 'Tôi';
});
