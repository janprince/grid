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
import '../../core/data/api/api_exception.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_sending || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _sending = true;
      _error = null;
    });

    final phone = Validators.normalizePhone(_phoneController.text);
    try {
      final challenge = await ref.read(authApiProvider).requestOtp(phone);
      if (!mounted) return;
      setState(() => _sending = false);
      context.push(Routes.otp, extra: OtpArgs(challenge: challenge));
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = switch (error.code) {
          'auth.invalid_phone' => 'Enter a Ghana mobile number.',
          'auth.otp_rate_limited' =>
            'Too many codes requested. Try again in '
                '${Fmt.waitTime(error.retryAfterSeconds)}.',
          _ => error.message,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDemo = !ref.watch(apiEnabledProvider);

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Insets.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: GridWordmark(fontSize: 20),
                    ),
                    Gaps.xxxl,
                    const ScreenIntro(
                      title: 'Welcome to GRID',
                      subtitle:
                          'Pay bills and book cleaning or laundry — all in '
                          'one place.',
                    ),
                    Gaps.xxl,
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d\s]')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Phone number',
                        hintText: '55 123 4567',
                        errorText: _error,
                        errorMaxLines: 3,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(
                            left: Insets.lg,
                            right: Insets.sm,
                          ),
                          child: Text(
                            '+233',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 0,
                        ),
                      ),
                      validator: Validators.ghanaPhone,
                      onFieldSubmitted: (_) => _continue(),
                    ),
                    Gaps.xxl,
                    PrimaryButton(
                      label: 'Continue',
                      busy: _sending,
                      onPressed: _continue,
                    ),
                    Gaps.xl,
                    InfoBanner(
                      message: isDemo
                          ? 'Demo sign-in — we will show you a one-time code '
                                'on the next screen. No SMS is sent.'
                          : 'We will text a 6-digit code to this number. '
                                'New to GRID? This creates your account.',
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
