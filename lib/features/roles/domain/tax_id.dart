import 'package:equatable/equatable.dart';

/// The tax country an application names when the person's own country is not
/// known. The API checks an application with no tax country as Philippine.
const defaultTaxCountry = 'PH';

/// A country a tax number can be from, as `GET /locations/countries` lists it.
class TaxCountry extends Equatable {
  const TaxCountry({
    required this.code,
    required this.name,
    this.phoneCode = '',
  });

  /// Null for a row without a 2-letter code or a name.
  static TaxCountry? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final code = '${raw['code'] ?? ''}'.trim().toUpperCase();
    final name = '${raw['name'] ?? ''}'.trim();
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(code) || name.isEmpty) return null;
    final phone = '${raw['phoneCode'] ?? ''}'.replaceAll(RegExp(r'\D'), '');
    return TaxCountry(code: code, name: name, phoneCode: phone);
  }

  final String code;
  final String name;

  /// The calling code without its "+", e.g. "63"; empty where the country
  /// has no phone numbering. The contact number follows it (mobile#537).
  final String phoneCode;

  @override
  List<Object?> get props => [code, name, phoneCode];
}

/// [typed] with [phoneCode] in front, as the API reads it (api#378): a number
/// without its "+code" is read as Philippine. Kept as typed when it already
/// starts with "+" or there's no code; a leading 0 (the local trunk prefix)
/// is dropped, as "0917 123 4567" in the Philippines is "+63 917 123 4567".
String internationalPhone(String typed, String phoneCode) {
  final value = typed.trim();
  if (value.isEmpty || value.startsWith('+') || phoneCode.isEmpty) {
    return value;
  }
  final digits = value.replaceAll(RegExp(r'\D'), '');
  final national = digits.startsWith('0') ? digits.substring(1) : digits;
  return '+$phoneCode$national';
}

/// The code of the country in [countries] that [profileCountry] names, by code
/// or by name; [defaultTaxCountry] when it names none.
String taxCountryFor(String profileCountry, List<TaxCountry> countries) {
  final wanted = profileCountry.trim().toLowerCase();
  if (wanted.isEmpty) return defaultTaxCountry;
  for (final c in countries) {
    if (c.code.toLowerCase() == wanted || c.name.toLowerCase() == wanted) {
      return c.code;
    }
  }
  return defaultTaxCountry;
}

/// One way a country writes its tax number, from
/// `GET /locations/countries/:code/tin-formats` (api `utils/tax-id-formats`).
class TinFormat extends Equatable {
  const TinFormat({
    required this.label,
    required this.example,
    required this.pattern,
    this.rule,
    this.mask = '',
  });

  static TinFormat? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final pattern = '${raw['pattern'] ?? ''}';
    if (pattern.isEmpty) return null;
    final rule = raw['rule'];
    return TinFormat(
      label: '${raw['label'] ?? ''}'.trim(),
      example: '${raw['example'] ?? ''}'.trim(),
      pattern: pattern,
      rule: rule is String && rule.isNotEmpty ? rule : null,
      mask: '${raw['mask'] ?? ''}',
    );
  }

  /// What the number is called there, e.g. "TIN", "SIN".
  final String label;
  final String example;

  /// Matches the uppercased value without spaces; separators are optional.
  final String pattern;

  /// A stricter check on the captured groups joined, when set.
  final String? rule;

  /// How the number is typed, e.g. "000-000-000". Empty for the API's
  /// catch-all format for a country it has no rules for.
  final String mask;

  /// The catch-all format: its label and example are placeholders.
  bool get isGeneric => mask.isEmpty;

  /// Whether [value] is written this way. The same check as the API's.
  bool accepts(String value) {
    final normalized = value.toUpperCase().replaceAll(RegExp(r'\s+'), '');
    final RegExp re;
    try {
      re = RegExp(pattern);
    } on FormatException {
      return true; // Leave a rule the app can't read to the API.
    }
    final m = re.firstMatch(normalized);
    if (m == null) return false;
    final r = rule;
    if (r == null) return true;
    final compact = [
      for (var i = 1; i <= m.groupCount; i++) m.group(i) ?? '',
    ].join();
    try {
      return RegExp(r).hasMatch(compact);
    } on FormatException {
      return true;
    }
  }

  @override
  List<Object?> get props => [label, example, pattern, rule, mask];
}

/// How a country's tax numbers look.
class TinFormats extends Equatable {
  const TinFormats({
    required this.formats,
    required this.message,
    this.issuesTin = true,
  });

  static TinFormats? tryParse(Object? raw) {
    final body = raw is Map && raw['data'] is Map ? raw['data'] : raw;
    if (body is! Map) return null;
    final list = body['formats'];
    final formats = [
      if (list is List)
        for (final row in list)
          if (TinFormat.tryParse(row) case final f?) f,
    ];
    if (formats.isEmpty) return null;
    return TinFormats(
      formats: formats,
      message: '${body['message'] ?? ''}'.trim(),
      issuesTin: body['issuesTin'] != false,
    );
  }

  final List<TinFormat> formats;

  /// What the API says when the number fits none of them.
  final String message;

  /// False for a country that issues no tax number.
  final bool issuesTin;

  /// The names the formats use, e.g. "TIN" or "TIN (old) or NID / eTIN". Empty
  /// for the catch-all format.
  String get label => {
        for (final f in formats)
          if (f.label.isNotEmpty && !f.isGeneric) f.label,
      }.join(' / ');

  /// The first format's example, for the field's hint; empty for the
  /// catch-all format.
  String get example => formats.first.isGeneric ? '' : formats.first.example;

  bool accepts(String value) => formats.any((f) => f.accepts(value));

  @override
  List<Object?> get props => [formats, message, issuesTin];
}
