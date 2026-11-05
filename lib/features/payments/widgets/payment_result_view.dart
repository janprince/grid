import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/models.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import 'power_token_block.dart';
import 'transaction_receipt_sheet.dart';

/// Full-screen payment outcome.
///
/// Success and failure now share one treatment — a saturated ground with the
/// verdict and the amount, and a sheet rising over it with the detail.
/// Previously only success got a designed screen and failure fell back to a
/// plain page, which made the worst moment in the app also the least
/// considered.
class PaymentResultView extends StatelessWidget {
  const PaymentResultView({
    super.key,
    required this.transaction,
    required this.onRetry,
    this.headline,
    this.message,
  });

  final PaymentTransaction transaction;
  final VoidCallback onRetry;

  /// Overrides for the verdict, e.g. "Refund on the way" for a refunded order.
  final String? headline;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.home);
      },
      child: switch (transaction.status) {
        TransactionStatus.success => _buildSuccess(context),
        TransactionStatus.failed => _buildFailure(context),
        TransactionStatus.pending => _buildPending(context),
      },
    );
  }

  /// Paid, but the biller hasn't confirmed yet — or a refund is under way.
  /// Nothing for the customer to do; Activity keeps the latest state.
  Widget _buildPending(BuildContext context) {
    return OutcomeScaffold(
      tone: OutcomeTone.pending,
      headline: headline ?? 'Payment processing',
      figure: Fmt.cedis(transaction.amount),
      message:
          message ??
          'We\'re confirming this with ${transaction.type.providerName}.',
      content: [
        AppCard(
          padding: const EdgeInsets.all(Insets.xl),
          child: TransactionReceiptBody(tx: transaction, showToken: false),
        ),
        Gaps.lg,
        const InfoBanner(
          message:
              'You can leave this screen. Activity shows the latest status.',
        ),
      ],
      actions: [
        Gaps.xl,
        PrimaryButton(
          label: 'Back to home',
          onPressed: () => context.go(Routes.home),
        ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context) {
    final token = transaction.token;

    return OutcomeScaffold(
      tone: OutcomeTone.success,
      headline: headline ?? 'Payment successful',
      figure: Fmt.cedis(transaction.amount),
      message: message ?? 'Your ${transaction.type.label} payment is complete.',
      content: [
        // The token comes first: on a prepaid purchase it is the thing the
        // customer actually bought, and it should not be buried in a
        // receipt they have to scroll.
        if (token != null) ...[PowerTokenBlock(token: token), Gaps.lg],
        AppCard(
          padding: const EdgeInsets.all(Insets.xl),
          child: TransactionReceiptBody(tx: transaction, showToken: false),
        ),
      ],
      actions: [
        Gaps.xl,
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Share',
                onPressed: () => _share(context),
                icon: Icons.ios_share_rounded,
              ),
            ),
            Gaps.md,
            Expanded(
              child: SecondaryButton(
                label: 'Save PDF',
                onPressed: () => _download(context),
                icon: Icons.download_rounded,
              ),
            ),
          ],
        ),
        Gaps.md,
        PrimaryButton(
          label: 'Back to home',
          onPressed: () => context.go(Routes.home),
        ),
      ],
    );
  }

  Widget _buildFailure(BuildContext context) {
    return OutcomeScaffold(
      tone: OutcomeTone.failure,
      headline: headline ?? 'Payment failed',
      figure: Fmt.cedis(transaction.amount),
      message:
          message ??
          transaction.failureReason ??
          'The payment could not be completed. You have not been charged.',
      content: [
        AppCard(
          padding: const EdgeInsets.all(Insets.xl),
          child: Column(
            children: [
              ReceiptRow(
                label: transaction.type.accountLabel,
                value: transaction.accountNumber,
              ),
              ReceiptRow(
                label: 'Payment method',
                value: transaction.paymentMethodLabel,
              ),
              ReceiptRow(label: 'Reference', value: transaction.reference),
              ReceiptRow(
                label: 'Status',
                value: '',
                valueWidget: const Align(
                  alignment: Alignment.centerRight,
                  child: StatusBadge(label: 'Failed', tone: BadgeTone.danger),
                ),
              ),
            ],
          ),
        ),
      ],
      actions: [
        Gaps.xl,
        PrimaryButton(label: 'Try again', onPressed: onRetry),
        Gaps.md,
        SecondaryButton(
          label: 'Back to home',
          onPressed: () => context.go(Routes.home),
        ),
      ],
    );
  }

  Future<void> _share(BuildContext context) async {
    final summary = [
      'GRID receipt',
      transaction.type.label,
      'Amount: ${Fmt.cedis(transaction.amount)}',
      '${transaction.type.accountLabel}: ${transaction.accountNumber}',
      if (transaction.token != null) 'Token: ${transaction.token}',
      if (transaction.billerReference != null)
        'Biller ref: ${transaction.billerReference}',
      'Ref: ${transaction.reference}',
      Fmt.dateTime(transaction.createdAt),
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: summary));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt copied — ready to share')),
      );
    }
  }

  void _download(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF receipts arrive with the live release'),
      ),
    );
  }
}
