import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:med_intel_client/core/theme/display_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shared_preferences_provider.dart';

const _kFontId = 'display_font_id';
const _kTextScale = 'display_text_scale';

class DisplayPreferencesState {
  const DisplayPreferencesState({
    required this.fontId,
    required this.textScale,
  });

  final String fontId;
  final double textScale;

  static const double minTextScale = 0.85;
  static const double maxTextScale = 1.35;

  DisplayPreferencesState copyWith({String? fontId, double? textScale}) {
    return DisplayPreferencesState(
      fontId: fontId ?? this.fontId,
      textScale: textScale ?? this.textScale,
    );
  }

  static DisplayPreferencesState read(SharedPreferences prefs) {
    final font = DisplayFontIds.normalize(prefs.getString(_kFontId));
    final scale = (prefs.getDouble(_kTextScale) ?? 1.0).clamp(minTextScale, maxTextScale);
    return DisplayPreferencesState(fontId: font, textScale: scale);
  }
}

class DisplayPreferencesNotifier extends Notifier<DisplayPreferencesState> {
  static const _memoryDefault = DisplayPreferencesState(
    fontId: DisplayFontIds.defaultId,
    textScale: 1.0,
  );

  @override
  DisplayPreferencesState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    if (prefs == null) return _memoryDefault;
    return DisplayPreferencesState.read(prefs);
  }

  void setFontId(String id) {
    final normalized = DisplayFontIds.normalize(id);
    state = state.copyWith(fontId: normalized);
    final p = ref.read(sharedPreferencesProvider);
    if (p != null) {
      Future<void>.microtask(() => p.setString(_kFontId, normalized));
    }
  }

  void setTextScale(double scale) {
    final clamped = scale.clamp(
      DisplayPreferencesState.minTextScale,
      DisplayPreferencesState.maxTextScale,
    );
    state = state.copyWith(textScale: clamped);
    final p = ref.read(sharedPreferencesProvider);
    if (p != null) {
      Future<void>.microtask(() => p.setDouble(_kTextScale, clamped));
    }
  }
}

final displayPreferencesProvider =
    NotifierProvider<DisplayPreferencesNotifier, DisplayPreferencesState>(
  DisplayPreferencesNotifier.new,
);
