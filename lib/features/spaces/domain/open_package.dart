import 'package:equatable/equatable.dart';
import 'package:flutter_template/features/spaces/domain/package_invite.dart';

/// Open packages and applications (api#460): packages being put together
/// that Providers and Mayors can apply to with one of their listings.

String? _text(Object? v) =>
    v is String && v.trim().isNotEmpty ? v.trim() : null;
num? _num(Object? v) => v is num ? v : num.tryParse('${v ?? ''}');

/// Where an application stands.
enum ApplicationStatus {
  pending,
  accepted,
  declined,
  withdrawn;

  static ApplicationStatus fromApi(Object? v) => switch (v) {
        'accepted' => accepted,
        'declined' => declined,
        'withdrawn' => withdrawn,
        _ => pending,
      };
}

/// A spot in a package: `venue` (one per package), or `asset:<category>` /
/// `service:<category>` (one per category).
class Spot {
  const Spot._();

  static bool isVenue(String spot) => spot == 'venue';

  /// A gear or service spot's category in words, "Sound system". The venue
  /// spot's word comes from the app's strings.
  static String category(String spot) {
    final category = spot.contains(':') ? spot.split(':').last : spot;
    final words = category.replaceAll('_', ' ').trim();
    if (words.isEmpty) return spot;
    return words[0].toUpperCase() + words.substring(1);
  }
}

/// One of the caller's applications to a package.
class MyApplication extends Equatable {
  const MyApplication({
    required this.id,
    required this.listingId,
    required this.status,
  });

  static MyApplication? tryParse(Object? raw) {
    if (raw is! Map || raw['id'] is! String) return null;
    return MyApplication(
      id: raw['id'] as String,
      listingId: '${raw['listingId'] ?? ''}',
      status: ApplicationStatus.fromApi(raw['status']),
    );
  }

  final String id;
  final String listingId;
  final ApplicationStatus status;

  @override
  List<Object?> get props => [id, listingId, status];
}

List<MyApplication> _applications(Object? raw) => [
      if (raw is List)
        for (final r in raw)
          if (MyApplication.tryParse(r) case final a?) a,
    ];

/// A package in the Open packages list.
class OpenPackage extends Equatable {
  const OpenPackage({
    required this.id,
    required this.name,
    this.city,
    this.hostName,
    this.maxAttendees,
    this.takenSpots = const [],
    this.myApplications = const [],
  });

  static OpenPackage? tryParse(Object? raw) {
    if (raw is! Map || raw['id'] is! String) return null;
    final owner = raw['owner'];
    final taken = raw['takenSpots'];
    return OpenPackage(
      id: raw['id'] as String,
      name: _text(raw['name']) ?? '',
      city: [_text(raw['targetCity']), _text(raw['targetState'])]
          .whereType<String>()
          .join(', '),
      hostName: owner is Map ? _text(owner['name']) : null,
      maxAttendees: _num(raw['maxAttendees'])?.round(),
      takenSpots: [
        if (taken is List)
          for (final s in taken)
            if (s is String) s,
      ],
      myApplications: _applications(raw['myApplications']),
    );
  }

  final String id;
  final String name;
  final String? city;
  final String? hostName;
  final int? maxAttendees;
  final List<String> takenSpots;
  final List<MyApplication> myApplications;

  /// The caller's waiting application, if they have one here.
  MyApplication? get waiting => myApplications
      .where((a) => a.status == ApplicationStatus.pending)
      .firstOrNull;

  @override
  List<Object?> get props => [id, name, takenSpots, myApplications];
}

/// One line already in an open package.
class OpenPackageLine extends Equatable {
  const OpenPackageLine({
    required this.name,
    required this.spot,
    required this.status,
    this.isOptional = false,
  });

  static OpenPackageLine? tryParse(Object? raw) {
    if (raw is! Map) return null;
    return OpenPackageLine(
      name: _text(raw['name']) ?? '',
      spot: '${raw['spot'] ?? ''}',
      status: InviteStatus.fromApi(raw['status']),
      isOptional: raw['isOptional'] == true,
    );
  }

  final String name;
  final String spot;
  final InviteStatus status;
  final bool isOptional;

  @override
  List<Object?> get props => [name, spot, status, isOptional];
}

/// Why one of the caller's listings can't apply.
enum ApplyBlock { spotTaken, alreadyApplied }

/// One of the caller's listings, and whether it can apply to the package.
class ApplyChoice extends Equatable {
  const ApplyChoice({
    required this.kind,
    required this.id,
    required this.name,
    required this.spot,
    this.price,
    this.block,
  });

  static ApplyChoice? tryParse(Object? raw) {
    if (raw is! Map || raw['id'] is! String || raw['kind'] is! String) {
      return null;
    }
    return ApplyChoice(
      kind: raw['kind'] as String,
      id: raw['id'] as String,
      name: _text(raw['name']) ?? '',
      spot: '${raw['spot'] ?? ''}',
      price: _num(raw['price']),
      block: switch (raw['why']) {
        'spot_taken' => ApplyBlock.spotTaken,
        'already_applied' => ApplyBlock.alreadyApplied,
        _ => raw['canApply'] == false ? ApplyBlock.spotTaken : null,
      },
    );
  }

  /// `venue`, `asset` or `service`.
  final String kind;
  final String id;
  final String name;
  final String spot;
  final num? price;
  final ApplyBlock? block;

  bool get canApply => block == null;

  @override
  List<Object?> get props => [kind, id, spot, block];
}

/// An open package with its lines and the caller's choices.
class OpenPackageDetail extends Equatable {
  const OpenPackageDetail({
    required this.id,
    required this.name,
    this.description,
    this.city,
    this.hostName,
    this.lines = const [],
    this.choices = const [],
    this.myApplications = const [],
  });

  static OpenPackageDetail? tryParse(Object? body) {
    final raw = body is Map ? (body['data'] ?? body) : null;
    if (raw is! Map || raw['id'] is! String) return null;
    final owner = raw['owner'];
    final lines = raw['lines'];
    final choices = raw['myListings'];
    return OpenPackageDetail(
      id: raw['id'] as String,
      name: _text(raw['name']) ?? '',
      description: _text(raw['description']),
      city: [_text(raw['targetCity']), _text(raw['targetState'])]
          .whereType<String>()
          .join(', '),
      hostName: owner is Map ? _text(owner['name']) : null,
      lines: [
        if (lines is List)
          for (final l in lines)
            if (OpenPackageLine.tryParse(l) case final line?) line,
      ],
      choices: [
        if (choices is List)
          for (final c in choices)
            if (ApplyChoice.tryParse(c) case final choice?) choice,
      ],
      myApplications: _applications(raw['myApplications']),
    );
  }

  final String id;
  final String name;
  final String? description;
  final String? city;
  final String? hostName;
  final List<OpenPackageLine> lines;
  final List<ApplyChoice> choices;
  final List<MyApplication> myApplications;

  bool get canApply => choices.any((c) => c.canApply);

  MyApplication? get waiting => myApplications
      .where((a) => a.status == ApplicationStatus.pending)
      .firstOrNull;

  @override
  List<Object?> get props => [id, lines, choices, myApplications];
}

/// An application to the caller's own package, as the Event Foxer sees it.
class PackageApplication extends Equatable {
  const PackageApplication({
    required this.id,
    required this.status,
    required this.listingName,
    required this.applicantName,
    this.spot,
    this.price,
    this.message,
    this.spotTaken = false,
  });

  static PackageApplication? tryParse(Object? raw) {
    if (raw is! Map || raw['id'] is! String) return null;
    final applicant = raw['applicant'];
    return PackageApplication(
      id: raw['id'] as String,
      status: ApplicationStatus.fromApi(raw['status']),
      listingName: _text(raw['listingName']) ?? '',
      applicantName: (applicant is Map ? _text(applicant['name']) : null) ?? '',
      spot: _text(raw['spot']),
      price: _num(raw['price']),
      message: _text(raw['message']),
      spotTaken: raw['spotTaken'] == true,
    );
  }

  final String id;
  final ApplicationStatus status;
  final String listingName;
  final String applicantName;
  final String? spot;
  final num? price;
  final String? message;

  /// The spot was filled since they applied.
  final bool spotTaken;

  @override
  List<Object?> get props => [id, status, spotTaken];
}
