import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';

class PropertiesScreen extends ConsumerWidget {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final properties = ref.watch(propertiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My homes')),
      floatingActionButton: properties.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push(Routes.addProperty),
              backgroundColor: AppColors.forestDeep,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add home'),
            ),
      body: properties.isEmpty
          ? EmptyState(
              icon: Icons.other_houses_rounded,
              title: 'No saved homes',
              message:
                  'Your digital concierge is ready. Add a property to '
                  'start managing utilities and services seamlessly.',
              actionLabel: 'Add your first home',
              onAction: () => context.push(Routes.addProperty),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                Insets.xl,
                Insets.sm,
                Insets.xl,
                96,
              ),
              itemCount: properties.length,
              separatorBuilder: (_, _) => Gaps.lg,
              itemBuilder: (context, i) =>
                  _PropertyCard(property: properties[i]),
            ),
    );
  }
}

class _PropertyCard extends ConsumerWidget {
  const _PropertyCard({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accounts = ref
        .watch(accountsProvider)
        .where((a) => a.propertyId == property.id)
        .toList();
    final openRequests = ref
        .watch(serviceRequestsProvider)
        .where((r) => r.propertyId == property.id && r.status.isOpen)
        .length;

    return AppCard(
      padding: const EdgeInsets.all(Insets.xl),
      onTap: () => context.push(Routes.property(property.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TintedIcon(
                property.kind == PropertyKind.apartment
                    ? Icons.apartment_rounded
                    : Icons.home_rounded,
                size: 48,
                color: AppColors.forest,
                background: AppColors.mint,
              ),
              Gaps.md,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(property.nickname, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      '${property.address}, ${property.city}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (property.isPrimary)
                const StatusBadge(label: 'Primary', tone: BadgeTone.success),
            ],
          ),
          if (accounts.isNotEmpty) ...[
            Gaps.lg,
            Wrap(
              spacing: Insets.sm,
              runSpacing: Insets.sm,
              children: [
                for (final account in accounts.take(4))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Insets.md,
                      vertical: Insets.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tealSoft,
                      borderRadius: Corners.pill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          account.type.icon,
                          size: 13,
                          color: AppColors.teal,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          account.type.shortLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          if (openRequests > 0) ...[
            Gaps.md,
            Text(
              '$openRequests open service request${openRequests == 1 ? '' : 's'}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.warning,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
