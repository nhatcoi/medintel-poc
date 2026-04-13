import '../../../services/api_service.dart';
import '../../../core/constants/api_paths.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    this.email,
    this.fullName,
    required this.role,
    this.phoneNumber,
  });

  final String id;
  final String? email;
  final String? fullName;
  final String role;
  final String? phoneNumber;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: (json['profile_id'] ?? json['id'] ?? '').toString(),
        email: json['email'] as String?,
        fullName: (json['full_name'] ?? json['fullName']) as String?,
        role: (json['role'] ?? 'patient') as String,
        phoneNumber: json['phone_number'] as String?,
      );
}

class SessionAuthResult {
  const SessionAuthResult({
    required this.sessionToken,
    required this.expiresAt,
    required this.user,
  });

  final String sessionToken;
  final String expiresAt;
  final AuthUser user;

  factory SessionAuthResult.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? json;
    return SessionAuthResult(
      sessionToken: (json['session_token'] ?? '').toString(),
      expiresAt: (json['expires_at'] ?? '').toString(),
      user: AuthUser.fromJson(userJson),
    );
  }
}

class OnboardingProfileResult {
  const OnboardingProfileResult({
    required this.profileId,
    required this.fullName,
  });

  final String profileId;
  final String fullName;

  factory OnboardingProfileResult.fromJson(Map<String, dynamic> json) {
    return OnboardingProfileResult(
      profileId: (json['profile_id'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
    );
  }
}

class AuthRepository {
  AuthRepository(this._api);
  final ApiService _api;

  Future<SessionAuthResult> registerPhone({
    required String fullName,
    required String phoneNumber,
    required String password,
    String role = 'patient',
  }) async {
    final resp = await _api.client.post<Map<String, dynamic>>(
      ApiPaths.authRegisterPhone,
      data: {
        'full_name': fullName,
        'phone_number': phoneNumber,
        'password': password,
        'role': role,
      },
    );
    return SessionAuthResult.fromJson(resp.data ?? {});
  }

  Future<SessionAuthResult> loginPhone({
    required String phoneNumber,
    required String password,
  }) async {
    final resp = await _api.client.post<Map<String, dynamic>>(
      ApiPaths.authLoginPhone,
      data: {
        'phone_number': phoneNumber,
        'password': password,
      },
    );
    return SessionAuthResult.fromJson(resp.data ?? {});
  }

  Future<AuthUser> sessionMe(String sessionToken) async {
    final resp = await _api.client.post<Map<String, dynamic>>(
      ApiPaths.authSessionMe,
      data: {'session_token': sessionToken},
    );
    return AuthUser.fromJson(resp.data ?? {});
  }

  Future<void> logoutPhone(String sessionToken) async {
    await _api.client.post(
      ApiPaths.authLogoutPhone,
      data: {'session_token': sessionToken},
    );
  }

  Future<void> updateOnboardingProfile({
    required String profileId,
    String? fullName,
    String? dateOfBirth,
    String? phoneNumber,
    String? email,
    List<String>? chronicConditions,
    List<String>? allergies,
    List<String>? currentMedications,
    String? primaryDiagnosis,
    String? treatmentStatus,
    String? medicalNotes,
  }) async {
    final payload = <String, dynamic>{};
    if (fullName != null) payload['full_name'] = fullName;
    if (dateOfBirth != null) payload['date_of_birth'] = dateOfBirth;
    if (phoneNumber != null) payload['phone_number'] = phoneNumber;
    if (email != null) payload['email'] = email;
    if (chronicConditions != null) payload['chronic_conditions'] = chronicConditions;
    if (allergies != null) payload['allergies'] = allergies;
    if (currentMedications != null) payload['current_medications'] = currentMedications;
    if (primaryDiagnosis != null) payload['primary_diagnosis'] = primaryDiagnosis;
    if (treatmentStatus != null) payload['treatment_status'] = treatmentStatus;
    if (medicalNotes != null) payload['medical_notes'] = medicalNotes;

    await _api.client.patch<Map<String, dynamic>>(
      '${ApiPaths.profileOnboarding.replaceAll('/onboarding', '')}/$profileId/onboarding',
      data: payload,
    );
  }

  Future<OnboardingProfileResult> createOnboardingProfile({
    required String fullName,
    required String role,
  }) async {
    final resp = await _api.client.post<Map<String, dynamic>>(
      ApiPaths.profileOnboarding,
      data: {
        'full_name': fullName,
        'role': role,
      },
    );
    return OnboardingProfileResult.fromJson(resp.data ?? const {});
  }
}
