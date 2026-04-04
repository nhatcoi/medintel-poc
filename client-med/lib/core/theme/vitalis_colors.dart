import 'package:flutter/material.dart';

/// Token màu **Vitalis Clarity** + [DESIGN.md] (MedIntel).
/// Không dùng viền 1px đặc — phân tầng bằng surface & độ trong suốt.
abstract final class VitalisColors {
  VitalisColors._();

  // —— Brand (kit + DESIGN) ——
  static const Color primary = Color(0xFF005FB8);
  static const Color primaryContainer = Color(0xFF5F9EFB);
  static const Color primaryDim = Color(0xFF3D7FC8);

  static const Color secondary = Color(0xFF546E7A);
  static const Color secondaryContainer = Color(0xFFE3E8EB);
  static const Color onSecondaryContainer = Color(0xFF2D333A);

  static const Color tertiary = Color(0xFF2E7D32);
  static const Color tertiaryBright = Color(0xFF1C6D25);

  static const Color neutral = Color(0xFF75777B);

  /// Nhãn/icon tab bottom bar khi không chọn (Stitch: xám xanh nhạt).
  static const Color navBarInactive = Color(0xFF78909C);

  // —— Surfaces (DESIGN “No-Line”) ——
  static const Color background = Color(0xFFF8F9FE);
  static const Color surface = Color(0xFFF8F9FE);
  static const Color surfaceBright = Color(0xFFF8F9FE);
  static const Color surfaceContainerLow = Color(0xFFF1F4F9);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerHighest = Color(0xFFF6F7FB);

  // —— On-* ——
  static const Color onBackground = Color(0xFF2D333A);
  static const Color onSurface = Color(0xFF2D333A);
  static const Color onSurfaceVariant = Color(0xFF5C6269);

  /// Viền “ghost” — DESIGN: outline-variant @ 15% opacity.
  static const Color outlineVariantBase = Color(0xFFADB2BA);

  static Color get outlineGhost => outlineVariantBase.withValues(alpha: 0.15);

  static Color get focusRing => primaryDim.withValues(alpha: 0.45);

  // —— Caregiver / trạng thái lâm sàng (mock + accessibility) ——
  static const Color caregiverHeroBlue = Color(0xFF1A56C5);
  static const Color statusSuccess = Color(0xFF2D8A4E);
  static const Color statusSuccessSoft = Color(0xFFE8F5E9);
  static const Color statusError = Color(0xFFB71C1C);
  static const Color statusErrorSoft = Color(0xFFFFEBEE);
  static const Color statusUpcomingIcon = Color(0xFFB0BEC5);
  static const Color chipDateBackground = Color(0xFFE3F2FD);
  static const Color chipDateForeground = Color(0xFF1565C0);

  /// Bóng khuếch tán (DESIGN §4): 0 20px 40px rgba(45,51,58,0.06)
  static List<BoxShadow> get ambientFloating => [
        BoxShadow(
          color: const Color(0xFF2D333A).withValues(alpha: 0.06),
          blurRadius: 40,
          offset: const Offset(0, 20),
        ),
      ];
}
