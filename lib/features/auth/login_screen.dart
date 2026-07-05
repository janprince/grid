import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import 'otp_screen.dart';

enum _LoginMode { phone, email }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  _LoginMode _mode = _LoginMode.phone;
  bool _sending = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);

    final isEmail = _mode == _LoginMode.email;
    final destination = isEmail
        ? _emailController.text.trim()
        : Validators.normalizePhone(_phoneController.text);
    final display = isEmail ? destination : Fmt.ghanaPhone(destination);

    await ref.read(authApiProvider).requestOtp(destination);

    if (!mounted) return;
    setState(() => _sending = false);
    context.push(
      Routes.otp,
      extra: OtpArgs(
        destination: destination,
        display: display,
        isEmail: isEmail,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPhone = _mode == _LoginMode.phone;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Insets.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: GridLogo(size: 72)),
                    Gaps.lg,
                    Center(
                      child: Text(
                        'Welcome to GRID',
                        style: theme.textTheme.headlineLarge,
                      ),
                    ),
                    Gaps.sm,
                    Center(
                      child: Text(
                        'Manage everything your home needs.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ),
                    Gaps.xxxl,
                    SegmentedButton<_LoginMode>(
                      segments: const [
                        ButtonSegment(
                          value: _LoginMode.phone,
                          label: Text('Phone'),
                          icon: Icon(Icons.smartphone_rounded, size: 18),
                        ),
                        ButtonSegment(
                          value: _LoginMode.email,
                          label: Text('Email'),
                          icon: Icon(Icons.mail_outline_rounded, size: 18),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (selection) =>
                          setState(() => _mode = selection.first),
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: AppColors.mint,
                        selectedForegroundColor: AppColors.forestDeep,
                      ),
                    ),
                    Gaps.xxl,
                    if (isPhone)
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d\s]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          hintText: '55 123 4567',
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(
                              left: Insets.lg,
                              right: Insets.sm,
                            ),
                            child: Text('🇬🇭  +233'),
                          ),
                          prefixIconConstraints: BoxConstraints(minWidth: 0),
                        ),
                        validator: Validators.ghanaPhone,
                        onFieldSubmitted: (_) => _continue(),
                      )
                    else
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          hintText: 'you@example.com',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        validator: Validators.email,
                        onFieldSubmitted: (_) => _continue(),
                      ),
                    Gaps.xxl,
                    FilledButton(
                      onPressed: _sending ? null : _continue,
                      child: _sending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Continue'),
                    ),
                    Gaps.xl,
                    const InfoBanner(
                      message:
                          'Demo sign-in — we will show you a one-time code '
                          'on the next screen. No SMS is sent.',
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
