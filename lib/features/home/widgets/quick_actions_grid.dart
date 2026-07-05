import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/models.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class _QuickAction {
  const _QuickAction(this.icon, this.label, this.route);

  final IconData icon;
  final String label;
  final String route;
}

final _actions = [
  _QuickAction(
    Icons.bolt_rounded,
    'Buy ECG',
    Routes.payFlow(UtilityType.ecg.name),
  ),
  _QuickAction(
    Icons.water_drop_rounded,
    'Pay Water',
    Routes.payFlow(UtilityType.water.name),
  ),
  _QuickAction(
    Icons.live_tv_rounded,
    'Pay TV',
    Routes.payFlow(UtilityType.dstv.name),
  ),
  _QuickAction(
    Icons.smartphone_rounded,
    'Airtime',
    Routes.payFlow(UtilityType.airtime.name),
  ),
  _QuickAction(
    Icons.signal_cellular_alt_rounded,
    'Data',
    Routes.payFlow(UtilityType.dataBundle.name),
  ),
  const _QuickAction(
    Icons.handyman_rounded,
    'Book Service',
    Routes.bookService,
  ),
];

/// Six fast repeat tasks — the actions people open GRID for.
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Insets.md,
      crossAxisSpacing: Insets.md,
      childAspectRatio: 1.15,
      children: [
        for (final action in _actions)
          _QuickActionTile(
            icon: action.icon,
            label: action.label,
            onTap: () => context.push(action.route),
          ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: Corners.lgRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: Corners.lgRadius,
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.all(Insets.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.tealSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: AppColors.forest),
              ),
              Gaps.sm,
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AppColors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
