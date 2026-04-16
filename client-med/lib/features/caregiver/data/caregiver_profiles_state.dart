import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local_medintel_state.dart';
import '../../../providers/providers.dart';
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
  bool _initialized = false;

  @override
  CareProfilesState build() {
    // Return empty initially, load in microtask or via an explicit fetch
    if (!_initialized) {
      _initialized = true;
      Future.microtask(_fetchFromBackend);
    }
    return const CareProfilesState();
  }

  Future<void> _fetchFromBackend() async {
    try {
      final api = ref.read(apiServiceProvider);
      final profileId = ref.read(authProvider).user?.id;
      if (profileId == null) return;

      // Fetch dynamic groups where user is a caregiver
      final response = await api.client.get(
        '/api/v1/care/my-patients',
        queryParameters: {'profile_id': profileId},
      );
      if (response.data is List) {
        final List<CareProfile> remoteProfiles = [];
        for (var item in response.data) {
          final pId = item['id']?.toString() ?? '';
          if (pId.isEmpty) continue;
          remoteProfiles.add(CareProfile(
            id: 'p_$pId', // temporary UI id
            profileId: pId,
            displayName: item['full_name']?.toString() ?? 'Ng\u01b0\u1eddi d\u00f9ng',
            relationshipLabel: item['role']?.toString() ?? 'Patient',
            localState: LocalMedintelState.empty,
          ));
        }

        // Keep "Bạn" (primary) profile automatically if needed, or if it comes from my-patients?
        // Usually caregivers manage *other* patients. But let's check `authProvider`.
        await syncPrimaryProfile(
           displayName: "Tôi", 
           profileId: ref.read(authProvider).user?.id ?? "", 
           localState: LocalMedintelState.empty,
           silent: true, // Internal silent sync
        );
        
        final existingPrimary = state.profiles.where((p) => p.id == 'primary').toList();
        final finalProfiles = [...existingPrimary, ...remoteProfiles];

        state = state.copyWith(
          profiles: finalProfiles,
          selectedProfileId: state.selectedProfileId ?? 'primary',
        );
      }
    } catch (e) {
      // Fallback
    }
  }

  Future<void> syncPrimaryProfile({
    required String displayName,
    required String profileId,
    required LocalMedintelState localState,
    bool silent = false,
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
      profileId: profileId.trim().isEmpty ? (existing?.profileId ?? '') : profileId.trim(),
      displayName: displayName.trim().isEmpty ? 'B\u1ea3n th\u00e2n' : displayName.trim(),
      relationshipLabel: 'C\u00e1 nh\u00e2n',
      localState: localState,
    );
    
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
  }

  Future<void> addProfile({
    required String profileId,
    required String displayName,
    required String relationshipLabel,
  }) async {
    // Re-fetch from backend to update state correctly
    await _fetchFromBackend();
  }

  Future<void> selectProfile(String id) async {
    if (state.profiles.every((p) => p.id != id)) return;
    state = state.copyWith(selectedProfileId: id);
  }
}
