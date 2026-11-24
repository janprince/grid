import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import 'pay_groups.dart';
import 'widgets/pay_flow_parts.dart';
import 'widgets/pay_help_sheet.dart';

/// "Select the recipient's network" / "Select a TV provider": the first
/// question for anything paid to one of several billers.
class PayProviderScreen extends StatelessWidget {
  const PayProviderScreen({super.key, required this.group});

  final PayGroup group;

  @override
  Widget build(BuildContext context) {
    final type = group.types.first;
    final tiles = type.isPhoneAccount
        ? [
            for (final n in MobileNetwork.values)
              ProviderTile(
                label: n.label,
                mark: NetworkMark(n, size: ProviderTile.roomyMark),
                roomy: true,
                onTap: () => context.push(
                  '${Routes.payFlow(type.name)}?network=${n.name}',
                ),
              ),
          ]
        : [
            for (final t in group.types)
              ProviderTile(
                label: t.label,
                mark: BillerMark(t, size: ProviderTile.roomyMark),
                roomy: true,
                onTap: () => context.push(Routes.payFlow(t.name)),
              ),
          ];

    return PayFlowScaffold(
      title: group.chooseTitle,
      onBack: () => context.pop(),
      onHelp: () => showPayHelpSheet(context),
      above: const PayFootnote(
        'No GRID fee on bills and top-ups.',
        icon: Icons.verified_user_outlined,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Insets.xl,
          Insets.md,
          Insets.xl,
          Insets.xl,
        ),
        children: [
          PayHeading(group.chooseHeading),
          Gaps.xl,
          ProviderGrid(columns: 2, children: tiles),
        ],
      ),
    );
  }
}
