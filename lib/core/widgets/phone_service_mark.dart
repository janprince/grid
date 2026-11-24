import 'package:flutter/material.dart';

import '../models/utility_type.dart';
import '../theme/app_colors.dart';

/// GRID's own tile for airtime and data before a network is chosen.
///
/// They span MTN, Telecel and AT, so no network logo is right, and a pale
/// generic icon looked unfinished beside the full-colour biller logos. This is
/// a solid navy tile (the same weight as a logo) with a white phone and an
/// amber badge for what's being bought: + for airtime, ↑↓ for data.
class PhoneServiceMark extends StatelessWidget {
  const PhoneServiceMark(this.type, {super.key, this.size = 44})
    : assert(
        type == UtilityType.airtime || type == UtilityType.dataBundle,
        'Only airtime and data have a GRID mark',
      );

  final UtilityType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: type.shortLabel,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _PhoneServicePainter(
            data: type == UtilityType.dataBundle,
          ),
        ),
      ),
    );
  }
}

class _PhoneServicePainter extends CustomPainter {
  const _PhoneServicePainter({required this.data});

  final bool data;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    // Tile, with the same corner ratio as the logo tiles.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(s * 0.27)),
      Paint()..color = AppColors.navy,
    );

    // Phone outline, set a little low and left so the badge can sit on
    // its top-right corner.
    final stroke = s * 0.056;
    final phone = Rect.fromCenter(
      center: Offset(s * 0.41, s * 0.54),
      width: s * 0.34,
      height: s * 0.52,
    );
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawRRect(
      RRect.fromRectAndRadius(phone, Radius.circular(s * 0.075)),
      white,
    );
    // Home bar.
    final barY = phone.bottom - s * 0.085;
    canvas.drawLine(
      Offset(phone.center.dx - s * 0.05, barY),
      Offset(phone.center.dx + s * 0.05, barY),
      white..strokeWidth = stroke * 0.8,
    );

    // Amber badge, ringed in navy so it cuts cleanly into the outline.
    final badge = Offset(s * 0.625, s * 0.345);
    final r = s * 0.165;
    canvas.drawCircle(badge, r + s * 0.045, Paint()..color = AppColors.navy);
    canvas.drawCircle(badge, r, Paint()..color = AppColors.amber);

    final ink = Paint()
      ..color = AppColors.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.042
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (!data) {
      final arm = r * 0.52;
      canvas
        ..drawLine(badge.translate(-arm, 0), badge.translate(arm, 0), ink)
        ..drawLine(badge.translate(0, -arm), badge.translate(0, arm), ink);
      return;
    }

    // Data: an up arrow and a down arrow side by side.
    final half = r * 0.5;
    final head = r * 0.3;
    final gap = r * 0.3;
    void arrow(double x, {required bool up}) {
      final tip = badge.translate(x, up ? -half : half);
      final tail = badge.translate(x, up ? half : -half);
      final back = up ? head : -head;
      canvas
        ..drawLine(tail, tip, ink)
        ..drawPath(
          Path()
            ..moveTo(tip.dx - head, tip.dy + back)
            ..lineTo(tip.dx, tip.dy)
            ..lineTo(tip.dx + head, tip.dy + back),
          ink,
        );
    }

    arrow(-gap, up: true);
    arrow(gap, up: false);
  }

  @override
  bool shouldRepaint(_PhoneServicePainter old) => old.data != data;
}
