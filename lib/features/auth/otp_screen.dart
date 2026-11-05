import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/api/api_exception.dart';
import '../../core/data/repositories.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';

class OtpArgs {
  const OtpArgs({required this.challenge});

  final OtpChallenge challenge;
}

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.args});

  final OtpArgs args;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controller = TextEditingController();
  late OtpChallenge _challenge = widget.args.challenge;
  bool _verifying = false;
  bool _resending = false;
  String? _error;
  int _resendIn = 0;
  Timer? _timer;

  String get _display => Fmt.ghanaPhone(_challenge.phoneNumber);

  @override
  void initState() {
    super.initState();
    _startResendTimer(_challenge.resendAfterSeconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startResendTimer(int seconds) {
    _timer?.cancel();
    setState(() => _resendIn = seconds);
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
    setState(() => _resending = true);
    try {
      final challenge = await ref
          .read(authApiProvider)
          .requestOtp(_challenge.phoneNumber);
      if (!mounted) return;
      _controller.clear();
      setState(() {
        _challenge = challenge;
        _error = null;
      });
      _startResendTimer(challenge.resendAfterSeconds);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('New code sent to $_display')));
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.code == 'auth.otp_rate_limited') {
        _startResendTimer(error.retryAfterSeconds ?? 60);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.code == 'auth.otp_rate_limited'
                ? 'Too many codes requested. Try again in '
                      '${Fmt.waitTime(error.retryAfterSeconds)}.'
                : error.message,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verify() async {
    if (_verifying) return;
    final code = _controller.text.replaceAll(RegExp(r'\D'), '');
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      // On success the router moves on: profile setup for someone new,
      // home for someone returning.
      await ref
          .read(sessionProvider.notifier)
          .verifyOtp(_challenge.phoneNumber, code);
    } on ApiException catch (error) {
      if (!mounted) return;
      _controller.clear();
      setState(() {
        _verifying = false;
        _error = switch (error.code) {
          'auth.otp_invalid' => switch (error.attemptsRemaining) {
            null => 'That code is not correct. Please try again.',
            1 => 'That code is not correct. 1 try left.',
            final n => 'That code is not correct. $n tries left.',
          },
          'auth.otp_expired' => 'That code has expired. Request a new one.',
          'auth.otp_attempts_exceeded' =>
            'Too many wrong tries. Request a new code.',
          _ => error.message,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppHeader(
        title: 'Verify your number',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Insets.xl),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Enter the 6-digit code', style: AppText.headline),
                  Gaps.sm,
                  Text(
                    'We sent a one-time code to $_display.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
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
                        color: AppColors.faint,
                      ),
                      errorText: _error,
                      errorMaxLines: 2,
                    ),
                    onSubmitted: (_) => _verify(),
                    onChanged: (value) {
                      if (value.length == 6) _verify();
                    },
                  ),
                  if (_challenge.developmentCode case final code?) ...[
                    Gaps.lg,
                    InfoBanner(
                      message:
                          'Test code: $code — in the live app this arrives '
                          'by SMS.',
                    ),
                  ],
                  Gaps.xxl,
                  PrimaryButton(
                    label: 'Verify',
                    busy: _verifying,
                    onPressed: _verify,
                  ),
                  Gaps.lg,
                  Center(
                    child: _resendIn > 0
                        ? Text(
                            'Resend code in ${_resendIn}s',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.faint,
                            ),
                          )
                        : TextButton(
                            onPressed: _resending ? null : _resend,
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
