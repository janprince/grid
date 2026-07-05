import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/repositories.dart';
import '../../core/providers/app_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import 'profile_setup_screen.dart';

class OtpArgs {
  const OtpArgs({
    required this.destination,
    required this.display,
    required this.isEmail,
  });

  final String destination;
  final String display;
  final bool isEmail;
}

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.args});

  final OtpArgs args;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controller = TextEditingController();
  bool _verifying = false;
  String? _error;
  int _resendIn = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendIn = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendIn <= 1) {
        t.cancel();
        setState(() => _resendIn = 0);
      } else {
        setState(() => _resendIn--);
      }
    });
  }

  Future<void> _resend() async {
    await ref.read(authApiProvider).requestOtp(widget.args.destination);
    if (!mounted) return;
    _startResendTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('New code sent to ${widget.args.display}')),
    );
  }

  Future<void> _verify() async {
    final code = _controller.text.replaceAll(RegExp(r'\D'), '');
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });

    final ok = await ref
        .read(authApiProvider)
        .verifyOtp(widget.args.destination, code);

    if (!mounted) return;
    if (!ok) {
      setState(() {
        _verifying = false;
        _error = 'That code is not correct. Please try again.';
      });
      return;
    }
    context.push(
      Routes.profileSetup,
      extra: ProfileSetupArgs(
        phone: widget.args.isEmail ? null : widget.args.destination,
        email: widget.args.isEmail ? widget.args.destination : null,
      ),
    );
    setState(() => _verifying = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Verify code')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Insets.xxl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Enter the 6-digit code',
                    style: theme.textTheme.headlineMedium,
                  ),
                  Gaps.sm,
                  Text(
                    'We sent a one-time code to ${widget.args.display}.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                  Gaps.xxl,
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: theme.textTheme.headlineLarge?.copyWith(
                      letterSpacing: 14,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••••',
                      hintStyle: theme.textTheme.headlineLarge?.copyWith(
                        letterSpacing: 14,
                        color: AppColors.inkFaint,
                      ),
                      errorText: _error,
                    ),
                    onSubmitted: (_) => _verify(),
                    onChanged: (value) {
                      if (value.length == 6) _verify();
                    },
                  ),
                  Gaps.lg,
                  const InfoBanner(
                    message:
                        'Demo code: ${MockAuthApi.demoCode} — in the live app '
                        'this arrives by SMS or email.',
                  ),
                  Gaps.xxl,
                  FilledButton(
                    onPressed: _verifying ? null : _verify,
                    child: _verifying
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Verify'),
                  ),
                  Gaps.lg,
                  Center(
                    child: _resendIn > 0
                        ? Text(
                            'Resend code in ${_resendIn}s',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.inkFaint,
                            ),
                          )
                        : TextButton(
                            onPressed: _resend,
                            child: const Text('Resend code'),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
