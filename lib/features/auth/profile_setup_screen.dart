import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';

class ProfileSetupArgs {
  const ProfileSetupArgs({this.phone, this.email});

  final String? phone;
  final String? email;
}

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key, required this.args});

  final ProfileSetupArgs args;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  bool _saving = false;

  bool get _needsPhone => widget.args.phone == null;

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final phone =
        widget.args.phone ?? Validators.normalizePhone(_contactController.text);
    final email =
        widget.args.email ??
        (_contactController.text.contains('@')
            ? _contactController.text.trim()
            : null);

    await ref
        .read(sessionProvider.notifier)
        .signIn(name: _nameController.text.trim(), phone: phone, email: email);
    // The router redirect takes over and lands on the dashboard.
    if (mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Set up your profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Insets.xxl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Almost there', style: theme.textTheme.headlineMedium),
                    Gaps.sm,
                    Text(
                      'Tell us who keeps this home running.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                    Gaps.xxl,
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        hintText: 'e.g. Kwame Mensah',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) =>
                          Validators.notEmpty(v, label: 'Your name'),
                    ),
                    Gaps.lg,
                    if (_needsPhone)
                      TextFormField(
                        controller: _contactController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          hintText: '+233 55 123 4567',
                          prefixIcon: Icon(Icons.smartphone_rounded),
                        ),
                        validator: Validators.ghanaPhone,
                      )
                    else
                      TextFormField(
                        controller: _contactController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email (optional)',
                          hintText: 'you@example.com',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? null
                            : Validators.email(v),
                      ),
                    Gaps.xxl,
                    FilledButton(
                      onPressed: _saving ? null : _finish,
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Enter GRID'),
                    ),
                    Gaps.lg,
                    const InfoBanner(
                      message:
                          'Your demo account comes with example homes, saved '
                          'meters and history so you can explore right away.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
