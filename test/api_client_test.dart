import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid/core/data/api/api_client.dart';
import 'package:grid/core/data/api/api_exception.dart';
import 'package:grid/core/data/api/session_store.dart';

/// Answers requests from a handler instead of the network.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final Future<(int, Object?)> Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (status, body) = await handler(options);
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _ok(Object? data) => {
  'success': true,
  'data': data,
  'error': null,
};

Map<String, dynamic> _fail(String code, {Map<String, dynamic>? detail}) => {
  'success': false,
  'error': {
    'code': code,
    'message': 'Nope',
    'detail': detail,
    'fields': [
      {'field': 'accountNumber', 'message': 'Too short'},
    ],
  },
};

Map<String, dynamic> _tokens(String access, String refresh) => {
  'accessToken': access,
  'accessTokenExpiresAt': '2026-10-17T12:00:00Z',
  'refreshToken': refresh,
  'refreshTokenExpiresAt': '2026-12-17T12:00:00Z',
  'isNewUser': false,
  'user': {'id': 'u1', 'phoneNumber': '233550000001', 'profileComplete': true},
};

void main() {
  late SessionStore sessions;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    sessions = SessionStore();
    await sessions.save(Session.fromAuthResponse(_tokens('old', 'r1')));
  });

  ApiClient client(_FakeAdapter adapter) =>
      ApiClient(sessions, dio: Dio()..httpClientAdapter = adapter);

  test('unwraps data and identifies the app on every request', () async {
    final adapter = _FakeAdapter((_) async => (200, _ok({'id': 'p1'})));
    final data = await client(adapter).get<Map<String, dynamic>>('/x');

    expect(data, {'id': 'p1'});
    final headers = adapter.requests.single.headers;
    expect(headers['X-Grid-App'], 'consumer');
    expect(headers['Authorization'], 'Bearer old');
  });

  test('accepts an envelope with no data key for void commands', () async {
    final adapter = _FakeAdapter(
      (_) async => (200, {'success': true, 'error': null}),
    );
    await client(adapter).delete<void>('/properties/p1');
  });

  test('turns an error envelope into ApiException with fields and detail', () async {
    final adapter = _FakeAdapter(
      (_) async =>
          (400, _fail('auth.otp_invalid', detail: {'attemptsRemaining': 3})),
    );

    await expectLater(
      client(adapter).post<Object?>('/auth/otp/verify'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'auth.otp_invalid')
            .having((e) => e.attemptsRemaining, 'attempts', 3)
            .having((e) => e.fieldErrors['accountNumber'], 'field', 'Too short'),
      ),
    );
  });

  test('concurrent 401s share one refresh, then replay', () async {
    var refreshCalls = 0;
    final refreshGate = Completer<void>();
    final adapter = _FakeAdapter((options) async {
      if (options.path == '/auth/tokens/refresh') {
        refreshCalls++;
        expect(options.data, {'refreshToken': 'r1'});
        await refreshGate.future;
        return (200, _ok(_tokens('new', 'r2')));
      }
      return options.headers['Authorization'] == 'Bearer new'
          ? (200, _ok(options.path))
          : (401, _fail('auth.unauthenticated'));
    });
    final api = client(adapter);

    final results = Future.wait([
      api.get<String>('/a'),
      api.get<String>('/b'),
      api.get<String>('/c'),
    ]);
    await Future<void>.delayed(Duration.zero);
    refreshGate.complete();

    expect(await results, ['/a', '/b', '/c']);
    expect(refreshCalls, 1);
    expect(sessions.current!.refreshToken, 'r2');
  });

  test('a rejected refresh clears the session and reports expiry', () async {
    var expired = false;
    final adapter = _FakeAdapter(
      (options) async => options.path == '/auth/tokens/refresh'
          ? (401, _fail('auth.refresh_invalid'))
          : (401, _fail('auth.unauthenticated')),
    );
    final api = client(adapter)..onSessionExpired = () => expired = true;

    await expectLater(api.get<Object?>('/a'), throwsA(isA<ApiException>()));
    expect(expired, isTrue);
    expect(sessions.current, isNull);
  });
}
