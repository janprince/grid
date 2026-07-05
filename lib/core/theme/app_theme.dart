import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Material 3 theme implementing the GRID design system:
/// Public Sans headlines, Inter body, forest-green brand, soft off-white
/// surfaces and generously rounded cards.
abstract final class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.forest,
      primary: AppColors.forestDeep,
      onPrimary: AppColors.onForest,
      primaryContainer: AppColors.mint,
      onPrimaryContainer: AppColors.forestDeep,
      secondary: AppColors.teal,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.tealSoft,
      onSecondaryContainer: AppColors.teal,
      error: AppColors.danger,
      onError: Colors.white,
      errorContainer: AppColors.dangerSoft,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.inkMuted,
      outline: AppColors.inkFaint,
      outlineVariant: AppColors.outline,
    );

    final headlineFont = GoogleFonts.publicSans();
    final bodyFont = GoogleFonts.inter();

    final textTheme = TextTheme(
      displayLarge: headlineFont.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      displayMedium: headlineFont.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      displaySmall: headlineFont.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      headlineLarge: headlineFont.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      headlineMedium: headlineFont.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      headlineSmall: headlineFont.copyWith(
        fontSize: 19,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: headlineFont.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: bodyFont.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      titleSmall: bodyFont.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
      bodyLarge: bodyFont.copyWith(fontSize: 16, height: 1.5),
      bodyMedium: bodyFont.copyWith(fontSize: 14, height: 1.45),
      bodySmall: bodyFont.copyWith(fontSize: 12, height: 1.4),
      labelLarge: bodyFont.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      labelMedium: bodyFont.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
      labelSmall: bodyFont.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.ink, size: 22),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: Corners.xlRadius),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.forestDeep,
          foregroundColor: AppColors.onForest,
          disabledBackgroundColor: AppColors.surfaceDim,
          disabledForegroundColor: AppColors.inkFaint,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: Insets.xxl),
          shape: const RoundedRectangleBorder(borderRadius: Corners.lgRadius),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forestDeep,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: Insets.xxl),
          side: const BorderSide(color: AppColors.outline, width: 1.2),
          shape: const RoundedRectangleBorder(borderRadius: Corners.lgRadius),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.teal,
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        hintStyle: textTheme.bodyLarge?.copyWith(color: AppColors.inkFaint),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.lg,
        ),
        border: const OutlineInputBorder(
          borderRadius: Corners.mdRadius,
          borderSide: BorderSide(color: AppColors.outline),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: Corners.mdRadius,
          borderSide: BorderSide(color: AppColors.outline),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: Corners.mdRadius,
          borderSide: BorderSide(color: AppColors.forest, width: 1.6),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: Corners.mdRadius,
          borderSide: BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: Corners.mdRadius,
          borderSide: BorderSide(color: AppColors.danger, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.tealSoft,
        labelStyle: textTheme.labelMedium?.copyWith(color: AppColors.teal),
        shape: const RoundedRectangleBorder(borderRadius: Corners.pill),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.md,
          vertical: Insets.xs,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Corners.xl)),
        ),
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: Corners.mdRadius),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: AppColors.mint.withValues(alpha: 0.55),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.forestDeep
                : AppColors.inkFaint,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? AppColors.forestDeep
                : AppColors.inkFaint,
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.inkMuted,
        contentPadding: EdgeInsets.symmetric(horizontal: Insets.lg),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.forestDeep,
        unselectedLabelColor: AppColors.inkFaint,
        indicatorColor: AppColors.forestDeep,
        labelStyle: textTheme.titleSmall,
        unselectedLabelStyle: textTheme.titleSmall,
        dividerColor: AppColors.divider,
      ),
    );
  }
}
