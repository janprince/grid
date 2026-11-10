import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Soft tinted callout with an icon — used for notices, pricing
/// transparency and verification messages.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.color = AppColors.navy,
    this.background = AppColors.navySoft,
  });

  const InfoBanner.warning({super.key, required this.message})
    : icon = Icons.error_outline_rounded,
      color = AppColors.warningText,
      background = AppColors.warningBg;

  final String message;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: Corners.mdRadius,
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: color),
          Gaps.sm,
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color == AppColors.navy ? AppColors.ink : color,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
