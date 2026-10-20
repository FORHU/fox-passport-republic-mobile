/// The Google Maps link for a place: its pin when the API gave coordinates,
/// otherwise a search for [query] (a name, an address, a city).
///
/// Null when there is nothing to look up.
Uri? mapsUri({double? lat, double? lng, String? query}) {
  final text = query?.trim() ?? '';
  final String search;
  if (lat != null && lng != null) {
    search = '$lat,$lng';
  } else if (text.isNotEmpty) {
    search = text;
  } else {
    return null;
  }
  return Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': search,
  });
}
