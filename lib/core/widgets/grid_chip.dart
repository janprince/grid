import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The app's one selectable pill.
///
/// Consolidates four near-identical hand-rolled chips (`_QuickAmountChip`,
/// `_DayChip`, `_PropertyFilterChip`, `_PropertyChip`) plus the stock
/// `ChoiceChip`s and `SegmentedButton`s the app was leaking. One chip means
/// quick amounts, day pickers, activity filters and time slots all behave
/// and animate the same way.
class GridChip extends StatelessWidget {
  const GridChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.accent = AppColors.navy,
    this.expand = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  /// Fill colour when selected. Varies by context — biller brand colour on
  /// a utility filter, danger on an emergency urgency.
  final Color accent;

  /// Stretch to fill the available width, for chips laid out in a row of
  /// equal parts rather than a wrap.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? accent : AppColors.surface,
        borderRadius: Corners.smRadius,
        border: Border.all(color: selected ? accent : AppColors.lineStrong),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : AppColors.muted,
            ),
            Gaps.sm,
          ],
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontSize: 13.5,
              letterSpacing: 0,
              color: selected ? Colors.white : AppColors.ink,
            ),
          ),
        ],
      ),
    );

    final tappable = Semantics(
      selected: selected,
      button: true,
      child: InkWell(onTap: onTap, borderRadius: Corners.smRadius, child: chip),
    );

    return expand ? Expanded(child: tappable) : tappable;
  }
}
