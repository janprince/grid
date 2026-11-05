import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';

/// The ECG power token — the app's typographic high point.
///
/// This number *is* the thing the customer bought, and it gets transcribed
/// by hand into a keypad on a wall. It was previously a grey box with a
/// little extra letter-spacing. Here it gets the brand ground, fixed-advance
/// digits and grouping in fours, which is what makes a twenty-digit string
/// possible to read one chunk at a time without losing your place.
class PowerTokenBlock extends StatelessWidget {
  const PowerTokenBlock({super.key, required this.token});

  final String token;

  /// Digits in groups of four, the way the token is printed on an ECG
  /// receipt and the way people read it aloud.
  static List<String> _group(String token) {
    final digits = token.replaceAll(RegExp(r'\s'), '');
    return [
      for (var i = 0; i < digits.length; i += 4)
        digits.substring(i, i + 4 > digits.length ? digits.length : i + 4),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.navy,
      borderRadius: Corners.lgRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: token));
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Token copied')));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(Insets.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'YOUR POWER TOKEN',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.navySoft,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: AppColors.onNavyMuted,
                  ),
                ],
              ),
              Gaps.md,
              Wrap(
                spacing: Insets.md,
                runSpacing: Insets.xs,
                children: [
                  for (final group in _group(token))
                    Text(
                      group,
                      style: theme.textTheme.headlineMedium?.token.copyWith(
                        color: AppColors.onNavy,
                      ),
                    ),
                ],
              ),
              Gaps.md,
              Text(
                'Tap to copy, then enter it on your meter keypad.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onNavyMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
