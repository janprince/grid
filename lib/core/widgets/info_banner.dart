import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Soft tinted callout with an icon — used for demo notices, pricing
/// transparency and verification messages.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.color = AppColors.teal,
    this.background = AppColors.tealSoft,
  });

  const InfoBanner.warning({super.key, required this.message})
    : icon = Icons.error_outline_rounded,
      color = AppColors.warning,
      background = AppColors.warningSoft;

  final String message;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: Corners.mdRadius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          Gaps.sm,
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small "Demo" tag stamped on receipts and transactions until live
/// integrations exist.
class DemoTag extends StatelessWidget {
  const DemoTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.sm, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: Corners.pill,
      ),
      child: Text(
        'DEMO',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.warning,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
