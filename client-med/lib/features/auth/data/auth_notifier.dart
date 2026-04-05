import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/api_service.dart';
import 'auth_repository.dart';

enum OnboardStatus { unknown, firstTime, completed }

class AuthState {
  const AuthState({this.status = OnboardStatus.unknown, this.user, this.token});
  final OnboardStatus status;
  final AuthUser? user;
  final String? token;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo, this._api, this._prefs) : super(const AuthState()) {
    _tryRestore();
  }

  final AuthRepository _repo;
  final ApiService _api;
  final SharedPreferences? _prefs;

  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';
  static const _userNameKey = 'auth_user_name';
  static const _setupDoneKey = 'setup_done';

  void _tryRestore() {
    final done = _prefs?.getBool(_setupDoneKey) ?? false;
    if (done) {
      final token = _prefs?.getString(_tokenKey) ?? '';
      final user = AuthUser(
        id: _prefs?.getString(_userIdKey) ?? '',
        fullName: _prefs?.getString(_userNameKey),
        role: 'patient',
      );
      if (token.isNotEmpty) _api.setAuthToken(token);
      state = AuthState(status: OnboardStatus.completed, user: user, token: token);
    } else {
      state = const AuthState(status: OnboardStatus.firstTime);
    }
  }

  Future<void> completeSetup({
    required String fullName,
    String? dateOfBirth,
    String? gender,
    String? medicalNotes,
  }) async {
    final result = await _repo.deviceSetup(
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      medicalNotes: medicalNotes,
    );
    _api.setAuthToken(result.token);
    _prefs?.setString(_tokenKey, result.token);
    _prefs?.setString(_userIdKey, result.user.id);
    _prefs?.setString(_userNameKey, result.user.fullName ?? fullName);
    _prefs?.setBool(_setupDoneKey, true);
    state = AuthState(status: OnboardStatus.completed, user: result.user, token: result.token);
  }

  String get userName => state.user?.fullName ?? 'Bạn';
}
