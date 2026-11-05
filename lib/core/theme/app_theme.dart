import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// The brand face, shared with GRID Pro: Plus Jakarta Sans, a geometric
/// sans with round, open forms. It includes the cedi sign (U+20B5); the
/// platform faces below are belt-and-braces for anything it lacks.
const String kBrandFont = 'PlusJakartaSans';

const List<String> kFontFallback = [
  'Roboto',
  'Noto Sans',
  'Helvetica Neue',
  'Arial',
];

/// Named text styles shared with GRID Pro, for components that are the same
/// in both apps. Screens may also use the Material [TextTheme] slots.
abstract final class AppText {
  static const _f = kBrandFont;
  static const tabularFigures = [FontFeature.tabularFigures()];

  static const display = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: kFontFallback,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.9,
    color: AppColors.ink,
  );
  static const headline = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: kFontFallback,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 1.18,
    letterSpacing: -0.5,
    color: AppColors.ink,
  );
  static const title = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: kFontFallback,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.25,
    color: AppColors.ink,
  );
  static const heading = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: kFontFallback,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.2,
    color: AppColors.ink,
  );
  static const subtitle = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: kFontFallback,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.ink,
  );
  static const body = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: kFontFallback,
    fontSize: 15,
    height: 1.45,
    letterSpacing: 0.1,
    color: AppColors.ink,
  );
  static const bodyMuted = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: kFontFallback,
    fontSize: 14.5,
    height: 1.45,
    letterSpacing: 0.1,
    color: AppColors.muted,
  );
  static const caption = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: kFontFallback,
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    height: 1.35,
    letterSpacing: 0.1,
    color: AppColors.muted,
  );
  static const overline = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: kFontFallback,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.9,
    color: AppColors.muted,
  );
  static const button = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: kFontFallback,
    fontSize: 15,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
  );
  static const amountXL = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: kFontFallback,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.7,
    color: AppColors.ink,
    fontFeatures: tabularFigures,
  );
  static const amount = TextStyle(
    fontFamily: _f,
    fontFamilyFallback: kFontFallback,
    fontSize: 15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    color: AppColors.ink,
    fontFeatures: tabularFigures,
  );
}

/// Numeric treatments for the content that *is* this product: meter
/// readings, ECG tokens, account digits, cedi amounts and references.
extension NumericType on TextStyle {
  /// Fixed-advance digits, so figures line up in columns and a long token
  /// can be read a digit at a time without losing your place.
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// The ECG token treatment: fixed-advance and opened up, because this
  /// number gets transcribed by hand into a keypad on a wall.
  TextStyle get token => copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
    letterSpacing: 2.4,
    fontWeight: FontWeight.w700,
  );
}

/// Material 3 theme implementing the GRID design system.
abstract final class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      primary: AppColors.navy,
      onPrimary: AppColors.onNavy,
      primaryContainer: AppColors.navySoft,
      onPrimaryContainer: AppColors.navy,
      secondary: AppColors.navy,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.navySoft,
      onSecondaryContainer: AppColors.navy,
      error: AppColors.danger,
      onError: Colors.white,
      errorContainer: AppColors.dangerBg,
      surface: AppColors.canvas,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.muted,
      outline: AppColors.faint,
      outlineVariant: AppColors.line,
    );

    // A scale with real range. The old theme defined 40px down to 11px but
    // never used anything above 22 in practice, so every screen sat in a
    // flat 12–17px band. The display sizes below are load-bearing: the
    // meter reading, the amount being paid, and the token.
    const f = kBrandFont;
    final textTheme = TextTheme(
      displayLarge: const TextStyle(
        fontFamily: f,
        fontFamilyFallback: kFontFallback,
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        height: 1.0,
      ),
      displayMedium: const TextStyle(
        fontFamily: f,
        fontFamilyFallback: kFontFallback,
        fontSize: 40,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.9,
        height: 1.05,
      ),
      displaySmall: const TextStyle(
        fontFamily: f,
        fontFamilyFallback: kFontFallback,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
        height: 1.1,
      ),
      headlineLarge: const TextStyle(
        fontFamily: f,
        fontFamilyFallback: kFontFallback,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.15,
      ),
      headlineMedium: const TextStyle(
        fontFamily: f,
        fontFamilyFallback: kFontFallback,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        height: 1.2,
      ),
      headlineSmall: const TextStyle(
        fontFamily: f,
        fontFamilyFallback: kFontFallback,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleLarge: const TextStyle(
        fontFamily: f,
        fontFamilyFallback: kFontFallback,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: const TextStyle(
        fontFamily: f,
        fontFamilyFallback: kFontFallback,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: const TextStyle(
        fontFamily: f,
        fontFamilyFallback: kFontFallback,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: const TextStyle(
        fontFamily: f,
        fontFamilyFallback: kFontFallback,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: const TextStyle(
        fontFamily: f,
        fontFamilyFallback: kFontFallback,
        fontSize: 14,
        height: 1.45,
        letterSpacing: 0.1,
      ),
      bodySmall: const TextStyle(
        fontFamily: f,
        fontFamilyFallback: kFontFallback,
        fontSize: 12.5,
        height: 1.4,
        letterSpacing: 0.1,
      ),
      labelLarge: const TextStyle(
        fontFamily: f,
        fontFamilyFallback: kFontFallback,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: const TextStyle(
        fontFamily: f,
        fontFamilyFallback: kFontFallback,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
      labelSmall: const TextStyle(
        fontFamily: f,
        fontFamilyFallback: kFontFallback,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);

    return ThemeData(
      useMaterial3: true,
      fontFamily: kBrandFont,
      fontFamilyFallback: kFontFallback,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.heading,
        iconTheme: const IconThemeData(color: AppColors.ink, size: 22),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: Corners.rowRadius),
      ),
      // Solid, squared navy actions. Labels are set in capitals by
      // PrimaryButton / SecondaryButton.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.onNavy,
          disabledBackgroundColor: AppColors.disabledFill,
          disabledForegroundColor: AppColors.faint,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: Insets.xxl),
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: Corners.smRadius),
          textStyle: AppText.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          backgroundColor: AppColors.surface,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: Insets.xxl),
          side: const BorderSide(color: AppColors.navy, width: 1.4),
          shape: const RoundedRectangleBorder(borderRadius: Corners.smRadius),
          textStyle: AppText.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.navy,
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: textTheme.bodyLarge?.copyWith(color: AppColors.faint),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.lg,
        ),
        border: const OutlineInputBorder(
          borderRadius: Corners.inputRadius,
          borderSide: BorderSide(color: AppColors.lineStrong),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: Corners.inputRadius,
          borderSide: BorderSide(color: AppColors.lineStrong),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: Corners.inputRadius,
          borderSide: BorderSide(color: AppColors.navy, width: 1.6),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: Corners.inputRadius,
          borderSide: BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: Corners.inputRadius,
          borderSide: BorderSide(color: AppColors.danger, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.navy,
        checkmarkColor: Colors.white,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.ink,
          fontSize: 13.5,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontSize: 13.5,
        ),
        shape: const RoundedRectangleBorder(borderRadius: Corners.smRadius),
        side: const BorderSide(color: AppColors.lineStrong),
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.sm,
          vertical: Insets.sm,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.success
              : AppColors.lineStrong,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.navy
              : Colors.transparent,
        ),
        side: const BorderSide(color: AppColors.faint, width: 1.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.navy,
        linearTrackColor: AppColors.line,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.lineStrong,
        dragHandleSize: Size(44, 5),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: Corners.mdRadius),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.muted,
        contentPadding: EdgeInsets.symmetric(horizontal: Insets.lg),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.navy,
        unselectedLabelColor: AppColors.faint,
        indicatorColor: AppColors.navy,
        labelStyle: textTheme.titleSmall,
        unselectedLabelStyle: textTheme.titleSmall,
        dividerColor: AppColors.line,
      ),
    );
  }
}
