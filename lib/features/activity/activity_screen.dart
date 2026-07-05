import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../payments/widgets/transaction_receipt_sheet.dart';
import 'widgets/activity_tile.dart';

enum _Filter { all, payments, services }

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  _Filter _filter = _Filter.all;
  String? _propertyFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = ref.watch(activityProvider);
    final properties = ref.watch(propertiesProvider);

    final items = all.where((item) {
      final kindOk = switch (_filter) {
        _Filter.all => true,
        _Filter.payments => item.kind == ActivityKind.payment,
        _Filter.services => item.kind == ActivityKind.service,
      };
      final propertyOk =
          _propertyFilter == null ||
          (item.kind == ActivityKind.payment
                  ? item.transaction?.propertyId
                  : item.request?.propertyId) ==
              _propertyFilter;
      return kindOk && propertyOk;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.xl,
                Insets.lg,
                Insets.xl,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Activity', style: theme.textTheme.headlineLarge),
                  Gaps.xs,
                  Text(
                    'Every payment and service request, in one history.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                  Gaps.lg,
                  SegmentedButton<_Filter>(
                    segments: const [
                      ButtonSegment(value: _Filter.all, label: Text('All')),
                      ButtonSegment(
                        value: _Filter.payments,
                        label: Text('Payments'),
                      ),
                      ButtonSegment(
                        value: _Filter.services,
                        label: Text('Services'),
                      ),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (selection) =>
                        setState(() => _filter = selection.first),
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: AppColors.mint,
                      selectedForegroundColor: AppColors.forestDeep,
                    ),
                  ),
                  Gaps.md,
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _PropertyFilterChip(
                          label: 'All homes',
                          selected: _propertyFilter == null,
                          onTap: () => setState(() => _propertyFilter = null),
                        ),
                        Gaps.sm,
                        for (final property in properties) ...[
                          _PropertyFilterChip(
                            label: property.nickname,
                            selected: _propertyFilter == property.id,
                            onTap: () =>
                                setState(() => _propertyFilter = property.id),
                          ),
                          Gaps.sm,
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? _emptyState(context)
                  : ListView.separated(
                      padding: const EdgeInsets.all(Insets.xl),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => Gaps.md,
                      itemBuilder: (context, i) {
                        final item = items[i];
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

  Widget _emptyState(BuildContext context) {
    return switch (_filter) {
      _Filter.payments => EmptyState(
        icon: Icons.receipt_long_rounded,
        title: 'No payments yet',
        message:
            'Utility payments you make will appear here with '
            'their receipts.',
        actionLabel: 'Make a payment',
        onAction: () => context.go(Routes.pay),
      ),
      _Filter.services => EmptyState(
        icon: Icons.handyman_rounded,
        title: 'No service requests',
        message:
            'Book trusted help for your home and track every job '
            'here.',
        actionLabel: 'Request a service',
        onAction: () => context.push(Routes.bookService),
      ),
      _Filter.all => EmptyState(
        icon: Icons.history_rounded,
        title: 'Nothing here yet',
        message:
            'Payments and service requests will appear here as '
            'you use GRID.',
        actionLabel: 'Make a payment',
        onAction: () => context.go(Routes.pay),
      ),
    };
  }
}

class _PropertyFilterChip extends StatelessWidget {
  const _PropertyFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.forestDeep : AppColors.card,
      borderRadius: Corners.pill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg,
            vertical: Insets.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: Corners.pill,
            border: Border.all(
              color: selected ? AppColors.forestDeep : AppColors.outline,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
