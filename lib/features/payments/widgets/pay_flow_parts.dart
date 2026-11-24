import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';

/// The frame every bill-payment screen shares: a quiet centred title between
/// back and close (or help), the step's content, and one action pinned to
/// the bottom that rides above the keyboard.
///
/// There is no step counter. Each screen asks one thing, so the question in
/// the body is the progress the person needs.
class PayFlowScaffold extends StatelessWidget {
  const PayFlowScaffold({
    super.key,
    required this.title,
    required this.body,
    this.onBack,
    this.onClose,
    this.onHelp,
    this.action,
    this.above,
    this.canPop = true,
  });

  final String title;
  final Widget body;
  final VoidCallback? onBack;
  final VoidCallback? onClose;

  /// Shows a "?" chip on the right instead of close.
  final VoidCallback? onHelp;

  /// The primary button.
  final Widget? action;

  /// Sits just above [action]: who is being paid, or a short footnote.
  final Widget? above;

  /// False when system back should run [onBack] rather than pop the route.
  final bool canPop;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack?.call();
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: PayFlowHeader(
          title: title,
          onBack: onBack,
          onClose: onClose,
          onHelp: onHelp,
        ),
        body: body,
        bottomNavigationBar: action == null && above == null
            ? null
            : Container(
                margin: EdgeInsets.only(bottom: bottomInset),
                color: AppColors.canvas,
                child: SafeArea(
                  minimum: const EdgeInsets.fromLTRB(
                    Insets.xl,
                    Insets.sm,
                    Insets.xl,
                    Insets.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (above != null) ...[above!, Gaps.lg],
                      ?action,
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// Back on the left, the flow's name in the middle, close or help on the
/// right. No hairline: the page below is one surface.
class PayFlowHeader extends StatelessWidget implements PreferredSizeWidget {
  const PayFlowHeader({
    super.key,
    required this.title,
    this.onBack,
    this.onClose,
    this.onHelp,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final VoidCallback? onHelp;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    Widget slot(Widget? child) => SizedBox(width: 48, child: child);
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 60,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              slot(
                onBack == null
                    ? null
                    : NavChip(onPressed: onBack!, color: Colors.transparent),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.subtitle.copyWith(fontSize: 16),
                ),
              ),
              slot(
                onHelp != null
                    ? NavChip(
                        onPressed: onHelp!,
                        icon: Icons.question_mark_rounded,
                        tooltip: 'Help',
                        color: AppColors.navySoft,
                        iconColor: AppColors.navy,
                      )
                    : onClose != null
                    ? NavChip(
                        onPressed: onClose!,
                        icon: Icons.close_rounded,
                        tooltip: 'Close',
                        color: Colors.transparent,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A white card lifted off the page: the one thing the step is about.
class PayCard extends StatelessWidget {
  const PayCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Insets.xl),
    this.onTap,
    this.selected = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Corners.lgRadius,
        boxShadow: AppColors.raisedShadow,
        border: Border.all(
          color: selected ? AppColors.navy : AppColors.surface,
          width: 1.6,
        ),
      ),
      child: child,
    );
    return onTap == null ? card : Pressable(onTap: onTap!, child: card);
  }
}

/// A biller or network to pick: its logo on a white card, its name beneath.
///
/// Two sizes. The Pay tab lists six choices, so they sit three to a row at
/// [compactMark]. A provider choice (three networks, three TV providers) is
/// the whole screen, so its tiles sit two to a row at [roomyMark]: large
/// enough to fill the page without the poster-sized logos of the first cut.
class ProviderTile extends StatelessWidget {
  const ProviderTile({
    super.key,
    required this.label,
    required this.mark,
    required this.onTap,
    this.caption,
    this.roomy = false,
  });

  static const compactMark = 48.0;
  static const roomyMark = 60.0;

  final String label;
  final String? caption;
  final Widget mark;
  final VoidCallback onTap;
  final bool roomy;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: caption == null ? label : '$label, $caption',
    excludeSemantics: true,
    child: PayCard(
      onTap: onTap,
      padding: roomy
          ? const EdgeInsets.fromLTRB(12, 22, 12, 18)
          : const EdgeInsets.fromLTRB(8, 18, 8, 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: roomy ? roomyMark : compactMark,
            child: Center(child: mark),
          ),
          SizedBox(height: roomy ? 12 : 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppText.subtitle.copyWith(fontSize: roomy ? 15.5 : 14.5),
          ),
          if (caption != null) ...[
            const SizedBox(height: 1),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(fontSize: 12),
            ),
          ],
        ],
      ),
    ),
  );
}

/// [ProviderTile]s in rows of [columns], each row as tall as its tallest.
class ProviderGrid extends StatelessWidget {
  const ProviderGrid({super.key, required this.children, this.columns = 3});

  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    final gap = columns == 2 ? Gaps.lg : Gaps.md;
    for (var i = 0; i < children.length; i += columns) {
      if (i > 0) rows.add(gap);
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = i; j < i + columns; j++) ...[
                if (j > i) gap,
                Expanded(
                  child: j < children.length
                      ? children[j]
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}

/// Several marks fanned out, for a choice that covers more than one biller
/// (TV, or any network).
class LogoCluster extends StatelessWidget {
  const LogoCluster({super.key, required this.marks, this.size = 44});

  final List<Widget Function(double size)> marks;
  final double size;

  @override
  Widget build(BuildContext context) {
    final step = size * 0.74;
    return SizedBox(
      width: size + step * (marks.length - 1) + 4,
      height: size + 4,
      child: Stack(
        children: [
          for (var i = 0; i < marks.length; i++)
            Positioned(
              left: step * i,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(size * 0.3),
                ),
                child: marks[i](size),
              ),
            ),
        ],
      ),
    );
  }
}

/// Who the money goes to, shown above the action on the amount and bundle
/// steps so it is never out of sight while choosing how much.
class RecipientChip extends StatelessWidget {
  const RecipientChip({
    super.key,
    required this.type,
    required this.name,
    required this.number,
    this.network,
    this.onTap,
  });

  final UtilityType type;
  final MobileNetwork? network;
  final String name;
  final String number;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shown = type.isPhoneAccount ? Fmt.ghanaPhone(number) : number;
    return Semantics(
      label: 'Paying $name, $shown',
      button: onTap != null,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: Corners.rowRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              BillerMark(type, size: 40, network: network),
              Gaps.md,
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.subtitle,
                    ),
                    Text(
                      shown,
                      maxLines: 1,
                      style: AppText.caption.copyWith(
                        fontSize: 13.5,
                        fontFeatures: AppText.tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small centred line under the content, e.g. "No GRID fee".
class PayFootnote extends StatelessWidget {
  const PayFootnote(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (icon != null) ...[
        Icon(icon, size: 16, color: AppColors.faint),
        const SizedBox(width: 6),
      ],
      Flexible(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppText.caption.copyWith(fontSize: 13),
        ),
      ),
    ],
  );
}

/// The step's question, large and left-aligned above its content.
class PayHeading extends StatelessWidget {
  const PayHeading(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppText.headline),
      if (subtitle != null) ...[
        Gaps.sm,
        Text(subtitle!, style: AppText.bodyMuted),
      ],
    ],
  );
}

/// A label and its value on one line, for the confirm sheet.
class PaySummaryRow extends StatelessWidget {
  const PaySummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.strong = false,
    this.trailing,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool strong;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final labelStyle = strong
        ? AppText.heading
        : AppText.body.copyWith(color: AppColors.muted);
    final valueStyle =
        (strong ? AppText.heading : AppText.body.copyWith(height: 1.3))
            .copyWith(
              color: valueColor ?? AppColors.ink,
              fontFeatures: AppText.tabularFigures,
            );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          Gaps.lg,
          Expanded(
            child: Text(value, textAlign: TextAlign.right, style: valueStyle),
          ),
          if (trailing != null) ...[Gaps.sm, trailing!],
        ],
      ),
    );
  }
}

extension PayFlowCopy on UtilityType {
  /// What the flow is called in its header.
  String get flowTitle => switch (this) {
    UtilityType.airtime => 'Airtime top-up',
    UtilityType.dataBundle => 'Data top-up',
    UtilityType.ecg => 'Buy ECG power',
    UtilityType.water => 'Pay Ghana Water',
    UtilityType.internet => 'Broadband top-up',
    _ => '$label subscription',
  };

  /// One line under the account question.
  String get accountPrompt => switch (this) {
    UtilityType.ecg => 'Enter the prepaid meter number you want to top up.',
    UtilityType.water => 'Enter the account number printed on your bill.',
    UtilityType.dstv || UtilityType.startimes =>
      'Enter the smartcard number on your decoder or account.',
    UtilityType.gotv => 'Enter the IUC number on your decoder.',
    UtilityType.internet => 'Enter the broadband number you want to top up.',
    UtilityType.airtime =>
      'Enter the mobile number you would like to send airtime to.',
    _ => 'Enter the mobile number you would like to send the bundle to.',
  };
}
