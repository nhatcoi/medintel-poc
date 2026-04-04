import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ghi đè trong [main] sau [SharedPreferences.getInstance].
///
/// Có thể **null** khi native channel lỗi (thường gặp sau **hot restart** iOS với
/// `shared_preferences`). Lúc đó app vẫn chạy; cài đặt hiển thị chỉ giữ trong RAM.
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) {
  throw StateError('sharedPreferencesProvider must be overridden in ProviderScope');
});
