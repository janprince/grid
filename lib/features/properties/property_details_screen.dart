import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/api/api_exception.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../activity/widgets/activity_tile.dart';
import '../payments/widgets/account_form_sheet.dart';
import '../payments/widgets/transaction_receipt_sheet.dart';

class PropertyDetailsScreen extends ConsumerWidget {
  const PropertyDetailsScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final property = ref.watch(propertyByIdProvider(propertyId));

    if (property == null) {
      return Scaffold(
        appBar: AppHeader(
          title: 'Home',
          onBack: () => Navigator.of(context).maybePop(),
        ),
        body: const ErrorView(
          title: 'Home not found',
          message: 'This home may have been removed.',
        ),
      );
    }

    final accounts = ref
        .watch(accountsProvider)
        .where((a) => a.propertyId == property.id)
        .toList();
    final activity = ref
        .watch(activityProvider)
        .where(
          (item) =>
              (item.transaction?.propertyId ?? item.request?.propertyId) ==
              property.id,
        )
        .take(6)
        .toList();

    return Scaffold(
      appBar: AppHeader(
        title: property.nickname,
        onBack: () => context.pop(),
        trailing: NavChip(
          icon: Icons.edit_outlined,
          tooltip: 'Edit home',
          onPressed: () => context.push(Routes.editProperty(property.id)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Insets.xl),
        children: [
          NavyPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      property.kind == PropertyKind.apartment
                          ? Icons.apartment_rounded
                          : Icons.home_rounded,
                      color: AppColors.navySoft,
                    ),
                    Gaps.sm,
                    Expanded(
                      child: Text(
                        property.nickname,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (property.isPrimary)
                      const StatusBadge(
                        label: 'Primary',
                        tone: BadgeTone.success,
                      ),
                  ],
                ),
                Gaps.sm,
                Text(
                  '${property.address}\n${property.location}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onNavyMuted,
                  ),
                ),
                if (!property.isPrimary) ...[
                  Gaps.lg,
                  SecondaryButton(
                    label: 'Make primary home',
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await ref
                            .read(propertiesProvider.notifier)
                            .setPrimary(property.id);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              '${property.nickname} is now your primary home',
                            ),
                          ),
                        );
                      } on Object catch (error) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(errorMessage(error))),
                        );
                      }
                    },
                    expand: false,
                  ),
                ],
              ],
            ),
          ),
          SectionHeader(
            title: 'Linked utilities',
            actionLabel: 'Add',
            onAction: () => showAccountFormSheet(context),
            padding: const EdgeInsets.fromLTRB(0, Insets.xxl, 0, Insets.md),
          ),
          if (accounts.isEmpty)
            const EmptyState(
              icon: Icons.bookmark_add_rounded,
              title: 'No linked utilities',
              message:
                  'Link meters and accounts to this home so every '
                  'payment is filed in the right place.',
              compact: true,
            )
          else
            for (final account in accounts) ...[
              AppCard(
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
                          Text(
                            account.nickname,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${account.type.label} • ${Fmt.masked(account.accountNumber)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (account.dueDate != null)
                      StatusBadge(
                        label: Fmt.dueLabel(account.dueDate!),
                        tone:
                            account.dueDate!
                                    .difference(DateTime.now())
                                    .inDays <=
                                3
                            ? BadgeTone.warning
                            : BadgeTone.neutral,
                      ),
                  ],
                ),
              ),
              Gaps.md,
            ],
          SectionHeader(
            title: 'Recent activity',
            padding: const EdgeInsets.fromLTRB(0, Insets.xl, 0, Insets.md),
          ),
          if (activity.isEmpty)
            const EmptyState(
              icon: Icons.history_rounded,
              title: 'No activity for this home',
              message:
                  'Payments and service requests for this home will '
                  'show up here.',
              compact: true,
            )
          else
            for (final item in activity) ...[
              ActivityTile(
                item: item,
                onTap: () {
                  if (item.transaction != null) {
                    showTransactionSheet(context, item.transaction!);
                  } else if (item.request != null) {
                    context.push(Routes.serviceRequest(item.request!.id));
                  }
                },
              ),
              Gaps.md,
            ],
          Gaps.xxl,
        ],
      ),
    );
  }
}
