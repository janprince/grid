import 'package:flutter/material.dart';

import '../data/asset_catalog.dart';

/// How a service looks, keyed by its catalogue slug so a service the API adds
/// later still gets a sensible look: its colours, its glyph, and its 3D
/// artwork in `assets/images/services/3d/`.
///
/// Artwork is optional. The 3D render wins; the older emoji illustration is
/// the fallback; the glyph on the solid colour is the last resort.
class ServiceLook {
  const ServiceLook({
    required this.tint,
    required this.arc,
    required this.ink,
    required this.badge,
    required this.icon,
    this.legacyIcon,
    this.photo,
  });

  /// Tile background.
  final Color tint;

  /// Decorative arcs on the tint.
  final Color arc;

  /// Text and icon colour on the tint.
  final Color ink;

  /// Solid fill behind the glyph.
  final Color badge;
  final IconData icon;
  final String? legacyIcon;
  final String? photo;

  static const _fallback = ServiceLook(
    tint: Color(0xFFF1F3F6),
    arc: Color(0xFFE2E6EC),
    ink: Color(0xFF13294B),
    badge: Color(0xFF13294B),
    icon: Icons.home_repair_service_rounded,
  );

  static const _looks = <String, ServiceLook>{
    'cleaning': ServiceLook(
      tint: Color(0xFFEAF6F0),
      arc: Color(0xFFD4EEE1),
      ink: Color(0xFF16603F),
      badge: Color(0xFF1F7A52),
      icon: Icons.cleaning_services_rounded,
      legacyIcon: 'assets/images/services/icons/cleaning.png',
      photo: 'assets/images/services/cleaning.jpg',
    ),
    'laundry': ServiceLook(
      tint: Color(0xFFEAF1FB),
      arc: Color(0xFFD5E3F7),
      ink: Color(0xFF1F4888),
      badge: Color(0xFF2F62B5),
      icon: Icons.local_laundry_service_rounded,
      legacyIcon: 'assets/images/services/icons/laundry.png',
    ),
    'ac-servicing': ServiceLook(
      tint: Color(0xFFF0EEFB),
      arc: Color(0xFFDDD8F5),
      ink: Color(0xFF3E3187),
      badge: Color(0xFF5B4BB7),
      icon: Icons.ac_unit_rounded,
      legacyIcon: 'assets/images/services/icons/ac_servicing.png',
      photo: 'assets/images/services/ac_repair.jpg',
    ),
    'pest-control': ServiceLook(
      tint: Color(0xFFF4F6E6),
      arc: Color(0xFFE5EBC6),
      ink: Color(0xFF4F5A12),
      badge: Color(0xFF6B7A1A),
      icon: Icons.pest_control_rounded,
    ),
    'plumbing': ServiceLook(
      tint: Color(0xFFFBEEE7),
      arc: Color(0xFFF5DACB),
      ink: Color(0xFF7E3A19),
      badge: Color(0xFFB4532A),
      icon: Icons.plumbing_rounded,
      legacyIcon: 'assets/images/services/icons/plumbing.png',
      photo: 'assets/images/services/plumbing.jpg',
    ),
    'electrical': ServiceLook(
      tint: Color(0xFFFFF6E0),
      arc: Color(0xFFFCE8B5),
      ink: Color(0xFF7A5500),
      badge: Color(0xFFB07A00),
      icon: Icons.electrical_services_rounded,
      photo: 'assets/images/services/electrical.jpg',
    ),
  };

  static ServiceLook of(String slug) => _looks[slug] ?? _fallback;

  /// The 3D render for a service or package slug, if it shipped.
  static String art(String slug) => 'assets/images/services/3d/$slug.png';

  /// The best artwork available for [slug], or null for the glyph.
  static String? artFor(String slug) {
    if (AssetCatalog.has(art(slug))) return art(slug);
    final legacy = _looks[slug]?.legacyIcon;
    return AssetCatalog.has(legacy) ? legacy : null;
  }

  /// The package's own render, falling back to its service's.
  static String? packageArt(String packageSlug, String serviceSlug) =>
      AssetCatalog.has(art(packageSlug))
      ? art(packageSlug)
      : artFor(serviceSlug);
}
