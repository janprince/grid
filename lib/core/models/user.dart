class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    this.givenName,
    this.lastName,
    this.email,
    this.profileComplete = true,
  });

  /// Reads the API's `user` (auth) or consumer profile object.
  factory AppUser.fromJson(Map<String, dynamic> json) {
    final first = json['firstName'] as String?;
    final last = json['lastName'] as String?;
    return AppUser(
      id: json['id'] as String,
      name:
          (json['fullName'] as String?) ??
          [first, last].whereType<String>().join(' '),
      phone: json['phoneNumber'] as String? ?? '',
      givenName: first,
      lastName: last,
      email: json['email'] as String?,
      profileComplete: json['profileComplete'] as bool? ?? false,
    );
  }

  final String id;

  /// Full display name.
  final String name;
  final String phone;
  final String? lastName;
  final String? email;

  /// False until the person has told GRID their name after first sign-in.
  final bool profileComplete;

  /// First name as the person typed it; null for older demo sessions.
  final String? givenName;

  String get firstName => (givenName?.isNotEmpty ?? false)
      ? givenName!
      : name.split(' ').first;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) return 'G';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  AppUser copyWith({String? name, String? phone, String? email}) => AppUser(
    id: id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    givenName: givenName,
    lastName: lastName,
    email: email ?? this.email,
    profileComplete: profileComplete,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': name,
    'phoneNumber': phone,
    'firstName': givenName,
    'lastName': lastName,
    'email': email,
    'profileComplete': profileComplete,
  };
}
