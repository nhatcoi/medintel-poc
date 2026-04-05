import '../../../services/api_service.dart';

class AuthUser {
  const AuthUser({required this.id, this.email, this.fullName, required this.role});
  final String id;
  final String? email;
  final String? fullName;
  final String role;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String?,
        fullName: json['full_name'] as String?,
        role: json['role'] as String? ?? 'patient',
      );
}

class AuthResult {
  const AuthResult({required this.token, required this.user});
  final String token;
  final AuthUser user;

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        token: json['access_token'] as String,
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}

class AuthRepository {
  AuthRepository(this._api);
  final ApiService _api;

  Future<AuthResult> deviceSetup({
    required String fullName,
    String? dateOfBirth,
    String? gender,
    String? medicalNotes,
  }) async {
    final resp = await _api.client.post<Map<String, dynamic>>(
      '/api/v1/auth/device-setup',
      data: {
        'full_name': fullName,
        'date_of_birth': dateOfBirth,
        'gender': gender,
        'medical_notes': medicalNotes,
      },
    );
    return AuthResult.fromJson(resp.data!);
  }
}
