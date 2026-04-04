import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'display_fonts.dart';
import 'vitalis_colors.dart';

/// Typography theo DESIGN.md — nền Google Fonts, có thể đổi họ font qua [fontId].
abstract final class VitalisTypography {
  VitalisTypography._();

  static TextTheme _googleBase(String fontId) {
    switch (DisplayFontIds.normalize(fontId)) {
      case DisplayFontIds.roboto:
        return GoogleFonts.robotoTextTheme();
      case DisplayFontIds.openSans:
        return GoogleFonts.openSansTextTheme();
      case DisplayFontIds.notoSans:
        return GoogleFonts.notoSansTextTheme();
      case DisplayFontIds.lato:
        return GoogleFonts.latoTextTheme();
      case DisplayFontIds.inter:
        return GoogleFonts.interTextTheme();
      default:
        return GoogleFonts.interTextTheme();
    }
  }

  static TextTheme textTheme(ColorScheme scheme, {String fontId = DisplayFontIds.defaultId}) {
    final base = _googleBase(fontId);
    final on = scheme.onSurface;
    final variant = VitalisColors.onSurfaceVariant;

    TextStyle t(
      TextStyle? from, {
      required double fontSize,
      required double lineHeight,
      required FontWeight fontWeight,
      required Color color,
      double? letterSpacing,
    }) {
      return (from ?? const TextStyle()).copyWith(
        fontSize: fontSize,
        height: lineHeight / fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
    }

    return base.copyWith(
      displayLarge: t(
        base.displayLarge,
        fontSize: 36,
        lineHeight: 44,
        fontWeight: FontWeight.w600,
        color: on,
        letterSpacing: -0.5,
      ),
      displayMedium: t(
        base.displayMedium,
        fontSize: 32,
        lineHeight: 40,
        fontWeight: FontWeight.w600,
        color: on,
      ),
      displaySmall: t(
        base.displaySmall,
        fontSize: 28,
        lineHeight: 36,
        fontWeight: FontWeight.w600,
        color: on,
      ),
      headlineLarge: t(
        base.headlineLarge,
        fontSize: 28,
        lineHeight: 36,
        fontWeight: FontWeight.w600,
        color: on,
      ),
      headlineMedium: t(
        base.headlineMedium,
        fontSize: 24,
        lineHeight: 32,
        fontWeight: FontWeight.w600,
        color: on,
      ),
      headlineSmall: t(
        base.headlineSmall,
        fontSize: 22,
        lineHeight: 30,
        fontWeight: FontWeight.w600,
        color: on,
      ),
      titleLarge: t(
        base.titleLarge,
        fontSize: 22,
        lineHeight: 28,
        fontWeight: FontWeight.w700,
        color: on,
      ),
      titleMedium: t(
        base.titleMedium,
        fontSize: 18,
        lineHeight: 24,
        fontWeight: FontWeight.w600,
        color: on,
      ),
      titleSmall: t(
        base.titleSmall,
        fontSize: 16,
        lineHeight: 22,
        fontWeight: FontWeight.w600,
        color: on,
      ),
      bodyLarge: t(
        base.bodyLarge,
        fontSize: 18,
        lineHeight: 26,
        fontWeight: FontWeight.w400,
        color: on,
      ),
      bodyMedium: t(
        base.bodyMedium,
        fontSize: 16,
        lineHeight: 24,
        fontWeight: FontWeight.w400,
        color: on,
      ),
      bodySmall: t(
        base.bodySmall,
        fontSize: 14,
        lineHeight: 20,
        fontWeight: FontWeight.w400,
        color: variant,
      ),
      labelLarge: t(
        base.labelLarge,
        fontSize: 14,
        lineHeight: 20,
        fontWeight: FontWeight.w600,
        color: on,
        letterSpacing: 0.1,
      ),
      labelMedium: t(
        base.labelMedium,
        fontSize: 12,
        lineHeight: 16,
        fontWeight: FontWeight.w500,
        color: variant,
        letterSpacing: 0.2,
      ),
      labelSmall: t(
        base.labelSmall,
        fontSize: 11,
        lineHeight: 14,
        fontWeight: FontWeight.w500,
        color: variant,
        letterSpacing: 0.2,
      ),
    );
  }
}
