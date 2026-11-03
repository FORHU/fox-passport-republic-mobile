import 'package:flutter_template/core/config/app_config.dart';

/// Card payments are not available in this build.
class PaymentsUnavailable implements Exception {
  const PaymentsUnavailable();
}

/// The person closed the payment sheet without paying. Not an error: nothing
/// went wrong and nothing was charged.
class PaymentCancelled implements Exception {
  const PaymentCancelled();
}

/// Takes a card payment for a booking.
abstract class PaymentGateway {
  /// Returns the payment intent id once the payment has gone through.
  Future<String> pay({
    required String? clientSecret,
    required num amount,
    required String currency,
  });
}

/// Succeeds only when the app runs against the mock backend, so nothing is
/// ever reported as paid that was not. Used when there is no Stripe key.
class StubPaymentGateway implements PaymentGateway {
  @override
  Future<String> pay({
    required String? clientSecret,
    required num amount,
    required String currency,
  }) async {
    if (AppConfig.instance.useMock) return 'pi_mock';
    throw const PaymentsUnavailable();
  }
}
