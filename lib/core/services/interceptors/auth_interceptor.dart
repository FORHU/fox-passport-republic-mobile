import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/adapter_config/adapter_config.dart';
import 'package:flutter_template/core/services/cookie_service.dart';
import 'package:flutter_template/core/services/storage_service.dart';

/// Attaches the access token to outgoing requests and transparently refreshes
/// it once when the server returns 401, then retries the original request.
///
/// Guards against the two ways a refresh used to sign people out for no
/// reason:
///
/// * **Only a refusal ends the session.** The server saying the refresh token
///   is invalid or expired (401/403) clears the session. A timeout, no
///   network or a 5xx does not: the original error is returned and the user
///   stays signed in, to try again.
/// * **One refresh per burst.** Extends [QueuedInterceptor], so concurrent 401s
///   run one at a time; a request that failed with a token which has since
///   been replaced is simply retried with the new one instead of refreshing
///   (and, with rotation, burning the refresh token) again.
///
/// The refresh call uses a separate, bare [Dio] so it does not recurse through
/// this interceptor.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(
    this._storage, {
    required String baseUrl,
    this.cookieService,
    this.onUnauthenticated,
    Dio? refreshClient,
  }) : _refreshClient = refreshClient ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                contentType: Headers.jsonContentType,
              ),
            ) {
    configureWebCredentials(_refreshClient);
    final jar = cookieService?.jar;
    if (jar != null && !kIsWeb) {
      _refreshClient.interceptors.add(CookieManager(jar));
    }
  }

  final StorageService _storage;
  final CookieService? cookieService;
  final Dio _refreshClient;
  final void Function()? onUnauthenticated;

  /// Marks a request that has already been retried after a refresh, to avoid
  /// infinite 401 loops.
  static const String _retriedFlag = 'auth_retried';

  /// Endpoints that must NOT carry a bearer token or trigger a refresh.
  static const Set<String> _authPaths = {
    ApiEndpoints.login,
    ApiEndpoints.refresh,
  };

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_authPaths.contains(options.path)) {
      final token = await _storage.readToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    final alreadyRetried = options.extra[_retriedFlag] == true;
    final isAuthCall = _authPaths.contains(options.path);

    if (!isUnauthorized || alreadyRetried || isAuthCall) {
      handler.next(err);
      return;
    }

    // A burst of 401s is handled one by one. If an earlier one in the queue
    // already swapped the token, this request just needs the new one.
    final sent = options.headers['Authorization']?.toString();
    final current = await _storage.readToken();
    var newToken = current != null &&
            current.isNotEmpty &&
            sent != null &&
            sent != 'Bearer $current'
        ? current
        : null;

    if (newToken == null) {
      final outcome = await _refreshToken();
      switch (outcome) {
        case _Refreshed(:final token):
          newToken = token;
        case _Rejected():
          // The server refused the refresh token: the session is over.
          await _storage.clearSession();
          await cookieService?.clearCookies();
          onUnauthenticated?.call();
          handler.next(err);
          return;
        case _Unavailable():
          // Could not reach the server (or it failed). Keep the session and
          // let the original request fail; the next one tries again.
          handler.next(err);
          return;
      }
    }

    // Replay the original request with the fresh token.
    options
      ..extra[_retriedFlag] = true
      ..headers['Authorization'] = 'Bearer $newToken';
    try {
      final response = await _refreshClient.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Exchanges the stored refresh token for a new access token.
  Future<_RefreshOutcome> _refreshToken() async {
    final refreshToken = await _storage.readRefreshToken();

    try {
      final res = await _refreshClient.post<dynamic>(
        ApiEndpoints.refresh,
        data: (refreshToken != null && refreshToken.isNotEmpty)
            ? {'refreshToken': refreshToken}
            : null,
      );
      final rawData = res.data;
      if (rawData is! Map) return const _Unavailable();

      final payload = (rawData['data'] is Map)
          ? (rawData['data'] as Map).cast<String, dynamic>()
          : rawData.cast<String, dynamic>();

      final token = (payload['token'] ?? payload['accessToken']) as String?;
      final newRefresh = payload['refreshToken'] as String?;
      // A success without a token is the server misbehaving, not a refusal.
      if (token == null || token.isEmpty) return const _Unavailable();

      await _storage.saveToken(token);
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await _storage.saveRefreshToken(newRefresh);
      }
      return _Refreshed(token);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // 400/401/403: the refresh token itself was refused. Everything else
      // (timeouts, offline, 5xx, 429) is the network or server, not the user.
      if (status == 400 || status == 401 || status == 403) {
        return const _Rejected();
      }
      return const _Unavailable();
    }
  }
}

/// How a refresh attempt ended.
sealed class _RefreshOutcome {
  const _RefreshOutcome();
}

class _Refreshed extends _RefreshOutcome {
  const _Refreshed(this.token);

  final String token;
}

/// The server refused the refresh token.
class _Rejected extends _RefreshOutcome {
  const _Rejected();
}

/// No answer worth acting on: offline, timed out, or a server error.
class _Unavailable extends _RefreshOutcome {
  const _Unavailable();
}
