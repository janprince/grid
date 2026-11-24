import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Where a surface sits relative to the page.
enum AppCardVariant {
  /// A hairline outline and no shadow. For cards on a tinted or grey ground,
  /// where a shadow would look dirty, and for dense lists.
  flat,

  /// The default: a soft shadow lifts the card off the page.
  raised,

  /// Reserved for the single hero element on a screen.
  lifted,
}

/// The standard GRID surface.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(Insets.lg),
    this.color = AppColors.surface,
    this.borderRadius = Corners.lgRadius,
    this.border,
    this.variant = AppCardVariant.raised,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color color;
  final BorderRadius borderRadius;

  /// Overrides the variant's own border when given.
  final BoxBorder? border;
  final AppCardVariant variant;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border:
            border ??
            (variant == AppCardVariant.flat ? AppColors.flatBorder : null),
        boxShadow: switch (variant) {
          AppCardVariant.flat => AppColors.flatShadow,
          AppCardVariant.raised => AppColors.raisedShadow,
          AppCardVariant.lifted => AppColors.liftedShadow,
        },
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(
                onTap: onTap,
                child: Padding(padding: padding, child: child),
              ),
      ),
    );
  }
}
