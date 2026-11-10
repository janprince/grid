import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/api/api_exception.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/biller_brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import 'widgets/payment_result_view.dart';

enum _Phase { steps, placing, approving, result }

/// One flow for every bill. The [UtilityType] drives labels and validation.
///
/// Steps: account (checked with the biller) → amount or bundle → review.
/// Confirming places the order, which sends a MoMo prompt to the signed-in
/// number; the screen then waits for the approval and the biller's answer.
class PaymentFlowScreen extends ConsumerStatefulWidget {
  const PaymentFlowScreen({
    super.key,
    required this.type,
    this.initialAccountId,
  });

  final UtilityType type;

  /// When set (e.g. "Pay again" or a saved-account card), the account is
  /// preselected and checked straight away.
  final String? initialAccountId;

  @override
  ConsumerState<PaymentFlowScreen> createState() => _PaymentFlowScreenState();
}

class _PaymentFlowScreenState extends ConsumerState<PaymentFlowScreen> {
  static const _stepCount = 3;

  _Phase _phase = _Phase.steps;
  int _step = 0;
  bool _busy = false;

  // Step 1 — account
  UtilityAccount? _selectedAccount;
  bool _enterNew = false;
  final _newAccountForm = GlobalKey<FormState>();
  final _numberCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  bool _saveNew = true;
  bool _postpaid = false;
  MobileNetwork? _network;
  String? _propertyId;

  /// What the biller said about the chosen account.
  BillLookup? _lookup;
  String? _meterNumber;

  // Step 2 — amount / bundle
  final _amountCtrl = TextEditingController();
  BillBundle? _bundle;
  String? _amountError;

  // Step 3 — the wallet that pays
  MobileNetwork? _wallet;

  /// One key per confirmation, so a double tap or a retried request can't
  /// place two orders.
  String? _idempotencyKey;
  BillOrder? _order;

  UtilityType get type => widget.type;

  String get _payerPhone => ref.read(sessionProvider).user?.phone ?? '';

  @override
  void initState() {
    super.initState();
    _propertyId = ref.read(selectedPropertyProvider)?.id;
    _wallet = MobileNetwork.guess(_payerPhone) ?? MobileNetwork.mtn;
    if (widget.initialAccountId != null) {
      final match = ref
          .read(accountsByTypeProvider(type))
          .where((a) => a.id == widget.initialAccountId)
          .firstOrNull;
      if (match != null) {
        _choose(match);
        WidgetsBinding.instance.addPostFrameCallback((_) => _continue());
      }
    }
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
      _numberCtrl.text.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();

  String get _accountNickname {
    if (_selectedAccount != null) return _selectedAccount!.nickname;
    final nickname = _nicknameCtrl.text.trim();
    return nickname.isEmpty
        ? 'New ${type.accountLabel.toLowerCase()}'
        : nickname;
  }

  /// "200.00" reads as noise at display size; "200" is the amount.
  static String _trimAmount(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  double? get _amount => type.isPlanBased
      ? _bundle?.amount
      : double.tryParse(_amountCtrl.text.replaceAll(',', ''));

  double get _minAmount => _lookup?.minAmount ?? 1;
  double get _maxAmount => _lookup?.maxAmount ?? 1000;

  bool get _canContinue => switch (_step) {
    0 => _selectedAccount != null || _enterNew,
    1 =>
      type.isPlanBased
          ? _bundle != null
          : Validators.amount(
                  _amountCtrl.text,
                  min: _minAmount,
                  max: _maxAmount,
                ) ==
                null,
    _ => _wallet != null,
  };

  BillTarget get _target {
    final network = type.isPhoneAccount
        ? (_network ?? MobileNetwork.guess(_accountNumber))
        : null;
    final ecgKind =
        _selectedAccount?.ecgKind ??
        (_postpaid ? EcgKind.postpaid : EcgKind.prepaid);
    final target = BillTarget(
      productCode: billProductCode(type, network: network, ecgKind: ecgKind),
      accountNumber: _accountNumber,
    );
    return _meterNumber == null ? target : target.withMeter(_meterNumber!);
  }

  void _choose(UtilityAccount account) {
    _selectedAccount = account;
    _enterNew = false;
    _network = account.network ?? MobileNetwork.guess(account.accountNumber);
    _propertyId = account.propertyId ?? _propertyId;
    if (account.lastAmount != null &&
        !type.isPlanBased &&
        _amountCtrl.text.isEmpty) {
      _amountCtrl.text = _trimAmount(account.lastAmount!);
    }
  }

  // -------------------------------------------------------------------------
  // Navigation
  // -------------------------------------------------------------------------

  void _back() {
    if (_phase != _Phase.steps || _busy) return;
    if (_step > 0) {
      setState(() => _step--);
    } else {
      context.pop();
    }
  }

  Future<void> _continue() async {
    if (_step == 0) {
      if (_enterNew && !(_newAccountForm.currentState?.validate() ?? false)) {
        return;
      }
      if (await _checkAccount()) setState(() => _step = 1);
      return;
    }
    if (_step == 1 && !type.isPlanBased) {
      final error = Validators.amount(
        _amountCtrl.text,
        min: _minAmount,
        max: _maxAmount,
      );
      setState(() => _amountError = error);
      if (error != null) return;
    }
    if (_step < _stepCount - 1) {
      setState(() => _step++);
    } else {
      await _pay();
    }
  }

  /// Asks the biller about the account. When the phone has several ECG
  /// meters, the person picks one and it is checked again.
  Future<bool> _checkAccount() async {
    setState(() => _busy = true);
    try {
      final lookup = await ref.read(billPaymentsApiProvider).lookup(_target);
      if (!mounted) return false;
      setState(() {
        _lookup = lookup;
        if (type.isPlanBased && !lookup.bundles.contains(_bundle)) {
          _bundle = null;
        }
        if (lookup.amountDue case final due?
            when due > 0 && _amountCtrl.text.isEmpty) {
          _amountCtrl.text = _trimAmount(due);
        }
      });
      return true;
    } on MeterSelectionRequired catch (choice) {
      final meter = await _pickMeter(choice.meters);
      if (meter == null || !mounted) return false;
      _meterNumber = meter;
      return _checkAccount();
    } on Object catch (error) {
      _toast(errorMessage(error));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay() async {
    _idempotencyKey ??= _newKey();
    setState(() => _phase = _Phase.placing);
    try {
      final order = await ref
          .read(billPaymentsApiProvider)
          .placeOrder(
            target: _target,
            amount: _amount!,
            idempotencyKey: _idempotencyKey!,
            bundle: _bundle?.value,
            channel: _wallet!.channel,
            savedAccountId: _selectedAccount?.id,
            propertyId: type.isPhoneAccount ? null : _propertyId,
          );
      if (!mounted) return;
      setState(() {
        _order = order;
        _phase =
            order.awaitingApproval || order.status == BillOrderStatus.processing
            ? _Phase.approving
            : _Phase.result;
      });
      if (_phase == _Phase.result) _settled(order);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _phase = _Phase.steps);
      _toast(errorMessage(error));
    }
  }

  /// The order has an answer (or has been waiting long enough): show it and
  /// bring history and saved accounts up to date.
  void _settled(BillOrder order) {
    setState(() {
      _order = order;
      _phase = _Phase.result;
    });
    unawaited(ref.read(transactionsProvider.notifier).refresh());
    if (order.status != BillOrderStatus.completed) return;
    final saved = _selectedAccount;
    if (saved != null) {
      unawaited(ref.read(accountsProvider.notifier).refresh());
    } else if (_saveNew) {
      unawaited(
        _savePayee(
          UtilityAccount(
            id: '',
            type: type,
            accountNumber: _lookup?.accountNumber ?? _accountNumber,
            nickname: _accountNickname,
            propertyId: type.isPhoneAccount ? null : _propertyId,
            network: type.isPhoneAccount ? _network : null,
            ecgKind: type == UtilityType.ecg
                ? (_postpaid ? EcgKind.postpaid : EcgKind.prepaid)
                : null,
          ),
        ),
      );
    }
  }

  void _retry() {
    setState(() {
      _idempotencyKey =
          null; // A declined order is final; try again with a new one.
      _order = null;
      _phase = _Phase.steps;
      _step = _stepCount - 1;
    });
  }

  /// Saving the payee is a convenience; a failure must not hide the receipt.
  Future<void> _savePayee(UtilityAccount draft) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(accountsProvider.notifier).add(draft);
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Paid, but the account was not saved: ${errorMessage(error)}',
          ),
        ),
      );
    }
  }

  void _toast(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  static String _newKey() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final order = _order;
    switch (_phase) {
      case _Phase.placing:
        return _WaitingView(
          title: 'Sending the payment request',
          message:
              'Your phone will ask you to approve ${Fmt.cedis(_amount ?? 0)}.',
        );
      case _Phase.approving when order != null:
        return _ApprovalView(
          order: order,
          payerPhone: _payerPhone,
          onSettled: _settled,
        );
      case _Phase.result when order != null:
        final saved = _selectedAccount;
        return PaymentResultView(
          transaction: order.toTransaction(
            nickname: saved?.nickname ?? (_enterNew ? _accountNickname : null),
            propertyLabel: ref
                .read(propertyByIdProvider(order.propertyId))
                ?.nickname,
          ),
          headline: order.headline,
          message: order.message,
          onRetry: _retry,
        );
      default:
        break;
    }

    return StepFlowScaffold(
      title: type.label,
      subtitle: type.providerName,
      step: _step,
      stepCount: _stepCount,
      onBack: _back,
      totalLabel: 'Total',
      totalValue: _step == 0 || _amount == null ? null : Fmt.cedis(_amount!),
      bottomBar: PrimaryButton(
        label: _step == _stepCount - 1 ? 'Confirm & pay' : 'Continue',
        busy: _busy,
        busyLabel: 'Checking',
        onPressed: _canContinue ? _continue : null,
      ),
      child: StepTransition(
        stepKey: _step,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Insets.xl),
          child: switch (_step) {
            0 => _buildAccountStep(),
            1 => _buildAmountStep(),
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
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
        Gaps.xl,
        for (final account in accounts) ...[
          SelectionTile(
            selected: !_enterNew && _selectedAccount?.id == account.id,
            onTap: () => setState(() {
              _choose(account);
              _lookup = null;
              _meterNumber = null;
            }),
            title: account.nickname,
            subtitle:
                '${Fmt.masked(account.accountNumber)}'
                '${account.lastPaidAt != null ? ' • ${Fmt.lastPaidLabel(account.lastPaidAt!)}' : ''}',
            leading: BillerMark(type, size: 40),
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
            _lookup = null;
            _meterNumber = null;
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
                  keyboardType: type.allowsLetters
                      ? TextInputType.text
                      : TextInputType.number,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      type.allowsLetters
                          ? RegExp(r'[A-Za-z\d\s]')
                          : RegExp(r'[\d\s]'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: type.accountLabel,
                    hintText: type.accountHint,
                  ),
                  onChanged: (value) => setState(() {
                    _lookup = null;
                    _meterNumber = null;
                    if (type.isPhoneAccount) {
                      _network = MobileNetwork.guess(value) ?? _network;
                    }
                  }),
                  validator: (v) => Validators.account(v, type),
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
                if (type == UtilityType.ecg)
                  SwitchListTile(
                    value: _postpaid,
                    onChanged: (v) => setState(() {
                      _postpaid = v;
                      _lookup = null;
                    }),
                    title: Text(
                      'This is a postpaid account',
                      style: theme.textTheme.bodyMedium,
                    ),
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: AppColors.navy,
                  ),
                SwitchListTile(
                  value: _saveNew,
                  onChanged: (v) => setState(() => _saveNew = v),
                  title: Text(
                    'Save for next time',
                    style: theme.textTheme.bodyMedium,
                  ),
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: AppColors.navy,
                ),
              ],
            ),
          ),
        ],
        if (type.isPhoneAccount && (_enterNew || _selectedAccount != null)) ...[
          Gaps.lg,
          Text('Network', style: theme.textTheme.titleSmall),
          Gaps.sm,
          _NetworkPicker(
            selected: _network,
            onSelected: (n) => setState(() {
              _network = n;
              _lookup = null;
            }),
          ),
        ],
      ],
    );
  }

  // Step 2 — amount or bundle -----------------------------------------------

  Widget _buildAmountStep() {
    final theme = Theme.of(context);
    final property = ref.watch(propertyByIdProvider(_propertyId));
    final lookup = _lookup;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          type.isPlanBased ? 'Choose a bundle' : 'How much?',
          style: theme.textTheme.headlineMedium,
        ),
        Gaps.lg,
        _PayingForCard(
          type: type,
          nickname: lookup?.customerName.isNotEmpty ?? false
              ? lookup!.customerName
              : _accountNickname,
          number: lookup?.accountNumber ?? _accountNumber,
          property: type.isPhoneAccount ? null : property,
          onChangeProperty: type.isPhoneAccount ? null : _pickProperty,
        ),
        if (lookup != null &&
            !lookup.nameConfirmed &&
            !type.isPhoneAccount) ...[
          Gaps.md,
          InfoBanner.warning(
            message:
                '${type.providerName} couldn\'t confirm who this ${type.accountLabel.toLowerCase()} '
                'belongs to. Check the number before you pay.',
          ),
        ],
        Gaps.xl,
        if (type.isPlanBased)
          ..._buildBundleChoices()
        else ...[
          if (lookup?.amountDue case final due? when due > 0) ...[
            Text(
              'Amount due: ${Fmt.cedis(due)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
              ),
            ),
            Gaps.md,
          ],
          AmountField(
            controller: _amountCtrl,
            quickAmounts: [
              for (final q in type.quickAmounts)
                if (q <= _maxAmount) q,
            ],
            onChanged: (_) => setState(() => _amountError = null),
          ),
          if (_amountError != null) ...[
            Gaps.lg,
            Text(
              _amountError!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.danger,
              ),
            ),
          ],
        ],
      ],
    );
  }

  List<Widget> _buildBundleChoices() {
    final bundles = _lookup?.bundles ?? const <BillBundle>[];
    if (bundles.isEmpty) {
      return [
        const InfoBanner.warning(
          message: 'No bundles are available for this number right now.',
        ),
      ];
    }
    return [
      for (final bundle in bundles) ...[
        SelectionTile(
          selected: _bundle == bundle,
          onTap: () => setState(() => _bundle = bundle),
          title: bundle.label,
          trailing: Text(
            Fmt.cedis(bundle.amount),
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

  Future<String?> _pickMeter(List<MeterChoice> meters) =>
      showAppBottomSheet<String>(
        context,
        title: 'Which meter?',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in meters) ...[
              SelectionTile(
                selected: false,
                onTap: () => Navigator.of(context).pop(m.meterNumber),
                title: m.customerName.isEmpty ? m.meterNumber : m.customerName,
                subtitle: m.meterNumber,
                leading: BillerMark(type, size: 40),
              ),
              Gaps.md,
            ],
          ],
        ),
      );

  Future<void> _pickWallet() async {
    final selected = await showAppBottomSheet<MobileNetwork>(
      context,
      title: 'Which wallet is on your number?',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final n in MobileNetwork.values) ...[
            SelectionTile(
              selected: n == _wallet,
              onTap: () => Navigator.of(context).pop(n),
              title: n.walletLabel,
              leading: const TintedIcon(
                Icons.account_balance_wallet_rounded,
                size: 40,
              ),
            ),
            Gaps.md,
          ],
        ],
      ),
    );
    if (selected != null) setState(() => _wallet = selected);
  }

  // Step 3 — review ---------------------------------------------------------

  Widget _buildReviewStep() {
    final theme = Theme.of(context);
    final property = ref.watch(propertyByIdProvider(_propertyId));
    final amount = _amount ?? 0;
    final lookup = _lookup;
    final chargePercent = lookup?.chargePercent ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review your payment', style: theme.textTheme.headlineMedium),
        Gaps.sm,
        Text(
          'Check everything before you confirm.',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
        Gaps.xl,
        AppCard(
          padding: const EdgeInsets.all(Insets.xl),
          child: Column(
            children: [
              BillerMark(type, size: 52),
              Gaps.md,
              Text(Fmt.cedis(amount), style: theme.textTheme.displaySmall),
              Text(
                type.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
              ),
              Gaps.lg,
              const DashedDivider(),
              Gaps.sm,
              ReceiptRow(
                label: type.accountLabel,
                value: lookup?.accountNumber ?? _accountNumber,
              ),
              if (lookup != null && lookup.customerName.isNotEmpty)
                ReceiptRow(label: 'Name', value: lookup.customerName),
              ReceiptRow(label: 'Nickname', value: _accountNickname),
              if (_bundle != null)
                ReceiptRow(label: 'Bundle', value: _bundle!.label),
              if (property != null && !type.isPhoneAccount)
                ReceiptRow(label: 'Home', value: property.nickname),
              ReceiptRow(
                label: 'Pay from',
                value: '',
                valueWidget: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _pickWallet,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      '${_wallet?.walletLabel ?? 'Choose'} • ${Fmt.ghanaPhone(_payerPhone)}',
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ),
              ReceiptRow(label: 'GRID fee', value: 'Free'),
              ReceiptRow(
                label: 'Network charge',
                value: chargePercent > 0
                    ? 'About ${chargePercent.toStringAsFixed(chargePercent % 1 == 0 ? 0 : 1)}%'
                    : 'Shown on the prompt',
              ),
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
        InfoBanner(
          icon: Icons.phone_iphone_rounded,
          message:
              'You\'ll get a prompt on ${Fmt.ghanaPhone(_payerPhone)} to approve this payment with your MoMo PIN.',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _NetworkPicker extends StatelessWidget {
  const _NetworkPicker({required this.selected, required this.onSelected});

  final MobileNetwork? selected;
  final ValueChanged<MobileNetwork> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Insets.sm,
      children: [
        for (final n in MobileNetwork.values)
          ChoiceChip(
            label: Text(n.label),
            selected: n == selected,
            onSelected: (_) => onSelected(n),
          ),
      ],
    );
  }
}

/// Waits for the customer to approve the prompt, then for the biller.
/// Polls the order with a short, steady interval; after a few minutes it
/// hands back whatever state the order is in so the customer isn't stuck.
class _ApprovalView extends ConsumerStatefulWidget {
  const _ApprovalView({
    required this.order,
    required this.payerPhone,
    required this.onSettled,
  });

  final BillOrder order;
  final String payerPhone;
  final ValueChanged<BillOrder> onSettled;

  @override
  ConsumerState<_ApprovalView> createState() => _ApprovalViewState();
}

class _ApprovalViewState extends ConsumerState<_ApprovalView> {
  static const _interval = Duration(seconds: 3);
  static const _giveUpAfter = Duration(minutes: 3);

  late BillOrder _order = widget.order;
  late final DateTime _started = DateTime.now();
  Timer? _timer;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_interval, (_) => _check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    try {
      final order = await ref.read(billPaymentsApiProvider).order(_order.id);
      if (!mounted) return;
      setState(() => _order = order);
      if (order.isFinal ||
          order.status == BillOrderStatus.refunding ||
          DateTime.now().difference(_started) >= _giveUpAfter) {
        _timer?.cancel();
        widget.onSettled(order);
      }
    } on Object {
      // Offline for a moment: the next tick tries again.
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final paid = _order.status == BillOrderStatus.processing;
    final amount = _order.amountCharged ?? _order.total;
    return _WaitingView(
      title: paid ? 'Payment received' : 'Approve on your phone',
      message: paid
          ? 'Paying ${_order.type.providerName}…'
          : 'Check ${Fmt.ghanaPhone(widget.payerPhone)} for a ${_order.walletLabel} prompt '
                'for ${Fmt.cedis(amount)} and enter your PIN.',
      footer: [
        TextButton(
          onPressed: _check,
          child: Text(paid ? 'Check again' : 'I\'ve approved it'),
        ),
        TextButton(
          onPressed: () {
            unawaited(ref.read(transactionsProvider.notifier).refresh());
            context.go(Routes.activity);
          },
          child: const Text('Continue in Activity'),
        ),
      ],
    );
  }
}

class _WaitingView extends StatelessWidget {
  const _WaitingView({
    required this.title,
    required this.message,
    this.footer = const [],
  });

  final String title;
  final String message;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
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
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                Gaps.sm,
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                if (footer.isNotEmpty) ...[Gaps.xl, ...footer],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
        color: type.brand.tint,
        borderRadius: Corners.lgRadius,
      ),
      child: Row(
        children: [
          BillerMark(type, size: 40),
          Gaps.md,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nickname, style: theme.textTheme.titleMedium),
                Text(
                  number.isEmpty ? type.accountHint : Fmt.masked(number),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
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
                    color: AppColors.navy,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
