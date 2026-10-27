import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/tickets/presentation/widgets/edit_request_sheet.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/tickets/edit_request.dart';
import 'package:flutter_template/shared/tickets/edit_requests_repository.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'me', email: 'a@b.co', name: 'Ada'),
      );
}

Map<String, dynamic> _row({
  String status = 'pending',
  Object? appliedAt,
  bool canWithdraw = true,
}) =>
    {
      'id': 'e1',
      'status': status,
      'currentTotalAmount': '1000.00',
      'proposedTotalAmount': '1500.00',
      'proposedGuestCount': 8,
      'reason': ' bigger party ',
      'declineReason': null,
      'appliedAt': appliedAt,
      'canWithdraw': canWithdraw,
    };

class _FakeRepo extends EditRequestsRepository {
  _FakeRepo({this.current, this.createFails = false}) : super(_MockApi());

  EditRequest? current;
  final bool createFails;
  final calls = <String>[];

  @override
  Future<EditRequest?> latest(String bookingId) async => current;

  @override
  Future<EditRequest> create(
    String bookingId, {
    int? guests,
    DateTime? start,
    DateTime? end,
    String? reason,
  }) async {
    calls.add('create $bookingId guests=$guests reason=$reason');
    if (createFails) throw const ServerException('Dates are not available');
    return current = EditRequest.fromJson(_row());
  }

  @override
  Future<void> withdraw(String requestId) async {
    calls.add('withdraw $requestId');
    current = EditRequest.fromJson(_row(status: 'withdrawn'));
  }
}

final _ticket = Ticket(
  id: 'b1',
  eventName: 'Rooftop',
  startAt: DateTime(2030, 5, 10, 18),
  endAt: DateTime(2030, 5, 10, 23),
  status: 'confirmed',
  guestCount: 4,
);

Future<void> _open(WidgetTester tester, _FakeRepo repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_Session.new),
        editRequestsRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showEditRequestSheet(context, _ticket),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('EditRequest', () {
    test('reads the API row', () {
      final r = EditRequest.fromJson(_row());
      expect(r.isPending, isTrue);
      expect(r.currentTotal, 1000);
      expect(r.proposedTotal, 1500);
      expect(r.proposedGuests, 8);
      expect(r.reason, 'bigger party');
      expect(r.declineReason, isNull);
      expect(r.canWithdraw, isTrue);
    });

    test('approved with a higher price waits for payment until applied', () {
      expect(
        EditRequest.fromJson(_row(status: 'approved')).awaitsPayment,
        isTrue,
      );
      expect(
        EditRequest.fromJson(
          _row(status: 'approved', appliedAt: '2030-01-01T00:00:00Z'),
        ).awaitsPayment,
        isFalse,
      );
    });
  });

  group('EditRequestsRepository', () {
    late _MockApi api;
    setUp(() => api = _MockApi());

    test('sends only what changed', () async {
      when(() => api.post(ApiEndpoints.bookingEditRequests, any()))
          .thenAnswer((_) async => {'data': _row()});
      await EditRequestsRepository(api)
          .create('b1', guests: 6, reason: ' party ');
      verify(
        () => api.post(ApiEndpoints.bookingEditRequests, {
          'bookingKind': 'booking',
          'bookingId': 'b1',
          'proposedGuestCount': 6,
          'reason': 'party',
        }),
      ).called(1);
    });

    test('no request yet is null', () async {
      when(
        () => api.get(
          ApiEndpoints.bookingEditRequests,
          query: any(named: 'query'),
        ),
      ).thenAnswer((_) async => {'success': true, 'data': null});
      expect(await EditRequestsRepository(api).latest('b1'), isNull);
    });
  });

  group('the sheet', () {
    testWidgets('sends a new guest count with the reason', (tester) async {
      final repo = _FakeRepo();
      await _open(tester, repo);

      final button = find.widgetWithText(ElevatedButton, 'Send request');
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);

      await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
      await tester.enterText(find.byType(TextField), 'bigger party');
      await tester.pump();
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(repo.calls, ['create b1 guests=5 reason=bigger party']);
      expect(find.text('Waiting for the venue'), findsOneWidget);
      expect(find.text('Withdraw request'), findsOneWidget);
    });

    testWidgets('a pending request can be withdrawn', (tester) async {
      final repo = _FakeRepo(current: EditRequest.fromJson(_row()));
      await _open(tester, repo);
      expect(find.text('Waiting for the venue'), findsOneWidget);

      await tester.tap(find.text('Withdraw request'));
      await tester.pumpAndSettle();

      expect(repo.calls, ['withdraw e1']);
      expect(find.text('You withdrew this request'), findsOneWidget);
      expect(find.text('Send request'), findsOneWidget);
    });

    testWidgets('a refusal is shown and nothing changes', (tester) async {
      await _open(tester, _FakeRepo(createFails: true));
      await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
      await tester.pump();
      await tester.tap(find.text('Send request'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Dates are not available'), findsOneWidget);
      expect(find.text('Waiting for the venue'), findsNothing);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('an approved change that needs paying says where to pay',
        (tester) async {
      await _open(
        tester,
        _FakeRepo(current: EditRequest.fromJson(_row(status: 'approved'))),
      );
      expect(
        find.text(
          'Approved. Pay the difference on the web to confirm the change.',
        ),
        findsOneWidget,
      );
    });
  });
}
