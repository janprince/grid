import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// An icon inside a soft tinted rounded square — used for utilities,
/// services and activity rows.
class TintedIcon extends StatelessWidget {
  const TintedIcon(
    this.icon, {
    super.key,
    this.size = 44,
    this.color = AppColors.teal,
    this.background = AppColors.tealSoft,
  });

  const TintedIcon.danger(this.icon, {super.key, this.size = 44})
    : color = AppColors.danger,
      background = AppColors.dangerSoft;

  const TintedIcon.warning(this.icon, {super.key, this.size = 44})
    : color = AppColors.warning,
      background = AppColors.warningSoft;

  final IconData icon;
  final double size;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}
