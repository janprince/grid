import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Where a surface sits relative to the page.
///
/// The redesign's central rule: **at most one `raised` or `lifted` surface
/// per viewport.** Previously every card carried the same shadow, so a
/// screen of ten cards had ten things competing to float and the eye had
/// nowhere to land.
enum AppCardVariant {
  /// The default. A hairline outline and no shadow — for list rows and
  /// grouped blocks, which is most content.
  flat,

  /// For a surface that genuinely floats above the page.
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
    this.variant = AppCardVariant.flat,
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
