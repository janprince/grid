import 'package:flutter/material.dart';

import '../models/service_category.dart';

/// Each service's tint, shared with GRID Pro: mint for cleaning, sky for
/// laundry. The tint is how a service is recognised before any text is read.
extension ServiceArt on ServiceCategory {
  /// Card background.
  Color get tint => switch (this) {
    ServiceCategory.cleaning => const Color(0xFFEAF6F0),
    ServiceCategory.laundry => const Color(0xFFEAF1FB),
  };

  /// Decorative arcs on the tint.
  Color get arc => switch (this) {
    ServiceCategory.cleaning => const Color(0xFFD4EEE1),
    ServiceCategory.laundry => const Color(0xFFD5E3F7),
  };

  /// Text and icon colour on the tint.
  Color get ink => switch (this) {
    ServiceCategory.cleaning => const Color(0xFF16603F),
    ServiceCategory.laundry => const Color(0xFF1F4888),
  };

  /// Solid badge behind the service icon.
  Color get badge => switch (this) {
    ServiceCategory.cleaning => const Color(0xFF1F7A52),
    ServiceCategory.laundry => const Color(0xFF2F62B5),
  };
}
