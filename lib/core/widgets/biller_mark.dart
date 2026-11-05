import 'package:flutter/material.dart';

import '../data/asset_catalog.dart';
import '../models/utility_type.dart';
import '../theme/app_spacing.dart';
import '../theme/biller_brand.dart';

/// A biller's identity: its logo on a wash of its own brand colour.
///
/// Replaces `TintedIcon` everywhere a *biller* is shown. The old treatment
/// gave ECG, DStv, MTN and Ghana Water the same teal glyph in the same
/// tinted square, so a list of utilities had no rhythm and nothing was
/// recognisable at a glance.
///
/// Artwork is optional by design. When the logo file is absent — or when a
/// biller has no single mark, as with airtime and data spanning MTN, Telecel
/// and AT — this falls back to the utility's own glyph in the brand colour.
/// The ground, size and radius are identical either way, so marks can be
/// added to `assets/images/billers/` one at a time without the list ever
/// looking half-finished.
class BillerMark extends StatelessWidget {
  const BillerMark(this.type, {super.key, this.size = 44});

  final UtilityType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final brand = type.brand;
    final path = AssetCatalog.has(brand.assetPath) ? brand.assetPath : null;
    // The supplied ECG artwork includes its own ground and clear space.
    final isEcgLogo = type == UtilityType.ecg && path != null;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isEcgLogo ? Colors.transparent : brand.tint,
        borderRadius: BorderRadius.circular(size * 0.27),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: path == null
          ? _glyph(brand)
          : Padding(
              padding: EdgeInsets.all(isEcgLogo ? 0 : size * 0.18),
              child: Image.asset(
                path,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => _glyph(brand),
              ),
            ),
    );
  }

  Widget _glyph(BillerBrand brand) =>
      Icon(type.icon, color: brand.color, size: size * 0.5);
}

/// The biller mark reduced to a colour chip — used where a row already
/// carries the biller's name and a full mark would be redundant, such as the
/// utility pills on a property card.
class BillerDot extends StatelessWidget {
  const BillerDot(this.type, {super.key, this.size = 8});

  final UtilityType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: type.brand.color,
        borderRadius: Corners.pill,
      ),
    );
  }
}
