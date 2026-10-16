import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/theme/tokens/occasion_colors.dart';

/// The five things people plan for. They are built into the app so Home can
/// draw them at once, before (or without) `GET /categories` answering.
enum Occasion {
  birthday,
  wedding,
  corporate,
  social,
  other;

  /// The occasion with this API name, or null for one the app does not know.
  static Occasion? fromName(String? name) {
    for (final o in values) {
      if (o.name == name) return o;
    }
    return null;
  }

  OccasionStyle get style => switch (this) {
        Occasion.wedding => OccasionColors.wedding,
        Occasion.birthday => OccasionColors.birthday,
        Occasion.corporate => OccasionColors.corporate,
        Occasion.social => OccasionColors.social,
        Occasion.other => OccasionColors.other,
      };

  IconData get icon => switch (this) {
        Occasion.wedding => Icons.favorite_border_rounded,
        Occasion.birthday => Icons.cake_outlined,
        Occasion.corporate => Icons.work_outline_rounded,
        Occasion.social => Icons.celebration_outlined,
        Occasion.other => Icons.auto_awesome_outlined,
      };
}

/// One row of `GET /categories`: a category and how much of it is bookable.
class CategorySummary extends Equatable {
  const CategorySummary({
    required this.name,
    required this.count,
    required this.isEventCategory,
    this.venues = 0,
    this.services = 0,
    this.assets = 0,
    this.events = 0,
  });

  static CategorySummary? tryParse(Map<String, dynamic> row) {
    final name = '${row['name'] ?? ''}'.trim();
    if (name.isEmpty) return null;
    final sources = row['sources'];
    int n(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    final map = sources is Map ? sources : const <String, dynamic>{};
    return CategorySummary(
      name: name,
      count: n(row['count']),
      isEventCategory: row['isEventCategory'] == true,
      venues: n(map['venues']),
      services: n(map['services']),
      assets: n(map['assets']),
      events: n(map['events']),
    );
  }

  final String name;
  final int count;
  final bool isEventCategory;
  final int venues;
  final int services;
  final int assets;
  final int events;

  @override
  List<Object?> get props =>
      [name, count, isEventCategory, venues, services, assets, events];
}

/// Every category with live counts. The call is public, so it works signed
/// out too. Home reads it for the occasion counts and the single-booking row.
final FutureProvider<List<CategorySummary>> categoriesProvider =
    FutureProvider.autoDispose<List<CategorySummary>>((ref) async {
  final body = await ref.watch(apiServiceProvider).get(ApiEndpoints.categories);
  final data = body is Map ? body['data'] : null;
  if (data is! List) return const [];
  return [
    for (final row in data)
      if (row is Map)
        if (CategorySummary.tryParse(row.cast<String, dynamic>())
            case final category?)
          category,
  ];
});
