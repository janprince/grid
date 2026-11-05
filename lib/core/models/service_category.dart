import 'package:flutter/material.dart';

/// The home services GRID can book. Version 1 offers two — home cleaning and
/// laundry — matching what GRID Pro professionals can sign up for.
enum ServiceCategory {
  cleaning(
    label: 'Home cleaning',
    description: 'Regular, deep and move-out cleans',
    icon: Icons.cleaning_services_rounded,
    fromPrice: 150,
    priceUnit: 'per visit',
    issues: [
      'Standard cleaning',
      'Deep cleaning',
      'Move-in / move-out cleaning',
      'After-party cleaning',
      'Sofa & carpet cleaning',
    ],
  ),
  laundry(
    label: 'Laundry',
    description: 'Wash, iron and dry cleaning, picked up and delivered',
    icon: Icons.local_laundry_service_rounded,
    fromPrice: 60,
    priceUnit: 'per bag',
    issues: [
      'Wash & fold',
      'Wash & iron',
      'Ironing only',
      'Dry cleaning',
      'Duvets & bulky items',
    ],
  );

  const ServiceCategory({
    required this.label,
    required this.description,
    required this.icon,
    required this.fromPrice,
    required this.priceUnit,
    required this.issues,
  });

  final String label;
  final String description;
  final IconData icon;

  /// Lowest typical price in GHS, before the professional confirms.
  final double fromPrice;

  /// What [fromPrice] buys, e.g. "per visit".
  final String priceUnit;

  /// What the customer can ask for, e.g. "Deep cleaning".
  final List<String> issues;
}
