import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';

/// One row of history: a payment or a service request.
///
/// No longer a card. A screen of identical white rounded cards is the single
/// biggest reason the app read as templated — history is a list, and lists
/// are flat. Rhythm comes from the biller's own mark on the left and from
/// the date headers the screen puts between groups.
class ActivityTile extends StatelessWidget {
  const ActivityTile({super.key, required this.item, required this.onTap});

  final ActivityItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use the typed constructors rather than matching on the display
    // string, which silently fell through to "info" for any new status.
    final badge = switch (item) {
      ActivityItem(transaction: final tx?) => StatusBadge.transaction(
        tx.status,
      ),
      ActivityItem(request: final req?) => StatusBadge.request(req.status),
      _ => StatusBadge(label: item.statusLabel, tone: BadgeTone.info),
    };

    final subtitleParts = [
      item.subtitle,
      if (item.propertyLabel != null) item.propertyLabel!,
    ];

    return InkWell(
      onTap: onTap,
      borderRadius: Corners.rowRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.sm,
          vertical: Insets.md,
        ),
        child: Row(
          children: [
            if (item.utilityType != null)
              BillerMark(item.utilityType!)
            else if (item.request != null)
              ServiceBadge(category: item.request!.category)
            else
              TintedIcon(item.icon),
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
                    subtitleParts.join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                    style: theme.textTheme.titleMedium?.tabular,
                  )
                else
                  Text(
                    Fmt.time(item.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.faint,
                    ),
                  ),
                const SizedBox(height: 6),
                badge,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
