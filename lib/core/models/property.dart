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
  });

  final String id;
  final String nickname;
  final String area;
  final String city;
  final String address;
  final PropertyKind kind;
  final bool isPrimary;

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
  );
}
