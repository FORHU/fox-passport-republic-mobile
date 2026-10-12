import 'package:flutter_template/features/worldMap/domain/entities/store_entity.dart';

/// Data-layer extension of [StoreEntity] that knows how to deserialize.
class StoreModel extends StoreEntity {
  const StoreModel({
    required super.id,
    required super.name,
    required super.address,
    required super.distanceKm,
    required super.rating,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) => StoreModel(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        address: (json['address'] ?? json['city'] ?? '').toString(),
        distanceKm:
            ((json['distanceKm'] ?? json['distance'] ?? 1.0) as num).toDouble(),
        rating:
            ((json['rating'] ?? json['avgRating'] ?? 5.0) as num).toDouble(),
      );
}
