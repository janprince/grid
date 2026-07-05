import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';

/// The signature GRID moment: a deep forest-green card summarising the
/// selected home's utilities at a glance.
class HomeHeroCard extends ConsumerWidget {
  const HomeHeroCard({super.key, required this.property});

  final Property property;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accounts = ref
        .watch(accountsProvider)
        .where((a) => a.propertyId == property.id)
        .toList();

    final dueSoon = accounts.where(_isDueSoon).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    final allGood = dueSoon.isEmpty;

    return Container(
      padding: const EdgeInsets.all(Insets.xl),
      decoration: BoxDecoration(
        color: AppColors.forestDeep,
        borderRadius: Corners.xlRadius,
        boxShadow: AppColors.floatingShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PulseDot(
                color: allGood ? AppColors.mint : const Color(0xFFFFC96B),
              ),
              Gaps.sm,
              Expanded(
                child: Text(
                  allGood
                      ? 'All systems normal'
                      : '${dueSoon.length} bill${dueSoon.length == 1 ? '' : 's'} need attention',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.onForestMuted,
                  ),
                ),
              ),
              Icon(
                Icons.other_houses_rounded,
                color: AppColors.onForestMuted.withValues(alpha: 0.7),
                size: 20,
              ),
            ],
          ),
          Gaps.md,
          Text(
            property.nickname,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.onForest,
            ),
          ),
          Text(
            property.location,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onForestMuted,
            ),
          ),
          if (accounts.isNotEmpty) ...[
            Gaps.xl,
            ...accounts.take(3).map((a) => _UtilityStatusRow(account: a)),
          ],
          if (!allGood) ...[
            Gaps.lg,
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    context.push(Routes.payFlow(dueSoon.first.type.name)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.mint,
                  foregroundColor: AppColors.forestDeep,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Settle bills'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static bool _isDueSoon(UtilityAccount a) {
    final due = a.dueDate;
    if (due == null) return false;
    return due.difference(DateTime.now()).inDays <= 3;
  }
}

class _UtilityStatusRow extends StatelessWidget {
  const _UtilityStatusRow({required this.account});

  final UtilityAccount account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final due = account.dueDate;
    final String status;
    final Color statusColor;
    if (due != null && due.difference(DateTime.now()).inDays <= 3) {
      status = Fmt.dueLabel(due);
      statusColor = const Color(0xFFFFC96B);
    } else if (due != null) {
      status = Fmt.dueLabel(due);
      statusColor = AppColors.onForestMuted;
    } else if (account.lastPaidAt != null) {
      status = Fmt.lastPaidLabel(account.lastPaidAt!);
      statusColor = AppColors.onForestMuted;
    } else {
      status = 'Active';
      statusColor = AppColors.onForestMuted;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.md),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: Corners.smRadius,
            ),
            child: Icon(account.type.icon, size: 16, color: AppColors.mint),
          ),
          Gaps.md,
          Expanded(
            child: Text(
              account.type.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onForest,
              ),
            ),
          ),
          Text(
            status,
            style: theme.textTheme.labelSmall?.copyWith(color: statusColor),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(
        begin: 0.5,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
