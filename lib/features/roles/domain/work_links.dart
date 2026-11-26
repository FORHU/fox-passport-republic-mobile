/// Where a Provider shows their work (mobile#519): one field each, instead of
/// one box of comma-separated links.
enum WorkLinkKind {
  facebook(['facebook.com', 'fb.com', 'fb.me']),
  instagram(['instagram.com']),
  tiktok(['tiktok.com']),
  youtube(['youtube.com', 'youtu.be']),

  /// Any site of their own.
  website([]);

  const WorkLinkKind(this.hosts);

  /// The sites a link in this field must be on; empty for [website].
  final List<String> hosts;
}

/// Why a link can't be sent.
enum WorkLinkProblem {
  /// Not a web address.
  invalid,

  /// A web address, but not on this field's site.
  wrongSite,
}

/// The longest link the API takes.
const maxWorkLinkLength = 2048;

/// [raw] as a full address: `facebook.com/page` becomes
/// `https://facebook.com/page`. Null when nothing was typed.
String? normalizeWorkLink(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;
  final hasScheme = RegExp('^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(text);
  return hasScheme ? text : 'https://$text';
}

/// What is wrong with [raw] typed into [kind]'s field, or null when it is
/// fine or empty.
WorkLinkProblem? workLinkProblem(WorkLinkKind kind, String raw) {
  final link = normalizeWorkLink(raw);
  if (link == null) return null;
  if (link.length > maxWorkLinkLength) return WorkLinkProblem.invalid;
  final uri = Uri.tryParse(link);
  if (uri == null ||
      !uri.hasAuthority ||
      (uri.scheme != 'https' && uri.scheme != 'http') ||
      !uri.host.contains('.')) {
    return WorkLinkProblem.invalid;
  }
  if (kind.hosts.isEmpty) return null;
  final host = uri.host.toLowerCase();
  final onSite = kind.hosts.any((h) => host == h || host.endsWith('.$h'));
  return onSite ? null : WorkLinkProblem.wrongSite;
}
