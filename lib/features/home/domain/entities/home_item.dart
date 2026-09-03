import 'package:equatable/equatable.dart';

/// A single directory entry shown on the home feed.
class HomeItem extends Equatable {
  const HomeItem({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
