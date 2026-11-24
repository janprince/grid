import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/service_art.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import 'booking_flow_screen.dart';

/// One service: what it is, the packages at GRID's prices, what's included,
/// and how a booking works. Choosing packages builds the booking; the
/// floating bar carries the total to the booking flow.
class ServiceScreen extends ConsumerStatefulWidget {
  const ServiceScreen({super.key, required this.slug});
  final String slug;

  @override
  ConsumerState<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends ConsumerState<ServiceScreen> {
  /// Package id → quantity.
  final _chosen = <String, int>{};

  List<BookingLine> _lines(ServiceItem service) => [
    for (final package in service.packages)
      if ((_chosen[package.id] ?? 0) > 0)
        BookingLine(package, _chosen[package.id]!),
  ];

  void _set(ServiceItem service, ServicePackage package, int quantity) {
    setState(() {
      if (!package.countable && quantity > 0) {
        // Sizes of one job replace each other.
        for (final other in service.packages) {
          if (other.group == package.group) _chosen.remove(other.id);
        }
      }
      if (quantity <= 0) {
        _chosen.remove(package.id);
      } else {
        _chosen[package.id] = quantity;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = ref.watch(catalogueProvider);
    final service = catalogue.value?.bySlug(widget.slug);

    if (service == null) {
      return Scaffold(
        appBar: AppHeader(onBack: () => Navigator.of(context).maybePop()),
        body: catalogue.isLoading
            ? const Padding(
                padding: EdgeInsets.all(Insets.xl),
                child: SkeletonCard(height: 260),
              )
            : ErrorView(
                title: catalogue.hasError
                    ? 'Couldn\'t load this service'
                    : 'This service isn\'t offered',
                message: catalogue.hasError
                    ? 'Check your connection and try again.'
                    : 'It may have been paused. See what else GRID offers.',
                onRetry: () => ref.invalidate(catalogueProvider),
              ),
      );
    }

    final lines = _lines(service);
    final total = lines.fold<double>(0, (sum, line) => sum + line.total);
    final look = ServiceLook.of(service.slug);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Hero(service: service, look: look),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.xl,
                  Insets.xl,
                  Insets.xl,
                  140,
                ),
                sliver: SliverList.list(
                  children: [
                    Text(service.name, style: AppText.headline),
                    Gaps.sm,
                    Text(service.description, style: AppText.bodyMuted),
                    Gaps.lg,
                    _Promises(service: service),
                    if (service.quoted) ...[
                      Gaps.xl,
                      const StatusBanner(
                        tone: BadgeTone.info,
                        title: 'You approve the price before any work',
                        message:
                            'The professional finds the problem and sends a '
                            'quote in the app. Say no and you only pay the '
                            'call-out.',
                      ),
                    ],
                    const SizedBox(height: 28),
                    Text(
                      'Choose what you need',
                      style: AppText.title.copyWith(fontSize: 20),
                    ),
                    Gaps.lg,
                    for (final (group, options) in service.groups) ...[
                      _GroupCard(
                        serviceSlug: service.slug,
                        group: group,
                        options: options,
                        chosen: _chosen,
                        onChanged: (package, quantity) =>
                            _set(service, package, quantity),
                      ),
                      Gaps.lg,
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'How it works',
                      style: AppText.title.copyWith(fontSize: 20),
                    ),
                    Gaps.lg,
                    _HowItWorks(service: service),
                    const SizedBox(height: 28),
                    Text(
                      'Questions',
                      style: AppText.title.copyWith(fontSize: 20),
                    ),
                    Gaps.sm,
                    ..._faqs(
                      service,
                    ).map((qa) => _Faq(question: qa.$1, answer: qa.$2)),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Insets.md),
                child: NavChip(
                  onPressed: () => Navigator.of(context).maybePop(),
                  color: AppColors.surface,
                ),
              ),
            ),
          ),
          Positioned(
            left: Insets.lg,
            right: Insets.lg,
            bottom: 0,
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: Insets.lg),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: lines.isEmpty
                    ? const SizedBox.shrink()
                    : FloatingActionBar(
                        key: const ValueKey('bar'),
                        title: Fmt.cedis(total),
                        caption: lines.length == 1
                            ? (lines.first.quantity > 1
                                  ? '${lines.first.quantity} × ${lines.first.package.label}'
                                  : lines.first.package.label)
                            : '${lines.length} items',
                        label: 'Continue',
                        onPressed: () => context.push(
                          Routes.bookService(service.slug),
                          extra: BookingArgs(lines: lines),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<(String, String)> _faqs(ServiceItem service) => [
    (
      'Who will come?',
      'A professional GRID has checked: Ghana Card, references and a '
          'skills check${service.slug == 'pest-control' ? ', plus an EPA pest control licence' : ''}. '
          'You see their name, rating and number as soon as they accept.',
    ),
    (
      'When do I pay?',
      'When you book, by MoMo. GRID holds the money and only pays the '
          'professional after you confirm the job is done.',
    ),
    (
      'Can I cancel?',
      'Yes, free of charge until your professional sets off. If no one is '
          'available, you\'re refunded in full automatically.',
    ),
    (
      'What if I\'m not happy?',
      'Tell us from the booking within 24 hours and we\'ll send someone '
          'to put it right, or refund you.',
    ),
  ];
}

class _Hero extends StatelessWidget {
  const _Hero({required this.service, required this.look});
  final ServiceItem service;
  final ServiceLook look;

  @override
  Widget build(BuildContext context) => Container(
    color: look.tint,
    child: SafeArea(
      bottom: false,
      child: SizedBox(
        height: 220,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(60, 12, 60, 8),
          child: ServiceArt(
            slug: service.slug,
            tint: Colors.transparent,
            inset: 0.04,
          ),
        ),
      ),
    ),
  );
}

class _Promises extends StatelessWidget {
  const _Promises({required this.service});
  final ServiceItem service;

  @override
  Widget build(BuildContext context) {
    final promises = [
      (Icons.verified_user_outlined, 'Vetted pros'),
      (Icons.sell_outlined, service.quoted ? 'Quote first' : 'Fixed price'),
      (Icons.shield_outlined, 'Refund if unfilled'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (icon, label) in promises)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: Corners.pill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: AppColors.navy),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppText.caption.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One kind of job: either sizes to choose between, or one item to add in a
/// quantity. Shows what the price covers on request.
class _GroupCard extends StatefulWidget {
  const _GroupCard({
    required this.serviceSlug,
    required this.group,
    required this.options,
    required this.chosen,
    required this.onChanged,
  });

  final String serviceSlug;
  final String group;
  final List<ServicePackage> options;
  final Map<String, int> chosen;
  final void Function(ServicePackage package, int quantity) onChanged;

  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard> {
  bool _details = false;

  @override
  Widget build(BuildContext context) {
    final first = widget.options.first;
    final sized = widget.options.length > 1;
    final selected = widget.options.any((p) => (widget.chosen[p.id] ?? 0) > 0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Corners.lgRadius,
        border: Border.all(
          color: selected ? AppColors.navy : AppColors.line,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: 68,
                child: ServiceArt(
                  slug: widget.serviceSlug,
                  packageSlug: first.slug,
                  radius: Corners.md,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.group,
                      style: AppText.subtitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (first.summary != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        first.summary!,
                        style: AppText.caption.copyWith(fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      sized
                          ? 'From ${Fmt.cedisShort(widget.options.map((p) => p.price).reduce((a, b) => a < b ? a : b))}'
                          : [
                              Fmt.cedisShort(first.price),
                              ?first.perUnit,
                              if (first.durationLabel.isNotEmpty)
                                first.durationLabel,
                            ].join(' · '),
                      style: AppText.caption.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                        fontFeatures: AppText.tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
              if (!sized) ...[
                const SizedBox(width: 8),
                QuantityStepper(
                  value: widget.chosen[first.id] ?? 0,
                  max: first.maxQuantity,
                  label: first.unitLabel ?? 'item',
                  onChanged: (q) => widget.onChanged(first, q),
                ),
              ],
            ],
          ),
          if (sized) ...[
            Gaps.md,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in widget.options)
                  _SizeChip(
                    package: option,
                    selected: (widget.chosen[option.id] ?? 0) > 0,
                    onTap: () => widget.onChanged(
                      option,
                      (widget.chosen[option.id] ?? 0) > 0 ? 0 : 1,
                    ),
                  ),
              ],
            ),
          ],
          if (first.includes.isNotEmpty || first.excludes.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextLink(
                label: _details ? 'Hide details' : 'What\'s included',
                onPressed: () => setState(() => _details = !_details),
              ),
            ),
            if (_details) _Included(package: first),
          ],
        ],
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({
    required this.package,
    required this.selected,
    required this.onTap,
  });
  final ServicePackage package;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '${package.name}, ${Fmt.cedis(package.price)}',
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: Corners.mdRadius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.surfaceSubtle,
          borderRadius: Corners.mdRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              package.name,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
            Text(
              Fmt.cedisShort(package.price),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFeatures: AppText.tabularFigures,
                color: selected ? AppColors.amber : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Included extends StatelessWidget {
  const _Included({required this.package});
  final ServicePackage package;

  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, Color color, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppText.body.copyWith(fontSize: 14)),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: Corners.mdRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in package.includes)
            row(Icons.check_rounded, AppColors.success, item),
          if (package.excludes.isNotEmpty) ...[
            if (package.includes.isNotEmpty) const SizedBox(height: 6),
            Text(
              'Not included',
              style: AppText.caption.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            for (final item in package.excludes)
              row(Icons.close_rounded, AppColors.faint, item),
          ],
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks({required this.service});
  final ServiceItem service;

  @override
  Widget build(BuildContext context) {
    final steps = [
      (
        'Book and pay',
        'Pick a time. Approve the MoMo prompt; GRID holds the money.',
      ),
      (
        'We match a professional',
        'The nearest vetted ${service.collected ? 'laundry' : 'professional'} who works then accepts. You see who\'s coming.',
      ),
      (
        service.collected ? 'Collected and returned' : 'The job gets done',
        service.collected
            ? 'Your laundry is picked up and brought back. Follow each step in the app.'
            : 'Follow each step in the app, then confirm it\'s done. Only then is the professional paid.',
      ),
    ];
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.navySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: AppText.subtitle.copyWith(color: AppColors.navy),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(steps[i].$1, style: AppText.subtitle),
                      const SizedBox(height: 2),
                      Text(
                        steps[i].$2,
                        style: AppText.caption.copyWith(fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Faq extends StatelessWidget {
  const _Faq({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      expandedAlignment: Alignment.centerLeft,
      title: Text(question, style: AppText.subtitle),
      children: [Text(answer, style: AppText.bodyMuted)],
    ),
  );
}
