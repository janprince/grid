import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';

class RequestDetailsScreen extends ConsumerWidget {
  const RequestDetailsScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final request = ref.watch(serviceRequestByIdProvider(requestId));

    if (request == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Service request')),
        body: const ErrorView(
          title: 'Request not found',
          message: 'This service request may have been removed.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(request.category.label),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: Insets.lg),
            child: Center(child: DemoTag()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Insets.xl),
        children: [
          // Status header
          AppCard(
            padding: const EdgeInsets.all(Insets.lg),
            child: Row(
              children: [
                TintedIcon(request.category.icon, size: 48),
                Gaps.md,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.issue, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        '${request.reference} • ${Fmt.relativeDay(request.createdAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge.request(request.status),
              ],
            ),
          ),
          Gaps.md,
          if (request.status == ServiceRequestStatus.pending)
            const InfoBanner(
              icon: Icons.search_rounded,
              message:
                  'We are matching your request with vetted '
                  'professionals nearby. You will be notified as soon as '
                  'one is assigned.',
            ),
          if (request.provider != null) ...[
            Gaps.md,
            _ProviderCard(provider: request.provider!),
          ],
          Gaps.xl,
          Text('Job status', style: theme.textTheme.headlineSmall),
          Gaps.md,
          AppCard(
            padding: const EdgeInsets.all(Insets.xl),
            child: _Timeline(request: request),
          ),
          Gaps.xl,
          Text('Cost summary', style: theme.textTheme.headlineSmall),
          Gaps.md,
          AppCard(
            padding: const EdgeInsets.all(Insets.xl),
            child: Column(
              children: [
                ReceiptRow(
                  label: 'Call-out fee',
                  value: request.calloutFee > 0
                      ? Fmt.cedis(request.calloutFee)
                      : 'Quoted after details',
                ),
                if (request.estimateLow != null)
                  ReceiptRow(
                    label: 'Estimated labour',
                    value:
                        '${Fmt.cedis(request.estimateLow!)} – ${Fmt.cedis(request.estimateHigh!)}',
                  ),
                if (request.finalAmount != null) ...[
                  const Divider(height: Insets.xl),
                  ReceiptRow(
                    label: 'Final amount paid',
                    value: Fmt.cedis(request.finalAmount!),
                    emphasize: true,
                  ),
                ] else ...[
                  Gaps.sm,
                  Text(
                    'The final cost is confirmed with you after diagnosis — '
                    'no surprises.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.inkFaint,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Gaps.xl,
          Text('Job details', style: theme.textTheme.headlineSmall),
          Gaps.md,
          AppCard(
            padding: const EdgeInsets.all(Insets.xl),
            child: Column(
              children: [
                ReceiptRow(label: 'Problem', value: request.description),
                ReceiptRow(label: 'Location', value: request.propertyLabel),
                ReceiptRow(
                  label: 'Requested time',
                  value:
                      '${Fmt.relativeDay(request.preferredDate)}, ${request.timeSlot}',
                ),
                ReceiptRow(label: 'Urgency', value: request.urgency.label),
              ],
            ),
          ),
          Gaps.xl,
          Text('Photos', style: theme.textTheme.headlineSmall),
          Gaps.md,
          AppCard(
            padding: const EdgeInsets.all(Insets.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PhotoStrip(
                  label: 'Before',
                  count: request.photoCount,
                  emptyHint: 'No photos attached',
                ),
                if (request.status == ServiceRequestStatus.completed) ...[
                  Gaps.lg,
                  const _PhotoStrip(
                    label: 'After',
                    count: 2,
                    emptyHint: 'Added when the job completes',
                  ),
                ],
              ],
            ),
          ),
          Gaps.xxl,
          OutlinedButton.icon(
            onPressed: () => _contactSupport(context),
            icon: const Icon(Icons.support_agent_rounded, size: 20),
            label: const Text('Contact support'),
          ),
          if (request.status.isOpen) ...[
            Gaps.md,
            OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rescheduling arrives with the live release'),
                ),
              ),
              icon: const Icon(Icons.event_repeat_rounded, size: 20),
              label: const Text('Reschedule'),
            ),
            Gaps.md,
            TextButton(
              onPressed: () => _cancel(context, ref, request),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Cancel request'),
            ),
          ],
          Gaps.xxl,
        ],
      ),
    );
  }

  void _contactSupport(BuildContext context) {
    showAppBottomSheet(
      context,
      title: 'Contact support',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const TintedIcon(Icons.call_rounded, size: 40),
            title: const Text('Call GRID support'),
            subtitle: const Text('030 700 0000 • 7am – 9pm'),
            contentPadding: EdgeInsets.zero,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Calling is a demo action')),
            ),
          ),
          ListTile(
            leading: const TintedIcon(Icons.chat_rounded, size: 40),
            title: const Text('Chat with us'),
            subtitle: const Text('Usually replies within minutes'),
            contentPadding: EdgeInsets.zero,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Chat arrives with the live release'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    ServiceRequest request,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this request?'),
        content: const Text(
          'Your professional will be stood down. You can book again '
          'any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep request'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Cancel request'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      ref.read(serviceRequestsProvider.notifier).cancel(request.id);
    }
  }
}

// ---------------------------------------------------------------------------

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider});

  final ServiceProviderSummary provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(Insets.lg),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.mint,
            child: Text(
              provider.initials,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.forestDeep,
              ),
            ),
          ),
          Gaps.md,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provider.name, style: theme.textTheme.titleMedium),
                Text(
                  '${provider.role} • ${provider.yearsExperience}+ years',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${provider.rating} (${provider.reviews} reviews)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('In-app calls arrive with the live release'),
              ),
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.tealSoft,
              foregroundColor: AppColors.teal,
            ),
            tooltip: 'Call ${provider.name}',
            icon: const Icon(Icons.call_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final events = request.timeline;
    final cancelled = request.status == ServiceRequestStatus.cancelled;
    final upcoming = _upcomingSteps();

    return Column(
      children: [
        for (var i = 0; i < events.length; i++)
          _TimelineRow(
            icon: cancelled && i == events.length - 1
                ? Icons.close_rounded
                : Icons.check_rounded,
            iconColor: cancelled && i == events.length - 1
                ? AppColors.danger
                : AppColors.success,
            iconBg: cancelled && i == events.length - 1
                ? AppColors.dangerSoft
                : AppColors.successSoft,
            title: events[i].title,
            subtitle: events[i].subtitle,
            time: Fmt.dateTime(events[i].time),
            showLine: i < events.length - 1 + upcoming.length,
            active: true,
          ),
        for (var i = 0; i < upcoming.length; i++)
          _TimelineRow(
            icon: Icons.circle_outlined,
            iconColor: AppColors.inkFaint,
            iconBg: AppColors.surfaceDim,
            title: upcoming[i],
            subtitle: null,
            time: null,
            showLine: i < upcoming.length - 1,
            active: false,
          ),
      ],
    );
  }

  List<String> _upcomingSteps() => switch (request.status) {
    ServiceRequestStatus.pending => [
      'Technician assigned',
      'Work starts',
      'Job completed',
    ],
    ServiceRequestStatus.assigned => ['Work starts', 'Job completed'],
    ServiceRequestStatus.inProgress => ['Job completed'],
    _ => const [],
  };
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.showLine,
    required this.active,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final String? time;
  final bool showLine;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              if (showLine)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: AppColors.divider,
                  ),
                ),
            ],
          ),
          Gaps.md,
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showLine ? Insets.lg : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: active ? AppColors.ink : AppColors.inkFaint,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                  if (time != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      time!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({
    required this.label,
    required this.count,
    required this.emptyHint,
  });

  final String label;
  final int count;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.inkFaint,
          ),
        ),
        Gaps.sm,
        if (count == 0)
          Text(
            emptyHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.inkFaint,
            ),
          )
        else
          Row(
            children: [
              for (var i = 0; i < count; i++) ...[
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.tealSoft,
                    borderRadius: Corners.mdRadius,
                  ),
                  child: const Icon(Icons.image_rounded, color: AppColors.teal),
                ),
                Gaps.sm,
              ],
            ],
          ),
      ],
    );
  }
}
