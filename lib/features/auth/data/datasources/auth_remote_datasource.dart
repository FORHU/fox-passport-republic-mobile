import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/data/models/user_model.dart';

/// Talks to the remote API. Knows nothing about storage or UI.
abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<void> register(
    String email,
    String password, {
    String? name,
    String? countryCode,
    String roleName,
  });
  Future<void> logout(String? refreshToken);
  Future<UserModel> checkAuth(String token);
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
    String? countryCode,
    String roleName = 'USER',
  }) async {
    await _api.post(ApiEndpoints.register, {
      'email': email,
      'password': password,
      'name': ?name,
      'countryCode': ?countryCode,
      'roleName': roleName,
    });
  }

  @override
  Future<void> logout(String? refreshToken) async {
    await _api.post(ApiEndpoints.logout, {
      'refreshToken': ?refreshToken,
    });
  }

  @override
  Future<UserModel> checkAuth(String token) async {
    final data = await _api.get(ApiEndpoints.me);
    return UserModel.fromJson((data as Map).cast<String, dynamic>());
  }
}
