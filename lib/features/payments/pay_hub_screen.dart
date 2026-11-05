import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import 'widgets/transaction_receipt_sheet.dart';

class PayHubScreen extends ConsumerWidget {
  const PayHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final savedHighlights = _highlights(accounts);
    final recentPayments = ref
        .watch(transactionsProvider)
        .where((t) => t.status == TransactionStatus.success)
        .take(3)
        .toList();

    return Scaffold(
      appBar: const AppHeader(title: 'Pay bills'),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            if (savedHighlights.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Saved accounts',
                  actionLabel: 'Manage',
                  onAction: () => context.push(Routes.savedAccounts),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 128,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: Insets.xl),
                    scrollDirection: Axis.horizontal,
                    itemCount: savedHighlights.length,
                    separatorBuilder: (_, _) => Gaps.md,
                    itemBuilder: (context, i) =>
                        _SavedAccountCard(account: savedHighlights[i]),
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SectionHeader(title: 'Utilities')),
            // Rows, not a 2-column grid. Eight tiles that differed only by
            // glyph colour were unscannable; a list lets each biller's own
            // mark carry the row.
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.md),
              sliver: SliverList.builder(
                itemCount: UtilityType.values.length,
                itemBuilder: (context, i) => _UtilityRow(
                  type: UtilityType.values[i],
                  accounts: accounts,
                ),
              ),
            ),
            if (recentPayments.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Pay again',
                  actionLabel: 'History',
                  onAction: () => context.go(Routes.activity),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.md,
                  0,
                  Insets.md,
                  Insets.xxxl,
                ),
                sliver: SliverList.builder(
                  itemCount: recentPayments.length,
                  itemBuilder: (context, i) =>
                      _RecentPaymentTile(tx: recentPayments[i]),
                ),
              ),
            ] else
              const SliverToBoxAdapter(child: SizedBox(height: Insets.xxxl)),
          ],
        ),
      ),
    );
  }

  /// Default/most relevant account per type, due-soon first.
  static List<UtilityAccount> _highlights(List<UtilityAccount> accounts) {
    final byType = <UtilityType, UtilityAccount>{};
    for (final a in accounts) {
      final existing = byType[a.type];
      if (existing == null || (a.isDefault && !existing.isDefault)) {
        byType[a.type] = a;
      }
    }
    // Accounts without a due date sort last.
    const farFuture = 8640000000000000; // max DateTime ms, JS-safe
    final list = byType.values.toList()
      ..sort((a, b) {
        final aDue = a.dueDate?.millisecondsSinceEpoch ?? farFuture;
        final bDue = b.dueDate?.millisecondsSinceEpoch ?? farFuture;
        return aDue.compareTo(bDue);
      });
    return list.take(5).toList();
  }
}

/// The one place on this screen that is allowed to float — a short
/// horizontal run of the accounts you actually return to.
class _SavedAccountCard extends StatelessWidget {
  const _SavedAccountCard({required this.account});

  final UtilityAccount account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final due = account.dueDate;
    final dueSoon = due != null && due.difference(DateTime.now()).inDays <= 3;

    return SizedBox(
      width: 208,
      child: AppCard(
        variant: AppCardVariant.raised,
        border: Border.all(color: AppColors.line),
        padding: const EdgeInsets.all(Insets.lg),
        borderRadius: Corners.lgRadius,
        onTap: () => context.push(
          '${Routes.payFlow(account.type.name)}?account=${account.id}',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BillerMark(account.type, size: 34),
                const Spacer(),
                if (dueSoon)
                  const StatusBadge(label: 'Due soon', tone: BadgeTone.warning)
                else if (account.isDefault)
                  const StatusBadge(label: 'Default', tone: BadgeTone.success),
              ],
            ),
            const Spacer(),
            Text(
              account.nickname,
              style: theme.textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              due != null
                  ? Fmt.dueLabel(due)
                  : account.lastPaidAt != null
                  ? Fmt.lastPaidLabel(account.lastPaidAt!)
                  : Fmt.masked(account.accountNumber),
              style: theme.textTheme.labelSmall?.copyWith(
                color: dueSoon ? AppColors.warning : AppColors.faint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UtilityRow extends StatelessWidget {
  const _UtilityRow({required this.type, required this.accounts});

  final UtilityType type;
  final List<UtilityAccount> accounts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saved = accounts.where((a) => a.type == type).length;

    return InkWell(
      onTap: () => context.push(Routes.payFlow(type.name)),
      borderRadius: Corners.rowRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.sm,
          vertical: Insets.md,
        ),
        child: Row(
          children: [
            BillerMark(type),
            Gaps.md,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.label,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    saved > 0
                        ? '$saved saved account${saved == 1 ? '' : 's'}'
                        : type.tagline,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.faint,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.faint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentPaymentTile extends ConsumerWidget {
  const _RecentPaymentTile({required this.tx});

  final PaymentTransaction tx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => showTransactionSheet(context, tx),
      borderRadius: Corners.rowRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.sm,
          vertical: Insets.md,
        ),
        child: Row(
          children: [
            BillerMark(tx.type),
            Gaps.md,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.accountNickname,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${Fmt.cedis(tx.amount)} · '
                    '${Fmt.relativeDay(tx.createdAt)}',
                    style: theme.textTheme.bodySmall?.tabular.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Gaps.sm,
            SecondaryButton(
              label: 'Pay again',
              onPressed: () {
                final account = ref
                    .read(accountsProvider)
                    .where(
                      (a) =>
                          a.type == tx.type &&
                          a.accountNumber == tx.accountNumber,
                    )
                    .firstOrNull;
                context.push(
                  account == null
                      ? Routes.payFlow(tx.type.name)
                      : '${Routes.payFlow(tx.type.name)}?account=${account.id}',
                );
              },
              expand: false,
            ),
          ],
        ),
      ),
    );
  }
}
