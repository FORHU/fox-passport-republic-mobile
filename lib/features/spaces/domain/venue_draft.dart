import 'dart:math' as math;

/// The categories the API accepts for a venue.
const venueCategories = [
  'indoor',
  'outdoor',
  'hotel',
  'beach_resort',
  'garden',
  'mix',
  'other',
];

/// How a venue's price is counted.
const billingRates = [
  'hourly',
  'daily',
  'weekly',
  'monthly',
  'yearly',
  'one_time',
];

/// A point on the map.
typedef GeoPoint = ({double lat, double lng});

/// The service area as a ring of `[lng, lat]` points, which is the order the
/// API stores. A circle around [center] with [radiusMeters], closed by
/// repeating the first point.
List<List<double>> circlePolygon(
  GeoPoint center,
  double radiusMeters, {
  int points = 24,
}) {
  const earth = 6371000.0;
  final lat = center.lat * math.pi / 180;
  final angular = radiusMeters / earth;
  final ring = <List<double>>[];
  for (var i = 0; i < points; i++) {
    final bearing = 2 * math.pi * i / points;
    final pointLat = math.asin(
      math.sin(lat) * math.cos(angular) +
          math.cos(lat) * math.sin(angular) * math.cos(bearing),
    );
    final pointLng = center.lng * math.pi / 180 +
        math.atan2(
          math.sin(bearing) * math.sin(angular) * math.cos(lat),
          math.cos(angular) - math.sin(lat) * math.sin(pointLat),
        );
    ring.add([pointLng * 180 / math.pi, pointLat * 180 / math.pi]);
  }
  return [...ring, List<double>.of(ring.first)];
}

/// The centre and radius of a ring made by [circlePolygon], or null when the
/// venue's area is some other shape drawn on the web.
({GeoPoint center, double radiusMeters})? circleOf(List<List<double>> ring) {
  // A drawn shape with a few corners can be equidistant from its middle too;
  // ours always has many points.
  if (ring.length < 13) return null;
  final points = ring.sublist(0, ring.length - 1);
  final lat = points.map((p) => p[1]).reduce((a, b) => a + b) / points.length;
  final lng = points.map((p) => p[0]).reduce((a, b) => a + b) / points.length;
  final radii = [for (final p in points) _meters(lat, lng, p[1], p[0])];
  final mean = radii.reduce((a, b) => a + b) / radii.length;
  final isCircle = radii.every((r) => (r - mean).abs() <= mean * 0.02);
  if (!isCircle) return null;
  return (center: (lat: lat, lng: lng), radiusMeters: mean);
}

double _meters(double lat1, double lng1, double lat2, double lng2) {
  const earth = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.pow(math.sin(dLat / 2), 2).toDouble() +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * earth * math.asin(math.sqrt(a));
}

/// Whether two rings overlap, by ray-casting each one's points into the other
/// and by testing their edges for a crossing. Good enough for the warning the
/// host sees; the API makes the final call and answers 409.
bool ringsOverlap(List<List<double>> a, List<List<double>> b) {
  bool inside(List<double> p, List<List<double>> ring) {
    var result = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final xi = ring[i][0];
      final yi = ring[i][1];
      final xj = ring[j][0];
      final yj = ring[j][1];
      if ((yi > p[1]) != (yj > p[1]) &&
          p[0] < (xj - xi) * (p[1] - yi) / (yj - yi) + xi) {
        result = !result;
      }
    }
    return result;
  }

  if (a.any((p) => inside(p, b)) || b.any((p) => inside(p, a))) return true;
  for (var i = 0; i < a.length - 1; i++) {
    for (var j = 0; j < b.length - 1; j++) {
      if (_cross(a[i], a[i + 1], b[j], b[j + 1])) return true;
    }
  }
  return false;
}

bool _cross(
  List<double> p1,
  List<double> p2,
  List<double> p3,
  List<double> p4,
) {
  double side(List<double> a, List<double> b, List<double> c) =>
      (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]);
  final d1 = side(p3, p4, p1);
  final d2 = side(p3, p4, p2);
  final d3 = side(p1, p2, p3);
  final d4 = side(p1, p2, p4);
  return (d1 > 0) != (d2 > 0) && (d3 > 0) != (d4 > 0);
}

/// A photo already uploaded: the id the API wants, and the url to show.
class VenuePhoto {
  const VenuePhoto({required this.fileId, required this.url});

  final String fileId;
  final String url;
}

/// What a host fills in while creating or editing a venue.
class VenueDraft {
  const VenueDraft({
    this.name = '',
    this.category,
    this.description = '',
    this.capacity,
    this.address = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.center,
    this.radiusMeters = 300,
    this.photos = const [],
    this.spaceType = const [],
    this.amenities = const [],
    this.techAv = const [],
    this.staffing = const [],
    this.policies = const [],
    this.price,
    this.billingRate = 'daily',
    this.extraGuestRate,
    this.cancellationPolicyId,
  });

  final String name;
  final String? category;
  final String description;
  final int? capacity;
  final String address;
  final String city;
  final String state;
  final String country;
  final GeoPoint? center;
  final double radiusMeters;
  final List<VenuePhoto> photos;
  final List<String> spaceType;
  final List<String> amenities;
  final List<String> techAv;
  final List<String> staffing;
  final List<String> policies;
  final double? price;
  final String billingRate;
  final double? extraGuestRate;
  final String? cancellationPolicyId;

  List<List<double>>? get boundary =>
      center == null ? null : circlePolygon(center!, radiusMeters);

  /// What is still missing before the venue can be sent for review, in the
  /// order the steps come.
  List<String> get missing => [
        if (name.trim().isEmpty) 'name',
        if (category == null) 'category',
        if (description.trim().isEmpty) 'description',
        if ((capacity ?? 0) < 1) 'capacity',
        if (address.trim().isEmpty ||
            city.trim().isEmpty ||
            country.trim().isEmpty)
          'address',
        if (center == null) 'location',
        if (photos.isEmpty) 'photos',
        if (price == null || price! < 0) 'price',
      ];

  bool get readyToSubmit => missing.isEmpty;

  VenueDraft copyWith({
    String? name,
    String? category,
    String? description,
    int? capacity,
    bool clearCapacity = false,
    String? address,
    String? city,
    String? state,
    String? country,
    GeoPoint? center,
    double? radiusMeters,
    List<VenuePhoto>? photos,
    List<String>? spaceType,
    List<String>? amenities,
    List<String>? techAv,
    List<String>? staffing,
    List<String>? policies,
    double? price,
    bool clearPrice = false,
    String? billingRate,
    double? extraGuestRate,
    String? cancellationPolicyId,
  }) =>
      VenueDraft(
        name: name ?? this.name,
        category: category ?? this.category,
        description: description ?? this.description,
        capacity: clearCapacity ? null : capacity ?? this.capacity,
        address: address ?? this.address,
        city: city ?? this.city,
        state: state ?? this.state,
        country: country ?? this.country,
        center: center ?? this.center,
        radiusMeters: radiusMeters ?? this.radiusMeters,
        photos: photos ?? this.photos,
        spaceType: spaceType ?? this.spaceType,
        amenities: amenities ?? this.amenities,
        techAv: techAv ?? this.techAv,
        staffing: staffing ?? this.staffing,
        policies: policies ?? this.policies,
        price: clearPrice ? null : price ?? this.price,
        billingRate: billingRate ?? this.billingRate,
        extraGuestRate: extraGuestRate ?? this.extraGuestRate,
        cancellationPolicyId: cancellationPolicyId ?? this.cancellationPolicyId,
      );

  /// The body for create or update. [status] is only ever `draft` or
  /// `pending`; a live venue is saved without one, so editing never demotes it.
  Map<String, dynamic> toJson({String? status}) => {
        'name': name.trim(),
        if (category != null) 'category': category,
        'description': description.trim(),
        if (capacity != null) 'capacity': capacity,
        'address': address.trim(),
        'city': city.trim(),
        if (state.trim().isNotEmpty) 'state': state.trim(),
        'country': country.trim(),
        if (boundary != null) 'boundary': boundary,
        'imgIds': [for (final p in photos) p.fileId],
        'spaceType': spaceType,
        'amenities': amenities,
        'techAv': techAv,
        'staffing': staffing,
        'policies': policies,
        if (price != null) 'price': price,
        'billingRate': billingRate,
        if (extraGuestRate != null) 'extraGuestRate': extraGuestRate,
        if (cancellationPolicyId != null)
          'cancellationPolicyId': cancellationPolicyId,
        if (status != null) 'status': status,
      };
}
