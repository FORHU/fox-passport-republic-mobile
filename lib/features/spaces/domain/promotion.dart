import 'package:equatable/equatable.dart';

/// A discount a Foxer offers on one of their listings.
class Promotion extends Equatable {
  const Promotion({
    required this.id,
    required this.name,
    required this.isPercentage,
    required this.value,
    required this.active,
    required this.autoApply,
    this.venueId,
  });

  /// Reads one row of the Foxer's promotions; null when it has no id.
  static Promotion? tryParse(Object? row) {
    if (row is! Map || row['id'] == null) return null;
    final value = row['discountValue'];
    return Promotion(
      id: '${row['id']}',
      name: row['name'] is String ? row['name'] as String : '',
      isPercentage: row['discountType'] == 'percentage',
      value: value is num ? value : num.tryParse('$value') ?? 0,
      active: row['active'] != false,
      autoApply: row['autoApply'] == true,
      venueId: row['venueId'] is String ? row['venueId'] as String : null,
    );
  }

  final String id;
  final String name;

  /// A percentage off, else a fixed amount off.
  final bool isPercentage;
  final num value;
  final bool active;

  /// Applies at checkout without a code.
  final bool autoApply;

  /// The venue it is on; null for gear or a service.
  final String? venueId;

  @override
  List<Object?> get props => [id, name, isPercentage, value, active, autoApply];
}

/// What a Foxer fills in to offer a discount on one venue.
class PromotionDraft {
  const PromotionDraft({
    required this.venueId,
    required this.name,
    required this.isPercentage,
    required this.value,
    required this.autoApply,
  });

  final String venueId;
  final String name;
  final bool isPercentage;
  final num value;
  final bool autoApply;

  Map<String, dynamic> toJson() => {
        'venueId': venueId,
        'name': name.trim(),
        'discountType': isPercentage ? 'percentage' : 'fixed',
        'discountValue': value,
        'autoApply': autoApply,
      };
}
