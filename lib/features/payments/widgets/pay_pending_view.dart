import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import 'pay_help_sheet.dart';

/// "Approve on your phone": the screen that waits while the MoMo prompt is
/// out. It says exactly where the prompt went, keeps something gently moving
/// so the wait doesn't read as frozen, and keeps help one tap away.
class PayPendingView extends StatefulWidget {
  const PayPendingView({
    super.key,
    required this.title,
    required this.message,
    this.phone,
    this.wallet,
    this.approved = false,
    this.onClose,
    this.footer,
  });

  final String title;
  final String message;

  /// The number the prompt went to, shown large with its wallet's mark.
  final String? phone;
  final MobileNetwork? wallet;

  /// The money is in; the biller is being paid.
  final bool approved;

  /// Leaves the wait; null while nothing can be left yet.
  final VoidCallback? onClose;

  /// Replaces the help button, e.g. while the request is still being sent.
  final Widget? footer;

  @override
  State<PayPendingView> createState() => _PayPendingViewState();
}

class _PayPendingViewState extends State<PayPendingView> {
  /// Prompts normally land within seconds; after this, say what to do.
  static const _patience = 20;

  int _left = _patience;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_left <= 1) timer.cancel();
      setState(() => _left--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phone = widget.phone;
    final showPromptHelp = phone != null && !widget.approved;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 60,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: widget.onClose == null
                        ? null
                        : NavChip(
                            onPressed: widget.onClose!,
                            icon: Icons.close_rounded,
                            tooltip: 'Close',
                            color: Colors.transparent,
                          ),
                  ),
                ),
              ),
              Expanded(
                // Centred in the space left, a little above the middle, and
                // still scrollable when large text pushes it past the edge.
                child: LayoutBuilder(
                  builder: (context, box) => SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: Insets.xxl),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: box.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PromptIllustration(approved: widget.approved),
                          const SizedBox(height: 36),
                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: AppText.headline,
                          ),
                          Gaps.md,
                          Text(
                            widget.message,
                            textAlign: TextAlign.center,
                            style: AppText.bodyMuted.copyWith(fontSize: 15.5),
                          ),
                          if (phone != null) ...[
                            Gaps.xl,
                            _PromptTarget(phone: phone, wallet: widget.wallet),
                          ],
                          if (showPromptHelp) ...[
                            Gaps.xl,
                            _PromptHint(
                              secondsLeft: _left,
                              onHelp: () => showPayHelpSheet(
                                context,
                                wallet: widget.wallet,
                              ),
                            ),
                          ],
                          const SizedBox(height: 56),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.xl,
                  Insets.sm,
                  Insets.xl,
                  Insets.lg,
                ),
                child:
                    widget.footer ??
                    SecondaryButton(
                      label: 'Need help?',
                      onPressed: () =>
                          showPayHelpSheet(context, wallet: widget.wallet),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromptTarget extends StatelessWidget {
  const _PromptTarget({required this.phone, this.wallet});

  final String phone;
  final MobileNetwork? wallet;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (wallet != null) ...[NetworkMark(wallet!, size: 34), Gaps.md],
      Flexible(
        child: Text(
          Fmt.ghanaPhone(phone),
          style: AppText.title.copyWith(fontFeatures: AppText.tabularFigures),
        ),
      ),
    ],
  );
}

/// "Didn't get the prompt?" — counts down first, because the prompt almost
/// always arrives in that time, then offers what to do.
class _PromptHint extends StatelessWidget {
  const _PromptHint({required this.secondsLeft, required this.onHelp});

  final int secondsLeft;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    final waiting = secondsLeft > 0;
    final style = AppText.caption.copyWith(fontSize: 14);
    return Semantics(
      liveRegion: !waiting,
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Didn\'t get the prompt? ', style: style),
          InkWell(
            onTap: waiting ? null : onHelp,
            borderRadius: Corners.smRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'See what to do',
                style: style.copyWith(
                  color: waiting ? AppColors.faint : AppColors.navy,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: waiting ? AppColors.faint : AppColors.navy,
                ),
              ),
            ),
          ),
          if (waiting)
            Text(
              ' (0:${secondsLeft.toString().padLeft(2, '0')})',
              style: style.copyWith(fontFeatures: AppText.tabularFigures),
            ),
        ],
      ),
    );
  }
}

/// A phone holding a MoMo prompt, its PIN dots filling one by one, with a
/// cedi coin drifting beside it. Once [approved], the dots are full and a
/// tick sits on the screen.
///
/// Drawn rather than shipped as an image so it stays sharp, takes GRID's
/// colours, and can hold still when the system asks for less motion.
class PromptIllustration extends StatefulWidget {
  const PromptIllustration({super.key, this.approved = false});

  final bool approved;

  @override
  State<PromptIllustration> createState() => _PromptIllustrationState();
}

class _PromptIllustrationState extends State<PromptIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _loop
        ..stop()
        ..value = 0.7;
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: 220,
      height: 180,
      child: AnimatedBuilder(
        animation: _loop,
        builder: (context, _) => CustomPaint(
          painter: _PromptPainter(t: _loop.value, approved: widget.approved),
        ),
      ),
    ),
  );
}

class _PromptPainter extends CustomPainter {
  _PromptPainter({required this.t, required this.approved});

  final double t;
  final bool approved;

  static const _ring = AppColors.navy;
  static final _cedi = TextPainter(
    text: const TextSpan(
      text: '₵',
      style: TextStyle(
        fontFamily: kBrandFont,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: Color(0xFF7A5200),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 4);
    final wave = math.sin(t * 2 * math.pi);

    // Soft ground and a cloud of light behind the phone.
    canvas.drawCircle(center, 74, Paint()..color = AppColors.navySoft);

    // Signal rings leaving the phone.
    for (var i = 0; i < 2; i++) {
      final p = (t + i * 0.5) % 1;
      canvas.drawCircle(
        center,
        48 + p * 50,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _ring.withValues(alpha: (1 - p) * 0.18),
      );
    }

    // The phone, bobbing and tilted a little.
    canvas.save();
    canvas.translate(center.dx - 6, center.dy + wave * 4);
    canvas.rotate(-0.1 + wave * 0.02);
    const body = Size(74, 124);
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: body.width,
        height: body.height,
      ),
      const Radius.circular(16),
    );
    canvas.drawRRect(
      bodyRect.shift(const Offset(3, 6)),
      Paint()..color = const Color(0x220B1526),
    );
    canvas.drawRRect(bodyRect, Paint()..color = AppColors.navy);
    final screen = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 2), width: 62, height: 104),
      const Radius.circular(10),
    );
    canvas.drawRRect(screen, Paint()..color = Colors.white);
    // Speaker slot.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, -56), width: 18, height: 3),
        const Radius.circular(2),
      ),
      Paint()..color = AppColors.navyLight,
    );

    // The prompt card on the screen.
    final card = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 0), width: 52, height: 64),
      const Radius.circular(8),
    );
    canvas.drawRRect(card, Paint()..color = AppColors.surfaceSubtle);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(card.left, card.top, card.width, 14),
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
      ),
      Paint()..color = AppColors.amber,
    );
    final lines = Paint()..color = AppColors.line;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(card.left + 7, card.top + 21, 38, 4),
        const Radius.circular(2),
      ),
      lines,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(card.left + 7, card.top + 29, 26, 4),
        const Radius.circular(2),
      ),
      lines,
    );

    // PIN dots: fill one by one, hold, then start over.
    final filled = approved ? 4 : (t * 6).floor().clamp(0, 4);
    for (var i = 0; i < 4; i++) {
      final dot = Offset(card.left + 11 + i * 10, card.top + 46);
      canvas.drawCircle(
        dot,
        3.4,
        Paint()..color = i < filled ? AppColors.navy : AppColors.lineStrong,
      );
    }

    if (approved) {
      final tick = Offset(0, card.bottom + 14);
      canvas.drawCircle(tick, 11, Paint()..color = AppColors.success);
      final path = Path()
        ..moveTo(tick.dx - 5, tick.dy)
        ..lineTo(tick.dx - 1.5, tick.dy + 3.5)
        ..lineTo(tick.dx + 5, tick.dy - 3.5);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = Colors.white,
      );
    }
    canvas.restore();

    // A cedi coin drifting beside the phone, out of step with it.
    final coin = Offset(
      center.dx + 56,
      center.dy - 46 - math.cos(t * 2 * math.pi) * 6,
    );
    canvas.drawCircle(
      coin.translate(1.5, 3),
      19,
      Paint()..color = const Color(0x1F0B1526),
    );
    canvas.drawCircle(coin, 19, Paint()..color = AppColors.amber);
    canvas.drawCircle(
      coin,
      14,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0x66FFFFFF),
    );
    _cedi.paint(canvas, coin - Offset(_cedi.width / 2, _cedi.height / 2));

    // Two small sparks on the other side.
    final spark = Paint()..color = AppColors.navyLight.withValues(alpha: 0.5);
    canvas.drawCircle(
      Offset(center.dx - 70, center.dy - 30 + wave * 3),
      4,
      spark,
    );
    canvas.drawCircle(
      Offset(center.dx - 54, center.dy + 50 - wave * 3),
      2.6,
      spark,
    );
  }

  @override
  bool shouldRepaint(_PromptPainter old) =>
      old.t != t || old.approved != approved;
}
