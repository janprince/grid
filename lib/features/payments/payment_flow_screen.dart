import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import 'widgets/payment_result_view.dart';

enum _Phase { steps, processing, result }

/// One flow for every utility. The [UtilityType] drives labels,
/// validation and whether the user enters an amount or picks a plan.
/// Steps: account → amount/plan → method → review → result.
class PaymentFlowScreen extends ConsumerStatefulWidget {
  const PaymentFlowScreen({
    super.key,
    required this.type,
    this.initialAccountId,
  });

  final UtilityType type;

  /// When set (e.g. "Pay again" or a saved-account card), the account is
  /// preselected and the flow starts on the amount step.
  final String? initialAccountId;

  @override
  ConsumerState<PaymentFlowScreen> createState() => _PaymentFlowScreenState();
}

class _PaymentFlowScreenState extends ConsumerState<PaymentFlowScreen> {
  static const _stepCount = 4;

  _Phase _phase = _Phase.steps;
  int _step = 0;

  // Step 1 — account
  UtilityAccount? _selectedAccount;
  bool _enterNew = false;
  final _newAccountForm = GlobalKey<FormState>();
  final _numberCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  bool _saveNew = true;
  String? _propertyId;

  // Step 2 — amount / plan
  final _amountCtrl = TextEditingController();
  UtilityPlan? _plan;
  String? _amountError;

  // Step 3 — method
  PaymentMethod? _method;

  PaymentTransaction? _result;

  UtilityType get type => widget.type;

  @override
  void initState() {
    super.initState();
    final accounts = ref.read(accountsByTypeProvider(type));
    _propertyId = ref.read(selectedPropertyIdProvider);
    if (widget.initialAccountId != null) {
      final match = accounts
          .where((a) => a.id == widget.initialAccountId)
          .firstOrNull;
      if (match != null) {
        _selectedAccount = match;
        _propertyId = match.propertyId ?? _propertyId;
        _step = 1;
        if (match.lastAmount != null && !type.isPlanBased) {
          _amountCtrl.text = match.lastAmount!.toStringAsFixed(2);
        }
      }
    }
    _method = ref
        .read(paymentMethodsProvider)
        .where((m) => m.isDefault)
        .firstOrNull;
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _nicknameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Derived state
  // -------------------------------------------------------------------------

  String get _accountNumber =>
      _selectedAccount?.accountNumber ??
      _numberCtrl.text.replaceAll(RegExp(r'\s'), '');

  String get _accountNickname {
    if (_selectedAccount != null) return _selectedAccount!.nickname;
    final nickname = _nicknameCtrl.text.trim();
    return nickname.isEmpty
        ? 'New ${type.accountLabel.toLowerCase()}'
        : nickname;
  }

  double? get _amount => type.isPlanBased
      ? _plan?.price
      : double.tryParse(_amountCtrl.text.replaceAll(',', ''));

  bool get _canContinue => switch (_step) {
    0 => _selectedAccount != null || _enterNew,
    1 =>
      type.isPlanBased
          ? _plan != null
          : Validators.amount(_amountCtrl.text) == null,
    2 => _method != null,
    _ => true,
  };

  // -------------------------------------------------------------------------
  // Navigation
  // -------------------------------------------------------------------------

  void _back() {
    if (_phase == _Phase.processing) return;
    if (_phase == _Phase.result) {
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
    if (_step == 0 && _enterNew && _selectedAccount == null) {
      if (!(_newAccountForm.currentState?.validate() ?? false)) return;
    }
    if (_step == 1 && !type.isPlanBased) {
      final error = Validators.amount(_amountCtrl.text);
      setState(() => _amountError = error);
      if (error != null) return;
    }
    if (_step < _stepCount - 1) {
      setState(() => _step++);
    } else {
      _pay();
    }
  }

  Future<void> _pay() async {
    final method = _method!;
    final amount = _amount!;
    final property = ref.read(propertyByIdProvider(_propertyId));

    setState(() => _phase = _Phase.processing);

    final tx = await ref
        .read(paymentsApiProvider)
        .pay(
          type: type,
          accountNumber: _accountNumber,
          accountNickname: _accountNickname,
          amount: amount,
          method: method,
          propertyId: property?.id,
          propertyLabel: property?.nickname,
          planName: _plan?.name,
        );

    if (!mounted) return;

    if (tx.status == TransactionStatus.success) {
      ref.read(transactionsProvider.notifier).insert(tx);
      final saved = _selectedAccount;
      if (saved != null) {
        ref.read(accountsProvider.notifier).markPaid(saved.id, amount);
      } else if (_saveNew) {
        ref
            .read(accountsProvider.notifier)
            .add(
              UtilityAccount(
                id: 'a${DateTime.now().microsecondsSinceEpoch}',
                type: type,
                accountNumber: _accountNumber,
                nickname: _accountNickname,
                propertyId: _propertyId,
                lastPaidAt: DateTime.now(),
                lastAmount: amount,
              ),
            );
      }
    } else {
      ref.read(transactionsProvider.notifier).insert(tx);
    }

    setState(() {
      _result = tx;
      _phase = _Phase.result;
    });
  }

  void _retry() {
    setState(() {
      _phase = _Phase.steps;
      _step = 2; // back to payment method
    });
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_phase == _Phase.processing) {
      return _ProcessingView(type: type, amount: _amount ?? 0);
    }
    if (_phase == _Phase.result && _result != null) {
      return PaymentResultView(transaction: _result!, onRetry: _retry);
    }

    return StepFlowScaffold(
      title: type.label,
      subtitle: type.providerName,
      step: _step,
      stepCount: _stepCount,
      onBack: _back,
      bottomBar: FilledButton(
        onPressed: _canContinue ? _continue : null,
        child: Text(
          _step == _stepCount - 1
              ? 'Confirm & pay ${_amount == null ? '' : Fmt.cedis(_amount!)}'
              : 'Continue',
        ),
      ),
      child: StepTransition(
        stepKey: _step,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Insets.xl),
          child: switch (_step) {
            0 => _buildAccountStep(),
            1 => _buildAmountStep(),
            2 => _buildMethodStep(),
            _ => _buildReviewStep(),
          },
        ),
      ),
    );
  }

  // Step 1 — choose account -------------------------------------------------

  Widget _buildAccountStep() {
    final theme = Theme.of(context);
    final accounts = ref.watch(accountsByTypeProvider(type));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          type.isPhoneAccount
              ? 'Who is this for?'
              : 'Which ${type.accountLabel.toLowerCase()}?',
          style: theme.textTheme.headlineMedium,
        ),
        Gaps.sm,
        Text(
          accounts.isEmpty
              ? 'Enter the details below — you can save them for next time.'
              : 'Pick a saved ${type.accountLabel.toLowerCase()} or add a new one.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.inkMuted,
          ),
        ),
        Gaps.xl,
        for (final account in accounts) ...[
          SelectionTile(
            selected: !_enterNew && _selectedAccount?.id == account.id,
            onTap: () => setState(() {
              _selectedAccount = account;
              _enterNew = false;
              _propertyId = account.propertyId ?? _propertyId;
              if (account.lastAmount != null &&
                  !type.isPlanBased &&
                  _amountCtrl.text.isEmpty) {
                _amountCtrl.text = account.lastAmount!.toStringAsFixed(2);
              }
            }),
            title: account.nickname,
            subtitle:
                '${Fmt.masked(account.accountNumber)}'
                '${account.lastPaidAt != null ? ' • ${Fmt.lastPaidLabel(account.lastPaidAt!)}' : ''}',
            leading: TintedIcon(type.icon, size: 40),
            trailing: account.isDefault
                ? const StatusBadge(label: 'Default', tone: BadgeTone.success)
                : null,
          ),
          Gaps.md,
        ],
        SelectionTile(
          selected: _enterNew,
          onTap: () => setState(() {
            _enterNew = true;
            _selectedAccount = null;
          }),
          title: type.isPhoneAccount
              ? 'New phone number'
              : 'New ${type.accountLabel.toLowerCase()}',
          subtitle: 'Enter details manually',
          leading: const TintedIcon(Icons.add_rounded, size: 40),
        ),
        if (_enterNew) ...[
          Gaps.xl,
          Form(
            key: _newAccountForm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _numberCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d\s]')),
                  ],
                  decoration: InputDecoration(
                    labelText: type.accountLabel,
                    hintText: type.accountHint,
                  ),
                  validator: (v) => type.isPhoneAccount
                      ? Validators.ghanaPhone(v)
                      : Validators.digits(
                          v,
                          min: type.minDigits,
                          max: type.maxDigits,
                          label: type.accountLabel,
                        ),
                ),
                Gaps.lg,
                TextFormField(
                  controller: _nicknameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nickname (optional)',
                    hintText: "e.g. My Home, Mum's House",
                  ),
                ),
                Gaps.sm,
                SwitchListTile(
                  value: _saveNew,
                  onChanged: (v) => setState(() => _saveNew = v),
                  title: Text(
                    'Save for next time',
                    style: theme.textTheme.bodyMedium,
                  ),
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: AppColors.forest,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Step 2 — amount or plan -------------------------------------------------

  Widget _buildAmountStep() {
    final theme = Theme.of(context);
    final property = ref.watch(propertyByIdProvider(_propertyId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          type.isPlanBased ? 'Choose a package' : 'How much?',
          style: theme.textTheme.headlineMedium,
        ),
        Gaps.lg,
        _PayingForCard(
          type: type,
          nickname: _accountNickname,
          number: _accountNumber,
          property: property,
          onChangeProperty: type.isPhoneAccount ? null : _pickProperty,
        ),
        Gaps.xl,
        if (type.isPlanBased)
          ..._buildPlanChoices()
        else ...[
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            style: theme.textTheme.headlineLarge,
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: 'GH₵ ',
              prefixStyle: theme.textTheme.headlineLarge?.copyWith(
                color: AppColors.inkFaint,
              ),
              hintText: '0.00',
              errorText: _amountError,
            ),
            onChanged: (_) => setState(() => _amountError = null),
          ),
          Gaps.lg,
          Wrap(
            spacing: Insets.sm,
            runSpacing: Insets.sm,
            children: [
              for (final quick in type.quickAmounts)
                _QuickAmountChip(
                  amount: quick,
                  selected: _amountCtrl.text == quick.toStringAsFixed(2),
                  onTap: () => setState(() {
                    _amountCtrl.text = quick.toStringAsFixed(2);
                    _amountError = null;
                  }),
                ),
            ],
          ),
        ],
      ],
    );
  }

  List<Widget> _buildPlanChoices() {
    final plans = ref.watch(plansProvider(type));
    return [
      for (final plan in plans) ...[
        SelectionTile(
          selected: _plan?.id == plan.id,
          onTap: () => setState(() => _plan = plan),
          title: plan.name,
          subtitle: plan.description,
          trailing: Text(
            Fmt.cedis(plan.price),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Gaps.md,
      ],
    ];
  }

  Future<void> _pickProperty() async {
    final properties = ref.read(propertiesProvider);
    final selected = await showAppBottomSheet<String>(
      context,
      title: 'Which home is this for?',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final p in properties) ...[
            SelectionTile(
              selected: p.id == _propertyId,
              onTap: () => Navigator.of(context).pop(p.id),
              title: p.nickname,
              subtitle: p.location,
              leading: const TintedIcon(Icons.home_outlined, size: 40),
            ),
            Gaps.md,
          ],
        ],
      ),
    );
    if (selected != null) setState(() => _propertyId = selected);
  }

  // Step 3 — payment method -------------------------------------------------

  Widget _buildMethodStep() {
    final theme = Theme.of(context);
    final methods = ref.watch(paymentMethodsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pay with', style: theme.textTheme.headlineMedium),
        Gaps.sm,
        Text(
          'Choose how you want to pay ${_amount == null ? '' : Fmt.cedis(_amount!)}.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.inkMuted,
          ),
        ),
        Gaps.xl,
        for (final method in methods) ...[
          SelectionTile(
            selected: _method?.id == method.id,
            onTap: () => setState(() => _method = method),
            title: method.label,
            subtitle: method.alwaysFails
                ? 'Use this to preview a failed payment'
                : method.maskedNumber,
            leading: TintedIcon(method.icon, size: 40),
            trailing: method.alwaysFails
                ? const StatusBadge(label: 'Demo', tone: BadgeTone.warning)
                : null,
          ),
          Gaps.md,
        ],
        Gaps.sm,
        const InfoBanner(
          icon: Icons.lock_outline_rounded,
          message:
              'Secured by GRID Pay. This is a demo — no real charge '
              'is made.',
        ),
      ],
    );
  }

  // Step 4 — review ---------------------------------------------------------

  Widget _buildReviewStep() {
    final theme = Theme.of(context);
    final property = ref.watch(propertyByIdProvider(_propertyId));
    final amount = _amount ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review your payment', style: theme.textTheme.headlineMedium),
        Gaps.sm,
        Text(
          'Check everything before you confirm.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.inkMuted,
          ),
        ),
        Gaps.xl,
        AppCard(
          padding: const EdgeInsets.all(Insets.xl),
          child: Column(
            children: [
              TintedIcon(type.icon, size: 52),
              Gaps.md,
              Text(Fmt.cedis(amount), style: theme.textTheme.displaySmall),
              Text(
                type.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
              Gaps.lg,
              const DashedDivider(),
              Gaps.sm,
              ReceiptRow(label: type.accountLabel, value: _accountNumber),
              ReceiptRow(label: 'Nickname', value: _accountNickname),
              if (_plan != null)
                ReceiptRow(label: 'Package', value: _plan!.name),
              if (property != null && !type.isPhoneAccount)
                ReceiptRow(label: 'Home', value: property.nickname),
              ReceiptRow(label: 'Paying with', value: _method!.label),
              ReceiptRow(label: 'Fees', value: 'Free'),
              const Divider(height: Insets.xl),
              ReceiptRow(
                label: 'Total',
                value: Fmt.cedis(amount),
                emphasize: true,
              ),
            ],
          ),
        ),
        Gaps.lg,
        const InfoBanner(
          message:
              'Demo transaction — nothing will be charged and no '
              'credit is delivered.',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _PayingForCard extends StatelessWidget {
  const _PayingForCard({
    required this.type,
    required this.nickname,
    required this.number,
    required this.property,
    this.onChangeProperty,
  });

  final UtilityType type;
  final String nickname;
  final String number;
  final Property? property;
  final VoidCallback? onChangeProperty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        color: AppColors.tealSoft,
        borderRadius: Corners.lgRadius,
      ),
      child: Row(
        children: [
          TintedIcon(type.icon, size: 40, background: Colors.white),
          Gaps.md,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nickname, style: theme.textTheme.titleMedium),
                Text(
                  number.isEmpty ? type.accountHint : Fmt.masked(number),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          if (property != null && onChangeProperty != null)
            TextButton.icon(
              onPressed: onChangeProperty,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: Insets.sm),
              ),
              icon: const Icon(Icons.home_outlined, size: 16),
              label: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 88),
                child: Text(
                  property!.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.teal,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickAmountChip extends StatelessWidget {
  const _QuickAmountChip({
    required this.amount,
    required this.selected,
    required this.onTap,
  });

  final int amount;
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
            vertical: Insets.md,
          ),
          decoration: BoxDecoration(
            borderRadius: Corners.pill,
            border: Border.all(
              color: selected ? AppColors.forestDeep : AppColors.outline,
            ),
          ),
          child: Text(
            'GH₵ $amount',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProcessingView extends StatelessWidget {
  const _ProcessingView({required this.type, required this.amount});

  final UtilityType type;
  final double amount;

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
                'Processing ${Fmt.cedis(amount)}',
                style: theme.textTheme.headlineSmall,
              ),
              Gaps.sm,
              Text(
                'Contacting ${type.providerName}…',
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
