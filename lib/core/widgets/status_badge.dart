import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum BadgeTone { success, warning, danger, info, neutral }

/// Pill badge with a soft tinted background — the app's single way of
/// showing a status.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.tone});

  StatusBadge.transaction(TransactionStatus status, {super.key})
    : label = switch (status) {
        TransactionStatus.success => 'Success',
        TransactionStatus.pending => 'Pending',
        TransactionStatus.failed => 'Failed',
      },
      tone = switch (status) {
        TransactionStatus.success => BadgeTone.success,
        TransactionStatus.pending => BadgeTone.warning,
        TransactionStatus.failed => BadgeTone.danger,
      };

  StatusBadge.request(ServiceRequestStatus status, {super.key})
    : label = status.label,
      tone = switch (status) {
        ServiceRequestStatus.pending => BadgeTone.warning,
        ServiceRequestStatus.assigned => BadgeTone.info,
        ServiceRequestStatus.inProgress => BadgeTone.info,
        ServiceRequestStatus.completed => BadgeTone.success,
        ServiceRequestStatus.cancelled => BadgeTone.neutral,
      };

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      BadgeTone.success => (AppColors.successSoft, AppColors.success),
      BadgeTone.warning => (AppColors.warningSoft, AppColors.warning),
      BadgeTone.danger => (AppColors.dangerSoft, AppColors.danger),
      BadgeTone.info => (AppColors.infoSoft, AppColors.info),
      BadgeTone.neutral => (AppColors.surfaceDim, AppColors.inkMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.md,
        vertical: Insets.xs,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: Corners.pill),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
