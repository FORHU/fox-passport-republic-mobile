import 'package:equatable/equatable.dart';

/// One thing an event still needs: a service, or gear.
class OpenSlot extends Equatable {
  const OpenSlot({
    required this.id,
    required this.price,
    required this.currency,
    this.description,
    this.isGear = false,
    this.quantity = 1,
  });

  final String id;

  /// What the host set aside for it.
  final num price;
  final String currency;
  final String? description;

  /// True when it asks for gear rather than a service.
  final bool isGear;

  /// How many of the gear are wanted.
  final int quantity;

  @override
  List<Object?> get props =>
      [id, price, currency, description, isGear, quantity];
}

/// An event that is looking for services, with the spots still open.
class OpenSlotEvent extends Equatable {
  const OpenSlotEvent({
    required this.id,
    required this.name,
    required this.slots,
    this.startAt,
    this.city,
    this.host,
  });

  /// Reads one event of the open-slots list. Spots that are already filled
  /// are left out; null when the event has none open or no id.
  static OpenSlotEvent? tryParse(Object? row) {
    if (row is! Map || row['id'] == null) return null;
    String? text(Object? v) => v is String && v.trim().isNotEmpty ? v : null;
    final template = row['template'];
    final slots = <OpenSlot>[
      ..._slots(template is Map ? template['templateServices'] : null),
      ..._slots(
        template is Map ? template['templateAssets'] : null,
        isGear: true,
      ),
    ];
    if (slots.isEmpty) return null;
    final host = row['host'];
    return OpenSlotEvent(
      id: '${row['id']}',
      name: text(row['name']) ?? '',
      city: text(row['targetCity']),
      host: host is Map ? text(host['name']) : null,
      startAt: DateTime.tryParse('${row['startAt']}'),
      slots: slots,
    );
  }

  static List<OpenSlot> _slots(Object? rows, {bool isGear = false}) {
    String? text(Object? v) => v is String && v.trim().isNotEmpty ? v : null;
    return [
      if (rows is List)
        for (final s in rows)
          if (s is Map && s['id'] != null && s['matched'] != true)
            OpenSlot(
              id: '${s['id']}',
              description: text(s['description']),
              currency: text(s['currency']) ?? 'PHP',
              price: s['agreedPrice'] is num
                  ? s['agreedPrice'] as num
                  : num.tryParse('${s['agreedPrice']}') ?? 0,
              isGear: isGear,
              quantity: s['quantity'] is int ? s['quantity'] as int : 1,
            ),
    ];
  }

  final String id;
  final String name;
  final List<OpenSlot> slots;
  final DateTime? startAt;
  final String? city;
  final String? host;

  @override
  List<Object?> get props => [id, name, slots, startAt];
}

/// What a provider fills in to apply for one spot, with a service or gear.
class BidDraft {
  const BidDraft({
    required this.eventId,
    required this.slotId,
    required this.listingId,
    required this.price,
    this.isGear = false,
    this.message = '',
  });

  final String eventId;
  final String slotId;

  /// The service or the gear being offered.
  final String listingId;
  final bool isGear;
  final num price;
  final String message;

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        if (isGear) ...{
          'eventTemplateAssetId': slotId,
          'proposedAssetId': listingId,
        } else ...{
          'eventTemplateServiceId': slotId,
          'proposedServiceId': listingId,
        },
        'proposedPrice': price,
        if (message.trim().isNotEmpty) 'message': message.trim(),
      };
}
