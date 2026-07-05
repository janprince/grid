import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';

class AddEditPropertyScreen extends ConsumerStatefulWidget {
  const AddEditPropertyScreen({super.key, this.propertyId});

  final String? propertyId;

  @override
  ConsumerState<AddEditPropertyScreen> createState() =>
      _AddEditPropertyScreenState();
}

class _AddEditPropertyScreenState extends ConsumerState<AddEditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();

  Property? get _existing => widget.propertyId == null
      ? null
      : ref.read(propertyByIdProvider(widget.propertyId));

  late final _nicknameCtrl = TextEditingController(text: _existing?.nickname);
  late final _areaCtrl = TextEditingController(text: _existing?.area);
  late final _cityCtrl = TextEditingController(text: _existing?.city);
  late final _addressCtrl = TextEditingController(text: _existing?.address);
  late PropertyKind _kind = _existing?.kind ?? PropertyKind.house;
  late bool _isPrimary = _existing?.isPrimary ?? false;

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _areaCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final notifier = ref.read(propertiesProvider.notifier);
    final existing = _existing;

    if (existing == null) {
      final property = Property(
        id: 'p${DateTime.now().microsecondsSinceEpoch}',
        nickname: _nicknameCtrl.text.trim(),
        area: _areaCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        kind: _kind,
        isPrimary: _isPrimary,
      );
      notifier.add(property);
    } else {
      notifier.update(
        existing.copyWith(
          nickname: _nicknameCtrl.text.trim(),
          area: _areaCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          kind: _kind,
          isPrimary: _isPrimary,
        ),
      );
    }
    context.pop();
  }

  Future<void> _delete() async {
    final existing = _existing!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this home?'),
        content: Text(
          '"${existing.nickname}" will be removed. Its linked utility '
          'accounts stay saved but become unlinked.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && mounted) {
      ref.read(propertiesProvider.notifier).remove(existing.id);
      context.go('/properties');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _existing != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit home' : 'Add a home')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Insets.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<PropertyKind>(
                  segments: const [
                    ButtonSegment(
                      value: PropertyKind.house,
                      label: Text('House'),
                      icon: Icon(Icons.home_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: PropertyKind.apartment,
                      label: Text('Apartment'),
                      icon: Icon(Icons.apartment_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: PropertyKind.office,
                      label: Text('Office'),
                      icon: Icon(Icons.business_rounded, size: 18),
                    ),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (selection) =>
                      setState(() => _kind = selection.first),
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.mint,
                    selectedForegroundColor: AppColors.forestDeep,
                  ),
                ),
                Gaps.xl,
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
                TextFormField(
                  controller: _addressCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Street address',
                    hintText: 'e.g. 45 Mensah Wood Ave',
                  ),
                  validator: (v) => Validators.notEmpty(v, label: 'Address'),
                ),
                Gaps.lg,
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _areaCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Area',
                          hintText: 'e.g. East Legon',
                        ),
                        validator: (v) => Validators.notEmpty(v, label: 'Area'),
                      ),
                    ),
                    Gaps.md,
                    Expanded(
                      child: TextFormField(
                        controller: _cityCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          hintText: 'e.g. Accra',
                        ),
                        validator: (v) => Validators.notEmpty(v, label: 'City'),
                      ),
                    ),
                  ],
                ),
                Gaps.sm,
                SwitchListTile(
                  value: _isPrimary,
                  onChanged: (v) => setState(() => _isPrimary = v),
                  title: const Text('Primary home'),
                  subtitle: const Text('Selected by default across the app'),
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: AppColors.forest,
                ),
                Gaps.xl,
                FilledButton(
                  onPressed: _save,
                  child: Text(isEditing ? 'Save changes' : 'Add home'),
                ),
                if (isEditing) ...[
                  Gaps.sm,
                  TextButton.icon(
                    onPressed: _delete,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Remove home'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
