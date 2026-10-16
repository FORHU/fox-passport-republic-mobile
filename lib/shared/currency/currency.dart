import 'package:flutter_template/shared/formatting/money.dart';

/// The platform's own currency: what venues and gear are priced and charged
/// in when a row carries no currency. Mirrors the web app's
/// `DEFAULT_CURRENCY`.
const kBaseCurrency = 'PHP';

/// The currencies the API can convert between (`/fx/rates`). Used until the
/// API's own list arrives, and when it cannot be reached.
const kSupportedCurrencies = [
  'PHP',
  'USD',
  'EUR',
  'GBP',
  'JPY',
  'AUD',
  'SGD',
  'CAD',
  'HKD',
  'KRW',
];

/// Exchange rates, as units of each currency per 1 unit of [base].
class FxRates {
  const FxRates({
    required this.base,
    required this.rates,
    this.currencies = kSupportedCurrencies,
  });

  factory FxRates.fromJson(Map<String, dynamic> json) {
    final rawRates = json['rates'];
    final rawList = json['currencies'];
    return FxRates(
      base: (json['base'] as String?) ?? kBaseCurrency,
      rates: {
        if (rawRates is Map)
          for (final e in rawRates.entries)
            if (e.key is String && e.value is num)
              e.key as String: e.value as num,
      },
      currencies: rawList is List && rawList.isNotEmpty
          ? rawList.whereType<String>().toList()
          : kSupportedCurrencies,
    );
  }

  final String base;
  final Map<String, num> rates;
  final List<String> currencies;
}

/// Converts [amount] from one currency to another through [rates]. Returns
/// the amount unchanged when there is no rate, so a missing rate shows the
/// original figure rather than a wrong one.
num convertCurrency(num amount, String from, String to, FxRates? rates) {
  if (from == to || rates == null) return amount;
  final fromRate = from == rates.base ? 1 : rates.rates[from];
  final toRate = to == rates.base ? 1 : rates.rates[to];
  if (fromRate == null || toRate == null || fromRate == 0) return amount;
  return amount / fromRate * toRate;
}

/// Shows amounts in the currency the viewer chose.
class MoneyFormatter {
  const MoneyFormatter({required this.currency, this.rates});

  /// What amounts are shown in.
  final String currency;
  final FxRates? rates;

  /// Whether [from] differs from what is shown, and there is a rate to
  /// convert with.
  bool converts(String from) => from != currency && rates != null;

  num convert(num amount, String from) =>
      convertCurrency(amount, from, currency, rates);

  /// [amount], denominated in [from], in the viewer's currency.
  String format(num amount, String from, {String? locale}) => formatMoney(
        convert(amount, from),
        converts(from) ? currency : from,
        locale: locale,
      );
}

/// The currency a country's people use, limited to the ones the API
/// converts. Takes an ISO 3166 code ("PH") or an English name
/// ("Philippines"); null when it is not one we know.
String? currencyForCountry(String? country) {
  final raw = country?.trim();
  if (raw == null || raw.isEmpty) return null;
  final byCode = _currencyByCode[raw.toUpperCase()];
  if (byCode != null) return byCode;
  return _currencyByName[raw.toLowerCase()];
}

const _euro = [
  'AT', 'BE', 'CY', 'DE', 'EE', 'ES', 'FI', 'FR', 'GR', 'HR', 'IE', 'IT',
  'LT', 'LU', 'LV', 'MT', 'NL', 'PT', 'SI', 'SK', //
];

final Map<String, String> _currencyByCode = {
  'PH': 'PHP',
  'US': 'USD',
  'GB': 'GBP',
  'JP': 'JPY',
  'AU': 'AUD',
  'SG': 'SGD',
  'CA': 'CAD',
  'HK': 'HKD',
  'KR': 'KRW',
  for (final code in _euro) code: 'EUR',
};

const _currencyByName = {
  'philippines': 'PHP',
  'united states': 'USD',
  'united states of america': 'USD',
  'united kingdom': 'GBP',
  'japan': 'JPY',
  'australia': 'AUD',
  'singapore': 'SGD',
  'canada': 'CAD',
  'hong kong': 'HKD',
  'south korea': 'KRW',
  'korea, republic of': 'KRW',
  'austria': 'EUR',
  'belgium': 'EUR',
  'cyprus': 'EUR',
  'germany': 'EUR',
  'estonia': 'EUR',
  'spain': 'EUR',
  'finland': 'EUR',
  'france': 'EUR',
  'greece': 'EUR',
  'croatia': 'EUR',
  'ireland': 'EUR',
  'italy': 'EUR',
  'lithuania': 'EUR',
  'luxembourg': 'EUR',
  'latvia': 'EUR',
  'malta': 'EUR',
  'netherlands': 'EUR',
  'portugal': 'EUR',
  'slovenia': 'EUR',
  'slovakia': 'EUR',
};
