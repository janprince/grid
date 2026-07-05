import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';

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
  const TransactionReceiptBody({super.key, required this.tx});

  final PaymentTransaction tx;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            TintedIcon(tx.type.icon),
            Gaps.md,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.type.label, style: theme.textTheme.titleMedium),
                  Text(
                    tx.accountNickname,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.inkMuted,
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
        ReceiptRow(label: 'Transaction ID', value: tx.reference),
        if (tx.token != null) ...[Gaps.md, _TokenBlock(token: tx.token!)],
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

/// The ECG power token, made prominent and copyable.
class _TokenBlock extends StatelessWidget {
  const _TokenBlock({required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: Corners.mdRadius,
      ),
      child: Column(
        children: [
          Text(
            'YOUR POWER TOKEN',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.inkFaint,
              letterSpacing: 1.2,
            ),
          ),
          Gaps.sm,
          Text(
            token,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          Gaps.sm,
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: token));
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Token copied')));
              }
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy token'),
          ),
        ],
      ),
    );
  }
}
