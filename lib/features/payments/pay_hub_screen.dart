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
import 'pay_groups.dart';
import 'widgets/pay_flow_parts.dart';
import 'widgets/pay_help_sheet.dart';
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
      appBar: AppHeader(
        title: 'Pay bills',
        trailing: NavChip(
          onPressed: () => showPayHelpSheet(context),
          icon: Icons.question_mark_rounded,
          tooltip: 'Help',
          color: AppColors.navySoft,
          iconColor: AppColors.navy,
        ),
      ),
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
            const SliverToBoxAdapter(
              child: SectionHeader(title: 'What are you paying for?'),
            ),
            // Two to a row, each biller's own logo large on a white card, so
            // the page is scanned by brand. TV, airtime and data open a
            // choice of provider rather than crowding this page with eight.
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                Insets.xl,
                Insets.xs,
                Insets.xl,
                Insets.sm,
              ),
              sliver: SliverToBoxAdapter(
                child: ProviderGrid(
                  children: [
                    for (final group in PayGroup.values)
                      ProviderTile(
                        label: group.label,
                        caption: _caption(group, accounts),
                        mark: group.mark(),
                        onTap: () => context.push(group.route),
                      ),
                  ],
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
                  Insets.xl,
                  0,
                  Insets.xl,
                  Insets.xxxl,
                ),
                sliver: SliverList.builder(
                  itemCount: recentPayments.length,
                  itemBuilder: (context, i) => _RecentPaymentTile(
                    tx: recentPayments[i],
                    divider: i != recentPayments.length - 1,
                  ),
                ),
              ),
            ] else
              const SliverToBoxAdapter(child: SizedBox(height: Insets.xxxl)),
          ],
        ),
      ),
    );
  }

  /// "2 saved" once there are saved accounts, otherwise what it covers.
  static String _caption(PayGroup group, List<UtilityAccount> accounts) {
    final saved = accounts.where((a) => group.types.contains(a.type)).length;
    return saved > 0 ? '$saved saved' : group.caption;
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
                BillerMark(account.type, size: 34, network: account.network),
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

class _RecentPaymentTile extends ConsumerWidget {
  const _RecentPaymentTile({required this.tx, required this.divider});

  final PaymentTransaction tx;
  final bool divider;

  void _payAgain(BuildContext context, WidgetRef ref) {
    final account = ref
        .read(accountsProvider)
        .where((a) => a.type == tx.type && a.accountNumber == tx.accountNumber)
        .firstOrNull;
    context.push(
      account == null
          ? Routes.payFlow(tx.type.name)
          : '${Routes.payFlow(tx.type.name)}?account=${account.id}',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => HistoryRow(
    leading: BillerMark(tx.type, size: 48, network: tx.network),
    // Unnamed payments carry their type as the nickname; the number is
    // what tells two of them apart.
    title: tx.accountNickname == tx.type.label
        ? (tx.type.isPhoneAccount
              ? Fmt.ghanaPhone(tx.accountNumber)
              : tx.accountNumber)
        : tx.accountNickname,
    subtitle: '${tx.type.label} · ${Fmt.relativeDay(tx.createdAt)}',
    onTap: () => showTransactionSheet(context, tx),
    divider: divider,
    trailing: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          Fmt.cedis(tx.amount),
          style: AppText.heading.copyWith(
            fontSize: 16,
            fontFeatures: AppText.tabularFigures,
          ),
        ),
        InkWell(
          onTap: () => _payAgain(context, ref),
          borderRadius: Corners.smRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Pay again',
              style: AppText.body.copyWith(
                fontSize: 14,
                height: 1.2,
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
