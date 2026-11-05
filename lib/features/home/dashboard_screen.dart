import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/service_art.dart';
import '../../core/widgets/widgets.dart';
import '../activity/widgets/activity_tile.dart';
import '../payments/widgets/transaction_receipt_sheet.dart';
import '../services/booking_flow_screen.dart';
import 'widgets/home_ground.dart';
import 'widgets/pay_shortcuts.dart';
import 'widgets/reminder_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final property = ref.watch(selectedPropertyProvider);
    final homesLoaded = ref.watch(homesLoadedProvider);
    final reminders = ref.watch(remindersProvider);
    final activity = ref.watch(activityProvider).take(4).toList();

    return Scaffold(
      // No SafeArea here: the navy ground runs up under the status bar so
      // it reads as the page itself rather than as a card on a page.
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: property == null && !homesLoaded
                ? const SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(Insets.xl),
                      child: SkeletonCard(height: 180),
                    ),
                  )
                : property == null
                ? SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(Insets.xl),
                      child: EmptyState(
                        icon: Icons.other_houses_rounded,
                        title: 'No saved homes',
                        message:
                            'Add a home to start managing its utilities '
                            'and services in one place.',
                        actionLabel: 'Add your first home',
                        onAction: () => context.push(Routes.addProperty),
                        compact: true,
                      ),
                    ),
                  )
                : _GroundWithSheetLip(child: HomeGround(property: property)),
          ),
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Pay something',
              padding: EdgeInsets.fromLTRB(
                Insets.xl,
                Insets.xxl,
                Insets.xl,
                Insets.lg,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: PayShortcuts()),
          const SliverToBoxAdapter(
            child: SectionHeader(title: 'Book a service'),
          ),
          const SliverToBoxAdapter(child: _ServiceShortcuts()),
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
                    separatorBuilder: (_, _) => Gaps.sm,
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
    );
  }
}

/// Overlays the page background on the bottom of the navy ground with
/// rounded top corners, so the rest of the dashboard reads as a sheet
/// rising over the brand colour rather than as a separate section.
class _GroundWithSheetLip extends StatelessWidget {
  const _GroundWithSheetLip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: Insets.xxl,
            decoration: const BoxDecoration(
              color: AppColors.canvas,
              borderRadius: Corners.sheetTop,
            ),
          ),
        ),
      ],
    );
  }
}

/// The two services as compact tinted tiles, side by side.
class _ServiceShortcuts extends StatelessWidget {
  const _ServiceShortcuts();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Insets.xl),
    child: Row(
      children: [
        for (final category in ServiceCategory.values) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => context.push(
                Routes.bookService,
                extra: BookingArgs(category: category),
              ),
              child: Semantics(
                button: true,
                label: 'Book ${category.label}',
                excludeSemantics: true,
                child: TintCard(
                  tint: category.tint,
                  arc: category.arc,
                  padding: const EdgeInsets.all(Insets.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ServiceBadge(category: category, size: 40),
                      Gaps.lg,
                      Text(
                        category.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.subtitle.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'From ${Fmt.cedis(category.fromPrice)}',
                        style: AppText.caption.copyWith(
                          color: category.ink,
                          fontFeatures: AppText.tabularFigures,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (category != ServiceCategory.values.last) Gaps.md,
        ],
      ],
    ),
  );
}
