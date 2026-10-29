import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What was typed into the composer and not posted: the words, and the
/// options of a poll. Photos are not kept; they are files on the phone.
class ComposeDraft extends Equatable {
  const ComposeDraft({
    this.text = '',
    this.options = const [],
    this.poll = false,
  });

  final String text;
  final List<String> options;
  final bool poll;

  /// Nothing worth keeping.
  bool get isEmpty =>
      text.trim().isEmpty && options.every((o) => o.trim().isEmpty);

  Map<String, dynamic> toJson() => {
        'text': text,
        'options': options,
        'poll': poll,
      };

  static ComposeDraft? tryParse(Object? raw) {
    if (raw is! String) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      final options = json['options'];
      return ComposeDraft(
        text: json['text'] is String ? json['text'] as String : '',
        options: [
          if (options is List)
            for (final o in options)
              if (o is String) o,
        ],
        poll: json['poll'] == true,
      );
    } on FormatException {
      return null;
    }
  }

  @override
  List<Object?> get props => [text, options, poll];
}

/// Keeps one person's draft on the phone, so a call or a swipe away does not
/// lose what they were writing.
class ComposeDraftStore {
  ComposeDraftStore(this._prefs, String userId)
      : _key = 'republic.compose_draft.$userId';

  final SharedPreferences _prefs;
  final String _key;

  ComposeDraft? read() {
    final draft = ComposeDraft.tryParse(_prefs.getString(_key));
    return draft == null || draft.isEmpty ? null : draft;
  }

  /// Saves [draft], or forgets it when there is nothing in it.
  Future<void> write(ComposeDraft draft) async {
    if (draft.isEmpty) {
      await _prefs.remove(_key);
    } else {
      await _prefs.setString(_key, jsonEncode(draft.toJson()));
    }
  }

  Future<void> clear() => _prefs.remove(_key);
}
