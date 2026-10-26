import 'dart:convert';

import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';

/// The person's upcoming tickets, saved on the phone so the code can still be
/// shown at a door with no signal. One copy per account; the next sign-in on
/// the device never sees someone else's.
class TicketsCache {
  TicketsCache(this._storage, this._userId);

  final StorageService _storage;
  final String? _userId;

  /// Every key starts with this, so signing out can remove them all.
  static const keyPrefix = 'tickets_cache_';

  /// How long past its end a ticket is kept: long enough to still show one
  /// that has just finished.
  static const keepAfterEnd = Duration(days: 1);

  String? get _key => _userId == null ? null : '$keyPrefix$_userId';

  /// Replaces the saved copy with [tickets] (an empty list included, so a
  /// ticket that no longer exists is not shown later).
  Future<void> save(List<Ticket> tickets, {DateTime? now}) async {
    final key = _key;
    if (key == null) return;
    await _storage.setString(
      key,
      jsonEncode({
        'savedAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
        'tickets': [
          for (final t in tickets)
            if (!t.isSample) t.toCache(),
        ],
      }),
    );
  }

  /// The saved tickets, each marked with when they were saved, without any
  /// that ended more than [keepAfterEnd] ago. Null when nothing is saved or
  /// what is saved cannot be read.
  List<Ticket>? read({DateTime? now}) {
    final key = _key;
    if (key == null) return null;
    final raw = _storage.getString(key);
    if (raw == null) return null;
    try {
      final body = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final savedAt = DateTime.parse('${body['savedAt']}').toLocal();
      final cutoff = (now ?? DateTime.now()).subtract(keepAfterEnd);
      final rows = body['tickets'] as List;
      return [
        for (final row in rows)
          if (row is Map)
            if (Ticket.fromCache(row.cast<String, dynamic>(), savedAt)
                case final t when t.endAt.isAfter(cutoff))
              t,
      ];
    } on Object {
      return null;
    }
  }
}
