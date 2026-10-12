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
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String,
        distanceKm: (json['distanceKm'] as num).toDouble(),
        rating: (json['rating'] as num).toDouble(),
      );
}
