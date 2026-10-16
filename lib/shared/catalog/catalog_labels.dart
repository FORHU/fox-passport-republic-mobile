import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/formatting/money.dart';
import 'package:intl/intl.dart';

/// "₱25,000/night": the price and the unit it is charged per, or null when
/// the item has no price.
///
/// The currency symbol follows the item's own currency code and the number
/// format follows [locale], so nothing here is tied to one country.
String? catalogPriceLabel(
  AppLocalizations l10n,
  CatalogItem item, {
  String? locale,
  MoneyFormatter? formatter,
}) {
  final price = item.price;
  // A price of 0 means "not priced yet", not "free".
  if (price == null || price <= 0) return null;
  final money = formatter != null
      ? formatter.format(price, item.currency, locale: locale)
      : formatMoney(price, item.currency, locale: locale);
  final unit = switch (item.billingRate) {
    'hourly' => l10n.priceUnitHour,
    'daily' => l10n.priceUnitDay,
    'weekly' => l10n.priceUnitWeek,
    'monthly' => l10n.priceUnitMonth,
    'yearly' => l10n.priceUnitYear,
    _ => null,
  };
  return unit == null ? money : '$money/$unit';
}

/// "Davao City · 200 guests", leaving out whatever the item doesn't have.
String catalogSubtitle(
  AppLocalizations l10n,
  CatalogItem item, {
  String? locale,
}) {
  final parts = <String>[
    if (item.city != null && item.city!.isNotEmpty) item.city!,
    if (item.eventStartAt != null)
      DateFormat('EEE d MMM', locale).format(item.eventStartAt!),
    if (item.capacity != null) l10n.guestsCount(item.capacity!),
    if (item.kind == CatalogKind.events &&
        item.host != null &&
        item.host!.isNotEmpty)
      l10n.searchHostedBy(item.host!),
  ];
  return parts.join(' · ');
}

/// "Indoor", "Outdoor" or the raw tag, capitalised, for a venue space type.
String spaceTypeLabel(AppLocalizations l10n, String tag) => switch (tag) {
      'indoor' => l10n.spaceIndoor,
      'outdoor' => l10n.spaceOutdoor,
      _ => tag.isEmpty ? tag : tag[0].toUpperCase() + tag.substring(1),
    };

/// A Foxer's main role as a label, or null when none is recognised.
String? foxerRoleLabel(AppLocalizations l10n, List<String> roles) {
  for (final role in roles) {
    final label = switch (role) {
      'eventFoxer' => l10n.messageRoleEventFoxer,
      'venueFoxer' => l10n.messageRoleVenueFoxer,
      'gearFoxer' => l10n.messageRoleGearFoxer,
      'serviceFoxer' => l10n.messageRoleServiceFoxer,
      'performerFoxer' => l10n.messageRolePerformer,
      _ => null,
    };
    if (label != null) return label;
  }
  return null;
}

/// "birthday" or "live_band" as "Birthday" / "Live band".
String categoryLabel(String raw) {
  final text = raw.trim().replaceAll('_', ' ');
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}
