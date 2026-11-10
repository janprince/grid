import 'package:flutter/material.dart';

import '../data/asset_catalog.dart';
import '../models/bill_payment.dart';
import '../models/utility_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/biller_brand.dart';

/// A biller's identity: its logo as a full rounded tile.
///
/// Every file in `assets/images/billers/` is the same square tile with the
/// logo already on its ground, so a list of billers lines up however different
/// the logos are. Airtime and data have no single mark until the network is
/// known; pass [network] wherever it is, and they show that network's logo.
class BillerMark extends StatelessWidget {
  const BillerMark(this.type, {super.key, this.size = 44, this.network});

  final UtilityType type;
  final double size;
  final MobileNetwork? network;

  @override
  Widget build(BuildContext context) => _MarkTile(
    brand: BillerBrand.resolve(type, network),
    glyph: type.icon,
    size: size,
  );
}

/// A mobile network's logo, for wallets and network choices.
class NetworkMark extends StatelessWidget {
  const NetworkMark(this.network, {super.key, this.size = 40});

  final MobileNetwork network;
  final double size;

  @override
  Widget build(BuildContext context) => _MarkTile(
    brand: BillerBrand.ofNetwork(network),
    glyph: Icons.smartphone_rounded,
    size: size,
  );
}

class _MarkTile extends StatelessWidget {
  const _MarkTile({
    required this.brand,
    required this.glyph,
    required this.size,
  });

  final BillerBrand brand;
  final IconData glyph;
  final double size;

  @override
  Widget build(BuildContext context) {
    final path = AssetCatalog.has(brand.assetPath) ? brand.assetPath : null;
    final radius = BorderRadius.circular(size * 0.27);
    final fallback = Center(
      child: Icon(glyph, color: brand.color, size: size * 0.5),
    );

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: path == null ? brand.tint : null,
        borderRadius: radius,
      ),
      // Some logos sit on white; the hairline keeps those tiles defined.
      foregroundDecoration: path == null
          ? null
          : BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: AppColors.line),
            ),
      child: path == null
          ? fallback
          : Image.asset(
              path,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}

/// The biller mark reduced to a colour chip, used where a row already
/// carries the biller's name and a full mark would be redundant.
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
