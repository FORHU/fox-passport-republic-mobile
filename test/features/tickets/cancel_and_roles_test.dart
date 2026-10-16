import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/roles/presentation/pages/roles_page.dart';
import 'package:flutter_template/features/tickets/presentation/widgets/ticket_card.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/roles/role_request.dart';
import 'package:flutter_template/shared/tickets/cancel_quote.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_template/shared/tickets/tickets_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _Citizen extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(
          id: 'u',
          email: 'u@example.com',
          name: 'U',
          roleType: ['gearFoxer'],
        ),
      );
}

Ticket _ticket({
  String status = 'confirmed',
  bool sample = false,
  Duration startsIn = const Duration(days: 5),
}) =>
    Ticket(
      id: 'b1',
      eventName: 'Sky Hall',
      startAt: DateTime.now().add(startsIn),
      endAt: DateTime.now().add(startsIn + const Duration(hours: 5)),
      status: status,
      isSample: sample,
    );

Widget _card(Ticket ticket, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(child: TicketCard(ticket: ticket)),
        ),
      ),
    );

void main() {
  group('CancelQuote', () {
    test('reads the API check, decimals as strings included', () {
      final q = CancelQuote.fromJson(const {
        'eligible': true,
        'refundPercent': 50,
        'totalPaid': '26250',
        'estimatedRefund': 13125,
        'message': 'Half back inside 7 days.',
        'hoursUntilStart': 96,
      });

      expect(q.eligible, isTrue);
      expect(q.totalPaid, 26250);
      expect(q.estimatedRefund, 13125);
      expect(q.hasRefund, isTrue);
    });
  });

  group('cancel action', () {
    setUp(TestWidgetsFlutterBinding.ensureInitialized);

    testWidgets('is offered for a live booking that has not started', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_card(_ticket()));
      await tester.pump();

      expect(find.text('Cancel booking'), findsOneWidget);
    });

    testWidgets('is not offered for samples, past or cancelled bookings', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      for (final ticket in [
        _ticket(sample: true),
        _ticket(startsIn: const Duration(days: -2)),
        _ticket(status: 'cancelled'),
        _ticket(status: 'completed'),
      ]) {
        await tester.pumpWidget(_card(ticket));
        await tester.pump();
        expect(find.text('Cancel booking'), findsNothing);
      }
    });

    testWidgets('shows the refund first, then cancels on confirmation', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final api = _MockApi();
      when(() => api.post(ApiEndpoints.bookingCancelCheck('b1'))).thenAnswer(
        (_) async => {
          'data': {
            'eligible': true,
            'refundPercent': 50,
            'totalPaid': 26250,
            'estimatedRefund': 13125,
            'message': 'Half back inside 7 days.',
          },
        },
      );
      when(() => api.post(ApiEndpoints.bookingCancel('b1')))
          .thenAnswer((_) async => {'data': <String, dynamic>{}});
      when(() => api.get(any(), query: any(named: 'query')))
          .thenAnswer((_) async => {'data': <Object>[]});
      final repo = TicketsRepository(api, 'u');

      await tester.pumpWidget(
        _card(
          _ticket(),
          overrides: [ticketsRepositoryProvider.overrideWithValue(repo)],
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Cancel booking'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel this booking?'), findsOneWidget);
      expect(find.text('₱26,250'), findsOneWidget);
      expect(find.text('₱13,125 (50%)'), findsOneWidget);
      expect(find.text('Half back inside 7 days.'), findsOneWidget);

      await tester.tap(find.text('Cancel booking').last);
      await tester.pumpAndSettle();

      verify(() => api.post(ApiEndpoints.bookingCancel('b1'))).called(1);
      expect(find.text('Cancel this booking?'), findsNothing);
    });

    testWidgets('a booking past its cancellation window cannot be cancelled', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final api = _MockApi();
      when(() => api.post(ApiEndpoints.bookingCancelCheck('b1'))).thenAnswer(
        (_) async => {
          'data': {
            'eligible': false,
            'refundPercent': 0,
            'totalPaid': 26250,
            'estimatedRefund': 0,
            'message': 'Too close to the event to cancel.',
          },
        },
      );

      await tester.pumpWidget(
        _card(
          _ticket(),
          overrides: [
            ticketsRepositoryProvider
                .overrideWithValue(TicketsRepository(api, 'u')),
          ],
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Cancel booking'));
      await tester.pumpAndSettle();

      expect(find.text('Too close to the event to cancel.'), findsOneWidget);
      final confirm = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Cancel booking'),
      );
      expect(confirm.onPressed, isNull);
      verifyNever(() => api.post(ApiEndpoints.bookingCancel('b1')));
    });
  });

  group('become a Foxer', () {
    testWidgets('lists every role with where each application stands', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 3200)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_Citizen.new),
            myRoleRequestsProvider.overrideWith(
              (ref) async => const [
                RoleRequestSummary(
                  id: 'r1',
                  roleType: 'venueFoxer',
                  status: 'pending',
                ),
                RoleRequestSummary(
                  id: 'r2',
                  roleType: 'serviceFoxer',
                  status: 'revision_requested',
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RolesPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Become a Foxer'), findsOneWidget);
      // Held (gear), under review (venue), needs changes (talent).
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('UNDER REVIEW'), findsOneWidget);
      expect(find.text('NEEDS REVISION'), findsOneWidget);
    });

    testWidgets('a role opens its details with a way to apply', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 3200)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_Citizen.new),
            myRoleRequestsProvider.overrideWith((ref) async => const []),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RolesPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Talent Foxer'));
      await tester.pumpAndSettle();

      expect(find.text('Continue on the web'), findsOneWidget);
      expect(find.text("WHAT YOU'LL DO"), findsOneWidget);
    });
  });
}
