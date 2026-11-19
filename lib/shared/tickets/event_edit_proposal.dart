/// The event's host proposes a replacement for a Supplier that can no longer
/// be part of a booked event. Nothing changes until the citizen accepts.
class EventEditProposal {
  const EventEditProposal({
    required this.id,
    required this.bookingId,
    required this.status,
    required this.itemName,
    required this.replacesName,
    required this.currentPrice,
    required this.proposedPrice,
    this.note,
    this.expiresAt,
  });

  factory EventEditProposal.fromJson(Map<String, dynamic> json) {
    num money(String key) => num.tryParse('${json[key]}') ?? 0;
    final note = (json['note'] as String?)?.trim();
    return EventEditProposal(
      id: '${json['id']}',
      bookingId: '${json['bookingId']}',
      status: '${json['status']}',
      itemName: '${json['itemName'] ?? ''}',
      replacesName: '${json['replacesName'] ?? ''}',
      currentPrice: money('currentPrice'),
      proposedPrice: money('proposedPrice'),
      note: note == null || note.isEmpty ? null : note,
      expiresAt: DateTime.tryParse('${json['expiresAt']}')?.toLocal(),
    );
  }

  final String id;
  final String bookingId;

  /// `pending`, `accepted`, `declined`, `withdrawn` or `expired`.
  final String status;

  /// The listing proposed, and the one it replaces.
  final String itemName;
  final String replacesName;

  /// What the replaced line cost and what the new one costs, fees included.
  final num currentPrice;
  final num proposedPrice;
  final String? note;
  final DateTime? expiresAt;

  num get priceDelta => proposedPrice - currentPrice;

  /// Still waiting for the citizen's answer.
  bool isOpen({DateTime? now}) =>
      status == 'pending' &&
      (expiresAt == null || expiresAt!.isAfter(now ?? DateTime.now()));
}
