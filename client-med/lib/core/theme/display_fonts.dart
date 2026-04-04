/// Font hiển thị — id lưu [SharedPreferences], map sang Google Fonts.
abstract final class DisplayFontIds {
  static const String inter = 'inter';
  static const String roboto = 'roboto';
  static const String openSans = 'open_sans';
  static const String notoSans = 'noto_sans';
  static const String lato = 'lato';

  static const String defaultId = inter;

  static const List<({String id, String label})> choices = [
    (id: inter, label: 'Inter (mặc định)'),
    (id: roboto, label: 'Roboto'),
    (id: openSans, label: 'Open Sans'),
    (id: notoSans, label: 'Noto Sans'),
    (id: lato, label: 'Lato'),
  ];

  static String normalize(String? raw) {
    final ids = {for (final c in choices) c.id};
    if (raw != null && ids.contains(raw)) return raw;
    return defaultId;
  }
}
