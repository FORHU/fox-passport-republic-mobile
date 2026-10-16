import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';

/// Card payments are not available in this build.
class PaymentsUnavailable implements Exception {
  const PaymentsUnavailable();
}

/// Takes a card payment for a booking.
///
/// The real implementation is Stripe's payment sheet, which is not in the app
/// yet. Swap this provider when it is.
abstract class PaymentGateway {
  /// Returns the payment intent id once the payment has gone through.
  Future<String> pay({
    required String? clientSecret,
    required num amount,
    required String currency,
  });
}

/// Succeeds only when the app runs against the mock backend, so nothing is
/// ever reported as paid that was not.
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

final paymentGatewayProvider =
    Provider<PaymentGateway>((ref) => StubPaymentGateway());

/// Pays for a booking that exists: creates the payment intent, runs it
/// through the [PaymentGateway] and confirms the booking.
class PaymentsRepository {
  PaymentsRepository(this._api, this._gateway);

  final ApiService _api;
  final PaymentGateway _gateway;

  /// Throws [PaymentsUnavailable] when the app cannot take a card yet.
  Future<void> payBooking({
    required String bookingId,
    required num amount,
    required String currency,
  }) async {
    final body = await _api.post(ApiEndpoints.createPaymentIntent, {
      'amount': amount,
      'currency': currency,
      'bookingId': bookingId,
    });
    final data = body is Map ? body['data'] : null;
    final secret = data is Map ? data['clientSecret']?.toString() : null;
    final intentId = data is Map ? data['paymentIntentId']?.toString() : null;

    final paid = await _gateway.pay(
      clientSecret: secret,
      amount: amount,
      currency: currency,
    );
    await _api.post(ApiEndpoints.bookingConfirm(bookingId), {
      'amount': amount,
      'method': 'stripe',
      'transactionId': intentId ?? paid,
    });
  }
}

final paymentsRepositoryProvider = Provider<PaymentsRepository>(
  (ref) => PaymentsRepository(
    ref.watch(apiServiceProvider),
    ref.watch(paymentGatewayProvider),
  ),
);
