import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared_preferences_provider.dart';

const _kAppLocaleCode = 'app_locale_code';

/// Mã ngôn ngữ giao diện: `vi` | `en` (lưu prefs thiết bị).
class AppLocaleNotifier extends Notifier<String> {
  static const vi = 'vi';
  static const en = 'en';

  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final code = prefs?.getString(_kAppLocaleCode);
    if (code == en) return en;
    if (code == vi) return vi;
    return vi;
  }

  Future<void> setLanguageCode(String code) async {
    final normalized = code == en ? en : vi;
    state = normalized;
    final p = ref.read(sharedPreferencesProvider);
    if (p != null) {
      await p.setString(_kAppLocaleCode, normalized);
    }
  }
}

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, String>(
  AppLocaleNotifier.new,
);
