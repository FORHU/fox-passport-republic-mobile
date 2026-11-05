import 'package:flutter_template/features/rewards/domain/reward_item.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

/// "₱100 off" for a Peso discount, "10% off" for a percentage one, and the
/// reward's own title for a perk. The numbers come from the server; the words
/// are the app's, so they are translated.
String rewardTitle(AppLocalizations l10n, RewardItem item) =>
    _off(l10n, item.discountPhp, item.discountPercentage) ?? item.title;

/// The same wording for a voucher that was issued.
String voucherOff(
  AppLocalizations l10n, {
  double? php,
  double? percent,
}) =>
    _off(l10n, php, percent) ?? '';

String? _off(AppLocalizations l10n, double? php, double? percent) {
  if (php != null) {
    return l10n.rewardsOffPhp(NumberFormat.decimalPattern().format(php));
  }
  if (percent != null) {
    return l10n.rewardsOffPercent(NumberFormat('0.##').format(percent));
  }
  return null;
}
