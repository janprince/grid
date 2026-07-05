import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../activity/widgets/activity_tile.dart';
import '../payments/widgets/transaction_receipt_sheet.dart';
import 'widgets/emergency_sheet.dart';
import 'widgets/home_hero_card.dart';
import 'widgets/property_switcher_sheet.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/reminder_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(sessionProvider).user;
    final property = ref.watch(selectedPropertyProvider);
    final reminders = ref.watch(remindersProvider);
    final activity = ref.watch(activityProvider).take(4).toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.xl,
                  Insets.lg,
                  Insets.xl,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.inkMuted,
                            ),
                          ),
                          Text(
                            user?.firstName ?? 'there',
                            style: theme.textTheme.headlineLarge,
                          ),
                        ],
                      ),
                    ),
                    if (property != null)
                      _PropertyChip(
                        label: property.nickname,
                        onTap: () => showPropertySwitcher(context),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.xl,
                  Insets.xl,
                  Insets.xl,
                  0,
                ),
                child: property == null
                    ? EmptyState(
                        icon: Icons.other_houses_rounded,
                        title: 'No saved homes',
                        message:
                            'Add a home to start managing its utilities '
                            'and services in one place.',
                        actionLabel: 'Add your first home',
                        onAction: () => context.push(Routes.addProperty),
                        compact: true,
                      )
                    : HomeHeroCard(property: property),
              ),
            ),
            const SliverToBoxAdapter(
              child: SectionHeader(title: 'Quick actions'),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: Insets.xl),
                child: QuickActionsGrid(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.xl,
                  Insets.xxl,
                  Insets.xl,
                  0,
                ),
                child: _EmergencyBanner(
                  onTap: () => showEmergencySheet(context),
                ),
              ),
            ),
            if (reminders.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: SectionHeader(title: 'Upcoming reminders'),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.xl),
                sliver: SliverList.separated(
                  itemCount: reminders.length,
                  separatorBuilder: (_, _) => Gaps.md,
                  itemBuilder: (context, i) =>
                      ReminderCard(reminder: reminders[i]),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Recent activity',
                actionLabel: 'See all',
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
              sliver: activity.isEmpty
                  ? const SliverToBoxAdapter(
                      child: EmptyState(
                        icon: Icons.receipt_long_rounded,
                        title: 'No activity yet',
                        message:
                            'Payments and service requests will appear '
                            'here as you use GRID.',
                        compact: true,
                      ),
                    )
                  : SliverList.separated(
                      itemCount: activity.length,
                      separatorBuilder: (_, _) => Gaps.md,
                      itemBuilder: (context, i) {
                        final item = activity[i];
                        return ActivityTile(
                          item: item,
                          onTap: () {
                            if (item.transaction != null) {
                              showTransactionSheet(context, item.transaction!);
                            } else if (item.request != null) {
                              context.push(
                                Routes.serviceRequest(item.request!.id),
                              );
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

class _PropertyChip extends StatelessWidget {
  const _PropertyChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: Corners.pill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.md,
            vertical: Insets.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: Corners.pill,
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.home_rounded, size: 16, color: AppColors.forest),
              Gaps.xs,
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyBanner extends StatelessWidget {
  const _EmergencyBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.dangerSoft,
      borderRadius: Corners.lgRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Insets.lg),
          child: Row(
            children: [
              const Icon(
                Icons.emergency_rounded,
                color: AppColors.danger,
                size: 26,
              ),
              Gaps.md,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need urgent help?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                    Text(
                      'Burst pipe, power fault — get someone fast.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.danger.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.danger),
            ],
          ),
        ),
      ),
    );
  }
}
