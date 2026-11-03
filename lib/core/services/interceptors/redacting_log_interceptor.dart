import 'package:dio/dio.dart';

/// Names whose values must never reach a log: passwords, tokens and cookies.
/// Compared lower-case, ignoring `-` and `_`.
const _secretKeys = {
  'password',
  'currentpassword',
  'newpassword',
  'confirmpassword',
  'token',
  'accesstoken',
  'refreshtoken',
  'idtoken',
  'authorization',
  'cookie',
  'setcookie',
  'setauthtoken',
  'secret',
  'otp',
  'code',
};

const _redacted = '***';

bool _isSecret(String key) =>
    _secretKeys.contains(key.toLowerCase().replaceAll(RegExp('[-_]'), ''));

/// A copy of [value] with every secret replaced, however deeply it is nested.
Object? redactSecrets(Object? value) {
  if (value is Map) {
    return {
      for (final entry in value.entries)
        '${entry.key}':
            _isSecret('${entry.key}') ? _redacted : redactSecrets(entry.value),
    };
  }
  if (value is List) return [for (final item in value) redactSecrets(item)];
  if (value is FormData) {
    return '<form data: ${value.fields.length} fields, '
        '${value.files.length} files>';
  }
  return value;
}

/// Logs each request and response for development without leaking sign-in
/// details: the method, address and status, and the bodies with secrets
/// redacted and long ones cut short. Headers are never printed.
class RedactingLogInterceptor extends Interceptor {
  RedactingLogInterceptor(this._log, {this.maxBody = 1200});

  final void Function(String message) _log;

  /// Longest body, in characters, that is printed.
  final int maxBody;

  String _body(Object? data) {
    if (data == null) return '';
    final text = '${redactSecrets(data)}';
    return text.length <= maxBody ? text : '${text.substring(0, maxBody)}…';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log('--> ${options.method} ${options.uri} ${_body(options.data)}'.trim());
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log(
      '<-- ${response.statusCode} ${response.requestOptions.uri} '
              '${_body(response.data)}'
          .trim(),
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(
      '<-- ERROR ${err.response?.statusCode ?? err.type.name} '
              '${err.requestOptions.uri} ${_body(err.response?.data)}'
          .trim(),
    );
    handler.next(err);
  }
}
