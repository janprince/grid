import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/api/api_exception.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import 'widgets/bundle_grid.dart';
import 'widgets/pay_flow_parts.dart';
import 'widgets/pay_pending_view.dart';
import 'widgets/payment_result_view.dart';

enum _Phase { steps, placing, approving, result }

/// One flow for every bill. The [UtilityType] drives labels and validation.
///
/// Each screen asks one thing: whose account (checked with the biller), then
/// how much or which bundle. A sheet then shows everything once more with the
/// wallet that pays; confirming sends a MoMo prompt to the signed-in number
/// and the screen waits for the approval and the biller's answer.
class PaymentFlowScreen extends ConsumerStatefulWidget {
  const PaymentFlowScreen({
    super.key,
    required this.type,
    this.initialAccountId,
    this.network,
  });

  final UtilityType type;

  /// When set (e.g. "Pay again" or a saved-account card), the account is
  /// preselected and checked straight away.
  final String? initialAccountId;

  /// The network picked before the flow, for airtime and data.
  final MobileNetwork? network;

  @override
  ConsumerState<PaymentFlowScreen> createState() => _PaymentFlowScreenState();
}

class _PaymentFlowScreenState extends ConsumerState<PaymentFlowScreen> {
  _Phase _phase = _Phase.steps;
  int _step = 0;
  bool _busy = false;

  // Step 1 — whose account
  UtilityAccount? _selectedAccount;
  final _form = GlobalKey<FormState>();
  final _numberCtrl = TextEditingController();
  bool _useMyNumber = false;
  String? _contactName;
  bool _saveNew = true;
  bool _postpaid = false;
  late MobileNetwork? _network;
  String? _propertyId;

  /// What the biller said about the chosen account.
  BillLookup? _lookup;
  String? _meterNumber;

  // Step 2 — amount / bundle
  final _amountCtrl = TextEditingController();
  BillBundle? _bundle;
  String? _amountError;

  /// The wallet that pays.
  late MobileNetwork _wallet;

  /// One key per confirmation, so a double tap or a retried request can't
  /// place two orders.
  String? _idempotencyKey;
  BillOrder? _order;

  UtilityType get type => widget.type;

  String get _payerPhone => ref.read(sessionProvider).user?.phone ?? '';
  String get _payerName => ref.read(sessionProvider).user?.name ?? '';

  @override
  void initState() {
    super.initState();
    _propertyId = ref.read(selectedPropertyProvider)?.id;
    _wallet = MobileNetwork.guess(_payerPhone) ?? MobileNetwork.mtn;
    _network = type.isPhoneAccount
        ? widget.network ?? MobileNetwork.guess(_payerPhone)
        : null;
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
    _amountCtrl.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Derived state
  // -------------------------------------------------------------------------

  String get _accountNumber =>
      _selectedAccount?.accountNumber ??
      _numberCtrl.text.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();

  /// Who the person is paying, in the words they'd use.
  String get _recipientName {
    final saved = _selectedAccount;
    if (type.isPhoneAccount) {
      if (_contactName case final name? when name.trim().isNotEmpty) {
        return name.trim();
      }
      if (saved != null) return saved.nickname;
      return _useMyNumber ? 'My number' : '${_network?.label ?? ''} number';
    }
    final name = _lookup?.customerName.trim() ?? '';
    if (name.isNotEmpty) return name;
    return saved?.nickname ?? 'My ${type.accountLabel.toLowerCase()}';
  }

  /// The name a new account is saved under.
  String get _newNickname {
    if (type.isPhoneAccount) {
      return _useMyNumber && _contactName == null
          ? 'My number'
          : _recipientName;
    }
    final name = _lookup?.customerName.trim() ?? '';
    return name.isEmpty
        ? 'My ${type.accountLabel.toLowerCase()}'
        : _titleCase(name);
  }

  static String _titleCase(String value) => value
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  /// "200.00" reads as noise at display size; "200" is the amount.
  static String _trimAmount(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  /// `+233 55 123 4567`, `233551234567` → `0551234567`.
  static String _localPhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('233')) digits = digits.substring(3);
    if (digits.length == 9) digits = '0$digits';
    return digits;
  }

  double? get _amount => type.isPlanBased
      ? _bundle?.amount
      : double.tryParse(_amountCtrl.text.replaceAll(',', ''));

  double get _minAmount => _lookup?.minAmount ?? 1;
  double get _maxAmount => _lookup?.maxAmount ?? 1000;

  bool get _amountValid =>
      Validators.amount(_amountCtrl.text, min: _minAmount, max: _maxAmount) ==
      null;

  BillTarget get _target {
    final ecgKind =
        _selectedAccount?.ecgKind ??
        (_postpaid ? EcgKind.postpaid : EcgKind.prepaid);
    final target = BillTarget(
      productCode: billProductCode(
        type,
        network: type.isPhoneAccount
            ? (_network ?? MobileNetwork.guess(_accountNumber))
            : null,
        ecgKind: ecgKind,
      ),
      accountNumber: _accountNumber,
    );
    return _meterNumber == null ? target : target.withMeter(_meterNumber!);
  }

  /// Saved accounts for this flow; for airtime and data, on this network.
  List<UtilityAccount> get _saved => ref
      .watch(accountsByTypeProvider(type))
      .where(
        (a) =>
            !type.isPhoneAccount ||
            (a.network ?? MobileNetwork.guess(a.accountNumber)) == _network,
      )
      .toList();

  void _choose(UtilityAccount account) {
    _selectedAccount = account;
    _numberCtrl.text = account.accountNumber;
    _contactName = null;
    _useMyNumber = false;
    _network = type.isPhoneAccount
        ? account.network ??
              MobileNetwork.guess(account.accountNumber) ??
              _network
        : null;
    _propertyId = account.propertyId ?? _propertyId;
    _lookup = null;
    _meterNumber = null;
    if (account.lastAmount != null &&
        !type.isPlanBased &&
        _amountCtrl.text.isEmpty) {
      _amountCtrl.text = _trimAmount(account.lastAmount!);
    }
  }

  /// The number typed or picked changed: whatever was known about the old
  /// one no longer applies.
  void _numberChanged() {
    _selectedAccount = null;
    _lookup = null;
    _meterNumber = null;
  }

  // -------------------------------------------------------------------------
  // Navigation
  // -------------------------------------------------------------------------

  void _back() {
    if (_phase != _Phase.steps || _busy) return;
    if (_step > 0) {
      setState(() => _step = 0);
    } else {
      context.pop();
    }
  }

  Future<void> _continue() async {
    if (_step == 0) {
      if (_selectedAccount == null) {
        if (!(_form.currentState?.validate() ?? false)) return;
        // A number typed in full that is already saved pays as that account.
        final match = ref
            .read(accountsByTypeProvider(type))
            .where((a) => a.accountNumber.toUpperCase() == _accountNumber)
            .firstOrNull;
        if (match != null) _selectedAccount = match;
      }
      FocusScope.of(context).unfocus();
      if (await _checkAccount()) setState(() => _step = 1);
      return;
    }
    if (!type.isPlanBased) {
      final error = Validators.amount(
        _amountCtrl.text,
        min: _minAmount,
        max: _maxAmount,
      );
      setState(() => _amountError = error);
      if (error != null) return;
    }
    await _confirm();
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

  /// Everything once more, with the wallet that pays. Confirming pays.
  Future<void> _confirm() async {
    final amount = _amount;
    if (amount == null) return;
    final lookup = _lookup;
    final confirmed = await showModalBottomSheet<_Confirmed>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _ConfirmSheet(
        type: type,
        amount: amount,
        chargePercent: lookup?.chargePercent ?? 0,
        wallet: _wallet,
        payerPhone: _payerPhone,
        payerName: _payerName,
        propertyId: type.isPhoneAccount ? null : _propertyId,
        rows: [
          if (type.isPhoneAccount) ...[
            ('Recipient', Fmt.ghanaPhone(_accountNumber)),
            if (_contactName != null || _selectedAccount != null)
              ('Name', _recipientName),
            ('Network', _network?.label ?? ''),
          ] else ...[
            (type.accountLabel, lookup?.accountNumber ?? _accountNumber),
            if (lookup != null && lookup.customerName.isNotEmpty)
              ('Name', lookup.customerName),
          ],
          if (_bundle != null) ('Bundle', BundleFacts.of(_bundle!).summary),
          (
            type.isPlanBased ? 'Price' : '${type.shortNoun} amount',
            Fmt.cedis(amount),
          ),
        ],
      ),
    );
    if (confirmed == null || !mounted) return;
    setState(() {
      _wallet = confirmed.wallet;
      _propertyId = confirmed.propertyId ?? _propertyId;
    });
    await _pay();
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
            channel: _wallet.channel,
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
            nickname: _newNickname,
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

  /// Leaves the wait; the order carries on and Activity shows how it ends.
  void _leaveWait() {
    unawaited(ref.read(transactionsProvider.notifier).refresh());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Still going. Activity will show how it ends.'),
      ),
    );
    context.go(Routes.activity);
  }

  void _retry() {
    setState(() {
      _idempotencyKey =
          null; // A declined order is final; try again with a new one.
      _order = null;
      _phase = _Phase.steps;
      _step = 1;
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

  Future<void> _pickContact() async {
    try {
      final contact = await FlutterNativeContactPicker().selectPhoneNumber();
      final raw =
          contact?.selectedPhoneNumber ?? contact?.phoneNumbers?.firstOrNull;
      if (raw == null || !mounted) return;
      setState(() {
        _numberChanged();
        _useMyNumber = false;
        _numberCtrl.text = _localPhone(raw);
        _contactName = contact?.fullName;
      });
      _form.currentState?.validate();
    } on Object {
      _toast('Couldn\'t open your contacts. Type the number instead.');
    }
  }

  void _toggleMyNumber(bool on) => setState(() {
    _numberChanged();
    _useMyNumber = on;
    _contactName = null;
    _numberCtrl.text = on ? _localPhone(_payerPhone) : '';
  });

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

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final order = _order;
    switch (_phase) {
      case _Phase.placing:
        return PayPendingView(
          title: 'Sending the payment request',
          message:
              'Your phone will ask you to approve ${Fmt.cedis(_amount ?? 0)}.',
          wallet: _wallet,
          footer: const SizedBox(height: 52),
        );
      case _Phase.approving when order != null:
        return _ApprovalPoller(
          order: order,
          payerPhone: _payerPhone,
          wallet: _wallet,
          onSettled: _settled,
          onLeave: _leaveWait,
        );
      case _Phase.result when order != null:
        final saved = _selectedAccount;
        return PaymentResultView(
          transaction: order.toTransaction(
            nickname: saved?.nickname ?? _newNickname,
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

    final lookup = _lookup;
    return PayFlowScaffold(
      title: type.flowTitle,
      onBack: _back,
      onClose: _busy ? null : () => context.pop(),
      canPop: false,
      above: _step == 0
          ? const PayFootnote(
              'No GRID fee. You pay from your Mobile Money.',
              icon: Icons.verified_user_outlined,
            )
          : RecipientChip(
              type: type,
              network: _network,
              name: _recipientName,
              number: lookup?.accountNumber ?? _accountNumber,
              onTap: _back,
            ),
      action: _step == 1 && type.isPlanBased
          ? null
          : PrimaryButton(
              label: 'Continue',
              busy: _busy,
              busyLabel: 'Checking',
              onPressed: _step == 0 || _amountValid ? _continue : null,
            ),
      body: StepTransition(
        stepKey: _step,
        child: switch (_step) {
          0 => _buildAccountStep(),
          _ when type.isPlanBased => _buildBundleStep(),
          _ => _buildAmountStep(),
        },
      ),
    );
  }

  // Step 1 — whose account ----------------------------------------------------

  Widget _buildAccountStep() {
    final saved = _saved;
    final network = _network;
    final guessed = type.isPhoneAccount
        ? MobileNetwork.guess(_numberCtrl.text)
        : null;
    final title = type.isPhoneAccount
        ? 'Recipient\'s ${network?.label ?? 'phone'} number'
        : type.accountLabel;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Insets.xl,
        Insets.md,
        Insets.xl,
        Insets.xl,
      ),
      children: [
        PayCard(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: AppText.title.copyWith(fontSize: 22)),
                Gaps.sm,
                Text(type.accountPrompt, style: AppText.bodyMuted),
                Gaps.xl,
                if (type.isPhoneAccount && _payerPhone.isNotEmpty) ...[
                  _SwitchRow(
                    label: 'Use my number',
                    value: _useMyNumber,
                    onChanged: _toggleMyNumber,
                  ),
                  Gaps.md,
                ],
                TextFormField(
                  controller: _numberCtrl,
                  readOnly: _useMyNumber,
                  keyboardType: type.allowsLetters
                      ? TextInputType.text
                      : TextInputType.phone,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      type.allowsLetters
                          ? RegExp(r'[A-Za-z\d\s]')
                          : RegExp(r'[\d\s+]'),
                    ),
                  ],
                  style: AppText.body.copyWith(
                    fontSize: 17,
                    fontFeatures: AppText.tabularFigures,
                    color: _useMyNumber ? AppColors.muted : AppColors.ink,
                  ),
                  decoration: InputDecoration(
                    labelText: type.isPhoneAccount
                        ? 'Recipient ${network?.label ?? ''} number'
                        : type.accountLabel,
                    hintText: type.accountHint,
                    fillColor: _useMyNumber
                        ? AppColors.surfaceSubtle
                        : AppColors.surface,
                  ),
                  onChanged: (_) => setState(() {
                    _numberChanged();
                    _contactName = null;
                  }),
                  onFieldSubmitted: (_) => _continue(),
                  validator: (v) => Validators.account(v, type),
                ),
                if (guessed != null &&
                    network != null &&
                    guessed != network) ...[
                  Gaps.sm,
                  Text(
                    'This looks like a ${guessed.label} number. If it moved '
                    'to ${network.label}, carry on.',
                    style: AppText.caption.copyWith(
                      color: AppColors.warningText,
                    ),
                  ),
                ],
                if (type == UtilityType.ecg && _selectedAccount == null) ...[
                  Gaps.md,
                  _SwitchRow(
                    label: 'This is a postpaid meter',
                    value: _postpaid,
                    onChanged: (v) => setState(() {
                      _postpaid = v;
                      _lookup = null;
                    }),
                  ),
                ],
                if (_selectedAccount == null) ...[
                  Gaps.xs,
                  _SwitchRow(
                    label: 'Save for next time',
                    value: _saveNew,
                    onChanged: (v) => setState(() => _saveNew = v),
                  ),
                ],
                if (type.isPhoneAccount) ...[
                  Gaps.sm,
                  Center(
                    child: TextButton.icon(
                      onPressed: _pickContact,
                      icon: const Icon(Icons.person_search_rounded, size: 22),
                      label: const Text('Choose from contacts'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        textStyle: AppText.subtitle.copyWith(fontSize: 15.5),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (saved.isNotEmpty) ...[
          Gaps.xxl,
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: Insets.md),
            child: Text(
              type.isPhoneAccount ? 'SAVED NUMBERS' : 'SAVED',
              style: AppText.overline,
            ),
          ),
          PayCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                for (var i = 0; i < saved.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, indent: 72, endIndent: 16),
                  _SavedRow(
                    account: saved[i],
                    selected: _selectedAccount?.id == saved[i].id,
                    onTap: _busy
                        ? null
                        : () {
                            setState(() => _choose(saved[i]));
                            _continue();
                          },
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Step 2 — amount -----------------------------------------------------------

  Widget _buildAmountStep() {
    final lookup = _lookup;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        Insets.xl,
        Insets.md,
        Insets.xl,
        Insets.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PayHeading(
            type == UtilityType.airtime ? 'How much airtime?' : 'How much?',
          ),
          if (lookup != null &&
              !lookup.nameConfirmed &&
              !type.isPhoneAccount) ...[
            Gaps.lg,
            InfoBanner.warning(
              message:
                  '${type.providerName} couldn\'t confirm who this '
                  '${type.accountLabel.toLowerCase()} belongs to. Check the '
                  'number before you pay.',
            ),
          ],
          if (lookup?.amountDue case final due? when due > 0) ...[
            Gaps.md,
            Text('Amount due: ${Fmt.cedis(due)}', style: AppText.bodyMuted),
          ],
          const SizedBox(height: 44),
          AmountField(
            controller: _amountCtrl,
            underline: true,
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
              style: AppText.caption.copyWith(
                color: AppColors.danger,
                fontSize: 13.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Step 2 — bundle -----------------------------------------------------------

  Widget _buildBundleStep() {
    final bundles = _lookup?.bundles ?? const <BillBundle>[];
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Insets.xl,
        Insets.md,
        Insets.xl,
        Insets.xl,
      ),
      children: [
        const PayHeading('Choose a bundle'),
        Gaps.xl,
        if (bundles.isEmpty)
          const InfoBanner.warning(
            message: 'No bundles are available for this number right now.',
          )
        else
          BundleGrid(
            bundles: bundles,
            selected: _bundle,
            onSelected: (bundle) {
              setState(() => _bundle = bundle);
              _confirm();
            },
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

extension on UtilityType {
  /// "Airtime amount", "Top-up amount" — what the money is called.
  String get shortNoun => switch (this) {
    UtilityType.airtime => 'Airtime',
    UtilityType.ecg || UtilityType.internet => 'Top-up',
    _ => 'Bill',
  };
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: InkWell(
      onTap: () => onChanged(!value),
      borderRadius: Corners.smRadius,
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.body)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.navy,
          ),
        ],
      ),
    ),
  );
}

class _SavedRow extends StatelessWidget {
  const _SavedRow({
    required this.account,
    required this.selected,
    required this.onTap,
  });

  final UtilityAccount account;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final number = account.type.isPhoneAccount
        ? Fmt.ghanaPhone(account.accountNumber)
        : account.accountNumber;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            BillerMark(account.type, size: 40, network: account.network),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.subtitle,
                  ),
                  Text(
                    account.lastPaidAt == null
                        ? number
                        : '$number · ${Fmt.lastPaidLabel(account.lastPaidAt!)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(
                      fontFeatures: AppText.tabularFigures,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.chevron_right_rounded,
              color: selected ? AppColors.navy : AppColors.faint,
            ),
          ],
        ),
      ),
    );
  }
}

typedef _Confirmed = ({MobileNetwork wallet, String? propertyId});

/// The last look before paying: the wallet that will be prompted, what is
/// being paid for, and the amount, with one button that says what it does.
class _ConfirmSheet extends ConsumerStatefulWidget {
  const _ConfirmSheet({
    required this.type,
    required this.amount,
    required this.chargePercent,
    required this.wallet,
    required this.payerPhone,
    required this.payerName,
    required this.propertyId,
    required this.rows,
  });

  final UtilityType type;
  final double amount;
  final double chargePercent;
  final MobileNetwork wallet;
  final String payerPhone;
  final String payerName;

  /// The home the bill belongs to; null for airtime and data.
  final String? propertyId;
  final List<(String, String)> rows;

  @override
  ConsumerState<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends ConsumerState<_ConfirmSheet> {
  late MobileNetwork _wallet = widget.wallet;
  late String? _propertyId = widget.propertyId;

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
              leading: NetworkMark(n),
            ),
            Gaps.md,
          ],
        ],
      ),
    );
    if (selected != null) setState(() => _wallet = selected);
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

  @override
  Widget build(BuildContext context) {
    final property = ref.watch(propertyByIdProvider(_propertyId));
    final charge = widget.chargePercent;
    final name = widget.payerName.trim();
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        Insets.xl,
        Insets.lg,
        Insets.xl,
        MediaQuery.paddingOf(context).bottom + Insets.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: Text('Confirm payment', style: AppText.title)),
              NavChip(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icons.close_rounded,
                tooltip: 'Close',
              ),
            ],
          ),
          Gaps.lg,
          Semantics(
            button: true,
            label:
                'Pay from ${_wallet.walletLabel}, '
                '${Fmt.ghanaPhone(widget.payerPhone)}. Change wallet',
            excludeSemantics: true,
            child: InkWell(
              onTap: _pickWallet,
              borderRadius: Corners.lgRadius,
              child: Container(
                padding: const EdgeInsets.all(Insets.md),
                decoration: BoxDecoration(
                  borderRadius: Corners.lgRadius,
                  border: Border.all(color: AppColors.lineStrong),
                ),
                child: Row(
                  children: [
                    NetworkMark(_wallet, size: 48),
                    Gaps.lg,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Fmt.ghanaPhone(widget.payerPhone),
                            style: AppText.heading.copyWith(
                              fontFeatures: AppText.tabularFigures,
                            ),
                          ),
                          Text(
                            name.isEmpty
                                ? _wallet.walletLabel
                                : '${_wallet.walletLabel} · $name',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption.copyWith(fontSize: 13.5),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.edit_outlined, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Gaps.xl,
          for (final (label, value) in widget.rows)
            PaySummaryRow(label: label, value: value),
          if (property != null)
            PaySummaryRow(
              label: 'For',
              value: property.nickname,
              trailing: InkWell(
                onTap: _pickProperty,
                borderRadius: Corners.smRadius,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    'Change',
                    style: AppText.body.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          const PaySummaryRow(
            label: 'GRID fee',
            value: 'Free',
            valueColor: AppColors.success,
          ),
          PaySummaryRow(
            label: 'Network charge',
            value: charge > 0
                ? 'About ${charge.toStringAsFixed(charge % 1 == 0 ? 0 : 1)}%'
                : 'Shown on the prompt',
            valueColor: AppColors.muted,
          ),
          const Divider(height: 28),
          PaySummaryRow(
            label: 'Amount to pay',
            value: Fmt.cedis(widget.amount),
            strong: true,
          ),
          Gaps.xl,
          PrimaryButton(
            label: 'Pay ${Fmt.cedis(widget.amount)}',
            onPressed: () => Navigator.of(
              context,
            ).pop<_Confirmed>((wallet: _wallet, propertyId: _propertyId)),
          ),
          Gaps.md,
          Text(
            'You\'ll approve it with your MoMo PIN.',
            textAlign: TextAlign.center,
            style: AppText.caption,
          ),
        ],
      ),
    );
  }
}

/// Waits for the customer to approve the prompt, then for the biller.
/// Polls the order with a short, steady interval; after a few minutes it
/// hands back whatever state the order is in so the customer isn't stuck.
class _ApprovalPoller extends ConsumerStatefulWidget {
  const _ApprovalPoller({
    required this.order,
    required this.payerPhone,
    required this.wallet,
    required this.onSettled,
    required this.onLeave,
  });

  final BillOrder order;
  final String payerPhone;
  final MobileNetwork wallet;
  final ValueChanged<BillOrder> onSettled;
  final VoidCallback onLeave;

  @override
  ConsumerState<_ApprovalPoller> createState() => _ApprovalPollerState();
}

class _ApprovalPollerState extends ConsumerState<_ApprovalPoller> {
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
    return PayPendingView(
      title: paid ? 'Payment received' : 'Approve on your phone',
      message: paid
          ? 'We\'re paying ${_order.type.providerName} now. This usually '
                'takes a few seconds.'
          : 'To finish paying ${Fmt.cedis(amount)}, enter your '
                '${_order.walletLabel} PIN in the prompt sent to:',
      phone: paid ? null : widget.payerPhone,
      wallet: MobileNetwork.fromChannel(_order.channel) ?? widget.wallet,
      approved: paid,
      onClose: widget.onLeave,
    );
  }
}
