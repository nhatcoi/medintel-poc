/// Vị trí tâm chỉ báo tròn — **5 tab cột đều** (khớp Stitch / mock Caregiver).
class NavSlotMetrics {
  const NavSlotMetrics({required this.width});

  final double width;

  static const int tabCount = 5;

  double get slotWidth => width / tabCount;

  /// Tọa độ X của **tâm** vòng highlight (0 = cạnh trái [LayoutBuilder]).
  double centerXForIndex(int index) {
    assert(index >= 0 && index < tabCount);
    final s = slotWidth;
    return s * index + s / 2;
  }
}
