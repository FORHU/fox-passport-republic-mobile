import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/data/datasources/social_credential_source.dart';
import 'package:flutter_template/features/auth/data/models/user_model.dart';

/// Talks to the remote API. Knows nothing about storage or UI.
abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<void> register(
    String email,
    String password, {
    String? name,
    String? username,
    String? countryCode,
    String roleName,
  });
  Future<void> logout(String? refreshToken);
  Future<UserModel> checkAuth(String token);
  Future<UserModel> loginWithSocialToken(SocialProvider provider, String token);
  Future<UserModel> exchangeSocialCode(SocialProvider provider, String code);
  Future<void> verifyEmail(String email, String otpCode);
  Future<void> resendVerificationOtp(String email);
  Future<void> forgotPassword(String email);
  Future<void> resetPassword(String email, String otpCode, String newPassword);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._api);

  final ApiService _api;

  @override
  Future<UserModel> login(String email, String password) async {
    final data = await _api.post(ApiEndpoints.login, {
      'email': email,
      'password': password,
    });
    return UserModel.fromJson((data as Map).cast<String, dynamic>());
  }

  @override
  Future<void> register(
    String email,
    String password, {
    String? name,
    String? username,
    String? countryCode,
    String roleName = 'CITIZEN',
  }) async {
    final computedName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : email.split('@').first;
    // The web sign-up form asks for a username; fall back to the email
    // local-part only for callers that don't supply one.
    final computedUsername = (username != null && username.trim().isNotEmpty)
        ? username.trim()
        : email.split('@').first;

    final payload = <String, dynamic>{
      'email': email.trim(),
      'password': password,
      'name': computedName,
      'username': computedUsername,
    };

    await _api.post(ApiEndpoints.register, payload);
  }

  @override
  Future<void> logout(String? refreshToken) async {
    final payload = <String, dynamic>{};
    if (refreshToken != null) payload['refreshToken'] = refreshToken;

    await _api.post(ApiEndpoints.logout, payload);
  }

  @override
  Future<UserModel> checkAuth(String token) async {
    final data = await _api.get(ApiEndpoints.me);
    return UserModel.fromJson((data as Map).cast<String, dynamic>());
  }

  /// Native flow: a Google ID token / Facebook access token from the SDK,
  /// signed in through Better Auth. Response is `{ token, user }`, which
  /// [UserModel.fromJson] already reads.
  @override
  Future<UserModel> loginWithSocialToken(
    SocialProvider provider,
    String token,
  ) async {
    final data = await _api.post(ApiEndpoints.socialSignIn, {
      'provider': provider.name,
      // Facebook's is an access token, which Better Auth checks with
      // Facebook's debug_token; it reads it from `accessToken`.
      'idToken': {
        'token': token,
        if (provider == SocialProvider.facebook) 'accessToken': token,
      },
    });
    return UserModel.fromJson((data as Map).cast<String, dynamic>());
  }

  /// Browser flow: redeems the one-time `xc` code from the app-scheme redirect.
  @override
  Future<UserModel> exchangeSocialCode(
    SocialProvider provider,
    String code,
  ) async {
    final path = switch (provider) {
      SocialProvider.google => ApiEndpoints.googleExchange,
      SocialProvider.facebook => ApiEndpoints.facebookExchange,
    };
    final data = await _api.post(path, {'code': code});
    return UserModel.fromJson((data as Map).cast<String, dynamic>());
  }

  @override
  Future<void> verifyEmail(String email, String otpCode) async {
    await _api.post(ApiEndpoints.verifyEmail, {
      'email': email.trim(),
      'otp': otpCode.trim(),
    });
  }

  @override
  Future<void> resendVerificationOtp(String email) async {
    await _api.post(ApiEndpoints.resendVerificationOtp, {
      'email': email.trim(),
      'type': 'email-verification',
    });
  }

  @override
  Future<void> forgotPassword(String email) async {
    await _api.post(ApiEndpoints.forgotPassword, {'email': email.trim()});
  }

  @override
  Future<void> resetPassword(
    String email,
    String otpCode,
    String newPassword,
  ) async {
    await _api.post(ApiEndpoints.resetPassword, {
      'email': email.trim(),
      'otp': otpCode.trim(),
      'password': newPassword,
    });
  }
}
