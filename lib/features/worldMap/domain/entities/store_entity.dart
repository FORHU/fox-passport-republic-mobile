import 'package:equatable/equatable.dart';

/// A single nearby place shown on the world map / list view.
class StoreEntity extends Equatable {
  const StoreEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.distanceKm,
    required this.rating,
  });

  final String id;
  final String name;
  final String address;
  final double distanceKm;
  final double rating;

  @override
  List<Object?> get props => [id, name, address, distanceKm, rating];
}
