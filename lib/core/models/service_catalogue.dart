/// How a service is booked. Fixed-price services sell packages at GRID's
/// price; call-out services charge a visit and quote the work on site.
enum BookingMode { fixedPrice, callOutThenQuote }

/// Something a customer buys at GRID's price: "Standard clean · 2 bedrooms",
/// "General service" per AC unit.
class ServicePackage {
  const ServicePackage({
    required this.id,
    required this.slug,
    required this.group,
    required this.name,
    required this.price,
    this.summary,
    this.includes = const [],
    this.excludes = const [],
    this.durationMinutes = 0,
    this.unitLabel,
    this.maxQuantity = 1,
  });

  final String id;
  final String slug;

  /// The kind of job, e.g. "Deep clean". Packages sharing a group are sizes
  /// of the same job and only one of them can be booked at a time.
  final String group;
  final String name;
  final String? summary;
  final List<String> includes;
  final List<String> excludes;
  final double price;
  final int durationMinutes;

  /// What one of it is ("bag", "unit"). Null for a whole job.
  final String? unitLabel;
  final int maxQuantity;

  /// Booked in quantities (bags, AC units) rather than once.
  bool get countable => maxQuantity > 1;

  /// "Deep clean · 3 bedrooms", or just the name when it has no sizes.
  String get label => group == name ? name : '$group · $name';

  /// "per bag", or null for a whole job.
  String? get perUnit => unitLabel == null ? null : 'per $unitLabel';

  /// "About 3 h", "About 45 min", "Back in 2 days".
  String get durationLabel {
    if (durationMinutes <= 0) return '';
    if (durationMinutes >= 1440) {
      final days = (durationMinutes / 1440).round();
      return 'Back in $days day${days == 1 ? '' : 's'}';
    }
    if (durationMinutes < 60) return 'About $durationMinutes min';
    final hours = durationMinutes / 60;
    return 'About ${hours == hours.roundToDouble() ? hours.toInt() : hours.toStringAsFixed(1)} h';
  }
}

/// A bookable service and its packages, as GRID sells it.
class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.slug,
    required this.name,
    required this.section,
    required this.packages,
    this.description = '',
    this.bookingMode = BookingMode.fixedPrice,
    this.fromPrice = 0,
    this.skills = const [],
  });

  final String id;

  /// Stable key shared with the API and GRID Pro, e.g. `ac-servicing`.
  final String slug;
  final String name;
  final String description;
  final String section;
  final BookingMode bookingMode;
  final double fromPrice;

  /// What the professionals do, e.g. "Deep foam cleaning".
  final List<String> skills;
  final List<ServicePackage> packages;

  bool get quoted => bookingMode == BookingMode.callOutThenQuote;

  /// Pickup and return rather than a visit.
  bool get collected => slug == 'laundry';

  /// Packages grouped by job, in catalogue order: each group is either one
  /// countable item or a set of sizes to choose between.
  List<(String group, List<ServicePackage> options)> get groups {
    final order = <String>[];
    final byGroup = <String, List<ServicePackage>>{};
    for (final package in packages) {
      if (!byGroup.containsKey(package.group)) order.add(package.group);
      byGroup.putIfAbsent(package.group, () => []).add(package);
    }
    return [for (final group in order) (group, byGroup[group]!)];
  }

  ServicePackage? package(String id) {
    for (final package in packages) {
      if (package.id == id) return package;
    }
    return null;
  }
}

class ServiceSection {
  const ServiceSection({required this.name, required this.services});
  final String name;
  final List<ServiceItem> services;
}

/// Everything a customer can book, grouped the way the Services tab shows it.
class ServiceCatalogue {
  const ServiceCatalogue({required this.sections});

  final List<ServiceSection> sections;

  List<ServiceItem> get services => [
    for (final section in sections) ...section.services,
  ];

  ServiceItem? bySlug(String? slug) {
    for (final service in services) {
      if (service.slug == slug) return service;
    }
    return null;
  }

  /// Services whose name, description, skills or packages mention [query].
  List<ServiceItem> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return services;
    bool has(String? text) => text != null && text.toLowerCase().contains(q);
    return [
      for (final service in services)
        if (has(service.name) ||
            has(service.description) ||
            service.skills.any(has) ||
            service.packages.any((p) => has(p.label) || has(p.summary)))
          service,
    ];
  }
}

/// A package and how many of it, on its way to becoming a booking.
class BookingLine {
  const BookingLine(this.package, this.quantity);
  final ServicePackage package;
  final int quantity;

  double get total => package.price * quantity;
}
