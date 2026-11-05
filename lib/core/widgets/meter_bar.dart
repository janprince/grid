import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The signature GRID element: prepaid credit shown as a depleting meter.
///
/// Deliberately segmented rather than a smooth progress bar. Prepaid
/// electricity in Ghana is sold in *units*, so the bar depicts what is
/// actually being measured — and it reads as a gauge on a wall rather than
/// as a download. The fill colour comes from [AppColors.meterTone], the one
/// ramp in the app reserved for things running out, so the colour itself
/// tells you where you stand before you read a number.
class MeterBar extends StatelessWidget {
  const MeterBar({
    super.key,
    required this.fraction,
    this.onDark = true,
    this.height = 10,
    this.segments = 20,
    this.caption,
    this.trailing,
  });

  /// Remaining credit as a fraction in 0..1.
  final double fraction;

  /// Whether the bar sits on the navy ground (the usual case) or on a
  /// light surface.
  final bool onDark;

  final double height;
  final int segments;

  /// Optional line below the bar: [caption] on the left, [trailing] right.
  final String? caption;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = fraction.clamp(0.0, 1.0);
    final tone = AppColors.meterTone(value);
    final track = onDark ? AppColors.meterTrack : AppColors.surfaceSubtle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(end: value),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => SizedBox(
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < segments; i++) ...[
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        // Each segment fills independently, so the boundary
                        // segment eases in instead of snapping.
                        color: Color.lerp(
                          track,
                          tone,
                          ((v * segments) - i).clamp(0.0, 1.0),
                        ),
                        borderRadius: Corners.pill,
                      ),
                    ),
                  ),
                  if (i != segments - 1) const SizedBox(width: 3),
                ],
              ],
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(height: Insets.md),
          Text(
            trailing!,
            style: theme.textTheme.titleMedium?.copyWith(color: tone),
          ),
        ],
        if (caption != null) ...[
          const SizedBox(height: Insets.xs),
          Text(
            caption!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: onDark ? AppColors.onNavyMuted : AppColors.faint,
            ),
          ),
        ],
      ],
    );
  }
}
