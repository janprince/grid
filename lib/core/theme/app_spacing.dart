import 'package:flutter/widgets.dart';

/// 8px-based spacing scale.
abstract final class Insets {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  /// Standard horizontal screen padding (20px per design system).
  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: xl);
}

/// Corner radii, ordered as a hierarchy rather than one value used
/// everywhere. Radius signals importance: the further a surface is from the
/// page, the rounder it gets.
///
///   [row]    list rows and inline blocks — the app's most common surface
///   [input]  text fields
///   [lg]     panels and grouped blocks
///   [xl]     reserved for the hero and the sheet-over-ground junction
abstract final class Corners {
  static const double sm = 8;
  static const double input = 8;
  static const double row = 12;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 22;

  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius inputRadius = BorderRadius.all(
    Radius.circular(input),
  );
  static const BorderRadius rowRadius = BorderRadius.all(Radius.circular(row));
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlRadius = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));

  /// The junction where a white sheet rises over the navy ground.
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}

/// Convenience vertical/horizontal gaps.
abstract final class Gaps {
  static const SizedBox xs = SizedBox(height: Insets.xs, width: Insets.xs);
  static const SizedBox sm = SizedBox(height: Insets.sm, width: Insets.sm);
  static const SizedBox md = SizedBox(height: Insets.md, width: Insets.md);
  static const SizedBox lg = SizedBox(height: Insets.lg, width: Insets.lg);
  static const SizedBox xl = SizedBox(height: Insets.xl, width: Insets.xl);
  static const SizedBox xxl = SizedBox(height: Insets.xxl, width: Insets.xxl);
  static const SizedBox xxxl = SizedBox(
    height: Insets.xxxl,
    width: Insets.xxxl,
  );
}
