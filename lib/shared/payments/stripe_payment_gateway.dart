import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/shared/payments/payment_gateway.dart';

/// The two calls the payment sheet needs, so the gateway can be tested
/// without a phone.
abstract class PaymentSheetDriver {
  /// Prepares the sheet for [clientSecret].
  Future<void> prepare({
    required String clientSecret,
    required String merchantName,
  });

  /// Shows the sheet and waits. Returns when the payment is done; throws a
  /// [PaymentCancelled] when the person closed it, or an [AppException] with
  /// Stripe's own words when the card was refused.
  Future<void> present();
}

/// Stripe's payment sheet, through `flutter_stripe`.
class FlutterStripeSheet implements PaymentSheetDriver {
  const FlutterStripeSheet();

  @override
  Future<void> prepare({
    required String clientSecret,
    required String merchantName,
  }) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: merchantName,
          style: ThemeMode.dark,
        ),
      );
    } on StripeException catch (e) {
      throw ServerException(_words(e));
    }
  }

  @override
  Future<void> present() async {
    try {
      await Stripe.instance.presentPaymentSheet();
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) throw const PaymentCancelled();
      throw ServerException(_words(e));
    }
  }

  static String _words(StripeException e) =>
      e.error.localizedMessage ??
      e.error.message ??
      'The payment did not go through.';
}

/// Takes a card payment with Stripe's payment sheet.
///
/// The API creates the payment and hands over its client secret; the sheet
/// takes the card. Nothing secret lives in the app: only Stripe's publishable
/// key, which is meant to be public.
class StripePaymentGateway implements PaymentGateway {
  const StripePaymentGateway({
    required this.merchantName,
    this.sheet = const FlutterStripeSheet(),
  });

  final String merchantName;
  final PaymentSheetDriver sheet;

  @override
  Future<String> pay({
    required String? clientSecret,
    required num amount,
    required String currency,
  }) async {
    final secret = clientSecret;
    if (secret == null || secret.isEmpty) {
      // The API did not mint a payment: nothing to take a card for.
      throw const ServerException('The payment could not be started.');
    }
    await sheet.prepare(clientSecret: secret, merchantName: merchantName);
    await sheet.present();
    return paymentIntentIdOf(secret);
  }

  /// `pi_123_secret_abc` is the secret of payment `pi_123`.
  static String paymentIntentIdOf(String clientSecret) {
    final cut = clientSecret.indexOf('_secret_');
    return cut < 0 ? clientSecret : clientSecret.substring(0, cut);
  }
}
