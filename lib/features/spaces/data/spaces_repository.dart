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

  /// Every venue the person runs. The API gives at most 100 at a time, so this
  /// asks page by page until it has them all.
  Future<List<SpaceListing>> myVenues() async {
    if (_userId == null) return const [];
    const pageSize = 100;
    const maxPages = 20;
    final all = <SpaceListing>[];
    for (var page = 1; page <= maxPages; page++) {
      final body = await _api.get(
        ApiEndpoints.venues,
        query: {'hostId': _userId, 'limit': pageSize, 'page': page},
      );
      final rows = body is Map ? body['venues'] ?? body['data'] : body;
      if (rows is! List) {
        throw const FormatException('Listings response is not a list');
      }
      all.addAll([
        for (final row in rows)
          if (SpaceListing.tryParse(row) case final l?) l,
      ]);
      final total = body is Map ? body['total'] : null;
      // Done when a page comes up short, or the API says there are no more.
      if (rows.length < pageSize || (total is int && all.length >= total)) {
        break;
      }
    }
    return all;
  }

  /// Every event the person runs. The API gives at most 50 at a time, so this
  /// asks page by page until it has them all.
  Future<List<SpaceListing>> myEvents() async {
    if (_userId == null) return const [];
    const pageSize = 50;
    const maxPages = 40;
    final all = <SpaceListing>[];
    for (var page = 1; page <= maxPages; page++) {
      final body = await _api.get(
        ApiEndpoints.events,
        query: {'ownerId': _userId, 'limit': pageSize, 'page': page},
      );
      Object? rows;
      if (body is Map) {
        for (final key in const ['templates', 'eventTemplates', 'data']) {
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
      all.addAll([
        for (final row in rows)
          if (SpaceListing.tryParse(row, cityKey: 'targetCity') case final l?)
            l,
      ]);
      final total = body is Map ? body['total'] : null;
      // Done when a page comes up short, or the API says there are no more.
      if (rows.length < pageSize || (total is int && all.length >= total)) {
        break;
      }
    }
    return all;
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
      ApiEndpoints.venueCreate,
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

  /// An Event Foxer asks to run events at a venue. Its Mayor decides.
  Future<void> applyToVenue(String venueId) async {
    await _api.post(ApiEndpoints.venueAffiliationApply, {'venueId': venueId});
  }

  /// A Mayor asks an Event Foxer to host events at one of their venues. The
  /// Event Foxer decides.
  Future<void> inviteEventFoxer(String venueId, String eventFoxerId) async {
    await _api.post(ApiEndpoints.venueAffiliationInvite, {
      'venueId': venueId,
      'eventFoxerId': eventFoxerId,
    });
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

/// How many partnerships on one side wait for the person's answer, for badges.
// The family type is not exported by flutter_riverpod, so it is inferred.
// ignore: specify_nonobvious_property_types
final partnersWaitingProvider =
    Provider.autoDispose.family<int, PartnerSide>((ref, side) {
  final lists = ref.watch(partnersProvider).asData?.value;
  if (lists == null) return 0;
  return lists.forSide(side).where((p) => p.awaitingMe).length;
});
