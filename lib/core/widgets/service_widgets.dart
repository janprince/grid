import 'package:flutter/material.dart';

import '../models/service_catalogue.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/service_art.dart';
import '../utils/formatters.dart';

/// A service's artwork on its soft tile: the 3D render, the older
/// illustration, or the glyph on the solid colour — whichever shipped.
///
/// [packageSlug] shows that package's own render when there is one.
class ServiceArt extends StatelessWidget {
  const ServiceArt({
    super.key,
    required this.slug,
    this.packageSlug,
    this.radius = Corners.lg,
    this.inset = 0.12,
    this.tint,
  });

  final String slug;
  final String? packageSlug;
  final double radius;

  /// Padding around the artwork, as a share of the tile's shorter side.
  final double inset;

  /// Overrides the service tint, e.g. a warm neutral behind every tile.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final look = ServiceLook.of(slug);
    final art = packageSlug == null
        ? ServiceLook.artFor(slug)
        : ServiceLook.packageArt(packageSlug!, slug);
    return ExcludeSemantics(
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: tint ?? look.tint,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final side = box.biggest.shortestSide;
            if (art != null) {
              return Padding(
                padding: EdgeInsets.all(side * inset),
                child: Image.asset(
                  art,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) => _Glyph(look: look, side: side),
                ),
              );
            }
            return _Glyph(look: look, side: side);
          },
        ),
      ),
    );
  }
}

class _Glyph extends StatelessWidget {
  const _Glyph({required this.look, required this.side});
  final ServiceLook look;
  final double side;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: side * 0.46,
      height: side * 0.46,
      decoration: BoxDecoration(
        color: look.badge,
        borderRadius: BorderRadius.circular(side * 0.14),
      ),
      child: Icon(look.icon, color: Colors.white, size: side * 0.24),
    ),
  );
}

/// The service's small square mark for rows and headers.
class ServiceBadge extends StatelessWidget {
  const ServiceBadge({super.key, required this.slug, this.size = 44});
  final String slug;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: ServiceArt(slug: slug, radius: size * 0.28, inset: 0.1),
  );
}

/// A service as a square of artwork with its name beneath — how services are
/// picked from a grid or a row.
class ServiceTile extends StatelessWidget {
  const ServiceTile({
    super.key,
    required this.service,
    required this.onTap,
    this.showPrice = false,
  });
  final ServiceItem service;
  final VoidCallback onTap;
  final bool showPrice;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    child: Semantics(
      button: true,
      label: '${service.name}, from ${Fmt.cedisShort(service.fromPrice)}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ServiceArt(slug: service.slug, radius: Corners.lg),
          ),
          const SizedBox(height: 8),
          Text(
            service.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(
              color: AppColors.ink,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          if (showPrice)
            Text(
              'From ${Fmt.cedisShort(service.fromPrice)}',
              textAlign: TextAlign.center,
              maxLines: 1,
              style: AppText.caption.copyWith(
                fontSize: 12.5,
                fontFeatures: AppText.tabularFigures,
              ),
            ),
        ],
      ),
    ),
  );
}

/// A service shown off: artwork on the left, what it is and its price on the
/// right, and one button. For the dashboard's featured carousel.
class FeaturedServiceCard extends StatelessWidget {
  const FeaturedServiceCard({
    super.key,
    required this.service,
    required this.onTap,
  });
  final ServiceItem service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final look = ServiceLook.of(service.slug);
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: Corners.xlRadius,
          boxShadow: AppColors.raisedShadow,
        ),
        child: Row(
          children: [
            AspectRatio(
              aspectRatio: 0.82,
              child: ServiceArt(
                slug: service.slug,
                radius: Corners.lg,
                inset: 0.14,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.quoted ? 'QUOTED ON SITE' : 'FIXED PRICE',
                    style: AppText.overline.copyWith(color: look.ink),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    service.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title.copyWith(fontSize: 19),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'From ${Fmt.cedisShort(service.fromPrice)}',
                            maxLines: 1,
                            style: AppText.subtitle.copyWith(
                              fontFeatures: AppText.tabularFigures,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.navy,
                          borderRadius: Corners.pill,
                        ),
                        child: const Text(
                          'Book',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Add", then − 2 + once added. [max] of 1 makes it a simple toggle.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.max,
    required this.onChanged,
    this.label = 'item',
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  /// For screen readers, e.g. "bag".
  final String label;

  @override
  Widget build(BuildContext context) {
    if (value == 0) {
      return OutlinedButton(
        onPressed: () => onChanged(1),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(76, 40),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: const StadiumBorder(),
          textStyle: AppText.button.copyWith(fontSize: 14),
        ),
        child: const Text('Add'),
      );
    }
    Widget button(IconData icon, String tip, VoidCallback? onTap) => IconButton(
      onPressed: onTap,
      tooltip: tip,
      icon: Icon(icon, size: 18),
      color: AppColors.navy,
      disabledColor: AppColors.faint,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      padding: EdgeInsets.zero,
    );
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navySoft,
        borderRadius: Corners.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(
            value == 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
            value == 1 ? 'Remove' : 'One less $label',
            () => onChanged(value - 1),
          ),
          Semantics(
            liveRegion: true,
            child: SizedBox(
              width: 22,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: AppText.subtitle.copyWith(
                  fontFeatures: AppText.tabularFigures,
                ),
              ),
            ),
          ),
          button(
            Icons.add_rounded,
            'One more $label',
            value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

/// Tap target that dips slightly while pressed. Artwork has no surface for
/// an ink ripple to read on, so the whole tile answers the touch instead.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: widget.onTap,
    onTapDown: (_) => _set(true),
    onTapUp: (_) => _set(false),
    onTapCancel: () => _set(false),
    child: AnimatedScale(
      scale: _down ? 0.97 : 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}
