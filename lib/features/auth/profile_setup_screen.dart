import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/api/api_exception.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';

/// Shown after the first sign-in, until the person has given their name.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final AppUser? _user = ref.read(sessionProvider).user;
  // Prefilled when the person already gave a name in GRID Pro.
  late final _firstNameController = TextEditingController(
    text: _user?.firstName,
  );
  late final _lastNameController = TextEditingController(text: _user?.lastName);
  late final _emailController = TextEditingController(text: _user?.email);
  bool _saving = false;
  Map<String, String> _fieldErrors = const {};
  String? _error;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  static String? _orNull(String value) =>
      value.trim().isEmpty ? null : value.trim();

  Future<void> _finish() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _fieldErrors = const {};
      _error = null;
    });

    try {
      // The router redirect takes over and lands on the dashboard.
      await ref
          .read(sessionProvider.notifier)
          .completeProfile(
            firstName: _firstNameController.text.trim(),
            lastName: _orNull(_lastNameController.text),
            email: _orNull(_emailController.text),
          );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _fieldErrors = error.fieldErrors;
        _error = error.fieldErrors.isEmpty ? error.message : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Set up your profile'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Insets.xl),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ScreenIntro(
                      title: 'Almost there',
                      subtitle: 'Tell us who keeps this home running.',
                    ),
                    Gaps.xxl,
                    TextFormField(
                      controller: _firstNameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.givenName],
                      decoration: InputDecoration(
                        labelText: 'First name',
                        hintText: 'e.g. Kwame',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        errorText: _fieldErrors['firstName'],
                      ),
                      validator: (v) =>
                          Validators.notEmpty(v, label: 'Your first name'),
                    ),
                    Gaps.lg,
                    TextFormField(
                      controller: _lastNameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.familyName],
                      decoration: InputDecoration(
                        labelText: 'Last name (optional)',
                        hintText: 'e.g. Mensah',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        errorText: _fieldErrors['lastName'],
                      ),
                    ),
                    Gaps.lg,
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: 'Email (optional)',
                        hintText: 'you@example.com',
                        prefixIcon: const Icon(Icons.mail_outline_rounded),
                        errorText: _fieldErrors['email'],
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? null
                          : Validators.email(v),
                      onFieldSubmitted: (_) => _finish(),
                    ),
                    if (_error case final error?) ...[
                      Gaps.lg,
                      InfoBanner.warning(message: error),
                    ],
                    Gaps.xxl,
                    PrimaryButton(
                      label: 'Enter GRID',
                      busy: _saving,
                      onPressed: _finish,
                    ),
                    Gaps.sm,
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => ref.read(sessionProvider.notifier).signOut(),
                      child: const Text('Use a different number'),
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
