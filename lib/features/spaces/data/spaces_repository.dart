import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/messages/data/photo_picker.dart';
import 'package:flutter_template/features/spaces/domain/partner_models.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/domain/venue_detail.dart';
import 'package:flutter_template/features/spaces/domain/venue_draft.dart';

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

  /// Totals and the latest payouts.
  Future<PayoutSummary> payouts({int limit = 10}) async {
    final body = await _api.get(
      ApiEndpoints.payoutsMe,
      query: {'limit': limit},
    );
    return PayoutSummary.fromJson(body);
  }

  Future<StripeStatus> stripeStatus() async {
    final body = await _api.get(ApiEndpoints.stripeStatus);
    return StripeStatus.fromJson(body);
  }

  /// Closes a day of a venue: nobody can book it until it is opened again.
  Future<void> blockDay(String venueId, DateTime day) async {
    await _api.post(ApiEndpoints.venueBlockedDates(venueId), {
      'date': _dateOnly(day),
    });
  }

  /// Opens a day that was closed.
  Future<void> unblockDay(String venueId, DateTime day) async {
    await _api.delete(ApiEndpoints.venueBlockedDate(venueId, _dateOnly(day)));
  }

  /// `YYYY-MM-DD` of a local calendar day, as the API takes it.
  static String _dateOnly(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  /// The venue as saved, to edit.
  Future<VenueDetail> venueDetail(String id) async {
    final body = await _api.get(ApiEndpoints.venueById(id));
    final detail = VenueDetail.tryParse(body);
    if (detail == null) throw const FormatException('Venue response is bad');
    return detail;
  }

  /// Saves a new venue and returns its id. [submit] sends it for review;
  /// otherwise it stays a draft.
  Future<String> createVenue(VenueDraft draft, {required bool submit}) async {
    final body = await _api.post(
      ApiEndpoints.venues,
      draft.toJson(status: submit ? 'pending' : 'draft'),
    );
    final venue = body is Map ? (body['venue'] ?? body['data']) : null;
    final id = venue is Map ? venue['id'] : null;
    if (id is! String) throw const FormatException('No id for the new venue');
    return id;
  }

  /// Saves changes. A live venue is sent without a status so it stays live.
  Future<void> updateVenue(
    String id,
    VenueDraft draft, {
    required bool live,
    required bool submit,
  }) async {
    final status = live ? null : (submit ? 'pending' : 'draft');
    await _api.put(ApiEndpoints.venueById(id), draft.toJson(status: status));
  }

  /// Uploads a photo and returns the id the venue needs, with its url.
  Future<VenuePhoto> uploadVenuePhoto(PickedPhoto photo) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(photo.bytes, filename: photo.name),
    });
    final body = await _api.post(ApiEndpoints.uploadFile, form);
    final fileId = body is Map ? body['fileId'] : null;
    final url =
        body is Map ? (body['url'] ?? (body['file'] as Map?)?['url']) : null;
    if (fileId is! String || url is! String) {
      throw const FormatException('The upload came back without a file id');
    }
    return VenuePhoto(fileId: fileId, url: url);
  }

  /// Other venues' service areas, so a new one can avoid them.
  Future<List<VenueBoundary>> neighbourBoundaries({String? excludeId}) async {
    final body = await _api.get(
      ApiEndpoints.venueBoundaries,
      query: {if (excludeId != null) 'excludeId': excludeId},
    );
    final rows = body is Map ? body['boundaries'] : null;
    if (rows is! List) return const [];
    return [
      for (final row in rows)
        if (VenueBoundary.tryParse(row) case final b?) b,
    ];
  }

  Future<List<PlaceOption>> countries() =>
      _places(ApiEndpoints.locationCountries);

  Future<List<PlaceOption>> states(String countryCode) =>
      _places(ApiEndpoints.locationStates(countryCode));

  /// The cities of a country, or of one of its states.
  Future<List<String>> cities(String countryCode, {String? stateCode}) async {
    final body = await _api.get(
      ApiEndpoints.locationCities(countryCode),
      query: stateCode == null ? null : {'state': stateCode},
    );
    final rows = body is Map ? body['data'] : body;
    if (rows is! List) return const [];
    return [
      for (final row in rows)
        if ('$row'.trim().isNotEmpty) '$row'.trim(),
    ];
  }

  Future<List<PlaceOption>> _places(String path) async {
    final body = await _api.get(path);
    final rows = body is Map ? body['data'] : body;
    if (rows is! List) return const [];
    return [
      for (final row in rows)
        if (PlaceOption.tryParse(row) case final p?) p,
    ];
  }

  Future<List<CancellationPolicyOption>> cancellationPolicies() async {
    final body = await _api.get(ApiEndpoints.cancellationPolicies);
    final rows = body is Map ? body['data'] : body;
    if (rows is! List) return const [];
    return [
      for (final row in rows)
        if (CancellationPolicyOption.tryParse(row) case final p?) p,
    ];
  }

  /// Every venue partnership the person is in, as a Mayor and as an Event
  /// Foxer.
  Future<PartnerLists> partners() async {
    final body = await _api.get(ApiEndpoints.venueAffiliationsMine);
    return PartnerLists.fromJson(body);
  }

  /// Approves an application (Mayor) or accepts an invitation (Event Foxer).
  Future<void> approvePartner(String id) async {
    await _api.patch(ApiEndpoints.venueAffiliationApprove(id));
  }

  /// Rejects an application or declines an invitation.
  Future<void> rejectPartner(String id, {String? reason}) async {
    await _api.patch(ApiEndpoints.venueAffiliationReject(id), {
      if (reason != null && reason.trim().isNotEmpty)
        'rejectionReason': reason.trim(),
    });
  }

  /// Takes back something the person started that is still waiting.
  Future<void> cancelPartner(String id) async {
    await _api.patch(ApiEndpoints.venueAffiliationCancel(id));
  }

  /// Ends an approved partnership. Only the Mayor can.
  Future<void> revokePartner(String id) async {
    await _api.delete(ApiEndpoints.venueAffiliation(id));
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

final FutureProvider<PayoutSummary> payoutsProvider =
    FutureProvider.autoDispose<PayoutSummary>(
  (ref) => ref.watch(spacesRepositoryProvider).payouts(),
);

final FutureProvider<StripeStatus> stripeStatusProvider =
    FutureProvider.autoDispose<StripeStatus>(
  (ref) => ref.watch(spacesRepositoryProvider).stripeStatus(),
);

final FutureProvider<PartnerLists> partnersProvider =
    FutureProvider.autoDispose<PartnerLists>(
  (ref) => ref.watch(spacesRepositoryProvider).partners(),
);
