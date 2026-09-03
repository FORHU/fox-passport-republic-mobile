/// Centralized API paths. Keep every endpoint here — never inline path strings
/// in data sources. Paths are relative to `AppConfig.instance.baseUrl`.
class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/login';
  static const String register = '/register';
  static const String refresh = '/refresh';
  static const String logout = '/logout';
  static const String me = '/users/me';

  /// Sample protected resource used to demonstrate a GET with the bearer token.
  static const String users = '/users';

  /// Sample protected resource used by the worldMap feature.
  static const String nearbyStores = '/stores/nearby';
}
