import 'package:equatable/equatable.dart';

/// A stamp earned by attending an event.
class PassportStamp extends Equatable {
  const PassportStamp({
    required this.label,
    required this.date,
  });

  /// Three letters for the place, e.g. `DVO`.
  final String label;
  final DateTime? date;

  @override
  List<Object?> get props => [label, date];
}

/// A badge in the catalogue, earned or not.
class PassportBadge extends Equatable {
  const PassportBadge({
    required this.id,
    required this.name,
    required this.earned,
    this.colorHex,
    this.path,
  });

  final String id;
  final String name;
  final bool earned;

  /// `#RRGGBB` from the catalogue, when it has one.
  final String? colorHex;

  /// The role the badge belongs to (`venueFoxer`, ...), or null for one that
  /// is not tied to a role.
  final String? path;

  @override
  List<Object?> get props => [id, name, earned, colorHex, path];
}

/// Everything the Passport screen shows: stamps and badges. There is no level
/// or XP: those are retired.
class PassportSummary extends Equatable {
  const PassportSummary({
    required this.stamps,
    required this.badges,
    this.isSample = false,
  });

  /// What a new Citizen's passport looks like, for when there is no data yet.
  factory PassportSummary.sample() => PassportSummary(
        stamps: [
          PassportStamp(label: 'DVO', date: DateTime(2026, 10)),
          PassportStamp(label: 'BAG', date: DateTime(2026, 9)),
        ],
        badges: const [
          PassportBadge(id: 'sample-1', name: 'First night', earned: true),
          PassportBadge(id: 'sample-2', name: '', earned: false),
        ],
        isSample: true,
      );

  /// Stamps a passport page holds.
  static const int stampSlots = 8;

  final List<PassportStamp> stamps;
  final List<PassportBadge> badges;
  final bool isSample;

  @override
  List<Object?> get props => [stamps, badges, isSample];
}
