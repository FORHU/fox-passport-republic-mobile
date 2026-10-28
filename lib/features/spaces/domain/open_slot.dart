import 'package:equatable/equatable.dart';

/// One thing an event still needs a service for.
class OpenSlot extends Equatable {
  const OpenSlot({
    required this.id,
    required this.price,
    required this.currency,
    this.description,
  });

  final String id;

  /// What the host set aside for it.
  final num price;
  final String currency;
  final String? description;

  @override
  List<Object?> get props => [id, price, currency, description];
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
    final rawSlots = template is Map ? template['templateServices'] : null;
    final slots = <OpenSlot>[
      if (rawSlots is List)
        for (final s in rawSlots)
          if (s is Map && s['id'] != null && s['matched'] != true)
            OpenSlot(
              id: '${s['id']}',
              description: text(s['description']),
              currency: text(s['currency']) ?? 'PHP',
              price: s['agreedPrice'] is num
                  ? s['agreedPrice'] as num
                  : num.tryParse('${s['agreedPrice']}') ?? 0,
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

  final String id;
  final String name;
  final List<OpenSlot> slots;
  final DateTime? startAt;
  final String? city;
  final String? host;

  @override
  List<Object?> get props => [id, name, slots, startAt];
}

/// What a service provider fills in to apply for one spot.
class ServiceBidDraft {
  const ServiceBidDraft({
    required this.eventId,
    required this.slotId,
    required this.serviceId,
    required this.price,
    this.message = '',
  });

  final String eventId;
  final String slotId;
  final String serviceId;
  final num price;
  final String message;

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'eventTemplateServiceId': slotId,
        'proposedServiceId': serviceId,
        'proposedPrice': price,
        if (message.trim().isNotEmpty) 'message': message.trim(),
      };
}
