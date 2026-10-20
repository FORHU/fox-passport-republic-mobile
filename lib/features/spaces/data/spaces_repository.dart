import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';

/// What the Venue and Event spaces read and do.
class SpacesRepository {
  SpacesRepository(this._api, this._userId);

  final ApiService _api;
  final String? _userId;

  /// Requests to confirm your venues in other people's events, those awaiting
  /// a reply first.
  Future<List<VenueRequest>> venueRequests() async {
    final body = await _api.get(ApiEndpoints.providerRequests);
    final rows = body is Map ? body['venues'] : null;
    if (rows is! List) {
      throw const FormatException('Requests response has no venues list');
    }
    final requests = [
      for (final row in rows)
        if (VenueRequest.tryParse(row) case final request?) request,
    ];
    // Stable: what needs a reply first, then the rest as the API gave them.
    return [
      ...requests.where((r) => r.needsReply),
      ...requests.where((r) => !r.needsReply),
    ];
  }

  /// Confirms or declines a request for your venue.
  Future<void> reviewVenueRequest(String id, {required bool accept}) async {
    await _api.patch(ApiEndpoints.requestReview(id), {
      'type': 'venue',
      'action': accept ? 'confirm' : 'reject',
    });
  }

  Future<List<SpaceListing>> myVenues() => _listings(
        ApiEndpoints.venues,
        query: {'hostId': _userId, 'limit': 50},
        keys: const ['venues', 'data'],
      );

  Future<List<SpaceListing>> myEvents() => _listings(
        ApiEndpoints.events,
        query: {'ownerId': _userId, 'limit': 50},
        keys: const ['templates', 'eventTemplates', 'data'],
        cityKey: 'targetCity',
      );

  Future<List<SpaceListing>> _listings(
    String path, {
    required Map<String, dynamic> query,
    required List<String> keys,
    String cityKey = 'city',
  }) async {
    if (_userId == null) return const [];
    final body = await _api.get(path, query: query);
    Object? rows;
    if (body is Map) {
      for (final key in keys) {
        if (body[key] is List) {
          rows = body[key];
          break;
        }
      }
    } else if (body is List) {
      rows = body;
    }
    if (rows is! List) {
      throw const FormatException('Listings response is not a list');
    }
    return [
      for (final row in rows)
        if (SpaceListing.tryParse(row, cityKey: cityKey) case final l?) l,
    ];
  }

  /// Checks a guest in by the code on their ticket.
  Future<CheckInResult> checkIn(String ticketCode) async {
    final body = await _api.patch(ApiEndpoints.bookingCheckIn, {
      'ticketCode': ticketCode.trim(),
    });
    return CheckInResult.fromJson(body);
  }
}

final spacesRepositoryProvider = Provider<SpacesRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return SpacesRepository(ref.watch(apiServiceProvider), userId);
});

final FutureProvider<List<VenueRequest>> venueRequestsProvider =
    FutureProvider.autoDispose<List<VenueRequest>>(
  (ref) => ref.watch(spacesRepositoryProvider).venueRequests(),
);

final FutureProvider<List<SpaceListing>> myVenuesProvider =
    FutureProvider.autoDispose<List<SpaceListing>>(
  (ref) => ref.watch(spacesRepositoryProvider).myVenues(),
);

final FutureProvider<List<SpaceListing>> myEventsProvider =
    FutureProvider.autoDispose<List<SpaceListing>>(
  (ref) => ref.watch(spacesRepositoryProvider).myEvents(),
);
