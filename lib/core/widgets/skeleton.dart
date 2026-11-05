import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Pulsing placeholder block for loading states.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = Corners.smRadius,
  });

  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    lowerBound: 0.35,
    upperBound: 0.9,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: widget.borderRadius,
        ),
      ),
    );
  }
}

/// A card-shaped skeleton used while lists load.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.height = 84});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Corners.xlRadius,
        boxShadow: AppColors.raisedShadow,
      ),
      child: Row(
        children: const [
          Skeleton(
            width: 44,
            height: 44,
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          Gaps.md,
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Skeleton(height: 14),
                Gaps.sm,
                Skeleton(height: 12, width: 140),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
