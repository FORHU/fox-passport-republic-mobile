import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/pages/check_in_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/ticket_scanner_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockRepo extends Mock implements SpacesRepository {}

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(
          id: 'u1',
          email: 'a@b.co',
          name: 'Ada',
          roleType: ['venueFoxer', 'eventFoxer'],
        ),
      );
}

void main() {
  late _MockRepo repo;
  String? scanned;
  var scans = 0;

  setUp(() {
    repo = _MockRepo();
    scanned = 'TKT-001';
    scans = 0;
  });

  Future<void> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, __) => null,
        overrides: [
          spacesRepositoryProvider.overrideWithValue(repo),
          sharedPreferencesProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(_Session.new),
          ticketScannerProvider.overrideWithValue((_) async {
            scans++;
            return scanned;
          }),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CheckInPage(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('offers the camera as well as typing the code', (tester) async {
    await pump(tester);

    expect(find.text('Scan ticket'), findsOneWidget);
    expect(find.text('Check in guest'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('a scanned ticket is checked in straight away', (tester) async {
    when(() => repo.checkIn('TKT-001')).thenAnswer(
      (_) async => const CheckInResult(message: 'Ada is checked in'),
    );
    await pump(tester);

    await tester.tap(find.text('Scan ticket'));
    await tester.pump();
    await tester.pump();

    verify(() => repo.checkIn('TKT-001')).called(1);
    expect(find.text('Ada is checked in'), findsOneWidget);
  });

  testWidgets('backing out of the camera checks nobody in', (tester) async {
    scanned = null;
    await pump(tester);

    await tester.tap(find.text('Scan ticket'));
    await tester.pump();
    await tester.pump();

    expect(scans, 1);
    verifyNever(() => repo.checkIn(any()));
  });

  testWidgets('says why when the server turns a scanned ticket away', (
    tester,
  ) async {
    when(() => repo.checkIn(any())).thenThrow(
      const ServerException('This ticket was already used'),
    );
    await pump(tester);

    await tester.tap(find.text('Scan ticket'));
    await tester.pump();
    await tester.pump();

    expect(find.text('This ticket was already used'), findsOneWidget);
  });

  testWidgets('typing a code still works', (tester) async {
    when(() => repo.checkIn('ABC')).thenAnswer(
      (_) async => const CheckInResult(),
    );
    await pump(tester);

    await tester.enterText(find.byType(TextFormField), 'ABC');
    await tester.tap(find.text('Check in guest'));
    await tester.pump();
    await tester.pump();

    verify(() => repo.checkIn('ABC')).called(1);
    expect(scans, 0);
  });
}
