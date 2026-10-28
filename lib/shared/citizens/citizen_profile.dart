import 'package:equatable/equatable.dart';

String? _text(Object? v) =>
    v is String && v.trim().isNotEmpty ? v.trim() : null;

int _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;

/// A stamp earned by attending an event at a venue.
class CitizenStamp extends Equatable {
  const CitizenStamp({
    required this.id,
    required this.eventName,
    required this.xp,
    this.place,
    this.date,
    this.imageUrl,
  });

  static CitizenStamp? tryParse(Object? row) {
    if (row is! Map || row['id'] == null) return null;
    final venue = row['venue'];
    final venueMap = venue is Map ? venue : const <String, dynamic>{};
    return CitizenStamp(
      id: '${row['id']}',
      eventName: _text(row['eventName']) ?? _text(venueMap['name']) ?? '',
      xp: _int(row['xpEarned']),
      place: _text(venueMap['name']) ?? _text(row['location']),
      date: _date(row['eventDate']),
      imageUrl: _text(venueMap['stampIconUrl']) ?? _text(row['imageUrl']),
    );
  }

  final String id;
  final String eventName;
  final int xp;
  final String? place;
  final DateTime? date;
  final String? imageUrl;

  @override
  List<Object?> get props => [id, eventName, xp, place, date];
}

/// A milestone badge a citizen has earned.
class CitizenBadge extends Equatable {
  const CitizenBadge({
    required this.id,
    required this.name,
    required this.rarity,
    this.description,
    this.earnedAt,
  });

  static CitizenBadge? tryParse(Object? row) {
    if (row is! Map || row['id'] == null) return null;
    final badge = row['badge'];
    if (badge is! Map) return null;
    return CitizenBadge(
      id: '${row['id']}',
      name: _text(badge['name']) ?? '',
      description: _text(badge['description']),
      rarity: (_text(badge['rarity']) ?? 'common').toLowerCase(),
      earnedAt: _date(row['earnedAt']),
    );
  }

  final String id;
  final String name;

  /// `legendary`, `epic`, `rare` or `common`.
  final String rarity;
  final String? description;
  final DateTime? earnedAt;

  @override
  List<Object?> get props => [id, name, rarity, earnedAt];
}

/// One of their Republic posts.
class CitizenPost extends Equatable {
  const CitizenPost({
    required this.id,
    required this.content,
    required this.likes,
    required this.comments,
    this.createdAt,
    this.mediaUrls = const [],
  });

  static CitizenPost? tryParse(Object? row) {
    if (row is! Map || row['id'] == null) return null;
    return CitizenPost(
      id: '${row['id']}',
      content: _text(row['content']) ?? '',
      likes: _int(row['likesCount']),
      comments: _int(row['commentsCount']),
      createdAt: _date(row['createdAt']),
      mediaUrls: [
        for (final u in row['mediaUrls'] as List? ?? const [])
          if (_text(u) case final url?) url,
      ],
    );
  }

  final String id;
  final String content;
  final int likes;
  final int comments;
  final DateTime? createdAt;

  /// Photos and videos attached, in order.
  final List<String> mediaUrls;

  @override
  List<Object?> get props => [id, content, likes, comments, mediaUrls];
}

/// What a citizen lists for booking: a venue, a service or gear.
class CitizenOffering extends Equatable {
  const CitizenOffering({
    required this.id,
    required this.name,
    required this.kind,
    this.detail,
    this.imageUrl,
  });

  static CitizenOffering? tryParse(Object? row, {required String kind}) {
    if (row is! Map || row['id'] == null) return null;
    final images = row['images'];
    String? image;
    if (images is List && images.isNotEmpty && images.first is Map) {
      image = _text((images.first as Map)['url']);
    }
    return CitizenOffering(
      id: '${row['id']}',
      name: _text(row['name']) ?? '',
      kind: kind,
      detail: _text(row['city']) ?? _text(row['category']),
      imageUrl: image,
    );
  }

  final String id;
  final String name;

  /// `venue`, `service` or `asset`.
  final String kind;
  final String? detail;
  final String? imageUrl;

  @override
  List<Object?> get props => [id, name, kind];
}

/// A person's public profile: who they are, their level, stamps and badges,
/// recent posts and what they list.
class CitizenProfile extends Equatable {
  const CitizenProfile({
    required this.id,
    required this.name,
    required this.level,
    required this.xp,
    this.username,
    this.bio,
    this.imageUrl,
    this.city,
    this.country,
    this.roles = const [],
    this.specializations = const [],
    this.verified = false,
    this.joinedAt,
    this.stamps = const [],
    this.badges = const [],
    this.posts = const [],
    this.postCount = 0,
    this.offerings = const [],
  });

  static CitizenProfile? tryParse(Object? json) {
    if (json is! Map || json['id'] == null) return null;
    final passport = json['passport'];
    var level = 1;
    var xp = 0;
    var stamps = const <CitizenStamp>[];
    var badges = const <CitizenBadge>[];
    if (passport is Map) {
      final paths = passport['paths'];
      if (paths is List) {
        for (final p in paths) {
          if (p is Map && p['path'] == 'user') {
            level = _int(p['level']).clamp(1, 1 << 30);
            xp = _int(p['currentXP']);
          }
        }
      }
      stamps = [
        for (final s in passport['stamps'] as List? ?? const [])
          if (CitizenStamp.tryParse(s) case final v?) v,
      ];
      badges = [
        for (final b in passport['userBadges'] as List? ?? const [])
          if (CitizenBadge.tryParse(b) case final v?) v,
      ];
    }
    List<CitizenOffering> offerings(String key, String kind) => [
          for (final o in json[key] as List? ?? const [])
            if (CitizenOffering.tryParse(o, kind: kind) case final v?) v,
        ];
    final posts = [
      for (final p in json['posts'] as List? ?? const [])
        if (CitizenPost.tryParse(p) case final v?) v,
    ];
    final count = json['_count'];
    return CitizenProfile(
      id: '${json['id']}',
      name: _text(json['name']) ?? '',
      username: _text(json['username']),
      bio: _text(json['bio']),
      imageUrl: _text(json['imgId']),
      city: _text(json['city']),
      country: _text(json['country']),
      roles: [
        for (final r in json['roleType'] as List? ?? const [])
          if (r is String) r,
      ],
      specializations: [
        for (final s in json['foxerSpecializations'] as List? ?? const [])
          if (s is Map && _text(s['category']) != null)
            _text(s['category'])!.replaceAll('_', ' '),
      ],
      verified: json['identityVerifiedAt'] != null,
      joinedAt: _date(json['createdAt']),
      level: level,
      xp: xp,
      stamps: stamps,
      badges: badges,
      posts: posts,
      postCount: count is Map ? _int(count['posts']) : posts.length,
      offerings: [
        ...offerings('venues', 'venue'),
        ...offerings('services', 'service'),
        ...offerings('assets', 'asset'),
      ],
    );
  }

  final String id;
  final String name;
  final String? username;

  /// A few lines they wrote about themselves.
  final String? bio;
  final String? imageUrl;
  final String? city;
  final String? country;
  final List<String> roles;
  final List<String> specializations;

  /// Their ID was checked: the Verified badge.
  final bool verified;
  final DateTime? joinedAt;
  final int level;
  final int xp;
  final List<CitizenStamp> stamps;
  final List<CitizenBadge> badges;
  final List<CitizenPost> posts;
  final int postCount;
  final List<CitizenOffering> offerings;

  /// XP needed for the next level, as the web shows it.
  int get nextLevelXp => level * 200;

  /// 0 to 1.
  double get progress => (xp / nextLevelXp).clamp(0, 1).toDouble();

  /// A Partner Foxer is shown in gold, as on the web.
  bool get isPartner => roles.contains('investor');

  @override
  List<Object?> get props => [id, name, level, xp, stamps, badges];
}

/// How many follow a person and how many they follow.
class CitizenFollowCounts extends Equatable {
  const CitizenFollowCounts({required this.followers, required this.following});

  static CitizenFollowCounts? tryParse(Object? data) {
    if (data is! Map) return null;
    return CitizenFollowCounts(
      followers: _int(data['followers']),
      following: _int(data['following']),
    );
  }

  final int followers;
  final int following;

  @override
  List<Object?> get props => [followers, following];
}
