import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/api_service.dart';
import 'auth_repository.dart';

enum OnboardStatus { unknown, firstTime, completed }

class AuthState {
  const AuthState({
    this.status = OnboardStatus.unknown,
    this.user,
    this.sessionToken,
  });

  final OnboardStatus status;
  final AuthUser? user;
  final String? sessionToken;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo, this._api, this._prefs) : super(const AuthState()) {
    _tryRestore();
  }

  final AuthRepository _repo;
  final ApiService _api;
  final SharedPreferences? _prefs;

  static const _sessionTokenKey = 'session_token';
  static const _userIdKey = 'auth_user_id';
  static const _userNameKey = 'auth_user_name';
  static const _userRoleKey = 'auth_user_role';
  static const _userPhoneKey = 'auth_user_phone';

  Future<void> _tryRestore() async {
    final token = _prefs?.getString(_sessionTokenKey);
    if (token == null || token.isEmpty) {
      state = const AuthState(status: OnboardStatus.firstTime);
      return;
    }

    final cachedUser = AuthUser(
      id: _prefs?.getString(_userIdKey) ?? '',
      fullName: _prefs?.getString(_userNameKey),
      role: _prefs?.getString(_userRoleKey) ?? 'patient',
      phoneNumber: _prefs?.getString(_userPhoneKey),
    );
    state = AuthState(
      status: OnboardStatus.completed,
      user: cachedUser,
      sessionToken: token,
    );

    try {
      final user = await _repo.sessionMe(token);
      _persistUser(user);
      state = AuthState(
        status: OnboardStatus.completed,
        user: user,
        sessionToken: token,
      );
    } catch (e) {
      debugPrint('Session restore failed: $e — keeping cached user');
    }
  }

  Future<void> registerPhone({
    required String fullName,
    required String phoneNumber,
    required String password,
  }) async {
    final result = await _repo.registerPhone(
      fullName: fullName,
      phoneNumber: phoneNumber,
      password: password,
    );
    _persistSession(result);
    state = AuthState(
      status: OnboardStatus.completed,
      user: result.user,
      sessionToken: result.sessionToken,
    );
  }

  Future<void> loginPhone({
    required String phoneNumber,
    required String password,
  }) async {
    final result = await _repo.loginPhone(
      phoneNumber: phoneNumber,
      password: password,
    );
    _persistSession(result);
    state = AuthState(
      status: OnboardStatus.completed,
      user: result.user,
      sessionToken: result.sessionToken,
    );
  }

  Future<void> updateOnboardingProfile({
    String? dateOfBirth,
    List<String>? chronicConditions,
    List<String>? allergies,
    String? primaryDiagnosis,
    String? medicalNotes,
  }) async {
    final profileId = state.user?.id;
    if (profileId == null || profileId.isEmpty) return;
    await _repo.updateOnboardingProfile(
      profileId: profileId,
      dateOfBirth: dateOfBirth,
      chronicConditions: chronicConditions,
      allergies: allergies,
      primaryDiagnosis: primaryDiagnosis,
      medicalNotes: medicalNotes,
    );
  }

  Future<void> logout() async {
    final token = state.sessionToken;
    if (token != null && token.isNotEmpty) {
      try {
        await _repo.logoutPhone(token);
      } catch (_) {}
    }
    await _clearPrefs();
    _api.setAuthToken('');
    state = const AuthState(status: OnboardStatus.firstTime);
  }

  String get userName => state.user?.fullName ?? 'Bạn';

  void _persistSession(SessionAuthResult result) {
    _prefs?.setString(_sessionTokenKey, result.sessionToken);
    _persistUser(result.user);
  }

  void _persistUser(AuthUser user) {
    _prefs?.setString(_userIdKey, user.id);
    if (user.fullName != null) _prefs?.setString(_userNameKey, user.fullName!);
    _prefs?.setString(_userRoleKey, user.role);
    if (user.phoneNumber != null) _prefs?.setString(_userPhoneKey, user.phoneNumber!);
  }

  Future<void> _clearPrefs() async {
    await _prefs?.remove(_sessionTokenKey);
    await _prefs?.remove(_userIdKey);
    await _prefs?.remove(_userNameKey);
    await _prefs?.remove(_userRoleKey);
    await _prefs?.remove(_userPhoneKey);
  }
}
