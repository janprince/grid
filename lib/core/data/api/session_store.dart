import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The authenticated session as issued by `POST /auth/otp/verify`.
class Session {
  const Session({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;

  /// The API's `user` object, kept so the app can open signed in while offline.
  final Map<String, dynamic> user;

  Session copyWith({
    String? accessToken,
    DateTime? accessTokenExpiresAt,
    String? refreshToken,
    Map<String, dynamic>? user,
  }) => Session(
    accessToken: accessToken ?? this.accessToken,
    accessTokenExpiresAt: accessTokenExpiresAt ?? this.accessTokenExpiresAt,
    refreshToken: refreshToken ?? this.refreshToken,
    user: user ?? this.user,
  );

  /// Reads the token-pair response shared by verify and refresh.
  factory Session.fromAuthResponse(Map<String, dynamic> data) => Session(
    accessToken: data['accessToken'] as String,
    accessTokenExpiresAt: DateTime.parse(data['accessTokenExpiresAt'] as String),
    refreshToken: data['refreshToken'] as String,
    user: data['user'] as Map<String, dynamic>,
  );

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'accessTokenExpiresAt': accessTokenExpiresAt.toIso8601String(),
    'refreshToken': refreshToken,
    'user': user,
  };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    accessToken: json['accessToken'] as String,
    accessTokenExpiresAt: DateTime.parse(
      json['accessTokenExpiresAt'] as String,
    ),
    refreshToken: json['refreshToken'] as String,
    user: json['user'] as Map<String, dynamic>,
  );
}

/// Persists the session in platform secure storage (Keychain /
/// EncryptedSharedPreferences). Refresh tokens are long-lived bearer
/// credentials, so they never go in shared_preferences.
class SessionStore {
  SessionStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  static const _key = 'grid.home.session';

  final FlutterSecureStorage _storage;
  Session? _cached;

  /// The session as of the last [load] or [save]. main() loads it before the
  /// first frame so the router can decide synchronously where to start.
  Session? get current => _cached;

  Future<Session?> load() async {
    if (_cached != null) return _cached;
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      return _cached = Session.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on Object {
      await clear();
      return null;
    }
  }

  Future<void> save(Session session) async {
    _cached = session;
    await _storage.write(key: _key, value: jsonEncode(session.toJson()));
  }

  Future<void> clear() async {
    _cached = null;
    await _storage.delete(key: _key);
  }
}
