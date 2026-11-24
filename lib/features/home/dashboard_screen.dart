import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../activity/widgets/activity_tile.dart';
import '../payments/widgets/transaction_receipt_sheet.dart';
import '../services/services_hub_screen.dart';
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
    final upcoming =
        ref
            .watch(serviceRequestsProvider)
            .where((r) => r.status.isOpen || r.awaitingConfirmation)
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.xl,
                Insets.lg,
                Insets.xl,
                0,
              ),
              child: _SearchPill(
                onTap: () => context.go(Routes.servicesSearch),
              ),
            ),
          ),
          if (upcoming.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: SectionHeader(title: 'Your next booking'),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.xl),
                child: BookingTile(request: upcoming.first),
              ),
            ),
          ],
          // Bills are what brings people back each week, so they stay near
          // the top; services follow with room to show themselves off.
          const SliverToBoxAdapter(
            child: SectionHeader(title: 'Pay something'),
          ),
          const SliverToBoxAdapter(child: PayShortcuts()),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Book a service',
              actionLabel: 'See all',
              onAction: () => context.go(Routes.services),
            ),
          ),
          const SliverToBoxAdapter(child: _ServiceShortcuts()),
          const SliverToBoxAdapter(child: _Featured()),
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
                : SliverList.builder(
                    itemCount: activity.length,
                    itemBuilder: (context, i) {
                      final item = activity[i];
                      return ActivityTile(
                        item: item,
                        divider: i != activity.length - 1,
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

/// "Search for a service": opens the Services tab with the keyboard up.
class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Search for a service',
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: Corners.pill,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: Corners.pill,
          boxShadow: AppColors.raisedShadow,
        ),
        child: const Row(
          children: [
            Icon(Icons.search_rounded, color: AppColors.ink),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'What do you need done?',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15.5, color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Fixed-price services, one card each, swiped sideways.
class _Featured extends ConsumerWidget {
  const _Featured();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services =
        ref.watch(catalogueProvider).value?.services ?? const <ServiceItem>[];
    if (services.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: SizedBox(
        height: 172,
        child: PageView.builder(
          controller: PageController(viewportFraction: 0.88),
          padEnds: false,
          itemCount: services.length,
          itemBuilder: (context, i) => Padding(
            padding: EdgeInsets.fromLTRB(i == 0 ? Insets.xl : 6, 4, 6, 12),
            child: FeaturedServiceCard(
              service: services[i],
              onTap: () => context.push(Routes.service(services[i].slug)),
            ),
          ),
        ),
      ),
    );
  }
}

/// The first four services as square tiles; the rest are a tap away.
class _ServiceShortcuts extends ConsumerWidget {
  const _ServiceShortcuts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogue = ref.watch(catalogueProvider);
    final services = (catalogue.value?.services ?? const <ServiceItem>[])
        .take(4)
        .toList();
    if (services.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: Insets.xl),
        child: catalogue.hasError
            ? TextLink(
                label: 'Couldn\'t load services. Try again',
                onPressed: () => ref.invalidate(catalogueProvider),
              )
            : const SkeletonCard(height: 110),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < 4; i++) ...[
            Expanded(
              child: i < services.length
                  ? ServiceTile(
                      service: services[i],
                      onTap: () =>
                          context.push(Routes.service(services[i].slug)),
                    )
                  : const SizedBox.shrink(),
            ),
            if (i != 3) Gaps.md,
          ],
        ],
      ),
    );
  }
}
