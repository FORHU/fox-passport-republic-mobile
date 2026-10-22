import 'package:flutter_template/features/spaces/domain/event_draft.dart';
import 'package:flutter_template/features/spaces/domain/venue_draft.dart';

/// Which list of the picker a package item is shown in.
enum ResourceBucket { venue, talent, service, equipment }

double? _num(Object? raw) =>
    raw is num ? raw.toDouble() : double.tryParse('$raw');

String? _text(Object? raw) {
  final value = raw is String ? raw.trim() : null;
  return value == null || value.isEmpty ? null : value;
}

String _slug(Object? category) {
  final raw =
      category is Map ? (category['slug'] ?? category['name']) : category;
  return '${raw ?? ''}'.trim().toLowerCase();
}

String? _firstImage(Object? images) {
  if (images is! List || images.isEmpty) return null;
  final first = images.first;
  return first is Map ? _text(first['url']) : null;
}

/// Which list a package item belongs in.
ResourceBucket bucketOf(PackageItem item) {
  if (item.isVenue) return ResourceBucket.venue;
  if (item.kind == PackageKind.talent) return ResourceBucket.talent;
  return item.icon == 'speaker'
      ? ResourceBucket.equipment
      : ResourceBucket.service;
}

/// A venue as a package item. Only a venue that is live can be offered.
PackageItem? packageItemFromVenue(Object? row, {required VenueAccess access}) {
  if (row is! Map || row['id'] == null) return null;
  return PackageItem(
    id: '${row['id']}',
    name: _text(row['name']) ?? '',
    kind: PackageKind.venue,
    cost: _num(row['price']) ?? _num(row['baseRate']) ?? 0,
    icon: 'location_city',
    description: _text(row['description']) ?? '',
    imageUrl: _firstImage(row['images']),
    city: _text(row['city']),
    state: _text(row['state']),
    country: _text(row['country']),
    lat: _num(row['lat']),
    lng: _num(row['lng']),
    access: access,
  );
}

/// An asset (something the host can add that is owned, not performed) as a
/// package item, sorted into talent, service or equipment as the web does.
PackageItem? packageItemFromAsset(
  Object? row, {
  double? agreedPrice,
  bool isOptional = false,
}) {
  if (row is! Map || row['id'] == null) return null;
  final slug = _slug(row['category']);
  var kind = PackageKind.asset;
  var icon = 'inventory_2';
  switch (slug) {
    case 'entertainment':
      kind = PackageKind.talent;
      icon = 'music_note';
    case 'planning':
      icon = 'event_note';
    case 'catering':
      icon = 'restaurant';
    case 'photography':
      icon = 'camera_alt';
    case 'equipment' || 'sound_system':
      icon = 'speaker';
    case 'decorations' || 'decoration' || 'furnitures' || 'furniture':
      icon = 'brush';
  }
  return PackageItem(
    id: '${row['id']}',
    name: _text(row['name']) ?? '',
    kind: kind,
    cost: _num(row['price']) ?? 0,
    agreedPrice: agreedPrice,
    isOptional: isOptional,
    icon: icon,
    description: _text(row['description']) ?? '',
    imageUrl: _firstImage(row['images']),
  );
}

/// A service as a package item. Performers (DJs, bands, hosts, photographers)
/// are talent; the rest are services.
PackageItem? packageItemFromService(
  Object? row, {
  double? agreedPrice,
  bool isOptional = false,
}) {
  if (row is! Map || row['id'] == null) return null;
  final slug = _slug(row['category']);
  const talentIcons = {
    'entertainment': 'music_note',
    'photography': 'camera_alt',
    'videography': 'videocam',
    'dj': 'music_note',
    'live_band': 'music_note',
    'mc': 'mic',
  };
  final talentIcon = talentIcons[slug];
  final icon = talentIcon ??
      switch (slug) {
        'catering' => 'restaurant',
        'planning' => 'event_note',
        _ => 'work_outline',
      };
  return PackageItem(
    id: '${row['id']}',
    name: _text(row['name']) ?? '',
    kind: talentIcon != null ? PackageKind.talent : PackageKind.service,
    cost: _num(row['price']) ?? 0,
    agreedPrice: agreedPrice,
    isOptional: isOptional,
    icon: icon,
    description: _text(row['description']) ?? '',
    imageUrl: _firstImage(row['images']),
    // Saved with the event as a service, whichever list it was found in.
    savedAsService: true,
  );
}

/// An event as saved, to edit.
class EventDetail {
  const EventDetail({
    required this.id,
    required this.status,
    required this.draft,
  });

  final String id;

  /// `draft`, `pending`, `published`, `rejected` or `archived`.
  final String status;
  final EventDraft draft;

  /// Only a draft can be sent for review; anything else can only be edited.
  bool get isDraft => status == 'draft';

  static EventDetail? tryParse(Object? body) {
    final raw = body is Map
        ? (body['template'] is Map ? body['template'] : body['data'] ?? body)
        : null;
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

    final items = <PackageItem>[];
    final venues = raw['templateVenues'];
    if (venues is List) {
      for (final row in venues) {
        if (row is! Map) continue;
        final item = packageItemFromVenue(
          row['venue'],
          access: VenueAccess.approved,
        );
        if (item != null) {
          items.add(
            PackageItem(
              id: item.id,
              name: item.name,
              kind: PackageKind.venue,
              cost: item.cost,
              agreedPrice: _num(row['agreedPrice']),
              isOptional: row['isOptional'] == true,
              icon: item.icon,
              description: item.description,
              imageUrl: item.imageUrl,
              city: item.city,
              state: item.state,
              country: item.country,
              lat: item.lat,
              lng: item.lng,
            ),
          );
        }
      }
    }
    final assets = raw['templateAssets'];
    if (assets is List) {
      for (final row in assets) {
        if (row is! Map) continue;
        final item = packageItemFromAsset(
          row['asset'],
          agreedPrice: _num(row['agreedPrice']),
          isOptional: row['isOptional'] == true,
        );
        if (item != null) items.add(item);
      }
    }
    final services = raw['templateServices'];
    if (services is List) {
      for (final row in services) {
        if (row is! Map) continue;
        final item = packageItemFromService(
          row['service'],
          agreedPrice: _num(row['agreedPrice']),
          isOptional: row['isOptional'] == true,
        );
        if (item != null) items.add(item);
      }
    }

    final category = eventCategoryLabel(raw['category']);
    var description = _text(raw['description']) ?? '';
    var categoryOther = '';
    if (category == 'Other') {
      final split = splitCategoryOtherNote(description);
      categoryOther = split.categoryOther;
      description = split.description;
    }

    return EventDetail(
      id: raw['id'] as String,
      status: '${raw['status'] ?? 'draft'}',
      draft: EventDraft(
        title: _text(raw['name']) ?? '',
        category: category,
        categoryOther: categoryOther,
        description: description,
        maxAttendees: (_num(raw['maxAttendees']) ?? 100).round(),
        country: _text(raw['targetCountry']) ?? '',
        state: _text(raw['targetState']) ?? '',
        city: _text(raw['targetCity']) ?? '',
        lat: _num(raw['lat']),
        lng: _num(raw['lng']),
        cancellationPolicyId: _text(raw['cancellationPolicyId']),
        photos: photos,
        items: items,
      ),
    );
  }
}
