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
import 'booking_flow_screen.dart';

/// Book a service, and keep an eye on the ones already booked. GRID offers
/// two services, so each gets a full card rather than a row in a catalogue.
class ServicesHubScreen extends ConsumerWidget {
  const ServicesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open =
        ref
            .watch(serviceRequestsProvider)
            .where((request) => request.status.isOpen)
            .toList()
          ..sort((a, b) => a.preferredDate.compareTo(b.preferredDate));

    return Scaffold(
      appBar: const AppHeader(title: 'Services'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Insets.xl, Insets.xl, Insets.xl, 32),
        children: [
          const ScreenIntro(
            title: 'What can we take off your hands?',
            subtitle: 'Vetted cleaners and laundries near you.',
          ),
          Gaps.xl,
          for (final category in ServiceCategory.values) ...[
            ServiceCard(
              category: category,
              actionLabel: switch (category) {
                ServiceCategory.cleaning => 'Book a clean',
                ServiceCategory.laundry => 'Book a pickup',
              },
              onTap: () => context.push(
                Routes.bookService,
                extra: BookingArgs(category: category),
              ),
            ),
            Gaps.md,
          ],
          if (open.isNotEmpty) ...[
            SectionHeader(
              title: 'Your requests',
              actionLabel: 'History',
              onAction: () => context.go(Routes.activity),
              padding: const EdgeInsets.only(top: 16, bottom: Insets.md),
            ),
            for (final request in open) ...[
              _RequestTile(request: request),
              Gaps.md,
            ],
          ],
          Gaps.md,
          const StatusBanner(
            tone: BadgeTone.neutral,
            title: 'Every professional is vetted',
            message:
                'ID-checked, trained to GRID standards and rated by '
                'homeowners like you. You pay after the job is done.',
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request});
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
                '${Fmt.relativeDay(request.preferredDate)} · '
                '${request.timeSlot.split('–').first.trim()}',
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
            ServiceBadge(category: request.category, size: 42),
            Gaps.md,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.issue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.subtitle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    request.provider == null
                        ? request.propertyLabel
                        : '${request.provider!.name} · ${request.propertyLabel}',
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
