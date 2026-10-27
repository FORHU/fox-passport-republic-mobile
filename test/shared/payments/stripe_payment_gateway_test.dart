import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/config/environment.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/shared/payments/payments_repository.dart';
import 'package:flutter_template/shared/payments/stripe_payment_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

/// A payment sheet that does what it is told, and remembers what it was asked.
class _FakeSheet implements PaymentSheetDriver {
  _FakeSheet({this.onPresent, this.prepareFails = false});

  final Future<void> Function()? onPresent;
  final bool prepareFails;
  final calls = <String>[];

  @override
  Future<void> prepare({
    required String clientSecret,
    required String merchantName,
  }) async {
    calls.add('prepare $clientSecret as $merchantName');
    if (prepareFails) throw const ServerException('Could not open the sheet');
  }

  @override
  Future<void> present() async {
    calls.add('present');
    await onPresent?.call();
  }
}

AppConfig _config({String stripeKey = '', bool mock = false}) => AppConfig(
      environment: Environment.dev,
      appName: 'Fox Passport',
      baseUrl: 'http://localhost:6002/api/v1',
      useMock: mock,
      stripePublishableKey: stripeKey,
    );

void main() {
  group('StripePaymentGateway', () {
    test('opens the sheet for the secret, and answers with the payment id',
        () async {
      final sheet = _FakeSheet();
      final gateway =
          StripePaymentGateway(merchantName: 'Fox Passport', sheet: sheet);

      final id = await gateway.pay(
        clientSecret: 'pi_3Abc_secret_xyz',
        amount: 26250,
        currency: 'PHP',
      );

      expect(id, 'pi_3Abc');
      expect(sheet.calls, [
        'prepare pi_3Abc_secret_xyz as Fox Passport',
        'present',
      ]);
    });

    test('reads the payment id out of a client secret', () {
      expect(StripePaymentGateway.paymentIntentIdOf('pi_1_secret_x'), 'pi_1');
      expect(StripePaymentGateway.paymentIntentIdOf('pi_1'), 'pi_1');
    });

    test('closing the sheet is a cancel, not a failure', () async {
      final gateway = StripePaymentGateway(
        merchantName: 'Fox Passport',
        sheet:
            _FakeSheet(onPresent: () async => throw const PaymentCancelled()),
      );

      await expectLater(
        gateway.pay(clientSecret: 'pi_1_secret_x', amount: 1, currency: 'PHP'),
        throwsA(isA<PaymentCancelled>()),
      );
    });

    test("a refused card keeps Stripe's words", () async {
      final gateway = StripePaymentGateway(
        merchantName: 'Fox Passport',
        sheet: _FakeSheet(
          onPresent: () async =>
              throw const ServerException('Your card was declined.'),
        ),
      );

      await expectLater(
        gateway.pay(clientSecret: 'pi_1_secret_x', amount: 1, currency: 'PHP'),
        throwsA(
          isA<ServerException>()
              .having((e) => e.message, 'message', 'Your card was declined.'),
        ),
      );
    });

    test('no secret from the API means no sheet', () async {
      final sheet = _FakeSheet();
      final gateway =
          StripePaymentGateway(merchantName: 'Fox Passport', sheet: sheet);

      for (final secret in [null, '']) {
        await expectLater(
          gateway.pay(clientSecret: secret, amount: 1, currency: 'PHP'),
          throwsA(isA<ServerException>()),
        );
      }
      expect(sheet.calls, isEmpty);
    });

    test('a sheet that fails to prepare is never shown', () async {
      final sheet = _FakeSheet(prepareFails: true);
      final gateway =
          StripePaymentGateway(merchantName: 'Fox Passport', sheet: sheet);

      await expectLater(
        gateway.pay(clientSecret: 'pi_1_secret_x', amount: 1, currency: 'PHP'),
        throwsA(isA<ServerException>()),
      );
      expect(sheet.calls.where((c) => c == 'present'), isEmpty);
    });
  });

  group('which gateway the app uses', () {
    // The app's config is global; put the plain dev one back after each test.
    setUp(() => AppConfig.instance = const AppConfig.dev());
    tearDown(() => AppConfig.instance = const AppConfig.dev());

    PaymentGateway pick(AppConfig config) {
      AppConfig.instance = config;
      final container = ProviderContainer();
      addTearDown(container.dispose);
      return container.read(paymentGatewayProvider);
    }

    test('Stripe when there is a publishable key', () {
      expect(
        pick(_config(stripeKey: 'pk_test_123')),
        isA<StripePaymentGateway>(),
      );
    });

    test('the stub, which refuses, when there is no key', () {
      expect(pick(_config()), isA<StubPaymentGateway>());
    });

    test('the stub against the mock backend, even with a key', () {
      expect(
        pick(_config(stripeKey: 'pk_test_123', mock: true)),
        isA<StubPaymentGateway>(),
      );
    });
  });

  group('paying for a booking', () {
    late _MockApi api;

    setUp(() {
      api = _MockApi();
      when(() => api.post(ApiEndpoints.createPaymentIntent, any())).thenAnswer(
        (_) async => {
          'data': {
            'clientSecret': 'pi_9_secret_abc',
            'paymentIntentId': 'pi_9',
          },
        },
      );
      when(() => api.post(ApiEndpoints.bookingConfirm('b1'), any()))
          .thenAnswer((_) async => {});
    });

    test('takes the card, then confirms the booking with the payment id',
        () async {
      final repo = PaymentsRepository(
        api,
        StripePaymentGateway(merchantName: 'Fox Passport', sheet: _FakeSheet()),
      );

      await repo.payBooking(bookingId: 'b1', amount: 26250, currency: 'PHP');

      verify(
        () => api.post(
          ApiEndpoints.createPaymentIntent,
          {'amount': 26250, 'currency': 'PHP', 'bookingId': 'b1'},
        ),
      ).called(1);
      verify(
        () => api.post(
          ApiEndpoints.bookingConfirm('b1'),
          {'amount': 26250, 'method': 'stripe', 'transactionId': 'pi_9'},
        ),
      ).called(1);
    });

    test('a closed sheet confirms nothing', () async {
      final repo = PaymentsRepository(
        api,
        StripePaymentGateway(
          merchantName: 'Fox Passport',
          sheet:
              _FakeSheet(onPresent: () async => throw const PaymentCancelled()),
        ),
      );

      await expectLater(
        repo.payBooking(bookingId: 'b1', amount: 1, currency: 'PHP'),
        throwsA(isA<PaymentCancelled>()),
      );
      verifyNever(() => api.post(ApiEndpoints.bookingConfirm('b1'), any()));
    });

    test('a refused card confirms nothing either', () async {
      final repo = PaymentsRepository(
        api,
        StripePaymentGateway(
          merchantName: 'Fox Passport',
          sheet: _FakeSheet(
            onPresent: () async => throw const ServerException('Declined'),
          ),
        ),
      );

      await expectLater(
        repo.payBooking(bookingId: 'b1', amount: 1, currency: 'PHP'),
        throwsA(isA<ServerException>()),
      );
      verifyNever(() => api.post(ApiEndpoints.bookingConfirm('b1'), any()));
    });
  });
}
