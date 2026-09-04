import 'package:flutter_template/features/home/domain/entities/home_item.dart';

/// Data-layer extension of [HomeItem] that knows how to deserialize.
class HomeItemModel extends HomeItem {
  const HomeItemModel({required super.id, required super.name});

  factory HomeItemModel.fromJson(Map<String, dynamic> json) => HomeItemModel(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}
