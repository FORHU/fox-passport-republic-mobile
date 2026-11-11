import 'package:equatable/equatable.dart';
import 'package:flutter_template/features/passport/domain/entities/passport_summary.dart';

/// A Foxer's Passport for one role: the perks they hold and the badges they
/// can earn in it. There is no level or XP: those are retired.
class FoxerPassport extends Equatable {
  const FoxerPassport({
    required this.path,
    required this.perks,
    required this.badges,
  });

  /// The role as the API names it (`venueFoxer`, `eventFoxer`, ...).
  final String path;

  /// Perk keys the account holds, as the API stores them.
  final List<String> perks;

  /// Badges earned in this role or for any role, then those still locked.
  final List<PassportBadge> badges;

  @override
  List<Object?> get props => [path, perks, badges];
}
