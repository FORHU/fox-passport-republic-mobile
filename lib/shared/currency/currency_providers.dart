import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/location/area.dart';

const _choiceKey = 'currency.choice';

/// Today's exchange rates, or null when they cannot be had; amounts are then
/// shown in the currency they are priced in.
final FutureProvider<FxRates?> fxRatesProvider =
    FutureProvider<FxRates?>((ref) async {
  try {
    final body = await ref
        .watch(apiServiceProvider)
        .get(ApiEndpoints.fxRates, query: {'base': kBaseCurrency});
    final data = body is Map ? (body['data'] ?? body) : null;
    if (data is! Map) return null;
    return FxRates.fromJson(data.cast<String, dynamic>());
  } on Object {
    return null;
  }
});

/// The currency the user picked, or null while they leave it automatic.
class CurrencyChoiceController extends Notifier<String?> {
  @override
  String? build() {
    // A preference that cannot be read must not stop prices from showing.
    try {
      return ref.read(storageServiceProvider).getString(_choiceKey);
    } on Object {
      return null;
    }
  }

  /// Picks [code] and saves it to the account, as the web app does. The
  /// account write is best effort: a failure keeps the choice on this device.
  Future<void> choose(String code) async {
    state = code;
    await ref.read(storageServiceProvider).setString(_choiceKey, code);
    if (!ref.read(authControllerProvider).isAuthenticated) return;
    try {
      await ref
          .read(apiServiceProvider)
          .put(ApiEndpoints.profile, {'preferredCurrency': code});
    } on Object {
      // Kept locally; it will simply not follow the user to another device.
    }
  }

  /// Goes back to deriving the currency from the user's location.
  Future<void> useAutomatic() async {
    state = null;
    await ref.read(storageServiceProvider).remove(_choiceKey);
  }
}

final currencyChoiceProvider =
    NotifierProvider<CurrencyChoiceController, String?>(
  CurrencyChoiceController.new,
);

/// The currency of where the user is: the device's country when they shared
/// it, otherwise the country on their profile.
final Provider<String?> locationCurrencyProvider = Provider<String?>((ref) {
  final area = ref.watch(areaProvider);
  if (area.source == AreaSource.device) {
    final byDevice = currencyForCountry(area.deviceCountry);
    if (byDevice != null) return byDevice;
  }
  final profile = ref.watch(profileLocationProvider).value;
  return currencyForCountry(profile?.country);
});

/// The currency amounts are shown in.
///
/// In order: what the user picked here; a non-default currency they set on
/// their account (the API defaults everyone to the platform currency, so that
/// value alone says nothing); the currency of where they are; the platform
/// currency.
final Provider<String> displayCurrencyProvider = Provider<String>((ref) {
  final chosen = ref.watch(currencyChoiceProvider);
  if (chosen != null) return chosen;
  final account = ref.watch(profileLocationProvider).value?.preferredCurrency;
  if (account != null && account != kBaseCurrency) return account;
  return ref.watch(locationCurrencyProvider) ?? account ?? kBaseCurrency;
});

/// Formats an amount in the user's currency, converting when it can.
final Provider<MoneyFormatter> moneyFormatterProvider =
    Provider<MoneyFormatter>((ref) {
  return MoneyFormatter(
    currency: ref.watch(displayCurrencyProvider),
    rates: ref.watch(fxRatesProvider).value,
  );
});
