import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/models.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';

/// The fast repeat tasks people open GRID for.
///
/// Was a 3×2 grid of identical teal circles — the canonical fintech home
/// screen, and unreadable at a glance because nothing distinguished ECG from
/// DStv from airtime. Now a horizontal run of biller marks, so the row is
/// scanned by brand colour the way a real wallet of bills is.
class PayShortcuts extends StatelessWidget {
  const PayShortcuts({super.key});

  static const _billers = [
    UtilityType.ecg,
    UtilityType.water,
    UtilityType.dstv,
    UtilityType.airtime,
    UtilityType.dataBundle,
    UtilityType.internet,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Insets.xl),
        itemCount: _billers.length,
        separatorBuilder: (_, _) => Gaps.lg,
        itemBuilder: (context, i) {
          final type = _billers[i];
          return _Shortcut(
            label: type.shortLabel,
            onTap: () => context.push(Routes.payFlow(type.name)),
            child: BillerMark(type, size: 52),
          );
        },
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: Corners.rowRadius,
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            child,
            Gaps.sm,
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
