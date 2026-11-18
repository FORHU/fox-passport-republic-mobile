import 'dart:convert';

import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/core/services/storage_service.dart';

/// A saved answer from the server and when it was saved.
typedef SavedBody = ({Object? body, DateTime savedAt});

/// The last answer of a few public reads (what Home lists), saved on the phone
/// so Home still has something to show with no signal. Treated as transient
/// content: it is only used when the server cannot be reached, always says
/// when it was saved, and is dropped after [keepFor].
class ResponseCache {
  ResponseCache(this._storage);

  final StorageService _storage;

  /// Every key starts with this, so signing out can remove them all.
  static const keyPrefix = 'response_cache_';

  /// How long a saved answer is kept before it is too old to show.
  static const keepFor = Duration(days: 3);

  /// One key per path and set of parameters, whatever order they come in.
  static String keyFor(String path, Map<String, dynamic>? params) {
    final sorted = (params?.entries.toList() ?? [])
      ..sort((a, b) => a.key.compareTo(b.key));
    final tail = sorted.map((e) => '${e.key}=${e.value}').join('&');
    return '$keyPrefix$path?$tail';
  }

  /// Replaces the saved answer for [key]. A body that cannot be saved is
  /// skipped: the cache is a courtesy, never a reason to fail a read.
  Future<void> save(String key, Object? body, {DateTime? now}) async {
    try {
      await _storage.setString(
        key,
        jsonEncode({
          'savedAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
          'body': body,
        }),
      );
    } on Object {
      return;
    }
  }

  /// The saved answer, or null when there is none, it is older than
  /// [keepFor], or it cannot be read.
  SavedBody? read(String key, {DateTime? now}) {
    final raw = _storage.getString(key);
    if (raw == null) return null;
    try {
      final saved = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final savedAt = DateTime.parse('${saved['savedAt']}').toLocal();
      final current = now ?? DateTime.now();
      if (current.difference(savedAt) > keepFor) return null;
      return (body: saved['body'], savedAt: savedAt);
    } on Object {
      return null;
    }
  }

  /// The server could not be reached, or is failing: the saved copy is better
  /// than nothing. A refusal (signed out, not allowed) is not.
  static bool cannotReach(AppException e) =>
      e is NetworkException ||
      (e is ServerException && (e.statusCode ?? 0) >= 500);

  /// GETs [path], saving each answer. With no connection, or while the server
  /// is down, the saved answer is returned instead, with when it was saved;
  /// `savedAt` is null for a fresh answer. Any other failure is not hidden.
  static Future<({Object? body, DateTime? savedAt})> get(
    ApiService api,
    ResponseCache? cache,
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final key = ResponseCache.keyFor(path, query);
    try {
      final body = await api.get(path, query: query);
      await cache?.save(key, body);
      return (body: body, savedAt: null);
    } on AppException catch (e) {
      final saved = cannotReach(e) ? cache?.read(key) : null;
      if (saved == null) rethrow;
      return (body: saved.body, savedAt: saved.savedAt);
    }
  }
}
