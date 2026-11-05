import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/api/api_exception.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';

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

  bool _saving = false;
  Map<String, String> _fieldErrors = const {};
  String? _error;

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final notifier = ref.read(propertiesProvider.notifier);
    final existing = _existing;
    setState(() {
      _saving = true;
      _fieldErrors = const {};
      _error = null;
    });

    try {
      if (existing == null) {
        await notifier.add(
          Property(
            id: '',
            nickname: _nicknameCtrl.text.trim(),
            area: _areaCtrl.text.trim(),
            city: _cityCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
            kind: _kind,
          ),
          makePrimary: _isPrimary,
        );
      } else {
        await notifier.save(
          existing.copyWith(
            nickname: _nicknameCtrl.text.trim(),
            area: _areaCtrl.text.trim(),
            city: _cityCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
            kind: _kind,
          ),
          makePrimary: _isPrimary,
        );
      }
      if (mounted) context.pop();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _fieldErrors = error is ApiException ? error.fieldErrors : const {};
        _error = _fieldErrors.isEmpty ? errorMessage(error) : null;
      });
    }
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
    if (!(confirmed ?? false) || !mounted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(propertiesProvider.notifier).remove(existing.id);
      if (mounted) context.go('/properties');
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = errorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _existing != null;

    return Scaffold(
      appBar: AppHeader(
        title: isEditing ? 'Edit home' : 'Add a home',
        onBack: () => Navigator.of(context).maybePop(),
      ),
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
                    selectedBackgroundColor: AppColors.navySoft,
                    selectedForegroundColor: AppColors.navy,
                  ),
                ),
                Gaps.xl,
                TextFormField(
                  controller: _nicknameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    errorText: _fieldErrors['nickname'],
                    labelText: 'Nickname',
                    hintText: "e.g. My Home, Mum's House",
                  ),
                  validator: (v) => Validators.notEmpty(v, label: 'Nickname'),
                ),
                Gaps.lg,
                TextFormField(
                  controller: _addressCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    errorText: _fieldErrors['address'],
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
                        decoration: InputDecoration(
                          errorText: _fieldErrors['area'],
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
                        decoration: InputDecoration(
                          errorText: _fieldErrors['city'],
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
                  // The primary home only changes by choosing another one.
                  onChanged: (_existing?.isPrimary ?? false)
                      ? null
                      : (v) => setState(() => _isPrimary = v),
                  title: const Text('Primary home'),
                  subtitle: const Text('Selected by default across the app'),
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: AppColors.navy,
                ),
                if (_error case final error?) ...[
                  Gaps.lg,
                  InfoBanner.warning(message: error),
                ],
                Gaps.xl,
                PrimaryButton(
                  label: isEditing ? 'Save changes' : 'Add home',
                  busy: _saving,
                  onPressed: _save,
                ),
                if (isEditing) ...[
                  Gaps.sm,
                  TextButton.icon(
                    onPressed: _saving ? null : _delete,
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
