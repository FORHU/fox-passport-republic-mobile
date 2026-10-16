import 'package:intl/intl.dart';

/// Formats [amount] in [currency], an ISO 4217 code such as `PHP` or `USD`.
///
/// The code comes from the data (every venue, asset and service carries one),
/// so nothing here assumes a country. Whole amounts drop their decimals:
/// `₱25,000`, not `₱25,000.00`.
String formatMoney(num amount, String currency, {String? locale}) {
  final code = currency.trim().isEmpty ? 'USD' : currency.trim().toUpperCase();
  final whole = amount == amount.roundToDouble();
  final symbol =
      NumberFormat.simpleCurrency(name: code, locale: locale).currencySymbol;
  return NumberFormat.currency(
    locale: locale,
    name: code,
    symbol: symbol,
    decimalDigits: whole ? 0 : 2,
  ).format(amount);
}
