import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'system.dart';

/// The GRID mark: the four-cell glyph (three cells and one lit amber cell)
/// on a rounded navy tile. Shared with GRID Pro.
class GridLogo extends StatelessWidget {
  const GridLogo({super.key, this.size = 56, this.onDark = false});
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'GRID',
    excludeSemantics: true,
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: onDark ? Colors.white : AppColors.navy,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: onDark
          ? GridGlyph(size: size * 0.5)
          : GridGlyph(size: size * 0.5, light: true),
    ),
  );
}

/// The GRID wordmark, with the glyph before it.
class GridWordmark extends StatelessWidget {
  const GridWordmark({super.key, this.fontSize = 28, this.onDark = false});
  final double fontSize;
  final bool onDark;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      GridGlyph(size: fontSize * 1.05, light: onDark),
      SizedBox(width: fontSize * 0.4),
      Text(
        'GRID',
        style: TextStyle(
          fontFamily: kBrandFont,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: fontSize * 0.03,
          height: 1,
          color: onDark ? Colors.white : AppColors.ink,
        ),
      ),
    ],
  );
}
