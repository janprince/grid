import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/api/api_exception.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';

/// What the service page hands the booking flow.
class BookingArgs {
  const BookingArgs({
    required this.lines,
    this.preferredProviderId,
    this.preferredProviderName,
  });

  final List<BookingLine> lines;

  /// "Book again": offered to this professional first.
  final String? preferredProviderId;
  final String? preferredProviderName;
}

enum _Phase { steps, submitting, approving, failed }

/// Book what was chosen on the service page: where → when → anything to
/// know → review and pay by MoMo. Payment is approved on the phone; the
/// booking opens once it lands.
class BookingFlowScreen extends ConsumerStatefulWidget {
  const BookingFlowScreen({super.key, required this.slug, this.args});

  final String slug;
  final BookingArgs? args;

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  static const _stepCount = 4;
  static const _days = 14;

  _Phase _phase = _Phase.steps;
  int _step = 0;

  String? _propertyId;
  ServiceAvailability? _availability;
  bool _checking = false;
  String? _availabilityError;

  late DateTime _day = _today();
  DateTime? _slot;

  final _notes = TextEditingController();
  final _key = _newKey();
  ServiceRequest? _request;
  String? _error;
  Timer? _poll;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static String _newKey() {
    final random = Random.secure();
    return List.generate(
      24,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
  }

  List<BookingLine> get _lines => widget.args?.lines ?? const [];
  double get _total => _lines.fold(0, (sum, line) => sum + line.total);

  @override
  void initState() {
    super.initState();
    _propertyId = ref.read(selectedPropertyProvider)?.id;
    if (_propertyId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _notes.dispose();
    super.dispose();
  }

  ServiceItem? get _service =>
      ref.read(catalogueProvider).value?.bySlug(widget.slug);

  Future<void> _check() async {
    final service = _service;
    final propertyId = _propertyId;
    if (service == null || propertyId == null) return;
    setState(() {
      _checking = true;
      _availabilityError = null;
      _slot = null;
    });
    try {
      final result = await ref
          .read(servicesApiProvider)
          .availability(
            serviceId: service.id,
            propertyId: propertyId,
            date: _day,
          );
      if (!mounted) return;
      setState(() => _availability = result);
    } on ApiException catch (error) {
      if (mounted) setState(() => _availabilityError = error.message);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  bool get _canContinue => switch (_step) {
    0 => _propertyId != null && (_availability?.served ?? false) && !_checking,
    1 => _slot != null,
    _ => true,
  };

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      context.pop();
    }
  }

  void _continue() {
    if (_step < _stepCount - 1) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    setState(() {
      _phase = _Phase.submitting;
      _error = null;
    });
    try {
      final request = await ref
          .read(servicesApiProvider)
          .book(
            lines: _lines,
            propertyId: _propertyId!,
            scheduledAt: _slot!,
            idempotencyKey: _key,
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            preferredProviderId: widget.args?.preferredProviderId,
          );
      ref.read(serviceRequestsProvider.notifier).put(request);
      _settle(request);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.steps;
        _error = error.message;
      });
    }
  }

  /// Moves on once the payment has an answer; polls while it doesn't.
  void _settle(ServiceRequest request) {
    if (!mounted) return;
    _request = request;
    switch (request.status) {
      case ServiceRequestStatus.awaitingPayment:
        setState(() => _phase = _Phase.approving);
        _poll ??= Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
      case ServiceRequestStatus.paymentFailed:
        _poll?.cancel();
        setState(() => _phase = _Phase.failed);
      default:
        _poll?.cancel();
        context.pushReplacement(Routes.serviceRequest(request.id));
    }
  }

  Future<void> _refresh() async {
    final id = _request?.id;
    if (id == null) return;
    try {
      final request = await ref.read(servicesApiProvider).request(id);
      ref.read(serviceRequestsProvider.notifier).put(request);
      _settle(request);
    } on Object {
      // A dropped connection: the next tick tries again.
    }
  }

  Future<void> _payAgain() async {
    final id = _request?.id;
    if (id == null) return;
    setState(() => _phase = _Phase.submitting);
    try {
      _settle(await ref.read(servicesApiProvider).pay(id));
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _phase = _Phase.failed;
          _error = error.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(catalogueProvider).value?.bySlug(widget.slug);
    if (service == null || _lines.isEmpty) {
      return Scaffold(
        appBar: AppHeader(title: 'Book', onBack: () => context.pop()),
        body: const ErrorView(
          title: 'Nothing chosen yet',
          message: 'Go back and choose what you\'d like done.',
        ),
      );
    }

    switch (_phase) {
      case _Phase.submitting:
        return const _Waiting(
          title: 'Booking…',
          message: 'Sending your MoMo prompt.',
        );
      case _Phase.approving:
        final phone = ref.read(sessionProvider).user?.phone ?? '';
        return _Waiting(
          title: 'Approve on your phone',
          message:
              'Check ${Fmt.ghanaPhone(phone)} for a MoMo prompt for '
              '${Fmt.cedis(_total)} and enter your PIN. GRID holds the money '
              'until your job is done.',
          footer: [
            TextButton(
              onPressed: _refresh,
              child: const Text('I\'ve approved it'),
            ),
            TextButton(
              onPressed: () =>
                  context.pushReplacement(Routes.serviceRequest(_request!.id)),
              child: const Text('View booking'),
            ),
          ],
        );
      case _Phase.failed:
        return Scaffold(
          appBar: AppHeader(title: 'Payment', onBack: () => context.pop()),
          body: Padding(
            padding: const EdgeInsets.all(Insets.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatusBanner(
                  tone: BadgeTone.danger,
                  title: 'The payment didn\'t go through',
                  message:
                      _error ??
                      'The prompt was declined or timed out. Nothing was '
                          'taken. Your booking is saved; try again.',
                ),
                const Spacer(),
                PrimaryButton(label: 'Try again', onPressed: _payAgain),
                Gaps.md,
                SecondaryButton(
                  label: 'View booking',
                  onPressed: () => context.pushReplacement(
                    Routes.serviceRequest(_request!.id),
                  ),
                ),
              ],
            ),
          ),
        );
      case _Phase.steps:
        break;
    }

    return StepFlowScaffold(
      title: service.name,
      step: _step,
      stepCount: _stepCount,
      onBack: _back,
      totalLabel: 'Total',
      totalValue: Fmt.cedis(_total),
      bottomBar: PrimaryButton(
        label: _step == _stepCount - 1
            ? 'Pay ${Fmt.cedisShort(_total)}'
            : 'Continue',
        onPressed: _canContinue ? _continue : null,
      ),
      child: StepTransition(
        stepKey: _step,
        child: ListView(
          key: ValueKey(_step),
          padding: const EdgeInsets.fromLTRB(
            Insets.xl,
            Insets.xl,
            Insets.xl,
            Insets.xxxl,
          ),
          children: switch (_step) {
            0 => _where(service),
            1 => _when(service),
            2 => _details(service),
            _ => _review(service),
          },
        ),
      ),
    );
  }

  // Step 1 — where ---------------------------------------------------------------

  List<Widget> _where(ServiceItem service) {
    final homes = ref.watch(propertiesProvider);
    return [
      ScreenIntro(
        title: service.collected
            ? 'Where do we collect from?'
            : 'Where is the job?',
        subtitle: 'GRID matches you with a professional near this home.',
      ),
      Gaps.xl,
      if (homes.isEmpty)
        EmptyState(
          icon: Icons.other_houses_rounded,
          title: 'Add a home first',
          message: 'Save the address so the professional can find you.',
          actionLabel: 'Add a home',
          onAction: () => context.push(Routes.addProperty),
          compact: true,
        )
      else ...[
        for (final home in homes) ...[
          SelectionTile(
            selected: home.id == _propertyId,
            onTap: () {
              setState(() {
                _propertyId = home.id;
                _availability = null;
              });
              _check();
            },
            title: home.nickname,
            subtitle: '${home.address}, ${home.location}',
            leading: const Icon(Icons.home_outlined, color: AppColors.navy),
          ),
          Gaps.md,
        ],
        TextLink(
          label: 'Add another home',
          onPressed: () => context.push(Routes.addProperty),
        ),
      ],
      Gaps.lg,
      if (_checking)
        const SkeletonCard(height: 64)
      else if (_availabilityError != null)
        StatusBanner(
          tone: BadgeTone.danger,
          title: 'Couldn\'t check this address',
          message: _availabilityError,
        )
      else if (_availability case final a?)
        a.served
            ? StatusBanner(
                tone: BadgeTone.success,
                title: 'GRID serves ${a.area}',
                message: a.providersNearby > 0
                    ? '${a.providersNearby} professional${a.providersNearby == 1 ? '' : 's'} nearby today.'
                    : 'Pick a day on the next step to see who\'s free.',
              )
            : const StatusBanner(
                tone: BadgeTone.warning,
                title: 'Not in this area yet',
                message:
                    'GRID doesn\'t serve this address yet. We\'re adding areas '
                    'every month; try another home.',
              ),
    ];
  }

  // Step 2 — when ----------------------------------------------------------------

  List<Widget> _when(ServiceItem service) {
    final slots = _availability?.slots ?? const <ServiceSlot>[];
    final open = slots.where((s) => s.available).toList();
    return [
      ScreenIntro(
        title: service.collected
            ? 'When should we collect?'
            : 'When should they arrive?',
        subtitle: 'Times are when the professional arrives.',
      ),
      Gaps.xl,
      SizedBox(
        height: 74,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _days,
          separatorBuilder: (_, _) => Gaps.sm,
          itemBuilder: (context, i) {
            final day = _today().add(Duration(days: i));
            final selected = day == _day;
            return _DayChip(
              day: day,
              selected: selected,
              onTap: () {
                setState(() => _day = day);
                _check();
              },
            );
          },
        ),
      ),
      Gaps.xl,
      if (_checking)
        const SkeletonCard(height: 160)
      else if (slots.isEmpty || open.isEmpty)
        EmptyState(
          icon: Icons.event_busy_outlined,
          title: 'No times left this day',
          message:
              'Try another day — most professionals work Monday to Saturday.',
          compact: true,
        )
      else
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: [
            for (final slot in slots)
              _SlotChip(
                slot: slot,
                selected: _slot == slot.startsAt,
                onTap: slot.available
                    ? () => setState(() => _slot = slot.startsAt)
                    : null,
              ),
          ],
        ),
    ];
  }

  // Step 3 — details -------------------------------------------------------------

  List<Widget> _details(ServiceItem service) => [
    const ScreenIntro(
      title: 'Anything they should know?',
      subtitle: 'Gate codes, parking, pets, rooms to focus on. Optional.',
    ),
    Gaps.xl,
    TextField(
      controller: _notes,
      maxLines: 5,
      maxLength: 1000,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: service.collected
            ? 'e.g. Shirts on hangers. Collect from the gate.'
            : 'e.g. Gate code 2468. Park at the back.',
      ),
    ),
    if (widget.args?.preferredProviderName case final name?) ...[
      Gaps.lg,
      StatusBanner(
        tone: BadgeTone.info,
        title: '$name gets this first',
        message:
            'If they can\'t make it, GRID offers it to the next nearest professional.',
      ),
    ],
  ];

  // Step 4 — review and pay ------------------------------------------------------

  List<Widget> _review(ServiceItem service) {
    final home = ref.watch(propertyByIdProvider(_propertyId));
    final phone = ref.read(sessionProvider).user?.phone ?? '';
    return [
      const ScreenIntro(title: 'Review and pay'),
      Gaps.xl,
      Container(
        padding: const EdgeInsets.all(Insets.lg),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: Corners.lgRadius,
          boxShadow: AppColors.raisedShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ServiceBadge(slug: service.slug, size: 48),
                Gaps.md,
                Expanded(
                  child: Text(
                    service.name,
                    style: AppText.subtitle.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            Gaps.lg,
            for (final line in _lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        line.quantity > 1
                            ? '${line.quantity} × ${line.package.label}'
                            : line.package.label,
                        style: AppText.body.copyWith(fontSize: 14.5),
                      ),
                    ),
                    Text(
                      Fmt.cedis(line.total),
                      style: AppText.body.copyWith(
                        fontSize: 14.5,
                        fontFeatures: AppText.tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 20),
            Row(
              children: [
                const Expanded(child: Text('Total', style: AppText.subtitle)),
                Text(
                  Fmt.cedis(_total),
                  style: AppText.amount.copyWith(fontSize: 17),
                ),
              ],
            ),
          ],
        ),
      ),
      Gaps.lg,
      DetailGroup(
        rows: [
          DetailRow(
            label: service.collected ? 'Collection' : 'When',
            value: '${Fmt.relativeDay(_slot!)} · ${Fmt.time(_slot!)}',
          ),
          DetailRow(
            label: 'Where',
            value: home == null ? '' : '${home.address}\n${home.location}',
            stacked: true,
          ),
          DetailRow(
            label: 'Pay with',
            value: 'MoMo · ${Fmt.ghanaPhone(phone)}',
          ),
        ],
      ),
      Gaps.lg,
      Text(
        'You\'ll get a prompt on your phone. GRID holds the money and pays the '
        'professional only after you confirm the job is done. Cancel free until '
        'they set off; if no one is available you\'re refunded in full.',
        style: AppText.caption.copyWith(fontSize: 13),
      ),
      if (_error != null) ...[
        Gaps.lg,
        StatusBanner(
          tone: BadgeTone.danger,
          title: 'Couldn\'t book',
          message: _error,
        ),
      ],
    ];
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.selected,
    required this.onTap,
  });
  final DateTime day;
  final bool selected;
  final VoidCallback onTap;

  static const _names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: Fmt.relativeDay(day),
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: Corners.mdRadius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 58,
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.surfaceSubtle,
          borderRadius: Corners.mdRadius,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _names[day.weekday - 1],
              style: TextStyle(
                fontSize: 12.5,
                color: selected ? AppColors.onNavyMuted : AppColors.muted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.slot,
    required this.selected,
    required this.onTap,
  });
  final ServiceSlot slot;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: Fmt.time(slot.startsAt),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: Corners.mdRadius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : AppColors.surface,
            borderRadius: Corners.mdRadius,
            border: Border.all(
              color: selected ? AppColors.navy : AppColors.line,
            ),
          ),
          child: Text(
            Fmt.time(slot.startsAt),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              decoration: enabled ? null : TextDecoration.lineThrough,
              color: selected
                  ? Colors.white
                  : (enabled ? AppColors.ink : AppColors.faint),
            ),
          ),
        ),
      ),
    );
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting({
    required this.title,
    required this.message,
    this.footer = const [],
  });
  final String title;
  final String message;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Insets.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.navy,
                ),
              ),
              Gaps.xxl,
              Text(title, textAlign: TextAlign.center, style: AppText.title),
              Gaps.sm,
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppText.bodyMuted,
              ),
              if (footer.isNotEmpty) ...[Gaps.xl, ...footer],
            ],
          ),
        ),
      ),
    ),
  );
}
