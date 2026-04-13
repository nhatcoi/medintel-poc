import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local_medintel_state.dart';
import '../../../providers/shared_preferences_provider.dart';

const String _prefsKey = 'caregiver_profiles_v1';

class CareProfile {
  const CareProfile({
    required this.id,
    required this.profileId,
    required this.displayName,
    required this.relationshipLabel,
    required this.localState,
  });

  final String id;
  final String profileId;
  final String displayName;
  final String relationshipLabel;
  final LocalMedintelState localState;

  Map<String, dynamic> toJson() => {
        'id': id,
        'profile_id': profileId,
        'display_name': displayName,
        'relationship_label': relationshipLabel,
        'local_state': localState.toJson(),
      };

  factory CareProfile.fromJson(Map<String, dynamic> json) {
    return CareProfile(
      id: json['id']?.toString() ?? '',
      profileId: json['profile_id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? 'Người thân',
      relationshipLabel: json['relationship_label']?.toString() ?? 'Gia đình',
      localState: LocalMedintelState.fromJson(
        json['local_state'] is Map<String, dynamic>
            ? json['local_state'] as Map<String, dynamic>
            : null,
      ),
    );
  }
}

class CareProfilesState {
  const CareProfilesState({
    this.profiles = const [],
    this.selectedProfileId,
  });

  final List<CareProfile> profiles;
  final String? selectedProfileId;

  CareProfile? get selectedProfile {
    if (profiles.isEmpty) return null;
    final id = selectedProfileId;
    if (id == null || id.isEmpty) return profiles.first;
    for (final p in profiles) {
      if (p.id == id) return p;
    }
    return profiles.first;
  }

  CareProfilesState copyWith({
    List<CareProfile>? profiles,
    String? selectedProfileId,
  }) {
    return CareProfilesState(
      profiles: profiles ?? this.profiles,
      selectedProfileId: selectedProfileId ?? this.selectedProfileId,
    );
  }

  Map<String, dynamic> toJson() => {
        'selected_profile_id': selectedProfileId,
        'profiles': profiles.map((e) => e.toJson()).toList(),
      };

  factory CareProfilesState.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CareProfilesState();
    final raw = json['profiles'];
    final profiles = <CareProfile>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          profiles.add(CareProfile.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return CareProfilesState(
      profiles: profiles,
      selectedProfileId: json['selected_profile_id']?.toString(),
    );
  }
}

final caregiverProfilesProvider =
    NotifierProvider<CaregiverProfilesNotifier, CareProfilesState>(
  CaregiverProfilesNotifier.new,
);

class CaregiverProfilesNotifier extends Notifier<CareProfilesState> {
  @override
  CareProfilesState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs?.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return const CareProfilesState();
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) {
        final loaded = CareProfilesState.fromJson(json);
        final cleaned = _cleanupLegacyProfiles(loaded);
        if (_isStateChanged(loaded, cleaned)) {
          Future.microtask(_save);
        }
        return cleaned;
      }
    } catch (_) {}
    return const CareProfilesState();
  }

  CareProfilesState _cleanupLegacyProfiles(CareProfilesState src) {
    String normalize(String s) => s.trim().toLowerCase();
    const blocked = {'124', 'con gai'};
    final profiles = src.profiles.where((p) {
      if (p.id == 'primary') return true;
      final name = normalize(p.displayName);
      final relation = normalize(p.relationshipLabel);
      return !blocked.contains(name) && !blocked.contains(relation);
    }).toList();

    String? selected = src.selectedProfileId;
    if (selected != null && profiles.every((p) => p.id != selected)) {
      selected = profiles.isNotEmpty ? profiles.first.id : null;
    }
    return CareProfilesState(
      profiles: profiles,
      selectedProfileId: selected,
    );
  }

  bool _isStateChanged(CareProfilesState a, CareProfilesState b) {
    return jsonEncode(a.toJson()) != jsonEncode(b.toJson());
  }

  Future<void> syncPrimaryProfile({
    required String displayName,
    required String profileId,
    required LocalMedintelState localState,
  }) async {
    CareProfile? existing;
    for (final p in state.profiles) {
      if (p.id == 'primary') {
        existing = p;
        break;
      }
    }
    final primary = CareProfile(
      id: 'primary',
      profileId: profileId.trim().isEmpty ? (existing?.profileId ?? _randomUuidV4()) : profileId.trim(),
      displayName: displayName.trim().isEmpty ? 'Bạn' : displayName.trim(),
      relationshipLabel: 'Bản thân',
      localState: localState,
    );
    if (existing != null &&
        existing.displayName == primary.displayName &&
        LocalMedintelState.encode(existing.localState) ==
            LocalMedintelState.encode(primary.localState)) {
      return;
    }
    final next = [...state.profiles];
    if (existing == null) {
      next.insert(0, primary);
    } else {
      final idx = next.indexWhere((p) => p.id == 'primary');
      next[idx] = primary;
    }
    state = state.copyWith(
      profiles: next,
      selectedProfileId:
          (state.selectedProfileId == null || state.selectedProfileId!.isEmpty)
              ? 'primary'
              : state.selectedProfileId,
    );
    await _save();
  }

  Future<void> addProfile({
    required String profileId,
    required String displayName,
    required String relationshipLabel,
  }) async {
    final id = 'p_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 24)}';
    final row = CareProfile(
      id: id,
      profileId: profileId,
      displayName: displayName.trim(),
      relationshipLabel: relationshipLabel.trim().isEmpty ? 'Gia đình' : relationshipLabel.trim(),
      localState: LocalMedintelState.empty,
    );
    state = state.copyWith(
      profiles: [...state.profiles, row],
      selectedProfileId: id,
    );
    await _save();
  }

  Future<void> selectProfile(String id) async {
    if (state.profiles.every((p) => p.id != id)) return;
    state = state.copyWith(selectedProfileId: id);
    await _save();
  }

  Future<void> _save() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs?.setString(_prefsKey, jsonEncode(state.toJson()));
  }

  String _randomUuidV4() {
    final rand = Random();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final h = bytes.map(hex).join();
    return '${h.substring(0, 8)}-'
        '${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-'
        '${h.substring(20, 32)}';
  }
}
