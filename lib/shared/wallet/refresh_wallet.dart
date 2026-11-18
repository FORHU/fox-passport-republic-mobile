import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/rewards/data/rewards_repository.dart';

/// Reads the Tokens balance again, for a feature that has just spent or been
/// given Tokens and may not import Rewards itself.
void refreshWallet(WidgetRef ref) => ref.invalidate(walletProvider);
