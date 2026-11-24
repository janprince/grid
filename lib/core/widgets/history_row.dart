import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// How a row's status line is coloured. Done things stay quiet; only what
/// needs attention takes a colour.
enum HistoryTone { quiet, active, waiting, problem }

/// One line of history, and the shape of every list like it: the thing's
/// mark on a soft tile, what it was above when, and the amount above where it
/// stands. Rows are separated by a hairline, not boxed into cards.
class HistoryRow extends StatelessWidget {
  const HistoryRow({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.value,
    this.status,
    this.tone = HistoryTone.quiet,
    this.trailing,
    this.onTap,
    this.divider = true,
  });

  /// A biller mark, service badge or [HistoryIcon], about 48 across.
  final Widget leading;
  final String title;

  /// Usually when, e.g. "18 Nov 2026" or "My Home Meter · 10:57 PM".
  final String subtitle;

  /// The figure on the right, e.g. "GH₵ 236.72".
  final String? value;

  /// Plain words under [value], e.g. "Completed".
  final String? status;
  final HistoryTone tone;

  /// Replaces [value] and [status], e.g. a "Pay again" link.
  final Widget? trailing;
  final VoidCallback? onTap;

  /// A hairline under the row; off for the last row of a group.
  final bool divider;

  static Color colorOf(HistoryTone tone) => switch (tone) {
    HistoryTone.quiet => AppColors.muted,
    HistoryTone.active => AppColors.navy,
    HistoryTone.waiting => AppColors.warningText,
    HistoryTone.problem => AppColors.danger,
  };

  @override
  Widget build(BuildContext context) {
    final right =
        trailing ??
        (value == null && status == null
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (value != null)
                    Text(
                      value!,
                      maxLines: 1,
                      style: AppText.heading.copyWith(
                        fontSize: 16,
                        fontFeatures: AppText.tabularFigures,
                      ),
                    ),
                  if (status != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      status!,
                      maxLines: 1,
                      style: AppText.body.copyWith(
                        fontSize: 14,
                        height: 1.2,
                        color: colorOf(tone),
                        fontWeight: tone == HistoryTone.quiet
                            ? FontWeight.w400
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ));

    return Semantics(
      button: onTap != null,
      label: [title, subtitle, ?value, ?status].join(', '),
      excludeSemantics: trailing == null,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            border: divider
                ? const Border(bottom: BorderSide(color: AppColors.line))
                : null,
          ),
          child: Row(
            children: [
              SizedBox.square(dimension: 48, child: leading),
              const SizedBox(width: Insets.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.subtitle.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyMuted.copyWith(
                        fontSize: 14,
                        height: 1.2,
                        fontFeatures: AppText.tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
              if (right != null) ...[Gaps.md, right],
            ],
          ),
        ),
      ),
    );
  }
}

/// An icon on the soft navy tile, for rows with no biller or service mark.
class HistoryIcon extends StatelessWidget {
  const HistoryIcon(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.navySoft,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, color: AppColors.navy, size: 24),
  );
}
