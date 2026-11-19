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
/// where they usually weren't signed in.
void main() {
  group('SpacesRepository.payoutSetupLink', () {
    late _MockApi api;
    late SpacesRepository repo;

    setUp(() {
      api = _MockApi();
      repo = SpacesRepository(api, 'u1');
    });

    test("asks the API for the person's own Stripe link", () async {
      when(() => api.post(ApiEndpoints.stripeOnboard)).thenAnswer(
        (_) async => {
          'success': true,
          'data': {'url': 'https://connect.stripe.com/setup/e/acct_1/abc'},
        },
      );

      final link = await repo.payoutSetupLink();

      expect(link.toString(), 'https://connect.stripe.com/setup/e/acct_1/abc');
      verify(() => api.post(ApiEndpoints.stripeOnboard)).called(1);
    });

    test('refuses a response without an https link', () async {
      when(() => api.post(ApiEndpoints.stripeOnboard)).thenAnswer(
        (_) async => {
          'data': {'url': 'javascript:alert(1)'},
        },
      );
      await expectLater(repo.payoutSetupLink(), throwsFormatException);

      when(() => api.post(ApiEndpoints.stripeOnboard))
          .thenAnswer((_) async => {'data': <String, Object>{}});
      await expectLater(repo.payoutSetupLink(), throwsFormatException);
    });
  });

  group('PayoutSetupController', () {
    late _MockRepo repo;
    late List<Uri> opened;
    late bool openResult;
    late int statusReads;

    ProviderContainer container() {
      final c = ProviderContainer(
        retry: (_, __) => null,
        overrides: [
          spacesRepositoryProvider.overrideWithValue(repo),
          payoutSetupOpenerProvider.overrideWithValue((link) async {
            opened.add(link);
            return openResult;
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

    setUp(() {
      repo = _MockRepo();
      opened = [];
      openResult = true;
      statusReads = 0;
    });

    test("opens Stripe's link", () async {
      final link = Uri.parse('https://connect.stripe.com/setup/x');
      when(() => repo.payoutSetupLink()).thenAnswer((_) async => link);

      final ok = await container().read(payoutSetupControllerProvider).open();

      expect(ok, isTrue);
      expect(opened, [link]);
    });

    test('says so when the API refuses or the link cannot open', () async {
      when(() => repo.payoutSetupLink())
          .thenThrow(const ServerException('Forbidden', statusCode: 403));
      final c = container();
      expect(await c.read(payoutSetupControllerProvider).open(), isFalse);
      expect(opened, isEmpty);

      when(() => repo.payoutSetupLink())
          .thenAnswer((_) async => Uri.parse('https://connect.stripe.com/s'));
      openResult = false;
      expect(await c.read(payoutSetupControllerProvider).open(), isFalse);
    });

    testWidgets('reads the status again when the person comes back',
        (tester) async {
      when(() => repo.payoutSetupLink())
          .thenAnswer((_) async => Uri.parse('https://connect.stripe.com/s'));
      final c = container();
      final sub = c.listen(stripeStatusProvider, (_, __) {});
      addTearDown(sub.close);
      await c.read(stripeStatusProvider.future);
      expect(statusReads, 1);

      await c.read(payoutSetupControllerProvider).open();
      // Stripe's form covers the app, then the person closes it.
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
