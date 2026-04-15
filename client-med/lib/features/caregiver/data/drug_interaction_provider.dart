import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/providers.dart';
import '../../treatment/data/treatment_provider.dart';
import 'drug_interaction_models.dart';

final drugInteractionRepositoryProvider =
    Provider<DrugInteractionRepository>(
  (ref) => DrugInteractionRepository(ref.watch(apiServiceProvider)),
);

class DrugInteractionState {
  const DrugInteractionState({
    this.loading = false,
    this.pairs = const [],
    this.error,
    this.lastDrugKey = '',
  });

  final bool loading;
  final List<DrugInteractionPair> pairs;
  final String? error;
  final String lastDrugKey;

  DrugInteractionState copyWith({
    bool? loading,
    List<DrugInteractionPair>? pairs,
    String? error,
    String? lastDrugKey,
  }) =>
      DrugInteractionState(
        loading: loading ?? this.loading,
        pairs: pairs ?? this.pairs,
        error: error,
        lastDrugKey: lastDrugKey ?? this.lastDrugKey,
      );
}

/// Auto-rechecks interactions whenever the active medication list changes.
/// Keys the cache on a normalised drug-name set so we don't re-hit the server
/// while the user is simply navigating.
final drugInteractionProvider = StateNotifierProvider<
    DrugInteractionNotifier, DrugInteractionState>((ref) {
  final notifier = DrugInteractionNotifier(
    ref.watch(drugInteractionRepositoryProvider),
  );
  ref.listen(treatmentProvider, (prev, next) {
    final drugs = next.items
        .where((m) => (m.status ?? 'active').toLowerCase() == 'active')
        .map((m) => m.name.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    notifier.maybeCheck(drugs);
  }, fireImmediately: true);
  return notifier;
});

class DrugInteractionNotifier extends StateNotifier<DrugInteractionState> {
  DrugInteractionNotifier(this._repo) : super(const DrugInteractionState());

  final DrugInteractionRepository _repo;

  String _key(List<String> drugs) {
    final normalised = drugs.map((d) => d.toLowerCase()).toList()..sort();
    return normalised.join('|');
  }

  Future<void> maybeCheck(List<String> drugs) async {
    if (drugs.length < 2) {
      state = const DrugInteractionState();
      return;
    }
    final key = _key(drugs);
    if (key == state.lastDrugKey && state.pairs.isNotEmpty) return;
    state = state.copyWith(loading: true, error: null, lastDrugKey: key);
    try {
      final pairs = await _repo.check(drugs);
      state = state.copyWith(loading: false, pairs: pairs, error: null);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> refresh(List<String> drugs) async {
    state = state.copyWith(lastDrugKey: '');
    await maybeCheck(drugs);
  }
}
