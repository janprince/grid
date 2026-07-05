import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/widgets.dart';

/// Add or edit a saved utility account.
Future<void> showAccountFormSheet(
  BuildContext context, {
  UtilityAccount? existing,
}) {
  return showAppBottomSheet(
    context,
    title: existing == null ? 'Add account' : 'Edit account',
    child: _AccountForm(existing: existing),
  );
}

class _AccountForm extends ConsumerStatefulWidget {
  const _AccountForm({this.existing});

  final UtilityAccount? existing;

  @override
  ConsumerState<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends ConsumerState<_AccountForm> {
  final _formKey = GlobalKey<FormState>();
  late UtilityType _type = widget.existing?.type ?? UtilityType.ecg;
  late final _numberCtrl = TextEditingController(
    text: widget.existing?.accountNumber,
  );
  late final _nicknameCtrl = TextEditingController(
    text: widget.existing?.nickname,
  );
  late String? _propertyId = widget.existing?.propertyId;
  late bool _isDefault = widget.existing?.isDefault ?? false;

  @override
  void dispose() {
    _numberCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final notifier = ref.read(accountsProvider.notifier);
    final number = _numberCtrl.text.replaceAll(RegExp(r'\s'), '');
    final nickname = _nicknameCtrl.text.trim();

    if (widget.existing == null) {
      notifier.add(
        UtilityAccount(
          id: 'a${DateTime.now().microsecondsSinceEpoch}',
          type: _type,
          accountNumber: number,
          nickname: nickname,
          propertyId: _propertyId,
          isDefault: _isDefault,
        ),
      );
    } else {
      notifier.update(
        widget.existing!.copyWith(
          type: _type,
          accountNumber: number,
          nickname: nickname,
          propertyId: _propertyId,
          clearProperty: _propertyId == null,
          isDefault: _isDefault,
        ),
      );
    }
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this account?'),
        content: Text(
          '"${widget.existing!.nickname}" will be removed from your '
          'saved accounts. Past payments are kept in Activity.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && mounted) {
      ref.read(accountsProvider.notifier).remove(widget.existing!.id);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final properties = ref.watch(propertiesProvider);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<UtilityType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Utility'),
              items: [
                for (final type in UtilityType.values)
                  DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(type.icon, size: 18, color: AppColors.teal),
                        Gaps.sm,
                        Text(type.label),
                      ],
                    ),
                  ),
              ],
              onChanged: widget.existing == null
                  ? (type) => setState(() => _type = type!)
                  : null,
            ),
            Gaps.lg,
            TextFormField(
              controller: _numberCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d\s]')),
              ],
              decoration: InputDecoration(
                labelText: _type.accountLabel,
                hintText: _type.accountHint,
              ),
              validator: (v) => _type.isPhoneAccount
                  ? Validators.ghanaPhone(v)
                  : Validators.digits(
                      v,
                      min: _type.minDigits,
                      max: _type.maxDigits,
                      label: _type.accountLabel,
                    ),
            ),
            Gaps.lg,
            TextFormField(
              controller: _nicknameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nickname',
                hintText: "e.g. My Home, Mum's House",
              ),
              validator: (v) => Validators.notEmpty(v, label: 'Nickname'),
            ),
            Gaps.lg,
            DropdownButtonFormField<String?>(
              initialValue: _propertyId,
              decoration: const InputDecoration(
                labelText: 'Linked home (optional)',
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Not linked'),
                ),
                for (final property in properties)
                  DropdownMenuItem<String?>(
                    value: property.id,
                    child: Text('${property.nickname} — ${property.location}'),
                  ),
              ],
              onChanged: (id) => setState(() => _propertyId = id),
            ),
            Gaps.sm,
            SwitchListTile(
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
              title: Text(
                'Default for ${_type.label}',
                style: theme.textTheme.bodyMedium,
              ),
              subtitle: Text(
                'Preselected when you pay',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.inkFaint,
                ),
              ),
              contentPadding: EdgeInsets.zero,
              activeTrackColor: AppColors.forest,
            ),
            Gaps.lg,
            FilledButton(
              onPressed: _save,
              child: Text(
                widget.existing == null ? 'Save account' : 'Save changes',
              ),
            ),
            if (widget.existing != null) ...[
              Gaps.sm,
              TextButton.icon(
                onPressed: _delete,
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Delete account'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
