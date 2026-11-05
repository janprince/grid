import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import 'power_token_block.dart';

/// Compact receipt shown when a past transaction is opened from
/// Activity or the dashboard.
Future<void> showTransactionSheet(BuildContext context, PaymentTransaction tx) {
  return showAppBottomSheet(
    context,
    title: 'Receipt',
    child: SingleChildScrollView(child: TransactionReceiptBody(tx: tx)),
  );
}

class TransactionReceiptBody extends StatelessWidget {
  const TransactionReceiptBody({
    super.key,
    required this.tx,
    this.showToken = true,
  });

  final PaymentTransaction tx;

  /// Set false where the screen features the token itself, so it is not
  /// printed twice on the same page.
  final bool showToken;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            BillerMark(tx.type),
            Gaps.md,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.type.label, style: theme.textTheme.titleMedium),
                  Text(
                    tx.accountNickname,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            StatusBadge.transaction(tx.status),
          ],
        ),
        Gaps.lg,
        const DashedDivider(),
        Gaps.sm,
        ReceiptRow(
          label: 'Amount',
          value: Fmt.cedis(tx.amount),
          emphasize: true,
        ),
        if (tx.planName != null)
          ReceiptRow(label: 'Package', value: tx.planName!),
        ReceiptRow(label: tx.type.accountLabel, value: tx.accountNumber),
        if (tx.propertyLabel != null)
          ReceiptRow(label: 'Home', value: tx.propertyLabel!),
        ReceiptRow(label: 'Paid with', value: tx.paymentMethodLabel),
        ReceiptRow(label: 'Date & time', value: Fmt.dateTime(tx.createdAt)),
        if (tx.fee > 0) ReceiptRow(label: 'Charges', value: Fmt.cedis(tx.fee)),
        ReceiptRow(label: 'Transaction ID', value: tx.reference),
        if (tx.billerReference != null)
          ReceiptRow(
            label: '${tx.type.label} reference',
            value: tx.billerReference!,
          ),
        if (showToken && tx.token != null) ...[
          Gaps.lg,
          PowerTokenBlock(token: tx.token!),
        ],
        if (tx.failureReason != null) ...[
          Gaps.md,
          InfoBanner.warning(message: tx.failureReason!),
        ],
        Gaps.lg,
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [DemoTag()],
        ),
      ],
    );
  }
}
