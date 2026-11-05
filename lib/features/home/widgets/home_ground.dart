import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/meter_estimate.dart';
import '../../../core/widgets/widgets.dart';
import 'property_switcher_sheet.dart';

/// The dashboard's navy ground — the app's one hero, with the GRID texture.
///
/// This is a *ground*, not a card: the greeting, the meter and the primary
/// actions sit directly on the brand colour, full-bleed to the screen edges
/// and up under the status bar. Previously a green card floated on an
/// off-white page, which is the arrangement every templated fintech home
/// screen uses and is why the dashboard read as generic.
///
/// It leads with power remaining rather than a money balance. GRID has no
/// wallet — it is a payment rail — so a balance figure would be invented.
/// What a prepaid household actually wants on waking is how long the lights
/// will stay on.
class HomeGround extends ConsumerWidget {
  const HomeGround({super.key, required this.property});

  final Property property;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).user;
    final accounts = ref
        .watch(accountsProvider)
        .where((a) => a.propertyId == property.id)
        .toList();

    final dueSoon = accounts.where(_isDueSoon).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    // The meter reads from this home's prepaid electricity account.
    final ecg = accounts.where((a) => a.type == UtilityType.ecg).firstOrNull;
    final meter = ecg == null ? null : MeterEstimate.forAccount(ecg);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyDeep, AppColors.navy, AppColors.navyLight],
        ),
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          const GridTexture(cell: 30),
          Padding(
            padding: EdgeInsets.fromLTRB(
              Insets.xl,
              MediaQuery.paddingOf(context).top + Insets.lg,
              Insets.xl,
              // Extra room at the foot for the sheet lip to sit over.
              Insets.xxl + Insets.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: AppText.caption.copyWith(
                              color: AppColors.onNavyMuted,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            user?.firstName ?? 'there',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.title.copyWith(
                              color: AppColors.onNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Gaps.sm,
                    _HomeSwitcher(
                      label: property.nickname,
                      onTap: () => showPropertySwitcher(context),
                    ),
                  ],
                ),
                Gaps.xxxl,
                if (meter != null)
                  _MeterReading(meter: meter, account: ecg!)
                else
                  _BillsReading(dueCount: dueSoon.length, property: property),
                Gaps.xxl,
                Wrap(
                  spacing: Insets.md,
                  runSpacing: Insets.md,
                  children: [
                    OnNavyButton(
                      label: 'Top up power',
                      icon: Icons.bolt_rounded,
                      onPressed: () =>
                          context.push(Routes.payFlow(UtilityType.ecg.name)),
                    ),
                    OnNavyButton(
                      label: dueSoon.isEmpty
                          ? 'All bills'
                          : '${dueSoon.length} bill${dueSoon.length == 1 ? '' : 's'} due',
                      filled: false,
                      onPressed: () => context.go(Routes.pay),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static bool _isDueSoon(UtilityAccount a) {
    final due = a.dueDate;
    if (due == null) return false;
    return due.difference(DateTime.now()).inDays <= 3;
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

/// Power remaining, as a figure and a meter.
class _MeterReading extends StatelessWidget {
  const _MeterReading({required this.meter, required this.account});

  final MeterEstimate meter;
  final UtilityAccount account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              meter.unitsRemaining.round().toString(),
              style: theme.textTheme.displayLarge?.tabular.copyWith(
                color: AppColors.onNavy,
              ),
            ),
            Gaps.sm,
            Text(
              'units',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.onNavyMuted,
              ),
            ),
          ],
        ),
        Gaps.xs,
        Text(
          'of power left on ${account.nickname}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.onNavyMuted,
          ),
        ),
        Gaps.xl,
        MeterBar(
          fraction: meter.fraction,
          caption:
              'Estimated from ${Fmt.cedis(meter.lastAmount)} '
              'on ${Fmt.date(meter.lastPaidAt)}',
          trailing: meter.daysLabel,
        ),
      ],
    );
  }
}

/// Shown when a home has no prepaid electricity account to meter — the
/// bills picture stands in for the power picture.
class _BillsReading extends StatelessWidget {
  const _BillsReading({required this.dueCount, required this.property});

  final int dueCount;
  final Property property;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dueCount == 0 ? 'Nothing due' : '$dueCount due',
          style: theme.textTheme.displaySmall?.copyWith(
            color: AppColors.onNavy,
          ),
        ),
        Gaps.xs,
        Text(
          dueCount == 0
              ? 'Every bill at ${property.nickname} is settled.'
              : 'Bills at ${property.nickname} need attention this week.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.onNavyMuted,
          ),
        ),
      ],
    );
  }
}

/// The home switcher, sized to sit on the dark ground.
class _HomeSwitcher extends StatelessWidget {
  const _HomeSwitcher({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.10),
      borderRadius: Corners.pill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Insets.md,
            Insets.sm,
            Insets.sm,
            Insets.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.onNavy),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.onNavyMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
