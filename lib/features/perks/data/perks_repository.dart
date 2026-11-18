import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/perks/domain/perk.dart';

/// Reads the perks Tokens can buy and spends Tokens on one. The server owns
/// every number: the balance, what is in stock, which bookings qualify and the
/// code.
class PerksRepository {
  PerksRepository(this._api);

  final ApiService _api;

  Future<PerkListing> list() async =>
      PerkListing.fromJson(_map(await _api.get(ApiEndpoints.perks)));

  Future<PerkDetail> detail(String id) async =>
      PerkDetail.fromJson(_map(await _api.get(ApiEndpoints.perk(id))));

  /// Spends the Tokens on [perkId] for [bookingId]. Throws an `AppException`
  /// with the server's reason when it refuses (too few Tokens, sold out, not
  /// eligible).
  Future<PerkRedeemed> redeem(String perkId, String bookingId) async =>
      PerkRedeemed.fromJson(
        _map(
          await _api.post(
            ApiEndpoints.perkRedeem(perkId),
            {'bookingId': bookingId},
          ),
        ),
      );

  Future<List<MyPerk>> mine() async {
    final body = await _api.get(ApiEndpoints.perksMine);
    final data = body is Map ? body['data'] : null;
    if (data is! List) {
      throw const FormatException('Perks response is not a list');
    }
    return [
      for (final p in data)
        if (p is Map) MyPerk.fromJson(p.cast<String, dynamic>()),
    ];
  }

  Future<PerkCode> code(String redemptionId) async => PerkCode.fromJson(
        _map(await _api.get(ApiEndpoints.perkCode(redemptionId))),
      );

  Map<String, dynamic> _map(dynamic body) {
    final data = body is Map ? body['data'] : null;
    if (data is! Map) throw const FormatException('Response is missing data');
    return data.cast<String, dynamic>();
  }
}

final perksRepositoryProvider = Provider<PerksRepository>(
  (ref) => PerksRepository(ref.watch(apiServiceProvider)),
);

/// The perks on offer; read again with `ref.invalidate` after a redeem.
final FutureProvider<PerkListing> perksProvider =
    FutureProvider.autoDispose<PerkListing>((ref) {
  // Another account has its own balance.
  ref.watch(currentUserIdProvider);
  return ref.watch(perksRepositoryProvider).list();
});

/// One perk and the bookings it could be used on.
// The family type is long and adds nothing here, so it is left inferred.
// ignore: specify_nonobvious_property_types
final perkDetailProvider =
    FutureProvider.autoDispose.family<PerkDetail, String>(
  (ref, id) => ref.watch(perksRepositoryProvider).detail(id),
);

/// The person's perks: ready, used, expired.
final FutureProvider<List<MyPerk>> myPerksProvider =
    FutureProvider.autoDispose<List<MyPerk>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(perksRepositoryProvider).mine();
});
