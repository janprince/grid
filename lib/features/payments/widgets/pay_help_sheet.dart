import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/models.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/support.dart';
import '../../../core/widgets/widgets.dart';

/// "We're here to help": what to do when a prompt doesn't come, and how to
/// reach a person. One card per way out, each saying what it leads to.
Future<void> showPayHelpSheet(BuildContext context, {MobileNetwork? wallet}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.canvas,
    builder: (sheet) => _PayHelpSheet(wallet: wallet, parent: context),
  );
}

class _PayHelpSheet extends StatelessWidget {
  const _PayHelpSheet({required this.wallet, required this.parent});

  final MobileNetwork? wallet;

  /// The screen under the sheet, which navigation acts on.
  final BuildContext parent;

  static String _menuCode(MobileNetwork network) => switch (network) {
    MobileNetwork.mtn => '*170#',
    MobileNetwork.telecel => '*110#',
    MobileNetwork.airtelTigo => '*110#',
  };

  @override
  Widget build(BuildContext context) {
    final network = wallet;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        Insets.xl,
        Insets.sm,
        Insets.xl,
        MediaQuery.paddingOf(context).bottom + Insets.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: NavChip(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icons.close_rounded,
              tooltip: 'Close',
            ),
          ),
          Text(
            'We\'re here to help',
            textAlign: TextAlign.center,
            style: AppText.headline,
          ),
          Gaps.sm,
          Text(
            'Payments usually go through in under a minute.',
            textAlign: TextAlign.center,
            style: AppText.bodyMuted,
          ),
          Gaps.xxl,
          _HelpCard(
            icon: Icons.phonelink_ring_rounded,
            title: 'Didn\'t get the prompt?',
            message: network == null
                ? 'Make sure your phone is on and unlocked. You can also '
                      'approve it from your wallet\'s menu under approvals.'
                : 'Make sure your phone is on and unlocked. You can also '
                      'dial ${_menuCode(network)} and approve it under '
                      '${network.walletLabel} approvals.',
          ),
          Gaps.lg,
          _HelpCard(
            icon: Icons.receipt_long_rounded,
            title: 'Check your payments',
            message: 'Activity shows every payment and where it stands.',
            onTap: () {
              Navigator.of(context).pop();
              parent.go(Routes.activity);
            },
          ),
          Gaps.lg,
          _HelpCard(
            icon: Icons.support_agent_rounded,
            title: 'Call GRID support',
            message: 'Talk to someone about a payment.',
            chip: Fmt.ghanaPhone(supportPhone),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              if (!await dial(supportPhone)) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Call ${Fmt.ghanaPhone(supportPhone)}'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({
    required this.icon,
    required this.title,
    required this.message,
    this.chip,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? chip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(Insets.xl),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: Corners.lgRadius,
        boxShadow: AppColors.raisedShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.heading),
                Gaps.xs,
                Text(message, style: AppText.bodyMuted),
                if (chip != null) ...[
                  Gaps.md,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.navySoft,
                      borderRadius: Corners.pill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.call_rounded,
                          size: 15,
                          color: AppColors.navy,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          chip!,
                          style: AppText.caption.copyWith(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w700,
                            fontFeatures: AppText.tabularFigures,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Gaps.lg,
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.navySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.navy, size: 26),
          ),
        ],
      ),
    );
    return onTap == null
        ? card
        : Semantics(
            button: true,
            child: Pressable(onTap: onTap!, child: card),
          );
  }
}
