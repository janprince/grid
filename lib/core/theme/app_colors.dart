import 'package:flutter/material.dart';

/// GRID color tokens, adopted from the Stitch "Premium Utility" design system.
abstract final class AppColors {
  // Brand
  static const Color forestDeep = Color(0xFF003527);
  static const Color forest = Color(0xFF064E3B);
  static const Color forestSoft = Color(0xFF2B6954);
  static const Color mint = Color(0xFFB0F0D6);
  static const Color teal = Color(0xFF006A61);
  static const Color tealSoft = Color(0xFFD4F0EC);

  // Neutrals
  static const Color surface = Color(0xFFF8FAF6);
  static const Color surfaceDim = Color(0xFFEFF1EE);
  static const Color card = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF191C1B);
  static const Color inkMuted = Color(0xFF404944);
  static const Color inkFaint = Color(0xFF707974);
  static const Color outline = Color(0xFFE3E7E2);
  static const Color divider = Color(0xFFF0F2EF);

  // Semantic
  static const Color success = Color(0xFF0E7A5F);
  static const Color successSoft = Color(0xFFDDF3EA);
  static const Color warning = Color(0xFFA05E03);
  static const Color warningSoft = Color(0xFFFDF0DC);
  static const Color danger = Color(0xFFBA1A1A);
  static const Color dangerSoft = Color(0xFFFFDAD6);
  static const Color info = Color(0xFF1E5A8A);
  static const Color infoSoft = Color(0xFFE0EDF8);

  // On dark-green surfaces (hero card, receipt header, splash)
  static const Color onForest = Color(0xFFFFFFFF);
  static const Color onForestMuted = Color(0xFFA8CBBC);

  /// Ambient card shadow tinted with forest green, per the design system.
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: forestDeep.withValues(alpha: 0.05),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get floatingShadow => [
    BoxShadow(
      color: forestDeep.withValues(alpha: 0.10),
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
  ];
}
