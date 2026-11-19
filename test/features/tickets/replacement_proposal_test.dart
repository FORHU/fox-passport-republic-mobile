import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/tickets/presentation/widgets/replacement_proposal_card.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/tickets/event_edit_proposal.dart';
import 'package:flutter_template/shared/tickets/event_edit_proposals_repository.dart';
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
  String proposedPrice = '5940.00',
  String? expiresAt,
  String? note,
}) =>
    {
      'id': 'p1',
      'bookingId': 'b1',
      'status': status,
      'itemName': 'Bigger speakers',
      'replacesName': 'Sound system',
      'currentPrice': '19440.00',
      'proposedPrice': proposedPrice,
      'note': note,
      'expiresAt': expiresAt ?? '2099-01-01T00:00:00Z',
    };

void main() {
  late _MockApi api;

  setUp(() => api = _MockApi());

  void answers(List<Map<String, dynamic>> rows) {
    when(
      () => api.get(
        ApiEndpoints.eventEditProposals,
        query: {'bookingId': 'b1'},
      ),
    ).thenAnswer((_) async => {'success': true, 'data': rows});
  }

  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, __) => null,
        overrides: [
          authControllerProvider.overrideWith(_Session.new),
          eventEditProposalsRepositoryProvider.overrideWithValue(
            EventEditProposalsRepository(api),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ReplacementProposalCard(bookingId: 'b1')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('a proposal', () {
    test('reads its prices and whether it is still open', () {
      final p = EventEditProposal.fromJson(_row(note: '  same spec '));

      expect(p.priceDelta, -13500);
      expect(p.note, 'same spec');
      expect(p.isOpen(), isTrue);
      expect(
        EventEditProposal.fromJson(_row(status: 'declined')).isOpen(),
        isFalse,
      );
      expect(
        EventEditProposal.fromJson(_row(expiresAt: '2000-01-01T00:00:00Z'))
            .isOpen(),
        isFalse,
      );
    });
  });

  group('the proposal card', () {
    testWidgets('shows nothing when no proposal is waiting', (tester) async {
      answers([_row(status: 'declined')]);

      await show(tester);

      expect(find.text('Your host proposes a change'), findsNothing);
    });

    testWidgets('shows nothing when the proposals cannot be read', (
      tester,
    ) async {
      when(
        () => api.get(
          ApiEndpoints.eventEditProposals,
          query: {'bookingId': 'b1'},
        ),
      ).thenThrow(const NetworkException());

      await show(tester);

      expect(find.text('Your host proposes a change'), findsNothing);
    });

    testWidgets('says what changes and by how much', (tester) async {
      answers([_row()]);

      await show(tester);

      expect(find.text('Your host proposes a change'), findsOneWidget);
      expect(
        find.text(
          "Sound system can't be part of your event. "
          'Your host proposes Bigger speakers instead.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('goes down by'), findsOneWidget);
    });

    testWidgets('says when the total goes up', (tester) async {
      answers([_row(proposedPrice: '20000.00')]);

      await show(tester);

      expect(find.textContaining('goes up by'), findsOneWidget);
    });

    testWidgets('accepting tells the API and says what happens next', (
      tester,
    ) async {
      answers([_row()]);
      when(
        () => api.post(ApiEndpoints.eventEditProposalAnswer('p1', 'accept')),
      ).thenAnswer((_) async => {'success': true});

      await show(tester);
      answers([_row(status: 'accepted')]);
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      verify(
        () => api.post(ApiEndpoints.eventEditProposalAnswer('p1', 'accept')),
      ).called(1);
      expect(
        find.text('Accepted. The new Supplier will confirm.'),
        findsOneWidget,
      );
      expect(find.text('Your host proposes a change'), findsNothing);
    });

    testWidgets('declining tells the API and the host', (tester) async {
      answers([_row()]);
      when(
        () => api.post(ApiEndpoints.eventEditProposalAnswer('p1', 'decline')),
      ).thenAnswer((_) async => {'success': true});

      await show(tester);
      answers([_row(status: 'declined')]);
      await tester.tap(find.text('Decline'));
      await tester.pumpAndSettle();

      verify(
        () => api.post(ApiEndpoints.eventEditProposalAnswer('p1', 'decline')),
      ).called(1);
      expect(find.text('Declined. Your host was told.'), findsOneWidget);
    });

    testWidgets('shows the reason when the API refuses', (tester) async {
      answers([_row()]);
      when(
        () => api.post(ApiEndpoints.eventEditProposalAnswer('p1', 'accept')),
      ).thenThrow(const ServerException('This proposal has expired'));

      await show(tester);
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      expect(find.text('This proposal has expired'), findsOneWidget);
    });
  });
}
