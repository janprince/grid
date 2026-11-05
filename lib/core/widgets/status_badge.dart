import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum BadgeTone { success, warning, danger, info, neutral }

/// Outlined status pill: light fill, coloured edge, coloured text — the
/// app's single way of showing a status.
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: tone.background,
      borderRadius: Corners.pill,
      border: Border.all(color: tone.border),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: tone.foreground,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    ),
  );
}

/// Colours and icon for each tone. Shared by [StatusBadge] and
/// `StatusBanner`, so a status reads the same wherever it appears.
extension BadgeToneStyle on BadgeTone {
  Color get background => switch (this) {
    BadgeTone.success => AppColors.successBg,
    BadgeTone.warning => AppColors.warningBg,
    BadgeTone.danger => AppColors.dangerBg,
    BadgeTone.info => AppColors.navySoft,
    BadgeTone.neutral => AppColors.chip,
  };

  Color get foreground => switch (this) {
    BadgeTone.success => AppColors.success,
    BadgeTone.warning => AppColors.warningText,
    BadgeTone.danger => AppColors.danger,
    BadgeTone.info => AppColors.navy,
    BadgeTone.neutral => AppColors.muted,
  };

  Color get border => switch (this) {
    BadgeTone.success => AppColors.successLine,
    BadgeTone.warning => AppColors.warningLine,
    BadgeTone.danger => AppColors.dangerLine,
    BadgeTone.info => const Color(0xFFB9C7DC),
    BadgeTone.neutral => AppColors.lineStrong,
  };

  IconData get icon => switch (this) {
    BadgeTone.success => Icons.check_circle_outline_rounded,
    BadgeTone.warning => Icons.error_outline_rounded,
    BadgeTone.danger => Icons.cancel_outlined,
    BadgeTone.info => Icons.info_outline_rounded,
    BadgeTone.neutral => Icons.info_outline_rounded,
  };
}
