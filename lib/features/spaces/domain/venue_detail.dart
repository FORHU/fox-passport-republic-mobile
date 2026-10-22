import 'package:flutter_template/features/spaces/domain/venue_draft.dart';

List<String> _strings(Object? raw) =>
    raw is List ? [for (final v in raw) v.toString()] : const [];

double? _number(Object? raw) =>
    raw is num ? raw.toDouble() : double.tryParse('$raw');

/// A neighbouring venue's service area, drawn so the host can avoid it.
class VenueBoundary {
  const VenueBoundary({
    required this.id,
    required this.name,
    required this.ring,
  });

  final String id;
  final String name;
  final List<List<double>> ring;

  static VenueBoundary? tryParse(Object? raw) {
    if (raw is! Map || raw['id'] is! String || raw['boundary'] is! List) {
      return null;
    }
    final ring = <List<double>>[];
    for (final p in raw['boundary'] as List) {
      if (p is List && p.length >= 2 && p[0] is num && p[1] is num) {
        ring.add([(p[0] as num).toDouble(), (p[1] as num).toDouble()]);
      }
    }
    if (ring.length < 4) return null;
    return VenueBoundary(
      id: raw['id'] as String,
      name: '${raw['name'] ?? ''}',
      ring: ring,
    );
  }
}

/// A cancellation policy the host can choose.
class CancellationPolicyOption {
  const CancellationPolicyOption({required this.id, required this.name});

  final String id;
  final String name;

  static CancellationPolicyOption? tryParse(Object? raw) {
    if (raw is! Map || raw['id'] is! String) return null;
    return CancellationPolicyOption(
      id: raw['id'] as String,
      name: '${raw['name'] ?? raw['title'] ?? 'Policy'}',
    );
  }
}

/// A venue read back from the API, to edit.
class VenueDetail {
  const VenueDetail({
    required this.id,
    required this.status,
    required this.draft,
  });

  final String id;
  final String status;
  final VenueDraft draft;

  /// A live venue is saved without a status; the others go back to draft or
  /// on to review.
  bool get isLive => status == 'available';

  static VenueDetail? tryParse(Object? body) {
    final raw = body is Map && body['venue'] is Map ? body['venue'] : body;
    if (raw is! Map || raw['id'] is! String) return null;

    final photos = <VenuePhoto>[];
    final images = raw['images'];
    if (images is List) {
      for (final image in images) {
        if (image is Map && image['id'] is String && image['url'] is String) {
          photos.add(
            VenuePhoto(
              fileId: image['id'] as String,
              url: image['url'] as String,
            ),
          );
        }
      }
    }

    final ring = <List<double>>[];
    if (raw['boundary'] is List) {
      for (final p in raw['boundary'] as List) {
        if (p is List && p.length >= 2) {
          ring.add([_number(p[0]) ?? 0, _number(p[1]) ?? 0]);
        }
      }
    }
    final circle = circleOf(ring);
    final lat = _number(raw['lat']);
    final lng = _number(raw['lng']);
    final center = circle?.center ??
        (lat != null && lng != null ? (lat: lat, lng: lng) : null);

    return VenueDetail(
      id: raw['id'] as String,
      status: '${raw['status'] ?? 'draft'}',
      draft: VenueDraft(
        name: '${raw['name'] ?? ''}',
        category: raw['category'] as String?,
        description: '${raw['description'] ?? ''}',
        capacity: (raw['capacity'] as num?)?.toInt(),
        address: '${raw['address'] ?? ''}',
        city: '${raw['city'] ?? ''}',
        state: '${raw['state'] ?? ''}',
        country: '${raw['country'] ?? ''}',
        center: center,
        radiusMeters: circle?.radiusMeters ?? 300,
        photos: photos,
        spaceType: _strings(raw['spaceType']),
        amenities: _strings(raw['amenities']),
        techAv: _strings(raw['techAv']),
        staffing: _strings(raw['staffing']),
        policies: _strings(raw['policies']),
        price: _number(raw['price']),
        billingRate: '${raw['billingRate'] ?? 'daily'}',
        extraGuestRate: _number(raw['extraGuestRate']),
        cancellationPolicyId: raw['cancellationPolicyId'] as String?,
      ),
    );
  }
}

/// A country or state in a dropdown: the code the API looks places up by, and
/// the name the venue stores.
class PlaceOption {
  const PlaceOption({required this.code, required this.name});

  final String code;
  final String name;

  static PlaceOption? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final name = '${raw['name'] ?? ''}'.trim();
    if (name.isEmpty) return null;
    return PlaceOption(code: '${raw['code'] ?? ''}', name: name);
  }
}
