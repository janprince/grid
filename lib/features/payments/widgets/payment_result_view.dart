import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/models.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import 'transaction_receipt_sheet.dart';

/// Full-screen payment outcome: an unmissable success receipt with the
/// dark-green header, or a clear failure with a retry path.
class PaymentResultView extends StatelessWidget {
  const PaymentResultView({
    super.key,
    required this.transaction,
    required this.onRetry,
  });

  final PaymentTransaction transaction;
  final VoidCallback onRetry;

  bool get _success => transaction.status == TransactionStatus.success;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.home);
      },
      child: Scaffold(
        backgroundColor: _success ? AppColors.forestDeep : AppColors.surface,
        body: SafeArea(
          child: _success ? _buildSuccess(context) : _buildFailure(context),
        ),
      ),
    );
  }

  // Success ------------------------------------------------------------------

  Widget _buildSuccess(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Insets.xxxl),
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 42,
                  color: AppColors.mint,
                ),
              ),
              Gaps.lg,
              Text(
                'Payment successful',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              Gaps.xs,
              Text(
                'Your ${transaction.type.label} payment is complete.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onForestMuted,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(Corners.xl),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Insets.xl),
              child: Column(
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(Insets.xl),
                    child: TransactionReceiptBody(tx: transaction),
                  ),
                  Gaps.xl,
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _share(context),
                          icon: const Icon(Icons.ios_share_rounded, size: 18),
                          label: const Text('Share'),
                        ),
                      ),
                      Gaps.md,
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _download(context),
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('Save PDF'),
                        ),
                      ),
                    ],
                  ),
                  Gaps.md,
                  FilledButton(
                    onPressed: () => context.go(Routes.home),
                    child: const Text('Back to home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Failure --------------------------------------------------------------------

  Widget _buildFailure(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Insets.xl),
      child: Column(
        children: [
          Gaps.xxxl,
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: AppColors.dangerSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close_rounded,
              size: 42,
              color: AppColors.danger,
            ),
          ),
          Gaps.lg,
          Text('Payment failed', style: theme.textTheme.headlineMedium),
          Gaps.sm,
          Text(
            transaction.failureReason ?? 'The payment could not be completed.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
          Gaps.xxl,
          AppCard(
            padding: const EdgeInsets.all(Insets.xl),
            child: Column(
              children: [
                ReceiptRow(
                  label: 'Amount',
                  value: Fmt.cedis(transaction.amount),
                  emphasize: true,
                ),
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
          Gaps.xl,
          FilledButton(
            onPressed: onRetry,
            child: const Text('Try a different payment method'),
          ),
          Gaps.md,
          OutlinedButton(
            onPressed: () => context.go(Routes.home),
            child: const Text('Back to home'),
          ),
        ],
      ),
    );
  }

  // Actions -------------------------------------------------------------------

  Future<void> _share(BuildContext context) async {
    final summary = [
      'GRID receipt (demo)',
      transaction.type.label,
      'Amount: ${Fmt.cedis(transaction.amount)}',
      '${transaction.type.accountLabel}: ${transaction.accountNumber}',
      if (transaction.token != null) 'Token: ${transaction.token}',
      'Ref: ${transaction.reference}',
      Fmt.dateTime(transaction.createdAt),
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: summary));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt copied — ready to share (demo)')),
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
