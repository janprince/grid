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
  );
}
