import 'package:flutter_template/features/rewards/domain/wallet.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';

/// What a Wallet history line says. A change to earlier Tokens is named by what
/// happened; a grant by the action behind it ("attendEvent" is "Attend event").
String walletEntryTitle(AppLocalizations l10n, WalletEntry entry) {
  if (!entry.isGrant) {
    return switch (entry.lifecycleType) {
      'RELEASE' => l10n.rewardsLifeRelease,
      'REDEMPTION' => l10n.rewardsLifeRedemption,
      'VOUCHER_RETURN' => l10n.rewardsLifeVoucherReturn,
      'REVERSAL' => l10n.rewardsLifeReversal,
      _ => l10n.rewardsCoins,
    };
  }
  final action = entry.action;
  if (action == null || action.isEmpty) return l10n.rewardsCoins;
  // camelCase and snake_case into words, first one capital.
  final words = action
      .replaceAllMapped(RegExp('([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll('_', ' ')
      .toLowerCase()
      .trim();
  return words.isEmpty
      ? l10n.rewardsCoins
      : words[0].toUpperCase() + words.substring(1);
}
