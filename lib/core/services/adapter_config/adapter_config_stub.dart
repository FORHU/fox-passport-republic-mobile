import 'package:dio/dio.dart';

/// Stub implementation for non-web platforms and tests.
void configureWebCredentials(Dio dio) {
  // Native platforms send no cookies; the session is the bearer token.
}
