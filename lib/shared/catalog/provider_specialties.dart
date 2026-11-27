import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';

/// A main category of the catalog (api#503), such as Photo & Video. It is a
/// heading, never picked itself: its subcategories are.
class ProviderSpecialtyGroup extends Equatable {
  const ProviderSpecialtyGroup({
    required this.slug,
    required this.name,
    this.icon,
  });

  /// Null when [json] isn't a main category.
  static ProviderSpecialtyGroup? tryParse(Object? json) {
    if (json is! Map || json['slug'] == null) return null;
    final name = '${json['name'] ?? ''}'.trim();
    return ProviderSpecialtyGroup(
      slug: '${json['slug']}',
      name: name.isEmpty ? '${json['slug']}' : name,
      icon: json['icon'] is String ? json['icon'] as String : null,
    );
  }

  final String slug;
  final String name;

  /// A Material icon name, as the catalog stores it.
  final String? icon;

  @override
  List<Object?> get props => [slug, name, icon];
}

/// One thing a Provider can specialise in, named by the catalog.
class ProviderSpecialty extends Equatable {
  const ProviderSpecialty({
    required this.slug,
    required this.name,
    this.group,
    this.listingKind,
  });

  factory ProviderSpecialty.fromJson(Map<String, dynamic> json) =>
      ProviderSpecialty(
        slug: '${json['slug']}',
        name: (json['name'] as String?)?.trim().isNotEmpty ?? false
            ? (json['name'] as String).trim()
            : '${json['slug']}',
        group: ProviderSpecialtyGroup.tryParse(json['group']),
        listingKind: switch (json['listingKind']) {
          'asset' => 'asset',
          'service' => 'service',
          _ => null,
        },
      );

  /// What it is listed as: `asset` (gear) or `service` (api#506); null when no
  /// listing can carry it yet, or from an older API.
  final String? listingKind;

  /// What the API stores and filters by.
  final String slug;

  /// What people read.
  final String name;

  /// The main category it belongs to; null from an API before api#503, or
  /// for an older specialty that has none.
  final ProviderSpecialtyGroup? group;

  @override
  List<Object?> get props => [slug, name, group, listingKind];

  /// "Photo & Video · Photo booth", or just the name when it has no main
  /// category.
  String get fullName => group == null ? name : '${group!.name} · $name';
}

/// [list] split by main category, in the order the API gave, with the
/// specialties that have none last under a null group. Empty groups never
/// appear.
List<(ProviderSpecialtyGroup?, List<ProviderSpecialty>)> groupSpecialties(
  List<ProviderSpecialty> list,
) {
  final groups = <String, (ProviderSpecialtyGroup, List<ProviderSpecialty>)>{};
  final loose = <ProviderSpecialty>[];
  for (final s in list) {
    final g = s.group;
    if (g == null) {
      loose.add(s);
    } else {
      groups.putIfAbsent(g.slug, () => (g, <ProviderSpecialty>[])).$2.add(s);
    }
  }
  return [
    for (final e in groups.values) (e.$1, e.$2),
    if (loose.isNotEmpty) (null, loose),
  ];
}

/// Reads the specialties a Provider can pick: the one list the API checks an
/// application, a profile edit and a search against.
class ProviderSpecialtiesRepository {
  ProviderSpecialtiesRepository(this._api);

  final ApiService _api;

  Future<List<ProviderSpecialty>> list() async {
    final body = await _api.get(ApiEndpoints.providerSpecialties);
    final data = body is Map ? body['data'] : null;
    if (data is! List) {
      throw const FormatException('Specialties response is missing data');
    }
    return [
      for (final row in data)
        if (row is Map) ProviderSpecialty.fromJson(row.cast<String, dynamic>()),
    ];
  }

  /// Asks for a specialty the catalog lacks (api#440). It stays out of
  /// [list] until a reviewer approves it, so it is never picked or sent with
  /// an application.
  Future<void> suggest(String name) async {
    await _api.post(ApiEndpoints.providerSpecialtySuggestions, {'name': name});
  }
}

final providerSpecialtiesRepositoryProvider =
    Provider<ProviderSpecialtiesRepository>(
  (ref) => ProviderSpecialtiesRepository(ref.watch(apiServiceProvider)),
);

/// The catalog's Provider specialties; read again with `ref.invalidate`.
final providerSpecialtiesProvider = FutureProvider<List<ProviderSpecialty>>(
  (ref) => ref.watch(providerSpecialtiesRepositoryProvider).list(),
);
