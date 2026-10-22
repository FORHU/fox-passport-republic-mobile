import 'package:flutter_template/features/spaces/domain/venue_draft.dart';

/// What a host fills in while creating or editing an event. These rules mirror
/// the web's event builder, so an event made on either behaves the same on the
/// other.

/// The categories a host can pick, as the web words them, and the API value
/// each is saved as. The API's category is a fixed list, so "Other" has no
/// place to keep its own label; see [withCategoryOtherNote].
const eventCategoryLabels = [
  'Corporate',
  'Birthday',
  'Wedding',
  'Social',
  'Other',
];

/// The API's value for a category label. Anything unknown is `other`.
String eventCategoryValue(String? label) => switch (label?.toLowerCase()) {
      'corporate' => 'corporate',
      'birthday' => 'birthday',
      'wedding' => 'wedding',
      'social' => 'social',
      _ => 'other',
    };

/// The label for the API's category value. Anything unknown reads as Other.
String eventCategoryLabel(Object? value) => switch ('$value'.toLowerCase()) {
      'corporate' => 'Corporate',
      'birthday' => 'Birthday',
      'wedding' => 'Wedding',
      'social' => 'Social',
      _ => 'Other',
    };

final _otherNote = RegExp(r'^Event type: (.+?)\n\n');

/// For the category Other, the host's own label goes at the top of the
/// description with a stable prefix, so an edit can read it back out.
String withCategoryOtherNote(
  String description,
  String? category,
  String categoryOther,
) {
  if (category != 'Other' || categoryOther.trim().isEmpty) return description;
  return 'Event type: ${categoryOther.trim()}\n\n$description';
}

/// The reverse of [withCategoryOtherNote].
({String categoryOther, String description}) splitCategoryOtherNote(
  String description,
) {
  final match = _otherNote.firstMatch(description);
  if (match == null) return (categoryOther: '', description: description);
  return (
    categoryOther: match.group(1)!,
    description: description.substring(match.end),
  );
}

/// How many words a text has.
int countWords(String text) {
  final trimmed = text.trim();
  return trimmed.isEmpty ? 0 : trimmed.split(RegExp(r'\s+')).length;
}

/// The most words an event description may have.
const maxEventWords = 500;

/// The description length the web recommends before submitting.
const recommendedEventWords = 100;

/// The most photos an event may have.
const maxEventPhotos = 5;

/// The web's icons that mark an item as a venue or as talent for the cost
/// breakdown.
const venueIcons = {'location_city', 'warehouse', 'forest'};
const talentIcons = {
  'music_note',
  'local_bar',
  'movie_filter',
  'mic',
  'camera_alt',
  'videocam',
};

/// What kind of thing a package item is. Talent and equipment are listed
/// apart from services for the host, but are saved as the asset or service
/// they are.
enum PackageKind { venue, asset, service, talent }

/// Whether the host may put a venue in their package: they run it, or an
/// affiliation with its Mayor is approved or still pending, or there is none.
enum VenueAccess { approved, pending, none }

/// One thing in an event's core package: a venue, or something it provides.
class PackageItem {
  const PackageItem({
    required this.id,
    required this.name,
    required this.kind,
    required this.cost,
    this.agreedPrice,
    this.isOptional = false,
    this.imageUrl,
    this.description = '',
    this.city,
    this.state,
    this.country,
    this.lat,
    this.lng,
    this.access = VenueAccess.approved,
    this.savedAsService = false,
    this.icon = 'inventory_2',
  });

  final String id;
  final String name;
  final PackageKind kind;

  /// The listed price.
  final double cost;

  /// What the host agreed for this event, when different from [cost].
  final double? agreedPrice;
  final bool isOptional;
  final String? imageUrl;
  final String description;

  /// A venue's place, used to fill in the event's own.
  final String? city;
  final String? state;
  final String? country;
  final double? lat;
  final double? lng;

  /// A venue's access for the host.
  final VenueAccess access;

  /// A talent item that is a service rather than an asset.
  final bool savedAsService;

  /// The web's icon name for the item. The cost breakdown groups items by it,
  /// so it is kept to give the same totals.
  final String icon;

  /// The price that counts: agreed if the host set one, else listed.
  double get price => agreedPrice ?? cost;

  bool get isVenue => kind == PackageKind.venue;

  /// Counted with the venue in the cost breakdown.
  bool get countsAsVenue => isVenue || venueIcons.contains(icon);

  /// Counted with talent in the cost breakdown.
  bool get countsAsTalent =>
      kind == PackageKind.talent || talentIcons.contains(icon);

  /// Whether it is attached to the event as a service (otherwise an asset).
  bool get isService =>
      kind == PackageKind.service ||
      (kind == PackageKind.talent && savedAsService);

  PackageItem copyWith({
    double? agreedPrice,
    bool clearAgreedPrice = false,
    bool? isOptional,
  }) =>
      PackageItem(
        id: id,
        name: name,
        kind: kind,
        cost: cost,
        agreedPrice: clearAgreedPrice ? null : agreedPrice ?? this.agreedPrice,
        isOptional: isOptional ?? this.isOptional,
        imageUrl: imageUrl,
        description: description,
        city: city,
        state: state,
        country: country,
        lat: lat,
        lng: lng,
        access: access,
        savedAsService: savedAsService,
        icon: icon,
      );
}

/// What a package costs, split the way the web shows it.
class PackageTotals {
  const PackageTotals({
    required this.base,
    required this.venue,
    required this.talent,
    required this.services,
    required this.suggested,
  });

  /// Everything together.
  final double base;
  final double venue;
  final double talent;

  /// Everything that is neither venue nor talent.
  final double services;

  /// [base] with the host's margin on top.
  final double suggested;
}

/// One line of the readiness list.
class ReadinessItem {
  const ReadinessItem({
    required this.id,
    required this.met,
    required this.required,
  });

  /// `title`, `category`, `venue`, `gallery` or `description`.
  final String id;
  final bool met;

  /// A required line blocks submitting; the others are only recommended.
  final bool required;
}

class EventDraft {
  const EventDraft({
    this.title = '',
    this.category,
    this.categoryOther = '',
    this.description = '',
    this.maxAttendees = 100,
    this.country = '',
    this.state = '',
    this.city = '',
    this.lat,
    this.lng,
    this.cancellationPolicyId,
    this.photos = const [],
    this.items = const [],
    this.marginPct = 20,
  });

  final String title;

  /// One of [eventCategoryLabels], or null before one is chosen.
  final String? category;

  /// For Other: what the host calls it.
  final String categoryOther;
  final String description;
  final int maxAttendees;
  final String country;
  final String state;
  final String city;
  final double? lat;
  final double? lng;
  final String? cancellationPolicyId;
  final List<VenuePhoto> photos;
  final List<PackageItem> items;

  /// The margin the suggested price is worked out with. For the host's eye
  /// only; it is not saved.
  final int marginPct;

  PackageItem? get venue => items.where((i) => i.isVenue).firstOrNull;

  /// The host may submit only with a venue they are approved for.
  bool get hasApprovedVenue =>
      items.any((i) => i.isVenue && i.access == VenueAccess.approved);

  int get words => countWords(description);

  PackageTotals get totals {
    double sum(bool Function(PackageItem) test) =>
        items.where(test).fold(0, (a, i) => a + i.price);
    final base = sum((_) => true);
    return PackageTotals(
      base: base,
      venue: sum((i) => i.countsAsVenue),
      talent: sum((i) => i.countsAsTalent),
      services: sum((i) => !i.countsAsVenue && !i.countsAsTalent),
      suggested: base * (1 + marginPct / 100),
    );
  }

  /// What gates submitting (a title, a category, and an approved venue) and
  /// two lines the web only recommends (5 photos, 100 words).
  List<ReadinessItem> get readiness => [
        ReadinessItem(
          id: 'title',
          met: title.trim().isNotEmpty,
          required: true,
        ),
        ReadinessItem(id: 'category', met: category != null, required: true),
        ReadinessItem(id: 'venue', met: hasApprovedVenue, required: true),
        ReadinessItem(
          id: 'gallery',
          met: photos.length >= maxEventPhotos,
          required: false,
        ),
        ReadinessItem(
          id: 'description',
          met: words >= recommendedEventWords,
          required: false,
        ),
      ];

  /// 0 to 100: how many readiness lines are met.
  int get score {
    final lines = readiness;
    return (lines.where((l) => l.met).length / lines.length * 100).round();
  }

  /// Category Other also needs the host's own label to submit.
  bool get categoryOtherMissing =>
      category == 'Other' && categoryOther.trim().isEmpty;

  bool get readyToSubmit =>
      readiness.where((l) => l.required).every((l) => l.met) &&
      !categoryOtherMissing;

  EventDraft copyWith({
    String? title,
    String? category,
    String? categoryOther,
    String? description,
    int? maxAttendees,
    String? country,
    String? state,
    String? city,
    double? lat,
    double? lng,
    String? cancellationPolicyId,
    List<VenuePhoto>? photos,
    List<PackageItem>? items,
    int? marginPct,
  }) =>
      EventDraft(
        title: title ?? this.title,
        category: category ?? this.category,
        categoryOther: categoryOther ?? this.categoryOther,
        description: description ?? this.description,
        maxAttendees: maxAttendees ?? this.maxAttendees,
        country: country ?? this.country,
        state: state ?? this.state,
        city: city ?? this.city,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        cancellationPolicyId: cancellationPolicyId ?? this.cancellationPolicyId,
        photos: photos ?? this.photos,
        items: items ?? this.items,
        marginPct: marginPct ?? this.marginPct,
      );

  /// The body for create and update, as the web sends it. Events are never
  /// public from here: the API publishes them after review.
  Map<String, dynamic> toJson() {
    final text = withCategoryOtherNote(description, category, categoryOther);
    return {
      'name': title.trim(),
      if (text.isNotEmpty) 'description': text,
      'category': eventCategoryValue(category),
      'isPublic': false,
      if (maxAttendees > 0) 'maxAttendees': maxAttendees,
      if (cancellationPolicyId != null)
        'cancellationPolicyId': cancellationPolicyId,
      if (city.trim().isNotEmpty) 'targetCity': city.trim(),
      if (state.trim().isNotEmpty) 'targetState': state.trim(),
      if (country.trim().isNotEmpty) 'targetCountry': country.trim(),
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (photos.isNotEmpty) 'imgIds': [for (final p in photos) p.fileId],
    };
  }
}
