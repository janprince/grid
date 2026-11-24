import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/data/api/api_exception.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/support.dart';
import '../../core/widgets/widgets.dart';
import 'booking_flow_screen.dart';

/// One booking: where it stands, who is coming, what it cost, and the one
/// thing to do next. Re-read from GRID every few seconds while it is moving.
class RequestDetailsScreen extends ConsumerStatefulWidget {
  const RequestDetailsScreen({super.key, required this.requestId});
  final String requestId;

  @override
  ConsumerState<RequestDetailsScreen> createState() =>
      _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends ConsumerState<RequestDetailsScreen> {
  Timer? _poll;
  bool _busy = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _refresh();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) {
      final current = ref.read(serviceRequestByIdProvider(widget.requestId));
      if (current == null ||
          current.status.isOpen ||
          current.awaitingConfirmation) {
        _refresh();
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final request = await ref
          .read(servicesApiProvider)
          .request(widget.requestId);
      if (!mounted) return;
      ref.read(serviceRequestsProvider.notifier).put(request);
      setState(() => _loadError = null);
    } on ApiException catch (error) {
      if (mounted) setState(() => _loadError = error.message);
    }
  }

  Future<void> _act(
    Future<ServiceRequest> Function() action, {
    String? done,
  }) async {
    setState(() => _busy = true);
    try {
      final request = await action();
      ref.read(serviceRequestsProvider.notifier).put(request);
      if (done != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(done)));
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _call(String phone) async {
    final number = phone.startsWith('+') ? phone : '+$phone';
    try {
      if (await launchUrl(Uri(scheme: 'tel', path: number))) return;
    } on Object {
      // Falls through to the message.
    }
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Call ${Fmt.ghanaPhone(phone)}')));
    }
  }

  Future<void> _cancel(ServiceRequest request) async {
    final yes = await showConfirmationSheet(
      context,
      title: 'Cancel this booking?',
      message: request.payment?.status == ServicePaymentStatus.paid
          ? 'You\'ll get ${Fmt.cedis(request.total)} back on MoMo, usually within a day.'
          : 'Nothing has been charged.',
      confirmLabel: 'Cancel booking',
      cancelLabel: 'Keep it',
    );
    if (yes) {
      await _act(
        () => ref.read(servicesApiProvider).cancel(request.id),
        done: 'Booking cancelled.',
      );
    }
  }

  Future<void> _rate(ServiceRequest request) async {
    final result = await showModalBottomSheet<(int, String?)>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _RatingSheet(name: request.provider?.name ?? 'your professional'),
    );
    if (result != null) {
      await _act(
        () => ref
            .read(servicesApiProvider)
            .review(request.id, rating: result.$1, comment: result.$2),
        done: 'Thanks for rating.',
      );
    }
  }

  void _bookAgain(ServiceRequest request) {
    final service = ref
        .read(catalogueProvider)
        .value
        ?.bySlug(request.serviceSlug);
    if (service == null) return;
    final lines = [
      for (final line in request.lines)
        if (service.package(line.packageId) case final package?)
          BookingLine(package, line.quantity),
    ];
    if (lines.isEmpty) {
      context.push(Routes.service(service.slug));
      return;
    }
    context.push(
      Routes.bookService(service.slug),
      extra: BookingArgs(
        lines: lines,
        preferredProviderId: request.provider?.id,
        preferredProviderName: request.provider?.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(serviceRequestByIdProvider(widget.requestId));
    if (request == null) {
      return Scaffold(
        appBar: AppHeader(title: 'Booking', onBack: () => context.pop()),
        body: _loadError == null
            ? const Padding(
                padding: EdgeInsets.all(Insets.xl),
                child: SkeletonCard(height: 220),
              )
            : ErrorView(
                title: 'Couldn\'t load this booking',
                message: _loadError!,
                onRetry: _refresh,
              ),
      );
    }

    final actions = <Widget>[
      if (request.awaitingConfirmation)
        PrimaryButton(
          label: 'Confirm it\'s done',
          busy: _busy,
          onPressed: () => _act(
            () => ref.read(servicesApiProvider).confirmCompletion(request.id),
            done:
                'Thanks. ${request.provider?.name ?? 'Your professional'} has been paid.',
          ),
        )
      else if (request.status == ServiceRequestStatus.completed &&
          request.review == null)
        PrimaryButton(
          label: 'Rate ${request.provider?.name ?? 'the job'}',
          onPressed: () => _rate(request),
        )
      else if (request.status == ServiceRequestStatus.paymentFailed)
        PrimaryButton(
          label: 'Pay again',
          busy: _busy,
          onPressed: () =>
              _act(() => ref.read(servicesApiProvider).pay(request.id)),
        )
      else if (request.status == ServiceRequestStatus.completed ||
          request.status == ServiceRequestStatus.cancelled ||
          request.status == ServiceRequestStatus.unfilled)
        PrimaryButton(
          label: 'Book again',
          onPressed: () => _bookAgain(request),
        ),
    ];

    return Scaffold(
      appBar: AppHeader(
        title: request.reference,
        onBack: () => context.pop(),
        trailing: NavChip(
          icon: Icons.support_agent_rounded,
          tooltip: 'Call GRID support',
          onPressed: () => _call(supportPhone),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Insets.xl,
            Insets.lg,
            Insets.xl,
            Insets.xxxl,
          ),
          children: [
            Row(
              children: [
                ServiceBadge(slug: request.serviceSlug, size: 56),
                Gaps.md,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.serviceName.toUpperCase(),
                        style: AppText.overline,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.title,
                        style: AppText.title.copyWith(fontSize: 19),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Gaps.xl,
            _StatusPanel(request: request),
            if (request.provider case final provider?) ...[
              Gaps.lg,
              _ProviderCard(
                provider: provider,
                onCall: request.status.isOpen
                    ? () => _call(provider.phone)
                    : null,
              ),
            ],
            if (request.jobStage != null &&
                request.status != ServiceRequestStatus.cancelled) ...[
              Gaps.xl,
              _Progress(request: request),
            ],
            Gaps.xl,
            _Schedule(request: request),
            Gaps.lg,
            DetailGroup(
              rows: [
                for (final line in request.lines)
                  DetailRow(
                    label: line.quantity > 1
                        ? '${line.quantity} × ${line.name}'
                        : line.name,
                    value: Fmt.cedis(line.total),
                  ),
                DetailRow(
                  label: 'Total',
                  value: Fmt.cedis(request.total),
                  emphasis: true,
                ),
                if (request.payment case final payment?)
                  DetailRow(
                    label: 'Payment',
                    // GRID holds it until the job is confirmed, then pays
                    // the professional.
                    value:
                        payment.status == ServicePaymentStatus.paid &&
                            request.status != ServiceRequestStatus.completed
                        ? 'Paid · held by GRID'
                        : payment.label,
                  ),
              ],
            ),
            if (request.notes case final notes? when notes.isNotEmpty) ...[
              Gaps.lg,
              DetailGroup(
                rows: [
                  DetailRow(label: 'Your note', value: notes, stacked: true),
                ],
              ),
            ],
            if (request.review case final review?) ...[
              Gaps.lg,
              DetailGroup(
                rows: [
                  DetailRow(
                    label: 'Your rating',
                    value: '${'★' * review.rating}${'☆' * (5 - review.rating)}',
                  ),
                  if (review.comment case final comment?
                      when comment.isNotEmpty)
                    DetailRow(label: 'Comment', value: comment, stacked: true),
                ],
              ),
            ],
            if (actions.isNotEmpty) ...[Gaps.xl, ...actions],
            if (request.canCancel) ...[
              Gaps.sm,
              Center(
                child: TextLink(
                  label: 'Cancel booking',
                  color: AppColors.danger,
                  onPressed: _busy ? null : () => _cancel(request),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.request});
  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final (tone, message) = switch (request.status) {
      ServiceRequestStatus.awaitingPayment => (
        BadgeTone.warning,
        'Check your phone for the MoMo prompt for ${Fmt.cedis(request.total)}.',
      ),
      ServiceRequestStatus.paymentFailed => (
        BadgeTone.danger,
        'Nothing was taken. Pay again to keep this booking.',
      ),
      ServiceRequestStatus.searching => (
        BadgeTone.info,
        'We\'re offering your job to the nearest vetted professionals. Usually a few minutes.',
      ),
      ServiceRequestStatus.assigned => (
        BadgeTone.success,
        '${request.provider?.name ?? 'Your professional'} will arrive ${Fmt.relativeDay(request.scheduledAt).toLowerCase()} at ${Fmt.time(request.scheduledAt)}.',
      ),
      ServiceRequestStatus.inProgress => (
        request.awaitingConfirmation ? BadgeTone.warning : BadgeTone.info,
        request.awaitingConfirmation
            ? 'Confirm the job is done to release payment. If something isn\'t right, call us first.'
            : 'We\'ll keep this page up to date.',
      ),
      ServiceRequestStatus.completed => (
        BadgeTone.success,
        'Thanks for booking with GRID.',
      ),
      ServiceRequestStatus.cancelled => (
        BadgeTone.neutral,
        request.payment?.status == ServicePaymentStatus.refunded
            ? 'Your money has been refunded.'
            : 'This booking was cancelled.',
      ),
      ServiceRequestStatus.unfilled => (
        BadgeTone.neutral,
        'No professional could take it this time. Your payment is being refunded in full.',
      ),
    };
    return StatusBanner(tone: tone, title: request.headline, message: message);
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider, this.onCall});
  final AssignedProvider provider;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Insets.lg),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      borderRadius: Corners.lgRadius,
      boxShadow: AppColors.raisedShadow,
    ),
    child: Row(
      children: [
        InitialsAvatar(initials: provider.initials, size: 52),
        Gaps.md,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.name,
                style: AppText.subtitle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                [
                  if (provider.rating case final r?)
                    '★ ${r.toStringAsFixed(1)} (${provider.reviews})'
                  else
                    'New on GRID',
                  '${provider.completedJobs} job${provider.completedJobs == 1 ? '' : 's'} done',
                ].join(' · '),
                style: AppText.caption,
              ),
            ],
          ),
        ),
        if (onCall != null)
          IconButton.filledTonal(
            onPressed: onCall,
            tooltip: 'Call ${provider.name}',
            icon: const Icon(Icons.call_outlined),
          ),
      ],
    ),
  );
}

/// The job's steps, ticked as GRID reports them.
class _Progress extends StatelessWidget {
  const _Progress({required this.request});
  final ServiceRequest request;

  static const _visit = [
    ('accepted', 'Booked'),
    ('onTheWay', 'On the way'),
    ('arrived', 'Arrived'),
    ('inProgress', 'Working'),
    ('awaitingConfirmation', 'Finished — confirm'),
    ('completed', 'Done'),
  ];

  static const _laundry = [
    ('accepted', 'Booked'),
    ('pickedUp', 'Collected'),
    ('processing', 'Washing'),
    ('readyForDelivery', 'Ready'),
    ('outForDelivery', 'On its way back'),
    ('awaitingConfirmation', 'Delivered — confirm'),
    ('completed', 'Done'),
  ];

  @override
  Widget build(BuildContext context) {
    final steps = request.serviceSlug == 'laundry' ? _laundry : _visit;
    final current = steps.indexWhere((s) => s.$1 == request.jobStage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= current ? AppColors.navy : AppColors.surface,
                      border: Border.all(
                        color: i <= current
                            ? AppColors.navy
                            : AppColors.lineStrong,
                        width: 2,
                      ),
                    ),
                    child:
                        i < current ||
                            (i == current &&
                                request.status ==
                                    ServiceRequestStatus.completed)
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  if (i != steps.length - 1)
                    Container(
                      width: 2,
                      height: 22,
                      color: i < current ? AppColors.navy : AppColors.line,
                    ),
                ],
              ),
              Gaps.md,
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  steps[i].$2,
                  style: AppText.body.copyWith(
                    fontSize: 14.5,
                    fontWeight: i == current
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: i <= current ? AppColors.ink : AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// When and where, side by side like a check-in card.
class _Schedule extends StatelessWidget {
  const _Schedule({required this.request});
  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, String value, String sub) => Expanded(
      child: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppText.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(value, style: AppText.body.copyWith(fontSize: 14.5)),
            Text(
              sub,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption,
            ),
          ],
        ),
      ),
    );
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: Corners.lgRadius,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            cell(
              request.serviceSlug == 'laundry' ? 'Collection' : 'Arrival',
              Fmt.relativeDay(request.scheduledAt),
              Fmt.time(request.scheduledAt),
            ),
            const VerticalDivider(width: 1, indent: 14, endIndent: 14),
            cell('Where', request.area, request.address),
          ],
        ),
      ),
    );
  }
}

class _RatingSheet extends StatefulWidget {
  const _RatingSheet({required this.name});
  final String name;

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _rating = 0;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      Insets.xl,
      0,
      Insets.xl,
      MediaQuery.viewInsetsOf(context).bottom + Insets.xl,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('How did ${widget.name} do?', style: AppText.title),
        Gaps.lg,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                iconSize: 38,
                tooltip: '$i star${i == 1 ? '' : 's'}',
                onPressed: () => setState(() => _rating = i),
                icon: Icon(
                  i <= _rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: i <= _rating ? AppColors.amber : AppColors.lineStrong,
                ),
              ),
          ],
        ),
        Gaps.md,
        TextField(
          controller: _comment,
          maxLines: 3,
          maxLength: 1000,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Anything to add? Optional.',
          ),
        ),
        Gaps.md,
        PrimaryButton(
          label: 'Send rating',
          onPressed: _rating == 0
              ? null
              : () => Navigator.pop(context, (
                  _rating,
                  _comment.text.trim().isEmpty ? null : _comment.text.trim(),
                )),
        ),
      ],
    ),
  );
}
