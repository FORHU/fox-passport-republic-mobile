/// Centralized API paths. Keep every endpoint here — never inline path strings
/// in data sources. Paths are relative to `AppConfig.instance.baseUrl`.
class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  static const String me = '/profile';
  static const String profile = '/profile';

  /// Fox Passport ecosystem endpoints
  static const String venues = '/venues';
  static const String events = '/event-templates';
  static const String categories = '/categories';

  /// Sample protected resource used to demonstrate a GET with the bearer token.
  static const String users = '/users';

  /// Sample protected resource used by the worldMap feature.
  static const String nearbyStores = '/stores/nearby';

  /// Interactive Quiz engine endpoints
  static const String quiz = '/quiz';
  static const String quizProgress = '/quiz/progress';
  static const String quizReset = '/quiz/progress/reset';
}
