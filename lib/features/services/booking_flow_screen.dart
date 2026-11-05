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

class BookingArgs {
  const BookingArgs({this.category, this.urgency});

  final ServiceCategory? category;
  final ServiceUrgency? urgency;
}

enum _Phase { steps, submitting, confirmed }

const _timeSlots = [
  '8:00 AM – 10:00 AM',
  '10:00 AM – 12:00 PM',
  '1:00 PM – 3:00 PM',
  '3:00 PM – 5:00 PM',
];

/// Book a service: which service → what to do → where and when → review.
class BookingFlowScreen extends ConsumerStatefulWidget {
  const BookingFlowScreen({super.key, this.initialCategory, this.args});

  final ServiceCategory? initialCategory;
  final BookingArgs? args;

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  static const _stepCount = 4;

  _Phase _phase = _Phase.steps;
  int _step = 0;

  ServiceCategory? _category;
  String? _issue;
  final _descriptionCtrl = TextEditingController();
  final _detailsForm = GlobalKey<FormState>();
  final int _photos = 0;
  String? _propertyId;
  ServiceUrgency _urgency = ServiceUrgency.standard;
  int _dayOffset = 0; // 0 = today, 1 = tomorrow, 2 = day after
  String _timeSlot = _timeSlots.first;

  ServiceRequest? _result;

  @override
  void initState() {
    super.initState();
    _category = widget.args?.category ?? widget.initialCategory;
    _urgency = widget.args?.urgency ?? ServiceUrgency.standard;
    _propertyId = ref.read(selectedPropertyProvider)?.id;
    if (_category != null) _step = 1;
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  bool get _canContinue => switch (_step) {
    0 => _category != null,
    1 => _issue != null,
    2 => _propertyId != null,
    _ => true,
  };

  double get _estimate => (_category?.fromPrice ?? 0) + _urgency.surcharge;

  void _back() {
    if (_phase != _Phase.steps) {
      context.pop();
      return;
    }
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
    final property = ref.read(propertyByIdProvider(_propertyId));
    if (property == null || _category == null || _issue == null) return;

    setState(() => _phase = _Phase.submitting);

    final now = DateTime.now();
    final date = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: _dayOffset));

    final request = await ref
        .read(servicesApiProvider)
        .submitRequest(
          category: _category!,
          issue: _issue!,
          description: _descriptionCtrl.text.trim(),
          property: property,
          urgency: _urgency,
          preferredDate: date,
          timeSlot: _timeSlot,
          photoCount: _photos,
        );

    if (!mounted) return;
    ref.read(serviceRequestsProvider.notifier).insert(request);
    setState(() {
      _result = request;
      _phase = _Phase.confirmed;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _Phase.submitting) {
      return const _SubmittingView();
    }
    if (_phase == _Phase.confirmed && _result != null) {
      return _ConfirmationView(request: _result!);
    }

    return StepFlowScaffold(
      title: 'Book a service',
      subtitle: _category?.label,
      step: _step,
      stepCount: _stepCount,
      onBack: _back,
      bottomBar: PrimaryButton(
        label: _step == _stepCount - 1 ? 'Confirm request' : 'Continue',
        onPressed: _canContinue ? _continue : null,
      ),
      child: StepTransition(
        stepKey: _step,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Insets.xl),
          child: switch (_step) {
            0 => _buildCategoryStep(),
            1 => _buildDetailsStep(),
            2 => _buildScheduleStep(),
            _ => _buildReviewStep(),
          },
        ),
      ),
    );
  }

  // Step 1 — service ----------------------------------------------------------

  Widget _buildCategoryStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('What do you need?', style: AppText.headline),
      Gaps.xl,
      for (final category in ServiceCategory.values) ...[
        ServiceCard(
          category: category,
          selected: _category == category,
          onTap: () => setState(() {
            if (_category != category) _issue = null;
            _category = category;
          }),
        ),
        Gaps.md,
      ],
    ],
  );

  // Step 2 — what to do -------------------------------------------------------

  Widget _buildDetailsStep() {
    final category = _category!;
    return Form(
      key: _detailsForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category == ServiceCategory.cleaning
                ? 'What kind of clean?'
                : 'What should we do with your items?',
            style: AppText.headline,
          ),
          Gaps.sm,
          Text(
            'Pick one. Your professional confirms the price before they '
            'start.',
            style: AppText.bodyMuted,
          ),
          Gaps.xl,
          for (final issue in category.issues) ...[
            SelectionTile(
              selected: _issue == issue,
              onTap: () => setState(() => _issue = issue),
              title: issue,
            ),
            Gaps.sm,
          ],
          Gaps.lg,
          TextFormField(
            controller: _descriptionCtrl,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Anything we should know? (optional)',
              hintText: category == ServiceCategory.cleaning
                  ? 'e.g. 3 bedrooms, focus on the kitchen. Supplies are in '
                        'the store room.'
                  : 'e.g. About 15 items. Shirts on hangers, please.',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  // Step 3 — schedule ----------------------------------------------------------

  Widget _buildScheduleStep() {
    final theme = Theme.of(context);
    final properties = ref.watch(propertiesProvider);
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _category == ServiceCategory.laundry
              ? 'Where and when should we pick up?'
              : 'Where and when?',
          style: AppText.headline,
        ),
        Gaps.xl,
        Text('Location', style: theme.textTheme.titleMedium),
        Gaps.md,
        for (final property in properties) ...[
          SelectionTile(
            selected: _propertyId == property.id,
            onTap: () => setState(() => _propertyId = property.id),
            title: property.nickname,
            subtitle: '${property.address}, ${property.city}',
            leading: const TintedIcon(Icons.home_outlined, size: 40),
          ),
          Gaps.md,
        ],
        Gaps.lg,
        Text('How soon', style: theme.textTheme.titleMedium),
        Gaps.md,
        for (final urgency in ServiceUrgency.values) ...[
          SelectionTile(
            selected: _urgency == urgency,
            onTap: () => setState(() => _urgency = urgency),
            title: urgency.label,
            subtitle: urgency.description,
            trailing: urgency.surcharge > 0
                ? Text(
                    '+${Fmt.cedis(urgency.surcharge)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.muted,
                    ),
                  )
                : null,
          ),
          Gaps.md,
        ],
        Gaps.lg,
        Text('Preferred day', style: theme.textTheme.titleMedium),
        Gaps.md,
        Row(
          children: [
            for (var offset = 0; offset < 3; offset++) ...[
              GridChip(
                expand: true,
                label: switch (offset) {
                  0 => 'Today',
                  1 => 'Tomorrow',
                  _ => Fmt.date(
                    now.add(const Duration(days: 2)),
                  ).split(' ').take(2).join(' '),
                },
                selected: _dayOffset == offset,
                onTap: () => setState(() => _dayOffset = offset),
              ),
              if (offset < 2) Gaps.sm,
            ],
          ],
        ),
        Gaps.lg,
        Text('Time slot', style: theme.textTheme.titleMedium),
        Gaps.md,
        Wrap(
          spacing: Insets.sm,
          runSpacing: Insets.sm,
          children: [
            for (final slot in _timeSlots)
              GridChip(
                label: slot,
                selected: _timeSlot == slot,
                onTap: () => setState(() => _timeSlot = slot),
              ),
          ],
        ),
      ],
    );
  }

  // Step 4 — review --------------------------------------------------------------

  Widget _buildReviewStep() {
    final theme = Theme.of(context);
    final category = _category!;
    final property = ref.watch(propertyByIdProvider(_propertyId));
    final now = DateTime.now();
    final date = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: _dayOffset));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review your request', style: AppText.headline),
        Gaps.xl,
        AppCard(
          padding: const EdgeInsets.all(Insets.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ServiceBadge(category: category),
                  Gaps.md,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.label,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          _issue ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Gaps.lg,
              const DashedDivider(),
              Gaps.sm,
              if (_descriptionCtrl.text.trim().isNotEmpty)
                ReceiptRow(label: 'Notes', value: _descriptionCtrl.text.trim()),
              if (property != null)
                ReceiptRow(
                  label: 'Location',
                  value:
                      '${property.nickname} — ${property.address}, ${property.city}',
                ),
              ReceiptRow(label: 'How soon', value: _urgency.label),
              ReceiptRow(
                label: 'Preferred time',
                value: '${Fmt.relativeDay(date)}, $_timeSlot',
              ),
              const Divider(height: Insets.xl),
              ReceiptRow(
                label: 'Price',
                value: 'From ${Fmt.cedis(_estimate)}',
                emphasize: true,
              ),
            ],
          ),
        ),
        Gaps.lg,
        InfoBanner(
          icon: Icons.receipt_long_rounded,
          message: category == ServiceCategory.laundry
              ? 'The final price is confirmed when your items are collected. '
                    'You pay once they are delivered.'
              : 'Your cleaner confirms the price when they arrive. You pay '
                    'once the job is done.',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _SubmittingView extends StatelessWidget {
  const _SubmittingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
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
              Text('Sending your request', style: AppText.title),
              Gaps.sm,
              Text(
                'Matching you with a vetted professional…',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmationView extends StatelessWidget {
  const _ConfirmationView({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.home);
      },
      // Shares the payment outcome treatment, so booking a clean ends on
      // a screen as considered as buying power does.
      child: OutcomeScaffold(
        tone: OutcomeTone.success,
        headline: 'Request received',
        figure: request.reference,
        message: 'Track it any time in Activity.',
        content: [
          AppCard(
            padding: const EdgeInsets.all(Insets.xl),
            child: Column(
              children: [
                ReceiptRow(label: 'Service', value: request.category.label),
                ReceiptRow(label: 'Type', value: request.issue),
                ReceiptRow(label: 'Location', value: request.propertyLabel),
                ReceiptRow(
                  label: 'Preferred time',
                  value:
                      '${Fmt.relativeDay(request.preferredDate)}, '
                      '${request.timeSlot}',
                ),
                ReceiptRow(
                  label: 'Price',
                  value: 'From ${Fmt.cedis(request.estimate)}',
                ),
              ],
            ),
          ),
          Gaps.lg,
          const InfoBanner(
            icon: Icons.schedule_rounded,
            message:
                'What happens next: we match you with a vetted '
                'professional nearby and send you their name and arrival '
                'time.',
          ),
        ],
        actions: [
          Gaps.xxl,
          PrimaryButton(
            label: 'View request',
            onPressed: () {
              context.go(Routes.home);
              context.push(Routes.serviceRequest(request.id));
            },
          ),
          Gaps.md,
          SecondaryButton(
            label: 'Back to home',
            onPressed: () => context.go(Routes.home),
          ),
        ],
      ),
    );
  }
}
