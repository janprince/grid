import 'package:flutter/material.dart';

/// GRID colour tokens — shared with GRID Pro. See
/// `DOCUMENTATION/design-system.md`.
///
/// Deep navy for action and identity, white working surfaces, and colour
/// used sparingly so that where it appears (a service tint, a biller's brand,
/// a status) it means something.
abstract final class AppColors {
  // Brand.
  static const Color navy = Color(0xFF13294B);
  static const Color navyDeep = Color(0xFF0B1C37);
  static const Color navyLight = Color(0xFF1D3B68);
  static const Color navySoft = Color(0xFFEBF0F7);

  /// Warm accent, only ever on navy surfaces.
  static const Color amber = Color(0xFFF4C76A);

  // Neutrals.
  static const Color canvas = Colors.white;
  static const Color surface = Colors.white;
  static const Color surfaceSubtle = Color(0xFFF6F7F9);
  static const Color chip = Color(0xFFF1F3F6);
  static const Color ink = Color(0xFF0B1526);
  static const Color muted = Color(0xFF5A6A82);
  static const Color faint = Color(0xFF8C99AD);
  static const Color line = Color(0xFFE6E9EF);
  static const Color lineStrong = Color(0xFFD5DBE4);
  static const Color disabledFill = Color(0xFFE9ECF1);

  // Semantic.
  static const Color success = Color(0xFF0B7A53);
  static const Color successBg = Color(0xFFE9F7F0);
  static const Color successLine = Color(0xFFA3DCC3);
  static const Color warning = Color(0xFFC77700);
  static const Color warningText = Color(0xFF9A5B00);
  static const Color warningBg = Color(0xFFFFF5E4);
  static const Color warningLine = Color(0xFFF2D19A);
  static const Color danger = Color(0xFFD3343B);
  static const Color dangerBg = Color(0xFFFDEEEE);
  static const Color dangerLine = Color(0xFFF1B3B6);

  /// Ground for the failure outcome screen — serious, not alarming.
  static const Color dangerDeep = Color(0xFF4A1614);

  // On navy surfaces (home hero, receipt header, splash).
  static const Color onNavy = Colors.white;
  static const Color onNavyMuted = Color(0xFFB5C3D8);

  /// Hairline on navy, where [line] would disappear.
  static const Color onNavyLine = Color(0xFF2A4670);

  // ── Depletion ramp ───────────────────────────────────────────────────
  // Used *only* by MeterBar, so the ramp carries meaning: when a user sees
  // these colours they are looking at something running out.

  static const Color meterHealthy = Color(0xFF7BE0B0);
  static const Color meterCaution = Color(0xFFF4C76A);
  static const Color meterCritical = Color(0xFFFF8A73);

  /// Track the meter fill runs in, on the navy ground.
  static const Color meterTrack = Color(0xFF223B60);

  /// The ramp colour for a remaining fraction in 0..1.
  static Color meterTone(double fraction) {
    if (fraction <= 0.15) return meterCritical;
    if (fraction <= 0.35) return meterCaution;
    return meterHealthy;
  }

  // ── Elevation ────────────────────────────────────────────────────────
  // Surfaces are flat: a hairline and no shadow. Shadow is reserved for the
  // one element that genuinely floats (a sheet, a preview card on navy).

  static Border get flatBorder =>
      Border.fromBorderSide(const BorderSide(color: line, width: 1));

  static const List<BoxShadow> flatShadow = [];

  static List<BoxShadow> get raisedShadow => [
    BoxShadow(
      color: navyDeep.withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get liftedShadow => [
    BoxShadow(
      color: navyDeep.withValues(alpha: 0.12),
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
  ];
}
