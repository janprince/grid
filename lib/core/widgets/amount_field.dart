import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'grid_chip.dart';

/// Full-bleed amount entry: the figure *is* the screen.
///
/// Every reference app in this category converges on this — a large figure
/// with the currency set small beside it, preset shortcuts, and one action.
/// The previous treatment was a bordered `TextField` with a `prefixText`,
/// which made the single most important number on the screen look like a
/// form field.
///
/// The system numeric keyboard is used rather than a bespoke keypad: it is
/// accessible, it is what the platform users already know, and the
/// distinctive part of the pattern is the figure, not the digits.
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    this.quickAmounts = const [],
    this.onChanged,
    this.autofocus = true,
  });

  final TextEditingController controller;

  /// Preset shortcuts from `UtilityType.quickAmounts`.
  final List<int> quickAmounts;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              // Optically aligns the currency with the cap height of the
              // figure rather than its full ascent.
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'GH₵',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.faint,
                ),
              ),
            ),
            Gaps.sm,
            IntrinsicWidth(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                autofocus: autofocus,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                textAlign: TextAlign.left,
                style: theme.textTheme.displayMedium?.tabular,
                cursorColor: AppColors.navy,
                cursorWidth: 3,
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: '0',
                  hintStyle: theme.textTheme.displayMedium?.tabular.copyWith(
                    color: AppColors.line,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (quickAmounts.isNotEmpty) ...[
          Gaps.xxl,
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: quickAmounts.length,
              separatorBuilder: (_, _) => Gaps.sm,
              itemBuilder: (context, i) {
                final amount = quickAmounts[i];
                return GridChip(
                  // Kept as "GH₵ 100" so the shortcut reads as money rather
                  // than as a bare number next to the figure above it.
                  label: 'GH₵ $amount',
                  // Compared numerically: the field may hold "100" from a
                  // tap or "100.00" prefilled from a previous payment.
                  selected: double.tryParse(controller.text) == amount,
                  onTap: () {
                    controller.text = '$amount';
                    onChanged?.call('$amount');
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
