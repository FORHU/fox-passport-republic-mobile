import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/messages/data/photo_picker.dart';
import 'package:flutter_template/features/spaces/domain/event_detail.dart';
import 'package:flutter_template/features/spaces/domain/event_draft.dart';
import 'package:flutter_template/features/spaces/domain/partner_models.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/domain/team_models.dart';
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

  /// Requests to confirm your gear and services in other people's events,
  /// those awaiting a reply first.
  Future<List<VenueRequest>> supplyRequests() async {
    final body = await _api.get(ApiEndpoints.providerRequests);
    if (body is! Map) {
      throw const FormatException('Requests response is not a map');
    }
    final requests = <VenueRequest>[];
    for (final kind in const [RequestKind.asset, RequestKind.service]) {
      final rows = body['${kind.name}s'];
      if (rows is! List) {
        throw FormatException('Requests response has no ${kind.name}s list');
      }
      for (final row in rows) {
        if (VenueRequest.tryParse(row, kind: kind) case final request?) {
          requests.add(request);
        }
      }
    }
    return [
      ...requests.where((r) => r.needsReply),
      ...requests.where((r) => !r.needsReply),
    ];
  }

  /// Confirms or declines a request for your venue, gear or service.
  Future<void> reviewVenueRequest(
    String id, {
    required bool accept,
    RequestKind kind = RequestKind.venue,
  }) async {
    await _api.patch(ApiEndpoints.requestReview(id), {
      'type': kind.name,
      'action': accept ? 'confirm' : 'reject',
    });
  }

  /// The gear the person lists. The API gives at most 50 at a time, so this
  /// asks page by page.
  Future<List<SpaceListing>> myAssets() =>
      _owned(ApiEndpoints.assets, 'assets');

  /// The services (and performances) the person lists.
  Future<List<SpaceListing>> myServices() =>
      _owned(ApiEndpoints.services, 'services');

  Future<List<SpaceListing>> _owned(String path, String key) async {
    if (_userId == null) return const [];
    const pageSize = 50;
    const maxPages = 40;
    final all = <SpaceListing>[];
    for (var page = 1; page <= maxPages; page++) {
      final body = await _api.get(
        path,
        query: {'ownerId': _userId, 'limit': pageSize, 'page': page},
      );
      final rows = body is Map ? body[key] ?? body['data'] : body;
      if (rows is! List) {
        throw const FormatException('Listings response is not a list');
      }
      all.addAll([
        for (final row in rows)
          if (SpaceListing.tryParse(row) case final l?) l,
      ]);
      final total = body is Map ? body['total'] : null;
      if (rows.length < pageSize || (total is int && all.length >= total)) {
        break;
      }
    }
    return all;
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

  // ── Team: Organizers and Check-in Helpers ──────────────────────────────

  String _teamPath(TeamTarget target) => target.isEvent
      ? ApiEndpoints.eventTeam(target.id)
      : ApiEndpoints.venueTeam(target.id);

  /// The venues the person can build a team for.
  Future<List<TeamTarget>> teamVenues() async => [
        for (final v in await myVenues())
          TeamTarget(
            isEvent: false,
            id: v.id,
            name: v.name,
            detail: [v.city, v.status].whereType<String>().join(' · '),
          ),
      ];

  /// The events the person organizes that can still take a team. The API gives
  /// at most 50 at a time, so this asks page by page.
  Future<List<TeamTarget>> teamEvents() async {
    if (_userId == null) return const [];
    const pageSize = 50;
    const maxPages = 40;
    final all = <TeamTarget>[];
    for (var page = 1; page <= maxPages; page++) {
      final body = await _api.get(
        ApiEndpoints.organizerEvents,
        query: {'organizerId': _userId, 'limit': pageSize, 'page': page},
      );
      final rows = body is Map ? body['events'] ?? body['data'] : body;
      if (rows is! List) {
        throw const FormatException('Events response is not a list');
      }
      all.addAll([
        for (final row in rows)
          if (teamTargetFromEvent(row) case final t?) t,
      ]);
      final total = body is Map ? body['total'] : null;
      if (rows.length < pageSize ||
          (total is int && page * pageSize >= total)) {
        break;
      }
    }
    return all;
  }

  /// Everyone on the venue's or event's team, invited, asking, or past.
  Future<List<TeamMember>> team(TeamTarget target) async {
    final body = await _api.get(_teamPath(target));
    final rows = body is Map ? body['data'] : body;
    if (rows is! List) {
      throw const FormatException('Team response is not a list');
    }
    return [
      for (final row in rows)
        if (TeamMember.tryParse(row) case final m?) m,
    ];
  }

  /// Invites an Organizer (by email, or someone picked from the search), or
  /// adds a Check-in Helper by email. The API says why when it refuses.
  Future<void> appoint(
    TeamTarget target,
    TeamKind kind, {
    String? email,
    String? userId,
  }) async {
    await _api.post(_teamPath(target), {
      'kind': kind.api,
      if (userId != null) 'userId': userId else 'email': email?.trim(),
    });
  }

  /// Removes someone from the team, or withdraws an invitation.
  Future<void> removeFromTeam(TeamTarget target, String appointmentId) async {
    await _api
        .delete('${_teamPath(target)}/${Uri.encodeComponent(appointmentId)}');
  }

  /// Answers an Organizer's request to join.
  Future<void> answerTeamRequest(
    TeamTarget target,
    String appointmentId, {
    required bool accept,
  }) async {
    final id = Uri.encodeComponent(appointmentId);
    await _api.post(
      '${_teamPath(target)}/$id/${accept ? 'approve' : 'decline'}-request',
    );
  }

  /// Whether Organizers may ask to join this venue or event.
  Future<bool> acceptsOrganizerRequests(TeamTarget target) async {
    final body = await _api.get('${_teamPath(target)}/settings');
    final data = body is Map ? body['data'] : null;
    return data is Map && data['acceptsOrganizerRequests'] == true;
  }

  Future<void> setAcceptsOrganizerRequests(
    TeamTarget target, {
    required bool value,
  }) async {
    await _api.patch('${_teamPath(target)}/settings', {
      'acceptsOrganizerRequests': value,
    });
  }

  /// Approved Organizers matching a name or city.
  Future<List<OrganizerCard>> searchOrganizers(String query) async {
    final body = await _api.get(
      ApiEndpoints.organizerSearch,
      query: {'q': query.trim()},
    );
    final rows = body is Map ? body['data'] : body;
    if (rows is! List) return const [];
    return [
      for (final row in rows)
        if (OrganizerCard.tryParse(row) case final c?) c,
    ];
  }

  /// The event as saved, to edit.
  Future<EventDetail> eventDetail(String id) async {
    final body = await _api.get(ApiEndpoints.eventById(id));
    final detail = EventDetail.tryParse(body);
    if (detail == null) throw const FormatException('Event response is bad');
    return detail;
  }

  /// Saves a new event as a draft and returns its id.
  Future<String> createEvent(EventDraft draft) async {
    final body = await _api.post(
      ApiEndpoints.events,
      draft.toJson(forCreate: true),
    );
    final created =
        body is Map ? (body['template'] ?? body['data'] ?? body) : null;
    final id = created is Map ? created['id'] : null;
    if (id is! String) throw const FormatException('No id for the new event');
    return id;
  }

  /// Saves changes to an event. Its status does not change.
  Future<void> updateEvent(String id, EventDraft draft) async {
    await _api.put(ApiEndpoints.eventById(id), draft.toJson());
  }

  /// Sends a draft for review. The API only allows it for a draft.
  Future<void> submitEvent(String id) async {
    await _api.post(ApiEndpoints.eventSubmit(id));
  }

  /// Makes the saved event's package match [items]: what was taken out is
  /// removed, what is new is attached, and what the host changed the price or
  /// optional flag of (compared with [before]) is attached again. Each attach
  /// is checked by the API (a venue needs an approved affiliation and a
  /// matching place), so a refusal is reported, not hidden.
  Future<List<PackageProblem>> syncEventPackage(
    String id,
    List<PackageItem> items, {
    List<PackageItem> before = const [],
  }) async {
    final problems = <PackageProblem>[];
    final current = await _api.get(ApiEndpoints.eventById(id));
    final template = current is Map
        ? (current['template'] is Map ? current['template'] : current) as Map
        : const <String, Object?>{};

    Set<String> ids(String key, String idKey) => {
          if (template[key] is List)
            for (final row in template[key] as List)
              if (row is Map && row[idKey] != null) '${row[idKey]}',
        };

    bool changed(PackageItem item) {
      final was = before.where((b) => b.id == item.id).firstOrNull;
      return was != null &&
          (was.price != item.price || was.isOptional != item.isOptional);
    }

    Future<void> run(PackageItem item, Future<void> Function() call) async {
      try {
        await call();
      } on AppException catch (e) {
        problems.add(PackageProblem(item.name, e.message));
      } on Object {
        problems.add(PackageProblem(item.name, ''));
      }
    }

    // The venue: only one, and it replaces any other.
    final venue = items.where((i) => i.isVenue).firstOrNull;
    final venueIds = ids('templateVenues', 'venueId');
    for (final old in venueIds) {
      if (old != venue?.id || changed(venue!)) {
        await _api.delete(ApiEndpoints.eventVenue(id, old));
      }
    }
    if (venue != null && (!venueIds.contains(venue.id) || changed(venue))) {
      await run(
        venue,
        () => _api.post(ApiEndpoints.eventVenues(id), {
          'venueId': venue.id,
          'agreedPrice': venue.price,
          'isOptional': venue.isOptional,
        }),
      );
    }

    // Assets, then services: remove what left, attach what is new or changed.
    final assets = [
      for (final i in items)
        if (!i.isVenue && !i.isService) i,
    ];
    final assetIds = ids('templateAssets', 'assetId');
    for (final old in assetIds) {
      final kept = assets.where((a) => a.id == old).firstOrNull;
      if (kept == null || changed(kept)) {
        await _api.delete(ApiEndpoints.eventAsset(id, old));
      }
    }
    for (final asset in assets) {
      if (!assetIds.contains(asset.id) || changed(asset)) {
        await run(
          asset,
          () => _api.post(ApiEndpoints.eventAssets(id), {
            'assetId': asset.id,
            'quantity': 1,
            'agreedPrice': asset.price,
            'isOptional': asset.isOptional,
          }),
        );
      }
    }

    final services = [
      for (final i in items)
        if (i.isService) i,
    ];
    final serviceIds = ids('templateServices', 'serviceId');
    for (final old in serviceIds) {
      final kept = services.where((s) => s.id == old).firstOrNull;
      if (kept == null || changed(kept)) {
        await _api.delete(ApiEndpoints.eventService(id, old));
      }
    }
    for (final service in services) {
      if (!serviceIds.contains(service.id) || changed(service)) {
        await run(
          service,
          () => _api.post(ApiEndpoints.eventServices(id), {
            'serviceId': service.id,
            'agreedPrice': service.price,
            'isOptional': service.isOptional,
          }),
        );
      }
    }
    return problems;
  }

  /// Live venues to put in an event, searched by name or town. Their access
  /// for the host is worked out by the caller.
  Future<({List<PackageItem> items, int total})> venueChoices({
    String query = '',
    int page = 1,
  }) async {
    final body = await _api.get(
      ApiEndpoints.venues,
      query: {
        'limit': 50,
        'page': page,
        if (query.trim().isNotEmpty) 'search': query.trim(),
      },
    );
    final rows = body is Map ? (body['venues'] ?? body['data']) : body;
    final items = <PackageItem>[
      if (rows is List)
        for (final row in rows)
          // Only a live venue can be offered.
          if (row is Map && row['status'] == 'available')
            if (packageItemFromVenue(row, access: VenueAccess.none)
                case final v?)
              v,
    ];
    final total = body is Map && body['total'] is int
        ? body['total'] as int
        : items.length;
    return (items: items, total: total);
  }

  /// Assets to put in an event (talent, equipment, and some services).
  Future<({List<PackageItem> items, int total})> assetChoices({
    int page = 1,
  }) =>
      _supplies(ApiEndpoints.assets, 'assets', page, packageItemFromAsset);

  /// Services to put in an event (performers and other services).
  Future<({List<PackageItem> items, int total})> serviceChoices({
    int page = 1,
  }) =>
      _supplies(
        ApiEndpoints.services,
        'services',
        page,
        packageItemFromService,
      );

  Future<({List<PackageItem> items, int total})> _supplies(
    String path,
    String key,
    int page,
    PackageItem? Function(Object? row) parse,
  ) async {
    final body = await _api.get(path, query: {'limit': 50, 'page': page});
    final rows = body is Map ? (body[key] ?? body['data']) : body;
    final items = <PackageItem>[
      if (rows is List)
        for (final row in rows)
          if (parse(row) case final item?) item,
    ];
    final total = body is Map && body['total'] is int
        ? body['total'] as int
        : items.length;
    return (items: items, total: total);
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

final FutureProvider<List<VenueRequest>> supplyRequestsProvider =
    FutureProvider.autoDispose<List<VenueRequest>>(
  (ref) => ref.watch(spacesRepositoryProvider).supplyRequests(),
);

final FutureProvider<List<SpaceListing>> myAssetsProvider =
    FutureProvider.autoDispose<List<SpaceListing>>(
  (ref) => ref.watch(spacesRepositoryProvider).myAssets(),
);

final FutureProvider<List<SpaceListing>> myServicesProvider =
    FutureProvider.autoDispose<List<SpaceListing>>(
  (ref) => ref.watch(spacesRepositoryProvider).myServices(),
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

final FutureProvider<List<TeamTarget>> teamVenuesProvider =
    FutureProvider.autoDispose<List<TeamTarget>>(
  (ref) => ref.watch(spacesRepositoryProvider).teamVenues(),
);

final FutureProvider<List<TeamTarget>> teamEventsProvider =
    FutureProvider.autoDispose<List<TeamTarget>>(
  (ref) => ref.watch(spacesRepositoryProvider).teamEvents(),
);

// The family types are not exported by flutter_riverpod, so they are inferred.
// ignore: specify_nonobvious_property_types
final teamProvider =
    FutureProvider.autoDispose.family<List<TeamMember>, TeamTarget>(
  (ref, target) => ref.watch(spacesRepositoryProvider).team(target),
);

// Same as above: the family type is inferred.
// ignore: specify_nonobvious_property_types
final teamAcceptsRequestsProvider =
    FutureProvider.autoDispose.family<bool, TeamTarget>(
  (ref, target) =>
      ref.watch(spacesRepositoryProvider).acceptsOrganizerRequests(target),
);

// Same as above: the family type is inferred.
// ignore: specify_nonobvious_property_types
final organizerSearchProvider =
    FutureProvider.autoDispose.family<List<OrganizerCard>, String>(
  (ref, query) => ref.watch(spacesRepositoryProvider).searchOrganizers(query),
);
