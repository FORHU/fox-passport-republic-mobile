import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/controllers/payout_setup_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _MockRepo extends Mock implements SpacesRepository {}

/// mobile#465: payout setup (Stripe Connect onboarding) starts from the app,
/// with the person's own session, instead of the web app's page in a browser
/// where they usually weren't signed in. mobile#476: Stripe sends the person
/// back to the app, and an expired link is replaced.
void main() {
  group('SpacesRepository.payoutSetupLink', () {
    late _MockApi api;
    late SpacesRepository repo;

    setUp(() {
      api = _MockApi();
      repo = SpacesRepository(api, 'u1');
    });

    test("asks the API for the person's own Stripe link", () async {
      when(() => api.post(ApiEndpoints.stripeOnboard, any())).thenAnswer(
        (_) async => {
          'success': true,
          'data': {'url': 'https://connect.stripe.com/setup/e/acct_1/abc'},
        },
      );

      final link = await repo.payoutSetupLink();

      expect(link.toString(), 'https://connect.stripe.com/setup/e/acct_1/abc');
      verify(() => api.post(ApiEndpoints.stripeOnboard)).called(1);
    });

    test('asks for the way back to the app when told to', () async {
      when(() => api.post(ApiEndpoints.stripeOnboard, any())).thenAnswer(
        (_) async => {
          'data': {'url': 'https://connect.stripe.com/setup/e/acct_1/abc'},
        },
      );

      await repo.payoutSetupLink(returnToApp: true);

      verify(
        () => api.post(ApiEndpoints.stripeOnboard, {'client': 'mobile'}),
      ).called(1);
    });

    test('refuses a response without an https link', () async {
      when(() => api.post(ApiEndpoints.stripeOnboard, any())).thenAnswer(
        (_) async => {
          'data': {'url': 'javascript:alert(1)'},
        },
      );
      await expectLater(repo.payoutSetupLink(), throwsFormatException);

      when(() => api.post(ApiEndpoints.stripeOnboard, any()))
          .thenAnswer((_) async => {'data': <String, Object>{}});
      await expectLater(repo.payoutSetupLink(), throwsFormatException);
    });
  });

  group('outcomeForCallback', () {
    test('reads the link the handoff page opens', () {
      expect(
        outcomeForCallback(Uri.parse('foxpassport://app/stripe/return')),
        StripeFormOutcome.returned,
      );
      expect(
        outcomeForCallback(Uri.parse('foxpassport://app/stripe/refresh')),
        StripeFormOutcome.expired,
      );
    });
  });

  group('PayoutSetupController', () {
    late _MockRepo repo;
    late List<Uri> opened;
    late List<StripeFormOutcome> outcomes;
    late int statusReads;
    late int linkCount;

    ProviderContainer container() {
      final c = ProviderContainer(
        retry: (_, __) => null,
        overrides: [
          spacesRepositoryProvider.overrideWithValue(repo),
          stripeFormRunnerProvider.overrideWithValue((link) async {
            opened.add(link);
            return outcomes.removeAt(0);
          }),
          stripeStatusProvider.overrideWith((ref) async {
            statusReads++;
            return const StripeStatus(hasAccount: true);
          }),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    void linksFromApi() {
      when(
        () => repo.payoutSetupLink(returnToApp: any(named: 'returnToApp')),
      ).thenAnswer(
        (_) async => Uri.parse('https://connect.stripe.com/s/${linkCount++}'),
      );
    }

    Future<void> watchStatus(ProviderContainer c) async {
      final sub = c.listen(stripeStatusProvider, (_, __) {});
      addTearDown(sub.close);
      await c.read(stripeStatusProvider.future);
    }

    setUp(() {
      repo = _MockRepo();
      opened = [];
      outcomes = [];
      statusReads = 0;
      linkCount = 0;
    });

    test("opens Stripe's link asking to come back to the app", () async {
      linksFromApi();
      outcomes = [StripeFormOutcome.returned];

      final result =
          await container().read(payoutSetupControllerProvider).open();

      expect(result, PayoutSetupResult.returned);
      expect(opened, [Uri.parse('https://connect.stripe.com/s/0')]);
      verify(() => repo.payoutSetupLink(returnToApp: true)).called(1);
    });

    test('reads the status again once Stripe sends the person back', () async {
      linksFromApi();
      outcomes = [StripeFormOutcome.returned];
      final c = container();
      await watchStatus(c);
      expect(statusReads, 1);

      await c.read(payoutSetupControllerProvider).open();
      await c.read(stripeStatusProvider.future);

      expect(statusReads, 2);
    });

    test('opens a new link when Stripe says the old one expired', () async {
      linksFromApi();
      outcomes = [StripeFormOutcome.expired, StripeFormOutcome.returned];

      final result =
          await container().read(payoutSetupControllerProvider).open();

      expect(result, PayoutSetupResult.returned);
      expect(opened, [
        Uri.parse('https://connect.stripe.com/s/0'),
        Uri.parse('https://connect.stripe.com/s/1'),
      ]);
    });

    test('stops after a few expired links instead of looping', () async {
      linksFromApi();
      outcomes = List.filled(
        PayoutSetupController.maxLinks,
        StripeFormOutcome.expired,
        growable: true,
      );

      final result =
          await container().read(payoutSetupControllerProvider).open();

      expect(result, PayoutSetupResult.left);
      expect(opened, hasLength(PayoutSetupController.maxLinks));
    });

    test('closed by the person: reads the status again', () async {
      linksFromApi();
      outcomes = [StripeFormOutcome.closed];
      final c = container();
      await watchStatus(c);

      final result = await c.read(payoutSetupControllerProvider).open();
      await c.read(stripeStatusProvider.future);

      expect(result, PayoutSetupResult.left);
      expect(statusReads, 2);
    });

    test('says so when the API refuses or the form cannot open', () async {
      when(
        () => repo.payoutSetupLink(returnToApp: any(named: 'returnToApp')),
      ).thenThrow(const ServerException('Forbidden', statusCode: 403));
      final c = container();
      expect(
        await c.read(payoutSetupControllerProvider).open(),
        PayoutSetupResult.failed,
      );
      expect(opened, isEmpty);

      linksFromApi();
      outcomes = [StripeFormOutcome.failed];
      expect(
        await c.read(payoutSetupControllerProvider).open(),
        PayoutSetupResult.failed,
      );
    });

    testWidgets('opened outside the app: reads the status when back',
        (tester) async {
      linksFromApi();
      outcomes = [StripeFormOutcome.openedElsewhere];
      final c = container();
      final sub = c.listen(stripeStatusProvider, (_, __) {});
      addTearDown(sub.close);
      await c.read(stripeStatusProvider.future);
      expect(statusReads, 1);

      await c.read(payoutSetupControllerProvider).open();
      // The browser covers the app, then the person comes back.
      [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ].forEach(tester.binding.handleAppLifecycleStateChanged);
      await c.read(stripeStatusProvider.future);

      expect(statusReads, 2);
      // Riverpod's pending timers must end before the test does.
      sub.close();
      c.dispose();
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
