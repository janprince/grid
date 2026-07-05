import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/models.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../services/booking_flow_screen.dart';

class ReminderCard extends StatelessWidget {
  const ReminderCard({super.key, required this.reminder});

  final Reminder reminder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (iconWidget, dueColor) = switch (reminder.severity) {
      ReminderSeverity.urgent => (
        TintedIcon.danger(reminder.icon),
        AppColors.danger,
      ),
      ReminderSeverity.warning => (
        TintedIcon.warning(reminder.icon),
        AppColors.warning,
      ),
      ReminderSeverity.info => (TintedIcon(reminder.icon), AppColors.inkMuted),
    };

    return AppCard(
      padding: const EdgeInsets.all(Insets.lg),
      child: Row(
        children: [
          iconWidget,
          Gaps.md,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  reminder.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Fmt.dueLabel(reminder.dueDate),
                  style: theme.textTheme.labelSmall?.copyWith(color: dueColor),
                ),
              ],
            ),
          ),
          if (reminder.actionLabel != null) ...[
            Gaps.sm,
            FilledButton(
              onPressed: () => _act(context),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
                textStyle: theme.textTheme.labelMedium,
              ),
              child: Text(reminder.actionLabel!),
            ),
          ],
        ],
      ),
    );
  }

  void _act(BuildContext context) {
    final utility = reminder.utilityType;
    if (utility != null) {
      context.push(Routes.payFlow(utility.name));
      return;
    }
    final category = reminder.serviceCategory;
    if (category != null) {
      context.push(Routes.bookService, extra: BookingArgs(category: category));
    }
  }
}
