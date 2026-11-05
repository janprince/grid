import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

import 'api_config.dart';
import 'api_exception.dart';
import 'session_store.dart';

/// HTTP access to the GRID API.
///
/// Kept in one place so repositories stay declarative: attaching the bearer
/// token, app id and a correlation id, unwrapping the response envelope,
/// turning failures into [ApiException], and refreshing an expired access
/// token exactly once even when several requests fail at the same moment.
class ApiClient {
  ApiClient(this._sessions, {Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = ApiConfig.baseUrl
      ..connectTimeout = ApiConfig.connectTimeout
      ..receiveTimeout = ApiConfig.receiveTimeout
      ..headers['Accept'] = 'application/json'
      ..headers['X-Grid-App'] = ApiConfig.appId
      // Let non-2xx through so the envelope can be parsed before deciding what to throw.
      ..validateStatus = (_) => true;
  }

  final Dio _dio;
  final SessionStore _sessions;
  final _random = Random();

  /// In-flight refresh, shared by every request that hits a 401 at the same
  /// time. Refresh tokens are single-use and rotate, so parallel refreshes
  /// would revoke each other.
  Future<Session?>? _refreshInFlight;

  /// Called when the session can no longer be recovered and the user must sign in again.
  void Function()? onSessionExpired;

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _send<T>('GET', path, query: query);

  /// [headers] are sent as-is and replayed with any token-refresh retry, so an
  /// `Idempotency-Key` stays the same across both attempts.
  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) => _send<T>('POST', path, body: body, headers: headers);

  Future<T> put<T>(String path, {Object? body}) =>
      _send<T>('PUT', path, body: body);

  Future<T> delete<T>(String path) => _send<T>('DELETE', path);

  Future<T> _send<T>(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    bool isRetry = false,
  }) async {
    final session = await _sessions.load();
    Response<dynamic> response;
    try {
      response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        options: Options(
          method: method,
          headers: {
            ...?headers,
            'X-Correlation-Id': _correlationId(),
            if (session != null)
              'Authorization': 'Bearer ${session.accessToken}',
          },
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }

    // An expired access token: refresh once, then replay the original request.
    if (response.statusCode == 401 && !isRetry && session != null) {
      final current = _sessions.current;
      // Another request already rotated the pair while this one was in flight.
      final refreshed =
          current != null && current.accessToken != session.accessToken
          ? current
          : await _refresh();
      if (refreshed != null) {
        return _send<T>(
          method,
          path,
          body: body,
          query: query,
          headers: headers,
          isRetry: true,
        );
      }
      // A failed refresh that left the session in place was a network
      // failure, not a dead token — keep the user signed in.
      if (_sessions.current == null) onSessionExpired?.call();
    }

    if (response.statusCode == null || response.statusCode! >= 400) {
      throw ApiException.fromDio(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
        ),
      );
    }

    return _unwrap<T>(response);
  }

  /// Pulls `data` out of the envelope. Void commands answer with no `data`
  /// key at all, which is legitimate whenever the caller expects nothing back.
  T _unwrap<T>(Response<dynamic> response) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data == null) {
        if (null is T) return null as T;
        throw ApiException(
          code: 'server.empty_response',
          message: 'GRID returned no data for this request.',
          statusCode: response.statusCode,
        );
      }
      return data as T;
    }
    if (body == null || (body is String && body.isEmpty)) {
      if (null is T) return null as T;
    }
    return body as T;
  }

  Future<Session?> _refresh() {
    // Collapse concurrent refreshes onto a single call.
    return _refreshInFlight ??= _performRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<Session?> _performRefresh() async {
    final session = await _sessions.load();
    if (session == null) return null;
    try {
      final response = await _dio.post<dynamic>(
        '/auth/tokens/refresh',
        data: {'refreshToken': session.refreshToken},
      );
      if (response.statusCode != 200) {
        // 5xx is the server's problem, not proof the token is dead.
        if ((response.statusCode ?? 500) < 500) await _sessions.clear();
        return null;
      }
      final data =
          (response.data as Map<String, dynamic>)['data']
              as Map<String, dynamic>;
      final updated = Session.fromAuthResponse(data);
      await _sessions.save(updated);
      return updated;
    } on DioException {
      // A network failure is not proof the token is dead — keep the session for a later retry.
      return null;
    }
  }

  String _correlationId() {
    const chars = 'abcdef0123456789';
    return List.generate(
      16,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
  }
}
