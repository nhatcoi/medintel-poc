import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'vitalis_colors.dart';
import 'vitalis_typography.dart';

/// Theme **MedIntel / Vitalis Clarity** — Material 3 + token DESIGN.md.
final class AppTheme {
  AppTheme._();

  static const double radiusMd = 24;
  static const double radiusXl = 48;
  static const double buttonVerticalPadding = 24;

  static ThemeData light() {
    final scheme = _lightColorScheme;
    final textTheme = VitalisTypography.textTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: VitalisColors.background,
      textTheme: textTheme,
      primaryTextTheme: tintTextTheme(textTheme, scheme.onPrimary),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: VitalisColors.surface,
        foregroundColor: VitalisColors.onSurface,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: VitalisColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(vertical: buttonVerticalPadding, horizontal: 28),
          shape: const StadiumBorder(),
          elevation: 0,
          backgroundColor: VitalisColors.primary,
          foregroundColor: Colors.white,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: VitalisColors.secondaryContainer,
          foregroundColor: VitalisColors.onSecondaryContainer,
          padding: const EdgeInsets.symmetric(vertical: buttonVerticalPadding, horizontal: 28),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: VitalisColors.onSurface,
          side: BorderSide(color: VitalisColors.outlineVariantBase.withValues(alpha: 0.35)),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: VitalisColors.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VitalisColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: VitalisColors.primaryDim, width: 2),
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(color: VitalisColors.neutral),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: VitalisColors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: VitalisColors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? VitalisColors.primary : VitalisColors.neutral,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 26,
            color: selected ? VitalisColors.primary : VitalisColors.neutral,
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 2,
        focusElevation: 4,
        hoverElevation: 4,
        backgroundColor: VitalisColors.tertiary,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: VitalisColors.primary,
        linearTrackColor: VitalisColors.surfaceContainerLow,
        circularTrackColor: VitalisColors.surfaceContainerLow,
        strokeWidth: 8,
      ),
      dividerTheme: DividerThemeData(
        color: VitalisColors.outlineGhost,
        thickness: 0,
        space: 32,
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 16,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        iconColor: VitalisColors.secondary,
        textColor: VitalisColors.onSurface,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(color: VitalisColors.onSurfaceVariant),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: VitalisColors.onSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: VitalisColors.surfaceContainerLow,
        selectedColor: VitalisColors.primary.withValues(alpha: 0.12),
        labelStyle: textTheme.labelLarge!,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        side: BorderSide.none,
      ),
    );
  }

  static final ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: VitalisColors.primary,
    onPrimary: Colors.white,
    primaryContainer: VitalisColors.primaryContainer,
    onPrimaryContainer: const Color(0xFF001E36),
    secondary: VitalisColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: VitalisColors.secondaryContainer,
    onSecondaryContainer: VitalisColors.onSecondaryContainer,
    tertiary: VitalisColors.tertiary,
    onTertiary: Colors.white,
    tertiaryContainer: const Color(0xFFE8F5E9),
    onTertiaryContainer: const Color(0xFF1B5E20),
    error: const Color(0xFFB3261E),
    onError: Colors.white,
    errorContainer: const Color(0xFFF9DEDC),
    onErrorContainer: const Color(0xFF410E0B),
    surface: VitalisColors.surface,
    onSurface: VitalisColors.onSurface,
    surfaceDim: VitalisColors.surfaceContainerLow,
    surfaceBright: VitalisColors.surfaceBright,
    surfaceContainerLowest: VitalisColors.surfaceContainerLowest,
    surfaceContainerLow: VitalisColors.surfaceContainerLow,
    surfaceContainer: const Color(0xFFE8ECF2),
    surfaceContainerHigh: const Color(0xFFE2E7EE),
    surfaceContainerHighest: VitalisColors.surfaceContainerHighest,
    onSurfaceVariant: VitalisColors.onSurfaceVariant,
    outline: VitalisColors.outlineGhost,
    outlineVariant: VitalisColors.outlineVariantBase.withValues(alpha: 0.15),
    shadow: const Color(0xFF2D333A).withValues(alpha: 0.08),
    scrim: Colors.black54,
    inverseSurface: const Color(0xFF2D333A),
    onInverseSurface: VitalisColors.surface,
    inversePrimary: VitalisColors.primaryContainer,
    surfaceTint: VitalisColors.primary,
  );
}

/// Ánh xạ text theme sang một màu chữ (ví dụ onPrimary).
TextTheme tintTextTheme(TextTheme base, Color color) {
  return base.copyWith(
    displayLarge: base.displayLarge?.copyWith(color: color),
    displayMedium: base.displayMedium?.copyWith(color: color),
    displaySmall: base.displaySmall?.copyWith(color: color),
    headlineLarge: base.headlineLarge?.copyWith(color: color),
    headlineMedium: base.headlineMedium?.copyWith(color: color),
    headlineSmall: base.headlineSmall?.copyWith(color: color),
    titleLarge: base.titleLarge?.copyWith(color: color),
    titleMedium: base.titleMedium?.copyWith(color: color),
    titleSmall: base.titleSmall?.copyWith(color: color),
    bodyLarge: base.bodyLarge?.copyWith(color: color),
    bodyMedium: base.bodyMedium?.copyWith(color: color),
    bodySmall: base.bodySmall?.copyWith(color: color),
    labelLarge: base.labelLarge?.copyWith(color: color),
    labelMedium: base.labelMedium?.copyWith(color: color),
    labelSmall: base.labelSmall?.copyWith(color: color),
  );
}
