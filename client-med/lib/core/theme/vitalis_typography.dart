import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'vitalis_colors.dart';

/// Typography **Inter** — display → label theo DESIGN.md (ưu tiên người cao tuổi).
abstract final class VitalisTypography {
  VitalisTypography._();

  static TextTheme textTheme(ColorScheme scheme) {
    final base = GoogleFonts.interTextTheme();
    final on = scheme.onSurface;

    return base.copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 36,
        height: 44 / 36,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: on,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 32,
        height: 40 / 32,
        fontWeight: FontWeight.w600,
        color: on,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 28,
        height: 36 / 28,
        fontWeight: FontWeight.w600,
        color: on,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 28,
        height: 36 / 28,
        fontWeight: FontWeight.w600,
        color: on,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w600,
        color: on,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 22,
        height: 30 / 22,
        fontWeight: FontWeight.w600,
        color: on,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w700,
        color: on,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w600,
        color: on,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 16,
        height: 22 / 16,
        fontWeight: FontWeight.w600,
        color: on,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 18,
        height: 26 / 18,
        fontWeight: FontWeight.w400,
        color: on,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: on,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: VitalisColors.onSurfaceVariant,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: on,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: VitalisColors.onSurfaceVariant,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        height: 14 / 11,
        fontWeight: FontWeight.w500,
        color: VitalisColors.onSurfaceVariant,
      ),
    );
  }
}
