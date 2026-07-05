class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
  });

  final String id;
  final String name;
  final String phone;
  final String? email;

  String get firstName => name.split(' ').first;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  AppUser copyWith({String? name, String? phone, String? email}) => AppUser(
    id: id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email ?? this.email,
  );
}
