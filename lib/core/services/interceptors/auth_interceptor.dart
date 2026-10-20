import 'package:dio/dio.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/cookie_service.dart';
import 'package:flutter_template/core/services/storage_service.dart';

/// Attaches the Better Auth session token to outgoing requests, and ends the
/// session when the server says it is over.
///
/// There is no refresh: a Better Auth session renews itself while it is used,
/// so a 401 on a signed-in request means the session has expired or been
/// revoked (signed out elsewhere, password reset). See the API's
/// docs/BETTER-AUTH-CONSOLIDATION.md.
///
/// * **Only a 401 ends the session.** A timeout, no network or a 5xx leaves
///   the user signed in, to try again.
/// * **Once per burst.** Extends [QueuedInterceptor], so concurrent 401s run
///   one at a time; once the first has cleared the session, the rest find no
///   token and do not sign the user out again.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(
    this._storage, {
    this.cookieService,
    this.onUnauthenticated,
  });

  final StorageService _storage;
  final CookieService? cookieService;
  final void Function()? onUnauthenticated;

  /// Endpoints that must NOT carry a bearer token.
  static const Set<String> _authPaths = {ApiEndpoints.login};

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
    final sentToken = options.headers['Authorization'] != null;
    final isUnauthorized = err.response?.statusCode == 401;

    if (isUnauthorized && sentToken && !_authPaths.contains(options.path)) {
      final current = await _storage.readToken();
      if (current != null && current.isNotEmpty) {
        await _storage.clearSession();
        await cookieService?.clearCookies();
        onUnauthenticated?.call();
      }
    }
    handler.next(err);
  }
}
