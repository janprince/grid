import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// The GRID mark: a rounded forest-green tile with a house-on-grid glyph.
class GridLogo extends StatelessWidget {
  const GridLogo({super.key, this.size = 56, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: onDark ? Colors.white : AppColors.forestDeep,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        Icons.other_houses_rounded,
        color: onDark ? AppColors.forestDeep : Colors.white,
        size: size * 0.55,
      ),
    );
  }
}

/// The GRID wordmark, optionally with the tile above it.
class GridWordmark extends StatelessWidget {
  const GridWordmark({super.key, this.fontSize = 28, this.onDark = false});

  final double fontSize;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      'GRID',
      style: GoogleFonts.publicSans(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: fontSize * 0.12,
        color: onDark ? Colors.white : AppColors.forestDeep,
      ),
    );
  }
}
