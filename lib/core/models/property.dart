enum PropertyKind { house, apartment, office }

class Property {
  const Property({
    required this.id,
    required this.nickname,
    required this.area,
    required this.city,
    required this.address,
    this.kind = PropertyKind.house,
    this.isPrimary = false,
    this.ghanaPostGps,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String nickname;
  final String area;
  final String city;
  final String address;
  final PropertyKind kind;
  final bool isPrimary;

  /// Digital address such as `GA-123-4567`. Not edited in the app yet, but
  /// carried through so a full-replace update never clears it.
  final String? ghanaPostGps;

  /// Where the home is, when known. Not edited in the app, but carried
  /// through every update: the API replaces the whole home, and a home
  /// without coordinates gives the professional no map pin.
  final double? latitude;
  final double? longitude;

  /// e.g. "East Legon, Accra"
  String get location => '$area, $city';

  Property copyWith({
    String? nickname,
    String? area,
    String? city,
    String? address,
    PropertyKind? kind,
    bool? isPrimary,
  }) => Property(
    id: id,
    nickname: nickname ?? this.nickname,
    area: area ?? this.area,
    city: city ?? this.city,
    address: address ?? this.address,
    kind: kind ?? this.kind,
    isPrimary: isPrimary ?? this.isPrimary,
    ghanaPostGps: ghanaPostGps,
    // A home moved to another area no longer sits at the old point.
    latitude: _sameArea(area, city) ? latitude : null,
    longitude: _sameArea(area, city) ? longitude : null,
  );

  bool _sameArea(String? area, String? city) =>
      (area == null || area == this.area) &&
      (city == null || city == this.city);
}
