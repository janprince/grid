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
                  for (final account in entry.value)
                    _AccountCard(
                      account: account,
                      divider: account != entry.value.last,
                    ),
                ],
              ],
            ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.account, required this.divider});

  final UtilityAccount account;
  final bool divider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final property = ref.watch(propertyByIdProvider(account.propertyId));
    final number = account.type.isPhoneAccount
        ? Fmt.ghanaPhone(account.accountNumber)
        : account.accountNumber;
    return HistoryRow(
      leading: BillerMark(account.type, size: 48, network: account.network),
      title: account.nickname,
      subtitle: [number, ?property?.nickname].join(' · '),
      status: account.isDefault
          ? 'Default'
          : account.lastPaidAt == null
          ? null
          : Fmt.lastPaidLabel(account.lastPaidAt!),
      tone: account.isDefault ? HistoryTone.active : HistoryTone.quiet,
      onTap: () => showAccountFormSheet(context, existing: account),
      divider: divider,
    );
  }
}
