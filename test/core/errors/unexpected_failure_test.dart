import 'package:flutter/foundation.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:flutter_template/features/profile/data/repositories/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements ProfileRemoteDataSource {}

void main() {
  late List<String?> logged;
  late DebugPrintCallback original;

  setUp(() {
    logged = [];
    original = debugPrint;
    debugPrint = (message, {wrapWidth}) => logged.add(message);
  });

  tearDown(() => debugPrint = original);

  group('ServerFailure.unexpected', () {
    test('shows people the plain sentence, not the error', () {
      final failure = ServerFailure.unexpected(
        const FormatException('Unexpected character (at character 1) <html>'),
      );
      expect(failure.message, serverErrorMessage);
      expect(failure.message, isNot(contains('FormatException')));
      expect(failure.message, isNot(contains('<html>')));
    });

    test('keeps the raw error for the log, where developers read it', () {
      ServerFailure.unexpected(const FormatException('bad reply'));
      expect(logged.join(), contains('bad reply'));
    });

    test('is the same sentence ApiService uses for a server error', () {
      expect(serverErrorMessage, ApiService.serverErrorMessage);
    });
  });

  group('a repository meeting an error nobody planned for', () {
    late _MockRemote remote;
    late ProfileRepositoryImpl repository;

    setUp(() {
      remote = _MockRemote();
      repository = ProfileRepositoryImpl(remote);
    });

    test('returns the plain sentence for a malformed reply', () async {
      when(remote.getProfile).thenThrow(
        const FormatException('Unexpected character (at character 1) <html>'),
      );

      final result = await repository.getProfile();

      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<ServerFailure>());
      expect(failure!.message, serverErrorMessage);
      expect(failure.message, isNot(contains('FormatException')));
    });

    test('still passes through the errors it does plan for', () async {
      when(remote.getProfile).thenThrow(const NetworkException());
      final network =
          (await repository.getProfile()).fold((f) => f, (_) => null);
      expect(network, isA<NetworkFailure>());

      when(remote.getProfile)
          .thenThrow(const UnauthorizedException('Session expired'));
      final unauthorized =
          (await repository.getProfile()).fold((f) => f, (_) => null);
      expect(unauthorized, isA<UnauthorizedFailure>());
      expect(unauthorized!.message, 'Session expired');

      when(remote.getProfile)
          .thenThrow(const ServerException('User already exists'));
      final server =
          (await repository.getProfile()).fold((f) => f, (_) => null);
      expect(server!.message, 'User already exists');
    });
  });
}
