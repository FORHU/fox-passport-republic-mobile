/// A request to change a booking (its guests or dates), and where the venue
/// has got to with it.
class EditRequest {
  const EditRequest({
    required this.id,
    required this.status,
    required this.currentTotal,
    required this.proposedTotal,
    this.proposedGuests,
    this.proposedStart,
    this.proposedEnd,
    this.reason,
    this.declineReason,
    this.canWithdraw = false,
    this.applied = false,
  });

  factory EditRequest.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) => DateTime.tryParse('${json[key]}')?.toLocal();
    num money(String key) => num.tryParse('${json[key]}') ?? 0;
    String? text(String key) {
      final v = (json[key] as String?)?.trim();
      return v == null || v.isEmpty ? null : v;
    }

    return EditRequest(
      id: '${json['id']}',
      status: '${json['status']}',
      currentTotal: money('currentTotalAmount'),
      proposedTotal: money('proposedTotalAmount'),
      proposedGuests: (json['proposedGuestCount'] as num?)?.toInt(),
      proposedStart: date('proposedStartDate'),
      proposedEnd: date('proposedEndDate'),
      reason: text('reason'),
      declineReason: text('declineReason'),
      canWithdraw: json['canWithdraw'] == true,
      applied: json['appliedAt'] != null,
    );
  }

  final String id;

  /// `pending`, `approved`, `declined`, `withdrawn` or `expired`.
  final String status;
  final num currentTotal;
  final num proposedTotal;
  final int? proposedGuests;
  final DateTime? proposedStart;
  final DateTime? proposedEnd;
  final String? reason;
  final String? declineReason;
  final bool canWithdraw;

  /// The change has taken effect on the booking.
  final bool applied;

  bool get isPending => status == 'pending';

  /// Approved, but the price went up and the difference is still unpaid.
  bool get awaitsPayment =>
      status == 'approved' && !applied && proposedTotal > currentTotal;
}
