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

/// Every service GRID offers, grouped by section and searchable, with the
/// bookings already under way on top.
class ServicesHubScreen extends ConsumerStatefulWidget {
  const ServicesHubScreen({super.key, this.focusSearch = false});

  /// Opened from a search box elsewhere: start with the keyboard up.
  final bool focusSearch;

  @override
  ConsumerState<ServicesHubScreen> createState() => _ServicesHubScreenState();
}

class _ServicesHubScreenState extends ConsumerState<ServicesHubScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = ref.watch(catalogueProvider);
    final open =
        ref
            .watch(serviceRequestsProvider)
            .where((r) => r.status.isOpen || r.awaitingConfirmation)
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return Scaffold(
      appBar: const AppHeader(title: 'Services'),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(catalogueProvider);
          await ref.read(serviceRequestsProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Insets.xl,
            Insets.lg,
            Insets.xl,
            32,
          ),
          children: [
            TextField(
              controller: _search,
              autofocus: widget.focusSearch,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search for a service',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() {
                          _search.clear();
                          _query = '';
                        }),
                      ),
              ),
            ),
            if (open.isNotEmpty && _query.isEmpty) ...[
              const SectionHeader(
                title: 'Your bookings',
                padding: EdgeInsets.only(top: 28, bottom: Insets.md),
              ),
              for (final request in open) ...[
                BookingTile(request: request),
                Gaps.md,
              ],
            ],
            ...switch (catalogue) {
              AsyncData(:final value) => _sections(value),
              AsyncError() => [
                Gaps.xxl,
                ErrorView(
                  title: 'Couldn\'t load services',
                  message: 'Check your connection and try again.',
                  onRetry: () => ref.invalidate(catalogueProvider),
                ),
              ],
              _ => [Gaps.xxl, const SkeletonCard(height: 220)],
            },
            if (_query.isEmpty) ...[Gaps.xxl, const _TrustPanel()],
          ],
        ),
      ),
    );
  }

  List<Widget> _sections(ServiceCatalogue catalogue) {
    if (_query.trim().isNotEmpty) {
      final found = catalogue.search(_query);
      return [
        const SizedBox(height: 28),
        if (found.isEmpty)
          EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Nothing matches "${_query.trim()}"',
            message:
                'GRID offers the services below. More are coming to your area.',
            compact: true,
          )
        else
          _Grid(services: found),
      ];
    }
    return [
      for (final section in catalogue.sections) ...[
        Padding(
          padding: const EdgeInsets.only(top: 28, bottom: Insets.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  section.name,
                  style: AppText.title.copyWith(fontSize: 20),
                ),
              ),
              Text(
                '${section.services.length} service${section.services.length == 1 ? '' : 's'}',
                style: AppText.caption,
              ),
            ],
          ),
        ),
        _Grid(services: section.services),
      ],
    ];
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.services});
  final List<ServiceItem> services;

  /// Rows rather than a fixed-ratio grid, so a two-line name or large text
  /// grows the row instead of overflowing the tile.
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final columns = box.maxWidth < 300 ? 2 : 3;
      return Column(
        children: [
          for (var i = 0; i < services.length; i += columns) ...[
            if (i > 0) Gaps.lg,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var j = i; j < i + columns; j++) ...[
                  if (j > i) Gaps.md,
                  Expanded(
                    child: j < services.length
                        ? ServiceTile(
                            service: services[j],
                            showPrice: true,
                            onTap: () =>
                                context.push(Routes.service(services[j].slug)),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ],
        ],
      );
    },
  );
}

/// Why a stranger can be let into the house: the promises behind every booking.
class _TrustPanel extends StatelessWidget {
  const _TrustPanel();

  static const _promises = [
    (
      Icons.verified_user_outlined,
      'ID-checked and trained',
      'Every professional meets GRID standards. Licensed where the law asks.',
    ),
    (
      Icons.sell_outlined,
      'One price, up front',
      'You see the price before you book. No haggling.',
    ),
    (
      Icons.shield_outlined,
      'Paid only when it\'s done',
      'GRID holds your payment until you confirm the job.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
    decoration: const BoxDecoration(
      color: AppColors.surfaceSubtle,
      borderRadius: Corners.lgRadius,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Booked through GRID', style: AppText.heading),
        Gaps.lg,
        for (final (icon, title, detail) in _promises)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppColors.navy, size: 22),
                Gaps.md,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppText.subtitle.copyWith(fontSize: 14.5),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        detail,
                        style: AppText.caption.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// A booking in a list: when, status, what, and who.
class BookingTile extends StatelessWidget {
  const BookingTile({super.key, required this.request});
  final ServiceRequest request;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: () => context.push(Routes.serviceRequest(request.id)),
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                '${Fmt.relativeDay(request.scheduledAt)} · ${Fmt.time(request.scheduledAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption,
              ),
            ),
            Flexible(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: StatusBadge.request(request.status),
              ),
            ),
          ],
        ),
        Gaps.md,
        Row(
          children: [
            ServiceBadge(slug: request.serviceSlug, size: 46),
            Gaps.md,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.subtitle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    request.provider == null
                        ? request.area
                        : '${request.provider!.name} · ${request.area}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(fontSize: 13.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
          ],
        ),
      ],
    ),
  );
}
