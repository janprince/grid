import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

/// The GRID design-system building blocks shared with GRID Pro. Names and
/// behaviour match `GRID PRO/lib/core/widgets/` so a screen reads the same in
/// either app. See `DOCUMENTATION/design-system.md`.

// ── Buttons ─────────────────────────────────────────────────────────────

/// The one solid navy action on a screen. Labels are set in capitals.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.busyLabel = 'Working',
    this.icon,
    this.expand = true,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final String busyLabel;
  final IconData? icon;

  /// Fill the available width (the default) or shrink to the label.
  final bool expand;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: busy ? null : onPressed,
    style: expand
        ? null
        : FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
            textStyle: AppText.button.copyWith(fontSize: 13),
          ),
    child: busy
        ? ButtonSpinner(label: busyLabel, onPrimary: false)
        : _ButtonLabel(label: label, icon: icon),
  );
}

/// White button with a navy outline, for the alternative to the primary.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.danger = false,
    this.expand = true,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool danger;
  final bool expand;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: danger ? AppColors.danger : null,
      side: danger
          ? const BorderSide(color: AppColors.dangerLine, width: 1.4)
          : null,
      minimumSize: expand ? null : const Size(0, 44),
      padding: expand
          ? null
          : const EdgeInsets.symmetric(horizontal: Insets.lg),
      textStyle: expand ? null : AppText.button.copyWith(fontSize: 13),
    ),
    child: _ButtonLabel(label: label, icon: icon),
  );
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({required this.label, this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (icon != null) ...[Icon(icon, size: 19), const SizedBox(width: 8)],
      Flexible(
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

/// Spinner sized to sit inside a button without changing its height.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key, required this.label, this.onPrimary = true});
  final String label;
  final bool onPrimary;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 22,
    height: 22,
    child: CircularProgressIndicator(
      strokeWidth: 2.4,
      color: onPrimary ? Colors.white : AppColors.muted,
      semanticsLabel: label,
    ),
  );
}

/// Compact white button for use on navy surfaces.
class OnNavyButton extends StatelessWidget {
  const OnNavyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.filled = true,
  });
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  /// White fill (true) or a hairline outline on navy (false).
  final bool filled;

  @override
  Widget build(BuildContext context) => Material(
    color: filled ? Colors.white : Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: Corners.smRadius,
      side: filled
          ? BorderSide.none
          : const BorderSide(color: AppColors.onNavyLine, width: 1.4),
    ),
    child: InkWell(
      onTap: onPressed,
      borderRadius: Corners.smRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.button.copyWith(
                  color: filled ? AppColors.navy : Colors.white,
                  fontSize: 13.5,
                ),
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(
                icon,
                size: 17,
                color: filled ? AppColors.navy : Colors.white,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

// ── Page structure ──────────────────────────────────────────────────────

/// Circular grey button used for back and close in page headers.
class NavChip extends StatelessWidget {
  const NavChip({
    super.key,
    required this.onPressed,
    this.icon = Icons.arrow_back_rounded,
    this.tooltip = 'Back',
    this.color = AppColors.chip,
    this.iconColor = AppColors.ink,
  });
  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Semantics(
      button: true,
      label: tooltip,
      excludeSemantics: true,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 40,
            child: Icon(icon, size: 20, color: iconColor),
          ),
        ),
      ),
    ),
  );
}

/// The title bar used across the app: a bold left-aligned title, an
/// optional back chip before it and a close chip after it, over a hairline.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.title,
    this.subtitle,
    this.onBack,
    this.onClose,
    this.trailing,
    this.divider = true,
  });

  final String? title;

  /// Small line under the title, e.g. "Step 2 of 4".
  final String? subtitle;
  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final Widget? trailing;
  final bool divider;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: EdgeInsets.fromLTRB(
        onBack != null ? 12 : Insets.xl,
        8,
        onClose != null || trailing != null ? 12 : Insets.xl,
        8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: divider
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            NavChip(onPressed: onBack!),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.heading,
                  ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption,
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          if (onClose != null) ...[
            const SizedBox(width: 8),
            NavChip(
              onPressed: onClose!,
              icon: Icons.close_rounded,
              tooltip: 'Close',
            ),
          ],
        ],
      ),
    ),
  );
}

/// A large title and an optional line of supporting copy.
class ScreenIntro extends StatelessWidget {
  const ScreenIntro({
    super.key,
    required this.title,
    this.subtitle,
    this.display = false,
    this.center = false,
  });
  final String title;
  final String? subtitle;
  final bool display;
  final bool center;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: center
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start,
    children: [
      Text(
        title,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: display ? AppText.display : AppText.headline,
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 10),
        Text(
          subtitle!,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: AppText.bodyMuted.copyWith(fontSize: 15.5),
        ),
      ],
    ],
  );
}

/// Two- or three-way switch styled as a grey track with a white thumb.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.chip,
      borderRadius: Corners.mdRadius,
    ),
    child: Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Semantics(
              button: true,
              selected: i == index,
              label: labels[i],
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: i == index
                        ? const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 6,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: i == index
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: i == index ? AppColors.ink : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

// ── Surfaces ────────────────────────────────────────────────────────────

/// A tinted card with the corner arcs — for when a service or a biller is
/// the subject of the screen.
class TintCard extends StatelessWidget {
  const TintCard({
    super.key,
    required this.tint,
    required this.arc,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.selected = false,
  });
  final Color tint;
  final Color arc;
  final Widget child;
  final EdgeInsets padding;

  /// Draws a navy ring, for when the card is a choice.
  final bool selected;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 160),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: tint,
      borderRadius: Corners.xlRadius,
      border: Border.all(
        color: selected ? AppColors.navy : Colors.transparent,
        width: 2,
      ),
    ),
    child: Stack(
      fit: StackFit.passthrough,
      children: [
        CornerArcs(color: arc),
        Padding(padding: padding, child: child),
      ],
    ),
  );
}

/// Navy panel with the grid texture: balances and other headline numbers.
class NavyPanel extends StatelessWidget {
  const NavyPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = Corners.xl,
  });
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.navyDeep, AppColors.navy, AppColors.navyLight],
      ),
    ),
    child: Stack(
      fit: StackFit.passthrough,
      children: [
        const GridTexture(),
        Padding(padding: padding, child: child),
      ],
    ),
  );
}

/// Bordered group of label/value rows separated by hairlines.
class DetailGroup extends StatelessWidget {
  const DetailGroup({super.key, required this.rows});
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: Corners.mdRadius,
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          rows[i],
          if (i != rows.length - 1) const Divider(height: 1),
        ],
      ],
    ),
  );
}

class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.stacked = false,
    this.emphasis = false,
    this.valueColor,
    this.trailing,
  });
  final String label;
  final String value;
  final bool stacked;
  final bool emphasis;
  final Color? valueColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(
      fontSize: emphasis ? 16 : 15,
      fontWeight: emphasis ? FontWeight.w800 : FontWeight.w500,
      color: valueColor ?? AppColors.ink,
      height: 1.4,
      fontFeatures: AppText.tabularFigures,
    );
    const labelStyle = TextStyle(
      fontSize: 14,
      color: AppColors.muted,
      height: 1.4,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: stacked
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: labelStyle),
                      const SizedBox(height: 3),
                      Text(value, style: valueStyle),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: valueStyle,
                  ),
                ),
              ],
            ),
    );
  }
}

/// A settings-style list: rows with an icon tile, a label and a chevron.
class MenuGroup extends StatelessWidget {
  const MenuGroup({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: Corners.lgRadius,
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1)
            const Padding(
              padding: EdgeInsets.only(left: 68),
              child: Divider(height: 1),
            ),
        ],
      ],
    ),
  );
}

class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.value,
    this.danger = false,
  });
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final String? value;
  final bool danger;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: danger ? AppColors.dangerBg : AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 21,
              color: danger ? AppColors.danger : AppColors.ink,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.subtitle.copyWith(
                    fontWeight: FontWeight.w500,
                    color: danger ? AppColors.danger : AppColors.ink,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption,
                  ),
              ],
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(fontSize: 13.5),
              ),
            ),
          ],
          if (!danger) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.faint,
              size: 22,
            ),
          ],
        ],
      ),
    ),
  );
}

/// Grey date marker that heads each day in a list.
class DateChip extends StatelessWidget {
  const DateChip(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: Corners.pill,
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        ),
      ),
    ),
  );
}

/// Initials in a rounded square — the user's avatar until photos exist.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.initials,
    this.size = 44,
    this.onNavy = false,
  });
  final String initials;
  final double size;
  final bool onNavy;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: onNavy ? Colors.white : AppColors.navySoft,
      borderRadius: BorderRadius.circular(size * 0.3),
    ),
    child: Text(
      initials,
      style: TextStyle(
        fontSize: size * 0.36,
        fontWeight: FontWeight.w800,
        color: AppColors.navy,
        letterSpacing: 0.3,
      ),
    ),
  );
}

/// Painted radio indicator for custom selectable cards.
class RadioDot extends StatelessWidget {
  const RadioDot({super.key, required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    width: 22,
    height: 22,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: selected ? Colors.white : Colors.transparent,
      border: Border.all(
        color: selected ? AppColors.navy : AppColors.lineStrong,
        width: selected ? 6.5 : 1.6,
      ),
    ),
  );
}

/// Segmented progress through a flow, with the current step named.
class StageProgress extends StatelessWidget {
  const StageProgress({
    super.key,
    required this.total,
    required this.current,
    required this.label,
  });
  final int total;
  final int current;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Step ${math.min(current + 1, total)} of $total: $label',
    excludeSemantics: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.subtitle,
              ),
            ),
            Text(
              'Step ${math.min(current + 1, total)} of $total',
              style: AppText.caption,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  height: 6,
                  decoration: BoxDecoration(
                    color: i <= current ? AppColors.navy : AppColors.line,
                    borderRadius: Corners.pill,
                  ),
                ),
              ),
              if (i != total - 1) const SizedBox(width: 4),
            ],
          ],
        ),
      ],
    ),
  );
}

/// Semantic status panel: icon and title in the tone's colour on its tint.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.tone,
    required this.title,
    this.message,
  });
  final BadgeTone tone;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
    decoration: BoxDecoration(
      color: tone.background,
      borderRadius: Corners.mdRadius,
      border: Border.all(color: tone.border.withValues(alpha: 0.6)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(tone.icon, color: tone.foreground, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: tone == BadgeTone.neutral
                      ? AppColors.ink
                      : tone.foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  height: 1.35,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 3),
                Text(
                  message!,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// Bottom sheet that asks before an action runs. An optional [header] — a
/// service card, say — shows what the action applies to.
Future<bool> showConfirmationSheet(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  Widget? header,
}) async {
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Insets.xl, 4, Insets.xl, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (header != null) ...[header, const SizedBox(height: 20)],
                Text(title, style: AppText.title),
                const SizedBox(height: 8),
                Text(message, style: AppText.bodyMuted),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: confirmLabel,
                  onPressed: () => Navigator.pop(context, true),
                ),
                const SizedBox(height: 10),
                SecondaryButton(
                  label: cancelLabel,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
          ),
        ),
      ) ??
      false;
}

// ── Brand patterns ──────────────────────────────────────────────────────

/// Concentric, broken arcs anchored in a corner of a card. Decorative.
class CornerArcs extends StatelessWidget {
  const CornerArcs({
    super.key,
    required this.color,
    this.size = 150,
    this.alignment = Alignment.bottomRight,
  });
  final Color color;
  final double size;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: ExcludeSemantics(
        child: Align(
          alignment: alignment,
          child: SizedBox.square(
            dimension: size,
            child: CustomPaint(
              painter: _ArcsPainter(color: color, alignment: alignment),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ArcsPainter extends CustomPainter {
  _ArcsPainter({required this.color, required this.alignment});
  final Color color;
  final Alignment alignment;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round;
    final centre = Offset(
      size.width * (0.5 + alignment.x * 0.55),
      size.height * (0.5 + alignment.y * 0.55),
    );
    final start = math.atan2(-alignment.y, -alignment.x) - math.pi / 2;
    const gaps = [
      [0.0, 1.0],
      [0.0, 0.42, 0.55, 1.0],
      [0.0, 0.18, 0.3, 0.7, 0.8, 1.0],
      [0.0, 0.5, 0.62, 1.0],
    ];
    for (var ring = 0; ring < gaps.length; ring++) {
      final radius = size.width * (0.18 + ring * 0.2);
      final rect = Rect.fromCircle(center: centre, radius: radius);
      final segments = gaps[ring];
      for (var i = 0; i < segments.length; i += 2) {
        canvas.drawArc(
          rect,
          start + segments[i] * math.pi,
          (segments[i + 1] - segments[i]) * math.pi,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ArcsPainter old) =>
      old.color != color || old.alignment != alignment;
}

/// A fine grid with a few lit cells, fading towards the bottom-left. Used
/// on navy surfaces — the GRID name, drawn.
class GridTexture extends StatelessWidget {
  const GridTexture({super.key, this.opacity = 1, this.cell = 26});
  final double opacity;
  final double cell;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: ExcludeSemantics(
        child: CustomPaint(
          painter: _GridPainter(opacity: opacity, cell: cell),
        ),
      ),
    ),
  );
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.opacity, required this.cell});
  final double opacity;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    Shader fade(double alpha) => LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Colors.white.withValues(alpha: alpha * opacity),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.8],
    ).createShader(Offset.zero & size);
    final line = Paint()
      ..shader = fade(0.08)
      ..strokeWidth = 1;
    for (var x = size.width; x > 0; x -= cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var y = 0.0; y < size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final fill = Paint()..shader = fade(0.07);
    const lit = [(0, 1), (1, 2), (2, 0), (3, 3)];
    for (final (col, row) in lit) {
      final rect = Rect.fromLTWH(
        size.width - (col + 1) * cell + 3,
        row * cell + 3,
        cell - 6,
        cell - 6,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) =>
      old.opacity != opacity || old.cell != cell;
}

/// The four-cell mark: three solid cells and one lit (amber) cell.
class GridGlyph extends StatelessWidget {
  const GridGlyph({super.key, this.size = 28, this.light = false});
  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final solid = light ? Colors.white : AppColors.navy;
    final gap = size * 0.12;
    final cell = (size - gap) / 2;
    Widget box(Color color) => Container(
      width: cell,
      height: cell,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(cell * 0.3),
      ),
    );
    return SizedBox.square(
      dimension: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [box(solid), box(solid)],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [box(solid), box(AppColors.amber)],
          ),
        ],
      ),
    );
  }
}
