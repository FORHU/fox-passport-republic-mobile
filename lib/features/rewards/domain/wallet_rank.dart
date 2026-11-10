import 'package:flutter_template/features/rewards/domain/wallet.dart';

/// Whether the server has named a rank, so "Explorer · Level 5" can be shown.
extension WalletRank on WalletSummary {
  bool get hasRank => rank.isNotEmpty;
}
