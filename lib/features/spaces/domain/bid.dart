import 'package:equatable/equatable.dart';

enum BidStatus {
  pending,
  accepted,
  rejected,
  withdrawn;

  static BidStatus of(Object? raw) => values.firstWhere(
        (s) => s.name == raw,
        orElse: () => BidStatus.pending,
      );
}

/// One application to supply a service or gear for an event.
class Bid extends Equatable {
  const Bid({
    required this.id,
    required this.isService,
    required this.status,
    required this.provider,
    required this.offer,
    required this.price,
    required this.currency,
    this.slot,
    this.message,
    this.quantity,
  });

  /// Reads one row of an event's service or gear bids; null when it has no id.
  static Bid? tryParse(Object? row, {required bool isService}) {
    if (row is! Map || row['id'] == null) return null;
    String? text(Object? v) => v is String && v.trim().isNotEmpty ? v : null;
    final provider = row['provider'];
    final offer = row[isService ? 'proposedService' : 'proposedAsset'];
    final slot = row['targetRequirement'];
    final price = row['proposedPrice'];
    final quantity = row['proposedQuantity'];
    return Bid(
      id: '${row['id']}',
      isService: isService,
      status: BidStatus.of(row['status']),
      provider: provider is Map ? text(provider['name']) ?? '' : '',
      offer: offer is Map ? text(offer['name']) ?? '' : '',
      price: price is num ? price : num.tryParse('$price') ?? 0,
      currency: slot is Map ? text(slot['currency']) : null,
      slot: slot is Map ? text(slot['description']) : null,
      message: text(row['message']),
      quantity: quantity is int && quantity > 1 ? quantity : null,
    );
  }

  final String id;

  /// A service bid, else a gear bid. The two are answered on different paths.
  final bool isService;
  final BidStatus status;

  /// Who applied.
  final String provider;

  /// The listing they offer.
  final String offer;
  final num price;

  /// What the event asked for, as the host described it.
  final String? slot;
  final String? currency;
  final String? message;

  /// How many, for gear; null when it is one.
  final int? quantity;

  @override
  List<Object?> get props => [id, isService, status, provider, price];
}
