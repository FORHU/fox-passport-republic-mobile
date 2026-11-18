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

  /// The perks of one event package, for someone booked on it.
  Future<PerkListing> forPackage(String templateId) async =>
      PerkListing.fromJson(
        _map(
          await _api.get(
            ApiEndpoints.perks,
            query: {'templateId': templateId},
          ),
        ),
      );

  /// The perks the person offers, with how many were bought.
  Future<List<OfferedPerk>> offered() async {
    final body = await _api.get(ApiEndpoints.perksOffered);
    final data = body is Map ? body['data'] : null;
    if (data is! List) {
      throw const FormatException('Perks response is not a list');
    }
    return [
      for (final p in data)
        if (p is Map) OfferedPerk.fromJson(p.cast<String, dynamic>()),
    ];
  }

  /// Offers a perk on an event package or a venue the person owns. The server
  /// sets the Token price from [worthPhp]. Throws an `AppException` with the
  /// server's reason when it refuses.
  Future<Perk> create({
    required PerkTarget target,
    required String title,
    required String description,
    required num worthPhp,
    required int quantity,
  }) async =>
      Perk.fromJson(
        _map(
          await _api.post(ApiEndpoints.perks, {
            if (target.isVenue)
              'venueId': target.id
            else
              'templateId': target.id,
            'title': title,
            if (description.isNotEmpty) 'description': description,
            'worthPhp': worthPhp,
            'quantity': quantity,
          }),
        ),
      );

  /// Stops an offer; everyone still holding it unused gets their Tokens back.
  Future<void> takeDown(String perkId) async {
    await _api.post(ApiEndpoints.perkTakeDown(perkId), {});
  }

  /// Staff check a scanned or typed perk code. Throws an `AppException` with
  /// the server's reason (no such code, an old code, not staff for it).
  Future<PerkCheck> check(String raw) async => PerkCheck.fromJson(
        _map(
          await _api.post(ApiEndpoints.perksCheck, {
            // A scanned code has dots (it is signed); a typed one does not.
            if (raw.contains('.')) 'live': raw else 'code': raw,
          }),
        ),
      );

  /// Staff mark a checked perk used, once.
  Future<void> markUsed(String redemptionId) async {
    await _api.post(ApiEndpoints.perkUse(redemptionId), {});
  }

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

/// The perks of one event package.
// The family type is long and adds nothing here, so it is left inferred.
// ignore: specify_nonobvious_property_types
final packagePerksProvider =
    FutureProvider.autoDispose.family<PerkListing, String>(
  (ref, templateId) =>
      ref.watch(perksRepositoryProvider).forPackage(templateId),
);

/// The perks the person offers.
final FutureProvider<List<OfferedPerk>> offeredPerksProvider =
    FutureProvider.autoDispose<List<OfferedPerk>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(perksRepositoryProvider).offered();
});

/// The person's perks: ready, used, expired.
final FutureProvider<List<MyPerk>> myPerksProvider =
    FutureProvider.autoDispose<List<MyPerk>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(perksRepositoryProvider).mine();
});
