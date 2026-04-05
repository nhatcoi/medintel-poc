import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_intel_client/data/local_medintel_state.dart';
import 'package:med_intel_client/providers/shared_preferences_provider.dart';
import 'package:med_intel_client/services/local_medintel_store.dart';

/// Trạng thái dữ liệu agent / người dùng lưu cục bộ.
final localMedintelProvider =
    NotifierProvider<LocalMedintelNotifier, LocalMedintelState>(LocalMedintelNotifier.new);

class LocalMedintelNotifier extends Notifier<LocalMedintelState> {
  @override
  LocalMedintelState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return LocalMedintelStore.load(prefs);
  }

  /// Thực thi tool_calls sau khi nhận phản hồi chat; trả về dòng tóm tắt cho UI.
  Future<List<String>> applyAgentToolCalls(List<Map<String, dynamic>> toolCalls) async {
    if (toolCalls.isEmpty) return [];
    final prefs = ref.read(sharedPreferencesProvider);
    final result = LocalMedintelStore.apply(state, toolCalls);
    await LocalMedintelStore.save(prefs, result.state);
    state = result.state;
    return result.summaries;
  }
}
