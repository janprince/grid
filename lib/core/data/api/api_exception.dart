import 'package:dio/dio.dart';

/// A failure surfaced by the GRID API or by the network beneath it.
///
/// The API wraps everything in `{success, data, error, traceId, timestamp}`
/// and puts a stable machine-readable identifier in `error.code` — that code
/// is what callers should branch on, never the message.
class ApiException implements Exception {
  ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
    this.detail = const {},
    this.detailList = const [],
    this.traceId,
  });

  /// Stable identifier such as `auth.otp_invalid` or `utility_accounts.duplicate`.
  final String code;
  final String message;
  final int? statusCode;

  /// Field-level validation messages keyed by field name.
  final Map<String, String> fieldErrors;

  /// Structured extras, e.g. `attemptsRemaining` or `retryAfterSeconds`.
  final Map<String, dynamic> detail;

  /// Extras sent as a list, e.g. the meters behind `bills.meter_selection_required`.
  final List<dynamic> detailList;
  final String? traceId;

  bool get isUnauthorized =>
      statusCode == 401 || code == 'auth.unauthenticated';

  /// True when the request never reached the server, so retrying later may succeed.
  bool get isOffline => code == 'network.offline' || code == 'network.timeout';

  int? get retryAfterSeconds => _int(detail['retryAfterSeconds']);
  int? get attemptsRemaining => _int(detail['attemptsRemaining']);

  static int? _int(Object? value) =>
      value is num ? value.toInt() : int.tryParse('${value ?? ''}');

  @override
  String toString() => 'ApiException($code, $statusCode): $message';

  /// Builds an exception from a Dio failure, handling both response shapes.
  factory ApiException.fromDio(DioException error) {
    final response = error.response;

    if (response == null) {
      final offline =
          error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.unknown;
      return ApiException(
        code: offline ? 'network.offline' : 'network.timeout',
        message: offline
            ? 'Can’t reach GRID. Check your connection and try again.'
            : 'GRID took too long to respond. Try again.',
      );
    }

    final body = response.data;
    if (body is Map<String, dynamic> && body['error'] is Map<String, dynamic>) {
      final err = body['error'] as Map<String, dynamic>;
      final fields = <String, String>{};
      final rawFields = err['fields'];
      if (rawFields is List) {
        for (final item in rawFields) {
          if (item is Map<String, dynamic>) {
            final field = item['field']?.toString();
            final message = item['message']?.toString();
            if (field != null && message != null) fields[field] = message;
          }
        }
      }
      final detail = err['detail'];
      return ApiException(
        code: err['code']?.toString() ?? 'server.error',
        message: err['message']?.toString() ?? 'Something went wrong.',
        statusCode: response.statusCode,
        fieldErrors: fields,
        detail: detail is Map<String, dynamic> ? detail : const {},
        detailList: detail is List ? detail : const [],
        traceId: body['traceId']?.toString(),
      );
    }

    // Not enveloped: anything a proxy injects.
    return ApiException(
      code: switch (response.statusCode) {
        401 => 'auth.unauthenticated',
        403 => 'auth.forbidden',
        404 => 'server.not_found',
        _ => 'server.error',
      },
      message: switch (response.statusCode) {
        401 => 'Your session has expired. Sign in again.',
        403 => 'You do not have permission to do that.',
        404 => 'That was not found.',
        _ => 'Something went wrong. Try again.',
      },
      statusCode: response.statusCode,
    );
  }
}

/// A sentence to show the person for any failure from an API call.
String errorMessage(Object error) =>
    error is ApiException ? error.message : 'Something went wrong. Try again.';
