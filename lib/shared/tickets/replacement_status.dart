/// Where a booked event stands when a Supplier dropped out (the answer of
/// `GET /event-transactions/booking/:id/replacement`): which items need
/// replacing, by when, and whether cancelling now refunds in full.
class ReplacementStatus {
  const ReplacementStatus({
    required this.items,
    this.replaceBy,
    this.fullRefund = false,
  });

  factory ReplacementStatus.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return ReplacementStatus(
      items: [
        if (raw is List)
          for (final i in raw)
            if (i is Map)
              ReplacementItem(
                itemName: '${i['itemName'] ?? ''}',
                pendingProposalId: i['pendingProposalId'] is String
                    ? i['pendingProposalId'] as String
                    : null,
              ),
      ],
      replaceBy: DateTime.tryParse('${json['replaceBy']}')?.toLocal(),
      fullRefund: json['fullRefund'] == true,
    );
  }

  static const none = ReplacementStatus(items: []);

  final List<ReplacementItem> items;

  /// The earliest deadline; past it the citizen may cancel for a full refund.
  final DateTime? replaceBy;
  final bool fullRefund;

  bool get needsReplacement => items.isNotEmpty;

  /// A replacement the host proposed, waiting for the citizen's answer.
  bool get hasProposal => items.any((i) => i.pendingProposalId != null);
}

class ReplacementItem {
  const ReplacementItem({required this.itemName, this.pendingProposalId});

  final String itemName;
  final String? pendingProposalId;
}
