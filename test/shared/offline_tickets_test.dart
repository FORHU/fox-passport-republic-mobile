import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/spaces/data/active_space.dart';
import 'package:flutter_template/features/spaces/domain/app_space.dart';
import 'package:flutter_template/features/tickets/presentation/pages/tickets_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_template/shared/tickets/tickets_cache.dart';
import 'package:flutter_template/shared/tickets/tickets_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApi extends Mock implements ApiService {}

class _MockSecure extends Mock implements FlutterSecureStorage {}

Ticket _ticket(
  String id, {
  DateTime? start,
  String code = 'FXP-1',
  String status = 'confirmed',
}) {
  final at = start ?? DateTime.now().add(const Duration(days: 2));
  return Ticket(
    id: id,
    eventName: 'Event $id',
    startAt: at,
    endAt: at.add(const Duration(hours: 4)),
    status: status,
    city: 'Davao City',
    guestCount: 3,
    ticketCode: code,
    templateId: 't1',
    hasReview: true,
  );
}

Map<String, dynamic> _booking(Ticket t) => {
      'id': t.id,
      'startAt': t.startAt.toUtc().toIso8601String(),
      'endAt': t.endAt.toUtc().toIso8601String(),
      'status': t.status,
      'guestCount': t.guestCount,
      'ticketCode': t.ticketCode,
      'event': {'name': t.eventName, 'targetCity': t.city},
    };

void main() {
  late StorageService storage;
  late SharedPreferences prefs;

  setUp(() async {
    AppConfig.instance = const AppConfig.dev();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    final secure = _MockSecure();
    when(() => secure.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    storage = StorageService(prefs, secure: secure);
  });

  group('a ticket saved for offline use', () {
    test('keeps what is needed to show it, and says it is a saved copy', () {
      final saved = DateTime(2026, 10, 20, 9);
      final back = Ticket.fromCache(_ticket('a').toCache(), saved);

      expect(back.id, 'a');
      expect(back.eventName, 'Event a');
      expect(back.ticketCode, 'FXP-1');
      expect(back.guestCount, 3);
      expect(back.city, 'Davao City');
      expect(back.templateId, 't1');
      expect(back.hasReview, isTrue);
      expect(back.cachedAt, saved);
    });

    test('a live ticket is not marked as saved', () {
      expect(_ticket('a').cachedAt, isNull);
    });
  });

  group('the saved tickets', () {
    test('come back as they were saved, marked with when', () async {
      final cache = TicketsCache(storage, 'u1');
      final now = DateTime(2026, 10, 20, 9);
      await cache.save([_ticket('a'), _ticket('b')], now: now);

      final read = cache.read(now: now)!;

      expect(read.map((t) => t.id), ['a', 'b']);
      expect(read.first.cachedAt, now);
      expect(read.first.ticketCode, 'FXP-1');
    });

    test('are per account', () async {
      await TicketsCache(storage, 'u1').save([_ticket('a')]);

      expect(TicketsCache(storage, 'u2').read(), isNull);
      expect(TicketsCache(storage, null).read(), isNull);
    });

    test('drop an event that ended more than a day ago', () async {
      final cache = TicketsCache(storage, 'u1');
      final now = DateTime.now();
      await cache.save(
        [
          _ticket('old', start: now.subtract(const Duration(days: 3))),
          // Over a few hours ago, but within the day.
          _ticket('just', start: now.subtract(const Duration(hours: 8))),
          _ticket('ahead'),
        ],
        now: now,
      );

      expect(cache.read(now: now)!.map((t) => t.id), ['just', 'ahead']);
    });

    test('an empty save replaces what was there', () async {
      final cache = TicketsCache(storage, 'u1');
      await cache.save([_ticket('a')]);
      await cache.save(const []);

      expect(cache.read(), isEmpty);
    });

    test('a demo ticket is never saved', () async {
      final cache = TicketsCache(storage, 'u1');
      await cache.save([Ticket.sample()]);

      expect(cache.read(), isEmpty);
    });

    test('what cannot be read is treated as nothing saved', () async {
      await storage.setString('${TicketsCache.keyPrefix}u1', 'not json');

      expect(TicketsCache(storage, 'u1').read(), isNull);
    });

    test('signing out removes the saved tickets of every account', () async {
      await TicketsCache(storage, 'u1').save([_ticket('a')]);
      await TicketsCache(storage, 'u2').save([_ticket('b')]);
      await storage.setString('something_else', 'kept');

      await storage.clearSession();

      expect(TicketsCache(storage, 'u1').read(), isNull);
      expect(TicketsCache(storage, 'u2').read(), isNull);
      expect(prefs.getString('something_else'), 'kept');
    });
  });

  group('the upcoming tickets with no signal', () {
    late _MockApi api;
    late TicketsRepository repo;

    setUp(() {
      api = _MockApi();
      repo = TicketsRepository(api, 'u1', TicketsCache(storage, 'u1'));
    });

    test('are saved each time the server answers', () async {
      when(() => api.get(any())).thenAnswer(
        (_) async => {
          'data': [_booking(_ticket('a'))],
        },
      );

      final live = await repo.upcoming();

      expect(live.single.cachedAt, isNull);
      expect(TicketsCache(storage, 'u1').read()!.single.id, 'a');
    });

    test('come from the phone when there is no connection', () async {
      when(() => api.get(any())).thenAnswer(
        (_) async => {
          'data': [_booking(_ticket('a'))],
        },
      );
      await repo.upcoming();
      when(() => api.get(any())).thenThrow(const NetworkException());

      final offline = await repo.upcoming();

      expect(offline.single.id, 'a');
      expect(offline.single.ticketCode, 'FXP-1');
      expect(offline.single.cachedAt, isNotNull);
    });

    test('come from the phone while the server is failing', () async {
      when(() => api.get(any())).thenAnswer(
        (_) async => {
          'data': [_booking(_ticket('a'))],
        },
      );
      await repo.upcoming();
      when(() => api.get(any()))
          .thenThrow(const ServerException('down', statusCode: 503));

      expect((await repo.upcoming()).single.cachedAt, isNotNull);
    });

    test('are not hidden behind a refusal', () async {
      when(() => api.get(any())).thenAnswer(
        (_) async => {
          'data': [_booking(_ticket('a'))],
        },
      );
      await repo.upcoming();
      when(() => api.get(any())).thenThrow(
        const UnauthorizedException('signed out', statusCode: 401),
      );
      await expectLater(
        repo.upcoming(),
        throwsA(isA<UnauthorizedException>()),
      );

      when(() => api.get(any()))
          .thenThrow(const ServerException('nope', statusCode: 404));
      await expectLater(repo.upcoming(), throwsA(isA<ServerException>()));
    });

    test('say so when there is nothing saved to fall back on', () async {
      when(() => api.get(any())).thenThrow(const NetworkException());

      await expectLater(repo.upcoming(), throwsA(isA<NetworkException>()));
    });

    test('a cancelled booking no longer shows once the server says so',
        () async {
      when(() => api.get(any())).thenAnswer(
        (_) async => {
          'data': [_booking(_ticket('a'))],
        },
      );
      await repo.upcoming();
      when(() => api.get(any())).thenAnswer((_) async => {'data': <Object>[]});
      await repo.upcoming();
      when(() => api.get(any())).thenThrow(const NetworkException());

      // The server's later, empty answer replaced the saved copy.
      expect(await repo.upcoming(), isEmpty);
    });
  });

  group('the Bookings screen', () {
    testWidgets('says it is showing saved tickets, and still has the code', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 1800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final saved = DateTime(2026, 10, 20, 9, 30);
      final ticket = Ticket.fromCache(_ticket('a').toCache(), saved);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            availableSpacesProvider.overrideWithValue(const [AppSpace.citizen]),
            upcomingTicketsProvider.overrideWith((ref) async => [ticket]),
            pastTicketsProvider.overrideWith((ref) async => <Ticket>[]),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: TicketsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('No connection'), findsOneWidget);
      expect(find.textContaining('Oct 20'), findsOneWidget);
      expect(find.textContaining('9:30'), findsOneWidget);
      expect(find.textContaining(' j'), findsNothing);
      expect(find.text('Event a'), findsOneWidget);
      expect(find.text('FXP-1'), findsOneWidget);
    });

    testWidgets('says nothing when the tickets are fresh', (tester) async {
      tester.view
        ..physicalSize = const Size(800, 1800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            availableSpacesProvider.overrideWithValue(const [AppSpace.citizen]),
            upcomingTicketsProvider.overrideWith((ref) async => [_ticket('a')]),
            pastTicketsProvider.overrideWith((ref) async => <Ticket>[]),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: TicketsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('No connection'), findsNothing);
    });
  });
}
