import 'package:equatable/equatable.dart';
import 'package:flutter_template/features/spaces/domain/package_invite.dart';

/// What kind of Supplier a package line is.
enum PackageLineKind { venue, gear, service }

/// Where a package is on its way to guests (mobile#509). A package is sent
/// for review only once every required Supplier accepted (api#469).
enum PackageStage {
  /// A draft still waiting on Suppliers, or with one to swap.
  building,

  /// A draft whose required Suppliers all accepted: it can be sent.
  ready,

  /// Sent; the admin is checking it.
  inReview,
  live,
  rejected,
  archived,
}

/// One venue, piece of gear or service in a package, with its Supplier's
/// answer.
class PackageLine extends Equatable {
  const PackageLine({
    required this.name,
    required this.kind,
    required this.required,
    this.supplierId,
    this.invite,
  });

  final String name;
  final PackageLineKind kind;

  /// A required line has to be accepted before the package can be sent.
  final bool required;

  /// The listing's owner, to message them.
  final String? supplierId;

  /// The Supplier's answer; null when the line joined at once (the Event
  /// Foxer's own listing, or a partner's), which counts as accepted.
  final LineInvite? invite;

  InviteStatus get status => invite?.status ?? InviteStatus.accepted;

  bool get accepted => status == InviteStatus.accepted;
  bool get waiting => status == InviteStatus.pending;

  /// Declined or expired: the Event Foxer swaps or removes it.
  bool get needsAction => invite?.needsAction ?? false;

  @override
  List<Object?> get props => [name, kind, required, supplierId, invite];
}

/// Where a package stands: its stage and each Supplier's answer, read from
/// an event-template row of `GET /event-templates` or `/event-templates/:id`.
class PackageStanding extends Equatable {
  const PackageStanding({required this.status, required this.lines});

  /// Reads the template's lines; null when [row] is not an event template.
  static PackageStanding? fromTemplate(Object? row) {
    if (row is! Map) return null;
    final status = row['status'];
    final lines = <PackageLine>[];

    void read(
      String key,
      String itemKey,
      String ownerKey,
      PackageLineKind kind,
    ) {
      final rows = row[key];
      if (rows is! List) return;
      for (final line in rows) {
        if (line is! Map) continue;
        final item = line[itemKey];
        final name = item is Map ? item['name'] : null;
        final owner = item is Map ? item[ownerKey] : null;
        lines.add(
          PackageLine(
            name: name is String ? name.trim() : '',
            kind: kind,
            required: line['isOptional'] != true,
            supplierId: owner is String && owner.isNotEmpty ? owner : null,
            invite: LineInvite.fromLine(line),
          ),
        );
      }
    }

    read('templateVenues', 'venue', 'mayorId', PackageLineKind.venue);
    read('templateAssets', 'asset', 'ownerId', PackageLineKind.gear);
    read('templateServices', 'service', 'ownerId', PackageLineKind.service);
    return PackageStanding(
      status: status is String ? status : 'draft',
      lines: lines,
    );
  }

  /// The template's `status`: `draft`, `pending`, `published`, `rejected` or
  /// `archived`.
  final String status;
  final List<PackageLine> lines;

  Iterable<PackageLine> get _required => lines.where((l) => l.required);

  /// Required lines whose Supplier hasn't answered yet.
  List<PackageLine> get waiting => [
        for (final l in _required)
          if (l.waiting) l,
      ];

  /// Required lines declined or expired.
  List<PackageLine> get toSwap => [
        for (final l in _required)
          if (l.needsAction) l,
      ];

  int get requiredCount => _required.length;
  int get acceptedCount => _required.where((l) => l.accepted).length;

  /// Every required Supplier accepted (and there is at least one line).
  bool get allAccepted =>
      lines.isNotEmpty && _required.every((l) => l.accepted);

  PackageStage get stage => switch (status) {
        'published' => PackageStage.live,
        'pending' => PackageStage.inReview,
        'rejected' => PackageStage.rejected,
        'archived' => PackageStage.archived,
        _ => allAccepted ? PackageStage.ready : PackageStage.building,
      };

  /// Whether the Event Foxer has something to do or wait for: a draft with
  /// lines (waiting, to swap, or ready to send).
  bool get needsAttention =>
      stage == PackageStage.ready ||
      (stage == PackageStage.building && lines.isNotEmpty);

  /// The fewest whole days any waiting Supplier has left; null when none is
  /// waiting or the request times are unknown.
  int? soonestDaysLeft(DateTime now) {
    int? soonest;
    for (final l in waiting) {
      final left = l.invite?.daysLeft(now);
      if (left != null && (soonest == null || left < soonest)) soonest = left;
    }
    return soonest;
  }

  @override
  List<Object?> get props => [status, lines];
}
