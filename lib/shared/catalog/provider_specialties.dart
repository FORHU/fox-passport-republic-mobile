import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';

/// One thing a Provider can specialise in, named by the catalog.
class ProviderSpecialty extends Equatable {
  const ProviderSpecialty({required this.slug, required this.name});

  factory ProviderSpecialty.fromJson(Map<String, dynamic> json) =>
      ProviderSpecialty(
        slug: '${json['slug']}',
        name: (json['name'] as String?)?.trim().isNotEmpty ?? false
            ? (json['name'] as String).trim()
            : '${json['slug']}',
      );

  /// What the API stores and filters by.
  final String slug;

  /// What people read.
  final String name;

  @override
  List<Object?> get props => [slug, name];
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
}

final providerSpecialtiesRepositoryProvider =
    Provider<ProviderSpecialtiesRepository>(
  (ref) => ProviderSpecialtiesRepository(ref.watch(apiServiceProvider)),
);

/// The catalog's Provider specialties; read again with `ref.invalidate`.
final providerSpecialtiesProvider = FutureProvider<List<ProviderSpecialty>>(
  (ref) => ref.watch(providerSpecialtiesRepositoryProvider).list(),
);
