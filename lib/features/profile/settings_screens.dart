import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';

/// Saved payment methods (mock — adding real methods needs the live
/// payments integration).
class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final methods = ref.watch(paymentMethodsProvider);

    return Scaffold(
      appBar: AppHeader(
        title: 'Payment methods',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Insets.xl),
        children: [
          for (final method in methods) ...[
            AppCard(
              padding: const EdgeInsets.all(Insets.lg),
              child: Row(
                children: [
                  TintedIcon(method.icon),
                  Gaps.md,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(method.label, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          method.alwaysFails
                              ? 'Demo — always declines'
                              : method.maskedNumber,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (method.isDefault)
                    const StatusBadge(label: 'Default', tone: BadgeTone.success)
                  else if (method.alwaysFails)
                    const StatusBadge(label: 'Demo', tone: BadgeTone.warning),
                ],
              ),
            ),
            Gaps.md,
          ],
          Gaps.sm,
          SecondaryButton(
            label: 'Add payment method',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Adding payment methods arrives with the live release',
                ),
              ),
            ),
            icon: Icons.add_rounded,
          ),
        ],
      ),
    );
  }
}

/// Notification preferences (persisted for the session).
class NotificationPrefsScreen extends StatefulWidget {
  const NotificationPrefsScreen({super.key});

  @override
  State<NotificationPrefsScreen> createState() =>
      _NotificationPrefsScreenState();
}

class _NotificationPrefsScreenState extends State<NotificationPrefsScreen> {
  bool _billReminders = true;
  bool _jobUpdates = true;
  bool _receipts = true;
  bool _tips = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        title: 'Notifications',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Insets.xl),
        children: [
          _PrefSwitch(
            title: 'Bill reminders',
            subtitle: 'Before ECG, water, TV or internet run out',
            value: _billReminders,
            onChanged: (v) => setState(() => _billReminders = v),
          ),
          _PrefSwitch(
            title: 'Service job updates',
            subtitle: 'Assignment, arrival and completion alerts',
            value: _jobUpdates,
            onChanged: (v) => setState(() => _jobUpdates = v),
          ),
          _PrefSwitch(
            title: 'Payment receipts',
            subtitle: 'A receipt after every successful payment',
            value: _receipts,
            onChanged: (v) => setState(() => _receipts = v),
          ),
          _PrefSwitch(
            title: 'Home care tips',
            subtitle: 'Occasional seasonal maintenance advice',
            value: _tips,
            onChanged: (v) => setState(() => _tips = v),
          ),
        ],
      ),
    );
  }
}

class _PrefSwitch extends StatelessWidget {
  const _PrefSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.md),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.xs,
        ),
        borderRadius: Corners.lgRadius,
        child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          title: Text(title, style: theme.textTheme.titleMedium),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          contentPadding: EdgeInsets.zero,
          activeTrackColor: AppColors.navy,
        ),
      ),
    );
  }
}

/// FAQs and contact options.
class HelpCentreScreen extends StatelessWidget {
  const HelpCentreScreen({super.key});

  static const _faqs = [
    (
      'How do ECG prepaid tokens work?',
      'After a successful top-up you receive a 20-digit token. Enter it on '
          'your meter keypad to load the credit. In this demo the token is '
          'a placeholder.',
    ),
    (
      'Who are the service professionals?',
      'GRID professionals are vetted, background-checked and rated after '
          'every job. You see their profile and rating before they arrive.',
    ),
    (
      'What does the call-out fee cover?',
      'It covers travel, inspection and diagnosis. You approve the full '
          'quote before any work starts — no surprises.',
    ),
    (
      'Can I manage more than one home?',
      'Yes — add as many homes as you need and switch between them from '
          'the dashboard. Every payment and job is filed under its home.',
    ),
    (
      'Is my money safe?',
      'This is a demo build: no real payments happen. The live release '
          'uses licensed payment partners for mobile money and cards.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppHeader(
        title: 'Help centre',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Insets.xl),
        children: [
          AppCard(
            padding: const EdgeInsets.all(Insets.lg),
            child: Row(
              children: [
                const TintedIcon(Icons.support_agent_rounded, size: 48),
                Gaps.md,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Talk to a person',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        '030 700 0000 • 7am – 9pm, every day',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                PrimaryButton(
                  label: 'Call',
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calling is a demo action')),
                  ),
                  expand: false,
                ),
              ],
            ),
          ),
          Gaps.xl,
          Text('Frequently asked', style: theme.textTheme.headlineSmall),
          Gaps.md,
          for (final (question, answer) in _faqs)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.md),
              child: AppCard(
                padding: EdgeInsets.zero,
                borderRadius: Corners.lgRadius,
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(question, style: theme.textTheme.titleMedium),
                    childrenPadding: const EdgeInsets.fromLTRB(
                      Insets.lg,
                      0,
                      Insets.lg,
                      Insets.lg,
                    ),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        answer,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Privacy & security settings.
class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _biometrics = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppHeader(
        title: 'Privacy & security',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Insets.xl),
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.lg,
              vertical: Insets.xs,
            ),
            borderRadius: Corners.lgRadius,
            child: SwitchListTile(
              value: _biometrics,
              onChanged: (v) {
                setState(() => _biometrics = v);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Biometric lock arrives with the live release',
                    ),
                  ),
                );
              },
              title: Text(
                'Unlock with biometrics',
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Text(
                'Require Face ID / fingerprint to open GRID',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
              ),
              contentPadding: EdgeInsets.zero,
              activeTrackColor: AppColors.navy,
            ),
          ),
          Gaps.md,
          AppCard(
            padding: const EdgeInsets.all(Insets.lg),
            borderRadius: Corners.lgRadius,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('The privacy policy opens in the live release'),
              ),
            ),
            child: Row(
              children: [
                const TintedIcon(Icons.description_rounded, size: 40),
                Gaps.md,
                Expanded(
                  child: Text(
                    'Privacy policy',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
              ],
            ),
          ),
          Gaps.md,
          const InfoBanner(
            icon: Icons.lock_rounded,
            message:
                'This demo stores everything on your device only. '
                'Nothing is sent to a server.',
          ),
        ],
      ),
    );
  }
}
