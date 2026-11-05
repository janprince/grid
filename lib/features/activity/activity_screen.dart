import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
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
      appBar: const AppHeader(title: 'Activity'),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Gaps.lg,
            // One chip everywhere, replacing the stock SegmentedButton and
            // the hand-rolled property pills it sat above.
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Insets.xl),
                children: [
                  for (final (filter, label) in const [
                    (_Filter.all, 'All'),
                    (_Filter.payments, 'Payments'),
                    (_Filter.services, 'Services'),
                  ]) ...[
                    GridChip(
                      label: label,
                      selected: _filter == filter,
                      onTap: () => setState(() => _filter = filter),
                    ),
                    Gaps.sm,
                  ],
                ],
              ),
            ),
            if (properties.length > 1) ...[
              Gaps.sm,
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Insets.xl),
                  children: [
                    GridChip(
                      label: 'All homes',
                      icon: Icons.home_rounded,
                      accent: AppColors.navy,
                      selected: _propertyFilter == null,
                      onTap: () => setState(() => _propertyFilter = null),
                    ),
                    Gaps.sm,
                    for (final property in properties) ...[
                      GridChip(
                        label: property.nickname,
                        accent: AppColors.navy,
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
            Gaps.md,
            Expanded(
              child: items.isEmpty
                  ? _emptyState(context)
                  : _GroupedActivityList(items: items),
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
        icon: Icons.cleaning_services_rounded,
        title: 'No service requests',
        message:
            'Book a clean or a laundry pickup and track every job '
            'here.',
        actionLabel: 'Book a service',
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

/// History under date headers, the way every reference banking app does it —
/// the header carries the "when", so each row no longer has to repeat it.
class _GroupedActivityList extends StatelessWidget {
  const _GroupedActivityList({required this.items});

  final List<ActivityItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Flatten to headers and rows so the whole history stays one lazily
    // built list rather than a column of nested lists.
    final entries = <(String?, ActivityItem?)>[];
    String? lastGroup;
    for (final item in items) {
      final group = Fmt.relativeDay(item.date);
      if (group != lastGroup) {
        entries.add((group, null));
        lastGroup = group;
      }
      entries.add((null, item));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(Insets.md, 0, Insets.md, Insets.xxxl),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final (header, item) = entries[i];
        if (header != null) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              Insets.sm,
              i == 0 ? Insets.sm : Insets.xl,
              Insets.sm,
              Insets.sm,
            ),
            child: Text(
              header,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.faint,
                letterSpacing: 1.0,
              ),
            ),
          );
        }
        return ActivityTile(
          item: item!,
          onTap: () {
            if (item.transaction != null) {
              showTransactionSheet(context, item.transaction!);
            } else if (item.request != null) {
              context.push(Routes.serviceRequest(item.request!.id));
            }
          },
        );
      },
    );
  }
}
