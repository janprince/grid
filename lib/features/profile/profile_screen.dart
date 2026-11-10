import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';

/// The account: who you are on a navy header, then everything you can set,
/// grouped. Shares its shape with GRID Pro's Account tab.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).user;
    final homes = ref.watch(propertiesProvider).length;
    final accounts = ref.watch(accountsProvider).length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            _ProfileHeader(
              initials: user?.initials ?? 'G',
              name: user?.name ?? 'GRID user',
              contact: user?.email ?? Fmt.ghanaPhone(user?.phone ?? ''),
            ),
            Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(
                  Insets.xl,
                  Insets.xl,
                  Insets.xl,
                  Insets.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MenuGroup(
                      children: [
                        MenuRow(
                          icon: Icons.other_houses_outlined,
                          label: 'My homes',
                          subtitle: '$homes saved',
                          onTap: () => context.push(Routes.properties),
                        ),
                        MenuRow(
                          icon: Icons.bookmark_outline_rounded,
                          label: 'Saved accounts',
                          subtitle: '$accounts meters, cards and numbers',
                          onTap: () => context.push(Routes.savedAccounts),
                        ),
                        MenuRow(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Payment methods',
                          onTap: () => context.push(Routes.paymentMethods),
                        ),
                      ],
                    ),
                    const SectionHeader(
                      title: 'Preferences',
                      padding: EdgeInsets.only(top: 24, bottom: Insets.md),
                    ),
                    MenuGroup(
                      children: [
                        MenuRow(
                          icon: Icons.notifications_none_rounded,
                          label: 'Notifications',
                          onTap: () => context.push(Routes.notifications),
                        ),
                        MenuRow(
                          icon: Icons.group_add_outlined,
                          label: 'Invite family',
                          value: 'Soon',
                          onTap: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Family & shared-home access arrives in '
                                    'a later release',
                                  ),
                                ),
                              ),
                        ),
                      ],
                    ),
                    const SectionHeader(
                      title: 'Help',
                      padding: EdgeInsets.only(top: 24, bottom: Insets.md),
                    ),
                    MenuGroup(
                      children: [
                        MenuRow(
                          icon: Icons.support_agent_rounded,
                          label: 'Help centre',
                          onTap: () => context.push(Routes.help),
                        ),
                        MenuRow(
                          icon: Icons.shield_outlined,
                          label: 'Privacy & security',
                          onTap: () => context.push(Routes.privacy),
                        ),
                      ],
                    ),
                    Gaps.lg,
                    MenuGroup(
                      children: [
                        MenuRow(
                          icon: Icons.logout_rounded,
                          label: 'Log out',
                          danger: true,
                          onTap: () => _logout(context, ref),
                        ),
                      ],
                    ),
                    Gaps.xl,
                    const Center(
                      child: Text('GRID · Version 0.1', style: AppText.caption),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmationSheet(
      context,
      title: 'Log out of GRID?',
      message: 'Your homes and saved accounts stay in your GRID account.',
      confirmLabel: 'Log out',
      cancelLabel: 'Stay',
    );
    if (confirmed) {
      await ref.read(sessionProvider.notifier).signOut();
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.initials,
    required this.name,
    required this.contact,
  });
  final String initials;
  final String name;
  final String contact;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.navyDeep, AppColors.navy],
      ),
    ),
    child: Stack(
      fit: StackFit.passthrough,
      children: [
        const GridTexture(),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Insets.xl, 24, Insets.xl, 50),
            child: Column(
              children: [
                InitialsAvatar(initials: initials, size: 76, onNavy: true),
                Gaps.lg,
                Text(
                  name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contact,
                  style: const TextStyle(
                    color: AppColors.onNavyMuted,
                    fontSize: 14,
                    fontFeatures: AppText.tabularFigures,
                  ),
                ),
                Gaps.md,
                InkWell(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Profile editing arrives with the live release',
                      ),
                    ),
                  ),
                  borderRadius: Corners.smRadius,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Edit profile',
                          style: TextStyle(
                            color: AppColors.amber,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.amber,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
