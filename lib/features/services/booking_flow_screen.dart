import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
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

/// Book a home service: category → problem details → schedule → review.
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
  int _photos = 0;
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
    _propertyId = ref.read(selectedPropertyIdProvider);
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

  double get _calloutFee => (_category?.calloutFee ?? 0) + _urgency.surcharge;

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
    if (_step == 1 && !(_detailsForm.currentState?.validate() ?? false)) {
      return;
    }
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
      title: 'Request a service',
      subtitle: _category?.label,
      step: _step,
      stepCount: _stepCount,
      onBack: _back,
      bottomBar: FilledButton(
        onPressed: _canContinue ? _continue : null,
        child: Text(_step == _stepCount - 1 ? 'Confirm request' : 'Continue'),
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

  // Step 1 — category ---------------------------------------------------------

  Widget _buildCategoryStep() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What do you need help with?',
          style: theme.textTheme.headlineMedium,
        ),
        Gaps.xl,
        for (final category in ServiceCategory.values) ...[
          SelectionTile(
            selected: _category == category,
            onTap: () => setState(() {
              _category = category;
              _issue = null;
            }),
            title: category.label,
            subtitle: category.description,
            leading: TintedIcon(category.icon, size: 40),
          ),
          Gaps.md,
        ],
      ],
    );
  }

  // Step 2 — issue & description ----------------------------------------------

  Widget _buildDetailsStep() {
    final theme = Theme.of(context);
    final category = _category!;

    return Form(
      key: _detailsForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us about the problem',
            style: theme.textTheme.headlineMedium,
          ),
          Gaps.sm,
          Text(
            'This helps us send the right professional with the right tools.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
          Gaps.xl,
          Text('Common issues', style: theme.textTheme.titleMedium),
          Gaps.md,
          Wrap(
            spacing: Insets.sm,
            runSpacing: Insets.sm,
            children: [
              for (final issue in category.issues)
                ChoiceChip(
                  label: Text(issue),
                  selected: _issue == issue,
                  onSelected: (_) => setState(() => _issue = issue),
                  selectedColor: AppColors.forestDeep,
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: _issue == issue ? Colors.white : AppColors.ink,
                  ),
                  backgroundColor: AppColors.card,
                  side: BorderSide(
                    color: _issue == issue
                        ? AppColors.forestDeep
                        : AppColors.outline,
                  ),
                  showCheckmark: false,
                ),
            ],
          ),
          Gaps.xl,
          TextFormField(
            controller: _descriptionCtrl,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Describe the problem',
              hintText:
                  'e.g. Half of the living room lost power after a '
                  'loud pop last night.',
              alignLabelWithHint: true,
            ),
            validator: (v) =>
                Validators.notEmpty(v, label: 'A short description'),
          ),
          Gaps.xl,
          Text('Add photos (optional)', style: theme.textTheme.titleMedium),
          Gaps.sm,
          Text(
            'A photo of the issue speeds up diagnosis.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.inkFaint,
            ),
          ),
          Gaps.md,
          Row(
            children: [
              for (var i = 0; i < _photos; i++) ...[
                _PhotoThumb(
                  index: i,
                  onRemove: () => setState(() => _photos--),
                ),
                Gaps.md,
              ],
              if (_photos < 3)
                _AddPhotoBox(onTap: () => setState(() => _photos++)),
            ],
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
        Text('Where and when?', style: theme.textTheme.headlineMedium),
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
        Text('Urgency', style: theme.textTheme.titleMedium),
        Gaps.md,
        for (final urgency in ServiceUrgency.values) ...[
          SelectionTile(
            selected: _urgency == urgency,
            onTap: () => setState(() => _urgency = urgency),
            title: urgency.label,
            subtitle: urgency.description,
            accent: urgency == ServiceUrgency.emergency
                ? AppColors.danger
                : AppColors.forest,
            trailing: urgency.surcharge > 0
                ? Text(
                    '+${Fmt.cedis(urgency.surcharge)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.inkMuted,
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
              Expanded(
                child: _DayChip(
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
              ChoiceChip(
                label: Text(slot),
                selected: _timeSlot == slot,
                onSelected: (_) => setState(() => _timeSlot = slot),
                selectedColor: AppColors.forestDeep,
                labelStyle: theme.textTheme.labelMedium?.copyWith(
                  color: _timeSlot == slot ? Colors.white : AppColors.ink,
                ),
                backgroundColor: AppColors.card,
                side: BorderSide(
                  color: _timeSlot == slot
                      ? AppColors.forestDeep
                      : AppColors.outline,
                ),
                showCheckmark: false,
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
        Text('Review your request', style: theme.textTheme.headlineMedium),
        Gaps.xl,
        AppCard(
          padding: const EdgeInsets.all(Insets.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TintedIcon(category.icon),
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
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_urgency == ServiceUrgency.emergency)
                    const StatusBadge(
                      label: 'Emergency',
                      tone: BadgeTone.danger,
                    ),
                ],
              ),
              Gaps.lg,
              const DashedDivider(),
              Gaps.sm,
              ReceiptRow(label: 'Problem', value: _descriptionCtrl.text.trim()),
              if (property != null)
                ReceiptRow(
                  label: 'Location',
                  value:
                      '${property.nickname} — ${property.address}, ${property.city}',
                ),
              ReceiptRow(label: 'Urgency', value: _urgency.label),
              ReceiptRow(
                label: 'Preferred time',
                value: '${Fmt.relativeDay(date)}, $_timeSlot',
              ),
              if (_photos > 0)
                ReceiptRow(label: 'Photos', value: '$_photos attached'),
              const Divider(height: Insets.xl),
              ReceiptRow(
                label: 'Call-out fee',
                value: _calloutFee > 0
                    ? Fmt.cedis(_calloutFee)
                    : 'Quoted after details',
                emphasize: true,
              ),
            ],
          ),
        ),
        Gaps.lg,
        const InfoBanner(
          icon: Icons.receipt_long_rounded,
          message:
              'Transparent pricing — the call-out fee covers inspection '
              'and diagnosis. You approve the final quote before any work '
              'starts.',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _DayChip extends StatelessWidget {
  const _DayChip({
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
      borderRadius: Corners.mdRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Insets.md),
          decoration: BoxDecoration(
            borderRadius: Corners.mdRadius,
            border: Border.all(
              color: selected ? AppColors.forestDeep : AppColors.outline,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddPhotoBox extends StatelessWidget {
  const _AddPhotoBox({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceDim,
      borderRadius: Corners.mdRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          onTap();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo attached (simulated upload)')),
          );
        },
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            borderRadius: Corners.mdRadius,
            border: Border.all(color: AppColors.outline),
          ),
          child: const Icon(
            Icons.add_a_photo_outlined,
            color: AppColors.inkFaint,
          ),
        ),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.index, required this.onRemove});

  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.tealSoft,
            borderRadius: Corners.mdRadius,
          ),
          child: const Icon(Icons.image_rounded, color: AppColors.teal),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Material(
            color: AppColors.ink,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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
                  color: AppColors.forest,
                ),
              ),
              Gaps.xxl,
              Text(
                'Submitting your request',
                style: theme.textTheme.headlineSmall,
              ),
              Gaps.sm,
              Text(
                'Matching you with vetted professionals…',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
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
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.home);
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Insets.xl),
            child: Column(
              children: [
                Gaps.xxxl,
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: AppColors.successSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 42,
                    color: AppColors.success,
                  ),
                ),
                Gaps.lg,
                Text('Request received', style: theme.textTheme.headlineMedium),
                Gaps.sm,
                Text(
                  'Reference ${request.reference} — track it any time in '
                  'Activity.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
                Gaps.xxl,
                AppCard(
                  padding: const EdgeInsets.all(Insets.xl),
                  child: Column(
                    children: [
                      ReceiptRow(
                        label: 'Service',
                        value: request.category.label,
                      ),
                      ReceiptRow(label: 'Issue', value: request.issue),
                      ReceiptRow(
                        label: 'Location',
                        value: request.propertyLabel,
                      ),
                      ReceiptRow(
                        label: 'Preferred time',
                        value:
                            '${Fmt.relativeDay(request.preferredDate)}, ${request.timeSlot}',
                      ),
                      ReceiptRow(
                        label: 'Call-out fee',
                        value: request.calloutFee > 0
                            ? Fmt.cedis(request.calloutFee)
                            : 'Quoted after details',
                      ),
                    ],
                  ),
                ),
                Gaps.lg,
                const InfoBanner(
                  icon: Icons.schedule_rounded,
                  message:
                      'What happens next: we assign a vetted professional, '
                      'you get their profile and ETA, and you approve the '
                      'quote before work starts.',
                ),
                Gaps.xxl,
                FilledButton(
                  onPressed: () {
                    context.go(Routes.home);
                    context.push(Routes.serviceRequest(request.id));
                  },
                  child: const Text('View request'),
                ),
                Gaps.md,
                OutlinedButton(
                  onPressed: () => context.go(Routes.home),
                  child: const Text('Back to home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
