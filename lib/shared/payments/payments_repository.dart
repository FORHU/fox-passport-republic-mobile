import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/shared/payments/payment_gateway.dart';
import 'package:flutter_template/shared/payments/stripe_payment_gateway.dart';

// Callers reach the gateway types through here.
export 'package:flutter_template/shared/payments/payment_gateway.dart';

final paymentGatewayProvider = Provider<PaymentGateway>((ref) {
  final key = AppConfig.instance.stripePublishableKey;
  // Real card payments need Stripe's publishable key; without one (or against
  // the mock backend) the stub says so rather than pretend.
  if (key.isEmpty || AppConfig.instance.useMock) return StubPaymentGateway();
  return StripePaymentGateway(merchantName: AppConfig.instance.appName);
});

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
