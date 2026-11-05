import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import 'widgets/account_form_sheet.dart';

/// Manage saved meters, water accounts, smartcards and phone numbers.
class SavedAccountsScreen extends ConsumerWidget {
  const SavedAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final grouped = <UtilityType, List<UtilityAccount>>{};
    for (final account in accounts) {
      grouped.putIfAbsent(account.type, () => []).add(account);
    }

    return Scaffold(
      appBar: AppHeader(
        title: 'Saved accounts',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      floatingActionButton: accounts.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showAccountFormSheet(context),
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add account'),
            ),
      body: accounts.isEmpty
          ? EmptyState(
              icon: Icons.bookmark_add_rounded,
              title: 'No saved accounts',
              message:
                  'Save your meters, smartcards and numbers once — then '
                  'every payment takes seconds.',
              actionLabel: 'Add an account',
              onAction: () => showAccountFormSheet(context),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                Insets.xl,
                Insets.sm,
                Insets.xl,
                96,
              ),
              children: [
                for (final entry in grouped.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      0,
                      Insets.xl,
                      0,
                      Insets.md,
                    ),
                    child: Text(
                      entry.key.label,
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(color: AppColors.faint),
                    ),
                  ),
                  for (final account in entry.value) ...[
                    _AccountCard(account: account),
                    Gaps.md,
                  ],
                ],
              ],
            ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.account});

  final UtilityAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final property = ref.watch(propertyByIdProvider(account.propertyId));

    return AppCard(
      padding: const EdgeInsets.all(Insets.lg),
      onTap: () => showAccountFormSheet(context, existing: account),
      child: Row(
        children: [
          BillerMark(account.type),
          Gaps.md,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        account.nickname,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (account.isDefault) ...[
                      Gaps.sm,
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: AppColors.warning,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  account.accountNumber,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                if (property != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${property.nickname} • ${property.location}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.faint,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Gaps.sm,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (account.lastPaidAt != null)
                Text(
                  Fmt.lastPaidLabel(account.lastPaidAt!),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.faint,
                  ),
                ),
              const SizedBox(height: 4),
              const Icon(Icons.edit_outlined, size: 18, color: AppColors.faint),
            ],
          ),
        ],
      ),
    );
  }
}
