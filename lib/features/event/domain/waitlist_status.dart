import 'package:equatable/equatable.dart';

/// Where someone stands on one event's waitlist. The waitlist belongs to the
/// event package (its template), not to one date.
class WaitlistStatus extends Equatable {
  const WaitlistStatus({
    this.isOnWaitlist = false,
    this.position,
    this.entryId,
    this.totalWaiting = 0,
  });

  /// Reads what `GET /waitlist` and `POST /waitlist` send. The join answer
  /// nests the row under `entry`.
  factory WaitlistStatus.fromJson(Object? json) {
    if (json is! Map) return const WaitlistStatus();
    final entry = json['entry'];
    final entryId = json['entryId'] ?? (entry is Map ? entry['id'] : null);
    final position = (json['position'] as num?)?.toInt();
    return WaitlistStatus(
      isOnWaitlist: json['isOnWaitlist'] == true || entry is Map,
      // The API says -1 for "not on it".
      position: position != null && position > 0 ? position : null,
      entryId: entryId == null ? null : '$entryId',
      totalWaiting: (json['totalWaiting'] as num?)?.toInt() ?? 0,
    );
  }

  final bool isOnWaitlist;

  /// 1 is next in line.
  final int? position;
  final String? entryId;
  final int totalWaiting;

  /// What this looks like after leaving.
  WaitlistStatus get left => WaitlistStatus(
        totalWaiting: totalWaiting > 0 ? totalWaiting - 1 : 0,
      );

  @override
  List<Object?> get props => [isOnWaitlist, position, entryId, totalWaiting];
}
