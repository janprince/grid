import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';

/// One row of history: a payment or a service request.
class ActivityTile extends StatelessWidget {
  const ActivityTile({super.key, required this.item, required this.onTap});

  final ActivityItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badge = switch (item.statusLabel) {
      'Success' || 'Completed' => StatusBadge(
        label: item.statusLabel,
        tone: BadgeTone.success,
      ),
      'Pending' => StatusBadge(
        label: item.statusLabel,
        tone: BadgeTone.warning,
      ),
      'Failed' => StatusBadge(label: item.statusLabel, tone: BadgeTone.danger),
      'Cancelled' => StatusBadge(
        label: item.statusLabel,
        tone: BadgeTone.neutral,
      ),
      _ => StatusBadge(label: item.statusLabel, tone: BadgeTone.info),
    };

    final subtitleParts = [
      item.subtitle,
      if (item.propertyLabel != null) item.propertyLabel!,
    ];

    return AppCard(
      padding: const EdgeInsets.all(Insets.lg),
      onTap: onTap,
      child: Row(
        children: [
          item.kind == ActivityKind.payment
              ? TintedIcon(item.icon)
              : TintedIcon(
                  item.icon,
                  color: AppColors.forest,
                  background: AppColors.mint,
                ),
          Gaps.md,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitleParts.join(' • '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  Fmt.relativeDay(item.date),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.inkFaint,
                  ),
                ),
              ],
            ),
          ),
          Gaps.sm,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (item.amount != null)
                Text(
                  Fmt.cedis(item.amount!),
                  style: theme.textTheme.titleMedium,
                ),
              const SizedBox(height: 6),
              badge,
            ],
          ),
        ],
      ),
    );
  }
}
