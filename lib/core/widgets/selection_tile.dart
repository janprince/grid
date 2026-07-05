import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A tappable card acting like a large radio option — used for saved
/// accounts, payment methods, plans, urgency levels and time slots.
class SelectionTile extends StatelessWidget {
  const SelectionTile({
    super.key,
    required this.selected,
    required this.onTap,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.accent = AppColors.forest,
  });

  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? accent.withValues(alpha: 0.05) : AppColors.card,
        borderRadius: Corners.lgRadius,
        border: Border.all(
          color: selected ? accent : AppColors.outline,
          width: selected ? 1.6 : 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: Corners.lgRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Insets.lg),
            child: Row(
              children: [
                if (leading != null) ...[leading!, Gaps.md],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[Gaps.sm, trailing!],
                Gaps.md,
                _RadioDot(selected: selected, accent: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected, required this.accent});

  final bool selected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? accent : Colors.transparent,
        border: Border.all(
          color: selected ? accent : AppColors.inkFaint,
          width: 1.6,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }
}
