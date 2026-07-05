import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(sessionProvider).user;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Insets.xl),
          children: [
            Text('Profile', style: theme.textTheme.headlineLarge),
            Gaps.xl,
            AppCard(
              padding: const EdgeInsets.all(Insets.xl),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.mint,
                    child: Text(
                      user?.initials ?? 'G',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.forestDeep,
                      ),
                    ),
                  ),
                  Gaps.lg,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'GRID user',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Fmt.ghanaPhone(user?.phone ?? ''),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.inkMuted,
                          ),
                        ),
                        if (user?.email != null)
                          Text(
                            user!.email!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.inkMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Profile editing arrives with the live release',
                        ),
                      ),
                    ),
                    tooltip: 'Edit profile',
                    icon: const Icon(Icons.edit_outlined, size: 20),
                  ),
                ],
              ),
            ),
            Gaps.xxl,
            _SectionLabel('Home & payments'),
            _SettingsTile(
              icon: Icons.other_houses_rounded,
              title: 'Manage homes',
              subtitle: 'Properties, addresses and primary home',
              onTap: () => context.push(Routes.properties),
            ),
            _SettingsTile(
              icon: Icons.bookmark_rounded,
              title: 'Saved utility accounts',
              subtitle: 'Meters, smartcards and numbers',
              onTap: () => context.push(Routes.savedAccounts),
            ),
            _SettingsTile(
              icon: Icons.credit_card_rounded,
              title: 'Payment methods',
              subtitle: 'Mobile money and cards',
              onTap: () => context.push(Routes.paymentMethods),
            ),
            Gaps.xl,
            _SectionLabel('Preferences'),
            _SettingsTile(
              icon: Icons.notifications_rounded,
              title: 'Notifications',
              subtitle: 'Reminders, receipts and job updates',
              onTap: () => context.push(Routes.notifications),
            ),
            _SettingsTile(
              icon: Icons.group_add_rounded,
              title: 'Invite household member',
              subtitle: 'Share access to your homes — coming soon',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Family & shared-home access arrives in a later release',
                  ),
                ),
              ),
            ),
            Gaps.xl,
            _SectionLabel('Support'),
            _SettingsTile(
              icon: Icons.help_rounded,
              title: 'Help centre',
              subtitle: 'FAQs and contact options',
              onTap: () => context.push(Routes.help),
            ),
            _SettingsTile(
              icon: Icons.shield_rounded,
              title: 'Privacy & security',
              subtitle: 'Your data and account safety',
              onTap: () => context.push(Routes.privacy),
            ),
            Gaps.xxl,
            OutlinedButton.icon(
              onPressed: () => _logout(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: BorderSide(
                  color: AppColors.danger.withValues(alpha: 0.4),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Log out'),
            ),
            Gaps.lg,
            Center(
              child: Text(
                'GRID v0.1.0 — demo build',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.inkFaint,
                ),
              ),
            ),
            Gaps.xl,
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out of GRID?'),
        content: const Text(
          'Your saved homes and accounts stay on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(sessionProvider.notifier).signOut();
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.md),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.inkFaint,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.md),
      child: AppCard(
        padding: const EdgeInsets.all(Insets.lg),
        borderRadius: Corners.lgRadius,
        onTap: onTap,
        child: Row(
          children: [
            TintedIcon(icon, size: 40),
            Gaps.md,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}
